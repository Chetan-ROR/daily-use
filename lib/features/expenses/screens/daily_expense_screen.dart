import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/premium_card.dart';
import '../../../core/constants/app_modules.dart';
import '../../../core/models/life_record.dart';
import '../../../core/providers/app_providers.dart';

enum _ExpenseChartRange { daily, weekly, monthly }

class DailyExpenseScreen extends ConsumerStatefulWidget {
  const DailyExpenseScreen({super.key});

  @override
  ConsumerState<DailyExpenseScreen> createState() => _DailyExpenseScreenState();
}

class _DailyExpenseScreenState extends ConsumerState<DailyExpenseScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  _ExpenseChartRange _chartRange = _ExpenseChartRange.daily;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      recordsByModuleProvider(AppModules.expenses.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Expenses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load expenses: $error')),
        data: (records) {
          final expenses =
              records.where((record) => !record.isArchived).toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          final totals = _ExpenseTotals.from(expenses);

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _ExpenseHero(total: totals.month),
                const SizedBox(height: 16),
                _buildEntryForm(context),
                const SizedBox(height: 16),
                _TotalsSection(totals: totals),
                const SizedBox(height: 16),
                _ExpenseChart(
                  records: expenses,
                  range: _chartRange,
                  onRangeChanged: (range) =>
                      setState(() => _chartRange = range),
                ),
                const SizedBox(height: 16),
                _ExpenseList(records: expenses, onDelete: _deleteExpense),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryForm(BuildContext context) {
    final now = DateTime.now();
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppModules.expenses.accent.withValues(
                  alpha: 0.16,
                ),
                child: Icon(
                  AppModules.expenses.icon,
                  color: AppModules.expenses.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add daily expense',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Date & time auto selected: ${DateFormat.yMMMd().add_jm().format(now)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Expense name',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            onSubmitted: (_) => _saveExpense(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _saveExpense,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Submit Expense'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveExpense() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (name.isEmpty) {
      _showMessage('Expense name required');
      return;
    }
    if (amount <= 0) {
      _showMessage('Valid amount required');
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = await ref.read(lifeRepositoryProvider.future);
      final now = DateTime.now();
      final record = LifeRecord(module: AppModules.expenses.id)
        ..title = name
        ..description = ''
        ..category = 'Daily Expense'
        ..status = 'Recorded'
        ..priority = 'Medium'
        ..date = now
        ..dueDate = now
        ..amount = amount
        ..isCompleted = true;
      await repository.saveRecord(record);
      _nameController.clear();
      _amountController.clear();
      _refresh();
      _showMessage('Expense saved');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteExpense(LifeRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          '${record.title} - ${_formatCurrency(record.amount)} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.softDelete(record);
    _refresh();
    _showMessage('Expense deleted');
  }

  void _refresh() {
    ref.invalidate(recordsByModuleProvider(AppModules.expenses.id));
    ref.invalidate(allRecordsProvider);
    ref.invalidate(activityProvider);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExpenseHero extends StatelessWidget {
  const _ExpenseHero({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      gradient: LinearGradient(
        colors: [
          AppModules.expenses.accent,
          Theme.of(context).colorScheme.primary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Expense Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add expenses quickly and review daily, weekly and monthly spend.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Chip(label: Text(_formatCurrency(total))),
        ],
      ),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({required this.totals});

  final _ExpenseTotals totals;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 4 ? 1.5 : 1.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _TotalCard(
              title: 'Today',
              amount: totals.today,
              icon: Icons.today_outlined,
            ),
            _TotalCard(
              title: 'This Week',
              amount: totals.week,
              icon: Icons.view_week_outlined,
            ),
            _TotalCard(
              title: 'This Month',
              amount: totals.month,
              icon: Icons.calendar_month_outlined,
            ),
            _TotalCard(
              title: 'All Time',
              amount: totals.all,
              icon: Icons.summarize_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  final String title;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppModules.expenses.accent),
          const SizedBox(height: 10),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  const _ExpenseChart({
    required this.records,
    required this.range,
    required this.onRangeChanged,
  });

  final List<LifeRecord> records;
  final _ExpenseChartRange range;
  final ValueChanged<_ExpenseChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final points = _chartPoints(records, range);
    final maxY = points
        .map((point) => point.amount)
        .fold<double>(0, (max, value) => value > max ? value : max);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final selector = _RangeSelector(
                range: range,
                onRangeChanged: onRangeChanged,
              );
              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Graph',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    selector,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Expense Graph',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  selector,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Text('Add expenses to see graph.')
          else
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY <= 0 ? 1 : maxY * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            NumberFormat.compactCurrency(
                              symbol: '₹',
                              decimalDigits: 0,
                            ).format(value),
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[index].label,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].amount,
                            color: AppModules.expenses.accent,
                            width: 18,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.range, required this.onRangeChanged});

  final _ExpenseChartRange range;
  final ValueChanged<_ExpenseChartRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_ExpenseChartRange>(
        segments: const [
          ButtonSegment(value: _ExpenseChartRange.daily, label: Text('Daily')),
          ButtonSegment(
            value: _ExpenseChartRange.weekly,
            label: Text('Weekly'),
          ),
          ButtonSegment(
            value: _ExpenseChartRange.monthly,
            label: Text('Monthly'),
          ),
        ],
        selected: {range},
        onSelectionChanged: (selection) => onRangeChanged(selection.first),
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.records, required this.onDelete});

  final List<LifeRecord> records;
  final ValueChanged<LifeRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyState(
        title: 'No daily expenses yet',
        message: 'Submit your first expense to see the full list here.',
      );
    }

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Expense List',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final record in records)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppModules.expenses.accent.withValues(
                  alpha: 0.14,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppModules.expenses.accent,
                ),
              ),
              title: Text(record.title.isEmpty ? 'Expense' : record.title),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(record.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrency(record.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete expense',
                    onPressed: () => onDelete(record),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseTotals {
  const _ExpenseTotals({
    required this.today,
    required this.week,
    required this.month,
    required this.all,
  });

  final double today;
  final double week;
  final double month;
  final double all;

  factory _ExpenseTotals.from(List<LifeRecord> records) {
    final now = DateTime.now();
    final todayStart = DateUtils.dateOnly(now);
    final weekStart = _startOfWeek(now);
    final monthStart = DateTime(now.year, now.month);

    double sumWhere(bool Function(LifeRecord record) test) => records
        .where(test)
        .fold<double>(0, (sum, record) => sum + record.amount);

    return _ExpenseTotals(
      today: sumWhere(
        (record) => _isWithin(
          record.date,
          todayStart,
          todayStart.add(const Duration(days: 1)),
        ),
      ),
      week: sumWhere(
        (record) => _isWithin(
          record.date,
          weekStart,
          weekStart.add(const Duration(days: 7)),
        ),
      ),
      month: sumWhere(
        (record) => _isWithin(
          record.date,
          monthStart,
          DateTime(now.year, now.month + 1),
        ),
      ),
      all: records.fold<double>(0, (sum, record) => sum + record.amount),
    );
  }
}

class _ChartPoint {
  const _ChartPoint(this.label, this.amount);

  final String label;
  final double amount;
}

List<_ChartPoint> _chartPoints(
  List<LifeRecord> records,
  _ExpenseChartRange range,
) {
  final now = DateTime.now();
  switch (range) {
    case _ExpenseChartRange.daily:
      return [
        for (var offset = 6; offset >= 0; offset--)
          _pointForRange(
            records,
            DateUtils.dateOnly(now.subtract(Duration(days: offset))),
            DateUtils.dateOnly(now.subtract(Duration(days: offset - 1))),
            DateFormat.E().format(now.subtract(Duration(days: offset))),
          ),
      ];
    case _ExpenseChartRange.weekly:
      return [
        for (var offset = 5; offset >= 0; offset--)
          _pointForRange(
            records,
            _startOfWeek(now).subtract(Duration(days: offset * 7)),
            _startOfWeek(now).subtract(Duration(days: (offset - 1) * 7)),
            'W${6 - offset}',
          ),
      ];
    case _ExpenseChartRange.monthly:
      return [
        for (var offset = 5; offset >= 0; offset--)
          _pointForRange(
            records,
            DateTime(now.year, now.month - offset),
            DateTime(now.year, now.month - offset + 1),
            DateFormat.MMM().format(DateTime(now.year, now.month - offset)),
          ),
      ];
  }
}

_ChartPoint _pointForRange(
  List<LifeRecord> records,
  DateTime start,
  DateTime end,
  String label,
) {
  final total = records
      .where((record) => _isWithin(record.date, start, end))
      .fold<double>(0, (sum, record) => sum + record.amount);
  return _ChartPoint(label, total);
}

DateTime _startOfWeek(DateTime date) {
  final day = DateUtils.dateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

bool _isWithin(DateTime value, DateTime start, DateTime end) =>
    !value.isBefore(start) && value.isBefore(end);

String _formatCurrency(double amount) =>
    NumberFormat.simpleCurrency(name: 'INR').format(amount);
