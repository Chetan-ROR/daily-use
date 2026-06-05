import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_modules.dart';
import '../../core/providers/app_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Global Search')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText:
                  'Search notes, tasks, expenses, guests, vendors, documents, goals and contacts',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('$error'),
            data: (records) => _query.trim().isEmpty
                ? const EmptyState(
                    title: 'Search everything',
                    message:
                        'Type a word to search across every offline module.',
                  )
                : records.isEmpty
                ? const EmptyState(
                    title: 'No matches',
                    message: 'Try a different keyword or create new records.',
                  )
                : Column(
                    children: [
                      for (final record in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PremiumCard(
                            onTap: () =>
                                context.go('/feature/${record.module}'),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                AppModules.byId(record.module).icon,
                                color: AppModules.byId(record.module).accent,
                              ),
                              title: Text(record.title),
                              subtitle: Text(
                                '${AppModules.byId(record.module).title} • ${record.category} • ${record.status}',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
