import 'dart:typed_data';

enum ExplorerDuplicateStrategy {
  renameWithTimestamp,
  replace,
  skip,
}

abstract class ExplorerFileCrudRepository {
  /// Rename a file row (does not rename storage object path; use a dedicated sync job for that).
  Future<void> renameFile({required String fileId, required String newName});

  /// Update the organizer classification fields used for block/day grouping.
  Future<void> updateOrganizerPlacement({
    required String fileId,
    required String blockName,
    required String dayOfWeek,
  });

  /// Soft-delete file (sets is_deleted + deleted_at when using Supabase).
  Future<void> softDeleteFile({required String fileId});

  /// Restore a soft-deleted file.
  Future<void> restoreFile({required String fileId});

  /// Permanently delete file row and storage object.
  Future<void> hardDeleteFile({
    required String fileId,
    String? storageBucket,
    String? storageObjectPath,
  });

  /// Duplicate a file row (and storage object in Supabase mode) with conflict strategy.
  Future<void> copyFile({
    required String fileId,
    required String currentName,
    required String blockName,
    required String dayOfWeek,
    required ExplorerDuplicateStrategy duplicateStrategy,
  });

  /// Download a file's bytes for open/save actions.
  Future<Uint8List> downloadFileBytes({
    required String fileId,
    required String storageBucket,
    required String storageObjectPath,
  });

  /// Upload bytes to storage (Supabase) and insert a `files` row; mock appends to in-memory store.
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
    String? localPath,
    String? contentType,
  });
}
