# Implementation Status

**Reviewed 17 November 2026.** This page describes what is merged into `main`. Open pull requests are listed separately and are not counted as delivered.

| Capability | Current verified state |
|---|---|
| Product requirements, architecture, contributor instructions | Documented |
| Next.js guest experience | Browser-only QR ordering and AI waiter simulation. No real orders are created |
| Pricing and order states | Client-side pricing calculator and pure state-transition functions, covered by unit tests |
| Reproducible npm build | Lockfile committed. CI runs `npm ci`, typecheck, unit tests and a production build |
| Tenant database schema | Nine RLS-enabled tables across four migration files |
| Authenticated tenant read isolation | SQL policies and restricted grants, with two-tenant tests |
| Restaurant onboarding (database) | Restricted `create_restaurant` RPC creates a trial tenant, owner membership, first branch and audit event in one transaction |
| Restaurant creation limits | Enforced in the database: three restaurants per account, at most one successful creation per minute, per-user lock against parallel requests. No IP-level or bot protection yet |
| Auth and RLS integration testing | PostgreSQL 17 checks with simulated identities, plus a disposable local Supabase stack with real HTTP sign-up, signed JWTs and PostgREST authorization |
| Owner sign-up, sign-in and sign-out (web) | Merged in #15. Uses the official Supabase SSR client and checks the user with `getUser()` on the server. Basic flows covered by the 12-test Chromium suite merged in #28; full session-lifecycle acceptance remains incomplete |
| Owner onboarding form and dashboard (web) | Merged in #15. Calls the audited RPC with the signed-in session and lists only the owner's restaurants. Basic flows covered by the 12-test Chromium suite merged in #28; full session-lifecycle acceptance remains incomplete |
| Staff invitations and role management | Invitation backend remains in draft PR #26 (#4). The role policy and unit tests merged in PR #16. That is a UI/design helper, not an authorization boundary |
| Server API for orders | Not implemented. Guest orders are not persisted |
| Kitchen display, realtime updates, staff handoff | Simulated or not implemented |
| AI waiter | Simulated static responses only |
| Hosted Supabase staging and release migrations | Protected staging is documented in #29; four canonical migrations applied there. Production is not configured (#5) |
| Production deployment | Not deployed |
| Licence | Public, all rights reserved; merged in PR #18 (#6) |

## Evidence

- [PR #8](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/8): guest UX prototype, starter schema, pinned dependencies and CI
- [PR #9](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/9): tenant-scoped read policies and PostgreSQL isolation tests
- [PR #10](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/10): audited, atomic onboarding function and denial tests
- [PR #11](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/11): disposable local Supabase integration workflow
- [PR #15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15): owner login, onboarding, dashboard, creation quotas and HTTP Auth tests. Merged with all three checks green; no recorded code review at merge time

- [PR #16](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/16): staff policy helper and tests
- [PR #18](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/18): licence and contribution terms
- [PR #27](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/27): controlled auth error messages
- [PR #28](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/28): 12-test disposable Chromium suite
- [PR #29](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/29): protected staging URL and runbook

## Issue tracking notes

- **#3** and **#13** closed after foundation implementation; their remaining browser acceptance criteria moved to **#17**.
- **#17** closed when the initial suite merged, but its full acceptance criteria are not complete. [PR #32](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/32) (#31) strengthens failure/sign-out/tampered-session assertions. [PR #34](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/34) (#33), based on #32, adds account-cap and real expiry/refresh/revocation tests. Both remain in review and are not counted as merged coverage.
- **#4** remains open. The role policy merged in #16; invitation database work is in draft [PR #26](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/26). Delivery, abuse controls and complete invitation UI/API verification remain required.
- **#5** remains open. Protected staging exists; production, monitoring, backup-restore rehearsal and public launch gates remain pending.
- **#6** is complete through merged #18. External contributions are not accepted.

## Limitations and release gates

- The merged 12-test browser suite covers basic owner flows, duplicate slugs, per-minute quota and cross-tenant PostgREST denial using a browser session. It does not establish the three-restaurant cap in the browser, repeated JWT expiry refresh, revoked-refresh-token denial or every callback/session assertion required by #17.
- Session-refresh middleware runs only on `/dashboard`, `/onboarding` and `/auth/callback`. Explicit callback-refresh coverage and a separate build/runtime test without Supabase settings remain outstanding.
- The login form maps provider errors to controlled messages and has a friendly callback error state, merged in #27.
- Canonical SQL lives in `supabase/migrations/`; CI applies those files to disposable stacks. The deployment runbook is [DEPLOYMENT.md](DEPLOYMENT.md). Hosted staging setup is documented evidence, not proof of production readiness.
- `main` protection is documented as requiring `verify` and `postgres-rls-smoke`; requiring `supabase-local` and browser checks remains a release task. No second reviewer is required while there is one maintainer.
- Protected staging is for internal testing only. Public signup still requires complete browser acceptance, abuse controls and the release gates in the deployment runbook.

## Next

1. Review #32 and #34 and finish the remaining #17 browser acceptance gaps.
2. Review and complete staff invitations (#4 / #26), including trusted email delivery and abuse prevention.
3. Complete operational release gates (#5); production requires explicit approval.
4. Build catalog/modifiers, table management and revocable QR sessions, then transactional orders and durable kitchen delivery. Billing and the grounded AI waiter follow those foundations.
