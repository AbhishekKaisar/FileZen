import '../models/explorer_item.dart';
import '../models/explorer_query.dart';

abstract class ExplorerRepository {
  Future<List<ExplorerItem>> fetchItems(ExplorerQuery query);
}
