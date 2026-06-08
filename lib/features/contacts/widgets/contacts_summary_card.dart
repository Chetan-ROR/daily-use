import 'package:flutter/material.dart';

class ContactsSummaryCard extends StatelessWidget {
  const ContactsSummaryCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
