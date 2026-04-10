-- Sample reporting queries: block + day-of-week distribution
-- Adjust workspace filter as needed.

set search_path = app, public;

-- 1) File counts and total size by organizer block (active files only)
select
  coalesce(f.organizer_block_label, '(unassigned)') as block_label,
  count(*)::bigint as file_count,
  coalesce(sum(f.size_bytes), 0)::bigint as total_bytes
from app.files f
where f.is_deleted = false
  -- and f.workspace_id = '<your-workspace-uuid>'::uuid
group by 1
order by file_count desc;

-- 2) File counts by block and weekday (pivot-friendly)
select
  coalesce(f.organizer_block_label, '(unassigned)') as block_label,
  coalesce(f.organizer_day_of_week, '(unscheduled)') as day_of_week,
  count(*)::bigint as file_count,
  coalesce(sum(f.size_bytes), 0)::bigint as total_bytes
from app.files f
where f.is_deleted = false
group by 1, 2
order by 1, 2;

-- 3) Per-workspace block/day rows (easy to feed charts or CSV export)
select
  f.workspace_id,
  coalesce(f.organizer_block_label, 'Unassigned Block') as block_label,
  coalesce(f.organizer_day_of_week, 'Unscheduled') as day_of_week,
  count(*)::bigint as file_count,
  coalesce(sum(f.size_bytes), 0)::bigint as total_bytes
from app.files f
where f.is_deleted = false
group by f.workspace_id, f.organizer_block_label, f.organizer_day_of_week
order by f.workspace_id, block_label, day_of_week;
