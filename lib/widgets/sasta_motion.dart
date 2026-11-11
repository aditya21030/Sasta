import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sasta_theme.dart';
import '../theme/sasta_tokens.dart';

/// Staggered upward reveal respecting reduced-motion settings.
class FadeUp extends StatefulWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 16,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SastaMotion.fadeUp,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: SastaMotion.curve,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Gentle vertical float loop capped to hero elements, honoring reduced motion.
class FloatBob extends StatefulWidget {
  const FloatBob({
    super.key,
    required this.child,
    this.amplitude = 7,
    this.phaseShift = 0,
  });

  final Widget child;
  final double amplitude;
  final double phaseShift;

  @override
  State<FloatBob> createState() => _FloatBobState();
}

class _FloatBobState extends State<FloatBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SastaMotion.float,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dy = math.sin((_controller.value + widget.phaseShift) * 2 * math.pi) *
            widget.amplitude *
            0.5 -
            widget.amplitude * 0.5;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: widget.child,
    );
  }
}

/// Interactive dual-line price history chart matching PriceHistory.dc.html.
class AnimatedPriceLineChart extends StatefulWidget {
  const AnimatedPriceLineChart({
    super.key,
    required this.primaryPoints,
    required this.secondaryPoints,
    required this.startLabel,
    required this.endLabel,
  });

  final List<int> primaryPoints;
  final List<int> secondaryPoints;
  final String startLabel;
  final String endLabel;

  @override
  State<AnimatedPriceLineChart> createState() => _AnimatedPriceLineChartState();
}

class _AnimatedPriceLineChartState extends State<AnimatedPriceLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drawController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedPriceLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryPoints != widget.primaryPoints) {
      _selectedIndex = null;
      _drawController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPosition, double width) {
    if (widget.primaryPoints.isEmpty) return;
    final chartLeft = 42.0;
    final chartRight = width - 16.0;
    final clampedX = localPosition.dx.clamp(chartLeft, chartRight);
    final ratio = (clampedX - chartLeft) / math.max(1.0, chartRight - chartLeft);
    final idx = (ratio * (widget.primaryPoints.length - 1))
        .round()
        .clamp(0, widget.primaryPoints.length - 1);
    setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeIdx = _selectedIndex ?? (widget.primaryPoints.length - 1);
    final activePrice = widget.primaryPoints.isNotEmpty
        ? widget.primaryPoints[activeIdx]
        : 0;
    final tooltipText = _selectedIndex == null
        ? '₹$activePrice today'
        : '₹$activePrice';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: palette.lavender,
        borderRadius: BorderRadius.circular(SastaRadius.card),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (d) =>
                    _handleTouch(d.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    _handleTouch(d.localPosition, constraints.maxWidth),
                child: SizedBox(
                  height: 175,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _drawController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _PriceChartPainter(
                          primary: widget.primaryPoints,
                          secondary: widget.secondaryPoints,
                          progress: disabled
                              ? 1.0
                              : Curves.easeOut.transform(_drawController.value),
                          selectedIndex: activeIdx,
                          tooltipText: tooltipText,
                          isDark: palette.isDark,
                          mutedColor: palette.muted,
                          inkColor: palette.ink,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.startLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SastaText.muted(context, size: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.endLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: SastaText.muted(context, size: 12),
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

class _PriceChartPainter extends CustomPainter {
  const _PriceChartPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
    required this.selectedIndex,
    required this.tooltipText,
    required this.isDark,
    required this.mutedColor,
    required this.inkColor,
  });

  final List<int> primary;
  final List<int> secondary;
  final double progress;
  final int selectedIndex;
  final String tooltipText;
  final bool isDark;
  final Color mutedColor;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (primary.isEmpty) return;

    final allVals = [...primary, ...secondary];
    final minVal = allVals.reduce(math.min) - 1;
    final maxVal = allVals.reduce(math.max) + 1;
    final range = math.max(1, maxVal - minVal);

    const leftPad = 42.0;
    const rightPad = 14.0;
    const topPad = 16.0;
    const bottomPad = 14.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // 3 horizontal gridlines + price labels
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5;

    final midVal = ((minVal + maxVal) / 2).round();
    final tickVals = [maxVal, midVal, minVal];
    for (var i = 0; i < tickVals.length; i++) {
      final y = topPad + (i / 2.0) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: '₹${tickVals[i]}',
          style: TextStyle(
            color: mutedColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    List<Offset> mapPoints(List<int> pts) {
      if (pts.length == 1) {
        return [Offset(leftPad + chartW / 2, topPad + chartH / 2)];
      }
      return List.generate(pts.length, (i) {
        final x = leftPad + (i / (pts.length - 1)) * chartW;
        final norm = (pts[i] - minVal) / range;
        final y = topPad + chartH * (1 - norm);
        return Offset(x, y);
      });
    }

    final secPts = mapPoints(secondary);
    final priPts = mapPoints(primary);

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, leftPad + chartW * progress + 18, size.height),
    );

    if (secPts.length >= 2) {
      final secPath = Path()..moveTo(secPts.first.dx, secPts.first.dy);
      for (final pt in secPts.skip(1)) {
        secPath.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        secPath,
        Paint()
          ..color = SastaColors.chartLineAmber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    if (priPts.length >= 2) {
      final priPath = Path()..moveTo(priPts.first.dx, priPts.first.dy);
      for (final pt in priPts.skip(1)) {
        priPath.lineTo(pt.dx, pt.dy);
      }

      final fillPath = Path.from(priPath)
        ..lineTo(priPts.last.dx, topPad + chartH)
        ..lineTo(priPts.first.dx, topPad + chartH)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SastaColors.chartLinePurple.withValues(alpha: 0.28),
              SastaColors.chartLinePurple.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
      );

      canvas.drawPath(
        priPath,
        Paint()
          ..color = SastaColors.chartLinePurple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();

    if (progress > 0.75) {
      final activePt = priPts[selectedIndex.clamp(0, priPts.length - 1)];
      canvas.drawCircle(activePt, 8, Paint()..color = SastaColors.chartLinePurple);
      canvas.drawCircle(activePt, 4.5, Paint()..color = Colors.white);

      final pillTp = TextPainter(
        text: TextSpan(
          text: tooltipText,
          style: TextStyle(
            color: isDark ? SastaColors.ink : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillW = pillTp.width + 18;
      final pillH = 26.0;
      final pillX = (activePt.dx - pillW * 0.72)
          .clamp(leftPad, size.width - pillW - 4);
      final pillY = math.max(2.0, activePt.dy - pillH - 10);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pillX, pillY, pillW, pillH),
          const Radius.circular(13),
        ),
        Paint()..color = isDark ? SastaColors.darkInk : SastaColors.ink,
      );
      pillTp.paint(
        canvas,
        Offset(pillX + 9, pillY + (pillH - pillTp.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.primary != primary ||
        oldDelegate.isDark != isDark;
  }
}

/// Animated pulsing coral unread dot for Notifications.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = SastaColors.unreadCoral});
  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final dot = Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (disabled) return dot;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final s = 0.9 + _controller.value * 0.45;
        return Transform.scale(scale: s, child: child);
      },
      child: dot,
    );
  }
}

/// Animated shimmer skeleton placeholder for HomeError.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 20,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disabled) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: palette.skeletonBase,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              palette.skeletonBase,
              palette.skeletonHighlight,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
