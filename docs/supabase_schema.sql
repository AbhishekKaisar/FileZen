-- FileZen initial database schema for Supabase PostgreSQL
-- Designed for a real file management app with folders, files, metadata,
-- reports, settings, automation rules, collaboration, and auditability.

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

create or replace function app.current_user_id()
returns uuid
language sql
stable
as $$
  select auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- Profiles and workspaces
-- ---------------------------------------------------------------------------

create table if not exists app.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  timezone text not null default 'UTC',
  locale text not null default 'en-US',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists app.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  description text,
  owner_user_id uuid not null references app.profiles (id) on delete restrict,
  plan_tier text not null default 'free'
    check (plan_tier in ('free', 'pro', 'team', 'enterprise')),
  status text not null default 'active'
    check (status in ('active', 'archived', 'suspended')),
  storage_quota_bytes bigint,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists app.workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  user_id uuid not null references app.profiles (id) on delete cascade,
  role text not null
    check (role in ('owner', 'admin', 'editor', 'viewer')),
  status text not null default 'active'
    check (status in ('invited', 'active', 'disabled')),
  invited_by uuid references app.profiles (id) on delete set null,
  joined_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (workspace_id, user_id)
);

create index if not exists idx_workspace_members_user_id
  on app.workspace_members (user_id);

create or replace function app.is_workspace_member(p_workspace_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from app.workspace_members wm
    where wm.workspace_id = p_workspace_id
      and wm.user_id = auth.uid()
      and wm.status = 'active'
  );
$$;

-- ---------------------------------------------------------------------------
-- Folder tree
-- ---------------------------------------------------------------------------

