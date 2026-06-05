import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_modules.dart';
import '../../core/models/life_record.dart';
import '../../core/providers/app_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(allRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (records) {
          final dayRecords = records
              .where(
                (record) =>
                    DateUtils.isSameDay(record.date, _selected) ||
                    DateUtils.isSameDay(record.dueDate, _selected) ||
                    (record.reminderAt != null &&
                        DateUtils.isSameDay(record.reminderAt!, _selected)),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              PremiumCard(
                child: CalendarDatePicker(
                  initialDate: _selected,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                  onDateChanged: (date) => setState(() => _selected = date),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Events on ${DateFormat.yMMMMd().format(_selected)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (dayRecords.isEmpty)
                const EmptyState(
                  title: 'No calendar items',
                  message:
                      'Tasks, notes, reminders, birthdays, anniversaries and wedding events appear here by date.',
                )
              else
                for (final record in dayRecords) _CalendarItem(record: record),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarItem extends StatelessWidget {
  const _CalendarItem({required this.record});
  final LifeRecord record;

  @override
  Widget build(BuildContext context) {
    final module = AppModules.byId(record.module);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(module.icon, color: module.accent),
          title: Text(record.title),
          subtitle: Text(
            '${module.title} • ${record.status} • ${DateFormat.yMMMd().format(record.dueDate)}',
          ),
        ),
      ),
    );
  }
}
