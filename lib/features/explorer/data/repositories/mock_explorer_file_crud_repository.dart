import 'dart:typed_data';

import '../../domain/models/explorer_item.dart';
import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../explorer_byte_format.dart';
import '../explorer_weekday.dart';
import '../mock_explorer_data_store.dart';

class MockExplorerFileCrudRepository implements ExplorerFileCrudRepository {
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
  Future<void> softDeleteFile({required String fileId}) async {
    MockExplorerDataStore.instance.ensureInitialized();
    MockExplorerDataStore.instance.removeById(fileId);
  }

  @override
  Future<void> createUploadedFile({
    required String fileName,
    required Uint8List bytes,
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
      ),
    );
  }

  String _replaceLastPathSegment(String path, String newLeaf) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/')..removeWhere((s) => s.isEmpty);
    if (segments.isEmpty) return '/$newLeaf';
    segments[segments.length - 1] = newLeaf;
    return '/${segments.join('/')}';
  }
}
