import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class TrendPoint {
  final String label;
  final double? kcal;
  final double? weight;
  const TrendPoint(this.label, this.kcal, this.weight);
}

class ChartSeries {
  final List<double> values;
  final Color color;
  final bool fill;

  const ChartSeries({
    required this.values,
    required this.color,
    this.fill = false,
  });
}

/// 多指标平滑折线图：每条线独立归一化，适合步数/睡眠/心率这种量纲不同的数据。
class MultiSeriesChart extends StatelessWidget {
  final List<ChartSeries> series;
  final List<String> labels;
  final double height;
  final int? highlightIndex;
  final String? highlightLabel;

  const MultiSeriesChart({
    super.key,
    required this.series,
    required this.labels,
    this.height = 176,
    this.highlightIndex,
    this.highlightLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = series.any(
      (item) => item.values.any((value) => value != 0),
    );
    if (!hasData) {
      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DashedLine(color: AppColors.sage, height: height - 24),
            const Text(
              '连接健康数据后生成趋势',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _MultiSeriesPainter(
          series: series,
          labels: labels,
          progress: progress,
          highlightIndex: highlightIndex,
          highlightLabel: highlightLabel,
        ),
      ),
    );
  }
}

class _MultiSeriesPainter extends CustomPainter {
  final List<ChartSeries> series;
  final List<String> labels;
  final double progress;
  final int? highlightIndex;
  final String? highlightLabel;

  _MultiSeriesPainter({
    required this.series,
    required this.labels,
    required this.progress,
    required this.highlightIndex,
    required this.highlightLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const right = 8.0;
    const top = 14.0;
    const bottom = 22.0;
    final rect = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    for (final item in series) {
      final values = item.values;
      if (values.length < 2 || values.every((value) => value == 0)) continue;
      final min = values.reduce(math.min);
      final max = values.reduce(math.max);
      final span = (max - min).abs() < .001 ? 1.0 : max - min;
      final points = <Offset>[];
      for (var i = 0; i < values.length; i++) {
        final x = rect.left + rect.width * i / (values.length - 1);
        final y = rect.bottom - rect.height * ((values[i] - min) / span);
        points.add(Offset(x, y));
      }
      final path = _smoothPath(points);
      if (item.fill) {
        final area = Path.from(path)
          ..lineTo(points.last.dx, rect.bottom)
          ..lineTo(points.first.dx, rect.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                item.color.withValues(alpha: .14 * progress),
                item.color.withValues(alpha: 0),
              ],
            ).createShader(rect),
        );
      }
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      if (progress > .96) {
        for (final point in points) {
          canvas.drawCircle(point, 2.6, Paint()..color = Colors.white);
          canvas.drawCircle(
            point,
            2.6,
            Paint()
              ..color = item.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.3,
          );
        }
        canvas.drawCircle(
          points.last,
          4.2,
          Paint()..color = item.color.withValues(alpha: .18),
        );
        canvas.drawCircle(points.last, 2.8, Paint()..color = item.color);
      }
    }

    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < labels.length; i++) {
      final x = rect.left + rect.width * i / math.max(1, labels.length - 1);
      labelPaint.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 8.5,
          color: Color(0xFF8D988D),
          fontFamilyFallback: ['NotoSansSC'],
        ),
      );
      labelPaint.layout();
      labelPaint.paint(
        canvas,
        Offset(x - labelPaint.width / 2, rect.bottom + 7),
      );
    }

    final highlight = highlightIndex;
    if (highlight != null && highlight >= 0 && highlight < labels.length) {
      final x =
          rect.left + rect.width * highlight / math.max(1, labels.length - 1);
      final dash = Paint()
        ..color = const Color(0xFFBFC7BA)
        ..strokeWidth = 1;
      var y = rect.top;
      while (y < rect.bottom) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 4, rect.bottom)),
          dash,
        );
        y += 8;
      }
      if (highlightLabel != null) {
        final bubble = TextPainter(
          text: TextSpan(
            text: highlightLabel,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4D5B3C),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final box = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, rect.top + 8),
            width: bubble.width + 14,
            height: 20,
          ),
          const Radius.circular(7),
        );
        canvas.drawRRect(box, Paint()..color = const Color(0xFFF1F9DD));
        bubble.paint(
          canvas,
          Offset(x - bubble.width / 2, rect.top + 8 - bubble.height / 2 + 1),
        );
      }
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _MultiSeriesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.series != series ||
      oldDelegate.highlightIndex != highlightIndex;
}

