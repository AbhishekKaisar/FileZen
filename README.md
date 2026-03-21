# FileZen

FileZen is a modern, cross-platform file management and organization application built with Flutter. Designed with a sleek Material-3-inspired Dark Theme ("Zen"), FileZen provides an intuitive and visually stunning interface for managing cloud assets, storage spaces, and deeply embedded OS metadata.

## Key Features
- **Dashboard Explorer**: View vault storage overviews, auto-sorter statuses, and quick access bento-grids.
- **Block & Day Organizer**: A chronological grid layout to organize files by active days, sessions, and primary tasks.
- **OS Metadata Visualizer**: A highly detailed, modal bottom-sheet designed to show secure UNIX privileges, storage geometry, and filesystem attributes.

## Getting Started

To get the app up and running on your local machine, follow these steps:

### Prerequisites
Make sure you have [Flutter](https://docs.flutter.dev/get-started/install) installed along with Android Studio or Xcode for emulator/simulator support.
- **Flutter SDK**: `^3.x`
- **Dart SDK**: `^3.x`

### Installation
1. **Clone the repository**:
   ```bash
   git clone <repository_url>
   cd file_zen
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the application**:
   ```bash
   flutter run
   ```

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
