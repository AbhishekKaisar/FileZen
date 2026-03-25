import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/explorer_repository_factory.dart';
import '../../domain/models/explorer_item.dart';
import '../../domain/models/explorer_query.dart';
import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../../domain/repositories/explorer_repository.dart';
import 'explorer_file_bytes.dart';

class AdvancedExplorerScreen extends StatefulWidget {
  const AdvancedExplorerScreen({super.key});

  @override
  State<AdvancedExplorerScreen> createState() => _AdvancedExplorerScreenState();
}

enum _ExplorerState {
  loading,
  ready,
  empty,
  error,
}

class _AdvancedExplorerScreenState extends State<AdvancedExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ExplorerRepository _repository = ExplorerRepositoryFactory.create();
  final ExplorerFileCrudRepository _fileCrud = ExplorerRepositoryFactory.createFileCrud();
  List<ExplorerItem> _allItems = const [];

  _ExplorerState _state = _ExplorerState.loading;
  ExplorerKindFilter _activeFilter = ExplorerKindFilter.all;
  ExplorerSortBy _sortBy = ExplorerSortBy.nameAsc;
  bool _uploading = false;
  String? _lastErrorMessage;
  static const List<String> _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
    'Unscheduled',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _state = _ExplorerState.loading;
      _lastErrorMessage = null;
    });
    try {
      final query = ExplorerQuery(
        search: _searchController.text,
        kind: _activeFilter,
        sortBy: _sortBy,
      );
      final items = await _repository.fetchItems(query);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _state = items.isEmpty ? _ExplorerState.empty : _ExplorerState.ready;
      });
    } catch (e, st) {
      debugPrint('Explorer load failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _state = _ExplorerState.error;
        _lastErrorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshItemsQuietly() async {
    try {
      final query = ExplorerQuery(
        search: _searchController.text,
        kind: _activeFilter,
        sortBy: _sortBy,
      );
      final items = await _repository.fetchItems(query);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _state = items.isEmpty ? _ExplorerState.empty : _ExplorerState.ready;
      });
    } catch (e, st) {
      debugPrint('Explorer quiet refresh failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _state = _ExplorerState.error;
        _lastErrorMessage = e.toString();
      });
    }
  }

  Future<void> _pickAndCreateFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = await resolvePickerFileBytes(picked);
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read file data. Try another file or pick with in-memory data enabled.'),
          backgroundColor: Color(0xFF7F2927),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      await _fileCrud.createUploadedFile(
        fileName: picked.name,
        bytes: bytes,
        localPath: picked.path,
        contentType: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File uploaded'),
          backgroundColor: Color(0xFF2E3E45),
        ),
      );
      await _refreshItemsQuietly();
    } catch (e, st) {
      debugPrint('Explorer upload failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      final message = e is StateError ? e.message : 'Upload failed: ${e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: const Color(0xFF7F2927),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0E0E0E),
          floatingActionButton: FloatingActionButton(
            onPressed: _uploading ? null : _pickAndCreateFile,
            tooltip: 'Upload file',
            backgroundColor: const Color(0xFFAEC6FF),
            foregroundColor: const Color(0xFF003D8A),
            child: const Icon(Icons.upload_file, size: 28),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explorer',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 46,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Browse and manage files across your vault.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Color(0xFFACABAA),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSearchAndFilters(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_uploading) ...[
          ModalBarrier(
            color: Colors.black.withValues(alpha: 0.45),
            dismissible: false,
          ),
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFAEC6FF),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search files and folders...',
              hintStyle: const TextStyle(color: Color(0xFF767575)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFACABAA)),
              filled: true,
              fillColor: const Color(0xFF131313),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFAEC6FF)),
              ),
            ),
          ),
        ),
        _buildFilterChip(label: 'All', filter: ExplorerKindFilter.all),
        _buildFilterChip(label: 'Folders', filter: ExplorerKindFilter.folders),
        _buildFilterChip(label: 'Files', filter: ExplorerKindFilter.files),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required ExplorerKindFilter filter}) {
    final bool selected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _activeFilter = filter;
        });
        _loadItems();
      },
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF003D8A) : const Color(0xFFACABAA),
        fontWeight: FontWeight.w600,
      ),
      selectedColor: const Color(0xFFAEC6FF),
      backgroundColor: const Color(0xFF1F2020),
      side: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      showCheckmark: false,
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExplorerSortBy>(
          value: _sortBy,
          dropdownColor: const Color(0xFF1F2020),
          iconEnabledColor: const Color(0xFFACABAA),
          style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
          items: const [
            DropdownMenuItem(
              value: ExplorerSortBy.nameAsc,
              child: Text('Name A-Z'),
            ),
            DropdownMenuItem(
              value: ExplorerSortBy.nameDesc,
              child: Text('Name Z-A'),
            ),
            DropdownMenuItem(
              value: ExplorerSortBy.updatedDesc,
              child: Text('Recently Updated'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _sortBy = value;
            });
            _loadItems();
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ExplorerState.loading:
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFAEC6FF),
          ),
        );
      case _ExplorerState.error:
        return _buildStatusCard(
          icon: Icons.error_outline,
          title: 'Could not load files',
          subtitle: _lastErrorMessage == null || _lastErrorMessage!.trim().isEmpty
              ? 'Please retry. Network or backend service may be unavailable.'
              : 'Please retry. ${_lastErrorMessage!}',
          actionLabel: 'Retry',
          onTap: _loadItems,
        );
      case _ExplorerState.empty:
        return _buildStatusCard(
          icon: Icons.folder_off_outlined,
          title: 'No files found',
          subtitle: 'This folder is empty. Upload files to get started.',
          actionLabel: 'Refresh',
          onTap: _loadItems,
        );
      case _ExplorerState.ready:
        final items = _allItems;
        if (items.isEmpty) {
          return _buildStatusCard(
            icon: Icons.search_off_outlined,
            title: 'No matching results',
            subtitle: 'Try changing search text or filters.',
            actionLabel: 'Clear search',
            onTap: () {
              _searchController.clear();
              setState(() {
                _activeFilter = ExplorerKindFilter.all;
              });
              _loadItems();
            },
          );
        }
        return _buildList(items);
    }
  }

  Widget _buildList(List<ExplorerItem> items) {
    final grouped = _groupByBlockAndDay(items);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: grouped.entries
            .map((blockEntry) => _buildBlockSection(
                  blockName: blockEntry.key,
                  dayGroups: blockEntry.value,
                ))
            .toList(),
      ),
    );
  }

  Map<String, Map<String, List<ExplorerItem>>> _groupByBlockAndDay(List<ExplorerItem> items) {
    final Map<String, Map<String, List<ExplorerItem>>> grouped = {};
    for (final item in items) {
      final blockName = item.blockName.trim().isEmpty ? 'Unassigned Block' : item.blockName.trim();
      final dayName = _normalizeDay(item.dayOfWeek);
      grouped.putIfAbsent(blockName, () => {});
      grouped[blockName]!.putIfAbsent(dayName, () => []);
      grouped[blockName]![dayName]!.add(item);
    }

    final sortedBlocks = grouped.keys.toList()..sort();
    final Map<String, Map<String, List<ExplorerItem>>> result = {};
    for (final block in sortedBlocks) {
      final days = grouped[block]!;
      final sortedDays = days.keys.toList()
        ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));
      result[block] = {
        for (final day in sortedDays) day: days[day]!,
      };
    }
    return result;
  }

  String _normalizeDay(String rawDay) {
    final normalized = rawDay.trim();
    final found = _dayOrder.firstWhere(
      (day) => day.toLowerCase() == normalized.toLowerCase(),
      orElse: () => 'Unscheduled',
    );
    return found;
  }

  Widget _buildBlockSection({
    required String blockName,
    required Map<String, List<ExplorerItem>> dayGroups,
  }) {
    final totalCount = dayGroups.values.fold<int>(0, (sum, list) => sum + list.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF191A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                blockName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount items organized by day',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFACABAA),
                ),
              ),
              const SizedBox(height: 12),
              ...dayGroups.entries.map(
                (dayEntry) => _buildDaySection(
                  dayName: dayEntry.key,
                  items: dayEntry.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection({
    required String dayName,
    required List<ExplorerItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFFAEC6FF),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(_buildFileTile),
        ],
      ),
    );
  }

  Widget _buildFileTile(ExplorerItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.isFolder ? const Color(0xFF2E3E45) : const Color(0xFF1F2020),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            item.isFolder ? Icons.folder : Icons.insert_drive_file,
            color: item.isFolder ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${item.path}\n${item.updatedLabel}  -  ${item.sizeLabel}',
          style: const TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFFACABAA),
            height: 1.4,
          ),
        ),
        isThreeLine: true,
        trailing: _buildItemMenu(item),
      ),
    );
  }

  Widget _buildItemMenu(ExplorerItem item) {
    final id = item.id;
    final canMutate = id != null && id.isNotEmpty && !item.isFolder;
    if (!canMutate) {
      return const SizedBox(width: 8);
    }
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFFACABAA)),
      color: const Color(0xFF1F2020),
      onSelected: (value) async {
        if (value == 'rename') {
          await _renameFile(item);
        } else if (value == 'delete') {
          await _confirmDeleteFile(item);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Move to trash')),
      ],
    );
  }

  Future<void> _renameFile(ExplorerItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) return;

    final controller = TextEditingController(text: item.name);
    try {
      final newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF131313),
          title: const Text('Rename file', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'File name',
              hintStyle: const TextStyle(color: Color(0xFF767575)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFAEC6FF)),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFACABAA))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save', style: TextStyle(color: Color(0xFFAEC6FF))),
            ),
          ],
        ),
      );

      if (newName == null || newName.isEmpty || !mounted) return;

      try {
        await _fileCrud.renameFile(fileId: id, newName: newName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File renamed'), backgroundColor: Color(0xFF2E3E45)),
        );
        await _loadItems();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not rename file'), backgroundColor: Color(0xFF7F2927)),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDeleteFile(ExplorerItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131313),
        title: const Text('Move to trash?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will mark "${item.name}" as deleted.',
          style: const TextStyle(color: Color(0xFFACABAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFACABAA))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEE7D77))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _fileCrud.softDeleteFile(fileId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File moved to trash'), backgroundColor: Color(0xFF2E3E45)),
      );
      await _loadItems();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete file'), backgroundColor: Color(0xFF7F2927)),
      );
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFAEC6FF), size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFACABAA),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAEC6FF),
                  foregroundColor: const Color(0xFF003D8A),
                ),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
