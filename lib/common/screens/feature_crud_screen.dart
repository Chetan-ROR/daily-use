import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_modules.dart';
import '../../core/models/life_record.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/export_service.dart';
import '../../core/services/notification_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/premium_card.dart';

class FeatureCrudScreen extends ConsumerStatefulWidget {
  const FeatureCrudScreen({super.key, required this.module});

  final AppModule module;

  @override
  ConsumerState<FeatureCrudScreen> createState() => _FeatureCrudScreenState();
}

class _FeatureCrudScreenState extends ConsumerState<FeatureCrudScreen> {
  String _query = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsByModuleProvider(widget.module.id));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          IconButton(
            tooltip: 'PDF Export',
            onPressed: () => _export(pdf: true),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'XLSX Export',
            onPressed: () => _export(pdf: false),
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(
              _showArchived ? Icons.inventory_2 : Icons.inventory_2_outlined,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(recordsByModuleProvider(widget.module.id)),
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Could not load ${widget.module.title}: $error'),
          ),
          data: (records) {
            final filtered = records.where((record) {
              if (!_showArchived && record.isArchived) return false;
              final haystack = [
                record.title,
                record.description,
                record.category,
                record.status,
                ...record.tags,
              ].join(' ').toLowerCase();
              return haystack.contains(_query.toLowerCase());
            }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _Header(module: widget.module, count: filtered.length),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search ${widget.module.title.toLowerCase()}',
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(() => _query = ''),
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  EmptyState(
                    title: 'No ${widget.module.title.toLowerCase()} yet',
                    message:
                        'Create your first entry with notes, status, priority, reminders and attachments.',
                    action: FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add entry'),
                    ),
                  )
                else
                  ...filtered.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordTile(
                        module: widget.module,
                        record: record,
                        onEdit: () => _openEditor(record),
                        onDelete: () => _delete(record),
                        onArchive: () => _archive(record),
                        onComplete: () => _complete(record),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feature-add-${widget.module.id}',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text('Add ${widget.module.title.split(' ').first}'),
      ),
    );
  }

  Future<void> _export({required bool pdf}) async {
    final records = await ref.read(
      recordsByModuleProvider(widget.module.id).future,
    );
    final file = pdf
        ? await ExportService.recordsToPdf(widget.module.id, records)
        : await ExportService.recordsToXlsx(widget.module.id, records);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Export created: ${file.path}')));
  }

  Future<void> _delete(LifeRecord record) async {
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.softDelete(record);
    _refresh();
  }

  Future<void> _archive(LifeRecord record) async {
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.archive(record, !record.isArchived);
    _refresh();
  }

  Future<void> _complete(LifeRecord record) async {
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.complete(record, !record.isCompleted);
    _refresh();
  }

  void _refresh() {
    ref.invalidate(recordsByModuleProvider(widget.module.id));
    ref.invalidate(allRecordsProvider);
    ref.invalidate(activityProvider);
  }

  Future<void> _openEditor([LifeRecord? source]) async {
    final saved = await showModalBottomSheet<LifeRecord>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _RecordEditor(module: widget.module, source: source),
    );
    if (saved == null) return;
    final repository = await ref.read(lifeRepositoryProvider.future);
    await repository.saveRecord(saved);
    if (saved.reminderAt != null) {
      await NotificationService.instance.showNow(
        title: 'Reminder saved',
        body: saved.title,
      );
    }
    _refresh();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.module, required this.count});

  final AppModule module;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      gradient: LinearGradient(
        colors: [module.accent, scheme.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            child: Icon(module.icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Chip(label: Text('$count')),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.module,
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
    required this.onComplete,
  });

  final AppModule module;
  final LifeRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().format(record.dueDate);
    return PremiumCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: module.accent.withValues(alpha: 0.16),
                child: Icon(module.icon, color: module.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title.isEmpty ? 'Untitled' : record.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.description.isEmpty
                          ? module.subtitle
                          : record.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'complete':
                      onComplete();
                      break;
                    case 'archive':
                      onArchive();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'complete',
                    child: Text(record.isCompleted ? 'Reopen' : 'Complete'),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(record.isArchived ? 'Restore' : 'Archive'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                icon: Icons.category_outlined,
                label: record.category.isEmpty ? 'General' : record.category,
              ),
              _Pill(icon: Icons.pending_actions_outlined, label: record.status),
              _Pill(icon: Icons.priority_high, label: record.priority),
              _Pill(icon: Icons.event_outlined, label: date),
              if (module.supportsAmount)
                _Pill(
                  icon: Icons.currency_rupee,
                  label: record.amount.toStringAsFixed(2),
                ),
              if (record.attachmentPaths.isNotEmpty)
                _Pill(
                  icon: Icons.attach_file,
                  label: '${record.attachmentPaths.length} files',
                ),
            ],
          ),
          if (module.supportsProgress) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: record.completionPercent),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _RecordEditor extends ConsumerStatefulWidget {
  const _RecordEditor({required this.module, this.source});

  final AppModule module;
  final LifeRecord? source;

  @override
  ConsumerState<_RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends ConsumerState<_RecordEditor> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late final TextEditingController _target;
  late final TextEditingController _progress;
  late final TextEditingController _tags;
  late DateTime _date;
  late DateTime _dueDate;
  DateTime? _reminderAt;
  late String _category;
  late String _status;
  late String _priority;
  late String _repeat;
  late List<String> _attachments;

  @override
  void initState() {
    super.initState();
    final record = widget.source;
    _title = TextEditingController(text: record?.title ?? '');
    _description = TextEditingController(text: record?.description ?? '');
    _amount = TextEditingController(
      text: record == null || record.amount == 0
          ? ''
          : record.amount.toString(),
    );
    _target = TextEditingController(
      text: record == null || record.targetValue == 0
          ? ''
          : record.targetValue.toString(),
    );
    _progress = TextEditingController(
      text: record == null || record.progressValue == 0
          ? ''
          : record.progressValue.toString(),
    );
    _tags = TextEditingController(text: record?.tags.join(', ') ?? '');
    _date = record?.date ?? DateTime.now();
    _dueDate = record?.dueDate ?? DateTime.now();
    _reminderAt = record?.reminderAt;
    _category = record?.category ?? '';
    _status = record?.status ?? 'Pending';
    _priority = record?.priority ?? 'Medium';
    _repeat = record?.repeatRule ?? 'None';
    _attachments = [...?record?.attachmentPaths];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final categories = ref.watch(
      masterDataProvider('${widget.module.id}:category'),
    );
    final statuses = ref.watch(masterDataProvider('status'));
    final priorities = ref.watch(masterDataProvider('priority'));
    final repeats = ref.watch(masterDataProvider('repeat'));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.source == null
                    ? 'Add ${widget.module.title}'
                    : 'Edit ${widget.module.title}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title / Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description / Notes',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _AsyncDropdown(
                label: 'Category',
                value: _category,
                fallback: 'General',
                asyncItems: categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AsyncDropdown(
                      label: 'Status',
                      value: _status,
                      fallback: 'Pending',
                      asyncItems: statuses,
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AsyncDropdown(
                      label: 'Priority',
                      value: _priority,
                      fallback: 'Medium',
                      asyncItems: priorities,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                  ),
                ],
              ),
              if (widget.module.supportsAmount) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount / Value',
                  ),
                ),
              ],
              if (widget.module.supportsProgress) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _target,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Target'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _progress,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Progress',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tags comma separated',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.today),
                    label: Text('Date ${DateFormat.MMMd().format(_date)}'),
                  ),
                  if (widget.module.supportsDueDate)
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.event),
                      label: Text('Due ${DateFormat.MMMd().format(_dueDate)}'),
                    ),
                  if (widget.module.supportsReminder)
                    OutlinedButton.icon(
                      onPressed: _pickReminder,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        _reminderAt == null
                            ? 'Reminder'
                            : DateFormat.MMMd().add_jm().format(_reminderAt!),
                      ),
                    ),
                ],
              ),
              if (widget.module.supportsReminder) ...[
                const SizedBox(height: 12),
                _AsyncDropdown(
                  label: 'Repeat',
                  value: _repeat,
                  fallback: 'None',
                  asyncItems: repeats,
                  onChanged: (value) => setState(() => _repeat = value),
                ),
              ],
              if (widget.module.supportsAttachments) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Documents'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Image'),
                    ),
                  ],
                ),
                if (_attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_attachments.length} attachment(s) selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(bool due) async {
    final initial = due ? _dueDate : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (due) {
        _dueDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(
      () => _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() => _attachments.addAll(result.paths.whereType<String>()));
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _attachments.add(image.path));
  }

  void _save() {
    final source = widget.source;
    final record = source ?? LifeRecord(module: widget.module.id);
    record
      ..module = widget.module.id
      ..title = _title.text.trim()
      ..description = _description.text.trim()
      ..category = _category.isEmpty ? 'General' : _category
      ..status = _status
      ..priority = _priority
      ..date = _date
      ..dueDate = _dueDate
      ..reminderAt = _reminderAt
      ..repeatRule = _repeat
      ..amount = double.tryParse(_amount.text.trim()) ?? 0
      ..targetValue = double.tryParse(_target.text.trim()) ?? 0
      ..progressValue = double.tryParse(_progress.text.trim()) ?? 0
      ..isCompleted = _status.toLowerCase() == 'completed'
      ..tags = _tags.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList()
      ..attachmentPaths = _attachments
          .where((path) => File(path).path.isNotEmpty)
          .toList();
    Navigator.of(context).pop(record);
  }
}

class _AsyncDropdown extends StatelessWidget {
  const _AsyncDropdown({
    required this.label,
    required this.value,
    required this.fallback,
    required this.asyncItems,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String fallback;
  final AsyncValue<List<MasterDataItem>> asyncItems;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = asyncItems.maybeWhen(
      data: (items) => items.map((item) => item.value).toList(),
      orElse: () => <String>[],
    );
    final effective = values.isEmpty ? <String>[fallback] : values;
    final selected = effective.contains(value) ? value : effective.first;
    if (value.isEmpty && selected != value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(selected));
    }
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in effective)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (newValue) {
        if (newValue != null) onChanged(newValue);
      },
    );
  }
}
