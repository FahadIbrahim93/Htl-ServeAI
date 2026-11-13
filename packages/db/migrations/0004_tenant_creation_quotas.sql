-- Server-enforced restaurant creation quotas and concurrency safety.
-- Restricts public signup abuse without trusting the browser.
-- Plan-specific paid quotas must be added through reviewed policy changes.
begin;

create index if not exists audit_logs_actor_creation_idx
  on public.audit_logs (actor_id, event_type, created_at desc);

create or replace function public.create_restaurant(
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
  v_count bigint;
  v_recent bigint;
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
    or v_slug is null or v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$'
    or pg_catalog.char_length(v_slug) not between 3 and 50
    or v_branch is null or pg_catalog.char_length(v_branch) not between 2 and 120
  then
    raise exception 'Invalid restaurant details' using errcode = '22023';
  end if;

  -- Serialize concurrent creations from one authenticated user so two
  -- simultaneous sessions cannot evade per-user limits.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text, 917));

  -- Keep duplicate-slug error consistent with the underlying unique index.
  if exists (select 1 from public.tenants where slug = v_slug) then
    raise exception 'Restaurant slug already exists'
      using errcode = '23505';
  end if;

  select count(*),
    count(*) filter (where created_at > pg_catalog.now() - interval '60 seconds')
    into v_count, v_recent
  from public.audit_logs
  where actor_id = v_actor and event_type = 'tenant.created';

  if v_count >= 3 then
    raise exception 'Restaurant limit reached. Contact support.'
      using errcode = '23514';
  end if;
  if v_recent >= 1 then
    raise exception 'Please wait before creating another restaurant.'
      using errcode = '23514';
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

-- Existing RPC execute grant to authenticated is preserved by CREATE OR REPLACE;
-- make these privileges explicit in the new migration as defense in depth.
revoke all on function public.create_restaurant(text,text,text) from public, anon;
grant execute on function public.create_restaurant(text,text,text) to authenticated;
commit;
