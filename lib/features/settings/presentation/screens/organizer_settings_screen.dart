import 'package:flutter/material.dart';

import '../widgets/extension_protocols_card.dart';
import '../widgets/temporal_logic_picker.dart';
import '../widgets/conflict_resolution_settings.dart';

import 'package:go_router/go_router.dart';

class OrganizerSettingsScreen extends StatelessWidget {
  const OrganizerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.grid_view, color: Color(0xFFAEC6FF)),
          onPressed: () => context.go('/'),
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
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2E3E45), // secondary-container
              radius: 16,
              child: const Icon(Icons.person, color: Color(0xFFB1C2CB), size: 16),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl roughly
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Organizer',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.0,
                    color: Colors.white, // on-surface
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define the logic for your automated digital vault.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    color: Color(0xFFACABAA), // on-surface-variant
                  ),
                ),
                const SizedBox(height: 48),
                
                // Content Blocks
                const ExtensionProtocolsCard(),
                const SizedBox(height: 32),
                const TemporalLogicPicker(),
                const SizedBox(height: 32),
                const ConflictResolutionSettings(),
                
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFACABAA), // on-surface-variant
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Discard changes'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAEC6FF), // primary
                        foregroundColor: const Color(0xFF003D8A), // on-primary
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        elevation: 4,
                        shadowColor: const Color(0xFFAEC6FF).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Apply Protocols', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFAEC6FF), // primary
        foregroundColor: const Color(0xFF003D8A), // on-primary
        elevation: 12,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
