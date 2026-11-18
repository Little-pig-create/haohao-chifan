import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';

class WaterCard extends StatefulWidget {
  final int glasses;
  final int goal;
  final int cupMl;
  final int targetMl;
  final ValueChanged<int> onSet;
  final VoidCallback onAdd;

  const WaterCard({
    super.key,
    required this.glasses,
    required this.goal,
    required this.cupMl,
    required this.targetMl,
    required this.onSet,
    required this.onAdd,
  });

  @override
  State<WaterCard> createState() => _WaterCardState();
}

class _WaterCardState extends State<WaterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stampController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final Animation<double> _stampScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.7,
        end: .9,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: .9,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 14,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 24),
  ]).animate(_stampController);
  late final Animation<double> _stampAngle = Tween(begin: -.32, end: -.16)
      .animate(
        CurvedAnimation(parent: _stampController, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _stampController.dispose();
    super.dispose();
  }

  void _stamp() {
    HapticFeedback.mediumImpact();
    _stampController.forward(from: 0);
  }

  void _addWater() {
    _stamp();
    widget.onAdd();
  }

  void _setWater(int value) {
    if (value > widget.glasses) _stamp();
    widget.onSet(value);
  }

  @override
  Widget build(BuildContext context) {
    final ml = widget.glasses * widget.cupMl;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E8EA),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      size: 18,
                      color: Color(0xFF3F6F7C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今日饮水', style: titleStyle(size: 14, height: 1.1)),
                      const SizedBox(height: 2),
                      const Text(
                        '保持充足水分',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF7E9184),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCounter(
                        value: ml,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w300,
                          color: AppColors.ink,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '/ ${formatNumber(widget.targetMl)} ml',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconPill(
                    icon: Icons.add_rounded,
                    size: 32,
                    background: AppColors.ink,
                    color: Colors.white,
                    onTap: _addWater,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(widget.goal, (index) {
                  final filled = index < widget.glasses;
                  return Expanded(
                    child: Pressable(
                      onTap: () => _setWater(index + 1),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 180 + index * 25),
                        height: 22,
                        margin: EdgeInsets.only(
                          right: index == widget.goal - 1 ? 0 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFFA9C6D1)
                              : AppColors.lineSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: filled
                                ? const Color(0xFFBCD5DE)
                                : AppColors.line,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _stampController,
              builder: (context, child) {
                final t = _stampController.value;
                if (t >= 1) return const SizedBox.shrink();
                final fall = Curves.easeOutCubic.transform(
                  (t / .5).clamp(0.0, 1.0),
                );
                final fade = t == 0
                    ? 0.0
                    : t < .74
                    ? 1.0
                    : (1 - (t - .74) / .26).clamp(0.0, 1.0);
                final ripple = ((t - .34) / .66).clamp(0.0, 1.0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (t > .34)
                      Opacity(
                        opacity: (1 - ripple) * .55,
                        child: Transform.scale(
                          scale: .45 + ripple * 1.45,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4F7D8A),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(0, (-34 * (1 - fall)) - 6),
                      child: Transform.rotate(
                        angle: _stampAngle.value,
                        child: Transform.scale(
                          scale: _stampScale.value,
                          child: Opacity(
                            opacity: fade,
                            child: Container(
                              key: const ValueKey('water-stamp'),
                              width: 78,
                              height: 78,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4FBFC)
                                    .withValues(alpha: .96),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4F7D8A),
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x29436670),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4F7D8A)
                                        .withValues(alpha: .45),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.water_drop_rounded,
                                      size: 21,
                                      color: Color(0xFF3F6F7C),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '+1 杯',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF3F6F7C),
                                      ),
                                    ),
                                    Text(
                                      '喝水',
                                      style: TextStyle(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        color: Color(0xFF6E929B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 全屏饮水印章，用于首页等没有 WaterCard 的快捷入口。
void showWaterStampOverlay(BuildContext context) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  HapticFeedback.mediumImpact();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _WaterStampOverlay(
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _WaterStampOverlay extends StatefulWidget {
  final VoidCallback onDone;
  const _WaterStampOverlay({required this.onDone});

  @override
  State<_WaterStampOverlay> createState() => _WaterStampOverlayState();
}

class _WaterStampOverlayState extends State<_WaterStampOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 760),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      });

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final fall = Curves.easeOutCubic.transform((t / .52).clamp(0.0, 1.0));
          final fade = t < .74 ? 1.0 : (1 - (t - .74) / .26).clamp(0.0, 1.0);
          final ripple = ((t - .34) / .66).clamp(0.0, 1.0);
          final scale = t < .52
              ? 1.65 - .65 * Curves.easeOutCubic.transform(t / .52)
              : 1.0 + .06 * math.sin((t - .52) / .48 * math.pi);
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (t > .34)
                  Opacity(
                    opacity: (1 - ripple) * .55,
                    child: Transform.scale(
                      scale: .45 + ripple * 1.7,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4F7D8A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, -46 * (1 - fall)),
                  child: Transform.rotate(
                    angle: -.18,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: fade,
                        child: Container(
                          key: const ValueKey('water-stamp-overlay'),
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4FBFC)
                                .withValues(alpha: .97),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4F7D8A),
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2E436670),
                                blurRadius: 22,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4F7D8A)
                                    .withValues(alpha: .45),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.water_drop_rounded,
                                  size: 23,
                                  color: Color(0xFF3F6F7C),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '+1 杯',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF3F6F7C),
                                  ),
                                ),
                                Text(
                                  '喝水',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF6E929B),
                                  ),
                                ),
                              ],
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
        },
      ),
    );
  }
}

