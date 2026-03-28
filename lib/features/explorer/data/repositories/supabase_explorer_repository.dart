import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/explorer_item.dart';
import '../../domain/models/explorer_query.dart';
import '../../domain/repositories/explorer_repository.dart';

class SupabaseExplorerRepository implements ExplorerRepository {
  SupabaseExplorerRepository({
    required SupabaseClient client,
    this.workspaceId,
  }) : _client = client;

  final SupabaseClient _client;
  final String? workspaceId;

  @override
  Future<List<ExplorerItem>> fetchItems(ExplorerQuery query) async {
    final rows = await _queryFiles(query);

    final items = rows.map((row) {
      final id = row['id']?.toString();
      final folderName = row['folder_name'] as String?;
      final fileName = row['name'] as String? ?? 'Unnamed';
      final displayPath = folderName == null || folderName.isEmpty ? '/vault/$fileName' : '/vault/$folderName/$fileName';
      final size = (row['size_bytes'] as num?)?.toInt() ?? 0;
      final updatedAt = row['updated_at'] as String?;
      final blockName = _resolveBlockLabel(
        column: row['organizer_block_label'],
        metadata: row['metadata'],
      );
      final dayOfWeek = _resolveDayOfWeek(
        column: row['organizer_day_of_week'],
        metadata: row['metadata'],
      );
      return ExplorerItem(
        id: id,
        name: fileName,
        path: displayPath,
        isFolder: false,
        sizeLabel: _formatBytes(size),
        updatedLabel: _formatUpdatedLabel(updatedAt),
        blockName: blockName,
        dayOfWeek: dayOfWeek,
      );
    }).toList();

    if (query.kind == ExplorerKindFilter.folders) {
      return const [];
    }

    return items;
  }

  Future<List<Map<String, dynamic>>> _queryFiles(ExplorerQuery query) async {
    dynamic request = _client.schema('app').from('files').select(
          'id,name,size_bytes,updated_at,metadata,organizer_block_label,organizer_day_of_week,folders(name)',
        );

    if (workspaceId != null && workspaceId!.isNotEmpty) {
      request = request.eq('workspace_id', workspaceId!);
    }
    if (query.search.trim().isNotEmpty) {
      request = request.ilike('name', '%${query.search.trim()}%');
    }

    final block = query.organizerBlockLabel?.trim();
    if (block != null && block.isNotEmpty) {
      request = request.eq('organizer_block_label', block);
    }

    final day = query.organizerDayOfWeek?.trim();
    if (day != null && day.isNotEmpty) {
      request = request.eq('organizer_day_of_week', day);
    }

    request = request.eq('is_deleted', false);

    switch (query.sortBy) {
      case ExplorerSortBy.nameAsc:
        request = request.order('name', ascending: true);
        break;
      case ExplorerSortBy.nameDesc:
        request = request.order('name', ascending: false);
        break;
      case ExplorerSortBy.updatedDesc:
        request = request.order('updated_at', ascending: false);
        break;
    }

    final response = await request.limit(200);
    return response.map<Map<String, dynamic>>((row) {
      final map = row;
      final folders = map['folders'];
      return {
        'id': map['id'],
        'name': map['name'],
        'size_bytes': map['size_bytes'],
        'updated_at': map['updated_at'],
        'metadata': map['metadata'],
        'organizer_block_label': map['organizer_block_label'],
        'organizer_day_of_week': map['organizer_day_of_week'],
        'folder_name': folders is Map<String, dynamic> ? folders['name'] : null,
      };
    }).toList();
  }

  static String _resolveBlockLabel({required dynamic column, required dynamic metadata}) {
    final fromCol = _nonEmptyString(column);
    if (fromCol != null) return fromCol;
    if (metadata is Map<String, dynamic>) {
      final fromMeta = _nonEmptyString(metadata['block']);
      if (fromMeta != null) return fromMeta;
    }
    return 'Unassigned Block';
  }

  static String _resolveDayOfWeek({required dynamic column, required dynamic metadata}) {
    final fromCol = _nonEmptyString(column);
    if (fromCol != null) return fromCol;
    if (metadata is Map<String, dynamic>) {
      final fromMeta = _nonEmptyString(metadata['day_of_week']);
      if (fromMeta != null) return _canonicalWeekday(fromMeta);
    }
    return 'Unscheduled';
  }

  static String? _nonEmptyString(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static String _canonicalWeekday(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'monday':
        return 'Monday';
      case 'tuesday':
        return 'Tuesday';
      case 'wednesday':
        return 'Wednesday';
      case 'thursday':
        return 'Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday':
        return 'Saturday';
      case 'sunday':
        return 'Sunday';
      default:
        return raw.trim();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    final display = size >= 10 || index == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$display ${units[index]}';
  }

  String _formatUpdatedLabel(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return 'Updated recently';
    }
    final updated = DateTime.tryParse(timestamp)?.toLocal();
    if (updated == null) {
      return 'Updated recently';
    }
    final diff = DateTime.now().difference(updated);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}
