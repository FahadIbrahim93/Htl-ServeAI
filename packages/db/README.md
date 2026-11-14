# Database tests

The migrations themselves live in [`supabase/migrations/`](../../supabase/migrations/), which is the single source of truth for the schema. This folder holds the tests that run against them:

- `tests/auth_stub.sql` sets up simulated Supabase Auth roles for plain PostgreSQL.
- `tests/rls_isolation.sql` and `tests/onboarding.sql` run in the **Database RLS smoke tests** workflow.
- `tests/supabase_integration.sql` and `tests/http_auth_integration.mjs` run in the **Local Supabase integration** workflow against a disposable `supabase start` stack.

To add a schema change, run `supabase migration new <name>` from the repository root, write the SQL there, and add or update a test here.
