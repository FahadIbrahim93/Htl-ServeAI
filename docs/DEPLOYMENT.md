# Deployment

This is the runbook for hosting ServeAI. It covers environments, the Supabase migration history, Vercel settings, Auth, and the release flow. Pricing and plan limits were checked on 15 November 2026; recheck them before relying on them.

## Current status

| Item | Status |
| --- | --- |
| Migration history | Done. `supabase/migrations/` is canonical and CI applies exactly those files. |
| `main` protection | Done. Pull request plus green `verify` and `postgres-rls-smoke` checks; no force-push or deletion. |
| Hosted Supabase staging | Done. `htl-serveai-staging` (ref `ipwdraxmmrlosbqgipda`, Singapore, Free plan), migrations `20261115000001`–`20261115000004` applied. |
| Hosted Supabase production | Not created. The account is at its free limit of two active projects; production needs Fahad's approval. |
| Vercel project | Done, staging only. `htl-serveai` (Hobby), linked to this repository; every environment points at staging. |

## Environments

| Environment | App | Database | Purpose |
| --- | --- | --- | --- |
| Local | `npm run dev` | Disposable stack from `supabase start` | Day-to-day development. Never point a checkout at a hosted production project. |
| Preview | Vercel URL for each pull request and for `main` | `htl-serveai-staging` | Review and smoke-test. No real restaurant or customer data. |
| Production | Vercel production URL, promoted by hand | `htl-serveai-prod` | Live traffic, only after the preview is checked. |

Staging and production are two separate Supabase projects with their own URLs, keys, Auth settings and data. Never reuse a Supabase project that belongs to another product.

## Supabase

**Projects.** `htl-serveai-staging` and `htl-serveai-prod`, region `ap-southeast-1` (Singapore, closest to Bangladesh), Free plan.

**Free plan limits.** Two active projects per account across all organisations you own or administer; 500 MB database and 50,000 monthly active users per project; no automatic backups; a project pauses after about a week of low activity. A paused project does not count toward the limit and can be restored.

**Applying migrations.** From a clean checkout of `main`:

```bash
supabase link --project-ref <staging-ref>
supabase db push --dry-run   # review the planned statements
supabase db push
supabase migration list      # local and remote must match
```

Production follows the same steps against `<prod-ref>`, after a fresh `pg_dump` backup and Fahad's approval. Never edit a migration that has been applied to a hosted project; add a new one. Never run migrations from a Vercel build. Rollback means restoring the backup and rolling the app back.

After each push, check the Security Advisor in the Supabase dashboard (or `get_advisors`) and confirm Row Level Security is on for every table in `public`.

**Auth, per project** (Authentication → Sign In / Providers and URL Configuration):

- Email provider on, **Confirm email** on, minimum password length 8.
- Site URL: that environment's app URL.
- Redirect URLs: only that environment's exact `/auth/callback` URL. Do not add a `*.vercel.app` wildcard, which would let any Vercel app finish a login redirect. For staging, the narrowest acceptable pattern is the project's own preview pattern, for example `https://htl-serveai-*-<team-slug>.vercel.app/auth/callback`.
- Keep the built-in Auth rate limits. Add captcha (Cloudflare Turnstile or hCaptcha) before open sign-up, and custom SMTP before inviting real restaurant users, because built-in email is heavily rate-limited.

## Vercel

- One project, `htl-serveai`, on the existing Hobby account, linked to this repository.
- Framework Next.js, Root Directory `apps/web`, with "Include files outside the root directory" on so the workspace lockfile is visible.
- Environment variables:

| Variable | Production | Preview and Development |
| --- | --- | --- |
| `NEXT_PUBLIC_SUPABASE_URL` | prod project URL | staging project URL |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | prod publishable key | staging publishable key |

- Never add a service-role or secret key to Vercel, and never give one a `NEXT_PUBLIC_` name.
- Turn off "Auto-assign Custom Production Domains" so a merge does not go live by itself. Promote a checked deployment by hand; instant rollback is available.
- Keep Vercel Authentication on for preview deployments.

## Staging (test only)

Live since 16 November 2026. There is no production database yet, so the Vercel project's Production, Preview and Development environments all use the staging Supabase URL and publishable key. Merging to `main` redeploys staging; that is expected and is not a production release.

| Item | Value |
| --- | --- |
| Staging URL | https://htl-serveai-hopetheorybd-2156s-projects.vercel.app |
| Vercel project | `htl-serveai` (`prj_H5QmuPulMdCcTAu8K7Xx7aohL4i6`), Root Directory `apps/web`, Node 22 |
| Supabase project | `htl-serveai-staging` (`ipwdraxmmrlosbqgipda`) |
| Access | Vercel Authentication on for this URL; sign in to the team's Vercel account to view. **The project alias `htl-serveai.vercel.app` is public** (checked 18 Nov 2026) and uses the same staging database; see [#42](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/42) |

**Auth URL configuration for staging** (Supabase dashboard → Authentication → URL Configuration):

- Site URL: `https://htl-serveai-hopetheorybd-2156s-projects.vercel.app`
- Redirect URLs:
  - `https://htl-serveai-hopetheorybd-2156s-projects.vercel.app/auth/callback`
  - `https://htl-serveai-*-hopetheorybd-2156s-projects.vercel.app/auth/callback` (pull request previews)

Until these are set, confirmation emails fall back to `http://localhost:3000`.

**Smoke test after each staging deploy:**

1. `/` returns 200 and shows the "UX prototype" label.
2. `/login` renders the owner sign-in form.
3. Signed out, `/dashboard` and `/onboarding` redirect to `/login`.
4. An anonymous REST read of any `public` table with the publishable key is refused (`42501`), and so is an anonymous call to `rpc/create_restaurant`.
5. A new sign-up shows "Check your email to confirm your account before signing in", and the confirmation link returns to the staging `/auth/callback`.

When production is created, give it its own Supabase project and switch the Vercel Production environment variables to it, as in the table above.

**Plan note.** Vercel Hobby is for personal and non-commercial use. Internal testing is fine; a restaurant pilot or any public, commercial use needs Vercel Pro ($20 per month). Supabase Pro (from $25 per month) adds daily backups and stops pausing.

## Release flow

1. Open a pull request. Required checks: `verify`, `postgres-rls-smoke`; `supabase-local` also runs and reports on every pull request.
2. Review the Vercel preview against staging.
3. Merge to `main` with a merge commit.
4. If the change includes migrations, push them to staging, check advisors, smoke-test.
5. With Fahad's approval: back up production, push the same migrations, promote the production deployment.
6. Smoke-test the production URL.

**Smoke test.** Home page returns 200 and is labelled as a prototype; `/login` renders; a sign-up with a test address shows "Check your email to confirm your account"; an anonymous REST read of `tenants` returns no rows; `/dashboard` redirects a signed-out visitor to `/login`.

## Before a public launch or pilot

From issue #5 and [operations](OPERATIONS.md): browser end-to-end tests (#17), captcha and custom SMTP, a free uptime monitor and error tracker, a rehearsed backup restore on staging, written rollback steps, checked domains and TLS, and the paid plans above.
