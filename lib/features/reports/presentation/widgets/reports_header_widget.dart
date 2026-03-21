import 'package:flutter/material.dart';

class ReportsHeaderWidget extends StatelessWidget {
  const ReportsHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SYSTEM INSIGHTS',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Color(0xFFACABAA), // on-surface-variant
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.0,
                      color: Colors.white, // on-surface
                    ),
                    children: [
                      TextSpan(text: 'Reports & '),
                      TextSpan(
                        text: 'Archives',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFAEC6FF), // primary
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isWide) const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAEC6FF), Color(0xFF0C4492)], // primary to primary-container
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAEC6FF).withValues(alpha: 0.2), // primary/20
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF003D8A), size: 24), // on-primary
                        SizedBox(width: 12),
                        Text(
                          'Generate Report',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D8A), // on-primary
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ],
    );
  }
}
