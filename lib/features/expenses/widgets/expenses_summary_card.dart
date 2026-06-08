import 'package:flutter/material.dart';

class ExpensesSummaryCard extends StatelessWidget {
  const ExpensesSummaryCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
