import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/isar_service.dart';
import '../models/life_record.dart';
import '../../features/health/services/walking_tracker_service.dart';
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

class WalkingTrackerController extends Notifier<WalkingTrackerState> {
  late final WalkingTrackerService _service;

  @override
  WalkingTrackerState build() {
    _service = WalkingTrackerService.instance;
    void syncState() => state = _service.state;
    _service.addListener(syncState);
    _service.initialize().then((_) => state = _service.state);
    ref.onDispose(() {
      _service.removeListener(syncState);
      _service.stop();
    });
    return _service.state;
  }

  Future<void> initialize() => _service.initialize();
  Future<void> start() => _service.start();
  Future<void> stop() => _service.stop();
  Future<void> resetToday() => _service.resetToday();
  Future<void> updateSettings({
    required int goalSteps,
    required double strideLengthMeters,
    required double weightKg,
  }) => _service.updateSettings(
    goalSteps: goalSteps,
    strideLengthMeters: strideLengthMeters,
    weightKg: weightKg,
  );
}

final walkingTrackerProvider =
    NotifierProvider<WalkingTrackerController, WalkingTrackerState>(
      WalkingTrackerController.new,
    );
