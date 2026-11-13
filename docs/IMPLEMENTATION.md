# Implementation plan and release gates

## Milestones
- M0 (weeks 1–2): customer discovery, tax/legal validation, wireframes, threat model, tenancy/roles, CI.
- M1 (weeks 3–5): audited schema, membership-based auth, branch/table management, QR token lifecycle, catalog, modifiers.
- M2 (weeks 6–8): transactional order creation, idempotency, outbox dispatcher, kitchen display, staff permissions, reconnect logic.
- M3 (weeks 9–10): bills, configurable tax policies, payment reconciliation, refunds, owner analytics, audit logs.
- M4 (weeks 11–12): Gemini tools, grounding, AI usage limits, human handoff, accessibility and bilingual QA.
- M5 (weeks 13–16): external security assessment, backup restore, load/soak testing, incident drills, 3–5 restaurant pilots.

## Security gates
- No public API with service-role keys in client bundles.
- All exposed tables have tested RLS policies and tenant-scoped FKs.
- Guest session permissions limited to specific table and active branch.
- Cross-tenant read/write, role escalation, QR replay, forged payment webhook and prompt-injection tests pass.
- Staff admin operations require reauthentication or stronger authorization where appropriate.

## Reliability gates
- Order retry never creates duplicate orders; stale versions reject state changes.
- Outbox event dispatch retries with dedupe and dead-letter alerting.
- Kitchen reconnect recovers missed tickets; payment status cannot be changed by AI.
- Backups restored successfully to staging; rollback playbook rehearsed.

## Deployment
1. Create separate Supabase staging and production projects and Vercel environments.
2. Configure least-privilege secrets and domain names; keep service role only in server runtime.
3. Apply reviewed migrations through CI; never auto-run destructive migrations on deploy.
4. Run unit, integration, browser, isolation and load tests against staging.
5. Deploy preview, conduct restaurant UAT, then promote approved release.
6. Configure alerting, backup retention, support on-call and manual fallback.

## Status

*Reviewed 14 November 2026. See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for the detailed table.*

M1 is partly done.

**Merged and tested:**
- Multi-tenant schema with row-level security on every exposed table
- Tenant-scoped read policies
- An audited, atomic `create_restaurant` function with per-account creation limits
- Owner sign-up, sign-in, onboarding and a tenant-scoped dashboard in the web app (#15)

Database and HTTP Auth tests run in CI against disposable PostgreSQL and local Supabase.

**Not yet done in M1:**
- Browser end-to-end tests for owner auth ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17))
- Staff invitations and role authorization ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)). A role policy is proposed in PR #16
- Branch and table management
- The QR token lifecycle
- Catalog and modifier management

The guest experience is still a browser-only prototype. M2 onwards has not started: orders, kitchen, billing, the AI waiter, payments, staging and production. No hosted Supabase or Vercel environment exists yet ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)).
