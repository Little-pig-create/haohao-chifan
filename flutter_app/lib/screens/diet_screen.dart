import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/date_strip.dart';
import '../widgets/sheets.dart';
import '../widgets/water_tip.dart';

class DietScreen extends StatelessWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    final added = state.addedFor(day);
    final consumed = state.consumedFor(day);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 108),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(2, 6, 2, 12),
          child: Text(
            '记录每一餐，比只看总热量更容易发现营养缺口。',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.55,
            ),
          ),
        ),
        DateStrip(selected: day, onChanged: state.selectDay),
        const SizedBox(height: 12),
        _DietSummary(
          consumed: consumed,
          goal: state.calorieGoal,
          protein: state.proteinFor(day),
          carbs: state.carbsFor(day),
          fat: state.fatFor(day),
          proteinGoal: state.proteinGoal,
          carbGoal: state.carbGoal,
          fatGoal: state.fatGoal,
        ),
        const SizedBox(height: AppSpacing.gap),
        Row(
          children: [
            Expanded(
              child: _QuickRecord(
                icon: Icons.photo_camera_outlined,
                label: '拍照',
                onTap: () => openMealLogger(
                  context,
                  state: state,
                  kind: state.defaultMealKind,
                  method: MealAddMethod.photo,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickRecord(
                icon: Icons.search_rounded,
                label: '搜索',
                onTap: () => openMealLogger(
                  context,
                  state: state,
                  kind: state.defaultMealKind,
                  method: MealAddMethod.search,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickRecord(
                icon: Icons.menu_book_outlined,
                label: '菜品库',
                onTap: () => openMealLogger(
                  context,
                  state: state,
                  kind: state.defaultMealKind,
                  method: MealAddMethod.library,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickRecord(
                icon: Icons.auto_awesome_rounded,
                label: '说一句',
                onTap: () => openMealLogger(
                  context,
                  state: state,
                  kind: state.defaultMealKind,
                  method: MealAddMethod.text,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap),
        WaterCard(
          glasses: state.waterFor(day),
          goal: state.glassGoal,
          cupMl: state.cupMl,
          targetMl: state.waterTargetMl,
          onSet: (value) => state.setWater(day, value),
          onAdd: () {
            state.addWater(day);
            showToast(context, '已记录一杯水', icon: Icons.water_drop_outlined);
          },
        ),
        const SizedBox(height: AppSpacing.gap),
        SectionTitle(
          title: '三餐记录',
          subtitle: added.isEmpty
              ? '还没有记录，点「记一餐」开始'
              : '已记录 ${formatNumber(consumed)} 千卡 · ${added.length} 项',
          trailing: PillButton(
            label: '记一餐',
            icon: Icons.add_rounded,
            height: 34,
            onPressed: () => openMealLogger(
              context,
              state: state,
              kind: state.defaultMealKind,
            ),
          ),
        ),
        _MealRecords(
          added: added,
          onAdd: (kind) => openMealLogger(context, state: state, kind: kind),
          onRemoveAdded: (item) {
            final index = added.indexOf(item);
            if (index < 0) return;
            state.removeAddedMeal(day, index);
            showToast(context, '已删除「${item.title}」');
          },
          onEditAddedTime: (item) async {
            final index = added.indexOf(item);
            if (index < 0) return;
            final time = await pickMealTime(context, item.time);
            if (time == null || !context.mounted) return;
            state.setAddedMealTime(day, index, time);
            showToast(context, '用餐时间已改为 $time');
          },
        ),
        const SizedBox(height: 12),
        const TipCard(),
      ],
    );
  }
}

class _DietSummary extends StatelessWidget {
  final int consumed;
  final int goal;
  final int protein;
  final int carbs;
  final int fat;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  const _DietSummary({
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (goal - consumed).clamp(0, goal);
    final progress = (consumed / goal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '今日摄入',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              SoftTag(
                '目标 ${formatNumber(goal)}',
                background: AppColors.mint,
                color: const Color(0xFF5B7550),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value: consumed,
                style: const TextStyle(
                  fontSize: 38,
                  height: 1,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '千卡',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '还剩 ${formatNumber(remaining)}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4C6738),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 6,
              color: AppColors.lineSoft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE4FA9A), Color(0xFFC6EC5D)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _macro(
                  '蛋白质',
                  protein,
                  proteinGoal,
                  const Color(0xFFD9A07C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macro('碳水', carbs, carbGoal, const Color(0xFFCDEB7E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _macro('脂肪', fat, fatGoal, const Color(0xFFA9C6D1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, int value, int goal, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '$value g',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '目标 $goal g',
          style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _QuickRecord extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickRecord({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 74,
        decoration: cardDecoration(radius: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.ink2),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
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

class _MealRecords extends StatelessWidget {
  final List<AddedMeal> added;
  final ValueChanged<String> onAdd;
  final ValueChanged<AddedMeal> onRemoveAdded;
  final ValueChanged<AddedMeal> onEditAddedTime;

  const _MealRecords({
    required this.added,
    required this.onAdd,
    required this.onRemoveAdded,
    required this.onEditAddedTime,
  });

  @override
  Widget build(BuildContext context) {
    if (added.isEmpty) return const _NoMealRecords();
    const order = ['早餐', '午餐', '晚餐', '加餐'];
    final kinds = added.map((meal) => meal.kind).toSet().toList()
      ..sort((a, b) {
        final left = order.indexOf(a);
        final right = order.indexOf(b);
        return (left < 0 ? order.length : left).compareTo(
          right < 0 ? order.length : right,
        );
      });
    return Column(
      children: kinds.map((kind) {
        final entries = added.where((meal) => meal.kind == kind).toList();
        return _ExtraMealCard(
          kind: kind,
          entries: entries,
          onAdd: () => onAdd(kind),
          onRemove: onRemoveAdded,
          onEditTime: onEditAddedTime,
        );
      }).toList(),
    );
  }
}

class _NoMealRecords extends StatelessWidget {
  const _NoMealRecords();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 22, color: AppColors.green2),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '还没有任何饮食记录',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '点右上角「记一餐」，添加后才会出现在这里。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddedEntries extends StatelessWidget {
  final List<AddedMeal> entries;
  final ValueChanged<AddedMeal> onRemove;
  final ValueChanged<AddedMeal> onEditTime;

  const _AddedEntries({
    required this.entries,
    required this.onRemove,
    required this.onEditTime,
  });

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<int>(0, (sum, item) => sum + item.kcal);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 8, 5, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lineSoft),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 13,
                color: AppColors.green2,
              ),
              const SizedBox(width: 5),
              Text(
                '本餐已记录 ${entries.length} 项',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF56705B),
                ),
              ),
              const Spacer(),
              Text(
                '$kcal 千卡',
                style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
              const SizedBox(width: 4),
            ],
          ),
          ...entries.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Pressable(
                    onTap: () => onEditTime(item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.edit_outlined,
                            size: 10,
                            color: Color(0xFFA8ADA7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.kcal} 千卡',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.ink2,
                    ),
                  ),
                  IconPill(
                    icon: Icons.close_rounded,
                    size: 24,
                    background: Colors.transparent,
                    color: const Color(0xFFA8ADA7),
                    onTap: () => onRemove(item),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtraMealCard extends StatelessWidget {
  final String kind;
  final List<AddedMeal> entries;
  final VoidCallback onAdd;
  final ValueChanged<AddedMeal> onRemove;
  final ValueChanged<AddedMeal> onEditTime;

  const _ExtraMealCard({
    required this.kind,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    required this.onEditTime,
  });

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<int>(0, (sum, item) => sum + item.kcal);
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EFE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_cafe_outlined,
                  size: 16,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$kind记录', style: titleStyle(size: 13)),
                    Text(
                      '${entries.length} 项 · $kcal 千卡',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('记录'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.green2,
                  textStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 6),
            _AddedEntries(
              entries: entries,
              onRemove: onRemove,
              onEditTime: onEditTime,
            ),
          ],
        ],
      ),
    );
  }
}
