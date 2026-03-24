import 'dart:typed_data';

abstract class ExplorerFileCrudRepository {
  /// Rename a file row (does not rename storage object path; use a dedicated sync job for that).
  Future<void> renameFile({required String fileId, required String newName});

  /// Soft-delete file (sets is_deleted + deleted_at when using Supabase).
  Future<void> softDeleteFile({required String fileId});

  /// Upload bytes to storage (Supabase) and insert a `files` row; mock appends to in-memory store.
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  });
}
