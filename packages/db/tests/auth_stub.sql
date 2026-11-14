-- CI-only minimal imitation of Supabase Auth identity.
-- NEVER apply to a real Supabase project: Supabase already owns the auth schema.
create schema if not exists auth;
create role anon nologin;
create role authenticated nologin;
create table auth.users (id uuid primary key, is_anonymous boolean not null default false, email text, email_confirmed_at timestamptz);

create function auth.uid() returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
