import 'package:supabase_flutter/supabase_flutter.dart';

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
    final rows = await _client
        .schema(dbSchema)
        .from('files')
        .select('id,extension,mime_type,created_at')
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
      final block = _blockFor(ext: ext, mime: mime);
      final day = _weekdayName(createdAt.toLocal().weekday);
      await _client.schema(dbSchema).from('files').update({
        'organizer_block_label': block,
        'organizer_day_of_week': day,
        'metadata': {
          'block': block,
          'day_of_week': day,
        },
      }).eq('id', id);
      updated += 1;
    }

    await _client.schema(dbSchema).from('workspace_settings').upsert({
      'workspace_id': workspaceId,
      'auto_sort_enabled': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    final summary = {
      'updated_file_count': updated,
      'strategy': 'extension+metadata',
    };
    final inserted = await _client.schema(dbSchema).from('scan_jobs').insert({
      'workspace_id': workspaceId,
      'job_type': 'reindex_files',
      'status': 'completed',
      'progress_percent': 100,
      'started_at': DateTime.now().toUtc().toIso8601String(),
      'finished_at': DateTime.now().toUtc().toIso8601String(),
      'result_summary': summary,
    }).select('id').limit(1);

    final row = inserted.first;
    final jobId = row['id']?.toString() ?? '';
    return OrganizerRunNowResult(updatedCount: updated, jobId: jobId);
  }

  String _blockFor({required String ext, required String mime}) {
    const docs = {'pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt', 'xls', 'xlsx'};
    const media = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'mp4', 'mp3', 'wav'};
    const code = {'dart', 'js', 'ts', 'py', 'java', 'cpp', 'c', 'h'};
    const archive = {'zip', 'rar', '7z', 'tar', 'gz'};
    if (docs.contains(ext) || mime.startsWith('application/pdf')) return 'Documents Block';
    if (media.contains(ext) || mime.startsWith('image/') || mime.startsWith('video/')) return 'Media Block';
    if (code.contains(ext) || mime.startsWith('text/')) return 'Code Block';
    if (archive.contains(ext)) return 'Archive Block';
    return 'General Block';
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
        return 'Unscheduled';
    }
  }
}
