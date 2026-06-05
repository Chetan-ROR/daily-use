import 'package:flutter/material.dart';

class ReportsSummaryCard extends StatelessWidget {
  const ReportsSummaryCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
