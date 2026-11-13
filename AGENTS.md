# AI Agent Instructions — HTL ServeAI

This file applies to all coding agents working in this repository.

## Mission and source of truth

Build a secure Bangla-first restaurant SaaS for Hope Theory Labs. Product requirements live in docs/PRD.md; architecture in docs/ARCHITECTURE.md; task acceptance criteria in GitHub issues. If they conflict, ask the maintainer; do not silently change requirements.

## Work isolation

1. Work on **one assigned GitHub issue** per branch.
2. Record scope, affected paths, assumptions, tests, and dependencies in the issue.
3. Check existing branches and open PRs before editing shared files.
4. Avoid unrelated refactors and do not overwrite other agents' work.
5. Commit small, reviewable changes with clear messages.
6. Open a draft PR early; describe what remains unverified.
7. Never merge your own security-sensitive changes without human approval.

## Hard security boundaries

- Never commit secrets, API keys, service-role credentials, production dumps or private customer data.
- Never expose privileged Supabase keys in `NEXT_PUBLIC_*`.
- Apply RLS to all exposed tenant tables; require tenant membership and scoped foreign keys.
- Never use editable user metadata as an authorization source.
- Never use client-provided totals, discounts, restaurant IDs or model output as transactional authority.
- All order submissions must be idempotent and validated server-side.
- The AI may propose a draft; only an explicit customer action can confirm an order.
- Do not deploy, rotate secrets, change billing, or run destructive migrations without explicit approval.

## Completion report

Every PR must state: issue, changed files, behavior, tests actually run, unverified items, migration impact, security implications, and screenshots when applicable. Do not claim tests passed unless they ran.
