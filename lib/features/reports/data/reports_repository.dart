import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ReportsSnapshot {
  const ReportsSnapshot({
    required this.totalBytes,
    required this.totalFiles,
    required this.integrityScore,
    required this.blockDayRows,
    required this.recentRuns,
  });

  final int totalBytes;
  final int totalFiles;
  final double integrityScore;
  final List<BlockDayRow> blockDayRows;
  final List<ReportRunRow> recentRuns;
}

class BlockDayRow {
  const BlockDayRow({
    required this.blockLabel,
    required this.dayOfWeek,
    required this.fileCount,
    required this.totalBytes,
  });

  final String blockLabel;
  final String dayOfWeek;
  final int fileCount;
  final int totalBytes;
}

class ReportRunRow {
  const ReportRunRow({
    required this.startedAt,
    required this.status,
    required this.reportType,
  });

  final DateTime startedAt;
  final String status;
  final String reportType;
}

class ReportGenerationResult {
  const ReportGenerationResult({
    required this.reportRunId,
    required this.createdAt,
  });

  final String reportRunId;
  final DateTime createdAt;
}

class ReportsRepository {
  ReportsRepository({
    required SupabaseClient client,
    required this.workspaceId,
    this.dbSchema = 'app',
  }) : _client = client;

  final SupabaseClient _client;
  final String workspaceId;
  final String dbSchema;

  Future<ReportsSnapshot> fetchSnapshot() async {
    final rows = await _client
        .schema(dbSchema)
        .from('files')
        .select('id,size_bytes,organizer_block_label,organizer_day_of_week')
        .eq('workspace_id', workspaceId)
        .eq('is_deleted', false)
        .limit(2000);

    int totalBytes = 0;
    int totalFiles = 0;
    final Map<String, _Agg> blockDayAgg = {};
    for (final dynamic raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      totalFiles += 1;
      final bytes = (raw['size_bytes'] as num?)?.toInt() ?? 0;
      totalBytes += bytes;
      final block = _normalizeBlock(raw['organizer_block_label'] as String?);
      final day = _normalizeDay(raw['organizer_day_of_week'] as String?);
      final key = '$block::$day';
      final agg = blockDayAgg.putIfAbsent(key, () => _Agg(block, day));
      agg.fileCount += 1;
      agg.totalBytes += bytes;
    }

    final blockDayRows = blockDayAgg.values
        .map(
          (e) => BlockDayRow(
            blockLabel: e.blockLabel,
            dayOfWeek: e.dayOfWeek,
            fileCount: e.fileCount,
            totalBytes: e.totalBytes,
          ),
        )
        .toList()
      ..sort((a, b) {
        final byBlock = a.blockLabel.compareTo(b.blockLabel);
        if (byBlock != 0) return byBlock;
        return _weekdayOrder(a.dayOfWeek).compareTo(_weekdayOrder(b.dayOfWeek));
      });

    final runRows = await _client
        .schema(dbSchema)
        .from('report_runs')
        .select('started_at,status,report_definitions(report_type)')
        .eq('workspace_id', workspaceId)
        .order('started_at', ascending: false)
        .limit(8);

    final recentRuns = runRows.map<ReportRunRow>((dynamic raw) {
      final row = raw as Map<String, dynamic>;
      final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '') ?? DateTime.now().toUtc();
      final status = row['status']?.toString() ?? 'unknown';
      final defs = row['report_definitions'];
      final reportType = defs is Map<String, dynamic> ? defs['report_type']?.toString() ?? 'custom' : 'custom';
      return ReportRunRow(startedAt: startedAt, status: status, reportType: reportType);
    }).toList();

    final integrityScore = _integrityScore(totalFiles: totalFiles, classifiedRows: blockDayRows.length);
    return ReportsSnapshot(
      totalBytes: totalBytes,
      totalFiles: totalFiles,
      integrityScore: integrityScore,
      blockDayRows: blockDayRows,
      recentRuns: recentRuns,
    );
  }

  Future<ReportGenerationResult> generateStorageUsageReport() async {
    final reportDefinitionId = await _ensureStorageUsageReportDefinition();
    final snapshot = await fetchSnapshot();
    final now = DateTime.now().toUtc();
    final runId = const Uuid().v4();

    await _client.schema(dbSchema).from('report_runs').insert({
      'id': runId,
      'report_definition_id': reportDefinitionId,
      'workspace_id': workspaceId,
      'status': 'completed',
      'started_at': now.toIso8601String(),
      'finished_at': now.toIso8601String(),
      'summary': {
        'total_files': snapshot.totalFiles,
        'total_bytes': snapshot.totalBytes,
        'integrity_score': snapshot.integrityScore,
        'block_day_rows': snapshot.blockDayRows.length,
      },
    });

    return ReportGenerationResult(reportRunId: runId, createdAt: now);
  }

  Future<String> _ensureStorageUsageReportDefinition() async {
    final existing = await _client
        .schema(dbSchema)
        .from('report_definitions')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('report_type', 'storage_usage')
        .limit(1);

    if (existing.isNotEmpty) {
      final row = existing.first;
      final id = row['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }

    final createdId = const Uuid().v4();
    await _client.schema(dbSchema).from('report_definitions').insert({
      'id': createdId,
      'workspace_id': workspaceId,
      'name': 'Faculty Demo Storage Usage',
      'description': 'Auto-created for FileZen faculty demo reporting.',
      'report_type': 'storage_usage',
      'output_format': 'json',
      'is_enabled': true,
      'filters': <String, dynamic>{},
    });
    return createdId;
  }

  static String _normalizeBlock(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? 'Unassigned Block' : v;
  }

  static String _normalizeDay(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Unscheduled';
    final low = v.toLowerCase();
    switch (low) {
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
        return v;
    }
  }

  static int _weekdayOrder(String value) {
    const order = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
      'Unscheduled',
    ];
    final idx = order.indexOf(value);
    return idx == -1 ? order.length : idx;
  }

  static double _integrityScore({required int totalFiles, required int classifiedRows}) {
    if (totalFiles <= 0) return 100;
    final ratio = (classifiedRows / totalFiles).clamp(0, 1);
    return (90 + (ratio * 10));
  }
}

class _Agg {
  _Agg(this.blockLabel, this.dayOfWeek);

  final String blockLabel;
  final String dayOfWeek;
  int fileCount = 0;
  int totalBytes = 0;
}
