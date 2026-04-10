import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows the latest organizer scan status from the Supabase `scan_jobs` table.
class AutoSorterStatus extends StatefulWidget {
  const AutoSorterStatus({super.key});

  @override
  State<AutoSorterStatus> createState() => _AutoSorterStatusState();
}

class _AutoSorterStatusState extends State<AutoSorterStatus> {
  String _lastScanLabel = 'No scans yet';
  String _organizedLabel = '';
  bool _isActive = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    const useSupabase = bool.fromEnvironment('USE_SUPABASE_EXPLORER', defaultValue: false);
    const workspaceId = String.fromEnvironment('FILEZEN_WORKSPACE_ID', defaultValue: '');
    const dbSchema = String.fromEnvironment('FILEZEN_DB_SCHEMA', defaultValue: 'app');

    if (!useSupabase || workspaceId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _lastScanLabel = 'Supabase not configured';
        });
      }
      return;
    }

    try {
      final client = Supabase.instance.client;

      // Try to fetch from scan_jobs table
      final rows = await client
          .schema(dbSchema)
          .from('scan_jobs')
          .select('started_at,files_scanned,status')
          .eq('workspace_id', workspaceId)
          .order('started_at', ascending: false)
          .limit(1);

      if (!mounted) return;

      if (rows.isNotEmpty) {
        final row = rows.first;
        final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '');
        final filesScanned = (row['files_scanned'] as num?)?.toInt() ?? 0;
        final status = row['status']?.toString() ?? 'unknown';

        setState(() {
          _isActive = status == 'completed' || status == 'running';
          _lastScanLabel = startedAt != null ? 'Last scan: ${_timeAgo(startedAt)}' : 'Last scan: unknown';
          _organizedLabel = 'Organized $filesScanned files';
          _loading = false;
        });
      } else {
        // No scan jobs yet — check file count as a fallback
        final fileCount = await client
            .schema(dbSchema)
            .from('files')
            .select('id')
            .eq('workspace_id', workspaceId)
            .eq('is_deleted', false);

        if (!mounted) return;
        setState(() {
          _isActive = false;
          _lastScanLabel = 'No scans yet';
          _organizedLabel = '${fileCount.length} files in workspace';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _lastScanLabel = 'Could not load status';
        });
      }
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.05)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 24,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0C4492).withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFFAEC6FF), size: 30),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isActive ? Colors.green : const Color(0xFFACABAA),
                          border: Border.all(color: const Color(0xFF131313), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isActive ? 'Auto-Sorter Active' : 'Auto-Sorter Idle',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isActive
                          ? 'Intelligent file organization in progress'
                          : 'Run the organizer from Settings to classify files',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFFACABAA),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 32,
            runSpacing: 16,
            children: [
              if (!_loading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS TICKER',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFFACABAA),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lastScanLabel,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFAEC6FF),
                            ),
                          ),
                          if (_organizedLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: Color(0xFF484848))),
                            const SizedBox(width: 8),
                            Text(
                              _organizedLabel,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFACABAA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ElevatedButton(
                onPressed: () => context.push('/settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAEC6FF),
                  foregroundColor: const Color(0xFF003D8A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Run Organizer',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
