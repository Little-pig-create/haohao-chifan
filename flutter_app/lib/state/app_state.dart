import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_data.dart';
import '../data/exercise_catalog.dart';
import '../models.dart';
import '../services/health_service.dart';
import '../services/llm_service.dart';
import '../services/reminder_service.dart';
import '../services/step_sensor.dart';

class AppState extends ChangeNotifier {
  static const _storageKey = 'haohao.flutter.v3';

  bool guest = false;
  int tab = 0;
  int planTab = 0;
  int insightTab = 0;
  int insightPeriod = 0;
  int meTab = 0;
  int selectedDay = todayIndex;

  String name = '林小满';
  String uid = '';
  String gender = '';
  int age = 0;
  Uint8List? avatarBytes;
  String planName = '轻盈生活计划';
  int calorieGoal = 1850;
  int proteinGoal = 95;
  int waterTargetMl = 2000;
  int cupMl = 250;
  double targetWeight = 55;
  double heightCm = 170;
  int stepGoal = 10000;
  int sleepGoalMinutes = 480;
  int exerciseGoalMinutes = 30;

  bool aiEnabled = true;
  bool remindersEnabled = false;
  int waterReminderMinutes = 120;
  String breakfastTime = '08:00';
  String lunchTime = '12:00';
  String dinnerTime = '18:30';
  String weightTime = '07:30';
  String sleepTime = '21:30';

  /// 新用户是否已经完成「目标 + AI 引擎」设置引导。
  bool onboardingSeen = false;

  /// 用户是否确认过每日目标；默认值不算确认。
  bool goalsConfigured = false;

  /// 首页的配置提醒是否被手动收起。
  bool setupChecklistDismissed = false;

  final Map<int, Set<int>> _completed = {};
  final Map<String, List<AddedMeal>> _addedByDate = {};
  final Map<int, List<Meal>> _customMeals = {};
  final Map<int, int> _water = {};
  final Map<String, int> intakeByDate = {};

  int _planVariation = 0;

  final HealthService _healthService = HealthService();
  final StepSensor _stepSensor = StepSensor();
  HealthSnapshot health = const HealthSnapshot();
  int? sensorSteps;
  bool _sensorDriven = false;
  bool healthBusy = false;
  String? healthError;

  final LlmService _llmService = LlmService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<LlmProvider> llmProviders = [];
  String? activeProviderId;
  String? activeModel;
  bool llmBusy = false;
  String? llmError;

  LlmProvider? get activeProvider {
    for (final provider in llmProviders) {
      if (provider.id == activeProviderId) return provider;
    }
    return null;
  }

  /// 添加提供商并且选中模型后，AI 功能才算真正可用。
  bool get aiConfigured {
    final provider = activeProvider;
    if (provider == null) return false;
    final model = activeModel ?? provider.model;
    return model != null && model.trim().isNotEmpty;
  }

  bool get setupComplete => goalsConfigured && aiConfigured;

  bool get setupChecklistVisible => !setupComplete && !setupChecklistDismissed;

  final Set<int> favorites = {3};
  final List<WeightEntry> weights = [...weightSeed];
  final List<MeasureEntry> measures = [...measureSeed];
  final List<ExerciseEntry> exercises = [...exerciseSeed];
  List<ExerciseType> _builtinExerciseTypes = [...exerciseCatalog];
  final List<ExerciseType> customExercises = [];
  final List<ChatMessage> chatMessages = [
    const ChatMessage(text: defaultChatWelcome, fromAi: true),
  ];
  final Map<String, AiReport> aiReports = {};

  List<ExerciseType> get exerciseTypes => [
    ..._builtinExerciseTypes,
    ...customExercises,
  ];

  ExerciseType? typeFor(String name) {
    for (final type in exerciseTypes) {
      if (type.name == name) return type;
    }
    return null;
  }

