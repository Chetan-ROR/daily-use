import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/life_record.dart';

class IsarService {
  IsarService._();

  static Isar? _instance;

  static Future<Isar> open() async {
    final existing = _instance;
    if (existing != null && existing.isOpen) return existing;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        LifeRecordSchema,
        UserProfileSchema,
        MasterDataItemSchema,
        ActivityLogSchema,
      ],
      directory: dir.path,
      name: 'life_manager_pro',
    );
    return _instance!;
  }
}
