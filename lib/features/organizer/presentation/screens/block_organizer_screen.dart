import 'package:flutter/material.dart';
import '../widgets/organizer_app_bar.dart';
import '../widgets/project_blocks_grid.dart';
import '../widgets/timeline_view_header.dart';
import '../widgets/day_tabs_selector.dart';
import '../widgets/session_file_list.dart';

class BlockOrganizerScreen extends StatelessWidget {
  const BlockOrganizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: const OrganizerAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProjectBlocksGrid(),
                SizedBox(height: 64),
                TimelineViewHeader(),
                SizedBox(height: 32),
                DayTabsSelector(),
                SizedBox(height: 24),
                SessionFileList(),
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
