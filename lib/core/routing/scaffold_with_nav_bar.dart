import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/file_zen_app_bar.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: const FileZenAppBar(),
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E).withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: const Color(0xFF484848).withValues(alpha: 0.15))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', '/', context),
              _buildNavItem(Icons.folder_open, 'Explorer', '/explorer', context),
              _buildNavItem(Icons.auto_awesome, 'Organizer', '/organizer', context),
              _buildNavItem(Icons.insert_chart, 'Reports', '/reports', context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String route, BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final bool isActive = location == route;

    return Expanded(
      child: InkWell(
        onTap: () => context.go(route),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2E3E45) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isActive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFFAEC6FF) : const Color(0xFFACABAA),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
