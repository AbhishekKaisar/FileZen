-- Phase A: one default workspace for FILEZEN_WORKSPACE_ID (no auth).
-- Run after 003_phase_a_anon_access.sql. Copy the id into --dart-define=FILEZEN_WORKSPACE_ID=...

set search_path = app, public;

insert into app.workspaces (id, name, slug, description, status, is_default)
values (
  'a0000000-0000-4000-8000-000000000001',
  'Default Vault',
  'default-vault',
  'Phase A demo workspace (faculty / local dev)',
  'active',
  true
)
on conflict (id) do nothing;

-- Optional: workspace_settings row (not required for basic file CRUD)
insert into app.workspace_settings (workspace_id)
values ('a0000000-0000-4000-8000-000000000001')
on conflict (workspace_id) do nothing;