/// 卡片里的迷你趋势线：加载时从左到右画出，带一层很淡的渐变。
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  final bool fill;
  final bool showEndDot;

  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 24,
    this.fill = true,
    this.showEndDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (values.length < 2) return DashedLine(color: color, height: height);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _SparklinePainter(
          values: values,
          color: color,
          progress: progress,
          fill: fill,
          showEndDot: showEndDot,
        ),
      ),
    );
  }
}

/// 没有数据时的占位线：虚线从左到右展开，再缓慢扫过一层微光。
/// 不伪造任何数值，只表达「等待同步」。
class DashedLine extends StatefulWidget {
  final Color color;
  final double height;

  const DashedLine({super.key, required this.color, this.height = 24});

  @override
  State<DashedLine> createState() => _DashedLineState();
}

class _DashedLineState extends State<DashedLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduced) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => AnimatedBuilder(
        animation: _shimmer,
        builder: (context, _) => CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _DashedLinePainter(
            color: widget.color,
            progress: progress,
            phase: _reduced ? 0 : _shimmer.value,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double progress;
  final bool fill;
  final bool showEndDot;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.fill,
    required this.showEndDot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = (max - min).abs() < .001 ? 1.0 : max - min;
    const pad = 3.0;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height -
          pad -
          (size.height - pad * 2) * ((values[i] - min) / span);
      points.add(Offset(x, y));
    }

    final path = _smoothPath(points);
    if (fill) {
      final area = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: .20 * progress),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(area, fillPaint);
    }

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(
      0,
      metric.length * progress.clamp(0.0, 1.0),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..strokeWidth = 1.7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showEndDot && progress > .96) {
      final end = points.last;
      canvas.drawCircle(end, 6, Paint()..color = color.withValues(alpha: .16));
      canvas.drawCircle(end, 3.4, Paint()..color = Colors.white);
      canvas.drawCircle(end, 2.2, Paint()..color = color);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.color != color;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double phase;

  _DashedLinePainter({
    required this.color,
    required this.progress,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 5;
    final paint = Paint()
      ..color = color.withValues(alpha: .34)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final limit = size.width * progress;
    var x = 0.0;
    while (x < limit) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, limit), y), paint);
      x += 8;
    }

    if (progress > .98) {
      final center = size.width * phase;
      final rect = Rect.fromLTWH(center - 34, 0, 68, size.height);
      final shimmer = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: .34),
            color.withValues(alpha: 0),
          ],
        ).createShader(rect)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(center - 34, y), Offset(center + 34, y), shimmer);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.phase != phase;
}

class CalorieTrendChart extends StatelessWidget {
  final List<TrendPoint> points;
  final int goal;
  final double height;
  final int? highlightIndex;

