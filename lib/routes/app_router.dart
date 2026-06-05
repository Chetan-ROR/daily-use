import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common/screens/app_bootstrap_screen.dart';
import '../common/screens/app_shell.dart';
import '../common/screens/calendar_screen.dart';
import '../common/screens/feature_crud_screen.dart';
import '../common/screens/global_search_screen.dart';
import '../common/screens/history_screen.dart';
import '../common/screens/notification_center_screen.dart';
import '../common/screens/reports_screen.dart';
import '../common/screens/settings_screen.dart';
import '../core/constants/app_modules.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/health/screens/health_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AppBootstrapScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AppShell(child: DashboardScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const AppShell(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const AppShell(child: CalendarScreen()),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const AppShell(child: ReportsScreen()),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const AppShell(child: HistoryScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AppShell(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const AppShell(child: NotificationCenterScreen()),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) =>
            const AppShell(child: GlobalSearchScreen()),
      ),
      GoRoute(
        path: '/feature/:module',
        builder: (context, state) {
          final module = AppModules.byId(
            state.pathParameters['module'] ?? 'notes',
          );
          if (module.id == 'health') {
            return const AppShell(child: HealthScreen());
          }
          return AppShell(child: FeatureCrudScreen(module: module));
        },
      ),
    ],
  );
});
