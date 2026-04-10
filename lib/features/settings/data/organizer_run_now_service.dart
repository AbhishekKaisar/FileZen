import 'package:supabase_flutter/supabase_flutter.dart';

import '../../explorer/data/file_metadata_pipeline.dart';

class OrganizerRunNowResult {
  const OrganizerRunNowResult({
    required this.updatedCount,
    required this.jobId,
  });

  final int updatedCount;
  final String jobId;
}

class OrganizerRunNowService {
  OrganizerRunNowService({
    required SupabaseClient client,
    required this.workspaceId,
    this.dbSchema = 'app',
  }) : _client = client;

  final SupabaseClient _client;
  final String workspaceId;
  final String dbSchema;

  Future<OrganizerRunNowResult> runNow() async {
    final startedAt = DateTime.now().toUtc().toIso8601String();
    final runningInsert = await _client.schema(dbSchema).from('scan_jobs').insert({
      'workspace_id': workspaceId,
      'job_type': 'metadata_extract',
      'status': 'running',
      'progress_percent': 0,
      'started_at': startedAt,
      'result_summary': const {'updated_file_count': 0},
    }).select('id').limit(1);
    final runningJobId = runningInsert.first['id']?.toString() ?? '';

    final rows = await _client
        .schema(dbSchema)
        .from('files')
        .select('id,name,extension,mime_type,size_bytes,created_at,updated_at')
        .eq('workspace_id', workspaceId)
        .eq('is_deleted', false)
        .limit(2000);

    var updated = 0;
    for (final dynamic raw in rows) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final ext = (raw['extension']?.toString() ?? '').toLowerCase();
      final mime = (raw['mime_type']?.toString() ?? '').toLowerCase();
      final createdAt = DateTime.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now().toUtc();
      final updatedAt = DateTime.tryParse(raw['updated_at']?.toString() ?? '') ?? createdAt;
      final block = FileMetadataPipeline.blockFor(ext: ext, mime: mime);
      final day = _weekdayName(createdAt.toLocal().weekday);
      final mediaCategory = FileMetadataPipeline.mediaCategoryFor(ext: ext, mime: mime);
      final size = (raw['size_bytes'] as num?)?.toInt() ?? 0;
      await _client.schema(dbSchema).from('files').update({
        'organizer_block_label': block,
        'organizer_day_of_week': day,
        'media_category': mediaCategory,
        'indexed_at': DateTime.now().toUtc().toIso8601String(),
        'metadata': {
          'block': block,
          'day_of_week': day,
          'media_category': mediaCategory,
        },
      }).eq('id', id);
      await _client.schema(dbSchema).from('file_metadata').upsert({
        'file_id': id,
        'fs_metadata': {
          'extension': ext,
          'mime_type': mime,
          'size_bytes': size,
          'created_at': createdAt.toIso8601String(),
          'updated_at': updatedAt.toIso8601String(),
        },
      });
      updated += 1;
    }

    await _client.schema(dbSchema).from('workspace_settings').upsert({
      'workspace_id': workspaceId,
      'auto_sort_enabled': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final summary = <String, dynamic>{
      'updated_file_count': updated,
      'strategy': 'extension+metadata',
      'workspace_id': workspaceId,
    };
    final finishedAt = DateTime.now().toUtc().toIso8601String();
    if (runningJobId.isNotEmpty) {
      await _client.schema(dbSchema).from('scan_jobs').update({
        'status': 'completed',
        'progress_percent': 100,
        'finished_at': finishedAt,
        'result_summary': summary,
      }).eq('id', runningJobId);
    }
    await _client.schema(dbSchema).from('audit_events').insert({
      'workspace_id': workspaceId,
      'actor_label': 'organizer_run_now',
      'entity_type': 'scan_job',
      'entity_id': runningJobId.isEmpty ? null : runningJobId,
      'action': 'metadata_extracted',
      'metadata': summary,
    });

    final jobId = runningJobId;
    return OrganizerRunNowResult(updatedCount: updated, jobId: jobId);
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday'; // DateTime.weekday is always 1–7; fallback should not occur
    }
  }
}
