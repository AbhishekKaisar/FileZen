import 'package:flutter/material.dart';

import '../../../explorer/data/repositories/explorer_repository_factory.dart';
import '../../../explorer/domain/models/explorer_query.dart';

/// Displays real block summaries fetched from the Explorer repository.
class ProjectBlocksGrid extends StatefulWidget {
  const ProjectBlocksGrid({super.key});

  @override
  State<ProjectBlocksGrid> createState() => _ProjectBlocksGridState();
}

class _BlockSummary {
  _BlockSummary(this.label);
  final String label;
  int fileCount = 0;
  final Map<String, int> dayCounts = {};
}

class _ProjectBlocksGridState extends State<ProjectBlocksGrid> {
  List<_BlockSummary> _blocks = [];
  int _totalFiles = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ExplorerRepositoryFactory.create();
      final files = await repo.fetchItems(
        const ExplorerQuery(kind: ExplorerKindFilter.files, sortBy: ExplorerSortBy.nameAsc),
      );

      final blockMap = <String, _BlockSummary>{};
      for (final f in files) {
        final b = f.blockName.trim().isEmpty ? 'Unassigned' : f.blockName.trim();
        final summary = blockMap.putIfAbsent(b, () => _BlockSummary(b));
        summary.fileCount++;
        final day = f.dayOfWeek.trim().isEmpty ? 'Unscheduled' : f.dayOfWeek.trim();
        summary.dayCounts[day] = (summary.dayCounts[day] ?? 0) + 1;
      }

      final sorted = blockMap.values.toList()
        ..sort((a, b) => b.fileCount.compareTo(a.fileCount));

      if (!mounted) return;
      setState(() {
        _blocks = sorted;
        _totalFiles = files.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _dayAbbrev = {
    'Monday': 'MON',
    'Tuesday': 'TUE',
    'Wednesday': 'WED',
    'Thursday': 'THU',
    'Friday': 'FRI',
    'Saturday': 'SAT',
    'Sunday': 'SUN',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text(
          'Project Blocks',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 56,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.0,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Systematic categorization of your digital assets. Organized by chronological priority and thematic relevance.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: Color(0xFFACABAA),
          ),
        ),
        const SizedBox(height: 40),
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
          ))
        else if (_blocks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF191A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
            ),
            child: const Text(
              'No blocks yet. Upload files from the Explorer tab — they will be auto-classified into blocks.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: Color(0xFFACABAA), height: 1.5),
            ),
          )
        else
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // Primary block (largest)
              if (_blocks.isNotEmpty) _buildPrimaryBlock(_blocks[0].label, _blocks[0]),
              // Summary card
              _buildSummaryCard(),
            ],
          ),
      ],
    );
  }

  Widget _buildPrimaryBlock(String label, _BlockSummary block) {
    // Find the day with the most files for highlighting
    String? activeDay;
    int maxCount = 0;
    block.dayCounts.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        activeDay = day;
      }
    });

    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFAEC6FF).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOP BLOCK',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFAEC6FF),
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: Color(0xFFAEC6FF), size: 30),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${block.fileCount} files',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA)),
                ),
                const Spacer(),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in _dayAbbrev.entries)
                      if (block.dayCounts.containsKey(entry.key))
                        _buildDayPreview(
                          entry.value,
                          '${block.dayCounts[entry.key]}',
                          entry.key == activeDay,
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.view_module, color: Color(0xFFE4DFFF), size: 24),
          const SizedBox(height: 24),
          const Text(
            'All Blocks',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_blocks.length} blocks containing $_totalFiles files.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFFACABAA),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < _blocks.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0 ? const Color(0xFFAEC6FF) : const Color(0xFFE4DFFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _blocks[i].label,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white),
                          ),
                        ),
                        Text(
                          '${_blocks[i].fileCount} files',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPreview(String day, String number, bool isActive) {
    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: isActive ? const Border(bottom: BorderSide(color: Color(0xFFAEC6FF), width: 2)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFFAEC6FF) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
