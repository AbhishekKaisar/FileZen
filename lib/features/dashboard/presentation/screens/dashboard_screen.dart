import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/storage_overview_widget.dart';
import '../widgets/quick_access_grid.dart';
import '../widgets/auto_sorter_status.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorageOverviewWidget(),
                SizedBox(height: 64),
                QuickAccessGrid(),
                SizedBox(height: 64),
                AutoSorterStatus(),
                SizedBox(height: 128),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFAEC6FF),
        child: const Icon(Icons.add, color: Color(0xFF003D8A), size: 30),
      ),
    );
  }
}
