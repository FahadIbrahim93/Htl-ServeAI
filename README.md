# HTL ServeAI

**Hope Theory Labs · Bangla-first restaurant SaaS**

ServeAI is an in-development restaurant SaaS for Bangladesh. This repository includes a **browser-only guest-ordering prototype**, domain pricing/order-state functions, a multi-tenant PostgreSQL schema, tenant-scoped read policies, controlled restaurant onboarding, owner login/dashboard code, documentation and automated CI.

> **Status: Pre-production foundation.** The Next.js login, onboarding form, and tenant-scoped dashboard code has been added, but a full browser end-to-end test and deployment validation are still pending. Order persistence, kitchen integration, a real AI waiter, and payments are not implemented. The demo does not submit real orders. Do not use for live restaurant operations.

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

Visit http://localhost:3000. The available application checks are `npm run typecheck`, `npm run test`, and `npm run build`. They do **not** verify real restaurant order placement.

## Database validation

The canonical SQL is currently in `packages/db/migrations/` (four sequential files). GitHub Actions runs:

1. **CI** — npm installation, TypeScript typecheck, Vitest unit tests, Next.js build.
2. **Database RLS smoke tests** — temporary PostgreSQL 17 with simulated Supabase Auth roles.
3. **Local Supabase integration** — disposable Docker-based Supabase stack, actual local Auth schema and SQL migrations, simulated SQL identities and real HTTP sign-in/JWT/PostgREST authorization tests.

See [database security](docs/DATABASE_SECURITY.md) for the permission matrix and boundaries. No hosted Supabase database has been modified for ServeAI, and the repo is not wired to a staging/production deployment.

## Next milestones

1. Complete browser E2E and staging verification for the new Next.js Supabase SSR login/onboarding dashboard.
2. Add staff branch permissions, invitation controls, IP-level anti-abuse defenses and audit reviews (tenant creation already has account quotas).
3. Implement server-side order validation, idempotent transactions, kitchen tickets and human handoff.
4. Integrate a menu-grounded Bangla/English AI waiter with explicit guest confirmation.
5. Configure staging, observability, backup recovery and release security gates.

All work must be issue-driven and reviewed through pull requests. Never commit credentials or real customer data.

## Licence

Copyright © 2026 Fahad Ibrahim / Hope Theory Labs. All rights reserved.

This repository is public so the work can be seen. It is **not** open source. You may not use, copy, modify, distribute, sublicense or deploy any part of it without prior written permission. External contributions are not accepted. See [LICENSE](LICENSE).
