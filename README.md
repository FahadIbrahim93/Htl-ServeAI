# HTL ServeAI

**Hope Theory Labs · Bangla-first restaurant SaaS**

ServeAI is an in-development restaurant SaaS for Bangladesh. This repository includes a **browser-only guest-ordering prototype**, domain pricing/order-state functions, a multi-tenant PostgreSQL schema, tenant-scoped read policies, controlled restaurant onboarding, owner login/dashboard code, documentation and automated CI.

> **Status: pre-production foundation (reviewed 14 November 2026).** Owner sign-up, sign-in, restaurant onboarding and a tenant-scoped dashboard were merged in [#15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15). They are covered by database and HTTP Auth tests, but **not yet by browser end-to-end tests** ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)). Nothing is deployed. Staff invitations, order persistence, the kitchen display, a real AI waiter and payments are not implemented. The guest demo at `/` does not submit real orders. Do not use this for live restaurant operations.

## Project navigation

- [Contributor guide](CONTRIBUTING.md)
- [Instructions for coding agents](AGENTS.md)
- [Product requirements](docs/PRD.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Database security model](docs/DATABASE_SECURITY.md)
- [Roadmap](docs/ROADMAP.md)
- [Security policy](SECURITY.md)

## Run the prototype

Requires Node.js 22 and npm. From the repository root:

```bash
npm ci
npm run dev
```

Visit http://localhost:3000 for the guest prototype. It runs without any Supabase settings.

The owner pages (`/login`, `/onboarding`, `/dashboard`) need a Supabase project. For local work, start a disposable stack with the Supabase CLI (`supabase start`), then copy `.env.example` to `.env.local` and fill in the local URL and publishable key. Never point a development checkout at a hosted production project.

The application checks are `npm run typecheck`, `npm run test` and `npm run build`. They do **not** verify real restaurant order placement.

## Database validation

The canonical SQL is currently in `packages/db/migrations/` (four sequential files). GitHub Actions runs:

1. **CI** — npm installation, TypeScript typecheck, Vitest unit tests, Next.js build.
2. **Database RLS smoke tests** — temporary PostgreSQL 17 with simulated Supabase Auth roles.
3. **Local Supabase integration** — disposable Docker-based Supabase stack, actual local Auth schema and SQL migrations, simulated SQL identities and real HTTP sign-in/JWT/PostgREST authorization tests.

See [database security](docs/DATABASE_SECURITY.md) for the permission matrix and boundaries. No hosted Supabase database has been modified for ServeAI, and the repo is not wired to a staging/production deployment.

## Next milestones

1. Browser end-to-end tests for owner sign-up, sign-in, session refresh, sign-out, onboarding, quotas and cross-tenant denial, against local Supabase in CI ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
2. Staff invitations and role authorization ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)). The role policy is proposed in [#16](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/16); the invitation backend is not started.
3. Staging environment and release gates ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)). Not started, and needs maintainer approval before any hosted project is created.
4. Server-side order validation, idempotent transactions, kitchen tickets and human handoff.
5. A menu-grounded Bangla/English AI waiter with explicit guest confirmation.

Licensing and contribution terms are tracked in [#6](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/6).

All work must be issue-driven and reviewed through pull requests. Never commit credentials or real customer data.

## Licensing

Copyright © Hope Theory Labs. A public repository is **not** automatically open-source. No reuse license is granted until maintainers select and publish one.
