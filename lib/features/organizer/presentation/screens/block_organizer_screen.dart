import 'package:flutter/material.dart';
import '../widgets/organizer_live_section.dart';
import '../widgets/project_blocks_grid.dart';
import '../widgets/timeline_view_header.dart';

class BlockOrganizerScreen extends StatelessWidget {
  const BlockOrganizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
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
                OrganizerLiveSection(),
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
