-- Staff invitations, restricted RPCs and audit trail. Applies after 0004.
-- REVIEW REQUIRED: this migration has not yet been executed in Supabase CI.
-- Direct client table writes remain denied; only signed-in RPC calls may mutate.
begin;

create table public.staff_invitations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  branch_id uuid,
  email text not null,
  role text not null check (role in ('manager','waiter','kitchen','cashier')),
  token_sha256 text not null unique check (length(token_sha256) = 64),
  invited_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  accepted_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  constraint staff_invitations_branch_fk
    foreign key (tenant_id,branch_id) references public.branches(tenant_id,id),
  constraint staff_invitations_state_check
    check (not (accepted_at is not null and revoked_at is not null)),
  constraint staff_invitations_expiry_check check (expires_at > created_at),
  constraint staff_invitations_accept_consistency
    check ((accepted_at is null) = (accepted_by is null))
);
create index staff_invites_tenant_created_idx
  on public.staff_invitations(tenant_id, created_at desc);
create index staff_invites_email_active_idx
  on public.staff_invitations(tenant_id, email, expires_at)
  where accepted_at is null and revoked_at is null;
alter table public.staff_invitations enable row level security;
revoke all on public.staff_invitations from public, anon, authenticated;
-- No RLS policies or SELECT grants: token hashes and recipients are server-only.

-- A privileged function is necessary because user-facing roles have no direct
-- membership/invitation write grants. Every function performs its own checks.
create function public.create_staff_invitation(
  p_tenant uuid, p_email text, p_role text, p_branch uuid default null
) returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_actor_role text;
  v_email text := pg_catalog.lower(pg_catalog.btrim(p_email));
  v_token text;
  v_hash text;
  v_invitation uuid;
begin
  if v_actor is null or not exists (
    select 1 from auth.users u where u.id = v_actor
      and u.is_anonymous is not true and u.email_confirmed_at is not null
  ) then
    raise exception 'Verified account required' using errcode='28000';
  end if;
  select m.role into v_actor_role from public.memberships m
    where m.tenant_id = p_tenant and m.user_id = v_actor;
  if v_actor_role is null or
     (v_actor_role = 'manager' and p_role not in ('waiter','kitchen','cashier')) or
     (v_actor_role <> 'owner' and v_actor_role <> 'manager') or
     p_role not in ('manager','waiter','kitchen','cashier') then
    raise exception 'Not authorized to invite role' using errcode='42501';
  end if;
  if not exists (select 1 from public.tenants t
      where t.id=p_tenant and t.status in ('trial','active')) then
    raise exception 'Tenant unavailable' using errcode='42501';
  end if;
  if v_email is null or length(v_email) not between 5 and 254 or
     v_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' then
    raise exception 'Invalid invitation email' using errcode='22023';
  end if;
  if p_branch is not null and not exists (
    select 1 from public.branches b
    where b.id=p_branch and b.tenant_id=p_tenant
  ) then
    raise exception 'Invalid branch' using errcode='22023';
  end if;
  -- Serialize invite issuance by actor to prevent concurrent throttle bypass.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text, 1221));
  if (select count(*) from public.staff_invitations
      where invited_by=v_actor and created_at > now() - interval '1 hour') >= 20 then
    raise exception 'Invitation rate limit reached' using errcode='23514';
  end if;
  if exists (
    select 1 from public.memberships m join auth.users u on u.id=m.user_id
    where m.tenant_id=p_tenant and pg_catalog.lower(u.email)=v_email
  ) then
    raise exception 'Account already belongs to restaurant' using errcode='23505';
  end if;
  -- Two independent UUIDv4 values make an unguessable 64-hex-char bearer token.
  v_token := pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '') ||
             pg_catalog.replace(pg_catalog.gen_random_uuid()::text, '-', '');
  v_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(v_token,'UTF8')), 'hex');
  insert into public.staff_invitations
    (tenant_id,branch_id,email,role,token_sha256,invited_by,expires_at)
    values (p_tenant,p_branch,v_email,p_role,v_hash,v_actor,
      now()+interval '48 hours')
    returning id into v_invitation;
  insert into public.audit_logs(tenant_id,actor_id,event_type,details)
    values (p_tenant,v_actor,'staff.invitation_created',
      pg_catalog.jsonb_build_object('invitation_id',v_invitation,'role',p_role));
  -- Secret returned ONLY once; caller must deliver via trusted channel and never log.
  return pg_catalog.jsonb_build_object(
    'invitation_id',v_invitation, 'token',v_token, 'expires_in_hours',48);
