# Staff access model — security design (Issue #4)

**Status:** Proposed authorization contract; NOT an implemented invitation system.

## Policy

Tenant roles: `owner`, `manager`, `waiter`, `kitchen`, `cashier`.

- **Owner:** may invite managers and operational staff, revoke non-owners, and change non-owner roles. Owner transfer is a separate multi-step audited process, not a general role edit.
- **Manager:** may invite, revoke, or reassign *operational* staff (waiter, kitchen, cashier) within their authorized scope. Cannot create/modify managers or owners.
- **Operational staff:** cannot invite, revoke, or change membership roles.
- Nobody may remove the final owner; nobody may promote themselves through user-provided role values.

A pure policy helper and tests are added under `apps/web/` for UI decisions and code review. **Do not use these checks alone for authorization.** The server/database must determine the current actor and actor role from a verified Supabase user session and database membership in the relevant tenant.

## Planned invitation protocol (not yet implemented)

1. Authorized owner/manager selects tenant, optional branch scope, role, and invitee email. Server resolves actor membership from `auth.uid()` and validates tenant and branch against database, not request claims.
2. Server creates a random high-entropy single-use invitation secret; store a *hash* only, along with scoped tenant/branch, role, email, issuer, expiry (e.g. 48 hours), redeemed/revoked timestamps and audit record. Email delivery is performed by a trusted server process.
3. The recipient signs in and **verifies** their email. A dedicated transactional RPC checks the token hash, expiration, non-revoked state, verified email match, issuer/scope policy, tenant subscription restrictions, and existing membership before inserting a membership and atomically consuming the invitation.
4. Replays, expired invitations, cross-tenant targets, unauthorized management and concurrent redemptions fail closed. Logs must never contain plaintext tokens.
5. Owners/managers may revoke within their permissions. Membership removal and role changes are audited and versioned. Existing sessions must not retain elevated authorization by relying solely on JWT roles.

## Database migration prerequisites

Current `memberships` primary key is `(tenant_id,user_id)`, so staff roles are tenant-wide. Branch-specific access requires a separate `membership_branches` table with a composite `(tenant_id,branch_id)` FK to `branches`; don't pretend the current schema enforces branch access. Implement server-side RPCs with explicit grants, fixed `search_path`, authorization predicates, rate limits, and no broad direct client writes.

## Test and acceptance matrix

- Owner invites manager, manager invites waiter; waiter cannot invite.
- Manager cannot grant/modify owner or manager; owner cannot create an owner with ordinary invite.
- Guest/anonymous/cross-tenant signed-in user cannot create or redeem an invitation for another identity.
- Wrong verified email, invalid or used token, expired/revoked token, simultaneous redemption: all rejected.
- Cross-tenant and cross-branch foreign-key attacks rejected by real database constraints.
- Existing member can't claim an invite to change own role.
- Removal/revocation immediately affects authoritative database checks.
- Full SQL tests run against disposable Supabase Auth + PostgREST; HTTP, SSR and E2E invitation flows tested.
- Email delivery errors handled without exposing secrets.

## Required review gates

Do not ship invitation links until migration, RPC implementation, audit tests, abuse prevention, delivery/expiry handling and end-to-end verification are reviewed. Staff authorization is a security boundary, not a UI feature.

See [DATABASE_SECURITY.md](DATABASE_SECURITY.md) and [AGENTS.md](../AGENTS.md).
