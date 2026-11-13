# HTL ServeAI

**Hope Theory Labs · Bangla-first restaurant SaaS**

ServeAI is an in-development restaurant SaaS for Bangladesh. The repository currently contains a **browser-only guest ordering UX prototype**, basic pricing/order-state functions, a starter multi-tenant SQL schema, documentation, and a CI configuration.

> **Status: Prototype / pre-production.** There is no working tenant onboarding, Supabase-backed authentication, persistent order API, kitchen integration, real AI waiter, or payment processing. The demo does not submit real orders. Do not use for live restaurant operations.

## Project navigation

- [Contributor guide](CONTRIBUTING.md)
- [Instructions for coding agents](AGENTS.md)
- [Product requirements](docs/PRD.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Roadmap](docs/ROADMAP.md)
- [Security policy](SECURITY.md)

## Run the prototype

Requires Node.js 22 and npm. From the repository root:

```bash
npm ci
npm run dev
```

Visit http://localhost:3000. Use `npm run typecheck`, `npm run test`, and `npm run build` for available checks. These are **not** integration tests of Supabase or order persistence.

## Technology direction

Next.js App Router · TypeScript · Supabase PostgreSQL/Auth/RLS (planned integration) · Gemini API (planned) · Vercel (planned).

## Next milestones

1. Obtain green GitHub Actions checks for the import/dependency branch.
2. Execute and review the SQL migration in isolated local Supabase.
3. Implement and test authentication, tenant onboarding, memberships and RLS policies.
4. Implement authoritative server-side ordering and kitchen workflows.
5. Integrate menu-grounded AI with explicit order confirmation and human handoff.

All changes should be issue-driven and submitted through reviewed pull requests. Never commit credentials or real customer data.

## Licensing

Copyright © Hope Theory Labs. A public repository is **not** automatically open-source. No reuse license is granted until maintainers select and publish one.
