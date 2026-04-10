-- FileZen migration: normalized organizer block + day-of-week on files
-- Run after docs/supabase_schema.sql (or on existing databases).
-- Note: Supabase PostgREST must expose schema `app` (or replace `app` with `public`
-- and adjust Flutter `.from('files')` accordingly).

set search_path = app, public;

-- ---------------------------------------------------------------------------
-- Columns (nullable; backfill from metadata where present)
-- ---------------------------------------------------------------------------

alter table app.files
  add column if not exists organizer_block_label text,
  add column if not exists organizer_day_of_week text;

-- Weekday constraint (NULL = not assigned / legacy rows)
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'files_organizer_day_of_week_valid'
      and conrelid = 'app.files'::regclass
  ) then
    alter table app.files
      add constraint files_organizer_day_of_week_valid
      check (
        organizer_day_of_week is null
        or organizer_day_of_week in (
          'Monday', 'Tuesday', 'Wednesday', 'Thursday',
          'Friday', 'Saturday', 'Sunday'
        )
      );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Backfill from JSON metadata (keys used by the Flutter app)
-- ---------------------------------------------------------------------------

update app.files f
set organizer_block_label = nullif(btrim(f.metadata->>'block'), '')
where f.organizer_block_label is null
  and f.metadata ? 'block';

update app.files f
set organizer_day_of_week = case lower(btrim(f.metadata->>'day_of_week'))
    when 'monday' then 'Monday'
    when 'tuesday' then 'Tuesday'
    when 'wednesday' then 'Wednesday'
    when 'thursday' then 'Thursday'
    when 'friday' then 'Friday'
    when 'saturday' then 'Saturday'
    when 'sunday' then 'Sunday'
    else null
  end
where f.organizer_day_of_week is null
  and f.metadata ? 'day_of_week';

-- Clear invalid day values that would violate CHECK (if any)
update app.files
set organizer_day_of_week = null
where organizer_day_of_week is not null
  and organizer_day_of_week not in (
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  );

-- ---------------------------------------------------------------------------
-- Indexes for Explorer + reporting
-- ---------------------------------------------------------------------------

create index if not exists idx_files_workspace_block_day
  on app.files (workspace_id, organizer_block_label, organizer_day_of_week)
  where is_deleted = false;

create index if not exists idx_files_organizer_block_label
  on app.files (organizer_block_label)
  where is_deleted = false and organizer_block_label is not null;
