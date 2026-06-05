import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/premium_card.dart';
import '../../../core/constants/app_modules.dart';
import '../../../core/models/life_record.dart';
import '../../../core/providers/app_providers.dart';
import '../services/walking_tracker_service.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walkingTrackerProvider);
    final tracker = ref.read(walkingTrackerProvider.notifier);
    final records = ref.watch(recordsByModuleProvider('health'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Walking Tracker'),
        actions: [
          IconButton(
            tooltip: 'Walking settings',
            onPressed: () => _openSettings(context, tracker, state),
            icon: const Icon(Icons.tune_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await tracker.initialize();
          ref.invalidate(recordsByModuleProvider('health'));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _WalkingHero(state: state),
            const SizedBox(height: 16),
            _MetricGrid(state: state),
            const SizedBox(height: 16),
            _ActionPanel(
              tracker: tracker,
              state: state,
              onSave: () => _saveToday(context, ref, state),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(state.errorMessage!),
                ),
              ),
            ],
            const SizedBox(height: 16),
            records.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Text('Health logs load nahi huye: $error'),
              data: (records) => _HealthHistory(records: records),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToday(
    BuildContext context,
    WidgetRef ref,
    WalkingTrackerState state,
  ) async {
    final repository = await ref.read(lifeRepositoryProvider.future);
    final today = DateTime.now();
    final record = LifeRecord(module: 'health')
      ..title = 'Walking - ${DateFormat.yMMMd().format(today)}'
      ..description =
          'Aaj ${state.todaySteps} steps chale. Distance ${state.distanceKm.toStringAsFixed(2)} km, calories ${state.calories.toStringAsFixed(0)} kcal.'
      ..category = 'Steps'
      ..status = state.todaySteps >= state.goalSteps
          ? 'Completed'
          : 'In Progress'
      ..priority = 'Medium'
      ..date = DateUtils.dateOnly(today)
      ..dueDate = DateUtils.dateOnly(today)
      ..amount = state.todaySteps.toDouble()
      ..targetValue = state.goalSteps.toDouble()
      ..progressValue = state.todaySteps.toDouble()
      ..metadataJson = jsonEncode({
        'distanceKm': state.distanceKm,
        'calories': state.calories,
        'activeMinutes': state.activeMinutes,
        'strideLengthMeters': state.strideLengthMeters,
        'weightKg': state.weightKg,
        'source': 'pedometer',
      });
    await repository.saveRecord(record);
    ref.invalidate(recordsByModuleProvider('health'));
    ref.invalidate(allRecordsProvider);
    ref.invalidate(activityProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aaj ka walking log save ho gaya.')),
      );
    }
  }

  Future<void> _openSettings(
    BuildContext context,
    WalkingTrackerController tracker,
    WalkingTrackerState state,
  ) async {
    final goal = TextEditingController(text: state.goalSteps.toString());
    final strideCm = TextEditingController(
      text: (state.strideLengthMeters * 100).toStringAsFixed(0),
    );
    final weight = TextEditingController(
      text: state.weightKg.toStringAsFixed(0),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Walking settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goal,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Daily step goal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: strideCm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stride length in cm',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight in kg for calorie estimate',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await tracker.updateSettings(
                    goalSteps: int.tryParse(goal.text.trim()) ?? 10000,
                    strideLengthMeters:
                        ((double.tryParse(strideCm.text.trim()) ?? 76.2) / 100)
                            .clamp(0.3, 1.5),
                    weightKg: (double.tryParse(weight.text.trim()) ?? 70).clamp(
                      20,
                      250,
                    ),
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkingHero extends StatelessWidget {
  const _WalkingHero({required this.state});

  final WalkingTrackerState state;

  @override
  Widget build(BuildContext context) {
    final color = AppModules.health.accent;
    return PremiumCard(
      gradient: LinearGradient(
        colors: [color, const Color(0xff0ea5e9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_walk, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aaj ke steps',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                    Text(
                      NumberFormat.decimalPattern().format(state.todaySteps),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                avatar: Icon(
                  state.isTracking ? Icons.sensors : Icons.sensors_off,
                  size: 18,
                ),
                label: Text(state.isTracking ? 'Live' : 'Stopped'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 10,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          Text(
            '${(state.progress * 100).toStringAsFixed(0)}% of ${NumberFormat.decimalPattern().format(state.goalSteps)} steps goal',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.state});

  final WalkingTrackerState state;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
      childAspectRatio: 1.35,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricCard(
          icon: Icons.route_outlined,
          title: 'Distance',
          value: '${state.distanceKm.toStringAsFixed(2)} km',
        ),
        _MetricCard(
          icon: Icons.local_fire_department_outlined,
          title: 'Calories',
          value: '${state.calories.toStringAsFixed(0)} kcal',
        ),
        _MetricCard(
          icon: Icons.timer_outlined,
          title: 'Active time',
          value: '${state.activeMinutes} min',
        ),
        _MetricCard(
          icon: Icons.trending_up_outlined,
          title: 'Session',
          value: '${state.sessionSteps} steps',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.tracker,
    required this.state,
    required this.onSave,
  });

  final WalkingTrackerController tracker;
  final WalkingTrackerState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walking tracker controls',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${state.status}. App open rahega to live steps update hote rahenge.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: state.isTracking ? tracker.stop : tracker.start,
                icon: Icon(state.isTracking ? Icons.pause : Icons.play_arrow),
                label: Text(
                  state.isTracking ? 'Stop tracking' : 'Start tracking',
                ),
              ),
              OutlinedButton.icon(
                onPressed: tracker.resetToday,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset today'),
              ),
              OutlinedButton.icon(
                onPressed: state.todaySteps == 0 ? null : onSave,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save today log'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthHistory extends StatelessWidget {
  const _HealthHistory({required this.records});

  final List<LifeRecord> records;

  @override
  Widget build(BuildContext context) {
    final walkingLogs =
        records.where((record) => record.category == 'Steps').toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walking history',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (walkingLogs.isEmpty)
            const EmptyState(
              title: 'No walking logs yet',
              message:
                  'Start tracker, walk, then save today log to build your daily history.',
            )
          else ...[
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barGroups: [
                    for (var i = 0; i < walkingLogs.take(7).length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (walkingLogs[i].amount / 1000).clamp(0.5, 20),
                            color: AppModules.health.accent,
                            width: 18,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final record in walkingLogs.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_walk),
                title: Text('${record.amount.toStringAsFixed(0)} steps'),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(record.date)} • ${record.description}',
                ),
                trailing: Text(
                  '${(record.completionPercent * 100).toStringAsFixed(0)}%',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
