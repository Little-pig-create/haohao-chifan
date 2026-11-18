import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haohao_chifan/data/exercise_catalog.dart';
import 'package:haohao_chifan/models.dart';
import 'package:haohao_chifan/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog has unique entries and covers every category', () {
    expect(exerciseCatalog.length, greaterThanOrEqualTo(50));
    expect(
      exerciseCatalog.map((item) => item.id).toSet().length,
      exerciseCatalog.length,
    );
    expect(
      exerciseCatalog.map((item) => item.name).toSet().length,
      exerciseCatalog.length,
    );
    for (final category
        in exerciseCategories.skip(1).where((item) => item != '自定义')) {
      expect(
        exerciseCatalog.any((item) => item.category == category),
        isTrue,
        reason: category,
      );
    }
  });

  test('calorie estimate scales with duration and intensity', () {
    final run = exerciseTypeByName('跑步')!;
    expect(run.kcalFor(minutes: 60, intensity: '适中', weightKg: 60), 588);
    expect(run.kcalFor(minutes: 30, intensity: '高', weightKg: 60), 368);
    expect(run.kcalFor(minutes: 30, intensity: '低', weightKg: 60), 235);
  });

  test('count exercises convert reps to estimated minutes and calories', () {
    final pushup = exerciseTypeByName('俯卧撑')!;
    expect(pushup.isCount, isTrue);
    expect(pushup.minutesForCount(30), 2);
    expect(pushup.kcalForCount(count: 30, intensity: '适中', weightKg: 60), 16);
  });

  test('energy model applies linear and quadratic coefficients', () {
    final model = ExerciseEnergyModel.fromJson('run', {
      'name': '跑步',
      'metric': 'duration',
      'met': 9.8,
      'linearKcalPerUnit': 9.8,
      'quadraticKcalPerUnit2': -0.02,
      'referenceWeightKg': 60,
      'updatedBy': 'seed',
    });
    final run = exerciseTypeById('run')!.withEnergy(model);
    expect(run.kcalFor(minutes: 60, intensity: '适中', weightKg: 60), 516);
    expect(run.kcalFor(minutes: 60, intensity: '高', weightKg: 75), 806);
  });

  test('energy asset covers built-in exercises', () async {
    final raw = await rootBundle.loadString('assets/data/exercise_energy.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final exercises = data['exercises'] as Map<String, dynamic>;
    expect(exercises.length, exerciseCatalog.length);
    expect(
      exercises.keys.toSet(),
      exerciseCatalog.map((item) => item.id).toSet(),
    );
    final run = ExerciseEnergyModel.fromJson(
      'run',
      Map<String, dynamic>.from(exercises['run'] as Map),
    );
    expect(run.quadraticKcalPerUnit2, lessThan(0));
  });

  test('custom exercise and energy model survive export and import', () {
    final state = AppState();
    state.customExercises.add(
      ExerciseType(
        id: 'custom-1',
        name: '空中自行车',
        category: '自定义',
        icon: customExerciseIcon,
        met: 6,
        metric: ExerciseMetric.count,
        repsPerMinute: 20,
        linearKcalPerUnit: .3,
        modelSource: 'llm',
      ),
    );
    state.exercises.add(
      const ExerciseEntry(
        id: 'entry-1',
        date: '2026-11-18',
        kind: '空中自行车',
        minutes: 2,
        intensity: '适中',
        kcal: 9,
        count: 30,
      ),
    );

    final restored = AppState();
    expect(restored.importJson(state.exportJson()), isTrue);
    final type = restored.typeFor('空中自行车');
    expect(type?.metric, ExerciseMetric.count);
    expect(type?.linearKcalPerUnit, .3);
    expect(restored.exercises.single.count, 30);
  });

  test('frequent sorting puts most used exercises first', () {
    final state = AppState();
    state.exercises.addAll(const [
      ExerciseEntry(
        id: 'a',
        date: '2026-11-18',
        kind: '瑜伽',
        minutes: 30,
        intensity: '适中',
        kcal: 80,
      ),
      ExerciseEntry(
        id: 'b',
        date: '2026-11-17',
        kind: '瑜伽',
        minutes: 30,
        intensity: '适中',
        kcal: 80,
      ),
      ExerciseEntry(
        id: 'c',
        date: '2026-11-16',
        kind: '跑步',
        minutes: 30,
        intensity: '适中',
        kcal: 300,
      ),
    ]);

    final sorted = state.sortedExerciseTypes();
    expect(sorted.first.name, '瑜伽');
    expect(sorted[1].name, '跑步');
    expect(state.sortedExerciseTypes(frequentFirst: false).first.name, '快走');
    expect(state.frequentExerciseTypes(limit: 2).map((item) => item.name), [
      '瑜伽',
      '跑步',
    ]);
  });

  test('chat messages and ai reports persist through export/import', () {
    final state = AppState();
    state.addChatMessage(const ChatMessage(text: '今天晚餐怎么补？', fromAi: false));
    state.saveAiReport(
      const AiReport(
        signature: 'd:2026-11-18',
        text: '做得好的：记录了晚餐。',
        fromModel: true,
      ),
    );

    final restored = AppState();
    expect(restored.importJson(state.exportJson()), isTrue);
    expect(restored.chatMessages.last.text, '今天晚餐怎么补？');
    expect(restored.aiReports['d:2026-11-18']?.fromModel, isTrue);
    expect(restored.aiReports['d:2026-11-18']?.text, '做得好的：记录了晚餐。');
  });
}
