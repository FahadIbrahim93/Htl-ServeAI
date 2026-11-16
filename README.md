# HTL ServeAI

**Hope Theory Labs · Bangla-first restaurant SaaS**

ServeAI is an in-development restaurant SaaS for Bangladesh. This repository includes a **browser-only guest-ordering prototype**, domain pricing/order-state functions, a multi-tenant PostgreSQL schema, tenant-scoped read policies, controlled restaurant onboarding, owner login/dashboard code, documentation and automated CI.

> **Status: pre-production foundation (reviewed 17 November 2026).** Owner sign-up, sign-in, restaurant onboarding and a tenant-scoped dashboard were merged in [#15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15). They have database/HTTP Auth tests and an initial 12-test browser suite (#28), but **full browser acceptance remains incomplete** ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)). A password-protected staging site is up for internal testing only (see below); nothing is in production. Staff invitations, order persistence, the kitchen display, a real AI waiter and payments are not implemented. The guest demo at `/` does not submit real orders. Do not use this for live restaurant operations.

## Staging (test only)

- **URL:** https://htl-serveai-hopetheorybd-2156s-projects.vercel.app
- **Access:** Vercel Authentication is on, so you must be signed in to the Hope Theory Labs Vercel account to open it.
- **Database:** the separate `htl-serveai-staging` Supabase project. Use test data only, never real restaurant or customer details.
- The guest demo at `/` is still simulated. Owner sign-up, sign-in, onboarding and the dashboard run against staging.

Details and the smoke-test checklist are in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md#staging-test-only).

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

| Variable | Where it comes from | Notes |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | `supabase status` locally, or the hosted project's API settings | Public. |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `supabase status` locally, or the hosted project's publishable key | Public. Never use a service-role or secret key here. |

The application checks are `npm run typecheck`, `npm run test` and `npm run build`. They do **not** verify real restaurant order placement.

## Database validation

The canonical SQL is the Supabase CLI migration history in [`supabase/migrations/`](supabase/migrations/) (four timestamped files), with local settings in `supabase/config.toml`. `supabase start` applies them to a disposable local stack, and `supabase db push` applies them to a linked hosted project. GitHub Actions runs:

1. **CI** — npm installation, TypeScript typecheck, Vitest unit tests, Next.js build.
2. **Database RLS smoke tests** — temporary PostgreSQL 17 with simulated Supabase Auth roles.
3. **Local Supabase integration** — disposable Docker-based Supabase stack, actual local Auth schema and SQL migrations, simulated SQL identities and real HTTP sign-in/JWT/PostgREST authorization tests. It reports on every pull request; the full stack only starts when `supabase/`, `packages/db/` or the workflow change.

See [database security](docs/DATABASE_SECURITY.md) for the permission matrix and boundaries. The four canonical migrations are applied to the separate staging Supabase project; production is not configured. The staging and production setup is described in [deployment](docs/DEPLOYMENT.md).

## Next milestones

1. Complete browser acceptance beyond the merged 12-test suite, including account-cap and session-lifecycle coverage (follow-up PRs #32/#34 in review), against local Supabase in CI ([#17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17)).
2. Staff invitations and role authorization ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)). The role policy merged in [#16](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/16); the invitation backend is in draft [#26](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/26).
3. Staging and production environments and release gates ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)). The migration history and deployment runbook are in place; see [deployment](docs/DEPLOYMENT.md).
4. Server-side order validation, idempotent transactions, kitchen tickets and human handoff.
5. A menu-grounded Bangla/English AI waiter with explicit guest confirmation.

The licence decision (public, all rights reserved) was made in [#6](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/6) and merged in [#18](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/18).

All work must be issue-driven and reviewed through pull requests. Never commit credentials or real customer data.

## Licence

Copyright © 2026 Fahad Ibrahim / Hope Theory Labs. All rights reserved.

This repository is public so the work can be seen. It is **not** open source. You may not use, copy, modify, distribute, sublicense or deploy any part of it without prior written permission. External contributions are not accepted. See [LICENSE](LICENSE).
