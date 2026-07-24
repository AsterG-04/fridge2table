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
