import 'package:flutter/material.dart';

class UnixPermissionsWidget extends StatelessWidget {
  final String numericPerms;
  final String rwxString; // e.g., "-rwxr-xr--"
  final bool uR, uW, uX;
  final bool gR, gW, gX;
  final bool oR, oW, oX;

  const UnixPermissionsWidget({
    super.key,
    required this.numericPerms,
    required this.rwxString,
    required this.uR,
    required this.uW,
    required this.uX,
    required this.gR,
    required this.gW,
    required this.gX,
    required this.oR,
    required this.oW,
    required this.oX,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // surface-container-low
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 32,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildNumericInfo(),
          _buildGridDisplay(),
        ],
      ),
    );
  }

  Widget _buildNumericInfo() {
    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNIX RWX PERMISSIONS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
              color: Color(0xFFACABAA),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                rwxString,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 36,
                  letterSpacing: -1.5,
                  color: Color(0xFFAEC6FF), // primary
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3E45), // secondary-container
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  numericPerms,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB1C2CB), // on-secondary-container
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridDisplay() {
    return Wrap(
      spacing: 48,
      runSpacing: 24,
      children: [
        _buildPermissionGroup('USER', uR, uW, uX),
        _buildPermissionGroup('GROUP', gR, gW, gX),
        _buildPermissionGroup('OTHERS', oR, oW, oX),
      ],
    );
  }

  Widget _buildPermissionGroup(String title, bool r, bool w, bool x) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Color(0xFFACABAA),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPermBox('R', r),
            const SizedBox(width: 4),
            _buildPermBox('W', w),
            const SizedBox(width: 4),
            _buildPermBox('X', x),
          ],
        )
      ],
    );
  }

  Widget _buildPermBox(String letter, bool isActive) {
    if (isActive) {
      // Following the Stitch UI loosely where some active states are primary and others are secondary-container
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFAEC6FF), // primary
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003D8A), // on-primary
          ),
        ),
      );
    } else {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF252626), // surface-variant
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: const Text(
          '-',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF484848), // outline-variant
          ),
        ),
      );
    }
  }
}
