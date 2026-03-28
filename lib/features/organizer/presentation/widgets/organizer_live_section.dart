import 'package:flutter/material.dart';

import '../../../explorer/data/repositories/explorer_repository_factory.dart';
import '../../../explorer/domain/models/explorer_item.dart';
import '../../../explorer/domain/models/explorer_query.dart';
import '../../../explorer/domain/repositories/explorer_repository.dart';
import 'day_tabs_selector.dart';
import 'session_file_list.dart';

/// Live organizer: distinct **blocks** from file rows, **day** filter, list from the same repository as Explorer.
class OrganizerLiveSection extends StatefulWidget {
  const OrganizerLiveSection({super.key});

  @override
  State<OrganizerLiveSection> createState() => _OrganizerLiveSectionState();
}

class _OrganizerLiveSectionState extends State<OrganizerLiveSection> {
  final ExplorerRepository _repository = ExplorerRepositoryFactory.create();

  List<String> _blockLabels = const [];
  String? _selectedBlock;
  String? _selectedDay;
  List<ExplorerItem> _rows = const [];

  bool _loadingMeta = true;
  bool _loadingRows = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reloadMeta();
  }

  Future<void> _reloadMeta() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final allFiles = await _repository.fetchItems(
        const ExplorerQuery(kind: ExplorerKindFilter.files, sortBy: ExplorerSortBy.nameAsc),
      );
      final blocks = <String>{};
      for (final item in allFiles) {
        final b = item.blockName.trim();
        if (b.isEmpty) continue;
        blocks.add(b);
      }
      final sorted = blocks.toList()..sort();
      if (!mounted) return;
      setState(() {
        _blockLabels = sorted;
        _selectedBlock = sorted.isNotEmpty ? sorted.first : null;
        _selectedDay = null;
        _loadingMeta = false;
      });
      await _reloadRows();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load organizer data.';
        _loadingMeta = false;
      });
    }
  }

  Future<void> _reloadRows() async {
    final block = _selectedBlock;
    if (block == null || block.isEmpty) {
      setState(() => _rows = const []);
      return;
    }
    setState(() => _loadingRows = true);
    try {
      final items = await _repository.fetchItems(
        ExplorerQuery(
          kind: ExplorerKindFilter.files,
          sortBy: ExplorerSortBy.updatedDesc,
          organizerBlockLabel: block,
          organizerDayOfWeek: _selectedDay,
        ),
      );
      if (!mounted) return;
      setState(() {
        _rows = items;
        _loadingRows = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loadingRows = false;
      });
    }
  }

  void _onBlockSelected(String? block) {
    if (block == null) return;
    setState(() => _selectedBlock = block);
    _reloadRows();
  }

  void _onDaySelected(String? day) {
    setState(() => _selectedDay = day);
    _reloadRows();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildError();
    }

    if (_loadingMeta) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
        ),
      );
    }

    if (_blockLabels.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF191A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
        ),
        child: const Text(
          'No organizer blocks yet. Open Explorer, upload files (they are tagged with a block and weekday), then return here.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.5,
            color: Color(0xFFACABAA),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live organizer',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose a block and weekday. Data comes from the same source as Explorer (mock or Supabase).',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFFACABAA),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Block',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final label in _blockLabels)
              ChoiceChip(
                label: Text(label),
                selected: _selectedBlock == label,
                onSelected: (_) => _onBlockSelected(label),
                labelStyle: TextStyle(
                  color: _selectedBlock == label ? const Color(0xFF003D8A) : const Color(0xFFACABAA),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
                selectedColor: const Color(0xFFAEC6FF),
                backgroundColor: const Color(0xFF1F2020),
                side: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.25)),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Day of week',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        DayTabsSelector(
          selectedDay: _selectedDay,
          onSelectDay: _onDaySelected,
        ),
        const SizedBox(height: 24),
        SessionFileList(
          items: _rows,
          isLoading: _loadingRows,
          blockLabel: _selectedBlock,
          dayLabel: _selectedDay,
        ),
      ],
    );
  }

  Widget _buildError() {
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
          Text(_error!, style: const TextStyle(color: Color(0xFFFF9993), fontFamily: 'Inter')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _reloadMeta,
            child: const Text('Retry', style: TextStyle(color: Color(0xFFAEC6FF))),
          ),
        ],
      ),
    );
  }
}
