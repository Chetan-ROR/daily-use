import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_modules.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create from anywhere',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final module in AppModules.quickActions)
                  ActionChip(
                    avatar: Icon(module.icon, color: module.accent),
                    label: Text(module.title),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/feature/${module.id}');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
