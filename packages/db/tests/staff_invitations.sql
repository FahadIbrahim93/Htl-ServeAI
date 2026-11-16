-- Disposable PostgreSQL authorization tests. Supabase Auth HTTP tests remain required.
begin;

insert into auth.users(id,is_anonymous,email,email_confirmed_at) values
 ('aaaabbbb-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false,'owner@example.test',now()),
 ('bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false,'staff@example.test',now()),
 ('ccccdddd-cccc-4ccc-8ccc-cccccccccccc',false,'other@example.test',now()),
 ('ddddeeee-dddd-4ddd-8ddd-dddddddddddd',false,'unverified@example.test',null),
 ('eeeeffff-eeee-4eee-8eee-eeeeeeeeeeee',false,'manager@example.test',now()),
 ('ffffaaaa-ffff-4fff-8fff-ffffffffffff',false,'revoked@example.test',now()),
 ('eeeeaaaa-eeee-4eee-8eee-aaaaaaaaaaab',false,'expired@example.test',now());

set role authenticated;
select set_config('request.jwt.claim.sub','aaaabbbb-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
select public.create_restaurant('Invite Test Restaurant','invitation-test','Main Branch');
do $$
declare v_tenant uuid; v_inv jsonb;
begin
  select id into v_tenant from public.tenants where slug='invitation-test';
  v_inv := public.create_staff_invitation(
    v_tenant,'STAFF@EXAMPLE.TEST','waiter',null);
  if v_inv->>'token' !~ '^[0-9a-f]{64}$' then
    raise exception 'Secret format is not 64 hex chars';
  end if;
  perform set_config('test.staff_invite_secret',v_inv->>'token',true);
end $$;
-- Direct SELECT of token hashes must be denied to the authenticated role.
do $$
begin
  begin
    perform count(*) from public.staff_invitations;
    raise exception 'Invitation token hashes unexpectedly readable';
  exception when insufficient_privilege then null;
  end;
end $$;

-- Manager/operational roles are not created by direct authenticated writes.
-- Wrong recipient cannot redeem a bearer token even if stolen.
select set_config('request.jwt.claim.sub','ccccdddd-cccc-4ccc-8ccc-cccccccccccc',true);
do $$
begin
  begin
    perform public.redeem_staff_invitation(
      current_setting('test.staff_invite_secret'));
    raise exception 'Wrong recipient could redeem invitation';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb',true);
do $$
declare v_tenant uuid;
begin
  v_tenant := public.redeem_staff_invitation(
    current_setting('test.staff_invite_secret'));
  if v_tenant is null then raise exception 'Redemption failed'; end if;
  begin
    perform public.redeem_staff_invitation(
      current_setting('test.staff_invite_secret'));
    raise exception 'Redeemed invitation accepted twice';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_staff_invitation(v_tenant,'guest@example.test','owner');
    raise exception 'Staff could invite owner';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','ddddeeee-dddd-4ddd-8ddd-dddddddddddd',true);
do $$
begin
  begin
    perform public.redeem_staff_invitation(
      current_setting('test.staff_invite_secret'));
    raise exception 'Unverified identity redeemed invitation';
  exception when invalid_authorization_specification then null;
  end;
end $$;
-- Owner can invite a manager, revoke outstanding invites, and cannot
-- create a branch-scoped invitation before branch membership ACLs exist.
select set_config('request.jwt.claim.sub','aaaabbbb-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
do $$
declare
  v_tenant uuid;
  v_manager jsonb;
  v_revoked jsonb;
  v_expired jsonb;
begin
  select id into v_tenant from public.tenants where slug='invitation-test';
  begin
    perform public.create_staff_invitation(
      v_tenant,'nobody@example.test','waiter',gen_random_uuid());
    raise exception 'Branch-scoped invitation unexpectedly accepted';
  exception when invalid_parameter_value then null;
  end;
  v_manager := public.create_staff_invitation(
    v_tenant,'manager@example.test','manager');
  perform set_config('test.manager_invite_secret',v_manager->>'token',true);
  v_revoked := public.create_staff_invitation(
    v_tenant,'revoked@example.test','cashier');
  perform set_config('test.revoked_invite_secret',v_revoked->>'token',true);
  -- Exercise denial for both an absent membership and an operational member.
  perform set_config('request.jwt.claim.sub','ccccdddd-cccc-4ccc-8ccc-cccccccccccc',true);
  begin
    perform public.revoke_staff_invitation((v_revoked->>'invitation_id')::uuid);
    raise exception 'Non-member revocation must be denied';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claim.sub','bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb',true);
  begin
    perform public.revoke_staff_invitation((v_revoked->>'invitation_id')::uuid);
    raise exception 'Operational member revocation must be denied';
  exception when insufficient_privilege then null;
  end;
  perform set_config('request.jwt.claim.sub','aaaabbbb-aaaa-4aaa-8aaa-aaaaaaaaaaaa',true);
  -- Successful owner revocation below also proves denied calls left it active.

  if not public.revoke_staff_invitation((v_revoked->>'invitation_id')::uuid) then
    raise exception 'Owner could not revoke invitation';
  end if;
  if public.revoke_staff_invitation((v_revoked->>'invitation_id')::uuid) then
    raise exception 'Revocation replay unexpectedly mutated invitation';
  end if;
  v_expired := public.create_staff_invitation(
    v_tenant,'expired@example.test','kitchen');
  perform set_config('test.expired_invite_secret',v_expired->>'token',true);
  perform set_config('test.expired_invite_id',v_expired->>'invitation_id',true);
end $$;

select set_config('request.jwt.claim.sub','eeeeffff-eeee-4eee-8eee-eeeeeeeeeeee',true);
do $$
declare
  v_tenant uuid;
begin
  v_tenant := public.redeem_staff_invitation(
    current_setting('test.manager_invite_secret'));
  if v_tenant is null then raise exception 'Manager redemption failed'; end if;
  begin
    perform public.create_staff_invitation(v_tenant,'promoted@example.test','manager');
    raise exception 'Manager could invite another manager';
  exception when insufficient_privilege then null;
  end;
  perform public.create_staff_invitation(v_tenant,'cook@example.test','kitchen');
end $$;

select set_config('request.jwt.claim.sub','ffffaaaa-ffff-4fff-8fff-ffffffffffff',true);
do $$
begin
  begin
    perform public.redeem_staff_invitation(
      current_setting('test.revoked_invite_secret'));
    raise exception 'Revoked token unexpectedly accepted';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;
-- Simulate passage of time by an administrator ONLY in rollbacked test fixture.
update public.staff_invitations
  set created_at=now()-interval '3 days', expires_at=now()-interval '1 minute'
  where id=current_setting('test.expired_invite_id')::uuid;
set role authenticated;
select set_config('request.jwt.claim.sub','eeeeaaaa-eeee-4eee-8eee-aaaaaaaaaaab',true);
do $$
begin
  begin
    perform public.redeem_staff_invitation(
      current_setting('test.expired_invite_secret'));
    raise exception 'Expired token unexpectedly accepted';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

do $$
begin
  if (select count(*) from public.memberships
      where user_id='bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
        and role='waiter') <> 1 then
    raise exception 'Invitee did not become waiter';
  end if;
  if (select count(*) from public.audit_logs
      where event_type in ('staff.invitation_created','staff.invitation_accepted','staff.invitation_revoked')) < 8 then
    raise exception 'Invitation audit events missing';
  end if;
end $$;
rollback;
select 'Staff invitation smoke tests passed' as result;
