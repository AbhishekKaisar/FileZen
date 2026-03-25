# FileZen

FileZen is a modern, cross-platform file management and organization application built with Flutter. Designed with a sleek Material-3-inspired Dark Theme ("Zen"), FileZen provides an intuitive and visually stunning interface for managing cloud assets, storage spaces, and deeply embedded OS metadata.

## Key Features
- **Dashboard Explorer**: View vault storage overviews, auto-sorter statuses, and quick access bento-grids.
- **Block & Day Organizer**: A chronological grid layout to organize files by active days, sessions, and primary tasks.
- **OS Metadata Visualizer**: A highly detailed, modal bottom-sheet designed to show secure UNIX privileges, storage geometry, and filesystem attributes.

## Getting Started

### Prerequisites
Make sure you have [Flutter](https://docs.flutter.dev/get-started/install) installed.

- **Flutter SDK**: `>=3.9.x`
- **Dart SDK**: `^3.9.2`

### Installation
1. **Clone the repository**
   ```bash
   git clone <repository_url>
   cd FileZen
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```

### Run in Mock Mode (no Supabase required)
This is the fastest way to run the app locally.

```bash
flutter run
```

### Run with Supabase
Pass runtime flags using `--dart-define`.

```bash
flutter run \
  --dart-define=USE_SUPABASE_EXPLORER=true \
  --dart-define=SUPABASE_URL=https://<your-project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=FILEZEN_WORKSPACE_ID=<workspace-uuid> \
  --dart-define=FILEZEN_DB_SCHEMA=app
```

Notes:
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are required for Supabase initialization and storage upload fallback.
- `FILEZEN_WORKSPACE_ID` is required for upload/create flows in Supabase mode.
- `FILEZEN_DB_SCHEMA` defaults to `app` if not provided.

## Supabase Setup

### 1) Create schema/tables
Run the SQL in:
- `docs/supabase_schema.sql`

### 2) Add organizer columns migration
Run:
- `docs/migrations/002_organizer_block_day_columns.sql`

### 3) Enable RLS and policies
Run:
- `docs/supabase_rls_policies.sql`

The baseline policy file expects a `workspace_id` claim in the JWT for end-user sessions.

## Quality Checks

Run before pushing changes:

```bash
flutter analyze
flutter test
```

CI is configured in:
- `.github/workflows/flutter_ci.yml`

## Project Structure
FileZen utilizes a clean architectural structure broken down by **features**:
- `lib/features/dashboard/`: Contains the entry view for system storage visualization.
- `lib/features/organizer/`: Houses the complex layouts like `ProjectBlocksGrid` and `MetadataVisualizerBottomSheet`.
- `lib/core/` (if defined): Application-wide thematic constraints and routers.

## Contributing
1. When making UI changes, ensure they align with the core Dark theme constraints (Background: `#0e0e0e`, Accents: `#AEC6FF`, etc.).
2. Do not use deprecated Material APIs (e.g. use `.withValues()` instead of `.withOpacity()`).
3. Run `flutter analyze` prior to committing to ensure code quality.

## License
MIT
