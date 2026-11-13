# Implementation Status

**Reviewed 2026-11-14.** This table describes code merged into `main`, not proposed PR work.

| Capability | Current verified state |
|---|---|
| Product requirements, architecture, contributor instructions | Documented |
| Next.js guest experience | Static browser-only QR ordering/AI waiter UX simulation |
| Pricing and order states | Client-side pricing calculator and pure transition functions; five unit tests |
| Reproducible npm build | Lockfile committed; CI verifies `npm ci`, typecheck, unit tests and production build |
| Tenant database schema | Nine RLS-enabled tables after four migration files |
| Authenticated tenant read isolation | SQL policies + restricted grants; two-tenant tests |
| Restaurant onboarding | Restricted `create_restaurant` database RPC creates trial tenant, owner membership, first branch and audit event atomically |
| Auth and RLS integration testing | PostgreSQL 17 mocks and disposable local Supabase Auth-schema/DB checks passed; HTTP JWT/PostgREST tests added |
| Next.js Supabase login/session integration | SSR/browser SDK and login/logout pages implemented; full browser and session-lifecycle E2E unverified |
| Connected onboarding UI | Validated form invokes the audited DB RPC with signed-in user; browser E2E unverified |
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
- [PR #11](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/11) — green local Supabase database integration workflow\n- [PR #15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15) — owner login, dashboard, database creation quotas, and HTTP Auth tests (verify CI and merge status)

## Limitations and release gates

- Local Supabase tests exercise both simulated SQL identities **and HTTP Auth/JWT/PostgREST**; they do not prove Next.js cookie/session security or browser E2E.
- Database SQL is maintained in `packages/db/migrations/`; the test workflow generates temporary Supabase CLI migrations. A reviewed persistent migration/deployment strategy is still needed.
- Owner tenant creation is wired to the dedicated onboarding UI; the QR guest-order flow remains a simulation without persistence.
- Do not expose privileged Supabase keys or apply migrations to a hosted project without an approved staging plan.
- Add rate limiting, staff permissions, migration review, HTTP/API tests, observability and incident recovery before launch.

Continue [Issue #3](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/3) for Auth/browser onboarding and production authorization, then Issue #4 for staff invitations and Issue #5 for staging.
