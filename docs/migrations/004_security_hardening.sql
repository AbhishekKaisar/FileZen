-- FileZen migration: security hardening for Supabase advisor warnings.
-- Run in Supabase SQL editor.

set search_path = app, public;

-- ---------------------------------------------------------------------------
-- 1) Ensure RLS is enabled for all workspace data tables
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
-- 2) Recreate helper function with fixed search_path
--    (addresses "Function Search Path Mutable")
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

-- ---------------------------------------------------------------------------
-- 3) Sensitive column hardening for file_shares
--    Hide raw token from anon/authenticated clients.
-- ---------------------------------------------------------------------------
revoke select (token) on table app.file_shares from anon, authenticated;
revoke update (token) on table app.file_shares from anon, authenticated;

-- Keep service_role/admin flows unaffected (service role bypasses RLS).

