class Meal {
  final String kind;
  final String time;
  final String title;
  final String description;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String image;

  const Meal({
    required this.kind,
    required this.time,
    required this.title,
    required this.description,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.image,
  });

  Meal copyWith({String? title, String? time}) => Meal(
    kind: kind,
    time: time ?? this.time,
    title: title ?? this.title,
    description: description,
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    image: image,
  );
}

class AddedMeal {
  final String title;
  final String kind;
  final String time;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final String image;

  const AddedMeal({
    required this.title,
    required this.kind,
    required this.time,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.image = 'assets/images/food-4.jpg',
  });

  Meal toMeal() => Meal(
    kind: kind,
    time: time,
    title: title,
    description: '手动记录的加餐',
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
    image: image,
  );
}

/// 拍照识别出的单个菜品，复杂图片里可能一次返回很多项。
class PhotoFoodEstimate {
  final String title;
  final String portion;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const PhotoFoodEstimate({
    required this.title,
    this.portion = '',
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  AddedMeal toAddedMeal({required String kind, required String time}) =>
      AddedMeal(
        title: title,
        kind: kind,
        time: time,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
}

class Ingredient {
  final String name;
  final String amount;
  final String category;
  const Ingredient(this.name, this.amount, [this.category = '其他']);
}

/// 采购清单里按名称合并后的一行。
class ShoppingEntry {
  final String name;
  final String amount;
  final String category;
  const ShoppingEntry(this.name, this.amount, this.category);
}

class GoalSuggestion {
  final int goal;
  final int delta;
  final String reason;
  const GoalSuggestion({
    required this.goal,
    required this.delta,
    required this.reason,
  });
}

class Recipe {
  final int id;
  final String title;
  final String category;
  final int minutes;
  final int kcal;
  final String level;
  final String image;
  final String summary;
  final int protein;
  final int carbs;
  final int fat;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String tip;

  const Recipe({
    required this.id,
    required this.title,
    required this.category,
    required this.minutes,
    required this.kcal,
    required this.level,
    required this.image,
    required this.summary,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.steps,
    required this.tip,
  });
}

class WeightEntry {
  final String date;
  final double kg;
  final double? bodyFat;
  const WeightEntry(this.date, this.kg, {this.bodyFat});
}

/// 体重 / 体脂率的单日记录，用于身体成分曲线。
/// 两项都可以缺失：旧记录只有体重，部分体脂秤只回传体脂。
class BodyPoint {
  final String date;
  final double? weightKg;
  final double? bodyFat;
  const BodyPoint(this.date, {this.weightKg, this.bodyFat});
}

class MeasureEntry {
  final String date;
  final double waist;
  const MeasureEntry(this.date, this.waist);
}

/// AI 从一句话里解析出的身体数据记录：体重或一次运动。
class BodyLog {
  final String type; // weight | exercise
  final double? kg;
  final String? kind;
  final int? minutes;
  final int? kcal;

  const BodyLog({
    required this.type,
    this.kg,
    this.kind,
    this.minutes,
    this.kcal,
  });

  bool get isWeight => type == 'weight';

  String get summary => isWeight
      ? '体重 ${kg?.toStringAsFixed(1) ?? '—'} kg'
      : '${kind ?? '运动'} · ${minutes ?? 0} 分钟 · ${kcal ?? 0} 千卡';
}

class ExerciseEntry {
  final String id;
  final String date;
  final String kind;
  final int minutes;
  final String intensity;
  final int kcal;
  final double? distanceKm;
  final int? count;

  /// HH:mm；旧数据可能为空。
  final String startTime;

  const ExerciseEntry({
    required this.id,
    required this.date,
    required this.kind,
    required this.minutes,
    required this.intensity,
    required this.kcal,
    this.distanceKm,
    this.count,
    this.startTime = '',
  });
}

class WeekDay {
  final String weekday;
  final String day;
  const WeekDay(this.weekday, this.day);
}

const defaultChatWelcome = '早上好。我会根据本机记录和已连接的健康数据回答，不会编造没有记录过的数值。';

class ChatMessage {
  final String text;
  final bool fromAi;
  final bool local;

  const ChatMessage({
    required this.text,
    required this.fromAi,
    this.local = false,
  });
}

class AiReport {
  final String signature;
  final String text;
  final bool fromModel;
  final String? error;

  const AiReport({
    required this.signature,
    required this.text,
    required this.fromModel,
    this.error,
  });
}
