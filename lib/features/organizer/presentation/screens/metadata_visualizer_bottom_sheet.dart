import 'package:flutter/material.dart';

class MetadataVisualizerBottomSheet extends StatelessWidget {
  const MetadataVisualizerBottomSheet({super.key});

  // Helper method to easily show the bottom sheet from anywhere
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const MetadataVisualizerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Metadata Visualizer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('File metadata placeholder...'),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
