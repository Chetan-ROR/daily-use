import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/isar_service.dart';
import '../models/life_record.dart';
import '../repositories/life_repository.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final isarProvider = FutureProvider((ref) => IsarService.open());

final lifeRepositoryProvider = FutureProvider<LifeRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final repository = IsarLifeRepository(isar);
  await repository.seedMasterData();
  return repository;
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = await ref.watch(lifeRepositoryProvider.future);
  return repository.getProfile();
});

final allRecordsProvider = FutureProvider<List<LifeRecord>>((ref) async {
  final repository = await ref.watch(lifeRepositoryProvider.future);
  return repository.list();
});

final recordsByModuleProvider = FutureProvider.family<List<LifeRecord>, String>(
  (ref, module) async {
    final repository = await ref.watch(lifeRepositoryProvider.future);
    return repository.list(module: module);
  },
);

final searchProvider = FutureProvider.family<List<LifeRecord>, String>((
  ref,
  query,
) async {
  final repository = await ref.watch(lifeRepositoryProvider.future);
  return repository.search(query);
});

final masterDataProvider = FutureProvider.family<List<MasterDataItem>, String>((
  ref,
  type,
) async {
  final repository = await ref.watch(lifeRepositoryProvider.future);
  return repository.masterData(type);
});

final activityProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final repository = await ref.watch(lifeRepositoryProvider.future);
  return repository.activity();
});
