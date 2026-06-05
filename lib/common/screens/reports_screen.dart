import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_modules.dart';
import '../../core/models/life_record.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/export_service.dart';
import '../widgets/premium_card.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(allRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('$error')),
        data: (records) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            for (final module in [
              AppModules.expenses,
              AppModules.tasks,
              AppModules.health,
              AppModules.wedding,
              AppModules.goals,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(module.icon, color: module.accent),
                    title: Text('${module.title} Report'),
                    subtitle: Text(
                      '${records.where((record) => record.module == module.id).length} records available',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'PDF',
                          onPressed: () => _export(
                            context,
                            module.id,
                            records
                                .where((record) => record.module == module.id)
                                .toList(),
                            true,
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                        ),
                        IconButton(
                          tooltip: 'XLSX',
                          onPressed: () => _export(
                            context,
                            module.id,
                            records
                                .where((record) => record.module == module.id)
                                .toList(),
                            false,
                          ),
                          icon: const Icon(Icons.table_chart_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    String name,
    List<LifeRecord> records,
    bool pdf,
  ) async {
    final file = pdf
        ? await ExportService.recordsToPdf(name, records)
        : await ExportService.recordsToXlsx(name, records);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report created: ${file.path}')));
    }
  }
}
