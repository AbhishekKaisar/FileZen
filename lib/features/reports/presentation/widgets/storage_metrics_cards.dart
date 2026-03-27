import 'package:flutter/material.dart';

class StorageMetricsCards extends StatelessWidget {
  const StorageMetricsCards({
    super.key,
    required this.totalBytes,
    required this.totalFiles,
    required this.integrityScore,
  });

  final int totalBytes;
  final int totalFiles;
  final double integrityScore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildLiveStatusCard(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildInfoCard(
                      Icons.folder_zip,
                      const Color(0xFF8FA0AA),
                      '$totalFiles',
                      'Total Objects Indexed',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      Icons.verified_user,
                      const Color(0xFFE4DFFF),
                      '${integrityScore.toStringAsFixed(1)}%',
                      'Integrity Score',
                    ),
                  ],
                ),
              )
            ],
          );
        } else {
          return Column(
            children: [
              _buildLiveStatusCard(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildInfoCard(
                        Icons.folder_zip,
                        const Color(0xFF8FA0AA),
                        '$totalFiles',
                        'Total Objects Indexed',
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildInfoCard(
                        Icons.verified_user,
                        const Color(0xFFE4DFFF),
                        '${integrityScore.toStringAsFixed(1)}%',
                        'Integrity Score',
                      ),
                    ),
                ],
              )
            ],
          );
        }
      },
    );
  }

  Widget _buildLiveStatusCard() {
    final usedRatio = totalFiles <= 0 ? 0.0 : (integrityScore / 100).clamp(0.05, 1.0);
    final storageLabel = _formatBytes(totalBytes);
    final split = storageLabel.split(' ');
    final amount = split.isEmpty ? '0' : split.first;
    final unit = split.length > 1 ? split.last : 'B';
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF191A1A), // surface-container
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storage, color: Color(0xFFAEC6FF), size: 36),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2020), // surface-container-high
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE STATUS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: Color(0xFFACABAA),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 48),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(amount, style: const TextStyle(fontFamily: 'Manrope', fontSize: 48, fontWeight: FontWeight.w300, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(unit, style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Total Storage Utilized', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFFACABAA))),
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
                  widthFactor: usedRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFAEC6FF), Color(0xFFE4DFFF)], // primary to tertiary
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131313), // surface-container-low
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFFACABAA),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final display = value >= 10 || unitIndex == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return '$display ${units[unitIndex]}';
  }
}
