import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../data/repositories/explorer_repository_factory.dart';
import '../../domain/models/explorer_item.dart';
import '../../domain/models/explorer_query.dart';
import '../../domain/repositories/explorer_file_crud_repository.dart';
import '../../domain/repositories/explorer_repository.dart';
import 'explorer_file_bytes.dart';
import 'explorer_file_save.dart';

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
  bool _uploading = false;
  bool _galleryView = true;
  String? _lastErrorMessage;

  // In-memory cache for downloaded file bytes (keyed by file ID).
  final Map<String, Uint8List> _bytesCache = {};

  Future<Uint8List> _cachedDownload(ExplorerItem item) async {
    final id = item.id!;
    final cached = _bytesCache[id];
    if (cached != null) return cached;
    final bytes = await _fileCrud.downloadFileBytes(
      fileId: id,
      storageBucket: item.storageBucket ?? '',
      storageObjectPath: item.storageObjectPath ?? '',
    );
    _bytesCache[id] = bytes;
    return bytes;
  }

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
        kind: ExplorerKindFilter.all,
        sortBy: ExplorerSortBy.updatedDesc,
        includeDeleted: false,
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
        kind: ExplorerKindFilter.all,
        sortBy: ExplorerSortBy.updatedDesc,
        includeDeleted: false,
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setState(() => _galleryView = false),
                                icon: Icon(
                                  Icons.view_list_rounded,
                                  color: !_galleryView ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                                ),
                                tooltip: 'List view',
                              ),
                              IconButton(
                                onPressed: () => setState(() => _galleryView = true),
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  color: _galleryView ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                                ),
                                tooltip: 'Gallery view',
                              ),
                            ],
                          ),
                        ],
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
                      _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search files...',
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
              _loadItems();
            },
          );
        }
        return _galleryView ? _buildGallery(items) : _buildList(items);
    }
  }

  Widget _buildList(List<ExplorerItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          color: const Color(0xFF484848).withValues(alpha: 0.15),
          height: 1,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) => _buildFileTile(items[index]),
      ),
    );
  }

  Widget _buildGallery(List<ExplorerItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGalleryTile(items[index]),
    );
  }

  final Map<String, Uint8List?> _thumbnailCache = {};

  Future<Uint8List?> _getThumbnailBytes(ExplorerItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) return null;
    if (_thumbnailCache.containsKey(id)) return _thumbnailCache[id];
    try {
      final bytes = await _cachedDownload(item);
      _thumbnailCache[id] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('Thumbnail load failed for ${item.name}: $e');
      _thumbnailCache[id] = null;
      return null;
    }
  }

  Widget _buildGalleryTile(ExplorerItem item) {
    final ext = _FilePreviewDialog._ext(item.name);
    final isImage = const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif'}.contains(ext);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _previewFile(item),
        onLongPress: () => _showItemActions(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: isImage
                  ? FutureBuilder<Uint8List?>(
                      future: _getThumbnailBytes(item),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: const Color(0xFF1F2020),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFAEC6FF),
                                ),
                              ),
                            ),
                          );
                        }
                        final bytes = snapshot.data;
                        if (bytes == null) return _buildFileIcon(item, isImage);
                        return Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFileIcon(item, isImage),
                        );
                      },
                    )
                  : _buildFileIcon(item, isImage),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF1A1A1A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sizeLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(ExplorerItem item, bool isImage) {
    return Container(
      color: const Color(0xFF1F2020),
      child: Center(
        child: Icon(
          item.isFolder
              ? Icons.folder
              : isImage
                  ? Icons.image_outlined
                  : Icons.insert_drive_file_outlined,
          color: item.isFolder ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
          size: 36,
        ),
      ),
    );
  }

  void _showItemActions(ExplorerItem item) {
    final id = item.id;
    final canMutate = id != null && id.isNotEmpty && !item.isFolder;
    if (!canMutate) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131313),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.preview, color: Color(0xFFACABAA)),
              title: const Text('Preview', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _previewFile(item); },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Color(0xFFACABAA)),
              title: const Text('Download', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _downloadFile(item); },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFFACABAA)),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _copyFile(item); },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFACABAA)),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _renameFile(item); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFEE7D77)),
              title: const Text('Move to trash', style: TextStyle(color: Color(0xFFEE7D77))),
              onTap: () { Navigator.pop(context); _confirmDeleteFile(item); },
            ),
          ],
        ),
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
          '${item.sizeLabel}  ·  ${item.updatedLabel}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFFACABAA),
          ),
        ),
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
        if (value == 'download') {
          await _downloadFile(item);
        } else if (value == 'preview') {
          await _previewFile(item);
        } else if (value == 'copy') {
          await _copyFile(item);
        } else if (value == 'rename') {
          await _renameFile(item);
        } else if (value == 'delete') {
          await _confirmDeleteFile(item);
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(value: 'preview', child: Text('Preview')),
          PopupMenuItem(value: 'download', child: Text('Download')),
          PopupMenuItem(value: 'copy', child: Text('Copy')),
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Move to trash')),
        ];
      },
    );
  }

  Future<void> _downloadFile(ExplorerItem item) async {
    final id = item.id;
    final bucket = item.storageBucket;
    final objectPath = item.storageObjectPath;
    if (id == null || id.isEmpty || bucket == null || objectPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download is unavailable for this item'),
          backgroundColor: Color(0xFF7F2927),
        ),
      );
      return;
    }
    try {
      final bytes = await _cachedDownload(item);
      if (!mounted) return;
      final saved = await saveBytesToDevice(bytes: bytes, fileName: item.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'Downloaded ${item.name}' : 'Download cancelled or not supported on this platform'),
          backgroundColor: saved ? const Color(0xFF2E3E45) : const Color(0xFF7F2927),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download file'), backgroundColor: Color(0xFF7F2927)),
      );
    }
  }

  Future<void> _previewFile(ExplorerItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview is unavailable for this item'),
          backgroundColor: Color(0xFF7F2927),
        ),
      );
      return;
    }

    try {
      final bytes = await _cachedDownload(item);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _FilePreviewDialog(fileName: item.name, bytes: bytes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final reason = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load file preview: $reason',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Color(0xFF7F2927),
        ),
      );
    }
  }

  Future<void> _copyFile(ExplorerItem item) async {
    final id = item.id;
    if (id == null || id.isEmpty) return;
    final strategy = await _askDuplicateStrategy();
    if (strategy == null) return;
    try {
      await _fileCrud.copyFile(
        fileId: id,
        currentName: item.name,
        blockName: item.blockName,
        dayOfWeek: item.dayOfWeek,
        duplicateStrategy: strategy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File copied'), backgroundColor: Color(0xFF2E3E45)),
      );
      await _loadItems();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not copy file'), backgroundColor: Color(0xFF7F2927)),
      );
    }
  }

  Future<ExplorerDuplicateStrategy?> _askDuplicateStrategy() {
    return showDialog<ExplorerDuplicateStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131313),
        title: const Text('Duplicate handling', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Choose what to do if a file with the same name already exists.',
          style: TextStyle(color: Color(0xFFACABAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ExplorerDuplicateStrategy.skip),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ExplorerDuplicateStrategy.replace),
            child: const Text('Replace'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ExplorerDuplicateStrategy.renameWithTimestamp),
            child: const Text('Rename'),
          ),
        ],
      ),
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

