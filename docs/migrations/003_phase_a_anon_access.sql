-- Phase A (no auth): allow the Supabase anon key to read/write app tables for local demos.
-- Run AFTER docs/supabase_schema.sql and docs/migrations/002_organizer_block_day_columns.sql.
-- SECURITY: Replace with real RLS + auth before any production deployment.

set search_path = app, public;

-- API access to schema `app` (also add "app" under Project Settings → Data API → Exposed schemas).
grant usage on schema app to anon, authenticated, service_role;

grant select, insert, update, delete on all tables in schema app to anon, authenticated;
grant usage, select on all sequences in schema app to anon, authenticated;

alter default privileges in schema app
  grant select, insert, update, delete on tables to anon, authenticated;
alter default privileges in schema app
  grant usage, select on sequences to anon, authenticated;

-- Row Level Security: permissive policies for anon (dev only)
alter table app.workspaces enable row level security;
alter table app.folders enable row level security;
alter table app.files enable row level security;

drop policy if exists "phase_a_anon_all_workspaces" on app.workspaces;
create policy "phase_a_anon_all_workspaces"
  on app.workspaces
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "phase_a_anon_all_folders" on app.folders;
create policy "phase_a_anon_all_folders"
  on app.folders
  for all
  to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "phase_a_anon_all_files" on app.files;
create policy "phase_a_anon_all_files"
  on app.files
  for all
  to anon, authenticated
  using (true)
  with check (true);
