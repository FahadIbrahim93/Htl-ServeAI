-- Disposable PostgreSQL authorization tests. Supabase Auth HTTP tests remain required.
begin;

insert into auth.users(id,is_anonymous,email,email_confirmed_at) values
 ('aaaabbbb-aaaa-4aaa-8aaa-aaaaaaaaaaaa',false,'owner@example.test',now()),
 ('bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb',false,'staff@example.test',now()),
 ('ccccdddd-cccc-4ccc-8ccc-cccccccccccc',false,'other@example.test',now()),
 ('ddddeeee-dddd-4ddd-8ddd-dddddddddddd',false,'unverified@example.test',null);

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
  if (select count(*) from public.staff_invitations) <> 0 then
    -- No direct table permission even for an authorized owner.
    raise exception 'Invitation table unexpectedly readable';
  end if;
exception when insufficient_privilege then
  null;
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
reset role;

do $$
begin
  if (select count(*) from public.memberships
      where user_id='bbbbcccc-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
        and role='waiter') <> 1 then
    raise exception 'Invitee did not become waiter';
  end if;
  if (select count(*) from public.audit_logs
      where event_type in ('staff.invitation_created','staff.invitation_accepted')) <> 2 then
    raise exception 'Invitation audit events missing';
  end if;
end $$;
rollback;
select 'Staff invitation smoke tests passed' as result;
