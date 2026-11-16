# Delivery Roadmap

Target schedule for a focused small team. Estimates are not commitments.

**Where we are (17 November 2026):** Phase 1 is in progress. Protected staging is available for internal testing; production is not configured and later product phases have not started.

## Phase 1 — Foundation (weeks 1–3) · in progress
- [x] Import the prepared Next.js/Supabase source (#1, PR #8).
- [x] Pin dependencies and commit lockfile (#2, PR #8).
- [x] Validate local build and test workflow. CI runs on every push and pull request.
- [x] Tenant schema, membership and RLS, with two-tenant isolation tests against PostgreSQL and local Supabase (PRs #9–#11).
- [x] Audited restaurant onboarding with per-account creation limits (PR #10, PR #15).
- [x] Owner sign-up, sign-in, onboarding form and dashboard in the web app (PR #15).
- [ ] Complete browser end-to-end acceptance for owner auth and onboarding; the initial 12-test suite merged in #28, with follow-ups #32/#34 in review ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
- [ ] Staff invitations and role authorization ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)). The role policy merged in PR #16; the invitation backend is in draft PR #26.
- [x] Basic branch protection on `main` (see deployment runbook).
- [ ] Independent security review and expanded required checks.
- [x] Publish the all-rights-reserved licence ([#6](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/6), PR #18).
- [ ] Staging environment and release gates ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)). Protected staging is running; production and launch gates remain pending.

Issues #3 and #13 were closed as their main pull requests merged. Their remaining end-to-end items were carried forward in #17, which also closed before full acceptance. Track the outstanding coverage through #31/#33 and the implementation status page.

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
