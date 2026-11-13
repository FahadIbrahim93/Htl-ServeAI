# Contributing to HTL ServeAI

We welcome maintainable, tested changes from authorized collaborators and coding agents.

## Before starting

1. Read README.md, AGENTS.md, docs/PRD.md, docs/ARCHITECTURE.md, and SECURITY.md.
2. Open or claim a GitHub issue with acceptance criteria.
3. Confirm the feature's owner, scope, dependencies, and affected tenants/data.
4. Create a branch from updated main: `feat/<issue>-short-name`, `fix/<issue>-short-name`, or `docs/<issue>-short-name`.
5. Never work directly on main.

## Development workflow

- Use Node.js LTS and a pinned dependency lockfile once the application is imported.
- Copy `.env.example` to `.env.local`; never commit `.env.local`.
- Use local Supabase for schema and RLS tests. Do not run migrations against production without approval.
- Keep business logic server-side; validate every untrusted input.
- Use integer monetary units; never trust model-generated prices or totals.
- Include tests for behavior, permissions, failures, and tenant isolation.
- Update documentation for changes to behavior, APIs, database schema or configuration.

## Pull request checklist

- [ ] Issue linked and scope explained
- [ ] No credentials, personal data or generated build artifacts
- [ ] Tests added/updated and executed (or explicitly marked unverified)
- [ ] Typecheck/lint/build results recorded
- [ ] Tenant boundaries and RLS reviewed
- [ ] Database migration reviewed for backward compatibility
- [ ] Screenshots for UI changes
- [ ] Documentation updated
- [ ] Reviewer requested

Use Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.

## Reviews and merge policy

At least one human maintainer should review security-sensitive changes; never self-approve an AI-generated change. CI must pass before merging. Prefer squash merges. Do not force-push main. Rollback procedures are required for high-risk changes.

## External contributions and license

Public visibility does not imply an open-source license. Maintainers must settle the project license and contribution terms before accepting external contributions.
