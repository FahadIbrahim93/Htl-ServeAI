# Database security — Phase 1 foundation

The canonical SQL currently consists of:

- `supabase/migrations/20261115000001_core.sql` — core tables, foreign keys and deny-by-default RLS
- `supabase/migrations/20261115000002_tenant_read_access.sql` — tenant-restricted staff reads and explicit grants
- `supabase/migrations/20261115000003_atomic_tenant_onboarding.sql` — audited, authenticated tenant bootstrap RPC
- `supabase/migrations/20261115000004_tenant_creation_quotas.sql` — per-account registration throttle and total creation cap

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
- [Local Supabase integration workflow](https://github.com/FahadIbrahim93/Htl-ServeAI/actions/workflows/supabase-integration.yml): Docker-based Supabase CLI; applies the canonical migration files and exercises the real local `auth.users` schema, `auth.uid()`, staff role, onboarding, and isolation

The local Supabase workflow also exercises real HTTP password signup, signed JWTs, PostgREST RPC authorization and cross-tenant data access with temporary accounts. **What these tests do not establish:** complete browser SSR cookie/session security, production anti-abuse, application order transactions or production behavior. The separate browser workflow merged in #28 adds 12 UI scenarios; session lifecycle acceptance is still incomplete. Staging migrations are documented separately in DEPLOYMENT.md.

## Migrations and deployment

`supabase/migrations/` is the single, canonical migration history. Both database workflows apply exactly these files in filename order, so CI tests what will be deployed. CI never touches a hosted project.

Do not paste SQL into a hosted SQL editor. Add a new timestamped file with `supabase migration new <name>`, get it through a pull request with green checks, then apply it to staging with `supabase db push --dry-run` followed by `supabase db push`. Production follows the same reviewed files, with a fresh `pg_dump` backup first and Fahad's approval. Never edit a migration that has already been applied to a hosted project; write a new one instead. Rollback is restoring the backup and rolling the app back, not an in-place destructive down-migration. The full runbook is in [deployment](DEPLOYMENT.md).

## Browser session flags observed in disposable CI (PR #28)

The Chromium E2E check merged in #28 observed two Supabase `sb-*`
session-cookie chunks with these attributes on **localhost HTTP only**:

| Attribute | Observed |
|---|---|
| `HttpOnly` | `false` |
| `Secure` | `false` |
| `SameSite` | `Lax` |
| `Path` | `/` |

These facts are **not** a claim that cookies in hosted HTTPS deployments
will have the same flags, nor that session rotation or revocation is proven.
Supabase browser-side cookies are JavaScript-readable in this configuration,
so XSS protection and a reviewed Content Security Policy remain essential.
CI prints cookie **flags only**, never cookie values or JWTs. This evidence
comes from the initial merged browser suite and is not a release approval. See
[Issue #17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)
for the acceptance contract; follow-ups #31/#32 and #33/#34 cover pending session checks in review. Issue closure does not establish full coverage.

## Next security tasks

1. Complete browser end-to-end tests for SSR cookie refresh, sign-in, onboarding and dashboard access ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
2. Expand tenant creation defenses beyond database per-user limits to IP/risk-based abuse controls.
3. Implement authenticated staff invitations, revocation and branch-based roles.
4. Add transaction-safe server order creation, idempotency, price snapshots and kitchen event delivery.
5. Require the `supabase-local` check in the `main` ruleset now that it always reports (`verify` and `postgres-rls-smoke` are already required).
