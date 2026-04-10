import 'package:flutter/material.dart';

import '../../../explorer/data/repositories/explorer_repository_factory.dart';
import '../../../explorer/domain/models/explorer_item.dart';
import '../../../explorer/domain/models/explorer_query.dart';

/// Quick-access cards showing real recent files and block summaries from the repository.
class QuickAccessGrid extends StatefulWidget {
  const QuickAccessGrid({super.key});

  @override
  State<QuickAccessGrid> createState() => _QuickAccessGridState();
}

class _QuickAccessGridState extends State<QuickAccessGrid> {
  List<ExplorerItem> _recentFiles = const [];
  List<String> _blockLabels = const [];
  int _totalFiles = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ExplorerRepositoryFactory.create();
      final files = await repo.fetchItems(
        const ExplorerQuery(
          kind: ExplorerKindFilter.files,
          sortBy: ExplorerSortBy.updatedDesc,
        ),
      );
      final blocks = <String>{};
      for (final f in files) {
        final b = f.blockName.trim();
        if (b.isNotEmpty) blocks.add(b);
      }
      if (!mounted) return;
      setState(() {
        _recentFiles = files.take(4).toList();
        _blockLabels = blocks.toList()..sort();
        _totalFiles = files.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.speed, color: Color(0xFFAEC6FF)),
            SizedBox(width: 12),
            Text(
              'Quick Access',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFAEC6FF)))
        else
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildCard(
                title: 'Recent',
                subtitle: 'Continue where you left off with your latest activity.',
                icon: Icons.history,
                iconColor: const Color(0xFFAEC6FF),
                iconBgColor: const Color(0xFFAEC6FF).withValues(alpha: 0.1),
                backgroundIcon: Icons.schedule,
                content: _recentFiles.isEmpty
                    ? const Text('No files yet. Upload from Explorer.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFACABAA)))
                    : Column(
                        children: [
                          for (var i = 0; i < _recentFiles.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _buildListItem(
                              _iconForFile(_recentFiles[i]),
                              _recentFiles[i].name,
                              i == 0 ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                              i == 0,
                            ),
                          ],
                        ],
                      ),
              ),
              _buildCard(
                title: 'Blocks',
                subtitle: 'File organization blocks in your workspace.',
                icon: Icons.widgets,
                iconColor: const Color(0xFFE4DFFF),
                iconBgColor: const Color(0xFFE4DFFF).withValues(alpha: 0.1),
                backgroundIcon: Icons.view_module,
                content: _blockLabels.isEmpty
                    ? const Text('No blocks yet.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFACABAA)))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _blockLabels.map((b) => _buildChip(b)).toList(),
                      ),
              ),
              _buildCard(
                title: 'Overview',
                subtitle: 'Workspace summary at a glance.',
                icon: Icons.analytics,
                iconColor: const Color(0xFF8FA0AA),
                iconBgColor: const Color(0xFF2E3E45),
                backgroundIcon: Icons.insights,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetric('Total Files', '$_totalFiles'),
                    const SizedBox(height: 8),
                    _buildMetric('Blocks', '${_blockLabels.length}'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  IconData _iconForFile(ExplorerItem item) {
    if (item.isFolder) return Icons.folder;
    final ext = item.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'svg':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildMetric(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFFACABAA))),
        Text(value, style: const TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required IconData backgroundIcon,
    required Widget content,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -24,
            child: Icon(
              backgroundIcon,
              size: 160,
              color: Colors.white.withValues(alpha: 0.02),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFFACABAA),
                ),
              ),
              const SizedBox(height: 24),
              content,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(IconData icon, String label, Color iconColor, bool isPrimary) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isPrimary ? Colors.white : const Color(0xFFACABAA),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}
