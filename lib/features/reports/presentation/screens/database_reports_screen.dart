import 'package:flutter/material.dart';


import '../widgets/reports_header_widget.dart';
import '../widgets/storage_metrics_cards.dart';
import '../widgets/schema_distribution_list.dart';

class DatabaseReportsScreen extends StatelessWidget {
  const DatabaseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E), // background
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
    );
  }
}
