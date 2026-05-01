import 'package:flutter/material.dart';

import '../../../explorer/data/repositories/explorer_repository_factory.dart';
import '../../../explorer/domain/models/explorer_item.dart';
import '../../../explorer/domain/models/explorer_query.dart';
import '../../../explorer/domain/repositories/explorer_repository.dart';

class BlockOrganizerScreen extends StatefulWidget {
  const BlockOrganizerScreen({super.key});

  @override
  State<BlockOrganizerScreen> createState() => _BlockOrganizerScreenState();
}

class _BlockOrganizerScreenState extends State<BlockOrganizerScreen> {
  final ExplorerRepository _repository = ExplorerRepositoryFactory.create();

  List<ExplorerItem> _allItems = const [];
  String? _selectedDay;
  bool _loading = true;
  String? _error;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchItems(
        ExplorerQuery(
          kind: ExplorerKindFilter.files,
          sortBy: ExplorerSortBy.nameAsc,
          organizerDayOfWeek: _selectedDay,
        ),
      );
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load files.';
        _loading = false;
      });
    }
  }

  void _onDaySelected(String? day) {
    setState(() => _selectedDay = day);
    _loadItems();
  }

  static String _fileCategory(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return 'Other';
    final ext = fileName.substring(dot + 1).toLowerCase();
    if (const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif', 'svg'}.contains(ext)) {
      return 'Images';
    }
    if (const {'txt', 'md', 'log', 'csv', 'ini'}.contains(ext)) {
      return 'Text';
    }
    if (const {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'odt'}.contains(ext)) {
      return 'Documents';
    }
    if (const {'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm'}.contains(ext)) {
      return 'Videos';
    }
    if (const {'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a'}.contains(ext)) {
      return 'Audio';
    }
    if (const {'zip', 'rar', '7z', 'tar', 'gz', 'bz2'}.contains(ext)) {
      return 'Archives';
    }
    if (const {'json', 'xml', 'yaml', 'yml', 'html', 'css', 'js', 'ts', 'dart', 'py', 'java', 'kt', 'swift', 'c', 'cpp', 'h', 'rb', 'go', 'rs'}.contains(ext)) {
      return 'Code';
    }
    return 'Other';
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Images': return Icons.image_outlined;
      case 'Text': return Icons.description_outlined;
      case 'Documents': return Icons.article_outlined;
      case 'Videos': return Icons.videocam_outlined;
      case 'Audio': return Icons.audiotrack_outlined;
      case 'Archives': return Icons.archive_outlined;
      case 'Code': return Icons.code_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Map<String, List<ExplorerItem>> _groupByCategory(List<ExplorerItem> items) {
    final Map<String, List<ExplorerItem>> grouped = {};
    for (final item in items) {
      final category = _fileCategory(item.name);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }
    // Sort categories: Images first, then alphabetical
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        const order = ['Images', 'Documents', 'Text', 'Code', 'Videos', 'Audio', 'Archives', 'Other'];
        return order.indexOf(a).compareTo(order.indexOf(b));
      });
    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organizer',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 46,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Files organized by type and schedule.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDayChips(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedDay == null,
            onSelected: (_) => _onDaySelected(null),
            labelStyle: TextStyle(
              color: _selectedDay == null ? const Color(0xFF003D8A) : const Color(0xFFACABAA),
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
            selectedColor: const Color(0xFFAEC6FF),
            backgroundColor: const Color(0xFF1F2020),
            side: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.25)),
            showCheckmark: false,
          ),
          const SizedBox(width: 8),
          for (final day in _days) ...[
            ChoiceChip(
              label: Text(day.substring(0, 3)),
              selected: _selectedDay == day,
              onSelected: (_) => _onDaySelected(day),
              labelStyle: TextStyle(
                color: _selectedDay == day ? const Color(0xFF003D8A) : const Color(0xFFACABAA),
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
              selectedColor: const Color(0xFFAEC6FF),
              backgroundColor: const Color(0xFF1F2020),
              side: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.25)),
              showCheckmark: false,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xFFFF9993), fontFamily: 'Inter')),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadItems,
              child: const Text('Retry', style: TextStyle(color: Color(0xFFAEC6FF))),
            ),
          ],
        ),
      );
    }

    if (_allItems.isEmpty) {
      return const Center(
        child: Text(
          'No files found for this filter.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA)),
        ),
      );
    }

    final grouped = _groupByCategory(_allItems);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final items = grouped[category]!;
        return _buildCategorySection(category, items);
      },
    );
  }

  Widget _buildCategorySection(String category, List<ExplorerItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_categoryIcon(category), color: const Color(0xFFAEC6FF), size: 20),
              const SizedBox(width: 8),
              Text(
                '$category (${items.length})',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131313),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildFileTile(items[i]),
                  if (i < items.length - 1)
                    Divider(
                      color: const Color(0xFF484848).withValues(alpha: 0.15),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTile(ExplorerItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2020),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _categoryIcon(_fileCategory(item.name)),
          color: const Color(0xFFACABAA),
          size: 20,
        ),
      ),
      title: Text(
        item.name,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.sizeLabel}  ·  ${item.dayOfWeek}',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Color(0xFFACABAA),
        ),
      ),
    );
  }
}
