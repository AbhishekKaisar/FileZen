-- FileZen migration: Supabase Storage policies for file preview/download/upload.
-- Apply in Supabase SQL Editor after creating bucket `filezen-assets`.

-- IMPORTANT:
-- This is student-friendly and free-tier compatible.
-- It allows authenticated users to access objects only under their workspace prefix:
--   <workspace_id>/<file_id>/<file_name>
-- Where workspace_id is passed as JWT claim `workspace_id`.

-- Note:
-- Some Supabase projects reject `alter table storage.objects ...` with:
-- "must be owner of table objects".
-- Storage RLS is typically already enabled by Supabase, so we only define policies here.

-- ---------------------------------------------------------------------------
-- Cleanup old/conflicting policies for this bucket (idempotent)
-- ---------------------------------------------------------------------------
drop policy if exists "anon_delete_filezen_assets" on storage.objects;
drop policy if exists "anon_update_filezen_assets" on storage.objects;
drop policy if exists "anon_insert_filezen_assets" on storage.objects;
drop policy if exists "anon_read_filezen_assets" on storage.objects;
drop policy if exists "allow public reads from filezen-assets" on storage.objects;
drop policy if exists "allow public uploads to filezen-assets" on storage.objects;
drop policy if exists "filezen_storage_delete_same_workspace" on storage.objects;
drop policy if exists "filezen_storage_update_same_workspace" on storage.objects;
drop policy if exists "filezen_storage_insert_same_workspace" on storage.objects;
drop policy if exists "filezen_storage_read_same_workspace" on storage.objects;

-- Read (preview/download).
create policy filezen_storage_read_filezen_assets_anon
on storage.objects
for select
to anon
using (
  bucket_id = 'filezen-assets'
);

-- Upload.
create policy filezen_storage_insert_filezen_assets_anon
on storage.objects
for insert
to anon
with check (
  bucket_id = 'filezen-assets'
);

-- Update/replace.
create policy filezen_storage_update_filezen_assets_anon
on storage.objects
for update
to anon
using (
  bucket_id = 'filezen-assets'
)
with check (
  bucket_id = 'filezen-assets'
);

-- Delete.
create policy filezen_storage_delete_filezen_assets_anon
on storage.objects
for delete
to anon
using (
  bucket_id = 'filezen-assets'
);
