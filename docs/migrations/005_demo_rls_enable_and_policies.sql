-- FileZen demo migration:
-- 1) Enable RLS on all app tables
-- 2) Add demo-safe policies for anon/authenticated so student app works without full auth flow
-- 3) Hide sensitive token column in file_shares
--
-- Use for course demo environment only.

set search_path = app, public;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
alter table app.workspaces enable row level security;
alter table app.folders enable row level security;
alter table app.files enable row level security;
alter table app.file_versions enable row level security;
alter table app.file_metadata enable row level security;
alter table app.tags enable row level security;
alter table app.file_tags enable row level security;
alter table app.file_shares enable row level security;
alter table app.saved_views enable row level security;
alter table app.organizer_rules enable row level security;
alter table app.report_definitions enable row level security;
alter table app.report_runs enable row level security;
alter table app.workspace_settings enable row level security;
alter table app.scan_jobs enable row level security;
alter table app.audit_events enable row level security;
alter table app.app_settings enable row level security;

-- ---------------------------------------------------------------------------
-- Demo policies (full table access for anon/authenticated)
-- ---------------------------------------------------------------------------
drop policy if exists demo_rw_workspaces on app.workspaces;
create policy demo_rw_workspaces on app.workspaces for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_folders on app.folders;
create policy demo_rw_folders on app.folders for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_files on app.files;
create policy demo_rw_files on app.files for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_file_versions on app.file_versions;
create policy demo_rw_file_versions on app.file_versions for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_file_metadata on app.file_metadata;
create policy demo_rw_file_metadata on app.file_metadata for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_tags on app.tags;
create policy demo_rw_tags on app.tags for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_file_tags on app.file_tags;
create policy demo_rw_file_tags on app.file_tags for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_file_shares on app.file_shares;
create policy demo_rw_file_shares on app.file_shares for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_saved_views on app.saved_views;
create policy demo_rw_saved_views on app.saved_views for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_organizer_rules on app.organizer_rules;
create policy demo_rw_organizer_rules on app.organizer_rules for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_report_definitions on app.report_definitions;
create policy demo_rw_report_definitions on app.report_definitions for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_report_runs on app.report_runs;
create policy demo_rw_report_runs on app.report_runs for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_workspace_settings on app.workspace_settings;
create policy demo_rw_workspace_settings on app.workspace_settings for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_scan_jobs on app.scan_jobs;
create policy demo_rw_scan_jobs on app.scan_jobs for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_audit_events on app.audit_events;
create policy demo_rw_audit_events on app.audit_events for all to anon, authenticated using (true) with check (true);

drop policy if exists demo_rw_app_settings on app.app_settings;
create policy demo_rw_app_settings on app.app_settings for all to anon, authenticated using (true) with check (true);

-- ---------------------------------------------------------------------------
-- Sensitive column hardening
-- ---------------------------------------------------------------------------
revoke select (token) on table app.file_shares from anon, authenticated;
revoke update (token) on table app.file_shares from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Function hardening
-- ---------------------------------------------------------------------------
create or replace function app.set_updated_at()
returns trigger
language plpgsql
set search_path = app, public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;
