# Delivery Roadmap

Target schedule for a focused small team. Estimates are not commitments.

**Where we are (14 November 2026):** Phase 1 is in progress. Nothing is deployed, and no phase after Phase 1 has started.

## Phase 1 — Foundation (weeks 1–3) · in progress
- [x] Import the prepared Next.js/Supabase source (#1, PR #8).
- [x] Pin dependencies and commit lockfile (#2, PR #8).
- [x] Validate local build and test workflow. CI runs on every push and pull request.
- [x] Tenant schema, membership and RLS, with two-tenant isolation tests against PostgreSQL and local Supabase (PRs #9–#11).
- [x] Audited restaurant onboarding with per-account creation limits (PR #10, PR #15).
- [x] Owner sign-up, sign-in, onboarding form and dashboard in the web app (PR #15).
- [ ] Browser end-to-end tests for owner auth and onboarding ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
- [ ] Staff invitations and role authorization ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)). The role policy is proposed in PR #16.
- [ ] Independent security review and branch protection on `main`.
- [ ] Publish the all-rights-reserved licence ([#6](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/6), PR #18).
- [ ] Staging environment and release gates ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)). Not started.

Issues #3 and #13 were closed as their main pull requests merged. Their remaining end-to-end items are carried forward in #17.

## Phase 2 — Operations (weeks 4–6) · not started
- Catalog, modifiers, QR table sessions and guest cart.
- Transactional ordering and idempotency.
- Kitchen display and waiter notifications.

## Phase 3 — Billing and reporting (weeks 7–8) · not started
- Tax rules, receipts, cash/manual payment tracking.
- Audit events and owner reporting.

## Phase 4 — AI waiter (weeks 9–10) · not started
- Menu-grounded Bangla/English chat and restricted tools.
- Budget suggestions, structured drafts and explicit confirmation.
- Human handoff and AI usage metering.

## Phase 5 — Hardening and pilot (weeks 11–14+) · not started
- Load tests, security tests, restoration drills and monitored pilot.
- Release gate review and staging/production rollout.
