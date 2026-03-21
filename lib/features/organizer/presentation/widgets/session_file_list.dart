import 'package:flutter/material.dart';

class SessionFileList extends StatelessWidget {
  const SessionFileList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSessionHeader('Morning Session — 09:00'),
        const SizedBox(height: 8),
        _buildFileItem(
          icon: Icons.description,
          iconColor: const Color(0xFFAEC6FF),
          title: 'Campaign_Brief_V2.pdf',
          subtitle: 'Last modified 2h ago • 4.2 MB',
          badgeText: 'Review',
          badgeColor: const Color(0xFF2E3E45),
          badgeTextColor: const Color(0xFFB1C2CB),
          extraInfo: 'Shared with 3 people',
        ),
        const SizedBox(height: 8),
        _buildFileItem(
          icon: Icons.image,
          iconColor: const Color(0xFFE4DFFF),
          title: 'Hero_Visual_Concept.png',
          subtitle: 'Last modified 4h ago • 12.8 MB',
          badgeText: 'Asset',
          badgeColor: const Color(0xFF1F2020),
          badgeTextColor: const Color(0xFFACABAA),
          extraInfo: 'Private',
        ),
        const SizedBox(height: 32),
        _buildSessionHeader('Afternoon Session — 14:30'),
        const SizedBox(height: 8),
        _buildFileItem(
          icon: Icons.table_chart,
          iconColor: const Color(0xFFAEC6FF),
          title: 'Budget_Projections_Final.xlsx',
          subtitle: 'Last modified 15m ago • 1.1 MB',
          badgeText: 'Priority',
          badgeColor: const Color(0xFF7F2927),
          badgeTextColor: const Color(0xFFFF9993),
          extraInfo: 'Auto-sync enabled',
        ),
      ],
    );
  }

  Widget _buildSessionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
          color: Color(0xFFE4DFFF),
        ),
      ),
    );
  }

  Widget _buildFileItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String extraInfo,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF191A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFFACABAA),
                  ),
                ),
              ],
            ),
          ),
          if (extraInfo.isNotEmpty) ...[
            Text(
              extraInfo,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF767575), // outline / 60
              ),
            ),
            const SizedBox(width: 24),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.more_vert, color: Color(0xFFACABAA)),
        ],
      ),
    );
  }
}
