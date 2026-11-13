# Implementation Status

**Reviewed 2026-11-14 against PR #7 and PR #8.** This document describes the PR #8 feature branch; the changes are not yet merged into `main`.

| Capability | Status |
|---|---|
| Product requirements and architecture | Draft documentation |
| Contribution and agent instructions | Present on `main` |
| Next.js guest UX | Browser-only prototype with static menu and simulated AI responses |
| Pricing | Pure client-side demo calculator; not authoritative |
| Order status | Pure transition function; no persistence or kitchen integration |
| Supabase migration | Starter SQL with 8 RLS-enabled tables and no client-facing RLS policies; not executed here |
| Authentication and tenant onboarding | Not implemented in submitted code |
| Staff invitations and authorization | Not implemented |
| API order creation / idempotent transactions | Not implemented (schema includes an idempotency constraint) |
| Dependency lockfile | Added in PR #8; needs successful CI validation |
| Domain tests | Five small unit tests in submitted code; agent reports passing locally |
| GitHub CI | PR #7 failed before tests due to missing lockfile; PR #8 CI success not verified |
| QR table sessions / real kitchen display | Not implemented |
| AI waiter / human handoff | Simulated UX only; no AI or staff backend |
| Production deployment | Not deployed |

## Merge gates

- GitHub CI green on the actual proposed head SHA.
- Review SQL RLS behavior in local Supabase before treating tenant access as implemented.
- Review security-sensitive code changes and avoid describing the prototype as production-ready.
- Document what was tested and what remains unverified.

See issues #3–#5 for next development work.
