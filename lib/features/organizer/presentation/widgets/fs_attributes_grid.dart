import 'package:flutter/material.dart';

class FsAttributesGrid extends StatelessWidget {
  final bool isImmutable;
  final bool isSigned;
  final bool isHidden;
  final bool isJournaled;
  final bool isCriticalPath;
  final int inodeNumber;
  final int hardLinks;

  const FsAttributesGrid({
    super.key,
    required this.isImmutable,
    required this.isSigned,
    required this.isHidden,
    required this.isJournaled,
    required this.isCriticalPath,
    required this.inodeNumber,
    required this.hardLinks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // surface-container-low
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FS ATTRIBUTES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: Color(0xFFACABAA),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBadge(Icons.lock, 'Immutable', isImmutable, const Color(0xFFE4DFFF)),
              _buildBadge(Icons.verified_user, 'Signed', isSigned, const Color(0xFFAEC6FF)),
              _buildBadge(Icons.visibility_off, 'Hidden', isHidden, Colors.white, opacity: 0.5),
              _buildBadge(Icons.archive, 'Journaled', isJournaled, const Color(0xFF2C59A8)), // on-primary-fixed-variant
              _buildBadge(Icons.warning, 'Critical Path', isCriticalPath, const Color(0xFFEE7D77)), // error
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inode Number',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFACABAA),
                ),
              ),
              Text(
                inodeNumber.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hard Links',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFACABAA),
                ),
              ),
              Text(
                hardLinks.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, bool isActive, Color activeColor, {double opacity = 1.0}) {
    if (!isActive) return const SizedBox.shrink();
    
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF252626), // surface-container-highest
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: activeColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
