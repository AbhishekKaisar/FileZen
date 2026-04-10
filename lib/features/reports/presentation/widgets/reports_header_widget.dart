import 'package:flutter/material.dart';

class ReportsHeaderWidget extends StatelessWidget {
  const ReportsHeaderWidget({
    super.key,
    required this.onGenerate,
    required this.generating,
    this.lastGeneratedAt,
  });

  final VoidCallback onGenerate;
  final bool generating;
  final DateTime? lastGeneratedAt;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    onPressed: generating ? null : onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (generating) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Color(0xFF003D8A),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else ...[
                          const Icon(Icons.auto_awesome, color: Color(0xFF003D8A), size: 24),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          generating ? 'Generating...' : 'Generate Report',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                    if (lastGeneratedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last run: ${lastGeneratedAt!.toLocal()}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFACABAA)),
                      ),
                    ],
                  ],
                )
              ],
            );
          },
        ),
      ],
    );
  }
}
