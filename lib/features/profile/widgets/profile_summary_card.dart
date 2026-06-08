import 'package:flutter/material.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
