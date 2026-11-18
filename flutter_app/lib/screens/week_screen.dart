import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  bool _generating = false;
  bool _adviceBusy = false;
  String? _advice;

  String _localAdvice(AppState state) {
    final day = state.selectedDay;
    final meals = state.mealsFor(day);
    if (meals.isEmpty) return '这一天还没有排餐，点上面的「一键生成推荐」开始。';
    final kcal = meals.fold<int>(0, (sum, meal) => sum + meal.kcal);
    final protein = meals.fold<int>(0, (sum, meal) => sum + meal.protein);
    final gap = state.proteinGoal - protein;
    final calorieNote = (kcal - state.calorieGoal).abs() <= 120
        ? '合计 $kcal 千卡，和 ${state.calorieGoal} 千卡目标接近。'
        : '合计 $kcal 千卡，比 ${state.calorieGoal} 千卡目标${kcal > state.calorieGoal ? '高' : '低'} ${(kcal - state.calorieGoal).abs()} 千卡。';
    final proteinNote = gap > 0
        ? '蛋白质 $protein g，还差 $gap g，可以在加餐补一份酸奶或鸡蛋。'
        : '蛋白质 $protein g，已经达到 ${state.proteinGoal} g 目标。';
    return '$calorieNote$proteinNote';
  }

  Future<void> _askAdvice() async {
    final state = AppScope.of(context);
    if (state.activeProvider == null) {
      showToast(context, '先在「我的 → AI 引擎」添加模型', icon: Icons.link_off_rounded);
      return;
    }
    setState(() => _adviceBusy = true);
    try {
      final meals = state.mealsFor(state.selectedDay);
      final text = await state.chat([
        {
          'role': 'system',
          'content': '你是营养师。根据这一天的三餐安排给一条 40–70 字的中文建议，只评价给出的数据，不要编造。',
        },
        {
          'role': 'user',
          'content':
              '目标 ${state.calorieGoal} 千卡。三餐：${meals.map((meal) => '${meal.kind}${meal.title}${meal.kcal}千卡/蛋白${meal.protein}g').join('；')}',
        },
      ]);
      if (!mounted) return;
      setState(() => _advice = text);
    } catch (error) {
      if (!mounted) return;
      showToast(
        context,
        '$error'.replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _adviceBusy = false);
    }
  }

  Future<void> _generate() async {
    final state = AppScope.of(context);
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    state.generateWeekPlan();
    setState(() => _generating = false);
    showToast(context, '已从 ${dishPool.length} 道菜中生成整周菜单');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final meals = state.mealsFor(day);
    final totalMeals = weekDays.asMap().keys.fold<int>(
      0,
      (sum, index) => sum + state.mealsFor(index).length,
    );
    final average =
        (weekDays.asMap().keys.fold<int>(
                  0,
                  (sum, index) => sum + state.plannedKcalFor(index),
                ) /
                7)
            .round();
    final proteinDays = weekDays
        .asMap()
        .keys
        .where(
          (index) =>
              state
                  .mealsFor(index)
                  .fold<int>(0, (sum, meal) => sum + meal.protein) >=
              state.proteinGoal,
        )
        .length;
    final varieties = weekDays
        .asMap()
        .keys
        .expand((index) => state.mealsFor(index))
        .map((meal) => meal.title)
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 26),
      children: [
        PageHeader(
          eyebrow:
              '${state.dateForDay(0).month}月${state.dateForDay(0).day}日 — ${state.dateForDay(6).month}月${state.dateForDay(6).day}日',
          title: '每周饮食计划',
          subtitle: '先把一周三餐排好，到点照着做，缺什么一次性采购。',
        ),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: _generating ? '正在生成…' : '一键生成推荐',
                icon: Icons.auto_awesome_rounded,
                tone: PillTone.outline,
                expand: true,
                onPressed: _generating ? null : _generate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: '生成采购清单',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: () =>
                    showAppSheet(context, child: const ShoppingListSheet()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 9) / 2;
            return Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                _SummaryTile(
                  width: width,
                  icon: Icons.calendar_month_outlined,
                  label: '本周计划',
                  value: '$totalMeals',
                  unit: '餐',
                  dark: true,
                ),
                _SummaryTile(
                  width: width,
                  icon: Icons.local_fire_department_outlined,
                  label: '日均热量',
                  value: formatNumber(average),
                  unit: '千卡',
                ),
                _SummaryTile(
                  width: width,
                  icon: Icons.bar_chart_rounded,
                  label: '蛋白质 ≥${state.proteinGoal}g',
                  value: '$proteinDays',
                  unit: '/ 7 天',
                ),
                _SummaryTile(
                  width: width,
                  icon: Icons.eco_outlined,
                  label: '菜品种类',
                  value: '$varieties',
                  unit: '种',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _WeekStrip(selected: day, onChanged: state.selectDay, state: state),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.dateForDay(day).month}月${state.dateForDay(day).day}日 · ${weekDays[day].weekday}${day == todayIndex ? ' · 今天' : ''}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('当日三餐', style: titleStyle(size: 18)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF1E6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '计划 ${formatNumber(state.plannedKcalFor(day))} 千卡',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF56705B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ...meals.asMap().entries.map((entry) {
                final meal = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Pressable(
                    onTap: () async {
                      final title = await showAppSheet<String>(
                        context,
                        child: SwapSheet(kind: meal.kind, current: meal.title),
                      );
                      if (title != null && context.mounted) {
                        state.swapMeal(day, entry.key, title);
                        showToast(context, '已换成「$title」');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lineSoft),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              meal.image,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${meal.kind} · ${meal.time}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meal.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle(size: 13.5),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${meal.kcal} 千卡 · 蛋白质 ${meal.protein}g${state.completedFor(day).contains(entry.key) ? ' · 已完成' : ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconPill(
                            icon: Icons.refresh_rounded,
                            size: 30,
                            onTap: () async {
                              final title = await showAppSheet<String>(
                                context,
                                child: SwapSheet(
                                  kind: meal.kind,
                                  current: meal.title,
                                ),
                              );
                              if (title != null && context.mounted) {
                                state.swapMeal(day, entry.key, title);
                                showToast(context, '已换成「$title」');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: Color(0xFF7D9A78),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '搭配建议',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334B3A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SoftTag(_advice == null ? '本地规则' : 'AI 生成'),
                              const Spacer(),
                              Pressable(
                                onTap: _adviceBusy ? null : _askAdvice,
                                child: _adviceBusy
                                    ? const SizedBox(
                                        width: 13,
                                        height: 13,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Color(0xFF799076),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        size: 13,
                                        color: Color(0xFF799076),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _advice ?? _localAdvice(state),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF526555),
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final bool dark;

  const _SummaryTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
          : cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: dark ? AppColors.accent : const Color(0xFFF2F4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: dark ? AppColors.greenInk : AppColors.green2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                letterSpacing: -.5,
              ),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 9,
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

class _WeekStrip extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final dynamic state;

  const _WeekStrip({
    required this.selected,
    required this.onChanged,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: cardDecoration(),
      child: Row(
        children: List.generate(weekDays.length, (index) {
          final active = selected == index;
          final planned = state.mealsFor(index).length;
          final done = state
              .completedFor(index)
              .where((item) => item < planned)
              .length;
          final status = planned == 0
              ? '待安排'
              : done >= planned
              ? '已完成'
              : '已计划';
          return Expanded(
            child: Pressable(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                height: 57,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: active ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekDays[index].weekday,
                      style: TextStyle(
                        fontSize: 8.5,
                        color: active
                            ? const Color(0xFFC2D2BD)
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      weekDays[index].day,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: active ? const Color(0xFFF8F2DF) : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 7.5,
                        color: active
                            ? const Color(0xFFC2D2BD)
                            : const Color(0xFF9AA597),
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
