import 'package:flutter/material.dart';

class TimelineViewHeader extends StatelessWidget {
  const TimelineViewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          children: [
            const Text(
              'Timeline View',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF131313),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF484848).withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2C2C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Detailed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: const Text(
                      'Summary',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFFACABAA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Row(
          children: [
            Icon(Icons.filter_list, color: Color(0xFFACABAA)),
            SizedBox(width: 12),
            Icon(Icons.search, color: Color(0xFFACABAA)),
          ],
        )
      ],
    );
  }
}
