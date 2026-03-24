-- FileZen initial database schema for Supabase PostgreSQL
-- Authentication and user profiles intentionally excluded.
-- This schema focuses on core file management, folder hierarchy, metadata,
-- reports, automation rules, settings, and operational history.

create extension if not exists pgcrypto;

create schema if not exists app;

set search_path = app, public;

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

create or replace function app.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Workspaces
-- ---------------------------------------------------------------------------

create table if not exists app.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  status text not null default 'active'
    check (status in ('active', 'archived')),
  is_default boolean not null default false,
  storage_quota_bytes bigint,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint workspaces_name_not_blank check (btrim(name) <> '')
);

create unique index if not exists uq_workspaces_default_true
  on app.workspaces (is_default)
  where is_default = true;

-- ---------------------------------------------------------------------------
-- Folder tree
-- ---------------------------------------------------------------------------

create table if not exists app.folders (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  parent_folder_id uuid references app.folders (id) on delete cascade,
  name text not null,
  path_cache text not null,
  depth integer not null default 0 check (depth >= 0),
  color_hex text,
  notes text,
  is_system boolean not null default false,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  archived_at timestamptz,
  constraint folders_name_not_blank check (btrim(name) <> '')
);

create unique index if not exists uq_folders_root_name
  on app.folders (workspace_id, lower(name))
  where parent_folder_id is null;

create unique index if not exists uq_folders_child_name
  on app.folders (workspace_id, parent_folder_id, lower(name))
  where parent_folder_id is not null;

create index if not exists idx_folders_workspace_parent
  on app.folders (workspace_id, parent_folder_id);

create index if not exists idx_folders_workspace_path
  on app.folders (workspace_id, path_cache);

-- ---------------------------------------------------------------------------
-- Files
-- ---------------------------------------------------------------------------

create table if not exists app.files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  folder_id uuid references app.folders (id) on delete set null,
  name text not null,
  original_name text,
  extension text,
  mime_type text,
  media_category text not null default 'other'
    check (media_category in (
      'document', 'image', 'video', 'audio', 'archive', 'code', 'spreadsheet',
      'presentation', 'pdf', 'system', 'other'
    )),
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  checksum_sha256 text,
  storage_bucket text not null default 'filezen-assets',
  storage_object_path text not null,
  storage_provider text not null default 'supabase'
    check (storage_provider in ('supabase', 's3', 'gcs', 'local')),
  storage_class text,
  description text,
  is_favorite boolean not null default false,
  is_locked boolean not null default false,
  is_archived boolean not null default false,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  last_accessed_at timestamptz,
  indexed_at timestamptz,
  current_version_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint files_name_not_blank check (btrim(name) <> ''),
  constraint files_deleted_consistency check (
    (is_deleted = false and deleted_at is null)
    or (is_deleted = true and deleted_at is not null)
  )
);

create unique index if not exists uq_files_folder_name_active
  on app.files (workspace_id, folder_id, lower(name))
  where is_deleted = false and folder_id is not null;

create unique index if not exists uq_files_root_name_active
  on app.files (workspace_id, lower(name))
  where is_deleted = false and folder_id is null;

create unique index if not exists uq_files_storage_object_path
  on app.files (storage_bucket, storage_object_path);

create index if not exists idx_files_workspace_folder
  on app.files (workspace_id, folder_id);

create index if not exists idx_files_workspace_category
  on app.files (workspace_id, media_category);

create index if not exists idx_files_workspace_archived
  on app.files (workspace_id, is_archived, is_deleted);

create index if not exists idx_files_metadata_gin
  on app.files using gin (metadata);

-- ---------------------------------------------------------------------------
-- File versions and extracted metadata
-- ---------------------------------------------------------------------------

create table if not exists app.file_versions (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references app.files (id) on delete cascade,
  version_number integer not null check (version_number > 0),
  size_bytes bigint not null default 0 check (size_bytes >= 0),
  checksum_sha256 text,
  storage_bucket text not null,
  storage_object_path text not null,
  change_summary text,
  source text not null default 'upload'
    check (source in ('upload', 'edit', 'import', 'restore', 'sync')),
  created_at timestamptz not null default timezone('utc', now()),
  unique (file_id, version_number),
  unique (storage_bucket, storage_object_path)
);

