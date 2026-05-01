import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

import '../../../explorer/data/explorer_byte_format.dart';

/// Queries Supabase for real storage totals, or shows zero-state when unavailable.
class StorageOverviewWidget extends StatefulWidget {
  const StorageOverviewWidget({super.key});

  @override
  State<StorageOverviewWidget> createState() => _StorageOverviewWidgetState();
}

class _StorageOverviewWidgetState extends State<StorageOverviewWidget> {
  int _usedBytes = 0;
  int _totalFiles = 0;
  int _capacityBytes = 0;
  int _supabaseStorageUsed = 0;
  static const int _supabaseStorageLimit = 1024 * 1024 * 1024; // 1 GB free tier
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    const useSupabase = bool.fromEnvironment('USE_SUPABASE_EXPLORER', defaultValue: false);
    const workspaceId = String.fromEnvironment('FILEZEN_WORKSPACE_ID', defaultValue: '');
    const dbSchema = String.fromEnvironment('FILEZEN_DB_SCHEMA', defaultValue: 'app');

    if (!useSupabase || workspaceId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .schema(dbSchema)
          .from('files')
          .select('size_bytes')
          .eq('workspace_id', workspaceId)
          .eq('is_deleted', false);

      int total = 0;
      for (final row in rows) {
        total += ((row['size_bytes'] as num?) ?? 0).toInt();
      }
      if (!mounted) return;

      // Determine workspace capacity: try workspace_settings first,
      // otherwise auto-scale to a readable tier above actual usage.
      int capacity = _autoCapacity(total);
      try {
        final settingsRows = await client
            .schema(dbSchema)
            .from('workspace_settings')
            .select('storage_quota_bytes')
            .eq('workspace_id', workspaceId)
            .limit(1);
        if (settingsRows.isNotEmpty) {
          final quota = (settingsRows.first['storage_quota_bytes'] as num?)?.toInt();
          if (quota != null && quota > 0) capacity = quota;
        }
      } catch (_) {
        // workspace_settings may not have this column; use auto-scale.
      }

      // Fetch actual Supabase storage bucket usage.
      int bucketUsed = total;
      try {
        final storageRows = await client
            .schema(dbSchema)
            .from('files')
            .select('size_bytes')
            .eq('workspace_id', workspaceId);
        int storageTotal = 0;
        for (final row in storageRows) {
          storageTotal += ((row['size_bytes'] as num?) ?? 0).toInt();
        }
        bucketUsed = storageTotal;
      } catch (_) {
        // Fall back to the non-deleted total.
      }

      if (!mounted) return;
      setState(() {
        _usedBytes = total;
        _totalFiles = rows.length;
        _capacityBytes = capacity;
        _supabaseStorageUsed = bucketUsed;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pick the next readable tier above [usedBytes] so the ring chart
  /// shows a meaningful percentage (e.g. 4.7 MB used → 10 MB capacity → 47%).
  static int _autoCapacity(int usedBytes) {
    if (usedBytes <= 0) return 100 * 1024 * 1024; // 100 MB default
    const tiers = [
      10 * 1024 * 1024,        //   10 MB
      50 * 1024 * 1024,        //   50 MB
      100 * 1024 * 1024,       //  100 MB
      500 * 1024 * 1024,       //  500 MB
      1024 * 1024 * 1024,      //    1 GB
    ];
    for (final tier in tiers) {
      if (usedBytes < tier) return tier;
    }
    // Above 1 GB: round up to the next whole GB.
    const gb = 1024 * 1024 * 1024;
    return ((usedBytes / gb).ceil() + 1) * gb;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator(color: Color(0xFFAEC6FF))),
      );
    }

    final percentage = _capacityBytes > 0
        ? ((_usedBytes / _capacityBytes) * 100).clamp(0, 100).toDouble()
        : 0.0;
    final freeBytes = (_capacityBytes - _usedBytes).clamp(0, _capacityBytes);
    final usedLabel = ExplorerByteFormat.humanReadable(_usedBytes);
    final freeLabel = ExplorerByteFormat.humanReadable(freeBytes);
    final totalLabel = ExplorerByteFormat.humanReadable(_capacityBytes);
    final percentText = '${percentage.toStringAsFixed(0)}%';

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 40.0,
      runSpacing: 40.0,
      children: [
        // Ring Chart Visualization
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _RingChartPainter(
                  percentage: percentage,
                  backgroundColor: const Color(0xFF2E3E45),
                  gradientColors: const [Color(0xFFAEC6FF), Color(0xFF0C4492)],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percentText,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: Color(0xFFAEC6FF),
                    ),
                  ),
                  const Text(
                    'CAPACITY USED',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Storage Details
        Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vault Storage',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalFiles files indexed. Currently managing $usedLabel of $totalLabel workspace capacity.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFFACABAA),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatCard('USED SPACE', usedLabel, Colors.white),
                  const SizedBox(width: 16),
                  _buildStatCard('FREE SPACE', freeLabel, const Color(0xFFAEC6FF)),
                ],
              ),
              const SizedBox(height: 20),
              _buildSupabaseStorageBar(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSupabaseStorageBar() {
    final usedLabel = ExplorerByteFormat.humanReadable(_supabaseStorageUsed);
    final limitLabel = ExplorerByteFormat.humanReadable(_supabaseStorageLimit);
    final fraction = (_supabaseStorageUsed / _supabaseStorageLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUPABASE STORAGE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: Color(0xFFACABAA),
                ),
              ),
              Text(
                '$usedLabel / $limitLabel',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFACABAA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: const Color(0xFF2E3E45),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3ECF8E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131313),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFACABAA),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final List<Color> gradientColors;

  _RingChartPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * (percentage / 100);
    if (sweepAngle <= 0) return; // nothing to draw at 0%

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
