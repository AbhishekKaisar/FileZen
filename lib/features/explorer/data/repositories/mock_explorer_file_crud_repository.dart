import 'dart:typed_data';

import '../../domain/models/explorer_item.dart';
import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../explorer_byte_format.dart';
import '../explorer_weekday.dart';
import '../mock_explorer_data_store.dart';

class MockExplorerFileCrudRepository implements ExplorerFileCrudRepository {
  static final Map<String, Uint8List> _uploadedBytesById = <String, Uint8List>{};

  @override
  Future<void> renameFile({required String fileId, required String newName}) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final items = MockExplorerDataStore.instance.snapshot();
    ExplorerItem? existing;
    for (final e in items) {
      if (e.id == fileId) {
        existing = e;
        break;
      }
    }
    if (existing == null || existing.isFolder) return;

    final newPath = _replaceLastPathSegment(existing.path, trimmed);
    MockExplorerDataStore.instance.updateItem(
      existing.copyWith(name: trimmed, path: newPath),
    );
  }

  @override
  Future<void> updateOrganizerPlacement({
    required String fileId,
    required String blockName,
    required String dayOfWeek,
  }) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final items = MockExplorerDataStore.instance.snapshot();
    ExplorerItem? existing;
    for (final e in items) {
      if (e.id == fileId) {
        existing = e;
        break;
      }
    }
    if (existing == null || existing.isFolder) return;
    MockExplorerDataStore.instance.updateItem(
      existing.copyWith(
        blockName: blockName.trim().isEmpty ? 'Unassigned Block' : blockName.trim(),
        dayOfWeek: dayOfWeek.trim().isEmpty ? 'Unscheduled' : dayOfWeek.trim(),
      ),
    );
  }

  @override
  Future<void> softDeleteFile({required String fileId}) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final existing = MockExplorerDataStore.instance.itemById(fileId);
    if (existing == null) return;
    MockExplorerDataStore.instance.updateItem(existing.copyWith(isDeleted: true));
  }

  @override
  Future<void> restoreFile({required String fileId}) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final existing = MockExplorerDataStore.instance.itemById(fileId);
    if (existing == null) return;
    MockExplorerDataStore.instance.updateItem(existing.copyWith(isDeleted: false));
  }

  @override
  Future<void> hardDeleteFile({
    required String fileId,
    String? storageBucket,
    String? storageObjectPath,
  }) async {
    MockExplorerDataStore.instance.ensureInitialized();
    MockExplorerDataStore.instance.removeById(fileId);
    _uploadedBytesById.remove(fileId);
  }

  @override
  Future<void> copyFile({
    required String fileId,
    required String currentName,
    required String blockName,
    required String dayOfWeek,
    required ExplorerDuplicateStrategy duplicateStrategy,
  }) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final src = MockExplorerDataStore.instance.itemById(fileId);
    if (src == null) return;
    final now = DateTime.now();
    final id = 'mock-copy-${now.millisecondsSinceEpoch}';
    var name = src.name;
    if (duplicateStrategy == ExplorerDuplicateStrategy.renameWithTimestamp) {
      name = '${src.name}_copy_${now.millisecondsSinceEpoch}';
    }
    if (duplicateStrategy == ExplorerDuplicateStrategy.skip) {
      final exists = MockExplorerDataStore.instance.snapshot().any((e) => !e.isDeleted && e.name == src.name);
      if (exists) return;
    }
    if (duplicateStrategy == ExplorerDuplicateStrategy.replace) {
      final toReplace = MockExplorerDataStore.instance.snapshot().where((e) => !e.isDeleted && e.name == src.name);
      for (final e in toReplace) {
        if (e.id != null) {
          MockExplorerDataStore.instance.removeById(e.id!);
        }
      }
    }
    MockExplorerDataStore.instance.addItem(
      src.copyWith(
        id: id,
        name: name,
        path: _replaceLastPathSegment(src.path, name),
        blockName: blockName,
        dayOfWeek: dayOfWeek,
        isDeleted: false,
      ),
    );
    final srcBytes = _uploadedBytesById[fileId];
    if (srcBytes != null) {
      _uploadedBytesById[id] = Uint8List.fromList(srcBytes);
    }
  }

  @override
  Future<Uint8List> downloadFileBytes({
    required String fileId,
    required String storageBucket,
    required String storageObjectPath,
  }) async {
    final inMemory = _uploadedBytesById[fileId];
    if (inMemory != null) {
      return Uint8List.fromList(inMemory);
    }
    return Uint8List.fromList('Mock file content for $fileId'.codeUnits);
  }

  @override
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
    String? localPath,
    String? contentType,
  }) async {
    MockExplorerDataStore.instance.ensureInitialized();
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final id = 'mock-upload-${now.millisecondsSinceEpoch}';
    final day = ExplorerWeekday.english(now);
    const block = 'Primary Archive';

    MockExplorerDataStore.instance.addItem(
      ExplorerItem(
        id: id,
        name: trimmed,
        path: '/vault/Uploads/$trimmed',
        isFolder: false,
        sizeLabel: ExplorerByteFormat.humanReadable(bytes.length),
        updatedLabel: 'Updated just now',
        blockName: block,
        dayOfWeek: day,
        storageBucket: 'mock-bucket',
        storageObjectPath: 'mock/$id/$trimmed',
      ),
    );
    _uploadedBytesById[id] = Uint8List.fromList(bytes);
  }

  String _replaceLastPathSegment(String path, String newLeaf) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/')..removeWhere((s) => s.isEmpty);
    if (segments.isEmpty) return '/$newLeaf';
    segments[segments.length - 1] = newLeaf;
    return '/${segments.join('/')}';
  }
}
