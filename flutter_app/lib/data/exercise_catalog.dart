import 'package:flutter/material.dart';

enum ExerciseMetric { duration, count }

class ExerciseType {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final double met;
  final bool tracksDistance;
  final ExerciseMetric metric;
  final double repsPerMinute;
  final double linearKcalPerUnit;
  final double quadraticKcalPerUnit2;
  final double referenceWeightKg;
  final String modelSource;
  final List<String> keywords;

  const ExerciseType({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.met,
    this.tracksDistance = false,
    this.metric = ExerciseMetric.duration,
    this.repsPerMinute = 20,
    this.linearKcalPerUnit = 0,
    this.quadraticKcalPerUnit2 = 0,
    this.referenceWeightKg = 60,
    this.modelSource = 'met',
    this.keywords = const [],
  });

  bool get isCount => metric == ExerciseMetric.count;

  double get kcalPerUnit {
    if (linearKcalPerUnit > 0) return linearKcalPerUnit;
    return isCount ? met / repsPerMinute : met;
  }

  int kcalFor({
    required int minutes,
    required String intensity,
    required double weightKg,
  }) => _kcalForUnits(minutes.toDouble(), intensity, weightKg);

  int kcalForCount({
    required int count,
    required String intensity,
    required double weightKg,
  }) => _kcalForUnits(count.toDouble(), intensity, weightKg);

  int minutesForCount(int count) =>
      (count / repsPerMinute).round().clamp(1, 600);

  int _kcalForUnits(double units, String intensity, double weightKg) {
    final factor = switch (intensity) {
      '低' => .8,
      '高' || '高强度' => 1.25,
      _ => 1.0,
    };
    final raw = kcalPerUnit * units + quadraticKcalPerUnit2 * units * units;
    final reference = referenceWeightKg <= 0 ? 60.0 : referenceWeightKg;
    return (raw * (weightKg / reference) * factor)
        .clamp(0.0, double.infinity)
        .round();
  }

  ExerciseType withEnergy(ExerciseEnergyModel model) {
    return ExerciseType(
      id: id,
      name: name,
      category: category,
      icon: icon,
      met: model.met,
      tracksDistance: tracksDistance,
      metric: model.metric,
      repsPerMinute: model.repsPerMinute,
      linearKcalPerUnit: model.linearKcalPerUnit,
      quadraticKcalPerUnit2: model.quadraticKcalPerUnit2,
      referenceWeightKg: model.referenceWeightKg,
      modelSource: model.updatedBy,
      keywords: keywords,
    );
  }

  Map<String, dynamic> energyToJson() => {
    'name': name,
    'metric': metric.name,
    'met': met,
    'repsPerMinute': repsPerMinute,
    'linearKcalPerUnit': kcalPerUnit,
    'quadraticKcalPerUnit2': quadraticKcalPerUnit2,
    'referenceWeightKg': referenceWeightKg,
    'updatedBy': modelSource,
  };
}

class ExerciseEnergyModel {
  final String id;
  final String name;
  final ExerciseMetric metric;
  final double met;
  final double repsPerMinute;
  final double linearKcalPerUnit;
  final double quadraticKcalPerUnit2;
  final double referenceWeightKg;
  final String updatedBy;

  const ExerciseEnergyModel({
    required this.id,
    required this.name,
    required this.metric,
    required this.met,
    required this.repsPerMinute,
    required this.linearKcalPerUnit,
    required this.quadraticKcalPerUnit2,
    required this.referenceWeightKg,
    required this.updatedBy,
  });

