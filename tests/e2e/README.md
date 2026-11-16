# ServeAI disposable browser E2E suite

This is an **initial 12-scenario subset** of [Issue #17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17). The remaining requirements include account-cap behavior after three creations, multiple JWT expiry-window refresh checks, cookie tampering, and complete callback error UX. The twelve scenarios include duplicate slugs and cross-tenant PostgREST access checked using a token read from the browser session. Do not claim the issue is complete until all 15 acceptance scenarios pass.

The suite is **hard-gated** to `E2E_DISPOSABLE_ONLY=1` and local HTTP origins; no hosted Supabase project, real customers or production credentials may be used.

Local setup: start `supabase start`, run `npm ci` at the root, and `npm ci --prefix tests/e2e`. Configure the local `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, run `npm run build && npm run start` in one terminal, then `E2E_DISPOSABLE_ONLY=1 npm run test:e2e --prefix tests/e2e`.

CI uses a disposable Supabase project with email confirmations disabled in its temporary local config. The workflow records cookie **flags only**, never cookie values, JWTs or service-role keys. Generated reports and traces should be treated as sensitive test artifacts and uploaded only upon failure, with short retention.

Public pages have a separate database-free smoke suite. With both Supabase public environment variables unset, build the app, then run `npm exec --prefix tests/e2e -- playwright test --config tests/e2e/public.config.mjs` from the repository root. It starts its own production server and checks `/` and `/login`; the `Public pages without Supabase` workflow runs the same check.
