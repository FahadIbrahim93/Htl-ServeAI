# Implementation Status

**Reviewed 18 November 2026 (`main` at `92f8b60`).** This page describes what is merged into `main`. Open pull requests (#26, #41, #30) are listed in [STATUS.md](STATUS.md) and are not counted as delivered.

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
| Owner sign-up, sign-in and sign-out (web) | Merged in #15. Uses the official Supabase SSR client and checks the user with `getUser()` on the server. Covered by the 19-test Chromium suite (#28, extended by #32, #34 and #40), including session expiry, refresh and revocation |
| Owner onboarding form and dashboard (web) | Merged in #15. Calls the audited RPC with the signed-in session and lists only the owner's restaurants. Covered by the 19-test Chromium suite (#28, extended by #32, #34 and #40), including session expiry, refresh and revocation |
| Staff invitations and role management | Invitation backend remains in draft PR #26 (#4). The role policy and unit tests merged in PR #16. That is a UI/design helper, not an authorization boundary |
| Server API for orders | Not implemented. Guest orders are not persisted |
| Kitchen display, realtime updates, staff handoff | Simulated or not implemented |
| AI waiter | Simulated static responses only |
| Hosted Supabase staging and release migrations | Staging is documented in #29; four canonical migrations applied there. The staging URL is behind Vercel login, but the project alias `htl-serveai.vercel.app` is public and uses the staging database (#42). Production is not configured (#5) |
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
- [PR #32](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/32) (`0f2e8d7`): owner auth failures, sign-out and tampered-session assertions
- [PR #34](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/34) (`c477b6e`): three-restaurant cap and real JWT expiry/refresh/revocation
- [PR #40](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/40) (`dc2b6f6`): session refresh across callback redirects
- [PR #38](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/38) (`1139a78`): 2-test public smoke with Supabase settings unset

## Issue tracking notes

- **#3** and **#13** closed after foundation implementation; their remaining browser acceptance criteria moved to **#17**.
- **#17** closed when the initial suite merged, but its full acceptance criteria are not complete. [PR #32](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/32) (#31) strengthens failure/sign-out/tampered-session assertions. [PR #34](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/34) (#33), based on #32, adds account-cap and real expiry/refresh/revocation tests, and [PR #40](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/40) (#39) covers callback-redirect refresh. All three merged on 18 November 2026 (`0f2e8d7`, `c477b6e`, `dc2b6f6`), and #31, #33 and #39 are closed. [PR #38](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/38) (#37, `1139a78`) added the public smoke without Supabase settings.
- **#4** remains open. The role policy merged in #16; invitation database work is in draft [PR #26](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/26). Delivery, abuse controls and complete invitation UI/API verification remain required.
- **#5** remains open. Protected staging exists; production, monitoring, backup-restore rehearsal and public launch gates remain pending.
- **#6** is complete through merged #18. External contributions are not accepted.

## Limitations and release gates

- The merged 19-test browser suite covers basic owner flows, auth failures, tampered sessions, duplicate slugs, per-minute quota, the three-restaurant cap, real JWT expiry refresh, revoked-refresh-token denial, callback-redirect refresh and cross-tenant PostgREST denial using a browser session. Test count alone does not prove every #17 acceptance scenario.
- Session-refresh middleware runs only on `/dashboard`, `/onboarding` and `/auth/callback`. Callback-refresh coverage merged in #40 and a build/runtime smoke without Supabase settings merged in #38.
- The login form maps provider errors to controlled messages and has a friendly callback error state, merged in #27.
- Canonical SQL lives in `supabase/migrations/`; CI applies those files to disposable stacks. The deployment runbook is [DEPLOYMENT.md](DEPLOYMENT.md). Hosted staging setup is documented evidence, not proof of production readiness.
- `main` protection is documented as requiring `verify` and `postgres-rls-smoke`; requiring `supabase-local` and browser checks remains a release task. No second reviewer is required while there is one maintainer.
- Protected staging is for internal testing only. Public signup still requires complete browser acceptance, abuse controls and the release gates in the deployment runbook.

## Next

1. Confirm any remaining #17 browser acceptance scenarios not covered by the merged #32, #34, #40 and #38 follow-ups.
2. Review and complete staff invitations (#4 / #26), including trusted email delivery and abuse prevention.
3. Complete operational release gates (#5); production requires explicit approval.
4. Build catalog/modifiers, table management and revocable QR sessions, then transactional orders and durable kitchen delivery. Billing and the grounded AI waiter follow those foundations.
