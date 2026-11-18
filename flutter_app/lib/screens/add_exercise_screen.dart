import 'package:flutter/material.dart';

import '../data/exercise_catalog.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

void openAddExercisePage(BuildContext context) {
  Navigator.of(context).push(slidePageRoute(const AddExerciseScreen()));
}

enum ExerciseLogMethod { manual, ai }

Future<void> openExerciseQuickLog(BuildContext context) async {
  final method = await showAppSheet<ExerciseLogMethod>(
    context,
    child: const _ExerciseLogMethodSheet(),
  );
  if (method == null || !context.mounted) return;
  if (method == ExerciseLogMethod.manual) {
    openAddExercisePage(context);
    return;
  }
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

class _ExerciseLogMethodSheet extends StatelessWidget {
  const _ExerciseLogMethodSheet();

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
            icon: Icons.directions_run_rounded,
            title: '记录运动',
            subtitle: '手动填写，或让 AI 从一句话里拆出多项运动。',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                _ExerciseMethodTile(
                  icon: Icons.edit_note_rounded,
                  title: '手动记录运动',
                  subtitle: '选择运动、时长、强度与开始时间',
                  badge: '离线可用',
                  onTap: () =>
                      Navigator.of(context).pop(ExerciseLogMethod.manual),
                ),
                const SizedBox(height: 8),
                _ExerciseMethodTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI 速记',
                  subtitle: '例如：早上跑步 30 分钟，晚上力量训练 20 分钟',
                  badge: aiReady ? 'AI 解析' : '需配置',
                  enabled: aiReady,
                  onTap: () {
                    if (!aiReady) {
                      showToast(
                        context,
                        '先在「我的 → AI 引擎」配置模型',
                        icon: Icons.link_off_rounded,
                      );
                      return;
                    }
                    Navigator.of(context).pop(ExerciseLogMethod.ai);
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

class _ExerciseMethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final bool enabled;
  final VoidCallback onTap;

  const _ExerciseMethodTile({
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

Future<void> openExerciseForm(BuildContext context, ExerciseType type) async {
  final state = AppScope.of(context);
  final entry = await showAppSheet<ExerciseEntry>(
    context,
    child: _ExerciseFormSheet(type: type, weightKg: state.currentWeightKg),
  );
  if (entry == null || !context.mounted) return;
  state.addExercise(entry);
  final amount = entry.count != null
      ? '${entry.count} 个（约 ${entry.minutes} 分钟）'
      : '${entry.minutes} 分钟';
  showToast(context, '已记录 ${entry.kind} $amount，约 ${entry.kcal} 千卡');
}

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _search = TextEditingController();
  String _category = '全部';
  bool _frequentFirst = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openForm(ExerciseType type) => openExerciseForm(context, type);

  Future<void> _openCustomForm() async {
    final state = AppScope.of(context);
    final result =
        await showAppSheet<({ExerciseEntry entry, ExerciseType type})>(
          context,
          child: _CustomExerciseSheet(
            weightKg: state.currentWeightKg,
            heightCm: state.heightCm,
          ),
        );
    if (result == null || !mounted) return;
    state.addCustomExercise(result.type);
    state.addExercise(result.entry);
    showToast(
      context,
      '已加入自定义运动，并记录 ${result.entry.kind}，约 ${result.entry.kcal} 千卡',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final types = state.sortedExerciseTypes(frequentFirst: _frequentFirst);
    final query = _search.text.trim().toLowerCase();
    final results = types.where((type) {
      if (_category != '全部' && type.category != _category) return false;
      if (query.isEmpty) return true;
      return type.name.toLowerCase().contains(query) ||
          type.category.contains(query) ||
          type.keywords.any((word) => word.toLowerCase().contains(query));
    }).toList();
    final showRecent = query.isEmpty && _category == '全部';
    final recent = state.frequentExerciseTypes();

    return SubpageFrame(
      title: '添加运动',
      trailing: SoftTag('${types.length} 种运动'),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '搜索运动，如跑步、游泳、瑜伽',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                  isDense: true,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                scrollDirection: Axis.horizontal,
                itemCount: exerciseCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final category = exerciseCategories[index];
                  final active = _category == category;
                  return Pressable(
                    onTap: () => setState(() => _category = category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.ink2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Pressable(
                onTap: _openCustomForm,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: lavenderGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E1F2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Color(0xFF7B6AAE),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '没有找到？让 AI 估算',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '输入运动名称和数量，分析消耗后加入「自定义」分类',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF7B6AAE),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (showRecent)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Row(
                  children: [
                    Text('常用运动', style: titleStyle(size: 16)),
                    const Spacer(),
                    const Text(
                      '按使用次数排序',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          if (showRecent)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final type = recent[index];
                    return Pressable(
                      onTap: () => _openForm(type),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                        decoration: cardDecoration(radius: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(type.icon, size: 18, color: AppColors.green2),
                            const SizedBox(height: 4),
                            Text(
                              type.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    showRecent ? '全部运动' : '$_category · 运动',
                    style: titleStyle(size: 16),
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: () =>
                        setState(() => _frequentFirst = !_frequentFirst),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _frequentFirst
                            ? AppColors.accentSoft
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.swap_vert_rounded,
                            size: 13,
                            color: AppColors.green2,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _frequentFirst ? '常用优先' : '默认排序',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${results.length} 种',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverToBoxAdapter(
                child: EmptyCard(
                  icon: Icons.search_off_rounded,
                  title: '没有找到运动',
                  text: '换个关键词，或点上方「让 AI 估算」加入自定义运动。',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final type = results[index];
                  return Pressable(
                    onTap: () => _openForm(type),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: cardDecoration(radius: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              type.icon,
                              size: 17,
                              color: AppColors.green2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type.isCount
                                ? '${type.category} · 按数量'
                                : type.tracksDistance
                                ? '${type.category} · 可记距离'
                                : type.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: results.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseFormSheet extends StatefulWidget {
  final ExerciseType type;
  final double weightKg;
  const _ExerciseFormSheet({required this.type, required this.weightKg});

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _minutes = TextEditingController(text: '30');
  final _count = TextEditingController(text: '20');
  final _distance = TextEditingController();
  String _intensity = '适中';
  String _startTime = '';

  @override
  void initState() {
    super.initState();
    _minutes.addListener(_refresh);
    _count.addListener(_refresh);
    _distance.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  int get _minutesValue => int.tryParse(_minutes.text) ?? 0;
  int get _countValue => int.tryParse(_count.text) ?? 0;
  int get _estimatedMinutes =>
      widget.type.minutesForCount(_countValue.clamp(0, 1000).toInt());

  double? get _distanceValue {
    final value = double.tryParse(_distance.text.trim());
    return value == null || value <= 0 ? null : value;
  }

  int get _kcal => widget.type.isCount
      ? widget.type.kcalForCount(
          count: _countValue,
          intensity: _intensity,
          weightKg: widget.weightKg,
        )
      : widget.type.kcalFor(
          minutes: _minutesValue,
          intensity: _intensity,
          weightKg: widget.weightKg,
        );

  @override
  void dispose() {
    _minutes.dispose();
    _count.dispose();
    _distance.dispose();
    super.dispose();
  }

  void _save() {
    final minutes = widget.type.isCount ? _estimatedMinutes : _minutesValue;
    if (widget.type.isCount) {
      if (_countValue <= 0 || _countValue > 1000) {
        showToast(
          context,
          '请输入 1~1000 个的数量',
          icon: Icons.error_outline_rounded,
        );
        return;
      }
    } else if (_minutesValue <= 0 || _minutesValue > 600) {
      showToast(context, '请输入 1~600 分钟的时长', icon: Icons.error_outline_rounded);
      return;
    }
    if (_distance.text.trim().isNotEmpty && _distanceValue == null) {
      showToast(context, '距离需要大于 0', icon: Icons.error_outline_rounded);
      return;
    }
    Navigator.of(context).pop(
      ExerciseEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        date: AppScope.of(context).todayIso,
        kind: widget.type.name,
        minutes: minutes,
        intensity: _intensity,
        kcal: _kcal,
        distanceKm: _distanceValue,
        count: widget.type.isCount ? _countValue : null,
        startTime: _startTime.isEmpty
            ? AppScope.of(context).currentTime
            : _startTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final start = _startTime.isEmpty
        ? AppScope.of(context).currentTime
        : _startTime;
    final end = addMinutesToClock(
      start,
      widget.type.isCount ? _estimatedMinutes : _minutesValue,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.type.icon,
                  size: 24,
                  color: AppColors.green2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.type.name, style: titleStyle(size: 21)),
                    const SizedBox(height: 3),
                    Text(
                      widget.type.isCount
                          ? '${widget.type.category} · 约 ${widget.type.repsPerMinute.round()} 个/分钟'
                          : '${widget.type.category} · 约 ${widget.type.kcalFor(minutes: 60, intensity: '适中', weightKg: widget.weightKg)} 千卡/小时',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
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
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                '开始时间',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink2,
                ),
              ),
              const Spacer(),
              MealTimeButton(
                time: start,
                onTap: () async {
                  final next = await pickMealTime(context, start);
                  if (next != null && mounted) {
                    setState(() => _startTime = next);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            end.isEmpty ? '保存后按开始时间计算时间范围' : '$start – $end',
            style: const TextStyle(fontSize: 9, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          if (widget.type.isCount) ...[
            const Text(
              '完成数量',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '输入数量',
                suffixText: '个',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [10, 20, 30, 50].map((value) {
                final active = _countValue == value;
                return Expanded(
                  child: Pressable(
                    onTap: () => _count.text = '$value',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 32,
                      margin: EdgeInsets.only(right: value == 50 ? 0 : 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentSoft
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$value 个',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              '按约 ${widget.type.repsPerMinute.round()} 个/分钟估算，约 $_estimatedMinutes 分钟',
              style: const TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ] else ...[
            const Text(
              '运动时长',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '输入时长',
                suffixText: '分钟',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [15, 30, 45, 60].map((value) {
                final active = _minutesValue == value;
                return Expanded(
                  child: Pressable(
                    onTap: () => _minutes.text = '$value',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 32,
                      margin: EdgeInsets.only(right: value == 60 ? 0 : 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentSoft
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$value 分',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (!widget.type.isCount && widget.type.tracksDistance) ...[
            const SizedBox(height: 14),
            const Text(
              '距离（可选）',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _distance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '例如 3.5',
                suffixText: '公里',
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            '强度',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['低', '适中', '高'].map((level) {
              final active = _intensity == level;
              return Expanded(
                child: Pressable(
                  onTap: () => setState(() => _intensity = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 38,
                    margin: EdgeInsets.only(right: level == '高' ? 0 : 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2EDD4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 24,
                  color: AppColors.green2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '预计消耗',
                        style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                      ),
                      const SizedBox(height: 1),
                      Text.rich(
                        TextSpan(
                          text: '$_kcal',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                          children: [
                            const TextSpan(
                              text: ' 千卡',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.weightKg.toStringAsFixed(0)} kg · $_intensity'
                  '${widget.type.isCount ? ' · 约 $_estimatedMinutes 分钟' : ''}',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: '保存运动记录',
            icon: Icons.check_rounded,
            expand: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _CustomExerciseSheet extends StatefulWidget {
  final double weightKg;
  final double heightCm;
  const _CustomExerciseSheet({required this.weightKg, required this.heightCm});

  @override
  State<_CustomExerciseSheet> createState() => _CustomExerciseSheetState();
}

class _CustomExerciseSheetState extends State<_CustomExerciseSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '30');
  ExerciseMetric _metric = ExerciseMetric.duration;
  String _intensity = '适中';
  bool _loading = false;
  String? _error;
  ExerciseType? _result;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
    _amount.addListener(() => setState(() {}));
  }

  void _onNameChanged() {
    if (_result != null) {
      setState(() => _result = null);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  int get _amountValue => int.tryParse(_amount.text) ?? 0;

  int get _kcal {
    final type = _result;
    if (type == null) return 0;
    return type.isCount
        ? type.kcalForCount(
            count: _amountValue,
            intensity: _intensity,
            weightKg: widget.weightKg,
          )
        : type.kcalFor(
            minutes: _amountValue,
            intensity: _intensity,
            weightKg: widget.weightKg,
          );
  }

  void _setMetric(ExerciseMetric metric) {
    if (_metric == metric) return;
    setState(() {
      _metric = metric;
      _result = null;
      _error = null;
      _amount.text = metric == ExerciseMetric.count ? '20' : '30';
    });
  }

  Future<void> _analyze() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, '请输入运动名称', icon: Icons.error_outline_rounded);
      return;
    }
    if (_amountValue <= 0 || _amountValue > 1000) {
      showToast(context, '请输入 1~1000 的数量', icon: Icons.error_outline_rounded);
      return;
    }
    final state = AppScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final type = await state.analyzeCustomExercise(
        name: name,
        metric: _metric,
        amount: _amountValue,
        intensity: _intensity,
        weightKg: widget.weightKg,
        heightCm: widget.heightCm,
      );
      if (!mounted) return;
      setState(() {
        if (type == null) {
          _error = 'AI 没有返回可用结果，请重试或换个名称。';
        } else {
          _result = type;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'AI 分析失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useFallback() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, '请输入运动名称', icon: Icons.error_outline_rounded);
      return;
    }
    final met = _metric == ExerciseMetric.count ? 6.0 : 5.0;
    final reps = 20.0;
    setState(() {
      _error = null;
      _result = ExerciseType(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: '自定义',
        icon: customExerciseIcon,
        met: met,
        metric: _metric,
        repsPerMinute: reps,
        linearKcalPerUnit: _metric == ExerciseMetric.count ? met / reps : met,
        modelSource: 'manual',
      );
    });
  }

  void _save() {
    final type = _result;
    if (type == null) return;
    if (_amountValue <= 0 || _amountValue > 1000) {
      showToast(context, '请输入有效数量', icon: Icons.error_outline_rounded);
      return;
    }
    final minutes = type.isCount
        ? type.minutesForCount(_amountValue)
        : _amountValue;
    Navigator.of(context).pop((
      entry: ExerciseEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        date: AppScope.of(context).todayIso,
        kind: type.name,
        minutes: minutes,
        intensity: _intensity,
        kcal: _kcal,
        count: type.isCount ? _amountValue : null,
        startTime: AppScope.of(context).currentTime,
      ),
      type: type,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 24,
                  color: Color(0xFF7B6AAE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI 自定义运动', style: titleStyle(size: 21)),
                    const SizedBox(height: 3),
                    const Text(
                      'AI 估算消耗，并加入「自定义」分类，下次可直接选择。',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        height: 1.4,
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
          const SizedBox(height: 18),
          const Text(
            '运动名称',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '例如 波比跳、空中自行车、爬绳',
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '记录方式',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _metricButton(ExerciseMetric.duration, '按时长'),
              const SizedBox(width: 6),
              _metricButton(ExerciseMetric.count, '按数量'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _metric == ExerciseMetric.count ? '完成数量' : '运动时长',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: _metric == ExerciseMetric.count ? '输入数量' : '输入时长',
              suffixText: _metric == ExerciseMetric.count ? '个' : '分钟',
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '强度',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['低', '适中', '高'].map((level) {
              final active = _intensity == level;
              return Expanded(
                child: Pressable(
                  onTap: () => setState(() => _intensity = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 38,
                    margin: EdgeInsets.only(right: level == '高' ? 0 : 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI 正在分析消耗，请稍候…',
                    style: TextStyle(fontSize: 11, color: AppColors.ink2),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEDE8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0D8CE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9B5A45),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Pressable(
                    onTap: _useFallback,
                    child: const Text(
                      '先用通用强度估算',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_result != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2EDD4)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 24,
                    color: AppColors.green2,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '预计消耗 · ${_result!.name}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text.rich(
                          TextSpan(
                            text: '$_kcal',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              height: 1.1,
                            ),
                            children: [
                              const TextSpan(
                                text: ' 千卡',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'MET ${_result!.met.toStringAsFixed(1)}\n'
                    '${_result!.isCount ? '${_result!.kcalPerUnit.toStringAsFixed(2)} 千卡/个' : '${_result!.kcalPerUnit.toStringAsFixed(1)} 千卡/分'}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (!_loading)
            PillButton(
              label: _result == null ? '让 AI 分析消耗' : '保存并加入自定义运动',
              icon: _result == null
                  ? Icons.auto_awesome_rounded
                  : Icons.check_rounded,
              expand: true,
              onPressed: _result == null ? _analyze : _save,
            ),
        ],
      ),
    );
  }

  Widget _metricButton(ExerciseMetric metric, String label) {
    final active = _metric == metric;
    return Expanded(
      child: Pressable(
        onTap: () => _setMetric(metric),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.ink : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
