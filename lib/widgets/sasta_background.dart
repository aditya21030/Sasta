import 'package:flutter/material.dart';

import '../theme/sasta_tokens.dart';

/// Ambient pastel corner glow canvas used across all standard Sasta screens.
class SastaBackground extends StatelessWidget {
  const SastaBackground({
    super.key,
    required this.child,
    this.isSplash = false,
  });

  final Widget child;
  final bool isSplash;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSplash && !palette.isDark
            ? SastaColors.splashLavender
            : palette.screen,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _AuraPainter(
                isSplash: isSplash,
                isDark: palette.isDark,
                auraLeft: palette.auraLeft,
                auraRight: palette.auraRight,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({
    required this.isSplash,
    required this.isDark,
    required this.auraLeft,
    required this.auraRight,
  });

  final bool isSplash;
  final bool isDark;
  final Color auraLeft;
  final Color auraRight;

  @override
  void paint(Canvas canvas, Size size) {
    if (isSplash) {
      final center = Offset(size.width * 0.5, size.height * 0.25);
      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: isDark
              ? const [
                  Color(0xFF392F1A),
                  Color(0xFF28203E),
                  Color(0xFF191522),
                ]
              : const [
                  SastaColors.splashCream,
                  SastaColors.splashLavender,
                  SastaColors.splashPeach,
                ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: size.longestSide * 0.85));
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }

    final leftCenter = Offset(size.width * 0.12, -size.height * 0.04);
    final leftRadius = size.width * 0.72;
    final leftPaint = Paint()
      ..shader = RadialGradient(
        colors: [auraLeft, auraLeft.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: leftCenter, radius: leftRadius));
    canvas.drawCircle(leftCenter, leftRadius, leftPaint);

    final rightCenter = Offset(size.width, size.height * 0.04);
    final rightRadius = size.width * 0.68;
    final rightPaint = Paint()
      ..shader = RadialGradient(
        colors: [auraRight, auraRight.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: rightCenter, radius: rightRadius));
    canvas.drawCircle(rightCenter, rightRadius, rightPaint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) {
    return oldDelegate.isSplash != isSplash ||
        oldDelegate.isDark != isDark ||
        oldDelegate.auraLeft != auraLeft ||
        oldDelegate.auraRight != auraRight;
  }
}
