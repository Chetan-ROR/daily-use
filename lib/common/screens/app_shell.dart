import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_modules.dart';
import 'quick_action_sheet.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final useRail = MediaQuery.sizeOf(context).width >= 840;
    final destinations = [
      _NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined),
      _NavItem('/feature/tasks', 'Tasks', Icons.task_alt_outlined),
      _NavItem('/feature/notes', 'Notes', Icons.sticky_note_2_outlined),
      _NavItem('/calendar', 'Calendar', Icons.calendar_month_outlined),
      _NavItem('/settings', 'Settings', Icons.settings_outlined),
    ];
    final selectedIndex = destinations.indexWhere(
      (item) => path == item.path || path.startsWith('${item.path}/'),
    );

    return Scaffold(
      drawer: useRail ? null : const _AppDrawer(),
      body: Row(
        children: [
          if (useRail)
            NavigationRail(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: IconButton.filledTonal(
                  tooltip: 'Search',
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search),
                ),
              ),
              destinations: [
                for (final item in destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => const QuickActionSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Text(
            'Life Manager Pro',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_outlined),
          title: const Text('Dashboard'),
          onTap: () => context.go('/dashboard'),
        ),
        ListTile(
          leading: const Icon(Icons.search),
          title: const Text('Global Search'),
          onTap: () => context.go('/search'),
        ),
        const Divider(),
        for (final module in AppModules.modules)
          ListTile(
            leading: Icon(module.icon, color: module.accent),
            title: Text(module.title),
            subtitle: Text(
              module.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.of(context).pop();
              switch (module.id) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'calendar':
                  context.go('/calendar');
                  break;
                case 'reports':
                  context.go('/reports');
                  break;
                case 'history':
                  context.go('/history');
                  break;
                case 'settings':
                  context.go('/settings');
                  break;
                case 'notifications':
                  context.go('/notifications');
                  break;
                default:
                  context.go('/feature/${module.id}');
              }
            },
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