  const CalorieTrendChart({
    super.key,
    required this.points,
    required this.goal,
    this.height = 205,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _TrendPainter(
          points: points,
          goal: goal,
          progress: progress,
          highlightIndex: highlightIndex,
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendPoint> points;
  final int goal;
  final double progress;
  final int? highlightIndex;

  _TrendPainter({
    required this.points,
    required this.goal,
    required this.progress,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const right = 26.0;
    const top = 16.0;
    const bottom = 26.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final maxKcal = math.max(goal * 1.18, 2200.0);
    final weights = points.map((e) => e.weight).whereType<double>().toList();
    final minWeight = weights.isEmpty ? 55.0 : weights.reduce(math.min) - .3;
    final maxWeight = weights.isEmpty ? 59.0 : weights.reduce(math.max) + .3;

    final grid = Paint()
      ..color = const Color(0xFFF1F3ED)
      ..strokeWidth = 1;
    final axis = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      axis.text = TextSpan(
        text: (maxKcal * (1 - i / 3)).round().toString(),
        style: const TextStyle(fontSize: 7.5, color: Color(0xFF9BA49A)),
      );
      axis.layout();
      axis.paint(canvas, Offset(0, y - 4));
    }

    final goalY = chart.top + chart.height * (1 - goal / maxKcal);
    final dash = Paint()
      ..color = const Color(0xFFC8A463)
      ..strokeWidth = 1;
    var x = chart.left;
    while (x < chart.right) {
      canvas.drawLine(
        Offset(x, goalY),
        Offset(math.min(x + 4, chart.right), goalY),
        dash,
      );
      x += 7;
    }

    final step = chart.width / math.max(points.length, 1);
    final barWidth = math.min(12.0, step * .34).toDouble();
    final barPaint = Paint();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final cx = chart.left + step * i + step / 2;
      if (point.kcal != null && point.kcal! > 0) {
        final ratio =
            (point.kcal! / maxKcal).clamp(0.0, 1.0).toDouble() * progress;
        final barHeight = chart.height * ratio;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cx - barWidth / 2,
            chart.bottom - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(4),
        );
        barPaint.color = point.kcal! > goal
            ? const Color(0xFFF0B39A)
            : const Color(0xFFCDEB7E);
        canvas.drawRRect(rect, barPaint);
      }

      axis.text = TextSpan(
        text: point.label,
        style: const TextStyle(
          fontSize: 8,
          color: Color(0xFF8D988D),
          fontFamilyFallback: ['NotoSansSC'],
        ),
      );
      axis.layout();
      axis.paint(canvas, Offset(cx - axis.width / 2, chart.bottom + 8));
    }

    if (highlightIndex != null &&
        highlightIndex! < points.length &&
        points[highlightIndex!].kcal != null) {
      final point = points[highlightIndex!];
      final cx = chart.left + step * highlightIndex! + step / 2;
      final marker = Paint()
        ..color = const Color(0xFFB9C0B5)
        ..strokeWidth = 1;
      var my = chart.top;
      while (my < chart.bottom) {
        canvas.drawLine(
          Offset(cx, my),
          Offset(cx, math.min(my + 4, chart.bottom)),
          marker,
        );
        my += 8;
      }
      final ratio = (point.kcal! / maxKcal).clamp(0.0, 1.0).toDouble();
      final cy = chart.bottom - chart.height * ratio * progress;
      final bubble = TextPainter(
        text: TextSpan(
          text: '${point.kcal!.round()}',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4D5B3C),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 17),
          width: bubble.width + 14,
          height: 20,
        ),
        const Radius.circular(7),
      );
      canvas.drawRRect(box, Paint()..color = const Color(0xFFF1F9DD));
      bubble.paint(
        canvas,
        Offset(cx - bubble.width / 2, cy - 17 - bubble.height / 2 + 1),
      );
    }

    final weightPoints = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (point.weight == null) continue;
      final cx = chart.left + step * i + step / 2;
      final ratio =
          (point.weight! - minWeight) / math.max(.1, maxWeight - minWeight);
      final cy = chart.top + chart.height * (1 - ratio);
      weightPoints.add(Offset(cx, cy));
    }
    if (weightPoints.length > 1) {
      final line = Path()..moveTo(weightPoints.first.dx, weightPoints.first.dy);
      for (final point in weightPoints.skip(1)) {
        line.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF9DB3BD)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      for (final point in weightPoints) {
        canvas.drawCircle(point, 3, Paint()..color = Colors.white);
        canvas.drawCircle(
          point,
          3,
          Paint()
            ..color = const Color(0xFF9DB3BD)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.points != points ||
      oldDelegate.highlightIndex != highlightIndex;
}

class BodyCompositionChart extends StatelessWidget {
  final List<BodyPoint> points;
  final double? targetWeight;
  final double height;

  const BodyCompositionChart({
    super.key,
    required this.points,
    this.targetWeight,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 22,
                color: Color(0xFFB4BDB2),
              ),
              const SizedBox(height: 8),
              Text(
                '再记录一次，就能看到体重与体脂的变化',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _BodyCompositionPainter(
          points: points,
          targetWeight: targetWeight,
          progress: progress,
        ),
      ),
    );
  }
}

class BodySparkline extends StatelessWidget {
  final List<BodyPoint> points;
  final double height;

  const BodySparkline({super.key, required this.points, this.height = 38});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _BodySparklinePainter(points),
    );
  }
}

class _BodySparklinePainter extends CustomPainter {
  final List<BodyPoint> points;
  _BodySparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final rect = Rect.fromLTRB(1, 3, size.width - 1, size.height - 3);
    final weightValues = points
        .map((point) => point.weightKg)
        .whereType<double>()
        .toList();
    final fatValues = points
        .map((point) => point.bodyFat)
        .whereType<double>()
        .toList();
    if (weightValues.isEmpty && fatValues.isEmpty) return;

