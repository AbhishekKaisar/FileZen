# Phase A — Supabase setup (no authentication)

This walkthrough covers **item 1** of Phase A: database, migration **002** (organizer columns), anonymous access for the Flutter app, storage bucket, and a default workspace.

## 1. Create a Supabase project

Create a project at [supabase.com](https://supabase.com) and open **SQL Editor**.

## 2. Run SQL scripts **in order**

1. Paste and run the full contents of **`docs/supabase_schema.sql`**.
2. Run **`docs/migrations/002_organizer_block_day_columns.sql`**.
3. Run **`docs/migrations/003_phase_a_anon_access.sql`** (grants + permissive RLS for `anon` — **dev only**).
4. Run **`docs/migrations/004_seed_phase_a_workspace.sql`**.

The seeded workspace id (used by the app) is:

`a0000000-0000-4000-8000-000000000001`

## 3. Expose the `app` schema to PostgREST

In the Supabase dashboard:

**Project Settings → Data API → Exposed schemas** — add **`app`** (keep `public` if present).

Without this, the Flutter client cannot query `app.files`.

## 4. Storage bucket `filezen-assets`

1. **Storage → New bucket** → name **`filezen-assets`** (public or private; policies below allow anon for dev).
2. **Storage → Policies** for `filezen-assets`, add policies so **anonymous** users can upload/read/update/delete objects used by the app, for example:
   - **SELECT** for `anon`
   - **INSERT** for `anon`
   - **UPDATE** for `anon`
   - **DELETE** for `anon`

Use the policy templates “Allow public access” only for **local demos**. Lock this down before production.

## 5. Flutter run arguments

```bash
flutter run -d android --dart-define=USE_SUPABASE_EXPLORER=true \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=FILEZEN_WORKSPACE_ID=a0000000-0000-4000-8000-000000000001
```

Get **URL** and **anon key** from **Project Settings → API**.

If `SUPABASE_*` are omitted, the app stays on **mock** data.

## 6. Verify

- **Explorer**: list, upload, rename, soft-delete files.
- **Organizer**: pick a **block** and **day**; the list should match rows in `app.files` (`organizer_block_label`, `organizer_day_of_week`).