  factory ExerciseEnergyModel.fromJson(
    String id,
    Map<String, dynamic> data, {
    double referenceWeightKg = 60,
  }) {
    final metric = data['metric'] == 'count'
        ? ExerciseMetric.count
        : ExerciseMetric.duration;
    final met = ((data['met'] as num?)?.toDouble() ?? 5)
        .clamp(1.0, 20.0)
        .toDouble();
    final reps = ((data['repsPerMinute'] as num?)?.toDouble() ?? 20)
        .clamp(2.0, 120.0)
        .toDouble();
    return ExerciseEnergyModel(
      id: id,
      name: '${data['name'] ?? id}',
      metric: metric,
      met: met,
      repsPerMinute: reps,
      linearKcalPerUnit:
          (data['linearKcalPerUnit'] as num?)?.toDouble() ??
          (metric == ExerciseMetric.count ? met / reps : met),
      quadraticKcalPerUnit2:
          (data['quadraticKcalPerUnit2'] as num?)?.toDouble() ?? 0,
      referenceWeightKg:
          (data['referenceWeightKg'] as num?)?.toDouble() ?? referenceWeightKg,
      updatedBy: '${data['updatedBy'] ?? 'seed'}',
    );
  }
}

const exerciseCategories = <String>[
  '全部',
  '有氧',
  '力量',
  '球类',
  '水上',
  '舞蹈',
  '柔韧',
  '户外',
  '搏击',
  '其他',
  '自定义',
];

const customExerciseIcon = Icons.auto_awesome_rounded;

