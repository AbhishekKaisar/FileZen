import 'package:flutter/material.dart';

class DayTabsSelector extends StatelessWidget {
  const DayTabsSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDayTab('Friday', true),
          _buildDayTab('Thursday', false),
          _buildDayTab('Wednesday', false),
          _buildDayTab('Tuesday', false),
          _buildDayTab('Monday', false),
        ],
      ),
    );
  }

  Widget _buildDayTab(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }
}
