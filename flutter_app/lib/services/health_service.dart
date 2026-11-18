import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models.dart';

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class HealthSnapshot {
  final bool connected;
  final String? error;
  final DateTime? syncedAt;
  final int? steps;
  final double? heartRate;
  final double? sleepMinutes;
  final double? weightKg;
  final double? bodyFat;
  final double? activeKcal;
  final String? source;
  final List<BodyPoint> bodyHistory;
  final List<HealthDay> week;
  final List<HealthWorkout> workouts;

  const HealthSnapshot({
    this.connected = false,
    this.error,
    this.syncedAt,
    this.steps,
    this.heartRate,
    this.sleepMinutes,
    this.weightKg,
    this.bodyFat,
    this.activeKcal,
    this.source,
    this.bodyHistory = const [],
    this.week = const [],
    this.workouts = const [],
  });

  HealthSnapshot copyWith({
    bool? connected,
    String? error,
    DateTime? syncedAt,
    int? steps,
    double? heartRate,
    double? sleepMinutes,
    double? weightKg,
    double? bodyFat,
    double? activeKcal,
    String? source,
    List<BodyPoint>? bodyHistory,
    List<HealthDay>? week,
    List<HealthWorkout>? workouts,
  }) => HealthSnapshot(
    connected: connected ?? this.connected,
    error: error ?? this.error,
    syncedAt: syncedAt ?? this.syncedAt,
    steps: steps ?? this.steps,
    heartRate: heartRate ?? this.heartRate,
    sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    weightKg: weightKg ?? this.weightKg,
    bodyFat: bodyFat ?? this.bodyFat,
    activeKcal: activeKcal ?? this.activeKcal,
    source: source ?? this.source,
    bodyHistory: bodyHistory ?? this.bodyHistory,
    week: week ?? this.week,
    workouts: workouts ?? this.workouts,
  );

  /// 0 步 / 0 千卡不算「有数据」，避免用空值算出假评分。
  bool get hasAnyData =>
      (steps ?? 0) > 0 ||
      heartRate != null ||
      (sleepMinutes ?? 0) > 0 ||
      weightKg != null ||
      bodyFat != null ||
      (activeKcal ?? 0) > 0 ||
      workouts.isNotEmpty;
}

class HealthWorkout {
  final String id;
  final String kind;
  final int minutes;
  final int kcal;
  final DateTime start;
  const HealthWorkout({
    required this.id,
    required this.kind,
    required this.minutes,
    required this.kcal,
    required this.start,
  });
}

class HealthDay {
  final DateTime date;
  final int steps;
  final double activeKcal;
  final double sleepMinutes;
  final double? heartRate;
  const HealthDay({
    required this.date,
    required this.steps,
    required this.activeKcal,
    required this.sleepMinutes,
    this.heartRate,
  });
}

