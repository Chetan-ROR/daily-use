import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_modules.dart';
import '../../core/providers/app_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(allRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Center')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (records) {
          final notifications =
              records.where((record) => record.reminderAt != null).toList()
                ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
          if (notifications.isEmpty) {
            return const EmptyState(
              title: 'No reminders',
              message:
                  'Reminder history, alerts, snooze-ready items and notification actions will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final record = notifications[index];
              final module = AppModules.byId(record.module);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.notifications_active_outlined,
                      color: module.accent,
                    ),
                    title: Text(record.title),
                    subtitle: Text(
                      '${module.title} • ${record.repeatRule} • ${DateFormat.yMMMd().add_jm().format(record.reminderAt!)}',
                    ),
                    trailing: const Icon(Icons.snooze_outlined),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
