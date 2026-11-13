# Architecture

## Approach

A **multi-tenant modular monolith** built on Next.js/TypeScript and PostgreSQL (Supabase). Domains: identity, tenancy, catalog, tables, orders, kitchen, payments, AI, reporting and subscriptions.

## Request path

Guest/staff browser → Next.js server API → authentication, authorization and Zod validation → domain services → PostgreSQL transaction and outbox → Supabase Realtime/worker notifications.

## Tenant isolation

Every tenant-owned row carries `tenant_id`; branch-specific rows also carry `branch_id`. Use database constraints and RLS to prevent cross-tenant references and access. Guest QR tokens identify a scoped table session, never staff privileges. Staff authorization is based on server-verified identity and membership, not client claims.

## Transaction integrity

Prices and taxes are calculated by backend from menu and tax rules; integer minor currency units. Orders and order items are inserted in one transaction with an idempotency key and immutable price snapshots. Kitchen events use an outbox for reliable delivery.

## AI boundary

The model only invokes allowlisted tools (search menu, item details, availability, recommend, draft order, request human). It cannot execute payments, change discounts or confirm orders. Human/guest confirmation and server validation are mandatory.

## Infrastructure

Vercel for application deployment, Supabase for Postgres/Auth/Realtime/Storage, monitored queues or outbox workers, GitHub Actions CI, structured logging and error monitoring.

## Architecture decisions

Major changes require an ADR in `docs/adr/` describing context, options, trade-offs, decision and migration plan.
