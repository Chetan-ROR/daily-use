import 'package:isar_community/isar.dart';

part 'life_record.g.dart';

@collection
class LifeRecord {
  LifeRecord({
    this.module = 'notes',
    this.title = '',
    this.description = '',
    this.category = '',
    this.status = 'Pending',
    this.priority = 'Medium',
    this.reminderAt,
    this.amount = 0,
    this.targetValue = 0,
    this.progressValue = 0,
    this.isDeleted = false,
    this.isArchived = false,
    this.isCompleted = false,
    this.syncStatus = 'local',
    this.repeatRule = 'None',
    this.tags = const [],
    this.attachmentPaths = const [],
    this.metadataJson = '{}',
  }) {
    final now = DateTime.now();
    date = now;
    dueDate = now;
    createdAt = now;
    updatedAt = now;
  }

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String module;

  @Index(type: IndexType.value)
  late String title;

  late String description;
  late String category;
  late String status;
  late String priority;
  late DateTime date;
  late DateTime dueDate;
  DateTime? reminderAt;
  late double amount;
  late double targetValue;
  late double progressValue;
  late bool isDeleted;
  late bool isArchived;
  late bool isCompleted;
  late String syncStatus;
  late String repeatRule;
  late List<String> tags;
  late List<String> attachmentPaths;
  late String metadataJson;
  late DateTime createdAt;
  late DateTime updatedAt;

  @ignore
  double get completionPercent {
    if (targetValue <= 0) return isCompleted ? 1 : 0;
    return (progressValue / targetValue).clamp(0, 1);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'module': module,
    'title': title,
    'description': description,
    'category': category,
    'status': status,
    'priority': priority,
    'date': date.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'amount': amount,
    'targetValue': targetValue,
    'progressValue': progressValue,
    'isDeleted': isDeleted,
    'isArchived': isArchived,
    'isCompleted': isCompleted,
    'syncStatus': syncStatus,
    'repeatRule': repeatRule,
    'tags': tags,
    'attachmentPaths': attachmentPaths,
    'metadataJson': metadataJson,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

@collection
class UserProfile {
  UserProfile({
    this.name = '',
    this.profilePhotoPath,
    this.dateOfBirth,
    this.mobileNumber = '',
    this.email = '',
    this.bloodGroup = '',
    this.emergencyContact = '',
    this.isDeleted = false,
    this.syncStatus = 'local',
  }) {
    final now = DateTime.now();
    createdAt = now;
    updatedAt = now;
  }

  Id id = 1;
  late String name;
  String? profilePhotoPath;
  DateTime? dateOfBirth;
  late String mobileNumber;
  late String email;
  late String bloodGroup;
  late String emergencyContact;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isDeleted;
  late String syncStatus;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'profilePhotoPath': profilePhotoPath,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'mobileNumber': mobileNumber,
    'email': email,
    'bloodGroup': bloodGroup,
    'emergencyContact': emergencyContact,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
    'syncStatus': syncStatus,
  };
}

@collection
class MasterDataItem {
  MasterDataItem({
    required this.type,
    required this.value,
    this.sortOrder = 0,
    this.isDeleted = false,
    this.syncStatus = 'local',
  }) {
    final now = DateTime.now();
    createdAt = now;
    updatedAt = now;
  }

  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('value')])
  late String type;
  late String value;
  late int sortOrder;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isDeleted;
  late String syncStatus;
}

@collection
class ActivityLog {
  ActivityLog({
    required this.module,
    required this.action,
    required this.title,
    this.isDeleted = false,
    this.syncStatus = 'local',
  }) {
    createdAt = DateTime.now();
  }

  Id id = Isar.autoIncrement;
  late String module;
  late String action;
  late String title;
  late DateTime createdAt;
  late bool isDeleted;
  late String syncStatus;
}
