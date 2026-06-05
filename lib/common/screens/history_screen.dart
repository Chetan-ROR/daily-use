import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_modules.dart';
import '../../core/providers/app_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(allRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (records) {
          final history = records
              .where(
                (record) =>
                    record.isCompleted ||
                    record.isArchived ||
                    record.status.toLowerCase() == 'completed',
              )
              .toList();
          if (history.isEmpty) {
            return const EmptyState(
              title: 'No history yet',
              message:
                  'Completed tasks, archived notes, habits and goals will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              final module = AppModules.byId(record.module);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(module.icon, color: module.accent),
                    title: Text(record.title),
                    subtitle: Text(
                      '${module.title} • ${record.status} • ${DateFormat.yMMMd().format(record.updatedAt)}',
                    ),
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
