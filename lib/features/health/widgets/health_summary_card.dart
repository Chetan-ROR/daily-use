import 'package:flutter/material.dart';

class HealthSummaryCard extends StatelessWidget {
  const HealthSummaryCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
