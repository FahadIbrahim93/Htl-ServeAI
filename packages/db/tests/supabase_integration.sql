-- Execute only against disposable LOCAL Supabase after core/read/onboarding migrations.
-- Uses real Supabase auth.users/auth.uid() and PostgreSQL roles; JWT claims are
-- simulated, so this does NOT validate HTTP JWT verification.
begin;

insert into auth.users
 (id,instance_id,aud,role,email,encrypted_password,created_at,updated_at)
values
 ('11111111-aaaa-4111-8111-111111111111','00000000-0000-0000-0000-000000000000','authenticated','authenticated','serveai-a@test.invalid','',now(),now()),
 ('22222222-bbbb-4222-8222-222222222222','00000000-0000-0000-0000-000000000000','authenticated','authenticated','serveai-b@test.invalid','',now(),now()),
 ('33333333-cccc-4333-8333-333333333333','00000000-0000-0000-0000-000000000000','authenticated','authenticated','serveai-outsider@test.invalid','',now(),now());

set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-aaaa-4111-8111-111111111111',true);
select public.create_restaurant('Supabase Restaurant A','supabase-a','Main Branch') as onboarded_a;

do $$
begin
  if (select count(*) from public.tenants) <> 1 then
    raise exception 'A tenant is not readable after onboarding';
  end if;
  if (select count(*) from public.memberships where role='owner') <> 1 then
    raise exception 'A owner membership missing';
  end if;
  if (select count(*) from public.audit_logs) <> 1 then
    raise exception 'A audit log missing';
  end if;
end $$;

select set_config('request.jwt.claim.sub','22222222-bbbb-4222-8222-222222222222',true);
select public.create_restaurant('Supabase Restaurant B','supabase-b','Main Branch') as onboarded_b;

do $$
begin
  if (select count(*) from public.tenants) <> 1 then
    raise exception 'B can read another tenant';
  end if;
  if (select count(*) from public.memberships) <> 1 then
    raise exception 'B can read another tenant membership';
  end if;
  if (select count(*) from public.branches) <> 1 then
    raise exception 'B can read another tenant branch';
  end if;
  if (select count(*) from public.audit_logs) <> 1 then
    raise exception 'B can read another tenant audit';
  end if;
end $$;

-- Server-side fixture setup can be done only with an administrative role.
reset role;
insert into public.menu_items (tenant_id,branch_id,name_en,price_minor)
select t.id,b.id,'Private menu '||t.slug,1000
from public.tenants t
join public.branches b on b.tenant_id=t.id;

set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-aaaa-4111-8111-111111111111',true);
do $$
begin
  if (select count(*) from public.menu_items) <> 1 then
    raise exception 'A can read tenant B menu';
  end if;
  if (select count(*) from public.menu_items where name_en='Private menu supabase-b') <> 0 then
    raise exception 'B menu disclosed to A';
  end if;
  begin
    insert into public.tenants(name,slug) values ('Attack','attack-tenant');
    raise exception 'Client could insert tenant';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','33333333-cccc-4333-8333-333333333333',true);
do $$
begin
  if (select count(*) from public.tenants) <> 0 then
    raise exception 'Unassigned user can see tenants';
  end if;
end $$;

reset role;
set local role anon;
do $$
begin
  begin
    perform * from public.tenants;
    raise exception 'Anonymous read unexpectedly worked';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.create_restaurant('Attack','another-attack','Branch');
    raise exception 'Anon executed onboarding function';
  exception when insufficient_privilege then null;
  end;
end $$;

rollback;
select 'Local Supabase RLS/auth integration checks passed' as result;
