import 'package:flutter_test/flutter_test.dart';
import 'package:haohao_chifan/data/demo_data.dart';
import 'package:haohao_chifan/models.dart';
import 'package:haohao_chifan/services/llm_service.dart';
import 'package:haohao_chifan/state/app_state.dart';

void main() {
  test('backup keeps waist and generated week meals', () {
    final state = AppState();
    state.addMeasure(const MeasureEntry('2026-11-18', 75.2));
    state.generateWeekPlan();

    final restored = AppState()..importJson(state.exportJson());

    expect(restored.measures.single.waist, 75.2);
    expect(restored.mealsFor(0).length, 3);
    expect(restored.mealsFor(6).length, 3);
    expect(
      restored.mealsFor(0).map((meal) => meal.title),
      state.mealsFor(0).map((meal) => meal.title),
    );
  });

  test('week generation fills 21 meals and a shopping list', () {
    final state = AppState()..generateWeekPlan();

    for (var day = 0; day < 7; day++) {
      expect(state.mealsFor(day), hasLength(3));
    }
    final shopping = state.shoppingForWeek();
    expect(shopping.length, greaterThan(5));
    expect(shopping.every((item) => item.amount.isNotEmpty), isTrue);
  });

  test('dish library keeps 30 breakfast, lunch and dinner options', () {
    for (final kind in const ['早餐', '午餐', '晚餐']) {
      expect(
        dishPool.where((meal) => meal.kind == kind).length,
        greaterThanOrEqualTo(30),
        reason: '$kind 菜品不足 30 道',
      );
    }
  });

  test('three meals start empty until the user adds records', () {
    final state = AppState();

    for (var day = 0; day < 7; day++) {
      expect(state.mealsFor(day), isEmpty);
      expect(state.plannedKcalFor(day), 0);
      expect(state.consumedFor(day), 0);
    }
    state.addMeal(
      0,
      AddedMeal(
        title: '皮蛋瘦肉粥',
        kind: '早餐',
        time: '',
        kcal: 360,
        protein: 20,
        carbs: 42,
        fat: 10,
      ),
    );
    expect(state.mealsFor(0), isEmpty);
    expect(state.addedForKind(0, '早餐').single.title, '皮蛋瘦肉粥');
    expect(
      state.addedForKind(0, '早餐').single.time,
      matches(RegExp(r'^\d{2}:\d{2}$')),
    );
    expect(state.consumedFor(0), 360);
  });

  test('generated plan follows goals and the common dish pool', () {
    final light = AppState()..calorieGoal = 1400;
    final heavy = AppState()..calorieGoal = 2600;
    light.generateWeekPlan();
    heavy.generateWeekPlan();

    for (var day = 0; day < 7; day++) {
      expect(light.mealsFor(day), hasLength(3));
      expect(light.mealsFor(day).map((meal) => meal.kind).toSet(), {
        '早餐',
        '午餐',
        '晚餐',
      });
    }
    final titles = {
      for (var day = 0; day < 7; day++)
        ...light.mealsFor(day).map((meal) => meal.title),
    };
    expect(titles.length, greaterThan(7));
    expect(heavy.plannedKcalFor(0), greaterThan(light.plannedKcalFor(0)));
    expect(
      heavy.mealsFor(0).map((meal) => meal.title).toList(),
      isNot(light.mealsFor(0).map((meal) => meal.title).toList()),
    );
  });

  test('generating again produces a fresh combination', () {
    final state = AppState()..generateWeekPlan();
    final first = [
      for (var day = 0; day < 7; day++)
        ...state.mealsFor(day).map((meal) => meal.title),
    ];
    state.generateWeekPlan();
    final second = [
      for (var day = 0; day < 7; day++)
        ...state.mealsFor(day).map((meal) => meal.title),
    ];
    expect(second, isNot(first));
  });

  test('dish usage counts feed the frequent-first library order', () {
    final state = AppState();
    state.addMeal(
      0,
      AddedMeal(
        title: '土豆烧牛肉盖饭',
        kind: '午餐',
        time: state.mealTimeFor('午餐'),
        kcal: 650,
        protein: 36,
        carbs: 76,
        fat: 22,
      ),
    );

    expect(state.dishUsageCounts['土豆烧牛肉盖饭'], 1);
    expect(isCommonDish('土豆烧牛肉盖饭'), isTrue);
    expect(isCommonDish('香煎三文鱼藜麦碗'), isFalse);
  });

  test('meal records use add time, can be edited and copy with the day', () {
    final state = AppState()
      ..breakfastTime = '09:15'
      ..generateWeekPlan();
    state
      ..addMeal(
        0,
        AddedMeal(
          title: '无糖酸奶',
          kind: '早餐',
          time: '',
          kcal: 90,
          protein: 9,
          carbs: 8,
          fat: 2,
        ),
      )
      ..setAddedMealTime(0, 0, '07:45')
      ..toggleMeal(0, 0)
      ..copyDay(0, 1);

    expect(state.addedForKind(0, '早餐').single.time, '07:45');
    expect(state.mealsFor(0).first.time, '09:15');
    expect(state.addedFor(1).single.title, '无糖酸奶');
    expect(state.addedFor(1).single.time, '07:45');
    expect(
      state.mealsFor(1).map((meal) => meal.title),
      state.mealsFor(0).map((meal) => meal.title),
    );
    expect(state.completedFor(1), contains(0));
    final restored = AppState()..importJson(state.exportJson());
    expect(restored.addedFor(0).single.time, '07:45');
  });

  test('exercise start time survives backup', () {
    final state = AppState();
    state.addExercise(
      const ExerciseEntry(
        id: 'e1',
        date: '2026-11-18',
        kind: '跑步',
        minutes: 30,
        intensity: '适中',
        kcal: 260,
        startTime: '19:20',
      ),
    );
    final restored = AppState()..importJson(state.exportJson());
    expect(restored.exercises.single.startTime, '19:20');
    expect(restored.exercises.single.minutes, 30);
  });

  test('body fat display uses the profile-based estimate', () {
    final state = AppState()
      ..completeProfile(
        name: 'Alex',
        gender: '男',
        age: 30,
        heightCm: 175,
        weightKg: 70,
      )
      ..addWeight(const WeightEntry('2026-11-18', 70, bodyFat: 40));

    expect(state.estimatedBodyFat, isNotNull);
    expect(state.displayBodyFat, closeTo(state.estimatedBodyFat!, 1e-9));
    expect(state.bodyFatIsEstimated, isTrue);
  });

  test('photo estimate scales with the selected portion', () {
    const estimate = PhotoFoodEstimate(
      title: '牛肉片',
      portion: '约100g',
      kcal: 200,
      protein: 20,
      carbs: 4,
      fat: 12,
    );
    final meal = estimate.toAddedMeal(kind: '午餐', time: '12:00', portion: 1.5);
    expect(meal.kcal, 300);
    expect(meal.protein, 30);
    expect(meal.carbs, 6);
    expect(meal.fat, 18);
  });

  test('calorie suggestion uses recent records', () {
    final state = AppState();
    state.addWeight(const WeightEntry('2026-11-05', 60));
    state.addWeight(const WeightEntry('2026-11-18', 58.8));
    state.intakeByDate['2026-11-18'] = 1600;

    final suggestion = state.calorieGoalSuggestion();

    expect(suggestion, isNotNull);
    expect(suggestion!.delta, greaterThan(0));
    expect(suggestion.reason, contains('下降'));
  });

  test('body fat survives backup and new weight keeps it', () {
    final state = AppState();
    state.updateProfile(heightCm: 170);
    state.addWeight(const WeightEntry('2026-11-17', 58.0, bodyFat: 22.4));

    final restored = AppState()..importJson(state.exportJson());
    expect(restored.weights.single.bodyFat, 22.4);
    expect(restored.heightCm, 170);
    expect(restored.bmi, closeTo(20.07, .05));

    state.addWeight(const WeightEntry('2026-11-17', 57.8));
    expect(state.weights.single.kg, 57.8);
    expect(state.weights.single.bodyFat, 22.4);
  });

  test('guest onboarding creates uid and persists profile', () {
    final state = AppState()
      ..completeProfile(
        name: 'Alex',
        gender: '男',
        age: 30,
        heightCm: 175,
        weightKg: 70,
      );

    expect(state.guest, isTrue);
    expect(state.profileComplete, isTrue);
    expect(state.uid, startsWith('HH-'));
    expect(state.estimatedBodyFat, closeTo(18.1, .1));

    final restored = AppState()..importJson(state.exportJson());
    expect(restored.uid, state.uid);
    expect(restored.gender, '男');
    expect(restored.age, 30);
    expect(restored.heightCm, 175);
    expect(restored.bodyPoints.last.weightKg, 70);
  });

  test('recommended goals adapt to profile and target weight', () {
    final state = AppState()
      ..completeProfile(
        name: 'Alex',
        gender: '男',
        age: 30,
        heightCm: 175,
        weightKg: 70,
      );

    final maintain = state.recommendedCalorieGoalFor(targetWeightKg: 70);
    final cut = state.recommendedCalorieGoalFor(targetWeightKg: 65);

    expect(maintain, inInclusiveRange(1200, 3500));
    expect(cut, lessThan(maintain));
    expect(state.recommendedProteinGoal, inInclusiveRange(40, 200));
    expect(state.recommendedWaterTargetMl, inInclusiveRange(1500, 3500));
    expect(state.recommendedStepGoal, 10000);
  });

  test('onboarding flags track goals and AI readiness', () {
    final state = AppState()
      ..completeProfile(
        name: 'Alex',
        gender: '女',
        age: 28,
        heightCm: 165,
        weightKg: 57,
      );

    expect(state.goalsConfigured, isFalse);
    expect(state.onboardingSeen, isFalse);
    expect(state.aiConfigured, isFalse);
    expect(state.setupChecklistVisible, isTrue);

    state.updateProfile(calorieGoal: 1700);
    expect(state.goalsConfigured, isTrue);

    state.llmProviders = [
      const LlmProvider(
        id: 'p1',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      ),
    ];
    state.activeProviderId = 'p1';
    state.activeModel = 'deepseek-chat';
    expect(state.aiConfigured, isTrue);
    expect(state.setupComplete, isTrue);
    expect(state.setupChecklistVisible, isFalse);

    state.markOnboardingSeen();
    final restored = AppState()..importJson(state.exportJson());
    expect(restored.goalsConfigured, isTrue);
    expect(restored.onboardingSeen, isTrue);
    restored.dismissSetupChecklist();
    expect(restored.setupChecklistDismissed, isTrue);
  });

  test('reminder settings survive backup', () {
    final state = AppState()
      ..waterReminderMinutes = 45
      ..breakfastTime = '09:15'
      ..sleepTime = '22:10';

    final restored = AppState()..importJson(state.exportJson());
    expect(restored.waterReminderMinutes, 45);
    expect(restored.breakfastTime, '09:15');
    expect(restored.sleepTime, '22:10');
  });
}
