import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/onboarding_screen.dart';
import 'app_shell.dart';

class AppBootstrapScreen extends ConsumerWidget {
  const AppBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not open local database: $error'),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null || profile.name.trim().isEmpty) {
          return const OnboardingScreen();
        }
        return const AppShell(child: DashboardScreen());
      },
    );
  }
}
