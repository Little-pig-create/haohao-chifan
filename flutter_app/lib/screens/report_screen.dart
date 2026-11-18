import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/date_strip.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _mode = 0;
  bool _loading = false;

  bool get _weekly => _mode == 1;

  String _signature(AppState state) =>
      '${_weekly ? 'w' : 'd'}:${state.dateKeyForDay(state.selectedDay)}';

  /// 最近 7 天（或选中日）的真实汇总。
  _Window _window(AppState state) {
    final end = state.selectedDay;
    final days = _weekly ? 7 : 1;
    final start = math.max(0, end - days + 1);
    final span = end - start + 1;
    var recorded = 0;
    var kcal = 0;
    var protein = 0;
    var water = 0;
    var exerciseMin = 0;
    for (var day = start; day <= end; day++) {
      final eaten = state.consumedFor(day);
      final ml = state.waterFor(day) * state.cupMl;
      if (eaten > 0 || ml > 0) recorded++;
      kcal += eaten;
      protein += state.proteinFor(day);
      water += ml;
      final key = state.dateKeyForDay(day);
      exerciseMin += state.exercises
          .where((item) => item.date == key)
          .fold<int>(0, (sum, item) => sum + item.minutes);
      final date = state.dateForDay(day);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      exerciseMin += state.health.workouts
          .where(
            (item) =>
                !item.start.isBefore(dayStart) && item.start.isBefore(dayEnd),
          )
          .fold<int>(0, (sum, item) => sum + item.minutes);
    }
    final count = math.max(1, span);
    double? weightStart;
    double? weightEnd;
    final startDate = state.dateForDay(start);
    final endDate = state.dateForDay(end);
    final windowWeights = state.weights.where((item) {
      final date = DateTime.tryParse(item.date);
      return date != null &&
          !date.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          ) &&
          !date.isAfter(DateTime(endDate.year, endDate.month, endDate.day));
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    if (windowWeights.isNotEmpty) {
      weightEnd = windowWeights.last.kg;
      weightStart = windowWeights.length > 1 ? windowWeights.first.kg : null;
    }
    return _Window(
      days: span,
      recorded: recorded,
      avgKcal: kcal / count,
      avgProtein: protein / count,
      avgWater: water / count,
      avgExercise: exerciseMin / count,
      weightStart: weightStart,
      weightEnd: weightEnd,
    );
  }

  Future<void> _generate() async {
    final state = AppScope.of(context);
    final window = _window(state);
    final signature = _signature(state);
    setState(() {
      _loading = true;
    });
    final data = window.describe(state);
    if (state.activeProvider == null) {
      state.saveAiReport(
        AiReport(
          signature: signature,
          text: _localText(state, window),
          fromModel: false,
        ),
      );
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final text = await state.chat([
        {
          'role': 'system',
          'content':
              '你是健康复盘助手。只能使用用户给出的真实数字，缺数据就说缺，不要编造。'
              '用中文写 3 小段，分别以「做得好的」「需要留意」「下一步」开头，每段 1–2 句，不要 Markdown 符号，不做疾病诊断。',
        },
        {'role': 'user', 'content': data},
      ]);
      if (!mounted) return;
      state.saveAiReport(
        AiReport(signature: signature, text: text, fromModel: true),
      );
      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      state.saveAiReport(
        AiReport(
          signature: signature,
          text: _localText(state, window),
          fromModel: false,
          error: '$error'.replaceFirst('Exception: ', ''),
        ),
      );
      setState(() {
        _loading = false;
      });
    }
  }

  String _localText(AppState state, _Window window) {
    final lines = <String>[];
    if (window.recorded == 0) {
      return '这段时间还没有可复盘的记录。先在饮食页记录一餐或一杯水，报告才有依据。';
    }
    lines.add(
      window.avgProtein >= state.proteinGoal
          ? '做得好的：平均每天 ${window.avgProtein.round()} g 蛋白质，已经达到目标。'
          : '做得好的：已经记录了 ${window.recorded} 天，先把习惯稳住。',
    );
    final gaps = <String>[];
    if (window.avgProtein < state.proteinGoal)
      gaps.add(
        '蛋白质平均 ${window.avgProtein.round()} g，离 ${state.proteinGoal} g 还差 ${(state.proteinGoal - window.avgProtein).round()} g',
      );
    if (window.avgWater < state.waterTargetMl)
      gaps.add(
        '饮水平均 ${window.avgWater.round()} ml，低于 ${state.waterTargetMl} ml 目标',
      );
    if (window.avgExercise < state.exerciseGoalMinutes)
      gaps.add(
        '运动平均 ${window.avgExercise.round()} 分钟，低于每天 ${state.exerciseGoalMinutes} 分钟',
      );
    lines.add(
      gaps.isEmpty
          ? '需要留意：主要指标都在目标范围内，注意别突然大幅压低热量。'
          : '需要留意：${gaps.join('；')}。',
    );
    lines.add(
      '下一步：${window.avgProtein < state.proteinGoal ? '每餐加一份蛋白质来源' : '保持蛋白质'}，${window.avgWater < state.waterTargetMl ? '把饮水拆成 4 个时段补完' : '饮水保持'}，${window.avgExercise < state.exerciseGoalMinutes ? '晚饭后快走 20 分钟' : '运动节奏保持'}。',
    );
    return lines.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final window = _window(state);
    final report = state.aiReports[_signature(state)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 108),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(
            '数字全部来自你的记录；模型只负责把结论写清楚。',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),
        _ModeTabs(
          labels: const ['日报', '周报'],
          icons: const [Icons.schedule_rounded, Icons.calendar_today_outlined],
          selected: _mode,
          onChanged: (index) => setState(() {
            _mode = index;
          }),
        ),
        if (!_weekly) ...[
          const SizedBox(height: 12),
          DateStrip(
            selected: day,
            onChanged: (index) {
              state.selectDay(index);
            },
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: '热量',
                      value: window.avgKcal.round().toString(),
                      suffix: '/ ${state.calorieGoal} 千卡',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      label: '蛋白质',
                      value: window.avgProtein.round().toString(),
                      suffix: '/ ${state.proteinGoal} g',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: '饮水',
                      value: window.avgWater.round().toString(),
                      suffix: '/ ${state.waterTargetMl} ml',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stat(
                      label: '运动',
                      value: window.avgExercise.round().toString(),
                      suffix: '分钟 / 天',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Stat(
                label: '体重',
                value: window.weightEnd == null
                    ? '—'
                    : window.weightEnd!.toStringAsFixed(1),
                suffix: window.weightStart == null || window.weightEnd == null
                    ? 'kg'
                    : 'kg · 较最早 ${(window.weightEnd! - window.weightStart!).toStringAsFixed(1)}',
                horizontal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PillButton(
          label: _loading
              ? '生成中…'
              : report != null
              ? '重新生成'
              : _weekly
              ? '生成本周周报'
              : '生成日报',
          icon: Icons.auto_awesome_rounded,
          expand: true,
          height: 46,
          onPressed: _loading ? null : _generate,
        ),
        if (report == null && !_loading) ...[
          const SizedBox(height: 12),
          const EmptyCard(
            icon: Icons.article_outlined,
            title: '还没有生成复盘',
            text: '把这段时间的饮食、饮水、运动和体重整理成能直接照做的总结。没有配置模型时使用本地规则。',
          ),
        ],
        if (_loading) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: cardDecoration(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Skeleton(width: 190, height: 16),
                SizedBox(height: 10),
                _Skeleton(width: double.infinity, height: 10),
                SizedBox(height: 6),
                _Skeleton(width: 240, height: 10),
              ],
            ),
          ),
        ],
        if (report != null) ...[
          const SizedBox(height: 12),
          _reportCard(state, window, report),
        ],
      ],
    );
  }

  Widget _reportCard(AppState state, _Window window, AiReport report) {
    return Container(
      key: ValueKey('${report.signature}:${report.text}'),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _weekly ? '本周复盘' : '今日复盘',
                  style: titleStyle(size: 18),
                ),
              ),
              SoftTag(
                report.fromModel ? 'AI 生成' : '本地规则',
                background: report.fromModel
                    ? AppColors.accent
                    : AppColors.surfaceSoft,
                color: report.fromModel ? AppColors.ink : AppColors.muted,
              ),
            ],
          ),
          if (report.error != null) ...[
            const SizedBox(height: 8),
            Text(
              '模型请求失败，已改用本地规则：${report.error}',
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFFA6553F),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            report.text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.85,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Score(score: window.score(state)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      window.recorded == 0
                          ? '缺少记录'
                          : '记录 ${window.recorded}/${window.days} 天',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '评分按热量、蛋白质、饮水、运动和体重记录计算，仅作参考。',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Window {
  final int days;
  final int recorded;
  final double avgKcal;
  final double avgProtein;
  final double avgWater;
  final double avgExercise;
  final double? weightStart;
  final double? weightEnd;

  const _Window({
    required this.days,
    required this.recorded,
    required this.avgKcal,
    required this.avgProtein,
    required this.avgWater,
    required this.avgExercise,
    this.weightStart,
    this.weightEnd,
  });

  int score(AppState state) {
    if (recorded == 0) return 0;
    var value = 40.0;
    value +=
        (1 - (avgKcal - state.calorieGoal).abs() / state.calorieGoal).clamp(
          0.0,
          1.0,
        ) *
        20;
    value += (avgProtein / state.proteinGoal).clamp(0.0, 1.0) * 20;
    value += (avgWater / state.waterTargetMl).clamp(0.0, 1.0) * 10;
    value += (avgExercise / state.exerciseGoalMinutes).clamp(0.0, 1.0) * 10;
    return value.round().clamp(0, 100);
  }

  String describe(AppState state) {
    final weight = weightEnd == null
        ? '没有体重记录'
        : '最近体重 ${weightEnd!.toStringAsFixed(1)} kg，目标 ${state.targetWeight.toStringAsFixed(0)} kg';
    return '统计区间：最近 $days 天，有记录 $recorded 天。\n'
        '平均每日热量 ${avgKcal.round()} 千卡（目标 ${state.calorieGoal}），'
        '蛋白质 ${avgProtein.round()} g（目标 ${state.proteinGoal}），'
        '饮水 ${avgWater.round()} ml（目标 ${state.waterTargetMl}），'
        '运动 ${avgExercise.round()} 分钟（建议 ${state.exerciseGoalMinutes}）。\n$weight。';
  }
}

class _ModeTabs extends StatelessWidget {
  final List<String> labels;
  final List<IconData> icons;
  final int selected;
  final ValueChanged<int> onChanged;

  const _ModeTabs({
    required this.labels,
    required this.icons,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E4D6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: Pressable(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 38,
                decoration: BoxDecoration(
                  color: active ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x14283C2D),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 13,
                      color: active ? AppColors.green : AppColors.muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppColors.green : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final bool horizontal;

  const _Stat({
    required this.label,
    required this.value,
    required this.suffix,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Text(
        label,
        style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      Text(
        suffix,
        style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: horizontal
          ? Row(
              children: [
                content[0],
                const SizedBox(width: 8),
                content[1],
                const Spacer(),
                content[2],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
    );
  }
}

class _Score extends StatelessWidget {
  final int score;
  const _Score({required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          color: AppColors.accentSoft,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${value.round()}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
            const Text(
              '分',
              style: TextStyle(fontSize: 8, color: Color(0xFF82927F)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  const _Skeleton({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFECEEE7),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
