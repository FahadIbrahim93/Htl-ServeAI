# Database security — Phase 1 foundation

The canonical SQL currently consists of:

- `packages/db/migrations/0001_core.sql` — core tables, foreign keys and deny-by-default RLS
- `packages/db/migrations/0002_tenant_read_access.sql` — tenant-restricted staff reads and explicit grants
- `packages/db/migrations/0003_atomic_tenant_onboarding.sql` — audited, authenticated tenant bootstrap RPC
- `packages/db/migrations/0004_tenant_creation_quotas.sql` — per-account registration throttle and total creation cap

## Access matrix

| Table | Authenticated staff | Anonymous clients | Direct client writes |
|---|---|---|---|
| tenants | Own tenant | Denied | Denied |
| memberships | Own membership rows | Denied | Denied |
| branches | Own tenant | Denied | Denied |
| dining_tables | Own tenant, excluding QR token hashes | Denied | Denied |
| menu_items | Own tenant | Denied | Denied |
| orders | Own tenant | Denied | Denied |
| order_items | Own tenant | Denied | Denied |
| outbox_events | Denied (internal) | Denied | Denied |
| audit_logs | Own tenant if owner | Denied | Denied |

## Bootstrap exception

The `public.create_restaurant` function is narrowly scoped and runs in one transaction. It creates a trial tenant, an owner membership bound to `auth.uid()`, a first branch, and an audit event. `EXECUTE` is revoked from `PUBLIC` and `anon` and granted only to `authenticated`. It checks the caller against `auth.users` and rejects Supabase anonymous sign-ins and missing identities. The `SECURITY DEFINER` function uses an empty `search_path` and schema-qualified SQL.

The RPC now uses a transaction-scoped per-user advisory lock, one-successful-creation-per-minute throttle, and maximum three restaurants per account. Production still requires network/IP-level abuse monitoring, verification of signup flows and a separate security review. Never grant arbitrary membership insert/update rights to a browser role. No authentication is inferred from editable user metadata.

## Automated test evidence

- [Database RLS smoke workflow](https://github.com/FahadIbrahim93/Htl-ServeAI/actions/workflows/database-rls.yml): ephemeral PostgreSQL 17 with mock `auth.uid()`, two tenants, explicit privilege/row checks, cross-tenant foreign key denial, onboarding audit and forbidden callers
- [Local Supabase integration workflow](https://github.com/FahadIbrahim93/Htl-ServeAI/actions/workflows/supabase-integration.yml): Docker-based Supabase CLI; generates temporary migrations from the canonical SQL and exercises the real local `auth.users` schema, `auth.uid()`, staff role, onboarding, and isolation

The local Supabase workflow also exercises real HTTP password signup, signed JWTs, PostgREST RPC authorization and cross-tenant data access with temporary accounts. **What these tests do not establish:** browser SSR cookie/session security, production anti-abuse, end-to-end UI interactions, application order transactions, hosted staging migrations or production behavior.

## Migrations and deployment

Do not apply the SQL directly to production. The repository's numbered `packages/db/migrations/` files are canonical, but are **not** automatically discovered by Supabase CLI. The CI workflow generates temporary Supabase migrations in the runner; it does not update any cloud project.

Before staging, establish a canonical Supabase migrations directory and history, review existing grants and role behavior, run a disposable/staging migration dry run and `supabase test db`, and author an explicit rollback plan. Revoking broad client privileges may break unreviewed existing clients.

## Next security tasks

1. Complete browser end-to-end tests for SSR cookie refresh, sign-in, onboarding and dashboard access ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
2. Expand tenant creation defenses beyond database per-user limits to IP/risk-based abuse controls.
3. Implement authenticated staff invitations, revocation and branch-based roles.
4. Add transaction-safe server order creation, idempotency, price snapshots and kitchen event delivery.
5. Make CI checks mandatory through GitHub branch protection/rulesets before production.
