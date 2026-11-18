import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class CalorieHero extends StatelessWidget {
  final int consumed;
  final int goal;
  final int protein;
  final int carbs;
  final VoidCallback? onDetails;

  const CalorieHero({
    super.key,
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (consumed / math.max(1, goal)).clamp(0.0, 1.0).toDouble();
    final percent = (ratio * 100).round();
    final label = consumed == 0
        ? '待记录'
        : percent >= 85
        ? '优秀'
        : percent >= 60
        ? '良好'
        : '进行中';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Text('营养概览', style: titleStyle(size: 16)),
              const Spacer(),
              CircleArrow(onTap: onDetails, size: 32),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 146,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _BreathingGauge(progress: ratio),
                ),
                Positioned(
                  top: 56,
                  child: Column(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7C8A7E),
                        ),
                      ),
                      const SizedBox(height: 1),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '${value.round()}%',
                          style: const TextStyle(
                            fontFamily: 'InterDisplay',
                            fontSize: 54,
                            height: .9,
                            fontWeight: FontWeight.w300,
                            color: AppColors.ink,
                            letterSpacing: -2.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _Macro(
                  label: '碳水',
                  value: '$carbs',
                  unit: 'g',
                  align: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _Macro(
                  label: '热量',
                  value: '$consumed',
                  unit: 'kcal',
                  align: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _Macro(
                  label: '蛋白质',
                  value: '$protein',
                  unit: 'g',
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final CrossAxisAlignment align;

  const _Macro({
    required this.label,
    required this.value,
    required this.unit,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        const SizedBox(height: 3),
        Text.rich(
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final double phase;
  _GaugePainter(this.progress, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 22;
    const stroke = 22.0;
    final center = Offset(size.width / 2, size.height - 6);
    final radius = math.min(size.width / 2 - 32, size.height - 20).toDouble();
    final start = math.pi;
    final step = math.pi / segments;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final activeCount = (progress * segments).ceil();

    for (var i = 0; i < segments; i++) {
      final a0 = start + step * i + .02;
      final a1 = start + step * (i + 1) - .02;
      final color = i < activeCount
          ? Color.lerp(
              const Color(0xFFB9FC4E),
              const Color(0xFFEDF8E8),
              i / (segments - 1),
            )!
          : const Color(0xFFEFF1F0);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, a0, a1 - a0, false, paint);
    }

    final dotRadius = radius - stroke / 2 - 7;
    final dotPaint = Paint()..color = const Color(0xFFD8DCCF);
    const dots = 84;
    for (var i = 0; i <= dots; i++) {
      final angle = math.pi + math.pi * i / dots;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * dotRadius;
      canvas.drawCircle(point, .95, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.phase != phase;
}

class _BreathingGauge extends StatefulWidget {
  final double progress;
  const _BreathingGauge({required this.progress});

  @override
  State<_BreathingGauge> createState() => _BreathingGaugeState();
}

class _BreathingGaugeState extends State<_BreathingGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduced) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.progress),
        duration: _reduced ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          size: const Size(double.infinity, 146),
          painter: _GaugePainter(value, _reduced ? 0 : _idle.value),
        ),
      ),
    );
  }
}