class HealthService {
  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
  ];

  final Health _health = Health();
  bool _configured = false;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  Future<HealthSnapshot> connectAndRead() async {
    if (!supported) {
      return const HealthSnapshot(error: '当前平台不支持 Health Connect / HealthKit');
    }
    try {
      await _ensureConfigured();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.activityRecognition.request();
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          await _health.installHealthConnect();
          return const HealthSnapshot(error: '请先安装并打开 Health Connect');
        }
      }
      final granted = await _health.requestAuthorization(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      );
      if (!granted) {
        return const HealthSnapshot(error: '未获得健康数据读取权限');
      }
      return await read();
    } catch (error) {
      return HealthSnapshot(error: _friendly(error));
    }
  }

  Future<HealthSnapshot?> refreshIfAuthorized() async {
    if (!supported) return null;
    try {
      await _ensureConfigured();
      final granted = await _health.hasPermissions(
        _types,
        permissions: List.filled(_types.length, HealthDataAccess.READ),
      );
      if (granted != true) return null;
      return await read();
    } catch (_) {
      return null;
    }
  }

  /// 只读今天步数，供 2 秒轮询使用，避免每 2 秒拉 30 天全量数据。
  Future<int?> readTodaySteps() async {
    if (!supported) return null;
    try {
      await _ensureConfigured();
      final granted = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      if (granted != true) return null;
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final total = await _health.getTotalStepsInInterval(midnight, now);
      if (total != null && total > 0) return total;
      // 某些系统上聚合接口返回 0，但原始 StepsRecord 还在，直接求和兜底。
      final points = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );
      final sum = points.fold<double>(
        0,
        (value, point) => value + _number(point),
      );
      return sum > 0 ? sum.round() : total;
    } catch (_) {
      return null;
    }
  }

  Future<HealthSnapshot> read() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    try {
      final stepsTotal = await _health.getTotalStepsInInterval(midnight, now);
      final points = await _health.getHealthDataFromTypes(
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
        types: _types,
      );

      final activeKcal = points
          .where(
            (point) =>
                point.type == HealthDataType.ACTIVE_ENERGY_BURNED &&
                point.dateFrom.isAfter(midnight),
          )
          .fold<double>(0, (sum, point) => sum + _number(point));

      final heartPoints =
          points
              .where(
                (point) =>
                    point.type == HealthDataType.HEART_RATE ||
                    point.type == HealthDataType.RESTING_HEART_RATE,
              )
              .toList()
            ..sort((a, b) => a.dateTo.compareTo(b.dateTo));

      final sleepStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(hours: 8));
      final sleepPoints = points
          .where(
            (point) =>
                point.type == HealthDataType.SLEEP_SESSION &&
                point.dateTo.isAfter(sleepStart) &&
                point.dateFrom.isBefore(now),
          )
          .toList();
      final sleepMinutes = sleepPoints.fold<double>(
        0,
        (sum, point) => sum + _number(point),
      );

      final weightPoints =
          points.where((point) => point.type == HealthDataType.WEIGHT).toList()
            ..sort((a, b) => a.dateTo.compareTo(b.dateTo));
      final fatPoints =
          points
              .where(
                (point) => point.type == HealthDataType.BODY_FAT_PERCENTAGE,
              )
              .toList()
            ..sort((a, b) => a.dateTo.compareTo(b.dateTo));

      // 按天合并体重与体脂，供「体重 / 体脂率」双曲线使用。
      final bodyMap = <String, ({double? kg, double? fat})>{};
      for (final point in [...weightPoints, ...fatPoints]) {
        final key = _dayKey(point.dateTo.toLocal());
        final previous = bodyMap[key] ?? (kg: null, fat: null);
        bodyMap[key] = (
          kg: point.type == HealthDataType.WEIGHT
              ? _number(point)
              : previous.kg,
          fat: point.type == HealthDataType.BODY_FAT_PERCENTAGE
              ? _number(point)
              : previous.fat,
        );
      }
      final bodyHistory =
          bodyMap.entries
              .map(
                (entry) => BodyPoint(
                  entry.key,
                  weightKg: entry.value.kg,
                  bodyFat: entry.value.fat,
                ),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      final source = points.isNotEmpty ? points.last.sourceName : null;
      final week = List<HealthDay>.generate(7, (index) {
        final day = midnight.subtract(Duration(days: 6 - index));
        final next = day.add(const Duration(days: 1));
        final dayPoints = points.where(
          (point) =>
              !point.dateFrom.isBefore(day) && point.dateFrom.isBefore(next),
        );
        final daySteps = dayPoints
            .where((point) => point.type == HealthDataType.STEPS)
            .fold<double>(0, (sum, point) => sum + _number(point));
        final dayActive = dayPoints
            .where((point) => point.type == HealthDataType.ACTIVE_ENERGY_BURNED)
            .fold<double>(0, (sum, point) => sum + _number(point));
        final daySleep = dayPoints
            .where((point) => point.type == HealthDataType.SLEEP_SESSION)
            .fold<double>(0, (sum, point) => sum + _number(point));
        final dayHeart = dayPoints
            .where(
              (point) =>
                  point.type == HealthDataType.HEART_RATE ||
                  point.type == HealthDataType.RESTING_HEART_RATE,
            )
            .map(_number)
            .where((value) => value > 0)
            .toList();
        return HealthDay(
          date: day,
          steps: daySteps.round(),
          activeKcal: dayActive,
          sleepMinutes: daySleep,
          heartRate: dayHeart.isEmpty
              ? null
              : dayHeart.reduce((a, b) => a + b) / dayHeart.length,
        );
      });
      final workoutPoints =
          points.where((point) => point.type == HealthDataType.WORKOUT).toList()
            ..sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final workouts = workoutPoints.map((point) {
        final value = point.value;
        final type = value is WorkoutHealthValue
            ? value.workoutActivityType
            : null;
        final kcal = value is WorkoutHealthValue
            ? (value.totalEnergyBurned ?? 0)
            : 0;
        final minutes = point.dateTo.difference(point.dateFrom).inMinutes;
        return HealthWorkout(
          id: 'hc-${point.dateFrom.microsecondsSinceEpoch}',
          kind: _workoutName(type),
          minutes: minutes <= 0 ? 0 : minutes,
          kcal: kcal,
          start: point.dateFrom,
        );
      }).toList();

      return HealthSnapshot(
        connected: true,
        syncedAt: now,
        // 没有任何数据点时的 0 步没有意义，按「未同步」处理。
        steps: (stepsTotal == null || (stepsTotal == 0 && points.isEmpty))
            ? null
            : stepsTotal,
        heartRate: heartPoints.isEmpty ? null : _number(heartPoints.last),
        sleepMinutes: sleepPoints.isEmpty ? null : sleepMinutes,
        weightKg: weightPoints.isEmpty ? null : _number(weightPoints.last),
        bodyFat: fatPoints.isEmpty ? null : _number(fatPoints.last),
        activeKcal: activeKcal == 0 ? null : activeKcal,
        source: source,
        bodyHistory: bodyHistory,
        week: week,
        workouts: workouts,
      );
    } catch (error) {
      return HealthSnapshot(connected: true, error: _friendly(error));
    }
  }

  String _workoutName(HealthWorkoutActivityType? type) {
    final name = type?.name.toLowerCase() ?? '';
    if (name.contains('run')) return '跑步';
    if (name.contains('walk')) return '快走';
    if (name.contains('bik') || name.contains('cycl')) return '骑行';
    if (name.contains('swim')) return '游泳';
    if (name.contains('hik')) return '徒步';
    if (name.contains('yoga')) return '瑜伽';
    if (name.contains('strength') || name.contains('weight')) return '力量训练';
    if (name.contains('badminton')) return '羽毛球';
    if (name.contains('basketball')) return '篮球';
    if (name.contains('football') || name.contains('soccer')) return '足球';
    if (name.contains('tennis')) return '网球';
    if (name.isEmpty) return '运动';
    return type!.name;
  }

  double _number(HealthDataPoint point) {
    final value = point.value;
    return value is NumericHealthValue ? value.numericValue.toDouble() : 0;
  }

  String _friendly(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('permission')) return '健康权限未授权：$text';
    if (text.contains('Health Connect')) return 'Health Connect 不可用：$text';
    return text.isEmpty ? '健康数据读取失败' : text;
  }
}