  ExerciseType? typeById(String id) {
    for (final type in exerciseTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  Map<String, int> get exerciseUsageCounts {
    final counts = <String, int>{};
    for (final entry in exercises) {
      counts[entry.kind] = (counts[entry.kind] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get exerciseLastUsedOrder {
    final lastUsed = <String, int>{};
    for (var index = 0; index < exercises.length; index++) {
      lastUsed[exercises[index].kind] = index;
    }
    return lastUsed;
  }

  List<ExerciseType> sortedExerciseTypes({bool frequentFirst = true}) {
    final types = exerciseTypes;
    if (!frequentFirst) return types;
    final usage = exerciseUsageCounts;
    final lastUsed = exerciseLastUsedOrder;
    final originalOrder = {
      for (var index = 0; index < types.length; index++) types[index].id: index,
    };
    types.sort((a, b) {
      final byUsage = (usage[b.name] ?? 0).compareTo(usage[a.name] ?? 0);
      if (byUsage != 0) return byUsage;
      final byLastUsed = (lastUsed[b.name] ?? -1).compareTo(
        lastUsed[a.name] ?? -1,
      );
      if (byLastUsed != 0) return byLastUsed;
      return originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
    });
    return types;
  }

  List<ExerciseType> frequentExerciseTypes({int limit = 6}) {
    final sorted = sortedExerciseTypes();
    final usage = exerciseUsageCounts;
    final result = sorted
        .where((type) => (usage[type.name] ?? 0) > 0)
        .take(limit)
        .toList();
    for (final id in const [
      'run',
      'walk',
      'cycle',
      'strength',
      'yoga',
      'jump_rope',
    ]) {
      if (result.length >= limit) break;
      final type = typeById(id);
      if (type != null && !result.any((item) => item.id == type.id)) {
        result.add(type);
      }
    }
    for (final type in sorted) {
      if (result.length >= limit) break;
      if (!result.any((item) => item.id == type.id)) result.add(type);
    }
    return result;
  }

  List<Meal> mealsFor(int day) {
    final custom = _customMeals[day];
    if (custom == null || custom.isEmpty) return const [];
    return custom.map(_withMealTime).toList();
  }

  Meal _withMealTime(Meal meal) => meal.copyWith(time: mealTimeFor(meal.kind));

  Set<int> completedFor(int day) => _completed[day] ?? <int>{};

  List<AddedMeal> addedFor(int day) => addedForDate(dateKeyForDay(day));

  List<AddedMeal> addedForDate(String date) => _addedByDate[date] ?? const [];

  List<AddedMeal> addedForKind(int day, String kind) =>
      addedFor(day).where((meal) => meal.kind == kind).toList();

  /// 菜品库排序依据：用户实际记录过的菜优先，其次是家常菜。
  Map<String, int> get dishUsageCounts {
    final counts = <String, int>{};
    void add(String title) {
      counts[title] = (counts[title] ?? 0) + 1;
    }

    for (final meal in _addedByDate.values.expand((items) => items)) {
      add(meal.title);
    }
    for (var day = 0; day < weekDays.length; day++) {
      final plan = mealsFor(day);
      for (final index in completedFor(day)) {
        if (index >= 0 && index < plan.length) add(plan[index].title);
      }
    }
    return counts;
  }

  /// 与餐次设置联动的记录时间，避免各页面各写一套。
  String mealTimeFor(String kind) => switch (kind) {
    '早餐' => breakfastTime,
    '午餐' => lunchTime,
    '晚餐' => dinnerTime,
    _ => '15:30',
  };

  /// 打开添加入口时默认落到当前时段最可能的一餐。
  String get defaultMealKind {
    final hour = DateTime.now().hour;
    if (hour < 10) return '早餐';
    if (hour < 15) return '午餐';
    if (hour < 21) return '晚餐';
    return '加餐';
  }

  /// 记录时间以实际添加时刻为准，用户可以在记录后继续修改。
  String get currentTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 碳水、脂肪目标由热量目标推导，蛋白质目标允许用户单独设置。
  int get fatGoal => (calorieGoal * .3 / 9).round();
  int get carbGoal => ((calorieGoal - proteinGoal * 4 - fatGoal * 9) / 4)
      .round()
      .clamp(0, 1000)
      .toInt();

  int waterFor(int day) => _water[day] ?? 0;

  /// 截至 [endDay] 的最近 7 天饮水量（毫升），用于首页迷你趋势。
  List<int> waterWeekFor(int endDay) {
    return List<int>.generate(7, (index) {
      final day = endDay - 6 + index;
      if (day < 0 || day >= weekDays.length) return 0;
      return waterFor(day) * cupMl;
    });
  }

  String get todayIso {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 体重 / 体脂率曲线数据：本机记录优先，Health Connect 补齐历史。
  List<BodyPoint> get bodyPoints {
    final byDate = <String, BodyPoint>{};
    for (final point in health.bodyHistory) {
      byDate[point.date] = point;
    }
    for (final entry in weights) {
      final previous = byDate[entry.date];
      byDate[entry.date] = BodyPoint(
        entry.date,
        weightKg: entry.kg,
        bodyFat: entry.bodyFat ?? previous?.bodyFat,
      );
    }
    if (health.weightKg != null || health.bodyFat != null) {
      final previous = byDate[todayIso];
      byDate[todayIso] = BodyPoint(
        todayIso,
        weightKg: health.weightKg ?? previous?.weightKg,
        bodyFat: health.bodyFat ?? previous?.bodyFat,
      );
    }
    return byDate.values
        .where((point) => point.weightKg != null || point.bodyFat != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double get currentWeightKg {
    if (weights.isNotEmpty) return weights.last.kg;
    return health.weightKg ?? 60;
  }

  /// AI 记录运动和计算消耗时使用的简要身体信息。
  String get bodyProfileSummary {
    final height = heightCm > 0 ? heightCm : 170.0;
    return '身高 ${height.toStringAsFixed(0)}cm，体重 ${currentWeightKg.toStringAsFixed(1)}kg';
  }

  /// 根据资料给出一个温和的每日热量建议，供首次设置引导使用。
  int recommendedCalorieGoalFor({double? weightKg, double? targetWeightKg}) {
    final weight = (weightKg ?? currentWeightKg).clamp(30, 200).toDouble();
    final target = (targetWeightKg ?? targetWeight).clamp(30, 200).toDouble();
    final height = heightCm > 0 ? heightCm : 170.0;
    final years = (age > 0 ? age : 28).toDouble();
    final sexOffset = gender == '男'
        ? 5.0
        : gender == '女'
        ? -161.0
        : -78.0;
    final bmr = 10 * weight + 6.25 * height - 5 * years + sexOffset;
    var kcal = bmr * 1.375;
    if (target < weight - 1) kcal -= 300;
    if (target > weight + 1) kcal += 200;
    // 取整到 50，手动加减时数字更整齐。
    return ((kcal / 50).round() * 50).clamp(1200, 3500);
  }

  int get recommendedCalorieGoal => recommendedCalorieGoalFor();

  int recommendedProteinGoalFor({double? weightKg, double? targetWeightKg}) {
    final weight = (weightKg ?? currentWeightKg).clamp(30, 200).toDouble();
    final target = (targetWeightKg ?? targetWeight).clamp(30, 200).toDouble();
    final losing = target < weight - 1;
    return (weight * (losing ? 1.6 : 1.2)).round().clamp(40, 200);
  }

  int get recommendedProteinGoal => recommendedProteinGoalFor();

  int recommendedWaterTargetMlFor({double? weightKg}) {
    final weight = (weightKg ?? currentWeightKg).clamp(30, 200).toDouble();
    return (((weight * 35) / 50).round() * 50).clamp(1500, 3500);
  }

  int get recommendedWaterTargetMl => recommendedWaterTargetMlFor();

  int get recommendedStepGoal => age >= 60 ? 8000 : 10000;

  double? get bmi {
    double? latest;
    for (final point in bodyPoints.reversed) {
      if (point.weightKg != null) {
        latest = point.weightKg;
        break;
      }
    }
    if (latest == null || heightCm <= 0) return null;
    final meters = heightCm / 100;
    return latest / (meters * meters);
  }

  bool get profileComplete =>
      gender.isNotEmpty &&
      age > 0 &&
      heightCm >= 120 &&
      (weights.isNotEmpty || health.weightKg != null);

  String _newUid() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List<String>.generate(
      8,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'HH-$code';
  }

  void completeProfile({
    required String name,
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    Uint8List? avatar,
  }) {
    if (name.trim().isNotEmpty) this.name = name.trim();
    this.gender = gender;
    this.age = age.clamp(10, 100);
    this.heightCm = heightCm.clamp(120, 220).toDouble();
    if (uid.isEmpty) uid = _newUid();
    if (avatar != null) avatarBytes = avatar;
    weights.removeWhere((item) => item.date == todayIso);
    weights.add(WeightEntry(todayIso, weightKg.clamp(30, 200).toDouble()));
    weights.sort((a, b) => a.date.compareTo(b.date));
    guest = true;
    goalsConfigured = false;
    onboardingSeen = false;
    setupChecklistDismissed = false;
    notifyListeners();
    _save();
  }

  void setAvatar(Uint8List? bytes) {
    avatarBytes = bytes;
    notifyListeners();
    _save();
  }

  double? get latestMeasuredBodyFat {
    for (final point in bodyPoints.reversed) {
      if (point.bodyFat != null) return point.bodyFat;
    }
    return null;
  }

  /// Deurenberg 估算：仅在没有实测体脂时使用。
  double? get estimatedBodyFat {
    final bmiValue = bmi;
    if (bmiValue == null || age <= 0 || gender.isEmpty) return null;
    final sex = gender == '男'
        ? 1.0
        : gender == '女'
        ? 0.0
        : 0.5;
    return (1.20 * bmiValue + 0.23 * age - 10.8 * sex - 5.4)
        .clamp(3, 60)
        .toDouble();
  }

  double? get displayBodyFat => latestMeasuredBodyFat ?? estimatedBodyFat;

  bool get bodyFatIsEstimated =>
      latestMeasuredBodyFat == null && estimatedBodyFat != null;

  DateTime dateForDay(int index) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: todayIndex - index));
  }

  String dateKeyForDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String dateKeyForDay(int index) => dateKeyForDate(dateForDay(index));

  int? intakeForDay(int index) => intakeByDate[dateKeyForDay(index)];

  int get glassGoal {
    final byTarget = (waterTargetMl / (cupMl == 0 ? 250 : cupMl)).round();
    return byTarget < 8 ? 8 : byTarget;
  }

  int consumedFor(int day) {
    return addedFor(day).fold<int>(0, (sum, item) => sum + item.kcal);
  }

  int proteinFor(int day) => _macroFor(day, (a) => a.protein);
  int carbsFor(int day) => _macroFor(day, (a) => a.carbs);
  int fatFor(int day) => _macroFor(day, (a) => a.fat);

  int _macroFor(int day, int Function(AddedMeal) fromAdded) {
    return addedFor(day).fold<int>(0, (sum, item) => sum + fromAdded(item));
  }

  int plannedKcalFor(int day) =>
      mealsFor(day).fold<int>(0, (sum, meal) => sum + meal.kcal);

  /// 全应用共用的健康评分口径，页面不要再各自复制一套权重。
  int? healthScoreFor(int day) {
    final hasData =
        health.hasAnyData || consumedFor(day) > 0 || waterFor(day) > 0;
    if (!hasData) return null;
    final protein = (proteinFor(day) / proteinGoal).clamp(0.0, 1.0);
    final water = (waterFor(day) * cupMl / waterTargetMl).clamp(0.0, 1.0);
    final steps = ((health.steps ?? 0) / stepGoal).clamp(0.0, 1.0);
    final sleep = ((health.sleepMinutes ?? 0) / sleepGoalMinutes).clamp(
      0.0,
      1.0,
    );
    return (45 + protein * 22 + water * 13 + steps * 12 + sleep * 8)
        .round()
        .clamp(0, 100);
  }

  /// 从菜池生成整周三餐，优先贴近热量目标并减少同菜重复。
  void generateWeekPlan() {
    _planVariation++;
    final plan = _buildWeekPlan(variation: _planVariation);
    for (var day = 0; day < weekDays.length; day++) {
      _customMeals[day] = plan[day];
    }
    notifyListeners();
    _save();
  }

  List<List<Meal>> _buildWeekPlan({required int variation}) {
    final used = <String, int>{};
    final weekSeed =
        dateForDay(0).difference(DateTime(2020)).inDays +
        variation * 7919 +
        calorieGoal;
    return List.generate(weekDays.length, (day) {
      return List.generate(3, (slot) {
        const kinds = ['早餐', '午餐', '晚餐'];
        const ratios = [.25, .45, .30];
        final kind = kinds[slot];
        final picked = _pickDish(
          kind: kind,
          targetKcal: calorieGoal * ratios[slot],
          targetProtein: proteinGoal * ratios[slot],
          used: used,
          seed: weekSeed + day * 31 + slot * 17,
        );
        used[picked.title] = (used[picked.title] ?? 0) + 1;
        return picked;
      });
    });
  }

  Meal _pickDish({
    required String kind,
    required double targetKcal,
    required double targetProtein,
    required Map<String, int> used,
    required int seed,
  }) {
    final candidates = dishPool.where((meal) => meal.kind == kind).toList();
    if (candidates.isEmpty) return dishPool.first;
    candidates.sort((a, b) {
      final byCost =
          _dishCost(
            a,
            targetKcal: targetKcal,
            targetProtein: targetProtein,
            used: used,
            seed: seed,
          ).compareTo(
            _dishCost(
              b,
              targetKcal: targetKcal,
              targetProtein: targetProtein,
              used: used,
              seed: seed,
            ),
          );
      return byCost == 0 ? a.title.compareTo(b.title) : byCost;
    });
    return candidates.first;
  }

  double _dishCost(
    Meal meal, {
    required double targetKcal,
    required double targetProtein,
    required Map<String, int> used,
    required int seed,
  }) {
    final kcalGap = (meal.kcal - targetKcal).abs();
    final proteinGap = (meal.protein - targetProtein).abs();
    final repeatPenalty = (used[meal.title] ?? 0) * 900.0;
    final jitter = _stableHash('${meal.title}:$seed') % 160;
    return kcalGap + proteinGap * 1.4 + repeatPenalty + jitter;
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  List<ShoppingEntry> shoppingForWeek() {
    final grouped = <String, ({String amount, String category, int count})>{};
    for (var day = 0; day < weekDays.length; day++) {
      for (final meal in mealsFor(day)) {
        final lines = dishIngredients[meal.title];
        if (lines == null || lines.isEmpty) {
          final current = grouped[meal.title];
          grouped[meal.title] = (
            amount: current?.amount ?? '1 份',
            category: current?.category ?? '菜品',
            count: (current?.count ?? 0) + 1,
          );
          continue;
        }
        for (final item in lines) {
          final current = grouped[item.name];
          grouped[item.name] = (
            amount: current?.amount ?? item.amount,
            category: current?.category ?? item.category,
            count: (current?.count ?? 0) + 1,
          );
        }
      }
    }
    final entries = grouped.entries
        .map(
          (entry) => ShoppingEntry(
            entry.key,
            entry.value.count > 1
                ? '${entry.value.amount} ×${entry.value.count}'
                : entry.value.amount,
            entry.value.category,
          ),
        )
        .toList();
    entries.sort((a, b) {
      final byCategory = a.category.compareTo(b.category);
      return byCategory == 0 ? a.name.compareTo(b.name) : byCategory;
    });
    return entries;
  }

  /// 根据最近 14 天体重和摄入给出带护栏的热量调整建议。
  GoalSuggestion? calorieGoalSuggestion() {
    final today = DateTime.now();
    final cutoff = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 14));
    final recentWeights = weights.where((item) {
      final date = DateTime.tryParse(item.date);
      return date != null && !date.isBefore(cutoff);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentIntake = <int>[];
    for (var i = 0; i < 14; i++) {
      final date = today.subtract(Duration(days: i));
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final value = intakeByDate[key];
      if (value != null && value > 0) recentIntake.add(value);
    }
    if (recentWeights.isEmpty && recentIntake.isEmpty) return null;

    final latest = recentWeights.isEmpty ? null : recentWeights.last.kg;
    final change = recentWeights.length > 1
        ? recentWeights.last.kg - recentWeights.first.kg
        : null;
    final average = recentIntake.isEmpty
        ? null
        : recentIntake.reduce((a, b) => a + b) / recentIntake.length;
    var next = calorieGoal;
    String reason;
    if (change != null && change < -0.8) {
      next = calorieGoal + 100;
      reason =
          '近两周体重下降 ${change.abs().toStringAsFixed(1)} kg，速度偏快，先把热量加回 100 千卡。';
    } else if (change != null && change > 0.5) {
      next = calorieGoal - 100;
      reason = '近两周体重上升 ${change.toStringAsFixed(1)} kg，先减 100 千卡观察一周。';
    } else if (average != null && average < calorieGoal * .8) {
      next = calorieGoal + 100;
      reason = '近期平均摄入 ${average.round()} 千卡，明显低于目标，不建议继续压低。';
    } else if (average != null && average > calorieGoal * 1.1) {
      next = calorieGoal - 100;
      reason = '近期平均摄入 ${average.round()} 千卡，高于目标，先减 100 千卡。';
    } else if (latest != null && targetWeight < latest) {
      next = calorieGoal - 100;
      reason =
          '最近体重 ${latest.toStringAsFixed(1)} kg，仍高于目标 ${targetWeight.toStringAsFixed(1)} kg，可以小幅下调 100 千卡。';
    } else {
      reason = latest == null
          ? '现有记录基本稳定，暂不调整热量，继续记录一周再看。'
          : '当前体重已接近目标，先维持热量，把重点放在蛋白质和运动。';
    }
    next = next.clamp(1200, 3500);
    final delta = next - calorieGoal;
    return GoalSuggestion(goal: next, delta: delta, reason: reason);
  }

  int get streakDays {
    var count = 0;
    for (var i = 0; i < weekDays.length; i++) {
      final mealCount = mealsFor(i).length;
      final done = completedFor(i).where((index) => index < mealCount).length;
      if (done >= 2) count++;
    }
    return count;
  }

  void selectDay(int index) {
    if (index < 0 || index >= weekDays.length || selectedDay == index) return;
    selectedDay = index;
    notifyListeners();
  }

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setPlanTab(int value) {
    planTab = value;
    notifyListeners();
  }

  void setInsightTab(int value) {
    insightTab = value;
    notifyListeners();
  }

  void setInsightPeriod(int value) {
    if (insightPeriod == value) return;
    insightPeriod = value;
    notifyListeners();
  }

  void setMeTab(int value) {
    meTab = value;
    notifyListeners();
  }

  void toggleMeal(int day, int index) {
    final set = _completed.putIfAbsent(day, () => <int>{});
    if (!set.remove(index)) set.add(index);
    intakeByDate[dateKeyForDay(day)] = consumedFor(day);
    notifyListeners();
    _save();
  }

  void swapMeal(int day, int index, String title) {
    final currentMeals = mealsFor(day);
    if (index < 0 || index >= currentMeals.length) return;
    final current = currentMeals[index];
    final next = swapPool.firstWhere(
      (meal) => meal.title == title,
      orElse: () => current,
    );
    final updated = [...currentMeals];
    updated[index] = next;
    _customMeals[day] = updated;
    notifyListeners();
    _save();
  }

  void addMeal(int day, AddedMeal meal) {
    final stored = meal.time.trim().isEmpty
        ? AddedMeal(
            title: meal.title,
            kind: meal.kind,
            time: currentTime,
            kcal: meal.kcal,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            image: meal.image,
          )
        : meal;
    _addedByDate.putIfAbsent(dateKeyForDay(day), () => []).add(stored);
    intakeByDate[dateKeyForDay(day)] = consumedFor(day);
    notifyListeners();
    _save();
  }

  void setDayMeals(int day, List<Meal> meals) {
    if (meals.isEmpty) return;
    _customMeals[day] = meals;
    notifyListeners();
    _save();
  }

  void setAddedMealTime(int day, int index, String time) {
    final list = _addedByDate[dateKeyForDay(day)];
    if (list == null || index < 0 || index >= list.length) return;
    final meal = list[index];
    list[index] = AddedMeal(
      title: meal.title,
      kind: meal.kind,
      time: time,
      kcal: meal.kcal,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      image: meal.image,
    );
    notifyListeners();
    _save();
  }

  /// 让模型按当天热量目标排一天三餐，返回可写入的计划。
  Future<List<Meal>?> suggestMeals(int day) async {
    final content = await chat([
      {
        'role': 'system',
        'content':
            '你是营养师。为用户排一天三餐，只返回 JSON，不要 Markdown。格式：'
            '{"meals":[{"kind":"早餐","title":"菜名","description":"主要食材","kcal":420,"protein":23,"carbs":55,"fat":13}]}。'
            '三餐总热量接近目标，蛋白质合计不少于 ${proteinGoal}g，食材要常见、做法简单。',
      },
      {
        'role': 'user',
        'content':
            '每日热量目标 ${calorieGoal} 千卡，饮水目标 ${waterTargetMl} ml，目标体重 ${targetWeight.toStringAsFixed(0)} kg。',
      },
    ]);
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final data =
          jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      final list = data['meals'] as List?;
      if (list == null || list.isEmpty) return null;
      return list.whereType<Map>().map((item) {
        final kind = '${item['kind'] ?? '加餐'}';
        return Meal(
          kind: kind,
          time: mealTimeFor(kind),
          title: '${item['title'] ?? '推荐餐'}',
          description: '${item['description'] ?? ''}',
          kcal: ((item['kcal'] as num?) ?? 0).round(),
          protein: ((item['protein'] as num?) ?? 0).round(),
          carbs: ((item['carbs'] as num?) ?? 0).round(),
          fat: ((item['fat'] as num?) ?? 0).round(),
          image: 'assets/images/food-4.jpg',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  void copyDay(int from, int to) {
    _completed[to] = {...completedFor(from)};
    _addedByDate[dateKeyForDay(to)] = [...addedFor(from)];
    final custom = _customMeals[from];
    if (custom == null || custom.isEmpty) {
      _customMeals.remove(to);
    } else {
      _customMeals[to] = [...custom];
    }
    _water[to] = waterFor(from);
    intakeByDate[dateKeyForDay(to)] = consumedFor(to);
    notifyListeners();
    _save();
  }

  void removeAddedMeal(int day, int index) {
    final list = _addedByDate[dateKeyForDay(day)];
    if (list == null || index < 0 || index >= list.length) return;
    list.removeAt(index);
    intakeByDate[dateKeyForDay(day)] = consumedFor(day);
    notifyListeners();
    _save();
  }

  void addWater(int day) {
    final next = waterFor(day) + 1;
    _water[day] = next > glassGoal ? glassGoal : next;
    notifyListeners();
    _save();
  }

  void setWater(int day, int value) {
    _water[day] = value.clamp(0, glassGoal);
    notifyListeners();
    _save();
  }

  void toggleFavorite(int recipeId) {
    if (!favorites.remove(recipeId)) favorites.add(recipeId);
    notifyListeners();
    _save();
  }

  void updateProfile({
    String? name,
    String? gender,
    int? age,
    String? planName,
    int? calorieGoal,
    int? proteinGoal,
    int? waterTargetMl,
    int? cupMl,
    double? targetWeight,
    double? heightCm,
    int? stepGoal,
    int? sleepGoalMinutes,
    int? exerciseGoalMinutes,
  }) {
    if (name != null) this.name = name;
    if (gender != null && gender.isNotEmpty) this.gender = gender;
    if (age != null) this.age = age.clamp(10, 100);
    if (planName != null) this.planName = planName;
    if (calorieGoal != null) this.calorieGoal = calorieGoal.clamp(1200, 3500);
    if (proteinGoal != null) this.proteinGoal = proteinGoal.clamp(40, 200);
    if (waterTargetMl != null)
      this.waterTargetMl = waterTargetMl.clamp(500, 5000);
    if (cupMl != null) this.cupMl = cupMl.clamp(100, 1000);
    if (targetWeight != null)
      this.targetWeight = targetWeight.clamp(30, 200).toDouble();
    if (heightCm != null) this.heightCm = heightCm.clamp(120, 220).toDouble();
    if (stepGoal != null) this.stepGoal = stepGoal.clamp(2000, 30000);
    if (sleepGoalMinutes != null)
      this.sleepGoalMinutes = sleepGoalMinutes.clamp(300, 720);
    if (exerciseGoalMinutes != null)
      this.exerciseGoalMinutes = exerciseGoalMinutes.clamp(10, 180);
    if (calorieGoal != null ||
        proteinGoal != null ||
        waterTargetMl != null ||
        targetWeight != null ||
        stepGoal != null ||
        sleepGoalMinutes != null ||
        exerciseGoalMinutes != null) {
      goalsConfigured = true;
    }
    notifyListeners();
    _save();
  }

  void markOnboardingSeen() {
    onboardingSeen = true;
    notifyListeners();
    _save();
  }

  void dismissSetupChecklist() {
    setupChecklistDismissed = true;
    notifyListeners();
    _save();
  }

  void setAiEnabled(bool value) {
    aiEnabled = value;
    notifyListeners();
    _save();
  }

  Future<bool> setRemindersEnabled(bool value) async {
    if (value) {
      final granted = await ReminderService.instance.requestPermission();
      if (!granted) return false;
    }
    remindersEnabled = value;
    notifyListeners();
    _save();
    await syncReminders();
    return true;
  }

  Future<void> setWaterReminderMinutes(int value) async {
    waterReminderMinutes = value.clamp(15, 240);
    notifyListeners();
    _save();
    await syncReminders();
  }

  Future<void> setReminderTime(String key, String value) async {
    switch (key) {
      case 'breakfast':
        breakfastTime = value;
      case 'lunch':
        lunchTime = value;
      case 'dinner':
        dinnerTime = value;
      case 'weight':
        weightTime = value;
      case 'sleep':
        sleepTime = value;
    }
    notifyListeners();
    _save();
    await syncReminders();
  }

  Future<void> syncReminders() {
    return ReminderService.instance.apply(
      enabled: remindersEnabled,
      waterMinutes: waterReminderMinutes,
      breakfast: breakfastTime,
      lunch: lunchTime,
      dinner: dinnerTime,
      weight: weightTime,
      sleep: sleepTime,
    );
  }

  void addWeight(WeightEntry entry) {
    final index = weights.indexWhere((item) => item.date == entry.date);
    final bodyFat =
        entry.bodyFat ?? (index >= 0 ? weights[index].bodyFat : null);
    weights.removeWhere((item) => item.date == entry.date);
    weights.add(WeightEntry(entry.date, entry.kg, bodyFat: bodyFat));
    weights.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
    _save();
  }

  void removeWeight(String date) {
    weights.removeWhere((item) => item.date == date);
    notifyListeners();
    _save();
  }

  void addExercise(ExerciseEntry entry) {
    exercises.add(entry);
    notifyListeners();
    _save();
  }

  void addCustomExercise(ExerciseType type) {
    if (typeFor(type.name) != null) return;
    customExercises.add(type);
    notifyListeners();
    _save();
  }

  void addChatMessage(ChatMessage message) {
    chatMessages.add(message);
    if (chatMessages.length > 60) {
      chatMessages.removeRange(0, chatMessages.length - 60);
    }
    notifyListeners();
    _save();
  }

  void saveAiReport(AiReport report) {
    aiReports[report.signature] = report;
    notifyListeners();
    _save();
  }

  void removeExercise(String id) {
    exercises.removeWhere((item) => item.id == id);
    notifyListeners();
    _save();
  }

  void addMeasure(MeasureEntry entry) {
    measures.removeWhere((item) => item.date == entry.date);
    measures.add(entry);
    measures.sort((a, b) => a.date.compareTo(b.date));
    notifyListeners();
    _save();
  }

  void removeMeasure(String date) {
    measures.removeWhere((item) => item.date == date);
    notifyListeners();
    _save();
  }

  void enterGuest() {
    guest = true;
    notifyListeners();
    _save();
  }

  Future<void> addLlmProvider({
    required String name,
    required String baseUrl,
    required String apiKey,
  }) async {
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    final provider = LlmProvider(
      id: id,
      name: name.trim(),
      baseUrl: baseUrl.trim(),
      apiKey: apiKey.trim(),
    );
    llmProviders = [...llmProviders, provider];
    activeProviderId ??= id;
    await _saveLlmKey(id, apiKey);
    await _persistLlm();
    notifyListeners();
    await fetchLlmModels(id);
  }

  Future<void> removeLlmProvider(String id) async {
    llmProviders = llmProviders.where((provider) => provider.id != id).toList();
    if (activeProviderId == id) {
      activeProviderId = llmProviders.isEmpty ? null : llmProviders.first.id;
      activeModel = llmProviders.isEmpty ? null : llmProviders.first.model;
    }
    try {
      await _secureStorage.delete(key: 'llm_key_$id');
    } catch (_) {}
    await _persistLlm();
    notifyListeners();
  }

  Future<void> fetchLlmModels(String id) async {
    final index = llmProviders.indexWhere((provider) => provider.id == id);
    if (index < 0) return;
    llmBusy = true;
    llmError = null;
    notifyListeners();
    final provider = llmProviders[index];
    try {
      final models = await _llmService.fetchModels(provider);
      _applyFetchedModels(index, models);
      await _persistLlm();
    } catch (error) {
      // 部分国内服务不实现 GET /models，用预设里的内置清单兜底。
      final preset = presetForBaseUrl(provider.baseUrl);
      final text = error.toString();
      final notImplemented = text.contains('404') || text.contains('405');
      if (notImplemented &&
          preset != null &&
          preset.fallbackModels.isNotEmpty) {
        _applyFetchedModels(
          index,
          preset.fallbackModels.map((id) => LlmModel(id: id)).toList(),
        );
        llmError = null;
        await _persistLlm();
      } else {
        llmError = text.replaceFirst('Exception: ', '');
      }
    } finally {
      llmBusy = false;
      notifyListeners();
    }
  }

  void _applyFetchedModels(int index, List<LlmModel> models) {
    if (models.isEmpty) return;
    final provider = llmProviders[index];
    final ids = models.map((model) => model.id).toSet();
    final enabled = provider.enabledModels.where(ids.contains).toList();
    final model = provider.model != null && ids.contains(provider.model)
        ? provider.model
        : models.first.id;
    llmProviders[index] = provider.copyWith(
      models: models,
      model: model,
      enabledModels: enabled.isEmpty
          ? models.map((item) => item.id).toList()
          : enabled,
    );
    if (activeProviderId == provider.id) activeModel = model;
  }

  /// 保存用户勾选的可用模型，并把当前模型切到 [active]。
  Future<void> updateProviderModels(
    String id,
    List<String> enabled,
    String active,
  ) async {
    final index = llmProviders.indexWhere((provider) => provider.id == id);
    if (index < 0) return;
    llmProviders[index] = llmProviders[index].copyWith(
      enabledModels: enabled,
      model: active,
    );
    activeProviderId = id;
    activeModel = active;
    await _persistLlm();
    notifyListeners();
  }

  Future<void> activateLlm(String providerId, String model) async {
    activeProviderId = providerId;
    activeModel = model;
    final index = llmProviders.indexWhere(
      (provider) => provider.id == providerId,
    );
    if (index >= 0)
      llmProviders[index] = llmProviders[index].copyWith(model: model);
    await _persistLlm();
    notifyListeners();
  }

  Future<String> chat(List<Map<String, dynamic>> messages) async {
    final provider = activeProvider;
    if (provider == null) throw Exception('先在设置里添加 LLM 提供商');
    final model = activeModel ?? provider.model;
    if (model == null || model.isEmpty) throw Exception('先选择一个模型');
    return _llmService.chat(
      provider: provider,
      model: model,
      messages: messages,
    );
  }

  /// 用当前提供商做一次极短的连通性测试，返回模型原文。
  Future<String> testLlm() {
    return chat([
      {'role': 'user', 'content': '只回复两个字：可用'},
    ]);
  }

  Future<AddedMeal?> analyzeFoodText(String text, {String kind = '加餐'}) async {
    final content = await chat([
      {
        'role': 'system',
        'content': '你是营养记录助手。只返回 JSON，不要 Markdown。格式：{"title":"食物名","kcal":整数,"protein":整数,"carbs":整数,"fat":整数}。数值是估算值，不确定时给保守估计。',
      },
      {'role': 'user', 'content': text},
    ]);
    final meal = _mealFromJson(content, kind);
    if (meal == null) {
      throw LlmResponseException(
        '模型返回了内容，但没有解析出营养结构',
        rawBody: content,
        model: activeModel ?? activeProvider?.model ?? '',
      );
    }
    return meal;
  }

  Future<List<PhotoFoodEstimate>?> analyzeFoodPhoto(
    Uint8List bytes, {
    String kind = '加餐',
    String note = '',
  }) async {
    final provider = activeProvider;
    if (provider == null) throw Exception('先在设置里添加 LLM 提供商');
    final model = activeModel ?? provider.model;
    if (model == null || model.isEmpty) throw Exception('先选择一个模型');
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final hint = note.trim();
    final prompt =
        '你是营养记录助手。识别照片里的食物，逐项列出，只返回 JSON，不要 Markdown。'
        '格式：{"items":[{"title":"菜名","portion":"约100g/1小碗","kcal":整数,"protein":整数,"carbs":整数,"fat":整数}]}。'
        '要求：不要合并不同菜品；按一人份估算；看不清的食材不要编造；最多列出 20 项。'
        '${hint.isEmpty ? '用户没有补充文字，请直接列出画面中所有可辨认的食物，按一人份估算，不要返回空清单。' : '用户补充说明：$hint。只估算说明中提到的食物，除非说明明确表示这些菜都吃了。'}';
    final content = await _llmService.chatWithImage(
      provider: provider,
      model: model,
      prompt: prompt,
      dataUrl: dataUrl,
    );
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw LlmResponseException(
        '模型返回了内容，但没有解析出菜品清单',
        rawBody: content,
        model: model,
      );
    }
    try {
      final data =
          jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      final rawItems = data['items'];
      if (rawItems is List && rawItems.isNotEmpty) {
        final items = rawItems.whereType<Map>().map((item) {
          return PhotoFoodEstimate(
            title: '${item['title'] ?? '识别食物'}',
            portion: '${item['portion'] ?? ''}',
            kcal: ((item['kcal'] as num?) ?? 0).round(),
            protein: ((item['protein'] as num?) ?? 0).round(),
            carbs: ((item['carbs'] as num?) ?? 0).round(),
            fat: ((item['fat'] as num?) ?? 0).round(),
          );
        }).toList();
        if (items.isNotEmpty) return items;
      }
      final single = _mealFromJson(content, kind);
      if (single != null) {
        return [
          PhotoFoodEstimate(
            title: single.title,
            kcal: single.kcal,
            protein: single.protein,
            carbs: single.carbs,
            fat: single.fat,
          ),
        ];
      }
    } catch (_) {
      // 继续抛出带原始响应的错误，方便在页面上查看模型到底返回了什么。
    }
    throw LlmResponseException(
      '模型返回了内容，但没有解析出菜品清单',
      rawBody: content,
      model: model,
    );
  }

  AddedMeal? _mealFromJson(String raw, String kind) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final data =
          jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final now = DateTime.now();
      return AddedMeal(
        title: (data['title'] ?? 'AI 识别食物').toString(),
        kind: kind,
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        kcal: ((data['kcal'] as num?) ?? 0).round(),
        protein: ((data['protein'] as num?) ?? 0).round(),
        carbs: ((data['carbs'] as num?) ?? 0).round(),
        fat: ((data['fat'] as num?) ?? 0).round(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 一句话记身体数据：一句话可以同时包含体重和多项运动。
  Future<List<BodyLog>?> analyzeBodyText(String text) async {
    final content = await chat([
      {
        'role': 'system',
        'content':
            '你是健康记录助手。用户会用一句话描述体重和/或运动。只返回 JSON，不要 Markdown。'
            '一句话可能包含多种运动，请逐项拆开。格式：'
            '{"items":[{"type":"exercise","kind":"跑步","minutes":30},'
            '{"type":"exercise","kind":"力量训练","minutes":20},'
            '{"type":"weight","kg":65.2}]}。'
            '如果用户提到“早上/上午/中午/下午/晚上/几点”，给该运动加 "startTime":"HH:mm"；'
            '早上按 07:30、上午按 09:30、中午按 12:30、下午按 15:30、晚上按 19:30，未提到则省略。'
            '不要返回 kcal，卡路里由应用根据体重和 MET 计算；'
            '用户说“跑了 5 公里”但没有时长时，按常见配速保守估计分钟数。'
            '用户身体信息：${bodyProfileSummary}，只用于判断运动强度和时长，不要复述。',
      },
      {'role': 'user', 'content': text},
    ]);
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw LlmResponseException(
        '模型返回了内容，但没有解析出运动记录',
        rawBody: content,
        model: activeModel ?? activeProvider?.model ?? '',
      );
    }
    try {
      final data =
          jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      final rawItems = data['items'];
      final items = rawItems is List ? rawItems.whereType<Map>() : [data];
      final logs = <BodyLog>[];
      for (final item in items) {
        final type = '${item['type'] ?? 'exercise'}';
        if (type == 'weight') {
          final kg = (item['kg'] as num?)?.toDouble();
          if (kg != null) logs.add(BodyLog(type: 'weight', kg: kg));
          continue;
        }
        final kind = '${item['kind'] ?? '运动'}';
        final minutes = ((item['minutes'] as num?) ?? 0).round();
        final startTime = _normalizeClockTime(item['startTime']);
        if (minutes > 0) {
          logs.add(
            BodyLog(
              type: 'exercise',
              kind: kind,
              minutes: minutes,
              startTime: startTime,
            ),
          );
        }
      }
      if (logs.isNotEmpty) return logs;
    } catch (_) {
      // 保留原始响应，交给页面展示诊断信息。
    }
    throw LlmResponseException(
      '模型返回了内容，但没有解析出运动记录',
      rawBody: content,
      model: activeModel ?? activeProvider?.model ?? '',
    );
  }

  String? _normalizeClockTime(dynamic raw) {
    final text = '${raw ?? ''}'.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<ExerciseType?> analyzeCustomExercise({
    required String name,
    required ExerciseMetric metric,
    required int amount,
    required String intensity,
    required double weightKg,
    required double heightCm,
  }) async {
    final content = await chat([
      {
        'role': 'system',
        'content':
            '你是运动能量消耗助手。根据运动名称、记录方式、本次数量、强度和体重估算代谢当量。'
            '只返回 JSON，不要 Markdown。格式：{"met":8.0,"repsPerMinute":15,"category":"力量"}。'
            'met 表示该运动的代谢当量，范围 1 到 20；'
            '数量型运动给 repsPerMinute（每分钟完成次数），范围 2 到 120；'
            '时长型运动 repsPerMinute 返回 20 即可。'
            '如该运动在长时间或多次后边际消耗明显下降，可加 "quadraticKcalPerUnit2"（负值，-0.05 到 0），否则省略。'
            'category 只能从 有氧、力量、球类、水上、舞蹈、柔韧、户外、搏击、其他 中选择。'
            '数值按普通成年人常见强度保守估计。',
      },
      {
        'role': 'user',
        'content':
            '运动：$name；记录方式：${metric == ExerciseMetric.count ? '按数量' : '按时长'}；'
            '本次数量：$amount；强度：$intensity；'
            '身高：${heightCm.toStringAsFixed(0)}cm；体重：${weightKg.toStringAsFixed(1)}kg',
      },
    ]);
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final data =
          jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
      final met = ((data['met'] as num?)?.toDouble() ?? 0)
          .clamp(1.0, 20.0)
          .toDouble();
      final reps = ((data['repsPerMinute'] as num?)?.toDouble() ?? 20)
          .clamp(2.0, 120.0)
          .toDouble();
      final quadratic =
          ((data['quadraticKcalPerUnit2'] as num?)?.toDouble() ?? 0)
              .clamp(-0.05, 0.0)
              .toDouble();
      return ExerciseType(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        category: '自定义',
        icon: customExerciseIcon,
        met: met,
        metric: metric,
        repsPerMinute: reps,
        linearKcalPerUnit: metric == ExerciseMetric.count ? met / reps : met,
        quadraticKcalPerUnit2: quadratic,
        modelSource: 'llm',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveLlmKey(String id, String key) async {
    try {
      if (key.trim().isEmpty) {
        await _secureStorage.delete(key: 'llm_key_$id');
      } else {
        await _secureStorage.write(key: 'llm_key_$id', value: key.trim());
      }
    } catch (error) {
      llmError = '密钥未能写入系统安全存储：$error';
    }
  }

  Future<void> _persistLlm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'haohao.llm.v1',
        jsonEncode({
          'activeProviderId': activeProviderId,
          'activeModel': activeModel,
          'providers': llmProviders
              .map((provider) => provider.toJson())
              .toList(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _loadLlm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('haohao.llm.v1');
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      activeProviderId = data['activeProviderId'] as String?;
      activeModel = data['activeModel'] as String?;
      final list = (data['providers'] as List? ?? []).map((item) {
        final provider = LlmProvider.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        return provider;
      }).toList();
      for (var i = 0; i < list.length; i++) {
        try {
          final key = await _secureStorage.read(key: 'llm_key_${list[i].id}');
          if (key != null) list[i] = list[i].copyWith(apiKey: key);
        } catch (_) {}
      }
      llmProviders = list;
    } catch (_) {}
  }

  Future<String?> connectHealth() async {
    if (healthBusy) return healthError;
    healthBusy = true;
    healthError = null;
    notifyListeners();
    final snapshot = await _healthService.connectAndRead();
    health = snapshot;
    healthError = snapshot.error;
    _sensorDriven = false;
    if (snapshot.steps == null && sensorSteps != null)
      _applySensorSteps(sensorSteps!);
    healthBusy = false;
    notifyListeners();
    return healthError;
  }

  Future<void> refreshHealth() async {
    if (healthBusy) return;
    healthBusy = true;
    notifyListeners();
    final snapshot = await _healthService.refreshIfAuthorized();
    if (snapshot != null) {
      health = snapshot;
      healthError = snapshot.error;
      _sensorDriven = false;
      if (snapshot.steps == null && sensorSteps != null)
        _applySensorSteps(sensorSteps!);
    }
    healthBusy = false;
    notifyListeners();
  }

  bool _stepBusy = false;

  /// 2 秒轮询：只读 Health Connect 的今日步数，失败时保留计步传感器兜底。
  Future<void> refreshSteps() async {
    if (_stepBusy) return;
    _stepBusy = true;
    final steps = await _healthService.readTodaySteps();
    _stepBusy = false;
    if (steps == null || steps <= 0) return;
    if (health.steps == steps && health.source == 'Health Connect') return;
    _applyHealthSteps(steps);
  }

  void _applyHealthSteps(int value) {
    _sensorDriven = false;
    final week = health.week.isEmpty
        ? List<HealthDay>.generate(
            7,
            (index) => HealthDay(
              date: DateTime.now().subtract(Duration(days: 6 - index)),
              steps: index == 6 ? value : 0,
              activeKcal: 0,
              sleepMinutes: 0,
            ),
          )
        : List<HealthDay>.of(health.week);
    if (week.isNotEmpty) {
      final last = week.last;
      week[week.length - 1] = HealthDay(
        date: last.date,
        steps: value,
        activeKcal: last.activeKcal,
        sleepMinutes: last.sleepMinutes,
        heartRate: last.heartRate,
      );
    }
    health = health.copyWith(
      connected: true,
      steps: value,
      source: 'Health Connect',
      syncedAt: DateTime.now(),
      week: week,
    );
    notifyListeners();
  }

  void signIn(String username) {
    if (username.trim().isNotEmpty) name = username.trim();
    guest = true;
    notifyListeners();
    _save();
  }

  void reset() {
    _completed.clear();
    _customMeals.clear();
    _planVariation = 0;
    _addedByDate.clear();
    _water.clear();
    intakeByDate.clear();
    favorites
      ..clear()
      ..add(3);
    weights
      ..clear()
      ..addAll(weightSeed);
    measures
      ..clear()
      ..addAll(measureSeed);
    exercises
      ..clear()
      ..addAll(exerciseSeed);
    customExercises.clear();
    chatMessages
      ..clear()
      ..add(const ChatMessage(text: defaultChatWelcome, fromAi: true));
    aiReports.clear();
    name = '林小满';
    uid = '';
    gender = '';
    age = 0;
    avatarBytes = null;
    planName = '轻盈生活计划';
    calorieGoal = 1850;
    proteinGoal = 95;
    waterTargetMl = 2000;
    cupMl = 250;
    targetWeight = 55;
    heightCm = 170;
    stepGoal = 10000;
    sleepGoalMinutes = 480;
    exerciseGoalMinutes = 30;
    selectedDay = todayIndex;
    goalsConfigured = false;
    onboardingSeen = false;
    setupChecklistDismissed = false;
    notifyListeners();
    _save();
  }

  Future<void> _loadExerciseEnergy() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/exercise_energy.json',
      );
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final reference = (data['referenceWeightKg'] as num?)?.toDouble() ?? 60;
      final models = data['exercises'] as Map<String, dynamic>? ?? const {};
      _builtinExerciseTypes = exerciseCatalog.map((type) {
        final item = models[type.id];
        if (item is! Map) return type;
        return type.withEnergy(
          ExerciseEnergyModel.fromJson(
            type.id,
            Map<String, dynamic>.from(item),
            referenceWeightKg: reference,
          ),
        );
      }).toList();
    } catch (_) {
      _builtinExerciseTypes = [...exerciseCatalog];
    }
  }

  Future<void> load() async {
    await _loadLlm();
    await _loadExerciseEnergy();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) _applyData(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // 存储损坏时保留默认值，不让应用卡在启动页
    }
    notifyListeners();
    await refreshHealth();
    await _startStepSensor();
  }

  /// 没有 Health Connect 数据时，用手机自带的计步传感器补齐步数。
  Future<void> _startStepSensor() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return;
    await _stepSensor.start(onUpdate: _applySensorSteps);
  }

  void _applySensorSteps(int value) {
    sensorSteps = value;
    if (health.steps != null && !_sensorDriven) return;
    _sensorDriven = true;
    final week = health.week.isEmpty
        ? List<HealthDay>.generate(
            7,
            (index) => HealthDay(
              date: DateTime.now().subtract(Duration(days: 6 - index)),
              steps: index == 6 ? value : 0,
              activeKcal: 0,
              sleepMinutes: 0,
            ),
          )
        : List<HealthDay>.of(health.week);
    if (week.isNotEmpty) {
      final last = week.last;
      week[week.length - 1] = HealthDay(
        date: last.date,
        steps: value,
        activeKcal: last.activeKcal,
        sleepMinutes: last.sleepMinutes,
        heartRate: last.heartRate,
      );
    }
    health = health.copyWith(steps: value, source: '手机传感器', week: week);
    notifyListeners();
  }

  void _applyData(Map<String, dynamic> data) {
    _completed.clear();
    _customMeals.clear();
    _addedByDate.clear();
    _water.clear();
    intakeByDate.clear();
    favorites.clear();
    weights.clear();
    measures.clear();
    exercises.clear();

    guest = data['guest'] as bool? ?? false;
    name = data['name'] as String? ?? name;
    uid = data['uid'] as String? ?? uid;
    gender = data['gender'] as String? ?? gender;
    final loadedAge = (data['age'] as num?)?.toInt();
    if (loadedAge != null) age = loadedAge.clamp(10, 100);
    final avatar = data['avatar'] as String?;
    if (avatar != null && avatar.isNotEmpty) {
      avatarBytes = base64Decode(avatar);
    }
    planName = data['planName'] as String? ?? planName;
    calorieGoal = (data['calorieGoal'] as num? ?? calorieGoal).toInt().clamp(
      1200,
      3500,
    );
    proteinGoal = (data['proteinGoal'] as num? ?? proteinGoal).toInt().clamp(
      40,
      200,
    );
    waterTargetMl = (data['waterTargetMl'] as num? ?? waterTargetMl)
        .toInt()
        .clamp(500, 5000);
    cupMl = (data['cupMl'] as num? ?? cupMl).toInt().clamp(100, 1000);
    targetWeight = (data['targetWeight'] as num? ?? targetWeight)
        .toDouble()
        .clamp(30, 200)
        .toDouble();
    heightCm = (data['heightCm'] as num? ?? heightCm)
        .toDouble()
        .clamp(120, 220)
        .toDouble();
    stepGoal = (data['stepGoal'] as num? ?? stepGoal).toInt().clamp(
      2000,
      30000,
    );
    sleepGoalMinutes = (data['sleepGoalMinutes'] as num? ?? sleepGoalMinutes)
        .toInt()
        .clamp(300, 720);
    exerciseGoalMinutes =
        (data['exerciseGoalMinutes'] as num? ?? exerciseGoalMinutes)
            .toInt()
            .clamp(10, 180);
    aiEnabled = data['aiEnabled'] as bool? ?? aiEnabled;
    remindersEnabled = data['remindersEnabled'] as bool? ?? remindersEnabled;
    waterReminderMinutes =
        (data['waterReminderMinutes'] as num? ?? waterReminderMinutes)
            .toInt()
            .clamp(15, 240);
    breakfastTime = data['breakfastTime'] as String? ?? breakfastTime;
    lunchTime = data['lunchTime'] as String? ?? lunchTime;
    dinnerTime = data['dinnerTime'] as String? ?? dinnerTime;
    weightTime = data['weightTime'] as String? ?? weightTime;
    sleepTime = data['sleepTime'] as String? ?? sleepTime;
    // 旧版本备份没有这两个标记：按「已看过引导」处理，避免升级后被强制打断。
    goalsConfigured = data['goalsConfigured'] as bool? ?? true;
    onboardingSeen = data['onboardingSeen'] as bool? ?? true;
    setupChecklistDismissed = data['setupChecklistDismissed'] as bool? ?? false;
    selectedDay = (data['selectedDay'] as int? ?? selectedDay).clamp(
      0,
      weekDays.length - 1,
    );

    final favs = (data['favorites'] as List?)?.cast<num>();
    if (favs != null) {
      favorites.addAll(favs.map((e) => e.toInt()));
    }

    final completed = data['completed'] as Map<String, dynamic>?;
    if (completed != null) {
      completed.forEach((key, value) {
        _completed[int.parse(key)] = (value as List)
            .map((e) => (e as num).toInt())
            .toSet();
      });
    }

    final customMeals = data['customMeals'] as Map<String, dynamic>?;
    if (customMeals != null) {
      customMeals.forEach((key, value) {
        _customMeals[int.parse(key)] = (value as List)
            .map((item) => _mealFromMap(Map<String, dynamic>.from(item as Map)))
            .toList();
      });
    }

    final water = data['water'] as Map<String, dynamic>?;
    if (water != null) {
      water.forEach(
        (key, value) => _water[int.parse(key)] = (value as num).toInt(),
      );
    }

    final addedByDate = data['addedByDate'] as Map<String, dynamic>?;
    if (addedByDate != null) {
      addedByDate.forEach((key, value) {
        _addedByDate[key] = (value as List)
            .map(
              (item) =>
                  _addedMealFromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      });
    } else {
      // 兼容旧版本：旧数据按周内索引保存，迁移到当前周的日期键。
      final added = data['added'] as Map<String, dynamic>?;
      if (added != null) {
        added.forEach((key, value) {
          final day = int.tryParse(key);
          if (day == null) return;
          _addedByDate[dateKeyForDay(day)] = (value as List)
              .map(
                (item) =>
                    _addedMealFromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
        });
      }
    }

    final weightList = data['weights'] as List?;
    if (weightList != null) {
      weights.addAll(
        weightList.map(
          (item) => WeightEntry(
            item['date'] as String,
            (item['kg'] as num).toDouble(),
            bodyFat: (item['bodyFat'] as num?)?.toDouble(),
          ),
        ),
      );
    }

    final measureList = data['measures'] as List?;
    if (measureList != null) {
      measures.addAll(
        measureList.map(
          (item) => MeasureEntry(
            item['date'] as String,
            (item['waist'] as num).toDouble(),
          ),
        ),
      );
    }

    final exerciseList = data['exercises'] as List?;
    if (exerciseList != null) {
      exercises.addAll(
        exerciseList.map(
          (item) => ExerciseEntry(
            id: item['id'] as String,
            date: item['date'] as String,
            kind: item['kind'] as String,
            minutes: (item['minutes'] as num).toInt(),
            intensity: item['intensity'] as String,
            kcal: (item['kcal'] as num).toInt(),
            distanceKm: (item['distanceKm'] as num?)?.toDouble(),
            count: (item['count'] as num?)?.toInt(),
            startTime: item['startTime'] as String? ?? '',
          ),
        ),
      );
    }

    final customList = data['customExercises'] as List?;
    if (customList != null) {
      customExercises.clear();
      customExercises.addAll(
        customList.map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          final metric = item['metric'] == 'count'
              ? ExerciseMetric.count
              : ExerciseMetric.duration;
          final met = ((item['met'] as num?)?.toDouble() ?? 5)
              .clamp(1.0, 20.0)
              .toDouble();
          final reps = ((item['repsPerMinute'] as num?)?.toDouble() ?? 20)
              .clamp(2.0, 120.0)
              .toDouble();
          return ExerciseType(
            id: '${item['id']}',
            name: '${item['name']}',
            category: '${item['category'] ?? '自定义'}',
            icon: customExerciseIcon,
            met: met,
            metric: metric,
            repsPerMinute: reps,
            linearKcalPerUnit:
                (item['linearKcalPerUnit'] as num?)?.toDouble() ??
                (metric == ExerciseMetric.count ? met / reps : met),
            quadraticKcalPerUnit2:
                (item['quadraticKcalPerUnit2'] as num?)?.toDouble() ?? 0,
            referenceWeightKg:
                (item['referenceWeightKg'] as num?)?.toDouble() ?? 60,
            modelSource: '${item['modelSource'] ?? item['updatedBy'] ?? 'llm'}',
          );
        }),
      );
    }

    final chatList = data['chatMessages'] as List?;
    if (chatList != null) {
      chatMessages.clear();
      chatMessages.addAll(
        chatList.map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          return ChatMessage(
            text: '${item['text'] ?? ''}',
            fromAi: item['fromAi'] == true,
            local: item['local'] == true,
          );
        }),
      );
    }
    if (chatMessages.isEmpty) {
      chatMessages.add(
        const ChatMessage(text: defaultChatWelcome, fromAi: true),
      );
    }

    final reportMap = data['aiReports'] as Map<String, dynamic>?;
    if (reportMap != null) {
      aiReports.clear();
      reportMap.forEach((key, raw) {
        if (raw is! Map) return;
        final item = Map<String, dynamic>.from(raw);
        aiReports[key] = AiReport(
          signature: key,
          text: '${item['text'] ?? ''}',
          fromModel: item['fromModel'] == true,
          error: item['error'] as String?,
        );
      });
    }

    final intake = data['intake'] as Map<String, dynamic>?;
    if (intake != null) {
      intakeByDate.addAll(
        intake.map((key, value) => MapEntry(key, (value as num).toInt())),
      );
    }
  }

  Meal _mealFromMap(Map<String, dynamic> value) => Meal(
    kind: value['kind'] as String? ?? '加餐',
    time: value['time'] as String? ?? '12:30',
    title: value['title'] as String? ?? '未命名菜品',
    description: value['description'] as String? ?? '',
    kcal: (value['kcal'] as num? ?? 0).toInt(),
    protein: (value['protein'] as num? ?? 0).toInt(),
    carbs: (value['carbs'] as num? ?? 0).toInt(),
    fat: (value['fat'] as num? ?? 0).toInt(),
    image: value['image'] as String? ?? 'assets/images/food-4.jpg',
  );

  AddedMeal _addedMealFromMap(Map<String, dynamic> value) => AddedMeal(
    title: value['title'] as String? ?? '未命名食物',
    kind: value['kind'] as String? ?? '加餐',
    time: value['time'] as String? ?? '',
    kcal: (value['kcal'] as num? ?? 0).toInt(),
    protein: (value['protein'] as num? ?? 0).toInt(),
    carbs: (value['carbs'] as num? ?? 0).toInt(),
    fat: (value['fat'] as num? ?? 0).toInt(),
    image: value['image'] as String? ?? 'assets/images/food-4.jpg',
  );

  /// 当前全部记录的 JSON 备份，可复制到剪贴板或写入文件。
  String exportJson() => const JsonEncoder.withIndent('  ').convert(_dataMap());

  /// 从备份 JSON 恢复；解析失败时不改动现有数据。
  bool importJson(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _applyData(data);
      notifyListeners();
      _save();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_dataMap()));
    } catch (_) {}
  }

  Map<String, dynamic> _dataMap() => <String, dynamic>{
    'schemaVersion': 3,
    'guest': guest,
    'name': name,
    'uid': uid,
    'gender': gender,
    'age': age,
    'avatar': avatarBytes == null ? null : base64Encode(avatarBytes!),
    'planName': planName,
    'calorieGoal': calorieGoal,
    'proteinGoal': proteinGoal,
    'waterTargetMl': waterTargetMl,
    'cupMl': cupMl,
    'targetWeight': targetWeight,
    'heightCm': heightCm,
    'stepGoal': stepGoal,
    'sleepGoalMinutes': sleepGoalMinutes,
    'exerciseGoalMinutes': exerciseGoalMinutes,
    'aiEnabled': aiEnabled,
    'remindersEnabled': remindersEnabled,
    'waterReminderMinutes': waterReminderMinutes,
    'breakfastTime': breakfastTime,
    'lunchTime': lunchTime,
    'dinnerTime': dinnerTime,
    'weightTime': weightTime,
    'sleepTime': sleepTime,
    'onboardingSeen': onboardingSeen,
    'goalsConfigured': goalsConfigured,
    'setupChecklistDismissed': setupChecklistDismissed,
    'selectedDay': selectedDay,
    'favorites': favorites.toList(),
    'completed': _completed.map(
      (key, value) => MapEntry('$key', value.toList()),
    ),
    'customMeals': _customMeals.map(
      (key, meals) => MapEntry(
        '$key',
        meals
            .map(
              (meal) => {
                'kind': meal.kind,
                'time': meal.time,
                'title': meal.title,
                'description': meal.description,
                'kcal': meal.kcal,
                'protein': meal.protein,
                'carbs': meal.carbs,
                'fat': meal.fat,
                'image': meal.image,
              },
            )
            .toList(),
      ),
    ),
    'water': _water.map((key, value) => MapEntry('$key', value)),
    'addedByDate': _addedByDate.map(
      (key, value) => MapEntry(
        key,
        value
            .map(
              (item) => {
                'title': item.title,
                'kind': item.kind,
                'time': item.time,
                'kcal': item.kcal,
                'protein': item.protein,
                'carbs': item.carbs,
                'fat': item.fat,
                'image': item.image,
              },
            )
            .toList(),
      ),
    ),
    'weights': weights
        .map(
          (item) => {
            'date': item.date,
            'kg': item.kg,
            if (item.bodyFat != null) 'bodyFat': item.bodyFat,
          },
        )
        .toList(),
    'measures': measures
        .map((item) => {'date': item.date, 'waist': item.waist})
        .toList(),
    'exercises': exercises
        .map(
          (item) => {
            'id': item.id,
            'date': item.date,
            'kind': item.kind,
            'minutes': item.minutes,
            'intensity': item.intensity,
            'kcal': item.kcal,
            if (item.distanceKm != null) 'distanceKm': item.distanceKm,
            if (item.count != null) 'count': item.count,
            if (item.startTime.isNotEmpty) 'startTime': item.startTime,
          },
        )
        .toList(),
    'customExercises': customExercises
        .map(
          (item) => {
            'id': item.id,
            'category': item.category,
            ...item.energyToJson(),
          },
        )
        .toList(),
    'chatMessages': chatMessages
        .map(
          (item) => {
            'text': item.text,
            'fromAi': item.fromAi,
            'local': item.local,
          },
        )
        .toList(),
    'aiReports': aiReports.map(
      (key, value) => MapEntry(key, {
        'text': value.text,
        'fromModel': value.fromModel,
        'error': value.error,
      }),
    ),
    'intake': intakeByDate,
  };
}
