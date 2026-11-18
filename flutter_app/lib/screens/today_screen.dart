import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/calorie_hero.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import '../widgets/water_tip.dart';
import 'add_exercise_screen.dart';
import 'onboarding_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final health = state.health;
    final steps = health.steps;
    final waterWeek = state
        .waterWeekFor(day)
        .map((value) => value.toDouble())
        .toList();
    final waterSpark = waterWeek.any((value) => value > 0) ? waterWeek : null;
    final bodyByDate = {
      for (final point in state.bodyPoints) point.date: point,
    };
    final weightSeries = <double>[];
    final fatSeries = <double>[];
    var lastWeight = 0.0;
    var lastFat = 0.0;
    for (var i = 0; i < 7; i++) {
      final point = bodyByDate[state.dateKeyForDay(day - 6 + i)];
      if (point?.weightKg != null) lastWeight = point!.weightKg!;
      if (point?.bodyFat != null) lastFat = point!.bodyFat!;
      weightSeries.add(lastWeight);
      fatSeries.add(lastFat);
    }
    double? latestWeight;
    for (final point in state.bodyPoints.reversed) {
      if (point.weightKg != null) {
        latestWeight = point.weightKg;
        break;
      }
    }
    double? latestFat;
    for (final point in state.bodyPoints.reversed) {
      if (point.bodyFat != null) {
        latestFat = point.bodyFat;
        break;
      }
    }
    final displayFat = state.displayBodyFat;
    final fatEstimated = state.bodyFatIsEstimated;
    final weightSpark = weightSeries.any((value) => value > 0)
        ? weightSeries
        : null;
    final fatSpark = fatSeries.any((value) => value > 0) ? fatSeries : null;
    final todayKey = state.dateKeyForDay(day);
    final todayExercises = state.exercises
        .where((item) => item.date == todayKey)
        .toList();
    final todayMinutes = todayExercises.fold<int>(
      0,
      (sum, item) => sum + item.minutes,
    );
    final todayKcal = todayExercises.fold<int>(
      0,
      (sum, item) => sum + item.kcal,
    );
    final weekMinutes = List<int>.generate(7, (index) {
      final key = state.dateKeyForDay(day - 6 + index);
      return state.exercises
          .where((item) => item.date == key)
          .fold<int>(0, (sum, item) => sum + item.minutes);
    });
    final week = health.week;
    const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    final weekLabels = List<String>.generate(7, (index) {
      if (week.isEmpty) return weekdayLabels[index];
      return weekdayLabels[week[index].date.weekday - 1];
    });
    final stepsSeries = week.map((item) => item.steps.toDouble()).toList();
    final waterValues = state.waterWeekFor(day);
    final dailyDone = List<int>.generate(7, (index) {
      if (week.isEmpty) return 0;
      var done = 0;
      if (week[index].steps >= state.stepGoal) done++;
      if (waterValues[index] >= state.waterTargetMl) done++;
      return done;
    });
    final doneTotal = dailyDone.fold<int>(0, (sum, value) => sum + value);

    Future<void> connect() async {
      final error = await state.connectHealth();
      if (!context.mounted) return;
      if (error != null) {
        showToast(context, error, icon: Icons.error_outline_rounded);
      } else {
        final snapshot = state.health;
        final empty =
            snapshot.heartRate == null &&
            snapshot.sleepMinutes == null &&
            snapshot.weightKg == null &&
            snapshot.bodyFat == null &&
            snapshot.week.every((item) => item.steps == 0);
        showToast(
          context,
          empty ? '已连接 Health Connect，但还没有读到数据' : '健康数据已同步',
          icon: empty ? Icons.info_outline_rounded : Icons.check_circle_outline,
        );
      }
    }

    Future<void> recordBody() async {
      final message = await showAppSheet<String>(
        context,
        child: const BodyRecordSheet(),
      );
      if (message != null && context.mounted) showToast(context, message);
    }

    Future<void> quickMeal() async {
      await openMealLogger(context, state: state, kind: state.defaultMealKind);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        2,
        AppSpacing.page,
        108,
      ),
      children: [
        const SizedBox(height: 4),
        if (state.setupChecklistVisible) ...[
          _SetupChecklistCard(
            goalsDone: state.goalsConfigured,
            aiDone: state.aiConfigured,
            calorieGoal: state.calorieGoal,
            waterGoal: state.waterTargetMl,
            aiLabel: state.aiConfigured
                ? '${state.activeProvider?.name ?? 'AI'} · ${state.activeModel ?? state.activeProvider?.model ?? '已连接'}'
                : null,
            onGoals: () => openOnboardingPage(context),
            onAi: () => openOnboardingPage(context, initialStep: 1),
            onDismiss: state.dismissSetupChecklist,
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                  width: width,
                  icon: Icons.directions_walk_rounded,
                  label: '步数',
                  value: steps == null ? '—' : formatNumber(steps),
                  unit: '步',
                  tint: const Color(0xFF8FBF56),
                  chart: _StepsBar(
                    value: steps == null ? 0 : steps / state.stepGoal,
                  ),
                  onTap: () {
                    if (!health.connected || health.error != null) {
                      connect();
                    } else {
                      state.setTab(2);
                    }
                  },
                ),
                _MetricCard(
                  width: width,
                  icon: Icons.monitor_weight_outlined,
                  label: '体重',
                  value: latestWeight == null
                      ? '—'
                      : latestWeight.toStringAsFixed(1),
                  unit: 'kg',
                  tint: const Color(0xFF7FA0AC),
                  chart: weightSpark == null
                      ? const DashedLine(color: Color(0xFF7FA0AC), height: 28)
                      : Sparkline(
                          values: weightSpark,
                          color: const Color(0xFF7FA0AC),
                          height: 28,
                        ),
                  onTap: recordBody,
                ),
                _MetricCard(
                  width: width,
                  icon: Icons.percent_rounded,
                  label: '体脂率',
                  note: fatEstimated ? '估算' : null,
                  value: displayFat == null
                      ? '—'
                      : displayFat.toStringAsFixed(1),
                  unit: '%',
                  tint: const Color(0xFFD98D7E),
                  chart: fatSpark == null
                      ? const DashedLine(color: Color(0xFFD98D7E), height: 28)
                      : Sparkline(
                          values: fatSpark,
                          color: const Color(0xFFD98D7E),
                          height: 28,
                        ),
                  onTap: recordBody,
                ),
                _MetricCard(
                  width: width,
                  icon: Icons.water_drop_outlined,
                  label: '饮水',
                  value: (state.waterFor(day) * state.cupMl / 1000)
                      .toStringAsFixed(1),
                  unit: 'L',
                  tint: const Color(0xFFDE8B7D),
                  chart: waterSpark == null
                      ? const DashedLine(color: Color(0xFFDE8B7D), height: 28)
                      : Sparkline(
                          values: waterSpark,
                          color: const Color(0xFFDE8B7D),
                          height: 28,
                        ),
                  onTap: () {
                    state.addWater(day);
                    showToast(
                      context,
                      '已记录一杯水',
                      icon: Icons.water_drop_outlined,
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.gap),
        _QuickActions(
          onMeal: quickMeal,
          onWater: () {
            final before = state.waterFor(day);
            state.addWater(day);
            showWaterStampOverlay(context);
            showUndoToast(
              context,
              '已记录一杯水',
              icon: Icons.water_drop_outlined,
              onUndo: () => state.setWater(day, before),
            );
          },
          onWeight: recordBody,
          onExercise: () => openExerciseQuickLog(context),
        ),
        const SizedBox(height: 12),
        if (!health.connected || health.error != null) ...[
          _HealthStatusCard(
            busy: state.healthBusy,
            error: health.error,
            onRetry: connect,
          ),
        ],
        const SizedBox(height: 12),
        CalorieHero(
          consumed: state.consumedFor(day),
          goal: state.calorieGoal,
          protein: state.proteinFor(day),
          carbs: state.carbsFor(day),
          onDetails: () {
            state.setTab(3);
            state.setInsightTab(0);
          },
        ),
        const SizedBox(height: 12),
        _HealthReportCard(
          labels: weekLabels,
          steps: stepsSeries,
          weight: weightSeries,
          fat: fatSeries,
          highlightLabel: steps != null
              ? '${formatNumber(steps)} 步'
              : latestWeight != null
              ? '${latestWeight.toStringAsFixed(1)} kg'
              : latestFat != null
              ? '${latestFat.toStringAsFixed(1)}%'
              : null,
          onOpen: () {
            state.setTab(3);
            state.setInsightTab(0);
          },
        ),
        const SizedBox(height: 12),
        _GoalsOverviewCard(
          protein: state.proteinFor(day),
          proteinGoal: state.proteinGoal,
          steps: steps,
          stepGoal: state.stepGoal,
          sleepMinutes: health.sleepMinutes,
          sleepGoalMinutes: state.sleepGoalMinutes,
          waterMl: state.waterFor(day) * state.cupMl,
          waterGoal: state.waterTargetMl,
          weekDone: doneTotal,
          weekTotal: 21,
          onOpen: () {
            state.setTab(3);
            state.setInsightTab(0);
          },
        ),
        const SizedBox(height: 12),
        _ExerciseOverview(
          minutes: todayMinutes,
          kcal: todayKcal,
          weekMinutes: weekMinutes,
          onOpen: () => state.setTab(2),
          onRecord: () => openExerciseQuickLog(context),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onMeal;
  final VoidCallback onWater;
  final VoidCallback onWeight;
  final VoidCallback onExercise;

  const _QuickActions({
    required this.onMeal,
    required this.onWater,
    required this.onWeight,
    required this.onExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.restaurant_outlined,
              label: '记一餐',
              onTap: onMeal,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.water_drop_outlined,
              label: '喝杯水',
              onTap: onWater,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.monitor_weight_outlined,
              label: '称体重',
              onTap: onWeight,
            ),
          ),
          Expanded(
            child: _QuickAction(
              icon: Icons.directions_run_rounded,
              label: '记运动',
              onTap: onExercise,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F8EA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: AppColors.green2),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupChecklistCard extends StatelessWidget {
  final bool goalsDone;
  final bool aiDone;
  final int calorieGoal;
  final int waterGoal;
  final String? aiLabel;
  final VoidCallback onGoals;
  final VoidCallback onAi;
  final VoidCallback onDismiss;

  const _SetupChecklistCard({
    required this.goalsDone,
    required this.aiDone,
    required this.calorieGoal,
    required this.waterGoal,
    required this.aiLabel,
    required this.onGoals,
    required this.onAi,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final done = (goalsDone ? 1 : 0) + (aiDone ? 1 : 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F9E0), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: const Color(0xFFE4EED4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '把好好吃饭调成你的样子',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      done == 0
                          ? '还差 2 项，大约 1 分钟'
                          : done == 1
                          ? '还差 1 项就设置完了'
                          : '设置完成',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: onDismiss,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Color(0xFF9AA296),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: done / 2,
              minHeight: 3,
              backgroundColor: const Color(0xFFE6EBDD),
              valueColor: const AlwaysStoppedAnimation(AppColors.green2),
            ),
          ),
          const SizedBox(height: 10),
          _SetupRow(
            done: goalsDone,
            title: '每日目标',
            subtitle: goalsDone
                ? '热量 $calorieGoal 千卡 · 饮水 $waterGoal ml'
                : '按你的身高体重推荐热量、饮水与步数',
            onTap: goalsDone ? null : onGoals,
          ),
          const SizedBox(height: 7),
          _SetupRow(
            done: aiDone,
            title: 'AI 引擎',
            subtitle: aiDone ? aiLabel ?? '模型已连接' : '一句话记饮食、拍照识别需要先接入模型',
            onTap: aiDone ? null : onAi,
          ),
        ],
      ),
    );
  }
}

class _SetupRow extends StatelessWidget {
  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SetupRow({
    required this.done,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done ? const Color(0xFFE4EED6) : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 17,
              color: done ? AppColors.green2 : const Color(0xFFB4BCAF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (!done)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '去设置',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green2,
                  ),
                ),
              )
            else
              const Text(
                '已完成',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HealthStatusCard extends StatelessWidget {
  final bool busy;
  final String? error;
  final Future<void> Function() onRetry;

  const _HealthStatusCard({
    required this.busy,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final failed = error != null;
    final message = error ?? '尚未连接健康数据。点击「连接」读取步数、心率、睡眠和体重。';
    final showPermissionHint =
        failed && (error!.contains('权限') || error!.contains('permission'));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: failed ? const Color(0xFFFDF1EE) : const Color(0xFFF3F8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: failed ? const Color(0xFFF1D8D0) : const Color(0xFFE0EAD8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            failed
                ? Icons.error_outline_rounded
                : Icons.health_and_safety_outlined,
            size: 20,
            color: failed ? const Color(0xFFB46758) : AppColors.green2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busy
                      ? '正在连接健康数据…'
                      : failed
                      ? '健康数据连接失败'
                      : '健康数据未连接',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: failed ? const Color(0xFF8F4A3E) : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
                if (showPermissionHint) ...[
                  const SizedBox(height: 3),
                  const Text(
                    '请到 Health Connect → 应用权限 → 好好吃饭，确认步数、心率、睡眠、体重等 7 项全部允许。',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.45,
                      color: Color(0xFF8F4A3E),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PillButton(
            label: busy
                ? '连接中'
                : failed
                ? '重试'
                : '连接',
            height: 34,
            onPressed: busy
                ? null
                : () {
                    onRetry();
                  },
          ),
        ],
      ),
    );
  }
}

class _HealthReportCard extends StatelessWidget {
  final List<String> labels;
  final List<double> steps;
  final List<double> weight;
  final List<double> fat;
  final String? highlightLabel;
  final VoidCallback onOpen;

  const _HealthReportCard({
    required this.labels,
    required this.steps,
    required this.weight,
    required this.fat,
    required this.highlightLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final series = <ChartSeries>[
      if (steps.any((value) => value > 0))
        ChartSeries(values: steps, color: const Color(0xFF9CCC5A), fill: true),
      if (weight.any((value) => value > 0))
        ChartSeries(values: weight, color: const Color(0xFF7FA0AC)),
      if (fat.any((value) => value > 0))
        ChartSeries(values: fat, color: const Color(0xFFD98D7E)),
    ];
    if (series.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('健康报告', style: titleStyle(size: 18)),
                const Spacer(),
                CircleArrow(onTap: onOpen),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '近 7 天 · 步数 / 体重 / 体脂率',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '记录体重或连接健康数据后生成趋势',
                      style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                    ),
                  ),
                  Text(
                    '待记录',
                    style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('健康报告', style: titleStyle(size: 18)),
              const Spacer(),
              CircleArrow(onTap: onOpen),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '近 7 天 · 步数 / 体重 / 体脂率',
            style: TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          MultiSeriesChart(
            series: series,
            labels: labels,
            height: 170,
            highlightIndex: series.isEmpty ? null : labels.length - 1,
            highlightLabel: highlightLabel,
          ),
          if (series.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (steps.any((value) => value > 0))
                  Expanded(
                    child: _LegendItem(
                      color: const Color(0xFF9CCC5A),
                      label: '步数',
                      value: formatNumber(steps.last),
                    ),
                  ),
                if (weight.any((value) => value > 0))
                  Expanded(
                    child: _LegendItem(
                      color: const Color(0xFF7FA0AC),
                      label: '体重',
                      value: '${weight.last.toStringAsFixed(1)} kg',
                    ),
                  ),
                if (fat.any((value) => value > 0))
                  Expanded(
                    child: _LegendItem(
                      color: const Color(0xFFD98D7E),
                      label: '体脂率',
                      value: '${fat.last.toStringAsFixed(1)}%',
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalsOverviewCard extends StatelessWidget {
  final int protein;
  final int proteinGoal;
  final int? steps;
  final int stepGoal;
  final double? sleepMinutes;
  final int sleepGoalMinutes;
  final int waterMl;
  final int waterGoal;
  final int weekDone;
  final int weekTotal;
  final VoidCallback onOpen;

  const _GoalsOverviewCard({
    required this.protein,
    required this.proteinGoal,
    required this.steps,
    required this.stepGoal,
    required this.sleepMinutes,
    required this.sleepGoalMinutes,
    required this.waterMl,
    required this.waterGoal,
    required this.weekDone,
    required this.weekTotal,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final sleepGoalHours = sleepGoalMinutes / 60;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('今日目标', style: titleStyle(size: 18)),
              const SizedBox(width: 8),
              Text(
                '本周 $weekDone / $weekTotal',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              const Spacer(),
              CircleArrow(onTap: onOpen),
            ],
          ),
          const SizedBox(height: 8),
          _GoalRow(
            label: '蛋白质',
            value: '$protein / ${proteinGoal}g',
            progress: protein / proteinGoal,
            hasData: true,
          ),
          _GoalRow(
            label: '步数',
            value: steps == null
                ? '— / ${formatNumber(stepGoal)}'
                : '${formatNumber(steps!)} / ${formatNumber(stepGoal)}',
            progress: (steps ?? 0) / stepGoal,
            hasData: steps != null,
          ),
          _GoalRow(
            label: '睡眠',
            value: sleepMinutes == null
                ? '— / ${sleepGoalHours.toStringAsFixed(sleepGoalHours % 1 == 0 ? 0 : 1)}h'
                : '${sleepMinutes! ~/ 60}h ${(sleepMinutes! % 60).round()}m / '
                      '${sleepGoalHours.toStringAsFixed(sleepGoalHours % 1 == 0 ? 0 : 1)}h',
            progress: (sleepMinutes ?? 0) / sleepGoalMinutes,
            hasData: sleepMinutes != null,
          ),
          _GoalRow(
            label: '饮水',
            value: '${formatNumber(waterMl)} / ${formatNumber(waterGoal)}ml',
            progress: waterMl / waterGoal,
            hasData: true,
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final bool hasData;

  const _GoalRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = progress.clamp(0.0, 1.0).toDouble();
    final status = !hasData
        ? '无数据'
        : ratio >= 1
        ? '完成'
        : ratio > 0
        ? '进行中'
        : '未开始';
    final statusColor = !hasData
        ? const Color(0xFF9AA399)
        : ratio >= 1
        ? const Color(0xFF6E9A4F)
        : ratio > 0
        ? const Color(0xFFD79A58)
        : const Color(0xFFC07A6E);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.ink2),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 4,
              color: AppColors.lineSoft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, current, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: current,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, Color(0xFFA9D95E)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color tint;
  final Widget chart;
  final VoidCallback onTap;
  final double width;
  final String? note;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.tint,
    required this.chart,
    required this.onTap,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == '—';
    return Pressable(
      onTap: onTap,
      child: Container(
        width: width,
        height: 112,
        padding: const EdgeInsets.all(AppSpacing.card),
        decoration: cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                if (note != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF9AA399),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                text: empty ? '—' : value,
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  color: empty ? AppColors.muted : AppColors.ink,
                  letterSpacing: -.8,
                ),
                children: [
                  if (!empty && unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: AppColors.muted,
                        letterSpacing: 0,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(height: 28, width: double.infinity, child: chart),
          ],
        ),
      ),
    );
  }
}

class _StepsBar extends StatelessWidget {
  final double value;

  const _StepsBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.bottomLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 6,
            width: constraints.maxWidth,
            color: AppColors.lineSoft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, current, _) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: constraints.maxWidth * current,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, Color(0xFFA9D95E)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseOverview extends StatelessWidget {
  final int minutes;
  final int kcal;
  final List<int> weekMinutes;
  final VoidCallback onOpen;
  final VoidCallback onRecord;

  const _ExerciseOverview({
    required this.minutes,
    required this.kcal,
    required this.weekMinutes,
    required this.onOpen,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final maxMinutes = weekMinutes.fold<int>(
      1,
      (max, item) => item > max ? item : max,
    );
    final duration = minutes >= 60
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : '$minutes 分钟';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('运动概览', style: titleStyle(size: 18)),
              const Spacer(),
              CircleArrow(onTap: onOpen),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  minutes == 0 ? '今天还没有运动' : '消耗 $kcal 千卡',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final value = weekMinutes[index] / maxMinutes;
                final today = index == 6;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: value),
                        duration: Duration(milliseconds: 500 + index * 40),
                        curve: Curves.easeOutCubic,
                        builder: (context, animated, _) => Container(
                          height: 38 * animated + 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: today
                                ? AppColors.accent
                                : const Color(0xFFEFF2EA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['一', '二', '三', '四', '五', '六', '日'][index],
                        style: TextStyle(
                          fontSize: 8,
                          color: today ? AppColors.ink : AppColors.muted,
                          fontWeight: today ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          PillButton(
            label: minutes == 0 ? '记录第一次运动' : '再记一次运动',
            icon: Icons.add_rounded,
            tone: PillTone.outline,
            expand: true,
            height: 36,
            onPressed: onRecord,
          ),
        ],
      ),
    );
  }
}
