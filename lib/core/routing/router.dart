import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'scaffold_with_nav_bar.dart';

// Imports for placeholder screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/explorer/presentation/screens/advanced_explorer_screen.dart';
import '../../features/organizer/presentation/screens/block_organizer_screen.dart';
import '../../features/reports/presentation/screens/database_reports_screen.dart';
import '../../features/settings/presentation/screens/organizer_settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/explorer',
          pageBuilder: (context, state) => const NoTransitionPage(child: AdvancedExplorerScreen()),
        ),
        GoRoute(
          path: '/organizer',
          pageBuilder: (context, state) => const NoTransitionPage(child: BlockOrganizerScreen()),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) => const NoTransitionPage(child: DatabaseReportsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const OrganizerSettingsScreen(),
    ),
  ],
);
