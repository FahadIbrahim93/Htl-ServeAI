# ServeAI disposable browser E2E suite

This is a **16-test subset** of [Issue #17](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/17). The remaining requirements include account-cap behavior after three creations, multiple JWT expiry-window refresh checks, revoked-refresh-token handling, and an env-unset guest smoke test. The tests include friendly unknown-account/wrong-password errors, missing/invalid callback feedback, sign-out cookie removal, tampered-session denial on both protected routes, duplicate slugs and cross-tenant PostgREST access checked using a token read from the browser session. Do not claim the issue is complete until all 15 acceptance scenarios pass (test count alone does not prove coverage).

The suite is **hard-gated** to `E2E_DISPOSABLE_ONLY=1` and local HTTP origins; no hosted Supabase project, real customers or production credentials may be used.

Local setup: start `supabase start`, run `npm ci` at the root, and `npm ci --prefix tests/e2e`. Configure the local `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, run `npm run build && npm run start` in one terminal, then `E2E_DISPOSABLE_ONLY=1 npm run test:e2e --prefix tests/e2e`.

CI uses a disposable Supabase project with email confirmations disabled in its temporary local config. The workflow records cookie **flags only**, never cookie values, JWTs or service-role keys. Playwright traces are disabled because they capture passwords, Authorization headers and session cookies. HTML reports and screenshots are uploaded only upon failure, with short retention; treat those artifacts as sensitive too.
