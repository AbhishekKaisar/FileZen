import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/env.dart';
import '../../../explorer/domain/models/explorer_item.dart';
import '../widgets/security_context_card.dart';
import '../widgets/unix_permissions_widget.dart';
import '../widgets/storage_geometry_card.dart';
import '../widgets/fs_attributes_grid.dart';

/// Displays real file metadata. Fetches from Supabase `file_metadata` table when
/// available, otherwise derives what it can from the [ExplorerItem].
class MetadataVisualizerBottomSheet extends StatefulWidget {
  const MetadataVisualizerBottomSheet({super.key, required this.item});

  final ExplorerItem item;

  @override
  State<MetadataVisualizerBottomSheet> createState() => _MetadataVisualizerBottomSheetState();
}

class _MetadataVisualizerBottomSheetState extends State<MetadataVisualizerBottomSheet> {
  Map<String, dynamic>? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final useSupabase = Env.useSupabase;
    final dbSchema = Env.dbSchema;

    if (!useSupabase || widget.item.id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .schema(dbSchema)
          .from('file_metadata')
          .select()
          .eq('file_id', widget.item.id!)
          .limit(1);

      if (!mounted) return;
      setState(() {
        _metadata = rows.isNotEmpty ? rows.first : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Derive file category from name extension
  String _fileCategory() {
    final ext = widget.item.name.split('.').last.toLowerCase();
    const mediaExts = {'png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'bmp'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv'};
    const docExts = {'pdf', 'doc', 'docx', 'txt', 'md', 'rtf'};
    const codeExts = {'dart', 'js', 'py', 'java', 'html', 'css', 'ts', 'go', 'rs'};
    const archiveExts = {'zip', 'rar', '7z', 'tar', 'gz'};

    if (mediaExts.contains(ext)) return 'IMAGE';
    if (videoExts.contains(ext)) return 'VIDEO';
    if (docExts.contains(ext)) return 'DOCUMENT';
    if (codeExts.contains(ext)) return 'SOURCE_CODE';
    if (archiveExts.contains(ext)) return 'ARCHIVE';
    return 'GENERAL';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final meta = _metadata;
    final category = meta?['media_category']?.toString().toUpperCase() ?? _fileCategory();

    // Extract metadata or use defaults
    final numericPerms = meta?['unix_permissions']?.toString() ?? '0644';
    final rwxString = _numericToRwx(numericPerms);
    final ownerId = (meta?['owner_uid'] as num?)?.toInt() ?? 1000;
    final ownerName = meta?['owner_name']?.toString() ?? 'user';
    final groupId = (meta?['group_gid'] as num?)?.toInt() ?? 1000;
    final groupName = meta?['group_name']?.toString() ?? 'staff';
    final seLinuxLabel = meta?['selinux_label']?.toString() ?? 'unconfined_u:object_r:user_home_t:s0';
    final blockSize = (meta?['block_size'] as num?)?.toInt() ?? 4096;
    final sizeBytes = (meta?['size_bytes'] as num?)?.toInt() ?? 0;
    final totalBlocks = blockSize > 0 && sizeBytes > 0 ? (sizeBytes / blockSize).ceil() : 1;
    final inodeNumber = (meta?['inode_number'] as num?)?.toInt() ?? 0;
    final hardLinks = (meta?['hard_links'] as num?)?.toInt() ?? 1;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF484848),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(color: Color(0xFFAEC6FF)),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb & Title
                    Row(
                      children: [
                        const Text('Explorer', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
                        const Icon(Icons.chevron_right, size: 16, color: Color(0xFFACABAA)),
                        Text(item.blockName, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
                        const Icon(Icons.chevron_right, size: 16, color: Color(0xFFACABAA)),
                        const Text('Metadata', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$category • ${item.sizeLabel} • ${item.dayOfWeek}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Color(0xFFACABAA),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Metadata Grid Layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final permWidget = UnixPermissionsWidget(
                          numericPerms: numericPerms,
                          rwxString: rwxString,
                          uR: rwxString.length > 1 && rwxString[1] == 'r',
                          uW: rwxString.length > 2 && rwxString[2] == 'w',
                          uX: rwxString.length > 3 && rwxString[3] == 'x',
                          gR: rwxString.length > 4 && rwxString[4] == 'r',
                          gW: rwxString.length > 5 && rwxString[5] == 'w',
                          gX: rwxString.length > 6 && rwxString[6] == 'x',
                          oR: rwxString.length > 7 && rwxString[7] == 'r',
                          oW: rwxString.length > 8 && rwxString[8] == 'w',
                          oX: rwxString.length > 9 && rwxString[9] == 'x',
                        );

                        final securityCard = SecurityContextCard(
                          ownerId: ownerId,
                          ownerName: ownerName,
                          groupId: groupId,
                          groupName: groupName,
                          seLinuxLabel: seLinuxLabel,
                        );

                        final storageCard = StorageGeometryCard(
                          blockSize: blockSize,
                          totalBlocks: totalBlocks,
                        );

                        final fsAttrs = FsAttributesGrid(
                          isImmutable: meta?['is_immutable'] == true,
                          isSigned: meta?['is_signed'] == true,
                          isHidden: item.name.startsWith('.'),
                          isJournaled: meta?['is_journaled'] == true,
                          isCriticalPath: meta?['is_critical_path'] == true,
                          inodeNumber: inodeNumber,
                          hardLinks: hardLinks,
                        );

                        if (constraints.maxWidth > 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildPrimaryStorageCard(item, category),
                                    const SizedBox(height: 24),
                                    permWidget,
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    securityCard,
                                    const SizedBox(height: 24),
                                    storageCard,
                                    const SizedBox(height: 24),
                                    fsAttrs,
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildPrimaryStorageCard(item, category),
                              const SizedBox(height: 24),
                              securityCard,
                              const SizedBox(height: 24),
                              permWidget,
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: storageCard),
                                  const SizedBox(width: 24),
                                  Expanded(child: fsAttrs),
                                ],
                              )
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrimaryStorageCard(ExplorerItem item, String category) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storage, color: Color(0xFFAEC6FF), size: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('FORMAT', style: TextStyle(fontFamily: 'Inter', fontSize: 12, letterSpacing: 2.0, color: Color(0xFFACABAA))),
                  const SizedBox(height: 4),
                  Text(category, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFAEC6FF))),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  item.sizeLabel.replaceAll(RegExp(r'[A-Za-z ]+$'), ''),
                  style: const TextStyle(fontFamily: 'Manrope', fontSize: 72, fontWeight: FontWeight.w200, color: Colors.white, height: 1.0),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.sizeLabel.replaceAll(RegExp(r'^[0-9.,]+\s*'), ''),
                style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, color: Color(0xFFACABAA)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Block: ${item.blockName} • Day: ${item.dayOfWeek}',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Updated', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              Text(item.updatedLabel, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA))),
            ],
          ),
        ],
      ),
    );
  }

  /// Convert numeric permission string like '0644' to rwx string like '-rw-r--r--'.
  static String _numericToRwx(String numeric) {
    final cleaned = numeric.replaceAll(RegExp(r'[^0-7]'), '');
    if (cleaned.length < 3) return '-rw-r--r--';

    final digits = cleaned.length >= 4
        ? cleaned.substring(cleaned.length - 3)
        : cleaned;

    String digitToRwx(String d) {
      final n = int.tryParse(d) ?? 0;
      return '${n & 4 != 0 ? 'r' : '-'}${n & 2 != 0 ? 'w' : '-'}${n & 1 != 0 ? 'x' : '-'}';
    }

    return '-${digitToRwx(digits[0])}${digitToRwx(digits[1])}${digitToRwx(digits[2])}';
  }
}
