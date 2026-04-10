-- FileZen RLS baseline policies for Supabase.
-- This script assumes:
-- 1) JWT contains workspace_id claim for end users.
-- 2) Service-role key bypasses RLS for backend/admin tasks.
--
-- Apply after creating tables in docs/supabase_schema.sql.

set search_path = app, public;

-- Enable row-level security on core tenant tables.
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

-- Workspace access helper.
create or replace function app.jwt_workspace_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'workspace_id', '')::uuid
$$;

-- Workspaces
drop policy if exists workspaces_rw_same_workspace on app.workspaces;
create policy workspaces_rw_same_workspace
on app.workspaces
for all
using (id = app.jwt_workspace_id())
with check (id = app.jwt_workspace_id());

-- Folders
drop policy if exists folders_rw_same_workspace on app.folders;
create policy folders_rw_same_workspace
on app.folders
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

-- Files
drop policy if exists files_rw_same_workspace on app.files;
create policy files_rw_same_workspace
on app.files
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

-- Version rows inherit access through file->workspace ownership.
drop policy if exists file_versions_rw_by_parent_file on app.file_versions;
create policy file_versions_rw_by_parent_file
on app.file_versions
for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_versions.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_versions.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
);

-- Metadata rows inherit access through file->workspace ownership.
drop policy if exists file_metadata_rw_by_parent_file on app.file_metadata;
create policy file_metadata_rw_by_parent_file
on app.file_metadata
for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_metadata.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_metadata.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
);

-- Simple workspace-guard policies for remaining workspace-scoped tables.
drop policy if exists tags_rw_same_workspace on app.tags;
create policy tags_rw_same_workspace
on app.tags
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists file_shares_rw_same_workspace on app.file_shares;
create policy file_shares_rw_same_workspace
on app.file_shares
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists saved_views_rw_same_workspace on app.saved_views;
create policy saved_views_rw_same_workspace
on app.saved_views
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists organizer_rules_rw_same_workspace on app.organizer_rules;
create policy organizer_rules_rw_same_workspace
on app.organizer_rules
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists report_definitions_rw_same_workspace on app.report_definitions;
create policy report_definitions_rw_same_workspace
on app.report_definitions
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists report_runs_rw_same_workspace on app.report_runs;
create policy report_runs_rw_same_workspace
on app.report_runs
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists workspace_settings_rw_same_workspace on app.workspace_settings;
create policy workspace_settings_rw_same_workspace
on app.workspace_settings
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists scan_jobs_rw_same_workspace on app.scan_jobs;
create policy scan_jobs_rw_same_workspace
on app.scan_jobs
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

drop policy if exists audit_events_rw_same_workspace on app.audit_events;
create policy audit_events_rw_same_workspace
on app.audit_events
for all
using (workspace_id = app.jwt_workspace_id())
with check (workspace_id = app.jwt_workspace_id());

-- file_tags is linked through files/tags ownership checks.
drop policy if exists file_tags_rw_by_file_or_tag on app.file_tags;
create policy file_tags_rw_by_file_or_tag
on app.file_tags
for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_tags.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
  and exists (
    select 1
    from app.tags t
    where t.id = file_tags.tag_id
      and t.workspace_id = app.jwt_workspace_id()
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_tags.file_id
      and f.workspace_id = app.jwt_workspace_id()
  )
  and exists (
    select 1
    from app.tags t
    where t.id = file_tags.tag_id
      and t.workspace_id = app.jwt_workspace_id()
  )
);
