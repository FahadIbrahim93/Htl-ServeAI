-- Run under isolated PostgreSQL 17 after 0001_core.sql and 0002_tenant_read_access.sql.
-- Auth is stubbed by auth_stub.sql; this is not a full hosted Supabase integration test.
-- psql -v ON_ERROR_STOP=1 --file=packages/db/tests/rls_isolation.sql
begin;

insert into auth.users(id) values
 ('11111111-1111-4111-8111-111111111111'),
 ('22222222-2222-4222-8222-222222222222'),
 ('33333333-3333-4333-8333-333333333333');

insert into public.tenants(id,name,slug) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Tenant A','tenant-a'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','Tenant B','tenant-b');

insert into public.memberships(tenant_id,user_id,role) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','11111111-1111-4111-8111-111111111111','owner'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','22222222-2222-4222-8222-222222222222','owner');

insert into public.branches(id,tenant_id,name) values
 ('aaaaaaaa-0000-4000-8000-000000000001','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','A Branch'),
 ('bbbbbbbb-0000-4000-8000-000000000001','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','B Branch');

insert into public.dining_tables(id,tenant_id,branch_id,label,token_hash) values
 ('aaaaaaaa-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-0000-4000-8000-000000000001','A-1','hash-a'),
 ('bbbbbbbb-1111-4111-8111-111111111111','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','bbbbbbbb-0000-4000-8000-000000000001','B-1','hash-b');

insert into public.menu_items(id,tenant_id,branch_id,name_en,price_minor) values
 ('aaaaaaaa-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-0000-4000-8000-000000000001','A Meal',5000),
 ('bbbbbbbb-2222-4222-8222-222222222222','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','bbbbbbbb-0000-4000-8000-000000000001','B Meal',6500);

insert into public.orders(id,tenant_id,branch_id,table_id,subtotal_minor,total_minor,idempotency_key) values
 ('aaaaaaaa-3333-4333-8333-333333333333','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-0000-4000-8000-000000000001','aaaaaaaa-1111-4111-8111-111111111111',5000,5000,'aaaaaaaa-4444-4444-8444-444444444444'),
 ('bbbbbbbb-3333-4333-8333-333333333333','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','bbbbbbbb-0000-4000-8000-000000000001','bbbbbbbb-1111-4111-8111-111111111111',6500,6500,'bbbbbbbb-4444-4444-8444-444444444444');

insert into public.order_items(id,tenant_id,branch_id,order_id,item_name_snapshot,unit_price_minor,quantity) values
 ('aaaaaaaa-5555-4555-8555-555555555555','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','aaaaaaaa-0000-4000-8000-000000000001','aaaaaaaa-3333-4333-8333-333333333333','A Meal',5000,1),
 ('bbbbbbbb-5555-4555-8555-555555555555','bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','bbbbbbbb-0000-4000-8000-000000000001','bbbbbbbb-3333-4333-8333-333333333333','B Meal',6500,1);

insert into public.outbox_events(tenant_id,topic,payload) values
 ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','test','{}'),
 ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','test','{}');

-- Verify RLS remains enabled on all eight exposed tables.
do $$
declare n integer;
begin
  select count(*) into n
  from pg_class c join pg_namespace s on s.oid=c.relnamespace
  where s.nspname='public' and c.relname in (
    'tenants','memberships','branches','dining_tables',
    'menu_items','orders','order_items','outbox_events','audit_logs'
  ) and c.relrowsecurity;
  if n <> 9 then raise exception 'RLS enabled on % of 9 tables', n; end if;
end $$;

set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);

do $$
begin
  if (select count(*) from public.tenants) <> 1 then raise exception 'User A tenant visibility failed'; end if;
  if (select count(*) from public.memberships) <> 1 then raise exception 'User A membership visibility failed'; end if;
  if (select count(*) from public.branches) <> 1 then raise exception 'User A branch isolation failed'; end if;
  if (select count(id) from public.dining_tables) <> 1 then raise exception 'User A dining table isolation failed'; end if;
  if (select count(*) from public.menu_items) <> 1 then raise exception 'User A menu isolation failed'; end if;
  if (select count(*) from public.orders) <> 1 then raise exception 'User A order isolation failed'; end if;
  if (select count(*) from public.order_items) <> 1 then raise exception 'User A order item isolation failed'; end if;
  if (select count(*) from public.menu_items where name_en='B Meal') <> 0 then raise exception 'Cross-tenant menu visible'; end if;
  begin
    perform token_hash from public.dining_tables limit 1;
    raise exception 'QR token_hash was exposed';
  exception when insufficient_privilege then null;
  end;
  begin
    perform * from public.outbox_events limit 1;
    raise exception 'Internal outbox was exposed';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.menu_items set price_minor=1;
    raise exception 'Client write unexpectedly allowed';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
do $$
begin
  if (select count(*) from public.tenants) <> 1 then raise exception 'User B tenant visibility failed'; end if;
  if (select count(*) from public.orders where tenant_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa') <> 0 then raise exception 'User B can see A orders'; end if;
  if (select count(*) from public.menu_items where name_en='B Meal') <> 1 then raise exception 'User B cannot see own menu'; end if;
end $$;

select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$
begin
  if (select count(*) from public.tenants) <> 0 then raise exception 'Outsider can see tenants'; end if;
  if (select count(*) from public.memberships) <> 0 then raise exception 'Outsider can see memberships'; end if;
  if (select count(*) from public.orders) <> 0 then raise exception 'Outsider can see orders'; end if;
end $$;

reset role;
set role anon;
do $$
begin
  begin
    perform * from public.tenants limit 1;
    raise exception 'Anonymous access unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- Foreign keys must reject a tenant A row pointing at tenant B branch or table.
do $$
begin
  begin
    insert into public.dining_tables(tenant_id,branch_id,label,token_hash)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'bbbbbbbb-0000-4000-8000-000000000001','INVALID','invalid-hash');
    raise exception 'Cross-tenant branch reference succeeded';
  exception when foreign_key_violation then null;
  end;
  begin
    insert into public.orders(tenant_id,branch_id,table_id,subtotal_minor,total_minor,idempotency_key)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'aaaaaaaa-0000-4000-8000-000000000001',
      'bbbbbbbb-1111-4111-8111-111111111111',10,10,gen_random_uuid());
    raise exception 'Cross-tenant table reference succeeded';
  exception when foreign_key_violation then null;
  end;
end $$;

rollback;
select 'RLS isolation smoke tests passed' as result;
