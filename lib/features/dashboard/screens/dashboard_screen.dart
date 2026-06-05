import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/premium_card.dart';
import '../../../core/constants/app_modules.dart';
import '../../../core/models/life_record.dart';
import '../../../core/providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(allRecordsProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final activity = ref.watch(activityProvider).asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Manager Pro'),
        actions: [
          IconButton(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Dashboard failed: $error')),
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              title: 'Start managing your life offline',
              message:
                  'Add notes, tasks, expenses, health logs, documents, wedding plans and goals from one premium dashboard.',
              action: FilledButton.icon(
                onPressed: () => context.go('/feature/tasks'),
                icon: const Icon(Icons.add),
                label: const Text('Add first task'),
              ),
            );
          }
          final today = DateUtils.dateOnly(DateTime.now());
          final todayRecords = records
              .where(
                (record) =>
                    DateUtils.isSameDay(record.date, today) ||
                    DateUtils.isSameDay(record.dueDate, today),
              )
              .toList();
          final pendingTasks = records
              .where(
                (record) => record.module == 'tasks' && !record.isCompleted,
              )
              .length;
          final upcoming = records
              .where(
                (record) =>
                    record.reminderAt != null &&
                    record.reminderAt!.isAfter(DateTime.now()),
              )
              .take(5)
              .toList();
          final expenses = records
              .where((record) => record.module == 'expenses')
              .fold<double>(0, (sum, record) => sum + record.amount);
          final income = records
              .where(
                (record) =>
                    record.module == 'expenses' &&
                    record.category.toLowerCase() == 'income',
              )
              .fold<double>(0, (sum, record) => sum + record.amount);
          final health = records
              .where((record) => record.module == 'health')
              .toList();
          final goals = records
              .where((record) => record.module == 'goals')
              .toList();
          final habits = records
              .where((record) => record.module == 'habits')
              .toList();
          final weddingDate = _weddingDate(records);
          final daysLeft = weddingDate?.difference(DateTime.now()).inDays;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allRecordsProvider);
              ref.invalidate(activityProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                PremiumCard(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      const Color(0xff8b5cf6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${profile?.name.isNotEmpty == true ? ', ${profile!.name}' : ''}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your offline-first command center for productivity, finance, wedding, health and documents.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _HeroPill(
                            label: '${todayRecords.length}',
                            title: 'Today',
                          ),
                          _HeroPill(
                            label: '$pendingTasks',
                            title: 'Pending tasks',
                          ),
                          _HeroPill(
                            label: '${upcoming.length}',
                            title: 'Upcoming',
                          ),
                          if (daysLeft != null)
                            _HeroPill(
                              label: '$daysLeft',
                              title: 'Wedding days',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ResponsiveGrid(
                  children: [
                    _MetricCard(
                      title: 'Monthly Expense',
                      value: NumberFormat.simpleCurrency(
                        name: 'INR',
                      ).format(expenses),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppModules.expenses.accent,
                      route: '/feature/expenses',
                    ),
                    _MetricCard(
                      title: 'Savings',
                      value: NumberFormat.simpleCurrency(
                        name: 'INR',
                      ).format(income - expenses),
                      icon: Icons.savings_outlined,
                      color: const Color(0xff14b8a6),
                      route: '/feature/expenses',
                    ),
                    _MetricCard(
                      title: 'Health Logs',
                      value: '${health.length}',
                      icon: Icons.health_and_safety_outlined,
                      color: AppModules.health.accent,
                      route: '/feature/health',
                    ),
                    _MetricCard(
                      title: 'Goal Progress',
                      value: '${_averageProgress(goals)}%',
                      icon: Icons.flag_outlined,
                      color: AppModules.goals.accent,
                      route: '/feature/goals',
                    ),
                    _MetricCard(
                      title: 'Habit Success',
                      value: '${_averageProgress(habits)}%',
                      icon: Icons.repeat_on_outlined,
                      color: AppModules.habits.accent,
                      route: '/feature/habits',
                    ),
                    _MetricCard(
                      title: 'Documents',
                      value:
                          '${records.where((r) => r.module == 'documents').length}',
                      icon: Icons.folder_copy_outlined,
                      color: AppModules.documents.accent,
                      route: '/feature/documents',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Life Analytics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(_pieData(context, records)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: BarChart(_barData(records))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Upcoming Reminders',
                  records: upcoming,
                  empty: 'No upcoming reminders',
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Timeline',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (activity.isEmpty)
                        const Text('No activity yet')
                      else
                        for (final item in activity.take(8))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.bolt_outlined),
                            title: Text('${item.action} - ${item.title}'),
                            subtitle: Text(
                              '${item.module} • ${DateFormat.yMMMd().add_jm().format(item.createdAt)}',
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime? _weddingDate(List<LifeRecord> records) {
    final dates = records
        .where(
          (record) =>
              record.module == 'wedding' &&
              record.category.toLowerCase().contains('countdown'),
        )
        .toList();
    if (dates.isEmpty) return null;
    dates.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return dates.first.dueDate;
  }

  int _averageProgress(List<LifeRecord> records) {
    if (records.isEmpty) return 0;
    final value =
        records
            .map((record) => record.completionPercent)
            .fold<double>(0, (sum, value) => sum + value) /
        records.length;
    return (value * 100).round();
  }

  PieChartData _pieData(BuildContext context, List<LifeRecord> records) {
    final modules = AppModules.modules
        .where(
          (module) => ![
            'profile',
            'reports',
            'settings',
            'history',
            'notifications',
          ].contains(module.id),
        )
        .take(8)
        .toList();
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 34,
      sections: [
        for (final module in modules)
          PieChartSectionData(
            color: module.accent,
            value: records
                .where((record) => record.module == module.id)
                .length
                .toDouble()
                .clamp(1, 999),
            title: records
                .where((record) => record.module == module.id)
                .length
                .toString(),
            radius: 48,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  BarChartData _barData(List<LifeRecord> records) {
    final modules = [
      AppModules.tasks,
      AppModules.expenses,
      AppModules.wedding,
      AppModules.health,
      AppModules.goals,
    ];
    return BarChartData(
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      barGroups: [
        for (var i = 0; i < modules.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: records
                    .where((record) => record.module == modules[i].id)
                    .length
                    .toDouble()
                    .clamp(1, 20),
                color: modules[i].accent,
                width: 18,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.title});
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: Colors.white.withValues(alpha: 0.18),
      label: Text('$label $title', style: const TextStyle(color: Colors.white)),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1000
            ? 3
            : width > 620
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 1 ? 2.8 : 2.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => context.go(route),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.records,
    required this.empty,
  });
  final String title;
  final List<LifeRecord> records;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(empty)
          else
            for (final record in records)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  AppModules.byId(record.module).icon,
                  color: AppModules.byId(record.module).accent,
                ),
                title: Text(record.title),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(record.reminderAt!),
                ),
              ),
        ],
      ),
    );
  }
}
