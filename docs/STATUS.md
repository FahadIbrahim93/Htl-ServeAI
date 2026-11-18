# Status — 18 November 2026

Snapshot of `main` at `92f8b60`. Written from the code, git history, CI runs, GitHub alerts and live URLs on this date. For the capability-by-capability table see [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

## What is live

**Nothing is in production.** ServeAI is a pre-production foundation.

- **Staging (internal testing):** https://htl-serveai-hopetheorybd-2156s-projects.vercel.app, behind Vercel login, backed by the Supabase project `htl-serveai-staging`. Owner sign-up, sign-in, onboarding and the dashboard run there with test data only.
- **Public alias:** https://htl-serveai.vercel.app is reachable without a login and is wired to the same staging database. This contradicts the earlier docs. Details and the decision it needs are in [#42](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/42).
- The guest demo at `/` is simulated and creates no orders.
- Fahad still has to set the staging Supabase Auth Site URL and Redirect URLs so confirmation emails return to the staging callback ([#5](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/5)).

## Recent work

| PR | Date | What |
| --- | --- | --- |
| [#36](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/36) | 17 Nov | Docs reconciled with merged evidence |
| [#32](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/32), [#34](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/34), [#38](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/38), [#40](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/40) | 17 Nov | Browser tests: auth failures, account cap, session expiry and refresh, public pages without Supabase settings |
| [#29](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/29) | 16 Nov | Staging link and runbook |
| [#28](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/28), [#27](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/27) | 16 Nov | Real-browser owner auth suite; safe login error messages |
| [#21](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/21) | 14 Nov | Persistent Supabase migration history and deployment runbook |
| [#15](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/15) | 13 Nov | Owner login, onboarding, dashboard, creation quotas |

## Open pull requests

| PR | State | Notes |
| --- | --- | --- |
| [#26](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/26) | Draft, 44 commits behind `main` | Staff invitation migration and tests (#4). Checks were green when last run |
| [#41](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/41) | Open, stacked on #26 | Requires explicit membership to revoke an invitation. Two review points open: the "Invitation not found" error reveals whether an invitation exists, and there is no test that a manager cannot revoke a manager invitation |
| [#30](https://github.com/FahadIbrahim93/Htl-ServeAI/pull/30) | Open, 20 commits behind `main` | Dependabot: Next 15.5.29 to 16.4.6. Its lockfile also clears the four postcss alerts |

## Checks

- On 18 Nov 2026 `typecheck`, `test` and `build` pass locally on `main`; CI is green.
- Required by the ruleset: `verify`, `postgres-rls-smoke`. Also run: `supabase-local`, `browser-e2e`, `Public pages without Supabase`.
- Browser suite: 19 tests plus a 2-test public smoke. Full #17 acceptance is not confirmed.

## Security alerts

Four open Dependabot alerts, all `postcss` in the root lockfile: two high (ids 3 and 4) and two medium (2 and 5). Patched in 8.5.10 to 8.5.23. Merging #30 resolves all four ([#43](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/43)).

## Known gaps

- Staff invitations are not on `main` ([#4](https://github.com/FahadIbrahim93/Htl-ServeAI/issues/4)).
- No server order API, kitchen display, payments or real AI waiter.
- No production Supabase project; the account is at the free two-project limit.
- Required checks do not include `supabase-local` or `browser-e2e`.
- Vercel Hobby is non-commercial; a pilot needs a paid plan, which is Fahad's decision.
