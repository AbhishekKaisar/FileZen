import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../explorer_weekday.dart';
import 'supabase_storage_upload.dart';

class SupabaseExplorerFileCrudRepository implements ExplorerFileCrudRepository {
  SupabaseExplorerFileCrudRepository(
    this._client, {
    required this.workspaceId,
    this.dbSchema = 'app',
    this.storageBucket = 'filezen-assets',
  });

  final SupabaseClient _client;
  final String workspaceId;
  final String dbSchema;
  final String storageBucket;

  @override
  Future<void> renameFile({required String fileId, required String newName}) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _client.schema(dbSchema).from('files').update({'name': trimmed}).eq('id', fileId);
  }

  @override
  Future<void> updateOrganizerPlacement({
    required String fileId,
    required String blockName,
    required String dayOfWeek,
  }) async {
    final block = blockName.trim().isEmpty ? 'Unassigned Block' : blockName.trim();
    final day = dayOfWeek.trim().isEmpty ? 'Unscheduled' : dayOfWeek.trim();
    await _client.schema(dbSchema).from('files').update({
      'organizer_block_label': block,
      'organizer_day_of_week': day,
      'metadata': {
        'block': block,
        'day_of_week': day,
      },
    }).eq('id', fileId);
  }

  @override
  Future<void> softDeleteFile({required String fileId}) async {
    await _client.schema(dbSchema).from('files').update({
      'is_deleted': true,
      'deleted_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', fileId);
  }

  @override
  Future<void> restoreFile({required String fileId}) async {
    await _client.schema(dbSchema).from('files').update({
      'is_deleted': false,
      'deleted_at': null,
    }).eq('id', fileId);
  }

  @override
  Future<void> hardDeleteFile({
    required String fileId,
    String? storageBucket,
    String? storageObjectPath,
  }) async {
    String? bucket = storageBucket;
    String? path = storageObjectPath;
    if ((bucket == null || bucket.isEmpty) || (path == null || path.isEmpty)) {
      final rows = await _client.schema(dbSchema).from('files').select('storage_bucket,storage_object_path').eq('id', fileId).limit(1);
      if (rows.isNotEmpty) {
        final row = rows.first;
        bucket = row['storage_bucket']?.toString();
        path = row['storage_object_path']?.toString();
      }
    }
    if (bucket != null && bucket.isNotEmpty && path != null && path.isNotEmpty) {
      await _client.storage.from(bucket).remove([path]);
    }
    await _client.schema(dbSchema).from('files').delete().eq('id', fileId);
  }

  @override
  Future<void> copyFile({
    required String fileId,
    required String currentName,
    required String blockName,
    required String dayOfWeek,
    required ExplorerDuplicateStrategy duplicateStrategy,
  }) async {
    final rows = await _client
        .schema(dbSchema)
        .from('files')
        .select('name,extension,mime_type,size_bytes,storage_bucket,storage_object_path')
        .eq('id', fileId)
        .limit(1);
    if (rows.isEmpty) {
      throw StateError('File not found for copy.');
    }
    final row = rows.first;
    final srcBucket = row['storage_bucket']?.toString() ?? storageBucket;
    final srcObjectPath = row['storage_object_path']?.toString() ?? '';
    if (srcObjectPath.isEmpty) {
      throw StateError('Missing storage path for copy.');
    }

    final sourceBytes = await _client.storage.from(srcBucket).download(srcObjectPath);
    final desiredName = (row['name']?.toString() ?? currentName).trim();
    final resolvedName = await _resolveNameForCopy(
      desiredName: desiredName,
      strategy: duplicateStrategy,
    );
    if (resolvedName == null) {
      return;
    }

    final newRowId = const Uuid().v4();
    final safeName = _safeFileName(resolvedName);
    final objectPath = '$workspaceId/$newRowId/$safeName';
    await _client.storage.from(srcBucket).uploadBinary(objectPath, sourceBytes);
    await _client.schema(dbSchema).from('files').insert({
      'id': newRowId,
      'workspace_id': workspaceId,
      'name': resolvedName,
      'original_name': row['name']?.toString() ?? currentName,
      'extension': row['extension']?.toString() ?? _fileExtension(resolvedName),
      'mime_type': row['mime_type']?.toString(),
      'size_bytes': (row['size_bytes'] as num?)?.toInt() ?? sourceBytes.length,
      'storage_bucket': srcBucket,
      'storage_object_path': objectPath,
      'storage_provider': 'supabase',
      'organizer_block_label': blockName,
      'organizer_day_of_week': dayOfWeek,
      'metadata': {
        'block': blockName,
        'day_of_week': dayOfWeek,
        'copied_from': fileId,
      },
    });
  }

  @override
  Future<Uint8List> downloadFileBytes({
    required String fileId,
    required String storageBucket,
    required String storageObjectPath,
  }) async {
    if (storageBucket.isEmpty || storageObjectPath.isEmpty) {
      throw StateError('Missing storage location for download.');
    }
    return _client.storage.from(storageBucket).download(storageObjectPath);
  }

  @override
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
    String? localPath,
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

    await uploadFileToSupabaseStorage(
      client: _client,
      bucket: storageBucket,
      objectPath: objectPath,
      bytes: bytes,
      localPath: localPath,
      contentType: contentType,
    );

    var resolvedName = trimmed;
    final insertPayload = <String, dynamic>{
      'id': rowId,
      'workspace_id': workspaceId,
      'name': resolvedName,
      'original_name': trimmed,
      'size_bytes': bytes.length,
      'storage_bucket': storageBucket,
      'storage_object_path': objectPath,
      'storage_provider': 'supabase',
      'organizer_block_label': 'Primary Archive',
      'organizer_day_of_week': dayLabel,
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
    try {
      await _client.schema(dbSchema).from('files').insert(insertPayload);
    } on PostgrestException catch (_) {
      resolvedName = _appendTimestamp(trimmed);
      insertPayload['name'] = resolvedName;
      await _client.schema(dbSchema).from('files').insert(insertPayload);
    }
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

  Future<String?> _resolveNameForCopy({
    required String desiredName,
    required ExplorerDuplicateStrategy strategy,
  }) async {
    final existingRows = await _client
        .schema(dbSchema)
        .from('files')
        .select('id,storage_bucket,storage_object_path')
        .eq('workspace_id', workspaceId)
        .eq('name', desiredName)
        .eq('is_deleted', false)
        .limit(1);
    if (existingRows.isEmpty) {
      return desiredName;
    }
    if (strategy == ExplorerDuplicateStrategy.skip) {
      return null;
    }
    if (strategy == ExplorerDuplicateStrategy.replace) {
      final existing = existingRows.first;
      final existingId = existing['id']?.toString();
      if (existingId != null && existingId.isNotEmpty) {
        final bucket = existing['storage_bucket']?.toString();
        final path = existing['storage_object_path']?.toString();
        await hardDeleteFile(fileId: existingId, storageBucket: bucket, storageObjectPath: path);
      }
      return desiredName;
    }
    return _appendTimestamp(desiredName);
  }

  String _appendTimestamp(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ts = DateTime.now().millisecondsSinceEpoch;
    if (dot <= 0 || dot == fileName.length - 1) {
      return '${fileName}_copy_$ts';
    }
    final base = fileName.substring(0, dot);
    final ext = fileName.substring(dot);
    return '${base}_copy_$ts$ext';
  }
}