    double xFor(int index) =>
        rect.left + rect.width * index / (points.length - 1);
    double yFor(double value, List<double> values) {
      final min = values.reduce(math.min);
      final max = values.reduce(math.max);
      final span = math.max(.1, max - min);
      return rect.top + rect.height * (1 - (value - min) / span);
    }

    void draw(List<double?> values, Color color, double width) {
      final present = values.whereType<double>().toList();
      if (present.isEmpty) return;
      final path = Path();
      var started = false;
      Offset? last;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        if (value == null) {
          started = false;
          continue;
        }
        final offset = Offset(xFor(i), yFor(value, present));
        if (!started) {
          path.moveTo(offset.dx, offset.dy);
          started = true;
        } else {
          path.lineTo(offset.dx, offset.dy);
        }
        last = offset;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      if (last != null) {
        canvas.drawCircle(last, 2.6, Paint()..color = color);
      }
    }

    draw(
      points.map((point) => point.weightKg).toList(),
      const Color(0xFF6F8F62),
      1.8,
    );
    draw(
      points.map((point) => point.bodyFat).toList(),
      const Color(0xFFD08B72),
      1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _BodySparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _BodyCompositionPainter extends CustomPainter {
  final List<BodyPoint> points;
  final double? targetWeight;
  final double progress;

  static const _weightColor = Color(0xFF5C7A63);
  static const _fatColor = Color(0xFFD08B72);
  static const _gridColor = Color(0xFFEDF0E9);
  static const _labelColor = Color(0xFF9AA399);

  _BodyCompositionPainter({
    required this.points,
    required this.targetWeight,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 32.0;
    const rightPad = 36.0;
    const topPad = 12.0;
    const bottomPad = 24.0;
    final rect = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final weightValues = points
        .map((point) => point.weightKg)
        .whereType<double>()
        .toList();
    final fatValues = points
        .map((point) => point.bodyFat)
        .whereType<double>()
        .toList();
    if (weightValues.isEmpty && fatValues.isEmpty) return;

    final weightBounds = _bounds(
      weightValues,
      pad: .4,
      minSpan: 1,
      include: targetWeight,
    );
    final fatBounds = _bounds(fatValues, pad: .8, minSpan: 2);

    double xFor(int index) => points.length == 1
        ? rect.center.dx
        : rect.left + rect.width * index / (points.length - 1);
    double yForWeight(double value) =>
        rect.top +
        rect.height *
            (1 -
                (value - weightBounds.min) /
                    (weightBounds.max - weightBounds.min));
    double yForFat(double value) =>
        rect.top +
        rect.height *
            (1 - (value - fatBounds.min) / (fatBounds.max - fatBounds.min));

    final gridPaint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final ratio = i / 2;
      final y = rect.top + rect.height * ratio;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      if (weightValues.isNotEmpty) {
        _text(
          canvas,
          (weightBounds.max - (weightBounds.max - weightBounds.min) * ratio)
              .toStringAsFixed(1),
          Offset(rect.left - 6, y - 5),
          align: _TextAlign.right,
        );
      }
      if (fatValues.isNotEmpty) {
        _text(
          canvas,
          '${(fatBounds.max - (fatBounds.max - fatBounds.min) * ratio).toStringAsFixed(1)}%',
          Offset(rect.right + 6, y - 5),
        );
      }
    }

    if (targetWeight != null) {
      final y = yForWeight(targetWeight!);
      if (y >= rect.top && y <= rect.bottom) {
        _dashedLine(canvas, Offset(rect.left, y), Offset(rect.right, y));
        _text(
          canvas,
          '目标 ${targetWeight!.toStringAsFixed(0)}',
          Offset(rect.right - 4, y - 11),
          align: _TextAlign.right,
          color: const Color(0xFFB4BDB2),
        );
      }
    }

    final weightSegments = _segments(
      points.map((point) => point.weightKg).toList(),
      xFor,
      yForWeight,
    );
    final fatSegments = _segments(
      points.map((point) => point.bodyFat).toList(),
      xFor,
      yForFat,
    );

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        rect.left - 4,
        0,
        rect.left + rect.width * progress + 4,
        size.height,
      ),
    );

    for (final segment in weightSegments.where(
      (segment) => segment.length > 1,
    )) {
      final area = Path()..moveTo(segment.first.dx, rect.bottom);
      for (final point in segment) {
        area.lineTo(point.dx, point.dy);
      }
      area
        ..lineTo(segment.last.dx, rect.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x336B826F), Color(0x006B826F)],
          ).createShader(rect),
      );
      _drawSegment(canvas, segment, _weightColor, 2.4);
    }

    for (final segment in fatSegments) {
      if (segment.length > 1) {
        _drawSegment(canvas, segment, _fatColor, 2);
      }
    }

    for (final segment in weightSegments) {
      for (final point in segment) {
        _dot(canvas, point, _weightColor);
      }
    }
    for (final segment in fatSegments) {
      for (final point in segment) {
        _dot(canvas, point, _fatColor, radius: 2.7);
      }
    }
    canvas.restore();

    final labelIndices = <int>{
      0,
      points.length ~/ 3,
      points.length * 2 ~/ 3,
      points.length - 1,
    }.toList()..sort();
    for (final index in labelIndices) {
      _text(
        canvas,
        _shortDate(points[index].date),
        Offset(xFor(index), rect.bottom + 7),
        align: _TextAlign.center,
      );
    }
  }

  List<List<Offset>> _segments(
    List<double?> values,
    double Function(int) xFor,
    double Function(double) yFor,
  ) {
    final segments = <List<Offset>>[];
    var current = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) {
        if (current.isNotEmpty) {
          segments.add(current);
          current = [];
        }
        continue;
      }
      current.add(Offset(xFor(i), yFor(value)));
    }
    if (current.isNotEmpty) segments.add(current);
    return segments;
  }

  void _drawSegment(
    Canvas canvas,
    List<Offset> segment,
    Color color,
    double width,
  ) {
    final path = Path()..moveTo(segment.first.dx, segment.first.dy);
    for (final point in segment.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dot(Canvas canvas, Offset point, Color color, {double radius = 3.2}) {
    canvas.drawCircle(point, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      point,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = const Color(0xFFC9D3C7)
      ..strokeWidth = 1;
    var x = from.dx;
    while (x < to.dx) {
      canvas.drawLine(
        Offset(x, from.dy),
        Offset(math.min(x + 5, to.dx), to.dy),
        paint,
      );
      x += 9;
    }
  }

  void _text(
    Canvas canvas,
    String value,
    Offset anchor, {
    _TextAlign align = _TextAlign.left,
    Color color = _labelColor,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontFamilyFallback: const ['NotoSansSC'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _TextAlign.left => anchor.dx,
      _TextAlign.center => anchor.dx - painter.width / 2,
      _TextAlign.right => anchor.dx - painter.width,
    };
    painter.paint(canvas, Offset(dx, anchor.dy));
  }

  ({double min, double max}) _bounds(
    List<double> values, {
    required double pad,
    required double minSpan,
    double? include,
  }) {
    final all = [...values, if (include != null) include];
    if (all.isEmpty) return (min: 0, max: 1);
    var min = all.reduce(math.min) - pad;
    var max = all.reduce(math.max) + pad;
    if (max - min < minSpan) {
      final mid = (max + min) / 2;
      min = mid - minSpan / 2;
      max = mid + minSpan / 2;
    }
    return (min: min, max: max);
  }

  String _shortDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return '${parsed.month}/${parsed.day}';
  }

  @override
  bool shouldRepaint(covariant _BodyCompositionPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.points != points ||
      oldDelegate.targetWeight != targetWeight;
}

enum _TextAlign { left, center, right }

class MacroDonut extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final String centerLabel;
  final String centerValue;
  final double size;

  const MacroDonut({
    super.key,
    this.protein = 26,
    this.carbs = 49,
    this.fat = 25,
    this.centerLabel = '均衡分',
    this.centerValue = '86',
    this.size = 156,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => CustomPaint(
          painter: _DonutPainter(
            protein: protein,
            carbs: carbs,
            fat: fat,
            progress: progress,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D2B23),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  centerLabel,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF66746B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;
  final double progress;

  _DonutPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = protein + carbs + fat;
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const stroke = 24.0;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius - stroke / 2,
        Paint()
          ..color = const Color(0xFFEFF2EA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      return;
    }
    final values = [
      (protein / total, const Color(0xFFD9A07C)),
      (carbs / total, const Color(0xFFCDEB7E)),
      (fat / total, const Color(0xFFA9C6D1)),
    ];
    var start = -math.pi / 2;
    for (final item in values) {
      final sweep = math.pi * 2 * item.$1 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start + .018,
        math.max(0, sweep - .036),
        false,
        Paint()
          ..color = item.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius - stroke - 4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
