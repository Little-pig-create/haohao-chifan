import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  bool _goalBusy = false;
  bool _showGoal = false;
  GoalSuggestion? _suggestion;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final period = state.insightPeriod;
    final today = state.selectedDay;
    final slice = _slice(state);
    final average = slice.average;
    final points = slice.points;
    final protein = state.proteinFor(today);
    final carbs = state.carbsFor(today);
    final fat = state.fatFor(today);
    final macroTotal = protein + carbs + fat;
    final score = state.healthScoreFor(today);
    final waterLiters = state.waterFor(today) * state.cupMl / 1000;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 108),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(
            '热量趋势按所选周期统计，其余指标为今日记录。',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label:
                              '${period == 0
                                  ? '本周'
                                  : period == 1
                                  ? '本月'
                                  : '三个月'}平均热量',
                          value: average == null ? '—' : formatNumber(average),
                          unit: '千卡 / 天',
                          note: average == null
                              ? '暂无记录'
                              : average > state.calorieGoal
                              ? '高于目标 ${formatNumber(average - state.calorieGoal)} 千卡'
                              : '低于目标 ${formatNumber(state.calorieGoal - average)} 千卡',
                          dark: true,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap),
                      Expanded(
                        child: _KpiCard(
                          label: '今日蛋白质',
                          value: '$protein',
                          unit: '克 / 天',
                          note: '今日记录',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label: '今日饮水',
                          value: waterLiters.toStringAsFixed(1),
                          unit: '升 / 天',
                          note:
                              '目标 ${(state.waterTargetMl / 1000).toStringAsFixed(1)} 升',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.gap),
                      Expanded(
                        child: _KpiCard(
                          label: '今日评分',
                          value: score?.toString() ?? '—',
                          unit: '分',
                          note: score == null
                              ? '数据不足'
                              : score >= 80
                              ? '良好'
                              : '待提升',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.gap),
        if (slice.recorded == 0)
          _EmptyNutritionCard(onRecord: () => state.setTab(1))
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('热量摄入趋势', style: titleStyle(size: 18)),
                    ),
                    const _Legend(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '每日目标 ${formatNumber(state.calorieGoal)} 千卡 · 柱为每日摄入，折线为体重',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 205,
                  child: CalorieTrendChart(
                    points: points,
                    goal: state.calorieGoal,
                    highlightIndex: points.isEmpty ? null : points.length - 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '记录 ${slice.recorded} / ${slice.days} 天',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      average == null
                          ? '暂无日均'
                          : '日均 ${formatNumber(average)} 千卡',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      state.health.weightKg == null
                          ? '体重 —'
                          : '体重 ${state.health.weightKg!.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('营养均衡', style: titleStyle(size: 18)),
                const SizedBox(height: 4),
                const Text(
                  '宏量营养素平均占比',
                  style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Center(
                  child: MacroDonut(
                    protein: macroTotal == 0 ? 0 : protein / macroTotal * 100,
                    carbs: macroTotal == 0 ? 0 : carbs / macroTotal * 100,
                    fat: macroTotal == 0 ? 0 : fat / macroTotal * 100,
                    centerValue: score?.toString() ?? '—',
                    centerLabel: macroTotal == 0 ? '暂无记录' : '均衡分',
                  ),
                ),
                const SizedBox(height: 14),
                _MacroLegendRow(
                  color: const Color(0xFFD9A07C),
                  label: '蛋白质',
                  percent: macroTotal == 0
                      ? '—'
                      : '${(protein / macroTotal * 100).round()}%',
                ),
                const SizedBox(height: 10),
                _MacroLegendRow(
                  color: const Color(0xFFCDEB7E),
                  label: '碳水',
                  percent: macroTotal == 0
                      ? '—'
                      : '${(carbs / macroTotal * 100).round()}%',
                ),
                const SizedBox(height: 10),
                _MacroLegendRow(
                  color: const Color(0xFFA9C6D1),
                  label: '脂肪',
                  percent: macroTotal == 0
                      ? '—'
                      : '${(fat / macroTotal * 100).round()}%',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _BodySignals(
          health: state.health,
          waterLiters: waterLiters,
          bmi: state.bmi,
        ),
        const SizedBox(height: 12),
        _GoalScore(
          score: score,
          protein: protein,
          waterLiters: waterLiters,
          steps: state.health.steps,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('今日健康洞察', style: titleStyle(size: 18))),
                  const SoftTag('本地分析'),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: Color(0xFF8B9A8D),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '根据今天的饮食与运动记录生成',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              ..._insights(state).map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lineSoft),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5ECDD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.kind == 'good'
                              ? Icons.check_rounded
                              : item.kind == 'watch'
                              ? Icons.water_drop_outlined
                              : Icons.eco_outlined,
                          size: 16,
                          color: AppColors.green2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.text,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('目标是否需要调整', style: titleStyle(size: 18)),
                const SizedBox(height: 4),
                const Text(
                  '结合体重变化与执行率给出建议，改动幅度受护栏限制（单次 ≤200 千卡）。',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                if (!_showGoal)
                  PillButton(
                    label: _goalBusy ? '分析中…' : '分析一下',
                    icon: Icons.auto_awesome_rounded,
                    tone: PillTone.outline,
                    onPressed: _goalBusy
                        ? null
                        : () async {
                            setState(() => _goalBusy = true);
                            await Future.delayed(
                              const Duration(milliseconds: 240),
                            );
                            if (!mounted) return;
                            final suggestion = state.calorieGoalSuggestion();
                            if (suggestion == null) {
                              setState(() => _goalBusy = false);
                              showToast(
                                context,
                                '记录还不够，先记录几天饮食或体重再分析',
                                icon: Icons.info_outline_rounded,
                              );
                              return;
                            }
                            setState(() {
                              _goalBusy = false;
                              _showGoal = true;
                              _suggestion = suggestion;
                            });
                          },
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: const ValueKey('advice'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${state.calorieGoal} → ${_suggestion?.goal ?? state.calorieGoal} 千卡',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 7),
                              SoftTag(
                                _suggestion == null || _suggestion!.delta == 0
                                    ? '维持'
                                    : _suggestion!.delta > 0
                                    ? '+${_suggestion!.delta}'
                                    : '${_suggestion!.delta}',
                                background: const Color(0xFFE3ECD9),
                                color: const Color(0xFF52705A),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _suggestion?.reason ?? '当前记录不足，暂不调整。',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.ink2,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 9),
                          PillButton(
                            label:
                                _suggestion == null || _suggestion!.delta == 0
                                ? '保持当前目标'
                                : '应用这个目标',
                            icon: Icons.check_rounded,
                            tone: PillTone.soft,
                            onPressed: () {
                              final goal =
                                  _suggestion?.goal ?? state.calorieGoal;
                              state.updateProfile(calorieGoal: goal);
                              showToast(
                                context,
                                '热量目标已调整为 ${formatNumber(goal)} 千卡',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ({List<TrendPoint> points, int recorded, int? average, int days}) _slice(
    AppState state,
  ) {
    final today = DateTime.now();
    final period = state.insightPeriod;
    final days = period == 0
        ? 7
        : period == 1
        ? 30
        : 90;
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    final recorded = <int>[];
    final points = <TrendPoint>[];
    final bucketSize = period == 2 ? 7 : 1;

    for (var offset = 0; offset < days; offset += bucketSize) {
      final bucketStart = start.add(Duration(days: offset));
      final bucketEnd = offset + bucketSize > days ? days : offset + bucketSize;
      final values = <int>[];
      double? weight;
      for (var index = offset; index < bucketEnd; index++) {
        final date = start.add(Duration(days: index));
        final key = _dateKey(date);
        final kcal = state.intakeByDate[key];
        if (kcal != null && kcal > 0) {
          values.add(kcal);
          recorded.add(kcal);
        }
        for (final entry in state.weights) {
          if (entry.date == key) weight = entry.kg;
        }
        if (_dateKey(today) == key && state.health.weightKg != null) {
          weight ??= state.health.weightKg;
        }
      }
      final label = period == 0
          ? const ['一', '二', '三', '四', '五', '六', '日'][bucketStart.weekday - 1]
          : period == 2 || (offset ~/ bucketSize) % 6 == 0
          ? '${bucketStart.month}/${bucketStart.day}'
          : '';
      points.add(
        TrendPoint(
          label,
          values.isEmpty
              ? null
              : values.reduce((a, b) => a + b) / values.length,
          weight,
        ),
      );
    }
    final average = recorded.isEmpty
        ? null
        : (recorded.reduce((a, b) => a + b) / recorded.length).round();
    return (
      points: points,
      recorded: recorded.length,
      average: average,
      days: days,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String note;
  final bool dark;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.note,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = label.contains('蛋白质')
        ? const Color(0xFFD9A07C)
        : label.contains('饮水')
        ? const Color(0xFFA9C6D1)
        : const Color(0xFFB9B2D8);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: dark
          ? BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FADB), Color(0xFFFFFFFF)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: const Color(0xFFE6F2CC)),
            )
          : BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.line),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!dark) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                letterSpacing: -.8,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            note,
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFCDEB7E),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '摄入',
          style: TextStyle(fontSize: 8.5, color: AppColors.muted),
        ),
        const SizedBox(width: 8),
        Container(width: 12, height: 2, color: const Color(0xFF9DB3BD)),
        const SizedBox(width: 4),
        const Text(
          '体重',
          style: TextStyle(fontSize: 8.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;

  const _MacroLegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.ink2),
        ),
        const Spacer(),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

List<({String title, String text, String kind})> _insights(AppState state) {
  final day = state.selectedDay;
  if (!state.health.hasAnyData && state.consumedFor(day) == 0) {
    return const [
      (
        title: '暂无足够数据',
        text: '连接 Health Connect 并记录一餐后，这里会基于真实数据生成洞察。',
        kind: 'watch',
      ),
    ];
  }
  final items = <({String title, String text, String kind})>[];
  final protein = state.proteinFor(day);
  final waterLeft = state.waterTargetMl - state.waterFor(day) * state.cupMl;
  final steps = state.health.steps;
  if (protein >= state.proteinGoal) {
    items.add((
      title: '蛋白质达标',
      text: '今日已记录 ${protein}g 蛋白质，达到目标。',
      kind: 'good',
    ));
  } else {
    items.add((
      title: '蛋白质还差 ${state.proteinGoal - protein}g',
      text: '晚餐可以加一份豆腐、鸡蛋或鸡胸肉。',
      kind: 'watch',
    ));
  }
  if (waterLeft > 0) {
    items.add((
      title: '饮水还差 ${formatNumber(waterLeft)}ml',
      text: '下午三点前补完，避免睡前集中喝水。',
      kind: 'watch',
    ));
  } else {
    items.add((title: '饮水已达标', text: '今天的水分摄入已经达到目标。', kind: 'good'));
  }
  if (steps != null) {
    items.add((
      title: steps >= state.stepGoal
          ? '步数达标'
          : '步数还差 ${formatNumber(state.stepGoal - steps)}',
      text: steps >= state.stepGoal
          ? '今日活动量已达到 ${formatNumber(state.stepGoal)} 步。'
          : '晚饭后快走 20 分钟就能补上。',
      kind: steps >= state.stepGoal ? 'good' : 'act',
    ));
  }
  return items;
}

class _EmptyNutritionCard extends StatelessWidget {
  final VoidCallback onRecord;
  const _EmptyNutritionCard({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 19,
              color: AppColors.green2,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '还没有饮食记录',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '记录一餐后，这里会生成热量和营养趋势。',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(label: '去记录', height: 32, onPressed: onRecord),
        ],
      ),
    );
  }
}

class _BodySignals extends StatelessWidget {
  final dynamic health;
  final double waterLiters;
  final double? bmi;
  const _BodySignals({
    required this.health,
    required this.waterLiters,
    required this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '静息心率',
        health.heartRate == null ? '—' : '${health.heartRate!.round()}',
        'bpm',
        const Color(0xFFD69C7F),
      ),
      (
        '睡眠',
        health.sleepMinutes == null
            ? '—'
            : '${(health.sleepMinutes! / 60).toStringAsFixed(1)}',
        'h',
        const Color(0xFF9C9BC0),
      ),
      (
        '体重',
        health.weightKg == null ? '—' : health.weightKg!.toStringAsFixed(1),
        'kg',
        const Color(0xFF8CB4A0),
      ),
      (
        'BMI',
        bmi == null ? '—' : bmi!.toStringAsFixed(1),
        'kg/m²',
        const Color(0xFFC9B36F),
      ),
      ('饮水', waterLiters.toStringAsFixed(1), 'L', const Color(0xFFA9C6D1)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('身体信号', style: titleStyle(size: 18)),
              const Spacer(),
              Text(
                health.syncedAt == null
                    ? '尚未同步'
                    : '同步于 ${_time(health.syncedAt)}',
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: item.$2,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                              letterSpacing: -.4,
                            ),
                            children: [
                              TextSpan(
                                text: ' ${item.$3}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _GoalScore extends StatelessWidget {
  final int? score;
  final int protein;
  final double waterLiters;
  final int? steps;
  const _GoalScore({
    required this.score,
    required this.protein,
    required this.waterLiters,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((score ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Text('目标完成度', style: titleStyle(size: 18)),
              const Spacer(),
              const SoftTag(
                '实时',
                background: AppColors.surfaceSoft,
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                score?.toString() ?? '—',
                style: const TextStyle(
                  fontSize: 40,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  score == null ? '数据不足' : '本地计算',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4D6A38),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                '满分 100',
                style: TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final x = constraints.maxWidth * progress;
              return SizedBox(
                height: 28,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFF2F3EC),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: x,
                      top: 12,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFE0B25A),
                      ),
                    ),
                    Positioned(
                      left: x - 6,
                      top: 6,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0B25A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Row(
            children: [
              Text(
                '0%',
                style: TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
              Spacer(),
              Text(
                '50%',
                style: TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
              Spacer(),
              Text(
                '100%',
                style: TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SoftTag(
                  '蛋白质 $protein g',
                  background: const Color(0xFFF2F9E5),
                  color: const Color(0xFF5C7648),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SoftTag(
                  '步数 ${steps ?? '—'}',
                  background: const Color(0xFFF6F1E7),
                  color: const Color(0xFF8A7042),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SoftTag(
                  '饮水 ${waterLiters.toStringAsFixed(1)} L',
                  background: const Color(0xFFF0F2F9),
                  color: const Color(0xFF626785),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
