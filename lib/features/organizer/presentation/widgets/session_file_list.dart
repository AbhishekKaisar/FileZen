import 'package:flutter/material.dart';

import '../../../explorer/domain/models/explorer_item.dart';
import '../screens/metadata_visualizer_bottom_sheet.dart';

/// Files for the selected organizer block + day (backed by Explorer / Supabase).
class SessionFileList extends StatelessWidget {
  const SessionFileList({
    super.key,
    required this.items,
    this.isLoading = false,
    this.blockLabel,
    this.dayLabel,
  });

  final List<ExplorerItem> items;
  final bool isLoading;
  final String? blockLabel;
  final String? dayLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
        ),
      );
    }

    if (items.isEmpty) {
      final dayPart =
          (dayLabel != null && dayLabel!.isNotEmpty) ? 'Day: $dayLabel' : 'All days';
      final scope = [
        if (blockLabel != null && blockLabel!.isNotEmpty) 'Block: $blockLabel',
        dayPart,
      ].join(' · ');
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
          ),
          child: Text(
            'No files for this view.\n$scope\nUpload files from Explorer or change block/day.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.5,
              color: Color(0xFFACABAA),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionHeader('Files in this view'),
        const SizedBox(height: 8),
        ...items.map((item) => _buildFileItem(context: context, item: item)),
      ],
    );
  }

  Widget _buildSessionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: Color(0xFFE4DFFF),
        ),
      ),
    );
  }

  Widget _buildFileItem({
    required BuildContext context,
    required ExplorerItem item,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => MetadataVisualizerBottomSheet(item: item),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF191A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.isFolder ? Icons.folder : Icons.insert_drive_file,
                  color: item.isFolder ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.updatedLabel} · ${item.sizeLabel}\n${item.dayOfWeek} · ${item.blockName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        height: 1.35,
                        color: Color(0xFFACABAA),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3E45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.dayOfWeek,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB1C2CB),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
