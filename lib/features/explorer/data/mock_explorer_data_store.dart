import '../domain/models/explorer_item.dart';

/// In-memory store so mock Explorer + CRUD stay in sync for demos.
class MockExplorerDataStore {
  MockExplorerDataStore._();
  static final MockExplorerDataStore instance = MockExplorerDataStore._();

  final List<ExplorerItem> _items = [];
  bool _initialized = false;

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _items.addAll(_seedItems);
  }

  List<ExplorerItem> snapshot() => List<ExplorerItem>.from(_items);

  void removeById(String id) {
    _items.removeWhere((e) => e.id == id);
  }

  ExplorerItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void updateItem(ExplorerItem next) {
    final i = _items.indexWhere((e) => e.id == next.id);
    if (i >= 0) {
      _items[i] = next;
    }
  }

  void addItem(ExplorerItem item) {
    ensureInitialized();
    _items.add(item);
  }

  static const List<ExplorerItem> _seedItems = [
    ExplorerItem(
      id: 'mock-folder-docs',
      name: 'Documents',
      path: '/vault/Documents',
      isFolder: true,
      sizeLabel: '--',
      updatedLabel: 'Updated today',
      blockName: 'Primary Archive',
      dayOfWeek: 'Thursday',
    ),
    ExplorerItem(
      id: 'mock-folder-design',
      name: 'Design Assets',
      path: '/vault/Design Assets',
      isFolder: true,
      sizeLabel: '--',
      updatedLabel: 'Updated 1 day ago',
      blockName: 'Primary Archive',
      dayOfWeek: 'Friday',
    ),
    ExplorerItem(
      id: 'mock-file-q4',
      name: 'Q4_Financial_Report.pdf',
      path: '/vault/Documents/Q4_Financial_Report.pdf',
      isFolder: false,
      sizeLabel: '4.2 MB',
      updatedLabel: 'Updated 2h ago',
      blockName: 'Primary Archive',
      dayOfWeek: 'Friday',
    ),
    ExplorerItem(
      id: 'mock-file-brand',
      name: 'Brand_Guide_v3.pdf',
      path: '/vault/Design Assets/Brand_Guide_v3.pdf',
      isFolder: false,
      sizeLabel: '8.8 MB',
      updatedLabel: 'Updated 8h ago',
      blockName: 'Creative Lab',
      dayOfWeek: 'Saturday',
    ),
    ExplorerItem(
      id: 'mock-file-hero',
      name: 'Hero_Visual_Concept.png',
      path: '/vault/Design Assets/Hero_Visual_Concept.png',
      isFolder: false,
      sizeLabel: '12.8 MB',
      updatedLabel: 'Updated yesterday',
      blockName: 'Creative Lab',
      dayOfWeek: 'Thursday',
    ),
  ];
}
