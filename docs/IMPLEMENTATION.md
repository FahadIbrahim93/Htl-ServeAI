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
The included web application is an interactive local prototype and domain test harness, not an integrated production SaaS. Production APIs, RLS policies, queue workers, payment integrations, AI model and deployments remain implementation tasks.
