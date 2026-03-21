import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/reports_header_widget.dart';
import '../widgets/storage_metrics_cards.dart';
import '../widgets/schema_distribution_list.dart';

class DatabaseReportsScreen extends StatelessWidget {
  const DatabaseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.grid_view, color: Color(0xFFAEC6FF)),
          onPressed: () {},
        ),
        title: const Text(
          'FileZen',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFFACABAA)),
              onPressed: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2E3E45), // secondary-container
              radius: 16,
              child: const Icon(Icons.person, color: Color(0xFFB1C2CB), size: 16),
            ),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200), // max-w-7xl
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReportsHeaderWidget(),
                      SizedBox(height: 48),
                      StorageMetricsCards(),
                      SizedBox(height: 48),
                      SchemaDistributionList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E).withValues(alpha: 0.9),
          border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.15))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard, 'Dashboard', false, context),
            _buildNavItem(Icons.folder_open, 'Explorer', false, context),
            _buildNavItem(Icons.auto_awesome, 'Organizer', false, context),
            _buildNavItem(Icons.insert_chart, 'Reports', true, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context) {
    void onTap() {
      if (label == 'Dashboard') context.go('/');
      if (label == 'Explorer') context.go('/explorer');
      if (label == 'Organizer') context.go('/organizer');
      if (label == 'Reports') context.go('/reports');
    }

    if (isActive) {
      return InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3E45), // secondary-container
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFFAEC6FF)),
              Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFAEC6FF))),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFACABAA)),
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFACABAA))),
        ],
      ),
    );
  }
}
