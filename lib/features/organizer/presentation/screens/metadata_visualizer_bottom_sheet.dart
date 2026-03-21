import 'package:flutter/material.dart';

import '../widgets/security_context_card.dart';
import '../widgets/unix_permissions_widget.dart';
import '../widgets/storage_geometry_card.dart';
import '../widgets/fs_attributes_grid.dart';

class MetadataVisualizerBottomSheet extends StatelessWidget {
  const MetadataVisualizerBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E), // surface
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
                color: const Color(0xFF484848), // outline-variant
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Scrollable Content
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
                      const Text('System_Root', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFFACABAA)),
                      const Text('Metadata', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'config_kernel.bin',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deep Binary Resource • Last Accessed 2m ago',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Metadata Grid Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildPrimaryStorageCard(),
                                  const SizedBox(height: 24),
                                  const UnixPermissionsWidget(
                                    numericPerms: '0754',
                                    rwxString: '-rwxr-xr--',
                                    uR: true, uW: true, uX: true,
                                    gR: true, gW: false, gX: true,
                                    oR: true, oW: false, oX: false,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  const SecurityContextCard(
                                    ownerId: 1000,
                                    ownerName: 'admin',
                                    groupId: 1000,
                                    groupName: 'wheel',
                                    seLinuxLabel: 'system_u:object_r:bin_t:s0',
                                  ),
                                  const SizedBox(height: 24),
                                  const StorageGeometryCard(
                                    blockSize: 4096,
                                    totalBlocks: 6054688,
                                  ),
                                  const SizedBox(height: 24),
                                  const FsAttributesGrid(
                                    isImmutable: true,
                                    isSigned: true,
                                    isHidden: true,
                                    isJournaled: true,
                                    isCriticalPath: true,
                                    inodeNumber: 284556122,
                                    hardLinks: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Narrow screen layout
                        return Column(
                          children: [
                            _buildPrimaryStorageCard(),
                            const SizedBox(height: 24),
                            const SecurityContextCard(
                              ownerId: 1000,
                              ownerName: 'admin',
                              groupId: 1000,
                              groupName: 'wheel',
                              seLinuxLabel: 'system_u:object_r:bin_t:s0',
                            ),
                            const SizedBox(height: 24),
                            const UnixPermissionsWidget(
                              numericPerms: '0754',
                              rwxString: '-rwxr-xr--',
                              uR: true, uW: true, uX: true,
                              gR: true, gW: false, gX: true,
                              oR: true, oW: false, oX: false,
                            ),
                            const SizedBox(height: 24),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: StorageGeometryCard(blockSize: 4096, totalBlocks: 6054688)),
                                SizedBox(width: 24),
                                Expanded(
                                  child: FsAttributesGrid(
                                    isImmutable: true,
                                    isSigned: true,
                                    isHidden: true,
                                    isJournaled: true,
                                    isCriticalPath: true,
                                    inodeNumber: 284556122,
                                    hardLinks: 1,
                                  ),
                                ),
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

  Widget _buildPrimaryStorageCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // surface-container-low
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
                  const Text('BINARY_EXECUTABLE', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFAEC6FF))),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('24.8', style: TextStyle(fontFamily: 'Manrope', fontSize: 72, fontWeight: FontWeight.w200, color: Colors.white, height: 1.0)),
              const SizedBox(width: 8),
              const Text('GB', style: TextStyle(fontFamily: 'Manrope', fontSize: 24, color: Color(0xFFACABAA))),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Total Logical Allocation on Volume /dev/nvme0n1p3', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Storage Efficiency', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              Text('98.2% Optimised', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA))),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF2E3E45), // secondary-container
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.982,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAEC6FF), Color(0xFF0C4492)], // primary -> primary-container
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