class _FilePreviewDialog extends StatefulWidget {
  const _FilePreviewDialog({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final List<int> bytes;

  static String _ext(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  @override
  State<_FilePreviewDialog> createState() => _FilePreviewDialogState();
}

class _FilePreviewDialogState extends State<_FilePreviewDialog> {
  List<Uint8List>? _pdfPages;
  bool _pdfLoading = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    final ext = _FilePreviewDialog._ext(widget.fileName);
    if (ext == 'pdf') _rasterizePdf();
  }

  Future<void> _rasterizePdf() async {
    setState(() => _pdfLoading = true);
    try {
      final pages = <Uint8List>[];
      await for (final page in Printing.raster(Uint8List.fromList(widget.bytes), dpi: 150)) {
        final png = await page.toPng();
        pages.add(png);
      }
      if (!mounted) return;
      setState(() {
        _pdfPages = pages;
        _pdfLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pdfError = e.toString();
        _pdfLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = _FilePreviewDialog._ext(widget.fileName);
    final isImage = const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic', 'heif'}.contains(ext);
    final isText = const {'txt', 'md', 'json', 'csv', 'yaml', 'yml', 'xml', 'log', 'ini'}.contains(ext);
    final isPdf = ext == 'pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Colors.white, fontFamily: 'Manrope'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFAEC6FF)),
      ),
      body: _buildPreviewBody(isImage: isImage, isText: isText, isPdf: isPdf),
    );
  }

  Widget _buildPreviewBody({required bool isImage, required bool isText, required bool isPdf}) {
    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(child: Image.memory(Uint8List.fromList(widget.bytes), fit: BoxFit.contain)),
      );
    }
    if (isPdf) {
      if (_pdfLoading) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFAEC6FF)));
      }
      if (_pdfError != null || _pdfPages == null || _pdfPages!.isEmpty) {
        return const Center(
          child: Text(
            'Could not render PDF preview.\nUse Download to view the file.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFACABAA), height: 1.4),
          ),
        );
      }
      return Container(
        color: Colors.white,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pdfPages!.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(_pdfPages![index], fit: BoxFit.fitWidth),
            ),
          ),
        ),
      );
    }
    if (isText) {
      final text = utf8.decode(widget.bytes, allowMalformed: true);
      final preview = text.length > 20000 ? '${text.substring(0, 20000)}\n\n... (truncated)' : text;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          preview,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFE2E2E2),
            fontSize: 13,
            height: 1.35,
          ),
        ),
      );
    }
    return const Center(
      child: Text(
        'Preview currently supports text, images, and PDFs.\nUse Download for other file types.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFACABAA), height: 1.4),
      ),
    );
  }

}
