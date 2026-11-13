-- Atomic restaurant onboarding. Applies after 0001 and 0002.
-- SECURITY DEFINER is used only for the bootstrap operation that cannot be
-- performed with client write grants. Review the EXECUTE grants and identity
-- checks before deploying. No database project is changed by committing this.
begin;

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_tenant_created_idx
  on public.audit_logs (tenant_id, created_at desc);

alter table public.audit_logs enable row level security;
revoke all privileges on public.audit_logs from public, anon, authenticated;
grant select on public.audit_logs to authenticated;

-- Audit events are restricted to tenant owners; other staff cannot read them.
create policy audit_owner_read on public.audit_logs
  for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = audit_logs.tenant_id
        and m.user_id = (select auth.uid()) and m.role = 'owner'
    )
  );

-- Public-schema RPC because Supabase Data API exposes RPCs from configured
-- exposed schemas. EXECUTE is revoked from PUBLIC and anon and the body checks
-- the authenticated user's ID against auth.users. All SQL references are fully
-- qualified and search_path is empty to avoid object shadowing.
create function public.create_restaurant(
  p_name text, p_slug text, p_branch_name text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor uuid;
  v_tenant uuid;
  v_name text := pg_catalog.btrim(p_name);
  v_slug text := pg_catalog.lower(pg_catalog.btrim(p_slug));
  v_branch text := pg_catalog.btrim(p_branch_name);
begin
  v_actor := (select auth.uid());

  if v_actor is null or not exists (
    select 1 from auth.users u
    where u.id = v_actor and u.is_anonymous is not true
  ) then
    raise exception 'Verified non-anonymous account required'
      using errcode = '28000';
  end if;

  if v_name is null or pg_catalog.char_length(v_name) not between 2 and 120
    or v_slug is null or
       v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
    or pg_catalog.char_length(v_slug) not between 3 and 50
    or v_branch is null or
       pg_catalog.char_length(v_branch) not between 2 and 120
  then
    raise exception 'Invalid restaurant details' using errcode = '22023';
  end if;

  insert into public.tenants (name, slug, status)
    values (v_name, v_slug, 'trial') returning id into v_tenant;

  insert into public.memberships (tenant_id, user_id, role)
    values (v_tenant, v_actor, 'owner');

  insert into public.branches (tenant_id, name)
    values (v_tenant, v_branch);

  insert into public.audit_logs (tenant_id, actor_id, event_type, details)
    values (v_tenant, v_actor, 'tenant.created',
      pg_catalog.jsonb_build_object('slug', v_slug));

  return v_tenant;
end;
$$;

revoke all on function public.create_restaurant(text,text,text)
  from public, anon;
grant execute on function public.create_restaurant(text,text,text)
  to authenticated;

commit;
