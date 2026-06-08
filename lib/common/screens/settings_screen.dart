import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/export_service.dart';
import '../../core/services/security_service.dart';
import '../widgets/premium_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleLarge),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) => ref
                      .read(themeModeProvider.notifier)
                      .setMode(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security', style: Theme.of(context).textTheme.titleLarge),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Biometric authentication'),
                  subtitle: const Text(
                    'Fingerprint or face unlock where available',
                  ),
                  trailing: FilledButton(
                    onPressed: () => _authenticate(context),
                    child: const Text('Test'),
                  ),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_clock_outlined),
                  title: Text('Auto lock'),
                  subtitle: Text(
                    '1 minute, 5 minutes, 15 minutes ready for policy wiring',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup & Restore',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Create backup file'),
                  subtitle: const Text('Exports offline records as JSON'),
                  onTap: () => _backup(context, ref),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Select restore file'),
                  subtitle: const Text(
                    'Restore pipeline is prepared for validation/import',
                  ),
                  onTap: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (context.mounted && result != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Selected restore file: ${result.files.single.name}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Offline-first sync readiness'),
                SizedBox(height: 8),
                Text(
                  'Every local entity stores id, createdAt, updatedAt, isDeleted and syncStatus so a REST API can be added behind the repository later.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate(BuildContext context) async {
    final ok = await SecurityService.instance.authenticate();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Authentication successful'
                : 'Biometric authentication is not available',
          ),
        ),
      );
    }
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final records = await ref.read(allRecordsProvider.future);
    final profile = await ref.read(profileProvider.future);
    final file = await ExportService.backupJson(records, profile?.toJson());
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup created: ${file.path}')));
    }
  }
}
