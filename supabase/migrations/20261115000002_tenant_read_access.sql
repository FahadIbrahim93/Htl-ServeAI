-- HTL ServeAI: least-privilege read access for staff tenant members.
-- Applies AFTER 0001_core.sql. Does not enable guest writes, onboarding, or order submission.
-- All writes remain server-only until transactional APIs and role checks are implemented.
begin;

-- Primary key (tenant_id, user_id) does not efficiently serve user_id-first lookups.
create index if not exists memberships_user_id_tenant_idx
  on public.memberships (user_id, tenant_id);

-- Supabase projects may grant broad privileges by default. Explicitly remove them.
-- Outbox is internal and intentionally NOT granted to authenticated clients.
revoke all privileges on public.tenants, public.memberships,
  public.branches, public.dining_tables, public.menu_items, public.orders,
  public.order_items, public.outbox_events from public, anon, authenticated;

grant usage on schema public to authenticated;

grant select on public.tenants, public.memberships, public.branches,
  public.menu_items, public.orders, public.order_items to authenticated;

-- Do not expose QR token hashes to staff browser clients.
grant select (id, tenant_id, branch_id, label, active)
  on public.dining_tables to authenticated;

-- Membership is deliberately read-only and visible only to the current user.
-- No mutation policy: invitations and role changes must be trusted server operations.
create policy memberships_self_read
  on public.memberships for select to authenticated
  using (user_id = (select auth.uid()));

create policy tenants_member_read
  on public.tenants for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = tenants.id and m.user_id = (select auth.uid())
    )
  );

create policy branches_member_read
  on public.branches for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = branches.tenant_id
        and m.user_id = (select auth.uid())
    )
  );

create policy tables_member_read
  on public.dining_tables for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = dining_tables.tenant_id
        and m.user_id = (select auth.uid())
    )
  );

create policy menu_items_member_read
  on public.menu_items for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = menu_items.tenant_id
        and m.user_id = (select auth.uid())
    )
  );

create policy orders_member_read
  on public.orders for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = orders.tenant_id
        and m.user_id = (select auth.uid())
    )
  );

create policy order_items_member_read
  on public.order_items for select to authenticated
  using (
    exists (
      select 1 from public.memberships m
      where m.tenant_id = order_items.tenant_id
        and m.user_id = (select auth.uid())
    )
  );

-- No policies on outbox_events. Internal service-only processing.
commit;
