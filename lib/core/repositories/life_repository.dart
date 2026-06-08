import 'package:isar_community/isar.dart';

import '../models/life_record.dart';

abstract class LifeRepository {
  Future<List<LifeRecord>> list({String? module, bool includeDeleted = false});
  Future<List<LifeRecord>> search(String query);
  Future<LifeRecord> saveRecord(LifeRecord record);
  Future<void> softDelete(LifeRecord record);
  Future<void> archive(LifeRecord record, bool archived);
  Future<void> complete(LifeRecord record, bool completed);
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<List<MasterDataItem>> masterData(String type);
  Future<MasterDataItem> saveMasterData(MasterDataItem item);
  Future<void> seedMasterData();
  Future<List<ActivityLog>> activity({int limit = 40});
}

class IsarLifeRepository implements LifeRepository {
  IsarLifeRepository(this._isar);

  final Isar _isar;

  @override
  Future<List<LifeRecord>> list({
    String? module,
    bool includeDeleted = false,
  }) async {
    final records = await _isar.lifeRecords.where().findAll();
    return records
        .where((record) => includeDeleted || !record.isDeleted)
        .where((record) => module == null || record.module == module)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<LifeRecord>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return list();
    final records = await list();
    return records.where((record) {
      final haystack = [
        record.module,
        record.title,
        record.description,
        record.category,
        record.status,
        record.priority,
        ...record.tags,
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  @override
  Future<LifeRecord> saveRecord(LifeRecord record) async {
    final isNew = record.id == Isar.autoIncrement;
    record.updatedAt = DateTime.now();
    if (record.status.toLowerCase() == 'completed') {
      record.isCompleted = true;
    }
    await _isar.writeTxn(() async => _isar.lifeRecords.put(record));
    await _log(record.module, isNew ? 'Create' : 'Update', record.title);
    return record;
  }

  @override
  Future<void> softDelete(LifeRecord record) async {
    record
      ..isDeleted = true
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.lifeRecords.put(record));
    await _log(record.module, 'Delete', record.title);
  }

  @override
  Future<void> archive(LifeRecord record, bool archived) async {
    record
      ..isArchived = archived
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.lifeRecords.put(record));
    await _log(record.module, archived ? 'Archive' : 'Restore', record.title);
  }

  @override
  Future<void> complete(LifeRecord record, bool completed) async {
    record
      ..isCompleted = completed
      ..status = completed ? 'Completed' : 'Pending'
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.lifeRecords.put(record));
    await _log(record.module, completed ? 'Complete' : 'Reopen', record.title);
  }

  @override
  Future<UserProfile?> getProfile() async => _isar.userProfiles.get(1);

  @override
  Future<void> saveProfile(UserProfile profile) async {
    profile
      ..id = 1
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.userProfiles.put(profile));
    await _log(
      'profile',
      'Update',
      profile.name.isEmpty ? 'Profile' : profile.name,
    );
  }

  @override
  Future<List<MasterDataItem>> masterData(String type) async {
    final items = await _isar.masterDataItems.where().findAll();
    return items.where((item) => item.type == type && !item.isDeleted).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<MasterDataItem> saveMasterData(MasterDataItem item) async {
    item.updatedAt = DateTime.now();
    await _isar.writeTxn(() async => _isar.masterDataItems.put(item));
    await _log('master_data', 'Update', '${item.type}: ${item.value}');
    return item;
  }

  @override
  Future<void> seedMasterData() async {
    final existing = await _isar.masterDataItems.where().count();
    if (existing > 0) return;

    final seed = <MasterDataItem>[];
    void add(String type, List<String> values) {
      for (var i = 0; i < values.length; i++) {
        seed.add(MasterDataItem(type: type, value: values[i], sortOrder: i));
      }
    }

    add('priority', ['Low', 'Medium', 'High', 'Critical']);
    add('status', ['Pending', 'In Progress', 'Completed', 'Hold', 'Cancelled']);
    add('repeat', ['None', 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom']);
    add('assignee', ['Self', 'Family', 'Partner', 'Vendor']);
    add('notes:category', ['Personal', 'Work', 'Ideas', 'Family', 'Wedding']);
    add('tasks:category', [
      'Personal',
      'Office',
      'Family',
      'Wedding',
      'Finance',
    ]);
    add('reminders:category', [
      'Notes',
      'Tasks',
      'Wedding Events',
      'Expenses',
      'Health',
      'Documents',
    ]);
    add('expenses:category', [
      'Income',
      'Food',
      'Travel',
      'Fuel',
      'Shopping',
      'Bills',
      'Rent',
      'Medical',
      'Entertainment',
      'Education',
      'Wedding',
      'Family',
      'Other',
    ]);
    add('expenses:payment_mode', [
      'Cash',
      'UPI',
      'Credit Card',
      'Debit Card',
      'Bank Transfer',
    ]);
    add('wedding:category', [
      'Guest',
      'Task',
      'Shopping',
      'Vendor',
      'Budget',
      'Invitation',
      'Countdown',
    ]);
    add('wedding:vendor_category', [
      'Venue',
      'Catering',
      'Decoration',
      'Photography',
      'DJ',
      'Makeup Artist',
    ]);
    add('wedding:guest_category', [
      'Bride Family',
      'Groom Family',
      'Friends',
      'Office',
      'VIP',
    ]);
    add('health:category', [
      'Steps',
      'Walking Distance',
      'Calories',
      'Water',
      'Weight',
      'BMI',
    ]);
    add('habits:category', [
      'Exercise',
      'Reading',
      'Meditation',
      'Water Intake',
      'Sleep',
    ]);
    add('goals:category', [
      'Personal',
      'Financial',
      'Fitness',
      'Career',
      'Wedding',
    ]);
    add('contacts:category', [
      'Family',
      'Friends',
      'Office',
      'Vendors',
      'Emergency Contacts',
    ]);
    add('documents:category', [
      'Aadhaar',
      'PAN',
      'Passport',
      'Driving License',
      'Insurance',
      'Wedding Documents',
      'Personal Documents',
    ]);

    await _isar.writeTxn(() async => _isar.masterDataItems.putAll(seed));
  }

  @override
  Future<List<ActivityLog>> activity({int limit = 40}) async {
    final logs = await _isar.activityLogs.where().findAll();
    return (logs..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(limit)
        .toList();
  }

  Future<void> _log(String module, String action, String title) async {
    await _isar.writeTxn(() async {
      await _isar.activityLogs.put(
        ActivityLog(module: module, action: action, title: title),
      );
    });
  }
}
