import '../../domain/models/explorer_item.dart';
import '../../domain/models/explorer_query.dart';
import '../../domain/repositories/explorer_repository.dart';
import '../mock_explorer_data_store.dart';

enum MockExplorerScenario {
  normal,
  empty,
  error,
}

class MockExplorerRepository implements ExplorerRepository {
  MockExplorerRepository({
    this.delay = const Duration(milliseconds: 800),
    this.scenario = MockExplorerScenario.normal,
  });

  final Duration delay;
  final MockExplorerScenario scenario;

  @override
  Future<List<ExplorerItem>> fetchItems(ExplorerQuery query) async {
    await Future<void>.delayed(delay);

    if (scenario == MockExplorerScenario.error) {
      throw Exception('Failed to load explorer items');
    }
    if (scenario == MockExplorerScenario.empty) {
      return const [];
    }

    MockExplorerDataStore.instance.ensureInitialized();
    final items = MockExplorerDataStore.instance.snapshot();

    final search = query.search.trim().toLowerCase();
    final filtered = items.where((item) {
      if (query.kind == ExplorerKindFilter.folders && !item.isFolder) {
        return false;
      }
      if (query.kind == ExplorerKindFilter.files && item.isFolder) {
        return false;
      }
      if (search.isEmpty) {
        return true;
      }
      return item.name.toLowerCase().contains(search) || item.path.toLowerCase().contains(search);
    }).toList();

    filtered.sort((a, b) {
      switch (query.sortBy) {
        case ExplorerSortBy.nameAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case ExplorerSortBy.nameDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case ExplorerSortBy.updatedDesc:
          return b.updatedLabel.toLowerCase().compareTo(a.updatedLabel.toLowerCase());
      }
    });

    return filtered;
  }
}
