import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import '../data/demo_data.dart';
import '../models.dart';
import '../services/llm_service.dart';
import '../services/media_permission.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  bool fullHeight = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x8014241A),
    builder: (context) {
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(context).height * (fullHeight ? .94 : .88),
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDD3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      );
    },
  );
}

class SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SheetHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.green2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle(size: 21)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          IconPill(
            icon: Icons.close_rounded,
            background: const Color(0xFFF1EEE4),
            color: AppColors.ink2,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

const mealKinds = ['早餐', '午餐', '晚餐', '加餐'];

class MealKindChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool dark;
  final double height;

  const MealKindChips({
    super.key,
    required this.value,
    required this.onChanged,
    this.dark = false,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: mealKinds.map((kind) {
        final active = value == kind;
        return Expanded(
          child: Pressable(
            onTap: () => onChanged(kind),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: height,
              margin: EdgeInsets.only(right: kind == mealKinds.last ? 0 : 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? (dark ? AppColors.ink : AppColors.green)
                    : const Color(0xFFF5F6F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                kind,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? (dark ? Colors.white : AppColors.cream)
                      : AppColors.ink2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String formatClock(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? parseClock(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String addMinutesToClock(String start, int minutes) {
  final parsed = parseClock(start);
  if (parsed == null) return '';
  final total = (parsed.hour * 60 + parsed.minute + minutes) % (24 * 60);
  final hour = (total ~/ 60).toString().padLeft(2, '0');
  final minute = (total % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<String?> pickMealTime(BuildContext context, String current) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: parseClock(current) ?? TimeOfDay.now(),
    helpText: '选择用餐时间',
    confirmText: '确定',
    cancelText: '取消',
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
  return picked == null ? null : formatClock(picked);
}

class MealTimeButton extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const MealTimeButton({super.key, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 13,
              color: AppColors.green2,
            ),
            const SizedBox(width: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 12, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _FoodOption {
  final String name;
  final String hint;
  final String emoji;
  final String source;
  final String image;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  const _FoodOption({
    required this.name,
    required this.hint,
    required this.emoji,
    required this.source,
    required this.image,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class AddFoodSheet extends StatefulWidget {
  final String initialKind;

  const AddFoodSheet({super.key, this.initialKind = '加餐'});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  late String _kind = widget.initialKind;
  late final List<_FoodOption> _foods = _buildFoods();
  String? _selectedName;
  int _portion = 1;
  String _time = '';
  final _query = TextEditingController();

  static List<_FoodOption> _buildFoods() {
    final byName = <String, _FoodOption>{};
    for (final food in quickFoods) {
      byName.putIfAbsent(
        food.name,
        () => _FoodOption(
          name: food.name,
          hint: food.hint,
          emoji: food.emoji,
          source: '常用食材',
          image: 'assets/images/food-4.jpg',
          kcal: food.kcal,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
        ),
      );
    }
    for (final dish in dishPool) {
      byName.putIfAbsent(
        dish.title,
        () => _FoodOption(
          name: dish.title,
          hint: dish.description,
          emoji: dish.kind.substring(0, 1),
          source: '菜品',
          image: dish.image,
          kcal: dish.kcal,
          protein: dish.protein,
          carbs: dish.carbs,
          fat: dish.fat,
        ),
      );
    }
    return byName.values.toList();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final keyword = _query.text.trim();
    final usage = state.dishUsageCounts;
    final foods = _foods
        .where(
          (food) =>
              keyword.isEmpty ||
              food.name.contains(keyword) ||
              food.hint.contains(keyword),
        )
        .toList();
    foods.sort((a, b) {
      final byUsage = (usage[b.name] ?? 0).compareTo(usage[a.name] ?? 0);
      if (byUsage != 0) return byUsage;
      final bySource = (a.source == '常用食材' ? 0 : 1).compareTo(
        b.source == '常用食材' ? 0 : 1,
      );
      if (bySource != 0) return bySource;
      return _foods.indexOf(a).compareTo(_foods.indexOf(b));
    });
    final selected = foods.isEmpty
        ? null
        : foods.firstWhere(
            (food) => food.name == _selectedName,
            orElse: () => foods.first,
          );
    final kcal = ((selected?.kcal ?? 0) * _portion).round();
    final time = _time.isEmpty ? state.currentTime : _time;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeader(
          icon: Icons.search_rounded,
          title: '搜索记录',
          subtitle: '搜食材或菜品，选份量和用餐时间后记录。',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() => _selectedName = null),
            decoration: const InputDecoration(
              hintText: '搜索食物，例如：鸡胸肉、牛肉面',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: foods.isEmpty
              ? const Center(
                  child: Text(
                    '没有找到，换个关键词试试',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  itemCount: foods.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    final active = selected?.name == food.name;
                    return Pressable(
                      onTap: () => setState(() => _selectedName = food.name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFEEF3E9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? const Color(0xFFD8E2D0)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFF0DCCF)
                                    : const Color(0xFFF0EFE7),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                food.emoji,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          food.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        food.source,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Color(0xFF9AA399),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    food.hint,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${food.kcal} 千卡',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.ink2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.green
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: active
                                      ? AppColors.green
                                      : const Color(0xFFD5D9CF),
                                ),
                              ),
                              child: active
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: AppColors.cream,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.lineSoft)),
            color: AppColors.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    '记录到',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  MealTimeButton(
                    time: time,
                    onTap: () async {
                      final next = await pickMealTime(context, time);
                      if (next != null && mounted) {
                        setState(() => _time = next);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MealKindChips(
                value: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '份量',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _Stepper(
                    value: _portion,
                    onMinus: () =>
                        setState(() => _portion = (_portion - 1).clamp(1, 9)),
                    onPlus: () =>
                        setState(() => _portion = (_portion + 1).clamp(1, 9)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PillButton(
                label: selected == null
                    ? '先选择一种食物'
                    : '记到$_kind · ${selected.name} · $kcal 千卡',
                icon: Icons.check_rounded,
                expand: true,
                height: 46,
                onPressed: selected == null
                    ? null
                    : () {
                        state.addMeal(
                          state.selectedDay,
                          AddedMeal(
                            title: selected.name,
                            kind: _kind,
                            time: _time.isEmpty ? state.currentTime : _time,
                            kcal: kcal,
                            protein: (selected.protein * _portion).round(),
                            carbs: (selected.carbs * _portion).round(),
                            fat: (selected.fat * _portion).round(),
                            image: selected.image,
                          ),
                        );
                        Navigator.of(context)
                            .pop('已记录「${selected.name}」到$_kind');
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _Stepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _step(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          _step(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _step(IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 32,
        child: Icon(icon, size: 14, color: AppColors.ink2),
      ),
    );
  }
}

class DishLibrarySheet extends StatefulWidget {
  final String initialKind;

  const DishLibrarySheet({super.key, this.initialKind = '加餐'});

  @override
  State<DishLibrarySheet> createState() => _DishLibrarySheetState();
}

class _DishLibrarySheetState extends State<DishLibrarySheet> {
  late String _kind;
  final Set<String> _selectedTitles = {};
  int _portion = 1;
  String _time = '';
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final keyword = _query.text.trim();
    final usage = state.dishUsageCounts;
    final dishes = dishPool
        .where(
          (dish) =>
              keyword.isEmpty ||
              dish.title.contains(keyword) ||
              dish.description.contains(keyword),
        )
        .toList();
    dishes.sort((a, b) {
      final byUsage = (usage[b.title] ?? 0).compareTo(usage[a.title] ?? 0);
      if (byUsage != 0) return byUsage;
      final byCommon = (isCommonDish(b.title) ? 1 : 0).compareTo(
        isCommonDish(a.title) ? 1 : 0,
      );
      if (byCommon != 0) return byCommon;
      return dishPool.indexOf(a).compareTo(dishPool.indexOf(b));
    });
    final selected = dishPool
        .where((dish) => _selectedTitles.contains(dish.title))
        .toList();
    final kcal =
        selected.fold<int>(0, (sum, dish) => sum + dish.kcal) * _portion;
    final time = _time.isEmpty ? state.currentTime : _time;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetHeader(
          icon: Icons.menu_book_outlined,
          title: '菜品库',
          subtitle: '全部菜品通用，可多选后一起记到某一餐。',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '搜索全部菜品',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dishes.isEmpty
              ? const Center(
                  child: Text(
                    '没有匹配的菜品，换个关键词试试',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                  itemCount: dishes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    final active = _selectedTitles.contains(dish.title);
                    return Pressable(
                      onTap: () => setState(() {
                        if (!_selectedTitles.remove(dish.title)) {
                          _selectedTitles.add(dish.title);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFF3F8EC)
                              : const Color(0xFFF8F9F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active
                                ? const Color(0xFFC9DABF)
                                : AppColors.lineSoft,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                dish.image,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dish.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      if ((usage[dish.title] ?? 0) > 0 ||
                                          isCommonDish(dish.title)) ...[
                                        const SizedBox(width: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (usage[dish.title] ?? 0) > 0
                                                ? const Color(0xFFEEF4E4)
                                                : const Color(0xFFF3F1EA),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                          child: Text(
                                            (usage[dish.title] ?? 0) > 0
                                                ? '常吃 ×${usage[dish.title]}'
                                                : '家常',
                                            style: TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  (usage[dish.title] ?? 0) > 0
                                                  ? const Color(0xFF5F7A45)
                                                  : AppColors.muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dish.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dish.kind} · ${dish.kcal} 千卡 · 蛋白 ${dish.protein}g',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.ink2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.green
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: active
                                      ? AppColors.green
                                      : const Color(0xFFD5D9CF),
                                ),
                              ),
                              child: active
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 15,
                                      color: AppColors.cream,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            18,
            10,
            18,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.lineSoft)),
            color: AppColors.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? '已选 0 道'
                          : '已选 ${selected.length} 道 · $kcal 千卡',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink2,
                      ),
                    ),
                  ),
                  MealTimeButton(
                    time: time,
                    onTap: () async {
                      final next = await pickMealTime(context, time);
                      if (next != null && mounted) {
                        setState(() => _time = next);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    '记到',
                    style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                  ),
                  const Spacer(),
                  _Stepper(
                    value: _portion,
                    onMinus: () =>
                        setState(() => _portion = (_portion - 1).clamp(1, 3)),
                    onPlus: () =>
                        setState(() => _portion = (_portion + 1).clamp(1, 3)),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              MealKindChips(
                value: _kind,
                height: 34,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: 9),
              PillButton(
                label: selected.isEmpty
                    ? '请选择菜品'
                    : '记到$_kind · ${selected.length} 道 · $kcal 千卡',
                icon: Icons.check_rounded,
                expand: true,
                height: 46,
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        final addTime = _time.isEmpty
                            ? state.currentTime
                            : _time;
                        for (final dish in selected) {
                          state.addMeal(
                            state.selectedDay,
                            AddedMeal(
                              title: dish.title,
                              kind: _kind,
                              time: addTime,
                              kcal: dish.kcal * _portion,
                              protein: dish.protein * _portion,
                              carbs: dish.carbs * _portion,
                              fat: dish.fat * _portion,
                              image: dish.image,
                            ),
                          );
                        }
                        Navigator.of(context)
                            .pop('已从菜品库记录 ${selected.length} 道到$_kind');
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AiLogSheet extends StatefulWidget {
  final String mode;
  final bool startInPhoto;
  final String initialKind;

  const AiLogSheet({
    super.key,
    this.mode = 'food',
    this.startInPhoto = false,
    this.initialKind = '加餐',
  });

  @override
  State<AiLogSheet> createState() => _AiLogSheetState();
}

class _AiLogSheetState extends State<AiLogSheet> {
  final _controller = TextEditingController();
  final _photoNote = TextEditingController();
  bool _loading = false;
  bool _photoMode = false;
  Uint8List? _photoBytes;
  AddedMeal? _meal;
  List<PhotoFoodEstimate> _photoItems = [];
  final Set<int> _selectedPhotoItems = {};
  List<BodyLog> _bodyLogs = [];
  late String _kind;
  String _time = '';
  String? _error;
  String? _rawResponse;

  bool get _isBody => widget.mode == 'body';
  bool get _hasResult =>
      _meal != null || _bodyLogs.isNotEmpty || _photoItems.isNotEmpty;
  int get _selectedPhotoKcal => _selectedPhotoItems.fold<int>(
    0,
    (sum, index) =>
        sum +
        (index >= 0 && index < _photoItems.length
            ? _photoItems[index].kcal
            : 0),
  );
  String get _primaryLabel {
    if (_photoItems.isNotEmpty) {
      if (_selectedPhotoItems.isEmpty) return '先勾选吃到的食物';
      return '确认写入 ${_selectedPhotoItems.length} 项 · $_selectedPhotoKcal 千卡';
    }
    if (_bodyLogs.isNotEmpty) {
      return _bodyLogs.length == 1 ? '确认写入' : '确认写入 ${_bodyLogs.length} 项';
    }
    return _hasResult ? '确认写入' : (_loading ? '正在解析…' : '解析');
  }

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _photoMode = widget.startInPhoto && !_isBody;
  }

  @override
  void dispose() {
    _controller.dispose();
    _photoNote.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final state = AppScope.of(context);
    if (state.activeProvider == null) {
      showToast(
        context,
        '先在「我的 → AI 引擎」里添加模型提供商',
        icon: Icons.link_off_rounded,
      );
      return;
    }
    if (_photoMode && _photoBytes == null) {
      showToast(context, '先拍一张餐盘照片', icon: Icons.photo_camera_outlined);
      return;
    }
    if (!_photoMode && _controller.text.trim().isEmpty) {
      showToast(context, '先说说你吃了什么', icon: Icons.edit_note_rounded);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rawResponse = null;
      _meal = null;
      _photoItems = [];
      _selectedPhotoItems.clear();
      _bodyLogs = [];
    });
    try {
      if (_isBody) {
        final logs = await state.analyzeBodyText(_controller.text.trim());
        if (!mounted) return;
        setState(() {
          if (logs == null || logs.isEmpty) {
            _error = '没能从这句话里解析出体重或运动，换个说法再试一次。';
          } else {
            _bodyLogs = logs;
          }
        });
      } else if (_photoMode) {
        final items = await state.analyzeFoodPhoto(
          _photoBytes!,
          kind: _kind,
          note: _photoNote.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          if (items == null || items.isEmpty) {
            _error = '模型没有返回可用的营养结构，换一张更清晰的餐盘照再试。';
          } else {
            _photoItems = items;
            _selectedPhotoItems.clear();
            if (items.length <= 3) {
              _selectedPhotoItems.addAll(
                List<int>.generate(items.length, (index) => index),
              );
            }
          }
        });
      } else {
        final meal = await state.analyzeFoodText(
          _controller.text.trim(),
          kind: _kind,
        );
        if (!mounted) return;
        setState(() {
          if (meal == null) {
            _error = '模型没有返回可用的营养结构，补充一下分量再试。';
          } else {
            _meal = meal;
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (error is LlmResponseException) {
          _error = error.message;
          _rawResponse = error.rawBody;
        } else {
          _error = '$error'.replaceFirst('Exception: ', '');
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto({bool gallery = false}) async {
    final allowed = await ensureMediaAccess(
      gallery ? MediaAccessKind.gallery : MediaAccessKind.camera,
    );
    if (!allowed) {
      if (mounted) {
        await showMediaPermissionPrompt(
          context,
          kind: gallery ? MediaAccessKind.gallery : MediaAccessKind.camera,
        );
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final file = await ImagePicker().pickImage(
        source: gallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _meal = null;
        _photoItems = [];
        _selectedPhotoItems.clear();
        _error = null;
        _rawResponse = null;
      });
    } catch (error) {
      if (mounted)
        showToast(
          context,
          gallery ? '无法打开相册：$error' : '无法打开相机：$error',
          icon: Icons.error_outline_rounded,
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showRawResponse() async {
    final raw = _rawResponse?.trim();
    if (raw == null || raw.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('模型原始返回'),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: SelectableText(
                raw,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.55,
                  color: AppColors.ink2,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: raw));
              if (mounted) {
                showToast(context, '已复制模型原始返回');
              }
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final state = AppScope.of(context);
    final day = state.selectedDay;
    if (_bodyLogs.isNotEmpty) {
      var exerciseCount = 0;
      double? weight;
      for (var index = 0; index < _bodyLogs.length; index++) {
        final log = _bodyLogs[index];
        if (log.isWeight) {
          final kg = log.kg;
          if (kg == null) continue;
          state.addWeight(WeightEntry(state.todayIso, kg));
          weight = kg;
          continue;
        }
        final minutes = log.minutes ?? 0;
        if (minutes <= 0) continue;
        final type = state.typeFor(log.kind ?? '');
        final kcal =
            type?.kcalFor(
              minutes: minutes,
              intensity: '适中',
              weightKg: state.currentWeightKg,
            ) ??
            0;
        state.addExercise(
          ExerciseEntry(
            id: 'ai-${DateTime.now().microsecondsSinceEpoch}-$index',
            date: state.todayIso,
            kind: log.kind ?? '运动',
            minutes: minutes,
            intensity: '中等',
            kcal: kcal,
            startTime: log.startTime ?? state.currentTime,
          ),
        );
        exerciseCount++;
      }
      final parts = <String>[
        if (weight != null) '体重 ${weight.toStringAsFixed(1)}kg',
        if (exerciseCount > 0) '$exerciseCount 项运动',
      ];
      Navigator.of(context)
          .pop(parts.isEmpty ? '没有可写入的记录' : '已记录${parts.join(' 和 ')}');
      return;
    }
    if (_photoItems.isNotEmpty) {
      final selected =
          _selectedPhotoItems
              .where((index) => index >= 0 && index < _photoItems.length)
              .toList()
            ..sort();
      if (selected.isEmpty) {
        showToast(context, '先勾选你实际吃到的食物', icon: Icons.checklist_rounded);
        return;
      }
      final time = _time.isEmpty ? state.currentTime : _time;
      var kcal = 0;
      for (final index in selected) {
        final item = _photoItems[index];
        kcal += item.kcal;
        state.addMeal(day, item.toAddedMeal(kind: _kind, time: time));
      }
      Navigator.of(context).pop('已记录 ${selected.length} 项 · $kcal 千卡');
      return;
    }
    final meal = _meal;
    if (meal == null) return;
    state.addMeal(
      day,
      AddedMeal(
        title: meal.title,
        kind: _kind,
        time: _time.isEmpty ? state.currentTime : _time,
        kcal: meal.kcal,
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat,
      ),
    );
    Navigator.of(context).pop('已记录「${meal.title}」· ${meal.kcal} 千卡');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final provider = state.activeProvider;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.auto_awesome_rounded,
            title: _isBody ? 'AI 记身体数据' : 'AI 记饮食',
            subtitle: _isBody
                ? '一句话可以包含多项运动和体重，解析后先确认。'
                : '说一句话或拍张照，识别结果先确认，再入库。',
          ),
          if (!_isBody)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECEEE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _modeTab(
                      '说一句话',
                      Icons.auto_awesome_rounded,
                      !_photoMode,
                      () => setState(() => _photoMode = false),
                    ),
                    _modeTab(
                      '拍餐盘',
                      Icons.photo_camera_outlined,
                      _photoMode,
                      () => setState(() => _photoMode = true),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _photoMode
                  ? _photoBytes == null
                        ? Container(
                            key: const ValueKey('photo'),
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _loading
                                      ? Icons.hourglass_top_rounded
                                      : Icons.add_a_photo_outlined,
                                  size: 26,
                                  color: AppColors.green2,
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  _loading ? '正在打开…' : '拍一张，或从相册选择',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _photoSourceButton(
                                      label: '拍照',
                                      icon: Icons.photo_camera_outlined,
                                      onTap: _loading
                                          ? null
                                          : () => _pickPhoto(),
                                    ),
                                    const SizedBox(width: 8),
                                    _photoSourceButton(
                                      label: '从相册选择',
                                      icon: Icons.photo_library_outlined,
                                      onTap: _loading
                                          ? null
                                          : () => _pickPhoto(gallery: true),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                const Text(
                                  '照片会直接发给你选择的模型',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF9AA399),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            key: const ValueKey('photo-preview'),
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Image.memory(
                                  _photoBytes!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconPill(
                                    icon: Icons.close_rounded,
                                    size: 30,
                                    background: const Color(0xE6FFFFFF),
                                    onTap: () => setState(() {
                                      _photoBytes = null;
                                      _meal = null;
                                      _photoItems = [];
                                      _selectedPhotoItems.clear();
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          )
                  : TextField(
                      key: const ValueKey('text'),
                      controller: _controller,
                      minLines: 4,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: _isBody
                            ? '例如：早上跑步 30 分钟，晚上做了 20 分钟力量训练，体重 66.6kg'
                            : '例如：中午吃了碗牛肉面，还喝了杯无糖拿铁',
                        alignLabelWithHint: true,
                      ),
                    ),
            ),
          ),
          if (!_isBody && _photoMode) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _photoNote,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '可选补充：我吃了牛肉、宽粉和半碗米饭',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 19),
                ),
              ),
            ),
          ],
          if (_isBody) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7ED),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: AppColors.green2,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '计算依据：${state.bodyProfileSummary}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF56705B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (provider == null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEFE6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_off_rounded,
                      size: 15,
                      color: Color(0xFFA6553F),
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text(
                        '还没有配置模型。前往「我的 → AI 引擎」添加提供商和 API Key。',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8A4A36),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEDE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A4A36),
                        height: 1.55,
                      ),
                    ),
                    if (_rawResponse != null &&
                        _rawResponse!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Pressable(
                        onTap: _showRawResponse,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0xFFF0D8CF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.code_rounded,
                                    size: 12,
                                    color: Color(0xFF9B5B49),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '模型原始返回',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9B5B49),
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    '点击查看完整内容',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFFB58A7E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _rawResponse!.trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  height: 1.5,
                                  color: Color(0xFF7E625A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_hasResult) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAE7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE1EDCA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AI 估算 · 待确认',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .5,
                            color: Color(0xFF6C8A4F),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          provider == null ? '' : (state.activeModel ?? ''),
                          style: const TextStyle(
                            fontSize: 8.5,
                            color: Color(0xFF93A184),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (_photoItems.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '识别到 ${_photoItems.length} 项',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '已选 ${_selectedPhotoItems.length} 项 · $_selectedPhotoKcal 千卡',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF6C8A4F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 196),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _photoItems.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 5),
                          itemBuilder: (context, index) {
                            final item = _photoItems[index];
                            final active = _selectedPhotoItems.contains(index);
                            return Pressable(
                              onTap: () => setState(() {
                                if (!_selectedPhotoItems.remove(index)) {
                                  _selectedPhotoItems.add(index);
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: .45),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? const Color(0xFFC9DABF)
                                        : const Color(0xFFE4EDD6),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? AppColors.green
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: active
                                              ? AppColors.green
                                              : const Color(0xFFBFCDB4),
                                        ),
                                      ),
                                      child: active
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: AppColors.cream,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          if (item.portion.trim().isNotEmpty)
                                            Text(
                                              item.portion,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 8.5,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${item.kcal} 千卡',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        color: AppColors.ink2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 9),
                      MealKindChips(
                        value: _kind,
                        height: 32,
                        dark: true,
                        onChanged: (kind) => setState(() => _kind = kind),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Text(
                            '用餐时间',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                            ),
                          ),
                          const Spacer(),
                          MealTimeButton(
                            time: _time.isEmpty ? state.currentTime : _time,
                            onTap: () async {
                              final current = _time.isEmpty
                                  ? state.currentTime
                                  : _time;
                              final next = await pickMealTime(context, current);
                              if (next != null && mounted) {
                                setState(() => _time = next);
                              }
                            },
                          ),
                        ],
                      ),
                    ] else if (_bodyLogs.isNotEmpty) ...[
                      Text(
                        '识别到 ${_bodyLogs.length} 项记录',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._bodyLogs.map((log) {
                        final type = state.typeFor(log.kind ?? '');
                        final kcal = log.isWeight
                            ? 0
                            : type?.kcalFor(
                                    minutes: log.minutes ?? 0,
                                    intensity: '适中',
                                    weightKg: state.currentWeightKg,
                                  ) ??
                                  0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4EDD6)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                log.isWeight
                                    ? Icons.monitor_weight_outlined
                                    : Icons.directions_run_rounded,
                                size: 16,
                                color: AppColors.green2,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  log.isWeight
                                      ? log.summary
                                      : [
                                          log.kind ?? '运动',
                                          if (log.startTime != null)
                                            '${log.startTime} – ${addMinutesToClock(log.startTime!, log.minutes ?? 0)}',
                                          '${log.minutes ?? 0} 分钟',
                                        ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (!log.isWeight) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '约 $kcal 千卡',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Text(
                        _meal?.title ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (_meal != null) ...[
                        Row(
                          children: [
                            _macroChip('热量', '${_meal!.kcal} kcal'),
                            const SizedBox(width: 5),
                            _macroChip('蛋白', '${_meal!.protein} g'),
                            const SizedBox(width: 5),
                            _macroChip('碳水', '${_meal!.carbs} g'),
                            const SizedBox(width: 5),
                            _macroChip('脂肪', '${_meal!.fat} g'),
                          ],
                        ),
                        const SizedBox(height: 9),
                        MealKindChips(
                          value: _kind,
                          height: 32,
                          dark: true,
                          onChanged: (kind) => setState(() => _kind = kind),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Text(
                              '用餐时间',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppColors.muted,
                              ),
                            ),
                            const Spacer(),
                            MealTimeButton(
                              time: _time.isEmpty ? state.currentTime : _time,
                              onTap: () async {
                                final current = _time.isEmpty
                                    ? state.currentTime
                                    : _time;
                                final next = await pickMealTime(
                                  context,
                                  current,
                                );
                                if (next != null && mounted) {
                                  setState(() => _time = next);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _isBody
                          ? '运动消耗会按 ${state.bodyProfileSummary} 和 MET 重新计算，确认后写入。'
                          : '数值由模型按可见份量估算，可以写入后再到饮食页调整。',
                      style: TextStyle(fontSize: 8.5, color: Color(0xFF93A184)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: '取消',
                    tone: PillTone.outline,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: PillButton(
                    label: _primaryLabel,
                    icon: _hasResult
                        ? Icons.check_rounded
                        : (_loading
                              ? Icons.hourglass_top_rounded
                              : Icons.auto_awesome_rounded),
                    expand: true,
                    onPressed: _loading ? null : (_hasResult ? _save : _parse),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSourceButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.green2),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.green2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14283C2D),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? AppColors.green : AppColors.muted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.green : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MealAddMethod { search, library, photo, text }

class MealAddRequest {
  final MealAddMethod method;
  final String kind;

  const MealAddRequest({required this.method, required this.kind});
}

/// 统一的三餐添加入口：先确认餐次和记录方式，再打开对应面板。
Future<void> openMealLogger(
  BuildContext context, {
  required AppState state,
  String kind = '加餐',
  MealAddMethod? method,
}) async {
  var targetKind = kind;
  var targetMethod = method;
  if (targetMethod == null) {
    final request = await showAppSheet<MealAddRequest>(
      context,
      child: AddMealMethodSheet(initialKind: kind),
    );
    if (request == null || !context.mounted) return;
    targetKind = request.kind;
    targetMethod = request.method;
  }
  if (!context.mounted) return;
  if ((targetMethod == MealAddMethod.photo ||
          targetMethod == MealAddMethod.text) &&
      !state.aiConfigured) {
    showToast(context, '先在「我的 → AI 引擎」里配置模型', icon: Icons.link_off_rounded);
    return;
  }
  String? message;
  if (targetMethod == MealAddMethod.search) {
    message = await showAppSheet<String>(
      context,
      child: AddFoodSheet(initialKind: targetKind),
    );
  } else if (targetMethod == MealAddMethod.library) {
    message = await showAppSheet<String>(
      context,
      child: DishLibrarySheet(initialKind: targetKind),
    );
  } else if (targetMethod == MealAddMethod.photo) {
    message = await showAppSheet<String>(
      context,
      child: AiLogSheet(initialKind: targetKind, startInPhoto: true),
    );
  } else {
    message = await showAppSheet<String>(
      context,
      child: AiLogSheet(initialKind: targetKind),
    );
  }
  if (message != null && context.mounted) showToast(context, message);
}

class AddMealMethodSheet extends StatefulWidget {
  final String initialKind;

  const AddMealMethodSheet({super.key, this.initialKind = '加餐'});

  @override
  State<AddMealMethodSheet> createState() => _AddMealMethodSheetState();
}

class _AddMealMethodSheetState extends State<AddMealMethodSheet> {
  late String _kind;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  void _choose(MealAddMethod method, {bool needsAi = false}) {
    final state = AppScope.of(context);
    if (needsAi && !state.aiConfigured) {
      showToast(context, '先在「我的 → AI 引擎」里配置模型', icon: Icons.link_off_rounded);
      return;
    }
    Navigator.of(context).pop(MealAddRequest(method: method, kind: _kind));
  }

  @override
  Widget build(BuildContext context) {
    final aiReady = AppScope.of(context).aiConfigured;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            icon: Icons.add_rounded,
            title: '记录一餐',
            subtitle: '搜索、菜品库、拍照或一句话，记到对应餐次。',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
            child: Row(
              children: [
                const Text(
                  '记录到',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  aiReady ? 'AI 已就绪' : 'AI 未配置',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: aiReady
                        ? const Color(0xFF6C8A4F)
                        : const Color(0xFFA6553F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: MealKindChips(
              value: _kind,
              height: 38,
              onChanged: (kind) => setState(() => _kind = kind),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _AddMethodCard(
                  icon: Icons.search_rounded,
                  title: '搜索食物',
                  subtitle: '按名称搜食材或菜品，可调份量',
                  badge: '离线可用',
                  onTap: () => _choose(MealAddMethod.search),
                ),
                const SizedBox(height: 8),
                _AddMethodCard(
                  icon: Icons.menu_book_outlined,
                  title: '从菜品库添加',
                  subtitle: '浏览内置菜品，看图挑选',
                  badge: '离线可用',
                  onTap: () => _choose(MealAddMethod.library),
                ),
                const SizedBox(height: 8),
                _AddMethodCard(
                  icon: Icons.photo_camera_outlined,
                  title: '拍照识别',
                  subtitle: '拍餐盘，AI 估算整餐热量',
                  badge: aiReady ? 'AI 估算' : '需配置',
                  enabled: aiReady,
                  onTap: () => _choose(MealAddMethod.photo, needsAi: true),
                ),
                const SizedBox(height: 8),
                _AddMethodCard(
                  icon: Icons.auto_awesome_rounded,
                  title: '一句话记录',
                  subtitle: '例如「中午吃了牛肉面和拿铁」',
                  badge: aiReady ? 'AI 估算' : '需配置',
                  enabled: aiReady,
                  onTap: () => _choose(MealAddMethod.text, needsAi: true),
                ),
              ],
            ),
          ),
          if (!aiReady) ...[
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '拍照和一句话记录需要先接入模型；搜索食物不受影响。',
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final bool enabled;
  final VoidCallback onTap;

  const _AddMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: cardDecoration(radius: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFE9F0E2)
                    : const Color(0xFFF1EEE7),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 19,
                color: enabled ? AppColors.green2 : AppColors.muted,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF1F6E6)
                    : const Color(0xFFFAEFE6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? const Color(0xFF6C8A4F)
                      : const Color(0xFFA6553F),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: enabled ? AppColors.green2 : const Color(0xFFB9BEB5),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeDetailSheet extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailSheet({super.key, required this.recipe});

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  double _portion = 1;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final recipe = widget.recipe;
    final saved = state.favorites.contains(recipe.id);
    return DraggableScrollableSheet(
      initialChildSize: .92,
      minChildSize: .6,
      maxChildSize: .96,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDD3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: 'recipe-${recipe.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.asset(
                              recipe.image,
                              height: 210,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconPill(
                            icon: Icons.close_rounded,
                            background: const Color(0xE6FFFFFF),
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SoftTag(recipe.category),
                          const SizedBox(height: 9),
                          Text(recipe.title, style: displayStyle(size: 24)),
                          const SizedBox(height: 6),
                          Text(
                            recipe.summary,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _meta(
                                Icons.schedule_rounded,
                                '${recipe.minutes} 分钟',
                              ),
                              const SizedBox(width: 14),
                              _meta(
                                Icons.local_fire_department_outlined,
                                '${recipe.kcal} 千卡',
                              ),
                              const SizedBox(width: 14),
                              _meta(
                                Icons.signal_cellular_alt_rounded,
                                recipe.level,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F2),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              children: [
                                _macro(
                                  '${(recipe.protein * _portion).round()}g',
                                  '蛋白质',
                                ),
                                _macro(
                                  '${(recipe.carbs * _portion).round()}g',
                                  '碳水',
                                ),
                                _macro(
                                  '${(recipe.fat * _portion).round()}g',
                                  '脂肪',
                                ),
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<double>(
                                      value: _portion,
                                      isDense: true,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.ink,
                                      ),
                                      items: const [.5, 1.0, 1.5, 2.0]
                                          .map(
                                            (value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(
                                                '${value.toStringAsFixed(value == 1 ? 0 : 1)} 份',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          setState(() => _portion = value ?? 1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('食材', style: titleStyle(size: 15)),
                          const SizedBox(height: 4),
                          ...recipe.ingredients.map(
                            (item) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.lineSoft),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.ink2,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.amount,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('做法', style: titleStyle(size: 15)),
                          const SizedBox(height: 8),
                          ...recipe.steps.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 21,
                                    height: 21,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE6EEE0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        color: AppColors.green2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.ink2,
                                        height: 1.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF6F8A72),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    recipe.tip,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF526555),
                                      height: 1.65,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: PillButton(
                                  label: saved ? '已收藏' : '收藏',
                                  icon: saved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  tone: PillTone.outline,
                                  expand: true,
                                  onPressed: () {
                                    state.toggleFavorite(recipe.id);
                                    showToast(
                                      context,
                                      saved ? '已取消收藏' : '已收藏「${recipe.title}」',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: PillButton(
                                  label: '加入今日菜单',
                                  icon: Icons.add_rounded,
                                  expand: true,
                                  onPressed: () {
                                    final kind = state.defaultMealKind;
                                    state.addMeal(
                                      state.selectedDay,
                                      AddedMeal(
                                        title: recipe.title,
                                        kind: kind,
                                        time: state.currentTime,
                                        kcal: (recipe.kcal * _portion).round(),
                                        protein: (recipe.protein * _portion)
                                            .round(),
                                        carbs: (recipe.carbs * _portion)
                                            .round(),
                                        fat: (recipe.fat * _portion).round(),
                                        image: recipe.image,
                                      ),
                                    );
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    Navigator.of(context).pop();
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('已加入今日菜单')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _macro(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class SwapSheet extends StatelessWidget {
  final String kind;
  final String current;
  const SwapSheet({super.key, required this.kind, required this.current});

  @override
  Widget build(BuildContext context) {
    final options = swapPool
        .where((meal) => meal.kind == kind && meal.title != current)
        .take(4)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.swap_horiz_rounded,
            title: '换一个$kind',
            subtitle: '按热量和蛋白质挑了几个接近的选择。',
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final meal = options[index];
                return Pressable(
                  onTap: () => Navigator.of(context).pop(meal.title),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9F5),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.lineSoft),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            meal.image,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${meal.kcal} 千卡 · 蛋白质 ${meal.protein}g',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9AA69A),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingListSheet extends StatefulWidget {
  const ShoppingListSheet({super.key});

  @override
  State<ShoppingListSheet> createState() => _ShoppingListSheetState();
}

class _ShoppingListSheetState extends State<ShoppingListSheet> {
  final Set<int> _checked = {};

  @override
  Widget build(BuildContext context) {
    final items = AppScope.of(context).shoppingForWeek();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            icon: Icons.shopping_basket_outlined,
            title: '本周采购清单',
            subtitle: '来自本周 ${items.length} 项食材的去重合并，按品类整理。',
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final checked = _checked.contains(index);
                return Pressable(
                  onTap: () => setState(
                    () =>
                        checked ? _checked.remove(index) : _checked.add(index),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.lineSoft),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: checked
                                ? AppColors.green
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: checked
                                  ? AppColors.green
                                  : const Color(0xFFD5D9CF),
                            ),
                          ),
                          child: checked
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: AppColors.cream,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: checked ? AppColors.muted : AppColors.ink,
                              decoration: checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          item.amount,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SoftTag(
                          item.category,
                          background: const Color(0xFFF2F3EC),
                          color: const Color(0xFF718078),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              10 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已勾选 ${_checked.length} / ${items.length}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                PillButton(
                  label: '复制清单',
                  icon: Icons.copy_rounded,
                  onPressed: () {
                    final text = items
                        .map(
                          (item) =>
                              '${item.category}｜${item.name} ${item.amount}',
                        )
                        .join('\n');
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(context).pop();
                    Clipboard.setData(ClipboardData(text: text));
                    messenger.showSnackBar(
                      const SnackBar(content: Text('采购清单已复制')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BodyRecordSheet extends StatefulWidget {
  const BodyRecordSheet({super.key});

  @override
  State<BodyRecordSheet> createState() => _BodyRecordSheetState();
}

class _BodyRecordSheetState extends State<BodyRecordSheet> {
  final _weight = TextEditingController();
  final _fat = TextEditingController();
  final _waist = TextEditingController();
  final _height = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = AppScope.of(context);
    final points = state.bodyPoints;
    for (final point in points.reversed) {
      if (point.weightKg != null) {
        _weight.text = point.weightKg!.toStringAsFixed(1);
        break;
      }
    }
    for (final point in points.reversed) {
      if (point.bodyFat != null) {
        _fat.text = point.bodyFat!.toStringAsFixed(1);
        break;
      }
    }
    if (state.measures.isNotEmpty) {
      _waist.text = state.measures.last.waist.toStringAsFixed(1);
    }
    _height.text = state.heightCm.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _weight.dispose();
    _fat.dispose();
    _waist.dispose();
    _height.dispose();
    super.dispose();
  }

  void _save() {
    final state = AppScope.of(context);
    final kg = double.tryParse(_weight.text);
    if (kg == null || kg < 30 || kg > 200) {
      showToast(context, '请输入 30~200 之间的体重', icon: Icons.error_outline_rounded);
      return;
    }
    double? fat;
    if (_fat.text.trim().isNotEmpty) {
      fat = double.tryParse(_fat.text);
      if (fat == null || fat < 3 || fat > 70) {
        showToast(
          context,
          '请输入 3~70 之间的体脂率',
          icon: Icons.error_outline_rounded,
        );
        return;
      }
    }
    double? waist;
    if (_waist.text.trim().isNotEmpty) {
      waist = double.tryParse(_waist.text);
      if (waist == null || waist < 40 || waist > 150) {
        showToast(
          context,
          '请输入 40~150 之间的腰围',
          icon: Icons.error_outline_rounded,
        );
        return;
      }
    }
    final height = double.tryParse(_height.text);
    if (height != null && (height < 120 || height > 220)) {
      showToast(
        context,
        '请输入 120~220 之间的身高',
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    if (height != null) state.updateProfile(heightCm: height);
    state.addWeight(WeightEntry(state.todayIso, kg, bodyFat: fat));
    if (waist != null) state.addMeasure(MeasureEntry(state.todayIso, waist));
    Navigator.of(context).pop(
      fat == null
          ? '已记录体重 ${kg.toStringAsFixed(1)} kg'
          : '已记录体重 ${kg.toStringAsFixed(1)} kg · 体脂 ${fat.toStringAsFixed(1)}%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        const SheetHeader(
          icon: Icons.monitor_weight_outlined,
          title: '记录身体数据',
          subtitle: '体重必填；体脂、腰围和身高可选。不填体脂会按年龄和 BMI 估算。',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BodyField(
                      label: '体重 (kg)',
                      controller: _weight,
                      hint: '57.3',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BodyField(
                      label: '体脂率 (%)',
                      controller: _fat,
                      hint: '22.1',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _BodyField(
                      label: '腰围 (cm)',
                      controller: _waist,
                      hint: '选填',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BodyField(
                      label: '身高 (cm)',
                      controller: _height,
                      hint: '170',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PillButton(
                label: '保存记录',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              const Text(
                '同一天重复记录会覆盖当天数据。',
                style: TextStyle(fontSize: 9.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _BodyField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }
}
