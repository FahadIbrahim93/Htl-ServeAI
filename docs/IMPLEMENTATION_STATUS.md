# Implementation Status

**Reviewed 14 November 2026.** This page describes what is merged into `main`. Open pull requests are listed separately and are not counted as delivered.

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
| Owner sign-up, sign-in and sign-out (web) | Merged in #15. Uses the official Supabase SSR client and checks the user with `getUser()` on the server. **Not yet tested in a real browser** (#17) |
| Owner onboarding form and dashboard (web) | Merged in #15. Calls the audited RPC with the signed-in session and lists only the owner's restaurants. **Not yet tested in a real browser** (#17) |
| Staff invitations and role management | Not implemented (#4). A role policy and unit tests are proposed in PR #16. That is a UI/design helper, not an authorization boundary |
| Server API for orders | Not implemented. Guest orders are not persisted |
| Kitchen display, realtime updates, staff handoff | Simulated or not implemented |
| AI waiter | Simulated static responses only |
| Hosted Supabase staging and release migrations | Not configured (#5) |
| Production deployment | Not deployed |
| Licence | Not yet published (#6) |

## Evidence

- [PR #8](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/8): guest UX prototype, starter schema, pinned dependencies and CI
- [PR #9](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/9): tenant-scoped read policies and PostgreSQL isolation tests
- [PR #10](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/10): audited, atomic onboarding function and denial tests
- [PR #11](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/11): disposable local Supabase integration workflow
- [PR #15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15): owner login, onboarding, dashboard, creation quotas and HTTP Auth tests. Merged with all three checks green; no recorded code review at merge time

## Issue tracking notes

- **#3** (tenant onboarding and RLS isolation) and **#13** (owner login and onboarding UI) were closed when the database work and #15 merged. Both were closed before every acceptance item was met. The outstanding browser, session-lifecycle and cross-tenant end-to-end checks now live in [#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17).
- **#4** staff invitations: open. PR #16 covers the role policy only.
- **#5** staging and release gates: open, not started.
- **#6** licensing and contribution terms: open.

## Limitations and release gates

- Local Supabase tests cover simulated SQL identities **and** HTTP Auth, JWT and PostgREST access. They do not prove browser cookie and session behaviour. That is #17.
- Session-refresh middleware runs only on `/dashboard`, `/onboarding` and `/auth/callback`. This is deliberate, so the guest demo works without Supabase settings.
- The login form currently shows Supabase Auth error text as returned. Friendlier messages are part of #17.
- Canonical SQL lives in `packages/db/migrations/`. CI generates temporary Supabase CLI migrations from it. A reviewed, persistent migration and deployment process is still needed before any hosted database is used.
- `main` has no branch protection yet, and merges so far have not had a recorded review.
- Do not expose privileged Supabase keys, or apply migrations to a hosted project, without an approved staging plan.

## Next

1. [#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17): browser end-to-end tests for owner auth and onboarding
2. [#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4): staff invitations, building on the policy in PR #16
3. [#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5): staging and release gates, after maintainer approval
4. [#6](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/6): licence decision
