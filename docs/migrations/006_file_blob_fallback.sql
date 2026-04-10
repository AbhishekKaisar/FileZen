-- FileZen migration: DB blob fallback for preview/download.
-- This keeps student demo flows working even when storage object paths/policies are inconsistent.

set search_path = app, public;

create table if not exists app.file_blobs (
  file_id uuid primary key references app.files (id) on delete cascade,
  content_base64 text not null,
  byte_size bigint not null default 0 check (byte_size >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_file_blobs_updated_at on app.file_blobs (updated_at desc);

-- RLS + demo-safe policy for current anon-based app mode.
alter table app.file_blobs enable row level security;
drop policy if exists demo_rw_file_blobs on app.file_blobs;
create policy demo_rw_file_blobs
on app.file_blobs
for all
to anon, authenticated
using (true)
with check (true);

-- Tables created after 003_phase_a_anon_access.sql do not get the earlier
-- "grant on all tables" unless default privileges applied; grant explicitly.
grant select, insert, update, delete on app.file_blobs to anon, authenticated;
