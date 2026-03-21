import 'package:flutter/material.dart';

class ProjectBlocksGrid extends StatelessWidget {
  const ProjectBlocksGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const Text(
          'Project Blocks',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 56,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.0,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Systematic categorization of your digital assets. Organized by chronological priority and thematic relevance.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            color: Color(0xFFACABAA),
          ),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            // Active Block
            Container(
              constraints: const BoxConstraints(maxWidth: 800),
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF191A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFAEC6FF).withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PRIMARY ARCHIVE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFAEC6FF),
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Q4 Marketing Campaign',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.auto_awesome, color: Color(0xFFAEC6FF), size: 30),
                          ],
                        ),
                        const Spacer(),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: [
                            _buildDayPreview('MON', '12', false),
                            _buildDayPreview('TUE', '08', false),
                            _buildDayPreview('WED', '24', true),
                            _buildDayPreview('THU', '15', false),
                            _buildDayPreview('FRI', '04', false),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Side Block 1
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131313),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_done, color: Color(0xFFE4DFFF), size: 24),
                  const SizedBox(height: 24),
                  const Text(
                    'Cloud Assets',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'External repositories synchronized for local processing.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFFACABAA),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Storage Capacity', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA))),
                      Text('82% Full', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFFACABAA))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3E45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.82,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFAEC6FF), Color(0xFFE4DFFF)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayPreview(String day, String number, bool isActive) {
    return Container(
      width: 64,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(8),
        border: isActive ? const Border(bottom: BorderSide(color: Color(0xFFAEC6FF), width: 2)) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFFAEC6FF) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
