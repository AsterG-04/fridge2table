-- Fridge2Table — Supabase "ingredients" table schema + RLS policies.
-- Run each section in the Supabase SQL Editor (Project -> SQL Editor -> New query).
--
-- History:
--   1. Table created (Phase 10) with no user scoping — every account
--      synced through one shared, unscoped table.
--   2. This migration adds a user_id column and locks the table down so
--      each authenticated user can only ever see/write their own rows.

-- 1. Add the user_id column (safe to re-run; errors harmlessly if it
--    already exists on some Postgres versions, so check first if unsure).
alter table public.ingredients add column user_id text;

-- 2. Remove the old policy that let anyone with the publishable key read
--    and write every row.
drop policy if exists "Allow anon full access" on public.ingredients;

-- 3. Only the authenticated owner of a row can read or write it.
-- auth.uid() is the signed-in user's id, taken from their verified JWT —
-- this is enforced by Postgres itself, not just trusted client input.
create policy "Users can only access their own ingredients"
on public.ingredients
for all
to authenticated
using (auth.uid()::text = user_id)
with check (auth.uid()::text = user_id);

-- 4. Make sure PostgREST picks up the schema change immediately instead
--    of waiting for its next periodic cache refresh.
select pg_notify('pgrst', 'reload schema');

-- Note: existing rows (synced before this migration) have user_id = NULL.
-- auth.uid()::text = NULL is never true in SQL, so those rows become
-- permanently invisible/inaccessible to every account under the new
-- policy — the cloud-side equivalent of the local backend's "orphaned"
-- rows. They still exist in the table and can be reassigned manually:
--   update public.ingredients set user_id = '<uuid>' where user_id is null;


-- ============================================================================
-- pantry_items — closing a "table publicly accessible" Supabase security
-- alert (2026-07-30).
--
-- pantry_items is the FastAPI backend's own table (backend/app/models.py),
-- created by SQLAlchemy's Base.metadata.create_all() over the same
-- Supabase Postgres instance the backend's DATABASE_URL (Session Pooler
-- string) points at. It was never given RLS, unlike `ingredients` above --
-- SQLAlchemy has no concept of Supabase's RLS conventions, it just creates
-- a plain table. Because that table lives in the `public` schema of a
-- Supabase project, Supabase's auto-generated PostgREST API exposes it to
-- anyone with the project URL + anon key by default, completely bypassing
-- the backend's own JWT auth (see backend/app/auth.py) -- PostgREST talks
-- straight to Postgres and has no idea the FastAPI layer exists.
--
-- Fix: enable RLS with *no* policies. The backend connects via the Session
-- Pooler as the `postgres` role, which owns this table and has BYPASSRLS
-- in Supabase's role model -- enabling RLS does not affect it at all. It
-- only affects PostgREST's `anon`/`authenticated` roles, which own
-- nothing and don't bypass RLS -- with zero policies defined, those roles
-- see and can write zero rows. Since nothing should ever access this
-- table except the backend's own direct connection, "no policies" is the
-- correct end state, not a placeholder to fill in later.
alter table public.pantry_items enable row level security;

select pg_notify('pgrst', 'reload schema');
