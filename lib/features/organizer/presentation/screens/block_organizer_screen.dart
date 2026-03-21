import 'package:flutter/material.dart';

class BlockOrganizerScreen extends StatelessWidget {
  const BlockOrganizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Organizer'),
      ),
      body: const Center(
        child: Text('Block Organizer Screen'),
      ),
    );
  }
}
