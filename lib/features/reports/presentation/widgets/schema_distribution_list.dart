import 'package:flutter/material.dart';

import '../../data/reports_repository.dart';

class SchemaDistributionList extends StatelessWidget {
  const SchemaDistributionList({
    super.key,
    required this.rows,
    required this.recentRuns,
  });

  final List<BlockDayRow> rows;
  final List<ReportRunRow> recentRuns;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A), // surface-container
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2020).withValues(alpha: 0.3), // surface-container-high
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data Distribution',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.filter_list, color: Color(0xFFACABAA)), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.more_vert, color: Color(0xFFACABAA)), onPressed: () {}),
                  ],
                )
              ],
            ),
          ),
          // Scrollable Table Body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: Column(
                children: [
                  _buildHeaderRow(),
                  if (rows.isEmpty)
                    _buildEmptyRow()
                  else
                    ...rows.take(14).map(_buildDataRow),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF131313), // surface-container-low
              border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${rows.isEmpty ? 0 : rows.length.clamp(0, 14)} of ${rows.length} block/day groups',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA)),
                ),
                Text(
                  recentRuns.isEmpty ? 'No report runs yet' : 'Latest run: ${recentRuns.first.status.toUpperCase()}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
      ),
      child: Row(
        // On web, this header row can end up under unbounded width constraints.
        // Shrink-wrap horizontally to avoid a flex layout fighting infinite width.
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 3,
            fit: FlexFit.loose,
            child: Text(
              'BLOCK',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Color(0xFFACABAA),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            fit: FlexFit.loose,
            child: Text(
              'DAY',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Color(0xFFACABAA),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'FILES',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Color(0xFFACABAA),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'SIZE',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Color(0xFFACABAA),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            fit: FlexFit.loose,
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(
                'STATUS',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Color(0xFFACABAA),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
      ),
      child: const Row(
        children: [
          Text(
            'No classified files yet. Upload files and assign block/day to populate this view.',
            style: TextStyle(color: Color(0xFFACABAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BlockDayRow row) {
    final status = row.fileCount > 0 ? 'Active' : 'Idle';
    final statusColor = row.fileCount > 0 ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(
              row.blockLabel,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(row.dayOfWeek, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('${row.fileCount}', style: const TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.white)),
            ),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(_formatBytes(row.totalBytes), style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFAEC6FF))),
            ),
          ),
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var index = 0;
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index += 1;
    }
    final display = size >= 10 || index == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
    return '$display ${units[index]}';
  }
}
