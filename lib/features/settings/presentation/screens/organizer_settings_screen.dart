import 'package:flutter/material.dart';

class OrganizerSettingsScreen extends StatelessWidget {
  const OrganizerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Settings'),
      ),
      body: const Center(
        child: Text('Organizer Settings Screen'),
      ),
    );
  }
}
