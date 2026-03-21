import 'package:flutter/material.dart';
import 'dart:math';

class StorageOverviewWidget extends StatelessWidget {
  const StorageOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 40.0,
      runSpacing: 40.0,
      children: [
        // Ring Chart Visualization
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(200, 200),
                painter: _RingChartPainter(
                  percentage: 72,
                  backgroundColor: const Color(0xFF2E3E45), // secondary-container equivalent
                  gradientColors: const [Color(0xFFAEC6FF), Color(0xFF0C4492)], // primary to primary-container
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '72%',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 64,
                      fontWeight: FontWeight.w200,
                      color: Color(0xFFAEC6FF),
                    ),
                  ),
                  Text(
                    'CAPACITY USED',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Color(0xFFACABAA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Storage Details
        Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vault Storage',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your digital assets are securely indexed. Currently managing 1.4 TB of 2.0 TB total capacity.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFFACABAA),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatCard('USED SPACE', '1,432 GB', Colors.white),
                  const SizedBox(width: 16),
                  _buildStatCard('FREE SPACE', '568 GB', const Color(0xFFAEC6FF)),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131313), // surface-container-low
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFACABAA),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingChartPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final List<Color> gradientColors;

  _RingChartPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * pi * (percentage / 100);
    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
