import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class WalkingTrackerState {
  const WalkingTrackerState({
    required this.dateKey,
    this.todaySteps = 0,
    this.sessionSteps = 0,
    this.distanceKm = 0,
    this.calories = 0,
    this.activeMinutes = 0,
    this.goalSteps = 10000,
    this.strideLengthMeters = 0.762,
    this.weightKg = 70,
    this.isTracking = false,
    this.permissionGranted = false,
    this.status = 'stopped',
    this.errorMessage,
    this.lastUpdated,
  });

  final String dateKey;
  final int todaySteps;
  final int sessionSteps;
  final double distanceKm;
  final double calories;
  final int activeMinutes;
  final int goalSteps;
  final double strideLengthMeters;
  final double weightKg;
  final bool isTracking;
  final bool permissionGranted;
  final String status;
  final String? errorMessage;
  final DateTime? lastUpdated;

  double get progress =>
      goalSteps <= 0 ? 0 : (todaySteps / goalSteps).clamp(0, 1);

  WalkingTrackerState copyWith({
    int? todaySteps,
    int? sessionSteps,
    double? distanceKm,
    double? calories,
    int? activeMinutes,
    int? goalSteps,
    double? strideLengthMeters,
    double? weightKg,
    bool? isTracking,
    bool? permissionGranted,
    String? status,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return WalkingTrackerState(
      dateKey: dateKey,
      todaySteps: todaySteps ?? this.todaySteps,
      sessionSteps: sessionSteps ?? this.sessionSteps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      goalSteps: goalSteps ?? this.goalSteps,
      strideLengthMeters: strideLengthMeters ?? this.strideLengthMeters,
      weightKg: weightKg ?? this.weightKg,
      isTracking: isTracking ?? this.isTracking,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class WalkingTrackerService extends ChangeNotifier {
  WalkingTrackerService._();

  static final instance = WalkingTrackerService._();

  SharedPreferences? _preferences;
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;
  int? _baselineSteps;
  int _storedAtSessionStart = 0;
  bool _initialized = false;

  WalkingTrackerState _state = WalkingTrackerState(dateKey: _todayKey());
  WalkingTrackerState get state => _state;

  static String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> initialize() async {
    if (_initialized) return;
    _preferences = await SharedPreferences.getInstance();
    await _loadToday();
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!(Platform.isAndroid || Platform.isIOS)) return false;

    final permission = await Permission.activityRecognition.request();
    final granted = permission.isGranted || permission.isLimited;
    _state = _state.copyWith(
      permissionGranted: granted,
      errorMessage: granted
          ? null
          : 'Activity recognition permission allow karo, tab steps count honge.',
    );
    notifyListeners();
    return granted;
  }

  Future<void> start() async {
    await initialize();
    final granted = await requestPermission();
    if (!granted) return;

    await stop();
    _baselineSteps = null;
    _storedAtSessionStart = _state.todaySteps;
    _state = _state.copyWith(
      isTracking: true,
      status: 'starting',
      errorMessage: null,
    );
    notifyListeners();

    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (Object error) {
        _state = _state.copyWith(
          isTracking: false,
          status: 'sensor_error',
          errorMessage:
              'Step sensor available nahi hai ya permission block hai: $error',
        );
        notifyListeners();
      },
      cancelOnError: false,
    );

    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      (event) {
        _state = _state.copyWith(status: event.status, errorMessage: null);
        notifyListeners();
      },
      onError: (_) {
        _state = _state.copyWith(status: 'unknown');
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    if (_state.isTracking) {
      _state = _state.copyWith(isTracking: false, status: 'stopped');
      notifyListeners();
    }
  }

  Future<void> resetToday() async {
    await initialize();
    final prefs = _preferences!;
    final key = _state.dateKey;
    await prefs.setInt('walking_steps_$key', 0);
    _baselineSteps = null;
    _storedAtSessionStart = 0;
    _state = _calculate(0, sessionSteps: 0).copyWith(
      isTracking: _state.isTracking,
      permissionGranted: _state.permissionGranted,
      status: _state.isTracking ? 'tracking' : 'stopped',
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> updateSettings({
    required int goalSteps,
    required double strideLengthMeters,
    required double weightKg,
  }) async {
    await initialize();
    final prefs = _preferences!;
    await prefs.setInt('walking_goal_steps', goalSteps);
    await prefs.setDouble('walking_stride_meters', strideLengthMeters);
    await prefs.setDouble('walking_weight_kg', weightKg);
    _state = _calculate(_state.todaySteps, sessionSteps: _state.sessionSteps)
        .copyWith(
          goalSteps: goalSteps,
          strideLengthMeters: strideLengthMeters,
          weightKg: weightKg,
        );
    notifyListeners();
  }

  Future<void> _loadToday() async {
    final prefs = _preferences!;
    final key = _todayKey();
    final savedSteps = prefs.getInt('walking_steps_$key') ?? 0;
    final goal = prefs.getInt('walking_goal_steps') ?? 10000;
    final stride = prefs.getDouble('walking_stride_meters') ?? 0.762;
    final weight = prefs.getDouble('walking_weight_kg') ?? 70;
    _state = WalkingTrackerState(
      dateKey: key,
      todaySteps: savedSteps,
      goalSteps: goal,
      strideLengthMeters: stride,
      weightKg: weight,
      permissionGranted:
          (await Permission.activityRecognition.status).isGranted,
    );
    _state = _calculate(
      savedSteps,
      sessionSteps: 0,
    ).copyWith(goalSteps: goal, strideLengthMeters: stride, weightKg: weight);
    notifyListeners();
  }

  Future<void> _onStepCount(StepCount event) async {
    final currentKey = _todayKey();
    if (currentKey != _state.dateKey) {
      await _loadToday();
      _baselineSteps = null;
      _storedAtSessionStart = _state.todaySteps;
    }

    _baselineSteps ??= event.steps;
    final sessionSteps = math.max(0, event.steps - _baselineSteps!);
    final totalSteps = _storedAtSessionStart + sessionSteps;
    await _preferences?.setInt('walking_steps_${_state.dateKey}', totalSteps);
    _state = _calculate(totalSteps, sessionSteps: sessionSteps).copyWith(
      isTracking: true,
      permissionGranted: true,
      status: _state.status == 'starting' ? 'tracking' : _state.status,
      errorMessage: null,
      lastUpdated: event.timeStamp,
    );
    notifyListeners();
  }

  WalkingTrackerState _calculate(int steps, {required int sessionSteps}) {
    final distanceKm = (steps * _state.strideLengthMeters) / 1000;
    final calories = distanceKm * _state.weightKg * 0.57;
    final activeMinutes = (steps / 100).round();
    return _state.copyWith(
      todaySteps: steps,
      sessionSteps: sessionSteps,
      distanceKm: distanceKm,
      calories: calories,
      activeMinutes: activeMinutes,
    );
  }
}
