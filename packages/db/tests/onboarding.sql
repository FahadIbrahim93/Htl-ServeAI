-- Smoke-tests the restricted onboarding RPC against isolated PostgreSQL.
-- This is not a Supabase Auth token-verification integration test.
begin;

insert into auth.users(id,is_anonymous) values
  ('44444444-4444-4444-8444-444444444444',false),
  ('55555555-5555-4555-8555-555555555555',false),
  ('66666666-6666-4666-8666-666666666666',true);

set role authenticated;
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',true);
select public.create_restaurant('  Restaurant A  ', '  restaurant-a  ', ' Main Branch ') as created_a;

do $$
begin
  if (select count(*) from public.tenants where slug='restaurant-a' and name='Restaurant A') <> 1 then
    raise exception 'Tenant A not created or normalized';
  end if;
  if (select count(*) from public.memberships where role='owner') <> 1 then
    raise exception 'Creator A not made owner';
  end if;
  if (select count(*) from public.branches where name='Main Branch') <> 1 then
    raise exception 'First branch not created';
  end if;
  if (select count(*) from public.audit_logs where event_type='tenant.created') <> 1 then
    raise exception 'Tenant creation was not audited';
  end if;
  if (select count(*) from public.tenants where status='trial') <> 1 then
    raise exception 'Onboarded tenant should start in trial';
  end if;
  begin
    perform public.create_restaurant('Another','BAD SLUG','Main Branch');
    raise exception 'Invalid slug unexpectedly accepted';
  exception when invalid_parameter_value then null;
  end;
  begin
    perform public.create_restaurant('Restaurant A','restaurant-a','Main Branch');
    raise exception 'Duplicate slug unexpectedly accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.memberships (tenant_id,user_id,role)
      select id,'55555555-5555-4555-8555-555555555555','owner'
      from public.tenants where slug='restaurant-a';
    raise exception 'Direct client membership insert was permitted';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','55555555-5555-4555-8555-555555555555',true);
select public.create_restaurant('Restaurant B','restaurant-b','Main Branch') as created_b;
do $$
begin
  if (select count(*) from public.tenants) <> 1 then
    raise exception 'User B sees another tenant';
  end if;
  if (select count(*) from public.audit_logs) <> 1 then
    raise exception 'User B sees another tenant audit log';
  end if;
  if (select count(*) from public.branches) <> 1 then
    raise exception 'User B sees another tenant branch';
  end if;
end $$;

select set_config('request.jwt.claim.sub','66666666-6666-4666-8666-666666666666',true);
do $$
begin
  begin
    perform public.create_restaurant('Anon Restaurant','anon-restaurant','Main Branch');
    raise exception 'Anonymous Supabase user created restaurant';
  exception when invalid_authorization_specification then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','77777777-7777-4777-8777-777777777777',true);
do $$
begin
  begin
    perform public.create_restaurant('Forged Identity','forged-identity','Main Branch');
    raise exception 'Nonexistent identity created restaurant';
  exception when invalid_authorization_specification then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','',true);
do $$
begin
  begin
    perform public.create_restaurant('Missing Identity','missing-identity','Main Branch');
    raise exception 'Missing identity created restaurant';
  exception when invalid_authorization_specification then null;
  end;
end $$;

reset role;
set role anon;
do $$
begin
  begin
    perform public.create_restaurant('Anonymous','anon-denied','Main Branch');
    raise exception 'Anonymous database role executed privileged RPC';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;

-- One creation per minute; simulate passage of time as a test administrator.
set role authenticated;
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',true);
do $
begin
  begin
    perform public.create_restaurant('Too Soon','too-soon','Main Branch');
    raise exception 'Rate limiting failed';
  exception when check_violation then null;
  end;
end $;
reset role;

update public.audit_logs set created_at=now()-interval '5 minutes'
  where actor_id='44444444-4444-4444-8444-444444444444';
set role authenticated;
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',true);
select public.create_restaurant('Second Restaurant','second-restaurant','Main Branch');
reset role;

update public.audit_logs set created_at=now()-interval '5 minutes'
  where actor_id='44444444-4444-4444-8444-444444444444';
set role authenticated;
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',true);
select public.create_restaurant('Third Restaurant','third-restaurant','Main Branch');
do $
begin
  begin
    perform public.create_restaurant('Over Quota','over-quota','Main Branch');
    raise exception 'Lifetime quota failed';
  exception when check_violation then null;
  end;
end $;
reset role;
rollback;
select 'Atomic onboarding smoke tests passed' as result;
