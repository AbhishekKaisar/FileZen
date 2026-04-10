import 'package:flutter/material.dart';

/// Day filter for the Organizer. `null` means **All days**.
class DayTabsSelector extends StatelessWidget {
  const DayTabsSelector({
    super.key,
    required this.selectedDay,
    required this.onSelectDay,
  });

  static const List<String?> orderedLabels = [
    null,
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final String? selectedDay;
  final ValueChanged<String?> onSelectDay;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final day in orderedLabels)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildDayTab(
                label: day ?? 'All',
                isActive: day == null ? selectedDay == null : selectedDay == day,
                onTap: () => onSelectDay(day),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0C4492) : const Color(0xFF191A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFAEC6FF).withValues(alpha: 0.2)
                  : const Color(0xFF484848).withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFFBDD0FF) : const Color(0xFFACABAA),
            ),
          ),
        ),
      ),
    );
  }
}