const exerciseCatalog = <ExerciseType>[
  ExerciseType(
    id: 'walk',
    name: '快走',
    category: '有氧',
    icon: Icons.directions_walk_rounded,
    met: 4.3,
    tracksDistance: true,
    keywords: ['走路', '散步', '步行'],
  ),
  ExerciseType(
    id: 'jog',
    name: '慢跑',
    category: '有氧',
    icon: Icons.directions_run_rounded,
    met: 7.0,
    tracksDistance: true,
    keywords: ['跑步', '有氧跑'],
  ),
  ExerciseType(
    id: 'run',
    name: '跑步',
    category: '有氧',
    icon: Icons.run_circle_rounded,
    met: 9.8,
    tracksDistance: true,
    keywords: ['快跑', '路跑', '户外跑'],
  ),
  ExerciseType(
    id: 'cycle',
    name: '骑行',
    category: '有氧',
    icon: Icons.directions_bike_rounded,
    met: 7.5,
    tracksDistance: true,
    keywords: ['骑车', '单车', '自行车'],
  ),
  ExerciseType(
    id: 'spinning',
    name: '动感单车',
    category: '有氧',
    icon: Icons.pedal_bike_rounded,
    met: 8.5,
    keywords: ['单车课', '室内骑行'],
  ),
  ExerciseType(
    id: 'elliptical',
    name: '椭圆机',
    category: '有氧',
    icon: Icons.accessibility_new_rounded,
    met: 5.0,
    keywords: ['椭圆仪', '有氧器械'],
  ),
  ExerciseType(
    id: 'rower',
    name: '划船机',
    category: '有氧',
    icon: Icons.rowing_rounded,
    met: 7.0,
    keywords: ['室内划船'],
  ),
  ExerciseType(
    id: 'stairs',
    name: '爬楼机',
    category: '有氧',
    icon: Icons.stairs_rounded,
    met: 8.0,
    keywords: ['登山机', '台阶机'],
  ),
  ExerciseType(
    id: 'jump_rope',
    name: '跳绳',
    category: '有氧',
    icon: Icons.sports_gymnastics_rounded,
    met: 11.0,
    keywords: ['跳神', '绳子'],
  ),
  ExerciseType(
    id: 'hiit',
    name: 'HIIT',
    category: '有氧',
    icon: Icons.bolt_rounded,
    met: 8.0,
    keywords: ['间歇', '燃脂', '高强度间歇'],
  ),
  ExerciseType(
    id: 'aerobics',
    name: '有氧操',
    category: '有氧',
    icon: Icons.accessibility_rounded,
    met: 6.5,
    keywords: ['跳操', '健身操'],
  ),
  ExerciseType(
    id: 'hula_hoop',
    name: '呼啦圈',
    category: '有氧',
    icon: Icons.loop_rounded,
    met: 4.0,
    keywords: ['呼拉圈'],
  ),
  ExerciseType(
    id: 'jumping_jack',
    name: '开合跳',
    category: '有氧',
    icon: Icons.accessibility_rounded,
    met: 8.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 35,
    keywords: ['jumping jack', '开合'],
  ),

  ExerciseType(
    id: 'strength',
    name: '力量训练',
    category: '力量',
    icon: Icons.fitness_center_rounded,
    met: 5.0,
    keywords: ['撸铁', '器械', '健身'],
  ),
  ExerciseType(
    id: 'bodyweight',
    name: '自重训练',
    category: '力量',
    icon: Icons.sports_gymnastics_rounded,
    met: 5.0,
    keywords: ['徒手', '俯卧撑', '深蹲'],
  ),
  ExerciseType(
    id: 'core',
    name: '核心训练',
    category: '力量',
    icon: Icons.accessibility_new_rounded,
    met: 4.5,
    keywords: ['腹肌', '卷腹'],
  ),
  ExerciseType(
    id: 'crossfit',
    name: '综合体能',
    category: '力量',
    icon: Icons.sports_mma_rounded,
    met: 8.0,
    keywords: ['crossfit', '体能'],
  ),
  ExerciseType(
    id: 'pushup',
    name: '俯卧撑',
    category: '力量',
    icon: Icons.fitness_center_rounded,
    met: 8.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 15,
    keywords: ['pushup', '伏地挺身'],
  ),
  ExerciseType(
    id: 'situp',
    name: '仰卧起坐',
    category: '力量',
    icon: Icons.airline_seat_recline_normal_rounded,
    met: 4.5,
    metric: ExerciseMetric.count,
    repsPerMinute: 18,
    keywords: ['situp', '起坐'],
  ),
  ExerciseType(
    id: 'crunch',
    name: '卷腹',
    category: '力量',
    icon: Icons.accessibility_new_rounded,
    met: 4.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 20,
  ),
  ExerciseType(
    id: 'squat',
    name: '深蹲',
    category: '力量',
    icon: Icons.sports_gymnastics_rounded,
    met: 5.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 20,
    keywords: ['squat', '下蹲'],
  ),
  ExerciseType(
    id: 'burpee',
    name: '波比跳',
    category: '力量',
    icon: Icons.bolt_rounded,
    met: 10.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 10,
    keywords: ['burpee', '立卧撑'],
  ),
  ExerciseType(
    id: 'pullup',
    name: '引体向上',
    category: '力量',
    icon: Icons.sports_gymnastics_rounded,
    met: 8.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 6,
    keywords: ['pullup', '单杠'],
  ),
  ExerciseType(
    id: 'mountain_climber',
    name: '俯身登山',
    category: '力量',
    icon: Icons.accessibility_new_rounded,
    met: 8.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 30,
    keywords: ['mountain climber', '登山跑'],
  ),
  ExerciseType(
    id: 'kettlebell',
    name: '壶铃',
    category: '力量',
    icon: Icons.sports_martial_arts_rounded,
    met: 8.0,
    keywords: ['壶铃摇摆'],
  ),
  ExerciseType(
    id: 'kettlebell_swing',
    name: '壶铃摇摆',
    category: '力量',
    icon: Icons.fitness_center_rounded,
    met: 9.0,
    metric: ExerciseMetric.count,
    repsPerMinute: 20,
    keywords: ['壶铃', 'swing'],
  ),
  ExerciseType(
    id: 'barbell',
    name: '杠铃',
    category: '力量',
    icon: Icons.fitness_center_rounded,
    met: 6.0,
    keywords: ['举重', '硬拉', '卧推'],
  ),
  ExerciseType(
    id: 'dumbbell_curl',
    name: '哑铃弯举',
    category: '力量',
    icon: Icons.fitness_center_rounded,
    met: 3.5,
    metric: ExerciseMetric.count,
    repsPerMinute: 15,
    keywords: ['二头肌', '哑铃'],
  ),
  ExerciseType(
    id: 'plank',
    name: '平板支撑',
    category: '力量',
    icon: Icons.accessibility_new_rounded,
    met: 3.5,
    keywords: ['plank', '支撑'],
  ),
  ExerciseType(
    id: 'wall_sit',
    name: '靠墙静蹲',
    category: '力量',
    icon: Icons.accessibility_rounded,
    met: 3.5,
    keywords: ['静蹲', 'wall sit'],
  ),

  ExerciseType(
    id: 'badminton',
    name: '羽毛球',
    category: '球类',
    icon: Icons.sports_tennis_rounded,
    met: 5.5,
    keywords: ['羽球'],
  ),
  ExerciseType(
    id: 'basketball',
    name: '篮球',
    category: '球类',
    icon: Icons.sports_basketball_rounded,
    met: 7.0,
  ),
  ExerciseType(
    id: 'soccer',
    name: '足球',
    category: '球类',
    icon: Icons.sports_soccer_rounded,
    met: 7.0,
    keywords: ['踢球'],
  ),
  ExerciseType(
    id: 'table_tennis',
    name: '乒乓球',
    category: '球类',
    icon: Icons.sports_tennis_rounded,
    met: 4.0,
    keywords: ['乒乓'],
  ),
  ExerciseType(
    id: 'tennis',
    name: '网球',
    category: '球类',
    icon: Icons.sports_tennis_rounded,
    met: 7.3,
  ),
  ExerciseType(
    id: 'volleyball',
    name: '排球',
    category: '球类',
    icon: Icons.sports_volleyball_rounded,
    met: 4.0,
  ),
  ExerciseType(
    id: 'golf',
    name: '高尔夫',
    category: '球类',
    icon: Icons.sports_golf_rounded,
    met: 4.8,
  ),
  ExerciseType(
    id: 'baseball',
    name: '棒球',
    category: '球类',
    icon: Icons.sports_baseball_rounded,
    met: 5.0,
  ),
  ExerciseType(
    id: 'handball',
    name: '手球',
    category: '球类',
    icon: Icons.sports_handball_rounded,
    met: 6.0,
  ),

  ExerciseType(
    id: 'swimming',
    name: '游泳',
    category: '水上',
    icon: Icons.pool_rounded,
    met: 8.0,
    tracksDistance: true,
    keywords: ['泳池', '自由泳'],
  ),
  ExerciseType(
    id: 'aqua',
    name: '水中有氧',
    category: '水上',
    icon: Icons.pool_rounded,
    met: 5.5,
    keywords: ['水中健身'],
  ),
  ExerciseType(
    id: 'kayak',
    name: '皮划艇',
    category: '水上',
    icon: Icons.kayaking_rounded,
    met: 5.0,
    keywords: ['划艇', '船'],
  ),
  ExerciseType(
    id: 'surfing',
    name: '冲浪',
    category: '水上',
    icon: Icons.surfing_rounded,
    met: 6.0,
  ),
  ExerciseType(
    id: 'diving',
    name: '潜水',
    category: '水上',
    icon: Icons.scuba_diving_rounded,
    met: 7.0,
  ),

  ExerciseType(
    id: 'dance',
    name: '舞蹈',
    category: '舞蹈',
    icon: Icons.music_note_rounded,
    met: 5.0,
    keywords: ['跳舞', '街舞'],
  ),
  ExerciseType(
    id: 'zumba',
    name: '尊巴',
    category: '舞蹈',
    icon: Icons.nightlife_rounded,
    met: 6.5,
    keywords: ['zumba'],
  ),
  ExerciseType(
    id: 'square_dance',
    name: '广场舞',
    category: '舞蹈',
    icon: Icons.groups_rounded,
    met: 4.5,
    keywords: ['坝坝舞'],
  ),
  ExerciseType(
    id: 'ballet',
    name: '芭蕾',
    category: '舞蹈',
    icon: Icons.theater_comedy_rounded,
    met: 5.0,
    keywords: ['形体'],
  ),

  ExerciseType(
    id: 'yoga',
    name: '瑜伽',
    category: '柔韧',
    icon: Icons.self_improvement_rounded,
    met: 2.5,
  ),
  ExerciseType(
    id: 'pilates',
    name: '普拉提',
    category: '柔韧',
    icon: Icons.accessibility_new_rounded,
    met: 3.0,
  ),
  ExerciseType(
    id: 'stretch',
    name: '拉伸',
    category: '柔韧',
    icon: Icons.accessibility_rounded,
    met: 2.3,
    keywords: ['放松', '拉筋'],
  ),
  ExerciseType(
    id: 'tai_chi',
    name: '太极',
    category: '柔韧',
    icon: Icons.self_improvement_rounded,
    met: 3.0,
    keywords: ['太极拳'],
  ),
  ExerciseType(
    id: 'baduanjin',
    name: '八段锦',
    category: '柔韧',
    icon: Icons.self_improvement_rounded,
    met: 2.5,
  ),

  ExerciseType(
    id: 'hiking',
    name: '徒步',
    category: '户外',
    icon: Icons.hiking_rounded,
    met: 6.0,
    tracksDistance: true,
    keywords: ['健走', '远足'],
  ),
  ExerciseType(
    id: 'mountaineering',
    name: '登山',
    category: '户外',
    icon: Icons.terrain_rounded,
    met: 7.0,
    tracksDistance: true,
    keywords: ['爬山'],
  ),
  ExerciseType(
    id: 'climbing',
    name: '攀岩',
    category: '户外',
    icon: Icons.landscape_rounded,
    met: 8.0,
    keywords: ['抱石'],
  ),
  ExerciseType(
    id: 'skateboard',
    name: '滑板',
    category: '户外',
    icon: Icons.skateboarding_rounded,
    met: 5.0,
  ),
  ExerciseType(
    id: 'roller_skating',
    name: '轮滑',
    category: '户外',
    icon: Icons.roller_skating_rounded,
    met: 7.0,
    keywords: ['溜冰', '旱冰'],
  ),
  ExerciseType(
    id: 'skiing',
    name: '滑雪',
    category: '户外',
    icon: Icons.downhill_skiing_rounded,
    met: 7.0,
    tracksDistance: true,
  ),
  ExerciseType(
    id: 'snowboard',
    name: '单板滑雪',
    category: '户外',
    icon: Icons.snowboarding_rounded,
    met: 7.0,
    tracksDistance: true,
  ),
  ExerciseType(
    id: 'dog_walk',
    name: '遛狗',
    category: '户外',
    icon: Icons.pets_rounded,
    met: 3.0,
    tracksDistance: true,
  ),

  ExerciseType(
    id: 'boxing',
    name: '拳击',
    category: '搏击',
    icon: Icons.sports_mma_rounded,
    met: 8.0,
    keywords: ['打拳'],
  ),
  ExerciseType(
    id: 'kickboxing',
    name: '搏击操',
    category: '搏击',
    icon: Icons.sports_martial_arts_rounded,
    met: 9.0,
    keywords: ['搏击', '燃脂操'],
  ),
  ExerciseType(
    id: 'taekwondo',
    name: '跆拳道',
    category: '搏击',
    icon: Icons.sports_martial_arts_rounded,
    met: 10.0,
  ),
  ExerciseType(
    id: 'mma',
    name: '综合格斗',
    category: '搏击',
    icon: Icons.sports_mma_rounded,
    met: 9.0,
    keywords: ['mma', '格斗'],
  ),
  ExerciseType(
    id: 'karate',
    name: '空手道',
    category: '搏击',
    icon: Icons.sports_martial_arts_rounded,
    met: 10.0,
  ),

  ExerciseType(
    id: 'housework',
    name: '家务',
    category: '其他',
    icon: Icons.cleaning_services_rounded,
    met: 2.5,
    keywords: ['打扫', '清洁'],
  ),
  ExerciseType(
    id: 'gardening',
    name: '园艺',
    category: '其他',
    icon: Icons.yard_rounded,
    met: 3.0,
    keywords: ['种花', '种菜'],
  ),
];

ExerciseType? exerciseTypeByName(String name) {
  for (final type in exerciseCatalog) {
    if (type.name == name) return type;
  }
  return null;
}

ExerciseType? exerciseTypeById(String id) {
  for (final type in exerciseCatalog) {
    if (type.id == id) return type;
  }
  return null;
}

IconData exerciseIcon(String name) =>
    exerciseTypeByName(name)?.icon ?? Icons.directions_run_rounded;