end;
$$;

create function public.redeem_staff_invitation(p_token text) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_email text;
  v_hash text;
  v_inv public.staff_invitations%rowtype;
begin
  if v_actor is null or not exists (
    select 1 from auth.users u where u.id=v_actor
      and u.is_anonymous is not true and u.email_confirmed_at is not null
  ) then raise exception 'Verified account required' using errcode='28000'; end if;
  select pg_catalog.lower(u.email) into v_email from auth.users u
    where u.id=v_actor;
  if p_token is null or p_token !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid invitation token' using errcode='22023';
  end if;
  v_hash := pg_catalog.encode(
    pg_catalog.sha256(pg_catalog.convert_to(p_token,'UTF8')), 'hex');
  -- The row lock makes concurrent replay of a token fail deterministically.
  select * into v_inv from public.staff_invitations
    where token_sha256=v_hash for update;
  if not found or v_inv.email <> v_email or
     v_inv.expires_at <= now() or v_inv.accepted_at is not null or
     v_inv.revoked_at is not null then
    raise exception 'Invitation invalid or expired' using errcode='42501';
  end if;
  if not exists(select 1 from public.tenants t
       where t.id=v_inv.tenant_id and t.status in ('trial','active')) then
    raise exception 'Tenant unavailable' using errcode='42501';
  end if;
  if exists(select 1 from public.memberships m
       where m.tenant_id=v_inv.tenant_id and m.user_id=v_actor) then
    raise exception 'Already a member' using errcode='23505';
  end if;
  insert into public.memberships(tenant_id,user_id,role)
    values (v_inv.tenant_id,v_actor,v_inv.role);
  update public.staff_invitations
    set accepted_at=now(), accepted_by=v_actor where id=v_inv.id;
  insert into public.audit_logs(tenant_id,actor_id,event_type,details)
    values (v_inv.tenant_id,v_actor,'staff.invitation_accepted',
      pg_catalog.jsonb_build_object('invitation_id',v_inv.id,'role',v_inv.role));
  return v_inv.tenant_id;
end;
$$;

create function public.revoke_staff_invitation(p_invitation uuid) returns boolean
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_inv public.staff_invitations%rowtype;
  v_actor_role text;
begin
  if v_actor is null or not exists (
    select 1 from auth.users u where u.id=v_actor
      and u.is_anonymous is not true and u.email_confirmed_at is not null
  ) then raise exception 'Verified account required' using errcode='28000'; end if;
  select * into v_inv from public.staff_invitations
    where id=p_invitation for update;
  if not found then raise exception 'Invitation not found' using errcode='42501'; end if;
  select role into v_actor_role from public.memberships
    where tenant_id=v_inv.tenant_id and user_id=v_actor;
  if v_actor_role <> 'owner' and
     not (v_actor_role='manager' and v_inv.role in ('waiter','kitchen','cashier')) then
    raise exception 'Insufficient permission' using errcode='42501';
  end if;
  if v_inv.accepted_at is not null or v_inv.revoked_at is not null then
    return false;
  end if;
  update public.staff_invitations set revoked_at=now() where id=v_inv.id;
  insert into public.audit_logs(tenant_id,actor_id,event_type,details)
    values (v_inv.tenant_id,v_actor,'staff.invitation_revoked',
      pg_catalog.jsonb_build_object('invitation_id',v_inv.id));
  return true;
end;
$$;

revoke all on function public.create_staff_invitation(uuid,text,text,uuid)
  from public, anon;
revoke all on function public.redeem_staff_invitation(text)
  from public, anon;
revoke all on function public.revoke_staff_invitation(uuid)
  from public, anon;
grant execute on function public.create_staff_invitation(uuid,text,text,uuid)
  to authenticated;
grant execute on function public.redeem_staff_invitation(text)
  to authenticated;
grant execute on function public.revoke_staff_invitation(uuid)
  to authenticated;
commit;
