import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StorageGeometryCard extends StatelessWidget {
  final int blockSize; // In Bytes
  final int totalBlocks;

  const StorageGeometryCard({
    super.key,
    required this.blockSize,
    required this.totalBlocks,
  });

  @override
  Widget build(BuildContext context) {
    final formatNumber = NumberFormat("#,###", "en_US");

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
            'STORAGE GEOMETRY',
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
            spacing: 32,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatNumber.format(blockSize),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 30,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'B',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFFACABAA),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Block Size',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: const Color(0xFF484848).withValues(alpha: 0.3),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatNumber.format(totalBlocks),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 30,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Total Blocks',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Fragment Visualizer Grid
          Row(
            children: [
              _buildFragment(1.0, true),
              _buildFragment(0.8, true),
              _buildFragment(0.9, true),
              _buildFragment(0.4, true),
              _buildFragment(1.0, true),
              _buildFragment(0.7, true),
              _buildFragment(1.0, false, color: const Color(0xFF0C4492)), // primary-container
              _buildFragment(1.0, false, color: const Color(0xFF252626)), // surface-variant
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFragment(double opacity, bool isPrimary, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 8,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFAEC6FF).withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
