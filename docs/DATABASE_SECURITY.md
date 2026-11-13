# Database access model — Phase 1 prototype

This note documents the SQL migration in `packages/db/migrations/0002_tenant_read_access.sql`.

## Security boundary

The initial schema has eight RLS-enabled `public` tables. This follow-up provides **authenticated staff read-only access restricted to their tenant**, implemented via the `memberships` table and verified by PostgreSQL tests.

| Table | Authenticated member | Anonymous | Writes from clients |
|---|---|---|---|
| tenants | Own tenants only | Denied | Denied |
| memberships | Own membership rows only | Denied | Denied |
| branches | Own tenant | Denied | Denied |
| dining_tables | Own tenant, excluding `token_hash` | Denied | Denied |
| menu_items | Own tenant | Denied | Denied |
| orders | Own tenant | Denied | Denied |
| order_items | Own tenant | Denied | Denied |
| outbox_events | Denied | Denied | Denied |
| audit_logs | Owner reads own tenant | Denied | Denied |

No policy relies on client-editable JWT user metadata. The audited `create_restaurant` RPC creates a trial tenant, its first branch and the caller's owner membership atomically; the function is restricted to verified non-anonymous authenticated users, with no browser INSERT grants. Staff invitations and general membership mutation still require a separate authorized backend workflow. The existing public schema is **not** yet a viable end-to-end app backend.

## Tests

`.github/workflows/database-rls.yml` starts ephemeral PostgreSQL 17 with a **mock of Supabase's `auth.uid()` identity function** and roles, applies both migrations, and tests:

- User A sees only tenant A data; user B sees only tenant B data.
- Signed-in nonmember sees no tenant rows.
- Anonymous read attempts are denied.
- Staff cannot update database rows directly.
- QR token hashes and outbox events aren't available to staff roles.
- Cross-tenant branch/table foreign keys are rejected.
- Onboarding creates a tenant, owner membership, branch, and audit log atomically; invalid, duplicate, anonymous, and forged callers are denied.
- All nine tables (including audited onboarding) have RLS enabled.

**Limitations:** This does not execute against Supabase Auth, PostgREST, real JWT verification, or production. Do not interpret a passing mock PostgreSQL job as successful Supabase integration testing. The project still needs local Supabase CLI tests (`supabase test db`) and application-layer tests before deployment.

## Migration and rollback

Run through a reviewed migration pipeline only after testing on disposable/staging Supabase. The file uses the existing `packages/db/migrations/` numbering scheme; it is not automatically discovered by Supabase CLI. When adopting `supabase/migrations/`, generate migrations with the CLI and reconcile migration history before applying to an existing database.

The read migration revokes broad client grants and introduces narrower read policies. It may break unaudited direct client access in an existing deployment; assess every client query before applying. Rollback must be authored and reviewed for the target database rather than blindly restoring broad grants.

## Next tasks

1. Integrate the audited onboarding RPC with verified Supabase Auth and a protected onboarding UI; add a per-user creation limit and rate limiting.
2. Implement branch-aware staff access, invitation lifecycle and audit trail.
3. Use backend-only, transactional ordering with idempotency and server-calculated pricing.
4. Add Supabase-local integration tests that exercise these paths.
5. Configure branch protections and a green CI requirement before deployment.
