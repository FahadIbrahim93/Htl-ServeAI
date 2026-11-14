-- Starter schema: review and extend before production. Apply in controlled migrations.
create extension if not exists pgcrypto;
create table public.tenants (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 slug text not null unique,
 status text not null default 'trial' check (status in ('trial','active','suspended')),
 created_at timestamptz not null default now()
);
create table public.memberships (
 tenant_id uuid not null references public.tenants(id),
 user_id uuid not null references auth.users(id),
 role text not null check (role in ('owner','manager','waiter','kitchen','cashier')),
 primary key (tenant_id,user_id)
);
create table public.branches (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.tenants(id),
 name text not null,
 created_at timestamptz not null default now(),
 unique (tenant_id,id)
);
create table public.dining_tables (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 branch_id uuid not null,
 label text not null,
 token_hash text not null unique,
 active boolean not null default true,
 foreign key (tenant_id,branch_id) references public.branches(tenant_id,id),
 unique (tenant_id,branch_id,id),
 unique (branch_id,label)
);
create table public.menu_items (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 branch_id uuid not null,
 name_en text not null,
 name_bn text,
 price_minor bigint not null check (price_minor >= 0),
 available boolean not null default true,
 foreign key (tenant_id,branch_id) references public.branches(tenant_id,id),
 unique (tenant_id,branch_id,id)
);
create table public.orders (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 branch_id uuid not null,
 table_id uuid not null,
 status text not null default 'confirmed' check (status in ('confirmed','preparing','ready','served','cancelled')),
 subtotal_minor bigint not null check (subtotal_minor >= 0),
 total_minor bigint not null check (total_minor >= 0),
 idempotency_key uuid not null,
 version integer not null default 1,
 created_at timestamptz not null default now(),
 foreign key (tenant_id,branch_id) references public.branches(tenant_id,id),
 foreign key (tenant_id,branch_id,table_id) references public.dining_tables(tenant_id,branch_id,id),
 unique (tenant_id,idempotency_key),
 unique (tenant_id,branch_id,id)
);
create table public.order_items (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null,
 branch_id uuid not null,
 order_id uuid not null,
 item_name_snapshot text not null,
 unit_price_minor bigint not null check (unit_price_minor >= 0),
 quantity integer not null check (quantity > 0),
 foreign key (tenant_id,branch_id,order_id) references public.orders(tenant_id,branch_id,id)
);
create table public.outbox_events (
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references public.tenants(id),
 topic text not null,
 payload jsonb not null,
 created_at timestamptz not null default now(),
 processed_at timestamptz
);
-- Deny all access through exposed roles by default until audited policies are added.
alter table public.tenants enable row level security;
alter table public.memberships enable row level security;
alter table public.branches enable row level security;
alter table public.dining_tables enable row level security;
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.outbox_events enable row level security;
-- No client-facing policies in this starter. Implement and test explicit policies
-- before exposing authenticated/anonymous access. Trusted server operations
-- must independently validate tenant membership, branch and role.
