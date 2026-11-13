# HTL ServeAI

**Hope Theory Labs · Bangla-first restaurant SaaS**

ServeAI is an in-development multi-tenant restaurant operations platform for Bangladesh: QR ordering, bilingual menus, kitchen display, staff workflows, billing, and a menu-grounded AI waiter.

> **Status: Pre-production.** Source documentation and implementation plans are available; the complete application has not been uploaded or verified yet. Do not use for live restaurant orders.

## Project navigation

- [Contributor guide](CONTRIBUTING.md)
- [Instructions for coding agents](AGENTS.md)
- [Product requirements](docs/PRD.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Roadmap](docs/ROADMAP.md)
- [Security policy](SECURITY.md)

## Technology direction

Next.js App Router · TypeScript · Supabase PostgreSQL/Auth/RLS · Tailwind CSS · Gemini API · Vercel · GitHub Actions.

## Engineering priorities

1. Upload and validate the Phase 1 application, migration and test files.
2. Establish reproducible builds with a committed lockfile.
3. Verify multi-tenant isolation and restaurant onboarding.
4. Implement QR ordering, kitchen and staff workflows.
5. Add restricted AI waiter tools and explicit order confirmation.

All changes should be issue-driven and submitted through focused pull requests. Never commit credentials or real customer data.

## Licensing

Copyright © Hope Theory Labs. A public repository is **not** automatically open-source. No reuse license is granted until maintainers select and publish one.
