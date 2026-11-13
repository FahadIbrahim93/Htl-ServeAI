# Implementation Status

**Reviewed 2026-11-14.** This table describes code merged into `main`, not proposed PR work.

| Capability | Current verified state |
|---|---|
| Product requirements, architecture, contributor instructions | Documented |
| Next.js guest experience | Static browser-only QR ordering/AI waiter UX simulation |
| Pricing and order states | Client-side pricing calculator and pure transition functions; five unit tests |
| Reproducible npm build | Lockfile committed; CI verifies `npm ci`, typecheck, unit tests and production build |
| Tenant database schema | Nine RLS-enabled tables after three migration files |
| Authenticated tenant read isolation | SQL policies + restricted grants; two-tenant tests |
| Restaurant onboarding | Restricted `create_restaurant` database RPC creates trial tenant, owner membership, first branch and audit event atomically |
| Auth and RLS integration testing | PostgreSQL 17 mocks and disposable local Supabase Auth-schema/DB checks passed |
| Next.js Supabase login/session integration | Not implemented |
| Connected onboarding UI | Not implemented; DB RPC not called from web app |
| Staff invitation/role management API | Not implemented |
| Server API for orders | Not implemented; no persisted guest orders |
| Kitchen display / realtime / staff handoff | Simulated or not implemented |
| AI waiter | Simulated static responses only |
| Hosted Supabase staging and release migrations | Not configured or tested |
| Production deployment | Not deployed |

## Evidence

- [PR #8](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/8) — guest UX prototype, starter schema, pinned dependencies and green CI
- [PR #9](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/9) — tenant-scoped read policies and PostgreSQL isolation tests
- [PR #10](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/10) — audited atomic onboarding database function and denial tests
- [PR #11](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/11) — green local Supabase database integration workflow

## Limitations and release gates

- Local Supabase integration tests simulate JWT identities **inside Postgres**; they do not authenticate via HTTP or prove browser session security.
- Database SQL is maintained in `packages/db/migrations/`; the test workflow generates temporary Supabase CLI migrations. A reviewed persistent migration/deployment strategy is still needed.
- No tenant creation or order flow is wired from the Next.js guest/staff UI.
- Do not expose privileged Supabase keys or apply migrations to a hosted project without an approved staging plan.
- Add rate limiting, staff permissions, migration review, HTTP/API tests, observability and incident recovery before launch.

Continue [Issue #3](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/3) for Auth/browser onboarding and production authorization, then Issue #4 for staff invitations and Issue #5 for staging.
