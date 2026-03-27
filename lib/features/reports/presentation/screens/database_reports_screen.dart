import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/reports_repository.dart';
import '../widgets/reports_header_widget.dart';
import '../widgets/storage_metrics_cards.dart';
import '../widgets/schema_distribution_list.dart';

class DatabaseReportsScreen extends StatefulWidget {
  const DatabaseReportsScreen({super.key});

  @override
  State<DatabaseReportsScreen> createState() => _DatabaseReportsScreenState();
}

class _DatabaseReportsScreenState extends State<DatabaseReportsScreen> {
  ReportsRepository? _repository;
  ReportsSnapshot? _snapshot;
  String? _error;
  bool _loading = true;
  bool _generating = false;
  DateTime? _lastGeneratedAt;

  @override
  void initState() {
    super.initState();
    _repository = _tryBuildRepository();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final repo = _repository;
    if (repo == null) {
      setState(() {
        _loading = false;
        _error = 'Reports require Supabase mode and FILEZEN_WORKSPACE_ID.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await repo.fetchSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _generateReport() async {
    final repo = _repository;
    if (repo == null || _generating) return;
    setState(() => _generating = true);
    try {
      final result = await repo.generateStorageUsageReport();
      if (!mounted) return;
      setState(() => _lastGeneratedAt = result.createdAt.toLocal());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report run saved: ${result.reportRunId.substring(0, 8)}...'),
          backgroundColor: const Color(0xFF2E3E45),
        ),
      );
      await _loadSnapshot();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate report: $e'),
          backgroundColor: const Color(0xFF7F2927),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  ReportsRepository? _tryBuildRepository() {
    const useSupabase = bool.fromEnvironment('USE_SUPABASE_EXPLORER', defaultValue: false);
    const workspaceId = String.fromEnvironment('FILEZEN_WORKSPACE_ID', defaultValue: '');
    const dbSchema = String.fromEnvironment('FILEZEN_DB_SCHEMA', defaultValue: 'app');
    if (!useSupabase || workspaceId.isEmpty) return null;
    try {
      return ReportsRepository(
        client: Supabase.instance.client,
        workspaceId: workspaceId,
        dbSchema: dbSchema,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReportsHeaderWidget(
                        onGenerate: _generateReport,
                        generating: _generating,
                        lastGeneratedAt: _lastGeneratedAt,
                      ),
                      const SizedBox(height: 48),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
                          ),
                        )
                      else if (_error != null)
                        _ErrorCard(message: _error!, onRetry: _loadSnapshot)
                      else if (snapshot != null) ...[
                        StorageMetricsCards(
                          totalBytes: snapshot.totalBytes,
                          totalFiles: snapshot.totalFiles,
                          integrityScore: snapshot.integrityScore,
                        ),
                        const SizedBox(height: 48),
                        SchemaDistributionList(
                          rows: snapshot.blockDayRows,
                          recentRuns: snapshot.recentRuns,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load reports',
            style: TextStyle(color: Colors.white, fontFamily: 'Manrope', fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFFACABAA))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAEC6FF),
              foregroundColor: const Color(0xFF003D8A),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
