import 'package:flutter/material.dart';

class DatabaseReportsScreen extends StatelessWidget {
  const DatabaseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Reports'),
      ),
      body: const Center(
        child: Text('Database Reports Screen'),
      ),
    );
  }
}