create table if not exists app.folders (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  parent_folder_id uuid references app.folders (id) on delete cascade,
  created_by uuid references app.profiles (id) on delete set null,
  name text not null,
  path_cache text not null,
  depth integer not null default 0 check (depth >= 0),
  color_hex text,
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
-- Files and versions
-- ---------------------------------------------------------------------------

create table if not exists app.files (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  folder_id uuid references app.folders (id) on delete set null,
  created_by uuid references app.profiles (id) on delete set null,
  updated_by uuid references app.profiles (id) on delete set null,
  name text not null,
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
  is_favorite boolean not null default false,
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

create table if not exists app.file_versions (
  id uuid primary key default gen_random_uuid(),
  file_id uuid not null references app.files (id) on delete cascade,
  version_number integer not null check (version_number > 0),
  created_by uuid references app.profiles (id) on delete set null,
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
-- Tags, favorites, shares
-- ---------------------------------------------------------------------------

create table if not exists app.tags (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  name text not null,
  color_hex text,
  created_by uuid references app.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (workspace_id, lower(name))
);

create table if not exists app.file_tags (
  file_id uuid not null references app.files (id) on delete cascade,
  tag_id uuid not null references app.tags (id) on delete cascade,
  created_by uuid references app.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (file_id, tag_id)
);

create table if not exists app.file_shares (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  file_id uuid references app.files (id) on delete cascade,
  folder_id uuid references app.folders (id) on delete cascade,
  created_by uuid not null references app.profiles (id) on delete cascade,
  share_type text not null
    check (share_type in ('internal', 'public_link')),
  access_level text not null
    check (access_level in ('viewer', 'editor', 'download')),
  token text unique,
  expires_at timestamptz,
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
  created_by uuid not null references app.profiles (id) on delete cascade,
  name text not null,
  scope text not null default 'private'
    check (scope in ('private', 'workspace')),
  filters jsonb not null default '{}'::jsonb,
  sort jsonb not null default '{}'::jsonb,
  layout text not null default 'list'
    check (layout in ('list', 'grid', 'timeline')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_saved_views_workspace
  on app.saved_views (workspace_id, created_by);

create table if not exists app.organizer_rules (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  created_by uuid not null references app.profiles (id) on delete cascade,
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
-- Reports and report runs
-- ---------------------------------------------------------------------------

create table if not exists app.report_definitions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  created_by uuid not null references app.profiles (id) on delete cascade,
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
  started_by uuid references app.profiles (id) on delete set null,
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

create table if not exists app.user_settings (
  user_id uuid primary key references app.profiles (id) on delete cascade,
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
  updated_at timestamptz not null default timezone('utc', now())
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
-- Indexing, scans, automation, audit
-- ---------------------------------------------------------------------------

create table if not exists app.scan_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references app.workspaces (id) on delete cascade,
  created_by uuid references app.profiles (id) on delete set null,
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
  actor_user_id uuid references app.profiles (id) on delete set null,
  entity_type text not null
    check (entity_type in (
      'workspace', 'folder', 'file', 'file_version', 'report', 'settings',
      'rule', 'share', 'member'
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

create trigger trg_profiles_updated_at
before update on app.profiles
for each row execute function app.set_updated_at();

create trigger trg_workspaces_updated_at
before update on app.workspaces
for each row execute function app.set_updated_at();

create trigger trg_workspace_members_updated_at
before update on app.workspace_members
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

create trigger trg_user_settings_updated_at
before update on app.user_settings
for each row execute function app.set_updated_at();

create trigger trg_workspace_settings_updated_at
before update on app.workspace_settings
for each row execute function app.set_updated_at();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table app.profiles enable row level security;
alter table app.workspaces enable row level security;
alter table app.workspace_members enable row level security;
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
alter table app.user_settings enable row level security;
alter table app.workspace_settings enable row level security;
alter table app.scan_jobs enable row level security;
alter table app.audit_events enable row level security;

create policy "profiles_select_own_or_member_visible"
on app.profiles for select
using (
  id = auth.uid()
  or exists (
    select 1
    from app.workspace_members wm_self
    join app.workspace_members wm_other
      on wm_self.workspace_id = wm_other.workspace_id
    where wm_self.user_id = auth.uid()
      and wm_other.user_id = profiles.id
      and wm_self.status = 'active'
      and wm_other.status = 'active'
  )
);

create policy "profiles_update_own"
on app.profiles for update
using (id = auth.uid())
with check (id = auth.uid());

create policy "workspaces_member_access"
on app.workspaces for select
using (app.is_workspace_member(id));

create policy "workspaces_owner_insert"
on app.workspaces for insert
with check (owner_user_id = auth.uid());

create policy "workspaces_admin_update"
on app.workspaces for update
using (
  exists (
    select 1
    from app.workspace_members wm
    where wm.workspace_id = workspaces.id
      and wm.user_id = auth.uid()
      and wm.role in ('owner', 'admin')
      and wm.status = 'active'
  )
);

create policy "workspace_members_member_select"
on app.workspace_members for select
using (app.is_workspace_member(workspace_id));

create policy "workspace_members_admin_manage"
on app.workspace_members for all
using (
  exists (
    select 1
    from app.workspace_members wm
    where wm.workspace_id = workspace_members.workspace_id
      and wm.user_id = auth.uid()
      and wm.role in ('owner', 'admin')
      and wm.status = 'active'
  )
)
with check (
  exists (
    select 1
    from app.workspace_members wm
    where wm.workspace_id = workspace_members.workspace_id
      and wm.user_id = auth.uid()
      and wm.role in ('owner', 'admin')
      and wm.status = 'active'
  )
);

create policy "folders_member_access"
on app.folders for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "files_member_access"
on app.files for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "file_versions_member_access"
on app.file_versions for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_versions.file_id
      and app.is_workspace_member(f.workspace_id)
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_versions.file_id
      and app.is_workspace_member(f.workspace_id)
  )
);

create policy "file_metadata_member_access"
on app.file_metadata for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_metadata.file_id
      and app.is_workspace_member(f.workspace_id)
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_metadata.file_id
      and app.is_workspace_member(f.workspace_id)
  )
);

create policy "tags_member_access"
on app.tags for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "file_tags_member_access"
on app.file_tags for all
using (
  exists (
    select 1
    from app.files f
    where f.id = file_tags.file_id
      and app.is_workspace_member(f.workspace_id)
  )
)
with check (
  exists (
    select 1
    from app.files f
    where f.id = file_tags.file_id
      and app.is_workspace_member(f.workspace_id)
  )
);

create policy "file_shares_member_access"
on app.file_shares for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "saved_views_member_access"
on app.saved_views for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "organizer_rules_member_access"
on app.organizer_rules for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "report_definitions_member_access"
on app.report_definitions for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "report_runs_member_access"
on app.report_runs for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "user_settings_own_access"
on app.user_settings for all
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "workspace_settings_member_access"
on app.workspace_settings for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "scan_jobs_member_access"
on app.scan_jobs for all
using (app.is_workspace_member(workspace_id))
with check (app.is_workspace_member(workspace_id));

create policy "audit_events_member_access"
on app.audit_events for select
using (workspace_id is null or app.is_workspace_member(workspace_id));

-- ---------------------------------------------------------------------------
-- Seed recommendation notes
-- ---------------------------------------------------------------------------
-- 1. Create a profile row for each auth.users record on signup.
-- 2. Create one personal workspace for each new user.
-- 3. Insert matching workspace_members row with role = 'owner'.
-- 4. Create workspace_settings defaults immediately after workspace creation.
-- 5. Store binary file content in Supabase Storage, and only metadata/path here.
