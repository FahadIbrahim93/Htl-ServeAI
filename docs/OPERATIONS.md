# QA, CI/CD and production operations

## Automated tests
- Unit: money arithmetic, taxes, modifiers, permissions, order state transitions, AI tool schemas.
- Integration: tenant isolation, transaction rollback, idempotency, outbox replay, realtime subscription scope, refunds.
- E2E: QR -> menu -> cart -> confirm -> KDS -> served -> bill -> payment -> owner report; run in Bangla and English.
- Security: IDOR, RLS, guest token replay, prompt injection, malicious uploads, webhook forgery.
- Load: peak restaurant dinner rush, reconnect storms, queue backlog, AI timeout/fallback.

## CI gates
Typecheck, lint, unit, migration validation, RLS tests, integration tests, Playwright smoke tests, dependency and secret scanning. Protected main branch; preview deployments; manual production approval.

## Environment separation
Distinct Supabase projects and credentials for dev, staging and production. Versioned migrations, backups, restricted admin access, audited releases. No real customer data in test.

## Observability
Track API latency/errors, order-confirmation success, outbox age, KDS lag, payment reconciliation failures, AI errors/tokens/cost, tenant-specific incident reports. Alert on persistent failures; do not log customer messages unnecessarily.

## Recovery
Document RPO/RTO targets with pilot clients; test restore from backups; have manual ordering fallback; replay outbox safely; publish incident and escalation process.

## Deployment checklist
Verify env vars and domains, DNS/TLS, RLS policies, storage policies, payment callbacks, rate limits, security headers, error monitoring, backups, feature flags, migration safety and rollback plan. Deploy to staging before production.