class TipCard extends StatefulWidget {
  const TipCard({super.key});

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  String? _aiTip;
  bool _busy = false;
  int _localIndex = 0;

  /// 全部来自本机真实记录，没有记录就不编造。
  List<(String, String)> _localTips(AppState state) {
    final day = state.selectedDay;
    final protein = state.proteinFor(day);
    final proteinGoal = state.proteinGoal;
    final waterLeft = math.max(
      0,
      state.waterTargetMl - state.waterFor(day) * state.cupMl,
    );
    final steps = state.health.steps;
    final tips = <(String, String)>[];
    if (protein < proteinGoal) {
      tips.add((
        '今天已记录 $protein g 蛋白质，距离 $proteinGoal g 目标还差 ${proteinGoal - protein} g。',
        '晚餐可以加一份豆腐、鱼或鸡胸，比补蛋白粉更耐饿。',
      ));
    } else {
      tips.add(('今天蛋白质已达到 $protein g。', '把重点放到蔬菜和膳食纤维，主食按饥饿感调整。'));
    }
    if (waterLeft > 0) {
      tips.add((
        '饮水距离目标还差 ${formatNumber(waterLeft)} ml。',
        '每次 200–250 ml，分两三次补完比一次灌完更舒服。',
      ));
    } else {
      tips.add(('今天的饮水目标已经完成。', '晚间少量补水即可，避免睡前一次喝太多。'));
    }
    if (steps == null) {
      tips.add(('还没有同步到今天的步数。', '连接 Health Connect 后，这里会按真实活动量给建议。'));
    } else {
      tips.add((
        '今天已走 ${formatNumber(steps)} 步。',
        steps >= state.stepGoal
            ? '活动量达标，注意拉伸和睡眠。'
            : '距离 ${formatNumber(state.stepGoal)} 步还差 ${formatNumber(state.stepGoal - steps)} 步，晚饭后快走 20 分钟就能补上。',
      ));
    }
    if (state.weights.length >= 2) {
      final last = state.weights[state.weights.length - 1];
      final prev = state.weights[state.weights.length - 2];
      final diff = last.kg - prev.kg;
      tips.add((
        '最近一次体重 ${last.kg.toStringAsFixed(1)} kg，比上次${diff == 0
            ? '持平'
            : diff > 0
            ? '增加 ${diff.abs().toStringAsFixed(1)} kg'
            : '下降 ${diff.abs().toStringAsFixed(1)} kg'}。',
        '单次波动多半是水分，看 7 天平均更可靠。',
      ));
    } else {
      tips.add(('体重记录还不到两条，暂时看不出趋势。', '每周固定同一时间称重 2–3 次，趋势才有参考意义。'));
    }
    return tips;
  }

  Future<void> _generate() async {
    final state = AppScope.of(context);
    if (state.activeProvider == null) {
      showToast(context, '先在「我的 → AI 引擎」添加模型提供商', icon: Icons.link_off_rounded);
      return;
    }
    setState(() => _busy = true);
    try {
      final reply = await state.chat([
        {
          'role': 'system',
          'content':
              '你是营养助手。根据用户今天的真实记录，用中文给一条 40–70 字的具体建议，不要编造没有记录的数值，不要提疾病诊断。',
        },
        {
          'role': 'user',
          'content':
              '今天热量 ${state.consumedFor(state.selectedDay)}/${state.calorieGoal} 千卡，蛋白质 ${state.proteinFor(state.selectedDay)}g，'
              '饮水 ${state.waterFor(state.selectedDay) * state.cupMl}/${state.waterTargetMl}ml，步数 ${state.health.steps ?? '未同步'}。',
        },
      ]);
      if (!mounted) return;
      setState(() => _aiTip = reply);
    } catch (error) {
      if (!mounted) return;
      showToast(
        context,
        '$error'.replaceFirst('Exception: ', ''),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tips = _localTips(state);
    final tip = tips[_localIndex % tips.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: softGreenGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0xFFE7EDDF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 15,
                color: Color(0xFF53705B),
              ),
              const SizedBox(width: 6),
              const Text(
                '今日小贴士',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF53705B),
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(width: 7),
              SoftTag(
                _aiTip == null ? '本地规则' : 'AI 生成',
                background: const Color(0xFFE6EEE0),
                color: const Color(0xFF4F7159),
              ),
              const Spacer(),
              if (_aiTip == null)
                Pressable(
                  onTap: () => setState(() => _localIndex++),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 15,
                      color: Color(0xFF8B9A8D),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Pressable(
                onTap: _busy ? null : _generate,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: Color(0xFF53705B),
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: Color(0xFF53705B),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, .06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _aiTip == null
                ? Column(
                    key: ValueKey('local-$_localIndex'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip.$1,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.7,
                          color: Color(0xFF3E4C42),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip.$2,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: Color(0xFF6A786D),
                        ),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('ai'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _aiTip!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.7,
                          color: Color(0xFF3E4C42),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '由你配置的模型根据今天的记录生成。',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF6A786D),
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

class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color background;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 4,
    this.background = const Color(0xFFEEEADE),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(math.max(1, height / 2)),
      child: Container(
        height: height,
        color: background,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, current, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: current,
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
