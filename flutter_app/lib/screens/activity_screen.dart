import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/health_service.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import 'add_exercise_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Future<void> _openAiExercise(BuildContext context) async {
    final state = AppScope.of(context);
    if (!state.aiConfigured) {
      showToast(context, '先在「我的 → AI 引擎」配置模型', icon: Icons.link_off_rounded);
      return;
    }
    final message = await showAppSheet<String>(
      context,
      child: const AiLogSheet(mode: 'body'),
    );
    if (message != null && context.mounted) showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final health = state.health;
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final deviceWorkouts = health.workouts
        .where((item) => item.start.isAfter(weekStart))
        .toList();
    final weekExercises = state.exercises
        .where(
          (item) => DateTime.tryParse(item.date)?.isAfter(weekStart) ?? false,
        )
        .toList();
    final weekMinutes =
        weekExercises.fold<int>(0, (sum, item) => sum + item.minutes) +
        deviceWorkouts.fold<int>(0, (sum, item) => sum + item.minutes);
    final weekKcal =
        weekExercises.fold<int>(0, (sum, item) => sum + item.kcal) +
        deviceWorkouts.fold<int>(0, (sum, item) => sum + item.kcal);
    final todayKey = state.todayIso;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayExercises = state.exercises.where(
      (item) => item.date == todayKey,
    );
    final todayDevice = health.workouts.where(
      (item) =>
          !item.start.isBefore(todayStart) && item.start.isBefore(todayEnd),
    );
    final todayMinutes =
        todayExercises.fold<int>(0, (sum, item) => sum + item.minutes) +
        todayDevice.fold<int>(0, (sum, item) => sum + item.minutes);
    final todayKcal =
        todayExercises.fold<int>(0, (sum, item) => sum + item.kcal) +
        todayDevice.fold<int>(0, (sum, item) => sum + item.kcal);
    final steps = health.steps;
    final stepRatio = ((steps ?? 0) / state.stepGoal)
        .clamp(0.0, 1.0)
        .toDouble();
    final activeKcal = health.activeKcal?.round() ?? todayKcal;
    final distance = steps == null ? null : steps * 0.00072;
    final weekByType = <String, int>{};
    for (final entry in weekExercises) {
      final name = state.typeFor(entry.kind)?.category ?? '其他';
      weekByType[name] = (weekByType[name] ?? 0) + entry.minutes;
    }
    final weekTypeEntries = weekByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxTypeMinutes = weekTypeEntries.isEmpty
        ? 1
        : weekTypeEntries.first.value;
    final recentExercises = [...state.exercises]
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        final aTime = a.startTime.isEmpty ? '00:00' : a.startTime;
        final bTime = b.startTime.isEmpty ? '00:00' : b.startTime;
        return bTime.compareTo(aTime);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 108),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(
            '把走路、通勤和训练都算进今天的活动量。',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1FAE3), Color(0xFFFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.hero),
            border: Border.all(color: const Color(0xFFE7F1D9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '今日步数',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text.rich(
                          TextSpan(
                            text: steps == null ? '未同步' : formatNumber(steps),
                            style: TextStyle(
                              fontSize: steps == null ? 22 : 38,
                              height: steps == null ? 1.7 : 1,
                              fontWeight: steps == null
                                  ? FontWeight.w500
                                  : FontWeight.w300,
                              color: steps == null
                                  ? AppColors.muted
                                  : AppColors.ink,
                              letterSpacing: -1.4,
                            ),
                            children: [
                              if (steps != null)
                                TextSpan(
                                  text: ' / ${formatNumber(state.stepGoal)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.muted,
                                    letterSpacing: 0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps == null
                              ? (health.connected
                                    ? 'Health Connect 里还没有今天的步数记录'
                                    : '连接健康数据后读取步数')
                              : '还差 ${formatNumber((state.stepGoal - steps).clamp(0, state.stepGoal))} 步达成目标',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: stepRatio),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CustomPaint(
                        painter: _StepRingPainter(value),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(value * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const Text(
                                '目标',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _mini(
                      Icons.local_fire_department_outlined,
                      '今日消耗',
                      '$activeKcal',
                      '千卡',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _mini(
                      Icons.timer_outlined,
                      '今日时长',
                      '$todayMinutes',
                      '分钟',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _mini(
                      Icons.route_outlined,
                      '今日距离',
                      distance == null ? '—' : distance.toStringAsFixed(1),
                      '公里',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: '手动记录运动',
                      icon: Icons.edit_note_rounded,
                      expand: true,
                      height: 38,
                      onPressed: () => openAddExercisePage(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PillButton(
                      label: 'AI 速记',
                      icon: Icons.auto_awesome_rounded,
                      tone: PillTone.soft,
                      expand: true,
                      height: 38,
                      onPressed: () => _openAiExercise(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!health.connected ||
            health.error != null ||
            health.source == '手机传感器') ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(AppSpacing.card),
            decoration: BoxDecoration(
              color: health.error != null
                  ? const Color(0xFFFDF1EE)
                  : const Color(0xFFF3F8EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: health.error != null
                    ? const Color(0xFFF1D8D0)
                    : const Color(0xFFE0EAD8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  health.error != null
                      ? Icons.error_outline_rounded
                      : Icons.watch_outlined,
                  size: 20,
                  color: health.error != null
                      ? const Color(0xFFB46758)
                      : AppColors.green2,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    health.error ??
                        (health.source == '手机传感器'
                            ? '步数来自手机计步传感器，从首次打开 App 起累计；在系统里允许「健康」写入 Health Connect 可拿到全天数据。'
                            : '连接 Health Connect 读取真实步数、心率、睡眠和活动消耗。'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ),
                PillButton(
                  label: state.healthBusy
                      ? '连接中'
                      : health.error != null
                      ? '重试'
                      : '连接',
                  height: 32,
                  onPressed: state.healthBusy
                      ? null
                      : () async {
                          final error = await state.connectHealth();
                          if (!context.mounted) return;
                          showToast(
                            context,
                            error ?? '健康数据已同步',
                            icon: error == null
                                ? Icons.check_circle_outline
                                : Icons.error_outline_rounded,
                          );
                        },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('本周活动', style: titleStyle(size: 18)),
                  const Spacer(),
                  SoftTag(
                    health.week.isEmpty ||
                            health.week.every((day) => day.steps == 0)
                        ? '暂无数据'
                        : '平均 ${formatNumber((health.week.fold<int>(0, (sum, day) => sum + day.steps) / 7).round())} 步',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '本周运动 $weekMinutes 分钟 · 消耗 ${formatNumber(weekKcal)} 千卡',
                style: const TextStyle(fontSize: 10, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (health.week.every((day) => day.steps == 0))
                SizedBox(
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const DashedLine(color: AppColors.sage, height: 72),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppColors.surface,
                        child: const Text(
                          '连接健康数据后显示 7 天步数趋势',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 112,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final day = health.week[index];
                      final maxSteps = math.max(
                        1,
                        health.week.map((item) => item.steps).reduce(math.max),
                      );
                      final value = (day.steps / maxSteps)
                          .clamp(0.0, 1.0)
                          .toDouble();
                      final today = index == 6;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${(day.steps / 1000).toStringAsFixed(1)}k',
                              style: const TextStyle(
                                fontSize: 7.5,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: value),
                              duration: Duration(
                                milliseconds: 600 + index * 50,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, animated, _) => Container(
                                height: 64 * animated,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: today
                                      ? AppColors.accent
                                      : const Color(0xFFEFF2EA),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              ['一', '二', '三', '四', '五', '六', '日'][index],
                              style: TextStyle(
                                fontSize: 8.5,
                                color: today ? AppColors.ink : AppColors.muted,
                                fontWeight: today
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        if (health.week.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BodyTrendCard(
            week: health.week,
            onOpen: () {
              state.setTab(3);
              state.setInsightTab(0);
            },
          ),
        ],
        if (weekTypeEntries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('本周运动构成', style: titleStyle(size: 18)),
                    const Spacer(),
                    SoftTag('${weekExercises.length} 次记录'),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '手动记录按运动类别拆分，设备同步的运动会单独列出。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                ...weekTypeEntries.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text(
                            item.key,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.ink2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: item.value / maxTypeMinutes,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.green2,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.value} 分钟',
                          style: const TextStyle(
                            fontSize: 9.5,
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
        ],
        if (deviceWorkouts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('设备同步的运动', style: titleStyle(size: 18)),
                    const Spacer(),
                    const SoftTag('Health Connect'),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '来自系统健康数据，不会重复计入手动记录。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                ...deviceWorkouts
                    .take(5)
                    .map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_run_rounded,
                              size: 15,
                              color: AppColors.green2,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                item.kind,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              '${item.minutes} 分钟',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.ink2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.kcal} 千卡',
                              style: const TextStyle(
                                fontSize: 10,
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
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('最近运动', style: titleStyle(size: 18)),
                  const Spacer(),
                  Text(
                    '${state.exercises.length} 次',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (state.exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '还没有手动记录，点上方「手动记录运动」开始。',
                    style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                  ),
                ),
              ...recentExercises.asMap().entries.map((item) {
                final entry = item.value;
                final last = item.key == recentExercises.length - 1;
                final start = entry.startTime;
                final end = start.isEmpty
                    ? ''
                    : addMinutesToClock(start, entry.minutes);
                final range = start.isEmpty ? '未记录开始时间' : '$start – $end';
                final dayLabel = entry.date == state.todayIso
                    ? '今天'
                    : entry.date.length >= 10
                    ? entry.date.substring(5)
                    : entry.date;
                final distance = entry.distanceKm == null
                    ? ''
                    : ' · ${entry.distanceKm!.toStringAsFixed(1)} 公里';
                final count = entry.count == null ? '' : '${entry.count} 个 · ';
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 44,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            start.isEmpty ? '--:--' : start,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 18,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (!last)
                              Positioned(
                                left: 8,
                                top: 20,
                                bottom: 0,
                                child: Container(
                                  width: 1.5,
                                  color: AppColors.line,
                                ),
                              ),
                            Positioned(
                              left: 3,
                              top: 13,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.green2,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lineSoft),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  state.typeFor(entry.kind)?.icon ??
                                      Icons.directions_run_rounded,
                                  size: 17,
                                  color: AppColors.ink2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.kind,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$dayLabel · $range · ${entry.intensity}'
                                      '$count$distance',
                                      maxLines: 2,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${entry.minutes} 分钟',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.kcal} 千卡',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.green2,
                                    ),
                                  ),
                                ],
                              ),
                              IconPill(
                                icon: Icons.delete_outline_rounded,
                                size: 26,
                                background: Colors.transparent,
                                color: const Color(0xFFA8ADA7),
                                onTap: () => state.removeExercise(entry.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mini(IconData icon, String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w400,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRingPainter extends CustomPainter {
  final double progress;
  _StepRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const segments = 28;
    final step = math.pi * 2 / segments;
    final activeCount = (progress * segments).ceil();
    final activePaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.accent, Color(0xFFA9D95E)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final idlePaint = Paint()
      ..color = const Color(0xFFEFF2EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < segments; i++) {
      final start = -math.pi / 2 + step * i + .035;
      final sweep = step - .07;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        i < activeCount ? activePaint : idlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StepRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BodyTrendCard extends StatelessWidget {
  final List<HealthDay> week;
  final VoidCallback onOpen;

  const _BodyTrendCard({required this.week, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];
    final labels = week
        .map((day) => weekdayLabels[day.date.weekday - 1])
        .toList();
    final steps = week.map((day) => day.steps.toDouble()).toList();
    String iso(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final bodyByDate = {
      for (final point in state.bodyPoints) point.date: point,
    };
    final weight = <double>[];
    final fat = <double>[];
    var lastWeight = 0.0;
    var lastFat = 0.0;
    for (final day in week) {
      final point = bodyByDate[iso(day.date)];
      if (point?.weightKg != null) lastWeight = point!.weightKg!;
      if (point?.bodyFat != null) lastFat = point!.bodyFat!;
      weight.add(lastWeight);
      fat.add(lastFat);
    }
    final series = <ChartSeries>[
      if (steps.any((value) => value > 0))
        ChartSeries(values: steps, color: const Color(0xFF9CCC5A), fill: true),
      if (weight.any((value) => value > 0))
        ChartSeries(values: weight, color: const Color(0xFF7FA0AC)),
      if (fat.any((value) => value > 0))
        ChartSeries(values: fat, color: const Color(0xFFD98D7E)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('身体趋势', style: titleStyle(size: 18)),
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
            height: 160,
            highlightIndex: labels.length - 1,
            highlightLabel: steps.last > 0
                ? '${formatNumber(steps.last)} 步'
                : null,
          ),
          if (series.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (steps.any((value) => value > 0))
                  Expanded(
                    child: _TrendLegend(
                      color: const Color(0xFF9CCC5A),
                      label: '步数',
                      value: formatNumber(steps.last),
                    ),
                  ),
                if (weight.any((value) => value > 0))
                  Expanded(
                    child: _TrendLegend(
                      color: const Color(0xFF7FA0AC),
                      label: '体重',
                      value: '${weight.last.toStringAsFixed(1)}kg',
                    ),
                  ),
                if (fat.any((value) => value > 0))
                  Expanded(
                    child: _TrendLegend(
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

class _TrendLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _TrendLegend({
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
