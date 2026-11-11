import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/sasta_tokens.dart';

enum MascotExpression { happy, joy, sad, calm }

/// Signature 8-lobe flower mascot ("blob") representing Sasta or a quick-commerce retailer.
class SastaMascot extends StatefulWidget {
  const SastaMascot({
    super.key,
    this.size = 72,
    this.color = SastaColors.gold,
    this.expression = MascotExpression.happy,
    this.hasCrown = false,
    this.haloColor,
    this.animateBlink = false,
  });

  final double size;
  final Color color;
  final MascotExpression expression;
  final bool hasCrown;
  final Color? haloColor;
  final bool animateBlink;

  @override
  State<SastaMascot> createState() => _SastaMascotState();
}

class _SastaMascotState extends State<SastaMascot>
    with SingleTickerProviderStateMixin {
  AnimationController? _blinkController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBlinkController();
  }

  @override
  void didUpdateWidget(covariant SastaMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateBlink != widget.animateBlink ||
        oldWidget.expression != widget.expression) {
      _syncBlinkController();
    }
  }

  void _syncBlinkController() {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final shouldBlink = !disableAnimations &&
        widget.animateBlink &&
        widget.expression == MascotExpression.happy;
    if (shouldBlink) {
      _blinkController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4500),
      );
      if (!_blinkController!.isAnimating) {
        _blinkController!.repeat();
      }
    } else {
      _blinkController?.stop();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final totalHeight = widget.hasCrown ? widget.size * 1.18 : widget.size;

    Widget paintMascot(double eyeScaleY) {
      return ClipRect(
        child: CustomPaint(
          size: Size(widget.size, totalHeight),
          painter: _MascotPainter(
            color: widget.color,
            expression: widget.expression,
            hasCrown: widget.hasCrown,
            haloColor: widget.haloColor,
            eyeScaleY: disableAnimations ? 1.0 : eyeScaleY,
          ),
        ),
      );
    }

    if (_blinkController == null || disableAnimations) {
      return paintMascot(1.0);
    }

    return AnimatedBuilder(
      animation: _blinkController!,
      builder: (context, _) {
        final t = _blinkController!.value;
        double scaleY = 1.0;
        if (t > 0.92 && t <= 0.96) {
          scaleY = 1.0 - ((t - 0.92) / 0.04) * 0.9;
        } else if (t > 0.96) {
          scaleY = 0.1 + ((t - 0.96) / 0.04) * 0.9;
        }
        return paintMascot(scaleY);
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  const _MascotPainter({
    required this.color,
    required this.expression,
    required this.hasCrown,
    required this.haloColor,
    required this.eyeScaleY,
  });

  final Color color;
  final MascotExpression expression;
  final bool hasCrown;
  final Color? haloColor;
  final double eyeScaleY;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = hasCrown ? size.height * 0.56 : size.height / 2;
    final ref = size.width;

    if (haloColor != null) {
      canvas.drawCircle(
        Offset(cx, cy),
        ref * 0.48,
        Paint()..color = haloColor!,
      );
    }

    final coreR = ref * (haloColor != null ? 0.275 : 0.32);
    final lobeOrbit = coreR * 0.775;
    final lobeR = coreR * 0.575;
    final blobPaint = Paint()..color = color;

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final lx = cx + math.cos(angle) * lobeOrbit;
      final ly = cy + math.sin(angle) * lobeOrbit;
      canvas.drawCircle(Offset(lx, ly), lobeR, blobPaint);
    }
    canvas.drawCircle(Offset(cx, cy), coreR, blobPaint);

    // Features color
    final featureColor =
        expression == MascotExpression.sad
            ? const Color(0xFF4A4458)
            : SastaColors.ink;
    final strokeW = math.max(1.8, coreR * 0.088);

    // Cheeks for non-sad expressions
    if (expression != MascotExpression.sad) {
      final cheekPaint = Paint()
        ..color = const Color(0xFFFF9BB5).withValues(alpha: 0.72);
      canvas.drawCircle(
        Offset(cx - coreR * 0.57, cy + coreR * 0.15),
        coreR * 0.112,
        cheekPaint,
      );
      canvas.drawCircle(
        Offset(cx + coreR * 0.57, cy + coreR * 0.15),
        coreR * 0.112,
        cheekPaint,
      );
    }

    // Eyes
    if (expression == MascotExpression.joy) {
      final eyePaint = Paint()
        ..color = featureColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(cx - coreR * 0.47, cy - coreR * 0.03)
        ..quadraticBezierTo(
          cx - coreR * 0.35,
          cy - coreR * 0.25,
          cx - coreR * 0.22,
          cy - coreR * 0.03,
        );
      final rightEye = Path()
        ..moveTo(cx + coreR * 0.22, cy - coreR * 0.03)
        ..quadraticBezierTo(
          cx + coreR * 0.35,
          cy - coreR * 0.25,
          cx + coreR * 0.47,
          cy - coreR * 0.03,
        );
      canvas.drawPath(leftEye, eyePaint);
      canvas.drawPath(rightEye, eyePaint);
    } else if (expression == MascotExpression.sad) {
      final eyePaint = Paint()..color = featureColor;
      canvas.drawCircle(
        Offset(cx - coreR * 0.35, cy - coreR * 0.08),
        coreR * 0.095,
        eyePaint,
      );
      canvas.drawCircle(
        Offset(cx + coreR * 0.35, cy - coreR * 0.08),
        coreR * 0.095,
        eyePaint,
      );
    } else {
      final eyePaint = Paint()..color = featureColor;
      final r = coreR * 0.095;
      canvas.save();
      canvas.translate(cx - coreR * 0.35, cy - coreR * 0.08);
      canvas.scale(1, eyeScaleY);
      canvas.drawCircle(Offset.zero, r, eyePaint);
      canvas.restore();

      canvas.save();
      canvas.translate(cx + coreR * 0.35, cy - coreR * 0.08);
      canvas.scale(1, eyeScaleY);
      canvas.drawCircle(Offset.zero, r, eyePaint);
      canvas.restore();
    }

    // Mouth
    final mouthPaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    final mouthPath = Path();
    if (expression == MascotExpression.sad) {
      mouthPath
        ..moveTo(cx - coreR * 0.22, cy + coreR * 0.28)
        ..quadraticBezierTo(
          cx,
          cy + coreR * 0.14,
          cx + coreR * 0.22,
          cy + coreR * 0.28,
        );
    } else {
      mouthPath
        ..moveTo(cx - coreR * 0.18, cy + coreR * 0.20)
        ..quadraticBezierTo(
          cx,
          cy + coreR * 0.40,
          cx + coreR * 0.18,
          cy + coreR * 0.20,
        );
    }
    canvas.drawPath(mouthPath, mouthPaint);

    // Optional Crown for Sasta+
    if (hasCrown) {
      final crownW = coreR * 0.94;
      final crownH = coreR * 0.52;
      final crownTop =
          math.max(2.0, cy - coreR - lobeR * 0.52 - crownH * 0.35);
      final path = Path()
        ..moveTo(cx - crownW * 0.46, crownTop + crownH)
        ..lineTo(cx - crownW * 0.54, crownTop + crownH * 0.22)
        ..lineTo(cx - crownW * 0.22, crownTop + crownH * 0.54)
        ..lineTo(cx, crownTop)
        ..lineTo(cx + crownW * 0.22, crownTop + crownH * 0.54)
        ..lineTo(cx + crownW * 0.54, crownTop + crownH * 0.22)
        ..lineTo(cx + crownW * 0.46, crownTop + crownH)
        ..close();

      canvas.drawPath(path, Paint()..color = SastaColors.goldDeep);
      canvas.drawPath(
        path,
        Paint()
          ..color = SastaColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.8, strokeW * 0.95)
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.expression != expression ||
        oldDelegate.hasCrown != hasCrown ||
        oldDelegate.haloColor != haloColor ||
        oldDelegate.eyeScaleY != eyeScaleY;
  }
}

/// Crisp 4-point star sparkle used in hero and milestone illustrations.
class SastaSparkle extends StatefulWidget {
  const SastaSparkle({
    super.key,
    this.size = 20,
    this.color = SastaColors.sparkleOrange,
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<SastaSparkle> createState() => _SastaSparkleState();
}

class _SastaSparkleState extends State<SastaSparkle>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final star = CustomPaint(
      size: Size.square(widget.size),
      painter: _SparklePainter(color: widget.color),
    );
    if (_controller == null || disabled) return star;
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final v = Curves.easeInOut.transform(_controller!.value);
        return Opacity(
          opacity: 0.38 + v * 0.62,
          child: Transform.scale(scale: 0.78 + v * 0.22, child: child),
        );
      },
      child: star,
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 2;
    final path = Path()
      ..moveTo(c, 0)
      ..quadraticBezierTo(c, c, size.width, c)
      ..quadraticBezierTo(c, c, c, size.height)
      ..quadraticBezierTo(c, c, 0, c)
      ..quadraticBezierTo(c, c, c, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}
