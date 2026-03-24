import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../explorer_weekday.dart';

class SupabaseExplorerFileCrudRepository implements ExplorerFileCrudRepository {
  SupabaseExplorerFileCrudRepository(
    this._client, {
    required this.workspaceId,
    this.storageBucket = 'filezen-assets',
  });

  final SupabaseClient _client;
  final String workspaceId;
  final String storageBucket;

  @override
  Future<void> renameFile({required String fileId, required String newName}) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _client.from('files').update({'name': trimmed}).eq('id', fileId);
  }

  @override
  Future<void> softDeleteFile({required String fileId}) async {
    await _client.from('files').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', fileId);
  }

  @override
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return;
    if (workspaceId.isEmpty) {
      throw StateError(
        'FILEZEN_WORKSPACE_ID is required for uploads. Pass it via --dart-define=FILEZEN_WORKSPACE_ID=...',
      );
    }

    final rowId = const Uuid().v4();
    final safeName = _safeFileName(trimmed);
    final objectPath = '$workspaceId/$rowId/$safeName';
    final ext = _fileExtension(trimmed);
    final nowLocal = DateTime.now();
    final dayLabel = ExplorerWeekday.english(nowLocal);

    await _client.storage.from(storageBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'application/octet-stream',
            upsert: false,
          ),
        );

    final insertPayload = <String, dynamic>{
      'id': rowId,
      'workspace_id': workspaceId,
      'name': trimmed,
      'original_name': trimmed,
      'size_bytes': bytes.length,
      'storage_bucket': storageBucket,
      'storage_object_path': objectPath,
      'storage_provider': 'supabase',
      'metadata': <String, dynamic>{
        'block': 'Primary Archive',
        'day_of_week': dayLabel,
      },
    };
    if (ext != null) {
      insertPayload['extension'] = ext;
    }
    if (contentType != null && contentType.isNotEmpty) {
      insertPayload['mime_type'] = contentType;
    }

    await _client.from('files').insert(insertPayload);
  }

  static String? _fileExtension(String name) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;
    return name.substring(dot + 1).toLowerCase();
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/]'), '_').trim();
    return cleaned.isEmpty ? 'upload.bin' : cleaned;
  }
}