alter table app.files
  add constraint fk_files_current_version
  foreign key (current_version_id)
  references app.file_versions (id)
  on delete set null;

create index if not exists idx_file_versions_file_id
  on app.file_versions (file_id, version_number desc);

create table if not exists app.file_metadata (
  file_id uuid primary key references app.files (id) on delete cascade,
  width_px integer,
  height_px integer,
  duration_ms bigint,
  page_count integer,
  word_count integer,
  language_code text,
  camera_model text,
  taken_at timestamptz,
  exif jsonb not null default '{}'::jsonb,
  fs_metadata jsonb not null default '{}'::jsonb,
  extracted_text tsvector,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_file_metadata_exif_gin
  on app.file_metadata using gin (exif);

create index if not exists idx_file_metadata_fs_metadata_gin
  on app.file_metadata using gin (fs_metadata);

create index if not exists idx_file_metadata_search
  on app.file_metadata using gin (extracted_text);

-- ---------------------------------------------------------------------------
-- Classification and sharing
-- ---------------------------------------------------------------------------

create table if not exists app.tags (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  name text not null,
  color_hex text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (workspace_id, lower(name))
);

create table if not exists app.file_tags (
  file_id uuid not null references app.files (id) on delete cascade,
  tag_id uuid not null references app.tags (id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (file_id, tag_id)
);

create table if not exists app.file_shares (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  file_id uuid references app.files (id) on delete cascade,
  folder_id uuid references app.folders (id) on delete cascade,
  share_type text not null
    check (share_type in ('public_link', 'internal_token')),
  access_level text not null
    check (access_level in ('viewer', 'editor', 'download')),
  token text not null unique,
  expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  constraint file_shares_target_check check (
    (file_id is not null and folder_id is null)
    or (file_id is null and folder_id is not null)
  )
);

-- ---------------------------------------------------------------------------
-- Search views and organizer rules
-- ---------------------------------------------------------------------------

create table if not exists app.saved_views (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  name text not null,
  filters jsonb not null default '{}'::jsonb,
  sort jsonb not null default '{}'::jsonb,
  layout text not null default 'list'
    check (layout in ('list', 'grid', 'timeline')),
  is_default boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_saved_views_workspace
  on app.saved_views (workspace_id, name);

create table if not exists app.organizer_rules (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  name text not null,
  description text,
  is_enabled boolean not null default true,
  priority integer not null default 100,
  trigger_type text not null
    check (trigger_type in ('on_upload', 'scheduled', 'manual', 'on_metadata_update')),
  match_mode text not null default 'all'
    check (match_mode in ('all', 'any')),
  conditions jsonb not null default '[]'::jsonb,
  actions jsonb not null default '[]'::jsonb,
  dry_run boolean not null default false,
  last_run_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_organizer_rules_workspace_enabled
  on app.organizer_rules (workspace_id, is_enabled, priority);

-- ---------------------------------------------------------------------------
-- Reports
-- ---------------------------------------------------------------------------

create table if not exists app.report_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  name text not null,
  description text,
  report_type text not null
    check (report_type in (
      'storage_usage', 'file_activity', 'integrity', 'duplicate_files',
      'media_breakdown', 'custom'
    )),
  filters jsonb not null default '{}'::jsonb,
  schedule_cron text,
  output_format text not null default 'json'
    check (output_format in ('json', 'csv', 'pdf')),
  is_enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists app.report_runs (
  id uuid primary key default gen_random_uuid(),
  report_definition_id uuid not null references app.report_definitions (id) on delete cascade,
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  status text not null
    check (status in ('queued', 'running', 'completed', 'failed', 'cancelled')),
  started_at timestamptz not null default timezone('utc', now()),
  finished_at timestamptz,
  output_storage_bucket text,
  output_storage_object_path text,
  summary jsonb not null default '{}'::jsonb,
  error_message text
);

create index if not exists idx_report_runs_definition
  on app.report_runs (report_definition_id, started_at desc);

create index if not exists idx_report_runs_workspace_status
  on app.report_runs (workspace_id, status, started_at desc);

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

create table if not exists app.app_settings (
  id boolean primary key default true,
  theme text not null default 'dark'
    check (theme in ('light', 'dark', 'system')),
  default_view text not null default 'dashboard'
    check (default_view in ('dashboard', 'explorer', 'organizer', 'reports')),
  date_format text not null default 'YYYY-MM-DD',
  time_format text not null default '24h'
    check (time_format in ('12h', '24h')),
  notifications_enabled boolean not null default true,
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint app_settings_single_row check (id = true)
);

create table if not exists app.workspace_settings (
  workspace_id uuid primary key references app.workspaces (id) on delete cascade,
  auto_sort_enabled boolean not null default false,
  duplicate_strategy text not null default 'version'
    check (duplicate_strategy in ('rename_with_timestamp', 'version', 'replace', 'skip', 'manual_review')),
  retention_days integer,
  archive_after_inactive_days integer,
  allowed_extensions jsonb not null default '[]'::jsonb,
  blocked_extensions jsonb not null default '[]'::jsonb,
  metadata_capture jsonb not null default '{}'::jsonb,
  security jsonb not null default '{}'::jsonb,
  ui jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- ---------------------------------------------------------------------------
-- Jobs and audit
-- ---------------------------------------------------------------------------

create table if not exists app.scan_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  job_type text not null
    check (job_type in ('index_workspace', 'reindex_files', 'metadata_extract', 'duplicate_detection')),
  status text not null
    check (status in ('queued', 'running', 'completed', 'failed', 'cancelled')),
  progress_percent numeric(5,2) not null default 0 check (progress_percent >= 0 and progress_percent <= 100),
  started_at timestamptz,
  finished_at timestamptz,
  result_summary jsonb not null default '{}'::jsonb,
  error_message text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_scan_jobs_workspace_status
  on app.scan_jobs (workspace_id, status, created_at desc);

create table if not exists app.audit_events (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid references app.workspaces (id) on delete cascade,
  actor_label text,
  entity_type text not null
    check (entity_type in (
      'workspace', 'folder', 'file', 'file_version', 'report', 'settings',
      'rule', 'share', 'scan_job'
    )),
  entity_id uuid,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_audit_events_workspace_created_at
  on app.audit_events (workspace_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

create trigger trg_workspaces_updated_at
before update on app.workspaces
for each row execute function app.set_updated_at();

create trigger trg_folders_updated_at
before update on app.folders
for each row execute function app.set_updated_at();

create trigger trg_files_updated_at
before update on app.files
for each row execute function app.set_updated_at();

create trigger trg_file_metadata_updated_at
before update on app.file_metadata
for each row execute function app.set_updated_at();

create trigger trg_tags_updated_at
before update on app.tags
for each row execute function app.set_updated_at();

create trigger trg_saved_views_updated_at
before update on app.saved_views
for each row execute function app.set_updated_at();

create trigger trg_organizer_rules_updated_at
before update on app.organizer_rules
for each row execute function app.set_updated_at();

create trigger trg_report_definitions_updated_at
before update on app.report_definitions
for each row execute function app.set_updated_at();

create trigger trg_app_settings_updated_at
before update on app.app_settings
for each row execute function app.set_updated_at();

create trigger trg_workspace_settings_updated_at
before update on app.workspace_settings
for each row execute function app.set_updated_at();

-- ---------------------------------------------------------------------------
-- Seed recommendation notes
-- ---------------------------------------------------------------------------
-- 1. Create one default workspace row for the app or for each logical vault.
-- 2. Create one workspace_settings row per workspace immediately after creation.
-- 3. Insert one app_settings row with id = true during bootstrap.
-- 4. Store binary file content in Supabase Storage, and only metadata/path here.
-- 5. Maintain folder path_cache and depth values in backend logic when moving folders.
