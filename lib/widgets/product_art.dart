import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/sasta_tokens.dart';
import 'sasta_mascot.dart';

/// Crisp pastel-framed flat-vector product illustration (zero emoji).
class ProductArtTile extends StatelessWidget {
  const ProductArtTile({
    super.key,
    required this.kind,
    required this.pastel,
    this.size = 56,
    this.borderRadius,
  });

  final ProductArtKind kind;
  final SastaPastel pastel;
  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bg = context.sasta.pastel(pastel);
    final radius = borderRadius ?? (size * 0.32);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.68),
        painter: ProductArtPainter(kind: kind),
      ),
    );
  }
}

class ProductArtPainter extends CustomPainter {
  const ProductArtPainter({required this.kind});

  final ProductArtKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    // Normalized 64x64 coordinate space matching HTML SVGs
    canvas.scale(s / 64.0);

    switch (kind) {
      case ProductArtKind.milk:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 18, 28, 36),
            const Radius.circular(4),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18, 18)
            ..lineTo(24, 10)
            ..lineTo(40, 10)
            ..lineTo(46, 18)
            ..close(),
          Paint()..color = const Color(0xFFDCEEFF),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(25, 6, 14, 5),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF4FB3FF),
        );
        canvas.drawRect(
          const Rect.fromLTWH(18, 28, 28, 13),
          Paint()..color = const Color(0xFF3E9DFF),
        );
        canvas.drawCircle(
          const Offset(32, 35),
          4.5,
          Paint()..color = Colors.white,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(16, 54, 32, 4),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.black.withValues(alpha: 0.08),
        );
      case ProductArtKind.bread:
        canvas.drawCircle(
          const Offset(24, 24),
          11,
          Paint()..color = const Color(0xFFB86B2B),
        );
        canvas.drawCircle(
          const Offset(40, 24),
          11,
          Paint()..color = const Color(0xFFB86B2B),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(15, 22, 34, 28),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFB86B2B),
        );
        canvas.drawCircle(
          const Offset(25, 26),
          8,
          Paint()..color = const Color(0xFFF3CFA0),
        );
        canvas.drawCircle(
          const Offset(39, 26),
          8,
          Paint()..color = const Color(0xFFF3CFA0),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(19, 26, 26, 21),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFFF3CFA0),
        );
      case ProductArtKind.eggs:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 30, 48, 22),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFFE0C89B),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 28, 44, 14),
            const Radius.circular(7),
          ),
          Paint()..color = const Color(0xFFF3DFBA),
        );
        const eggXs = [20.0, 32.0, 44.0];
        for (final x in eggXs) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, 26), width: 11, height: 15),
            Paint()..color = const Color(0xFFFFF8EC),
          );
        }
      case ProductArtKind.rice:
      case ProductArtKind.atta:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 12, 36, 42),
            const Radius.circular(10),
          ),
          Paint()..color = kind == ProductArtKind.atta
              ? const Color(0xFFFFF1D6)
              : const Color(0xFFF7EEDB),
        );
        canvas.drawRect(
          const Rect.fromLTWH(14, 23, 36, 12),
          Paint()..color = kind == ProductArtKind.atta
              ? const Color(0xFFFF7A1A)
              : const Color(0xFFE05542),
        );
        canvas.drawCircle(
          const Offset(32, 42),
          6,
          Paint()..color = const Color(0xFFF6BA3D),
        );
      case ProductArtKind.curd:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 20, 40, 6),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFFF6D8A),
        );
        canvas.drawPath(
          Path()
            ..moveTo(15, 26)
            ..lineTo(49, 26)
            ..lineTo(44, 52)
            ..lineTo(20, 52)
            ..close(),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          const Rect.fromLTWH(17, 34, 30, 8),
          Paint()..color = const Color(0xFFFFB2C2),
        );
      case ProductArtKind.oil:
      case ProductArtKind.beverage:
        final liquidColor = kind == ProductArtKind.beverage
            ? const Color(0xFF7B4829)
            : const Color(0xFFFFD84D);
        final capColor = kind == ProductArtKind.beverage
            ? const Color(0xFFFF8A3D)
            : const Color(0xFFE84C3D);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 20, 24, 34),
            const Radius.circular(7),
          ),
          Paint()..color = liquidColor,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(25, 8, 14, 7),
            const Radius.circular(3),
          ),
          Paint()..color = capColor,
        );
        canvas.drawRect(
          const Rect.fromLTWH(20, 31, 24, 11),
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.drawCircle(
          const Offset(32, 36.5),
          4,
          Paint()..color = const Color(0xFFE5560A),
        );
      case ProductArtKind.butter:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 22, 44, 24),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFFFD21F),
        );
        canvas.drawRect(
          const Rect.fromLTWH(10, 30, 44, 8),
          Paint()..color = const Color(0xFF2370D8),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 17, 28, 6),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFFFE570),
        );
      case ProductArtKind.salt:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(15, 10, 34, 44),
            const Radius.circular(8),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawRect(
          const Rect.fromLTWH(15, 22, 34, 15),
          Paint()..color = const Color(0xFF1F6FB5),
        );
        canvas.drawCircle(
          const Offset(32, 29.5),
          5,
          Paint()..color = Colors.white,
        );
      case ProductArtKind.noodles:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 14, 44, 36),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFFFFD21F),
        );
        canvas.drawRect(
          const Rect.fromLTWH(14, 22, 36, 14),
          Paint()..color = const Color(0xFFE03A2F),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 40, 24, 5),
            const Radius.circular(2.5),
          ),
          Paint()..color = Colors.white,
        );
      case ProductArtKind.tea:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 12, 36, 42),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF3E296E),
        );
        canvas.drawCircle(
          const Offset(32, 31),
          9,
          Paint()..color = const Color(0xFFFFD21F),
        );
        canvas.drawCircle(
          const Offset(32, 31),
          5,
          Paint()..color = const Color(0xFF2FA162),
        );
      case ProductArtKind.coffee:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 18, 28, 36),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF5A3422),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(21, 9, 22, 9),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFFD93B2B),
        );
        canvas.drawRect(
          const Rect.fromLTWH(18, 29, 28, 12),
          Paint()..color = const Color(0xFFF6DFB8),
        );
      case ProductArtKind.biscuits:
      case ProductArtKind.snacks:
        canvas.drawCircle(
          const Offset(26, 34),
          14,
          Paint()..color = const Color(0xFFE6A24E),
        );
        canvas.drawCircle(
          const Offset(39, 28),
          13,
          Paint()..color = const Color(0xFFF4B968),
        );
        final dot = Paint()..color = const Color(0xFF9C5D22);
        canvas.drawCircle(const Offset(35, 24), 1.8, dot);
        canvas.drawCircle(const Offset(43, 25), 1.8, dot);
        canvas.drawCircle(const Offset(39, 31), 1.8, dot);
      case ProductArtKind.veg:
        canvas.drawCircle(
          const Offset(32, 36),
          16,
          Paint()..color = const Color(0xFFE8473C),
        );
        canvas.drawCircle(
          const Offset(26, 30),
          4.5,
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
        canvas.drawPath(
          Path()
            ..moveTo(32, 21)
            ..quadraticBezierTo(24, 12, 20, 18)
            ..quadraticBezierTo(28, 23, 32, 21)
            ..quadraticBezierTo(40, 12, 44, 18)
            ..close(),
          Paint()..color = const Color(0xFF2EA458),
        );
      case ProductArtKind.detergent:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(13, 12, 38, 42),
            const Radius.circular(9),
          ),
          Paint()..color = const Color(0xFF1F6FB5),
        );
        canvas.drawCircle(
          const Offset(32, 33),
          10,
          Paint()..color = const Color(0xFFFFD21F),
        );
        canvas.drawCircle(
          const Offset(32, 33),
          6,
          Paint()..color = const Color(0xFFFF6A00),
        );
      case ProductArtKind.iceCream:
      case ProductArtKind.babyCare:
      case ProductArtKind.meat:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(14, 18, 36, 30),
            const Radius.circular(10),
          ),
          Paint()..color = const Color(0xFFFF8A9D),
        );
        canvas.drawCircle(
          const Offset(32, 33),
          8,
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ProductArtPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// Crisp 2.3px-stroke vector icons for categories, nav, and UI tiles.
class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 22,
  });

  final CategoryIconKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconData = switch (kind) {
      CategoryIconKind.milk => Icons.local_drink_outlined,
      CategoryIconKind.apple => Icons.eco_outlined,
      CategoryIconKind.cookie => Icons.cookie_outlined,
      CategoryIconKind.cup => Icons.coffee_outlined,
      CategoryIconKind.grain => Icons.grain_outlined,
      CategoryIconKind.bottle => Icons.water_drop_outlined,
      CategoryIconKind.sparkle => Icons.auto_awesome_outlined,
      CategoryIconKind.spray => Icons.cleaning_services_outlined,
      CategoryIconKind.heart => Icons.child_care_outlined,
      CategoryIconKind.snowflake => Icons.ac_unit_rounded,
      CategoryIconKind.croissant => Icons.bakery_dining_outlined,
      CategoryIconKind.fish => Icons.set_meal_outlined,
    };
    return Icon(iconData, size: size, color: color);
  }
}

/// Pulsing orange map pin with yellow smiling mascot for the Pincode screen.
class PincodePinIllustration extends StatefulWidget {
  const PincodePinIllustration({super.key, this.size = 210});
  final double size;

  @override
  State<PincodePinIllustration> createState() => _PincodePinIllustrationState();
}

class _PincodePinIllustrationState extends State<PincodePinIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final palette = context.sasta;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size * 0.88,
            height: widget.size * 0.88,
            decoration: BoxDecoration(
              color: palette.peach,
              shape: BoxShape.circle,
            ),
          ),
          if (!disabled)
            AnimatedBuilder(
              animation: _ripple,
              builder: (context, _) {
                final v = Curves.easeOut.transform(_ripple.value);
                return Transform.scale(
                  scale: 0.5 + v * 0.72,
                  child: Opacity(
                    opacity: (1 - v) * 0.45,
                    child: Container(
                      width: widget.size * 0.76,
                      height: widget.size * 0.76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SastaColors.instamart,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          CustomPaint(
            size: Size(widget.size * 0.62, widget.size * 0.76),
            painter: const _MapPinPainter(),
          ),
          Transform.translate(
            offset: Offset(0, -widget.size * 0.065),
            child: const SastaMascot(
              size: 76,
              color: SastaColors.gold,
              expression: MascotExpression.happy,
              animateBlink: true,
            ),
          ),
          Positioned(
            right: widget.size * 0.08,
            top: widget.size * 0.14,
            child: const SastaSparkle(size: 20, color: SastaColors.zepto),
          ),
          Positioned(
            left: widget.size * 0.1,
            bottom: widget.size * 0.24,
            child: const SastaSparkle(size: 16, color: SastaColors.sparkleOrange),
          ),
        ],
      ),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  const _MapPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    // Smooth teardrop pin silhouette
    final r = w * 0.43;
    final pinCenter = Offset(cx, r + h * 0.03);
    final betterPath = Path()
      ..addOval(Rect.fromCircle(center: pinCenter, radius: r))
      ..moveTo(cx - r * 0.85, pinCenter.dy + r * 0.48)
      ..lineTo(cx, h * 0.96)
      ..lineTo(cx + r * 0.85, pinCenter.dy + r * 0.48)
      ..close();

    canvas.drawPath(betterPath, Paint()..color = SastaColors.accent);
    canvas.drawCircle(
      pinCenter,
      r * 0.72,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Warm orange shopping basket with peeking happy yellow mascot.
class BasketHeroIllustration extends StatelessWidget {
  const BasketHeroIllustration({super.key, this.size = 180});
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: BoxDecoration(
              color: palette.peach,
              shape: BoxShape.circle,
            ),
          ),
          Transform.translate(
            offset: Offset(0, -size * 0.09),
            child: SastaMascot(
              size: size * 0.42,
              color: SastaColors.gold,
              expression: MascotExpression.joy,
            ),
          ),
          Transform.translate(
            offset: Offset(0, size * 0.14),
            child: CustomPaint(
              size: Size(size * 0.64, size * 0.38),
              painter: const _BasketBodyPainter(),
            ),
          ),
          Positioned(
            right: size * 0.08,
            top: size * 0.12,
            child: const SastaSparkle(size: 18, color: SastaColors.zepto),
          ),
          Positioned(
            left: size * 0.1,
            top: size * 0.24,
            child: const SastaSparkle(size: 14, color: SastaColors.sparkleOrange),
          ),
        ],
      ),
    );
  }
}

class _BasketBodyPainter extends CustomPainter {
  const _BasketBodyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final trap = Path()
      ..moveTo(w * 0.04, h * 0.22)
      ..lineTo(w * 0.96, h * 0.22)
      ..lineTo(w * 0.84, h)
      ..lineTo(w * 0.16, h)
      ..close();
    canvas.drawPath(trap, Paint()..color = SastaColors.accent);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, h * 0.08, w, h * 0.2),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFFF984A),
    );
    final rib = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final factor in [0.3, 0.5, 0.7]) {
      canvas.drawLine(
        Offset(w * factor, h * 0.42),
        Offset(w * factor, h * 0.84),
        rib,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Splash floating composition matching Splash.dc.html (yellow mascot + milk + bread + rotated ₹ badge).
class SplashHeroArtwork extends StatelessWidget {
  const SplashHeroArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SastaMascot(
            size: 132,
            color: SastaColors.gold,
            expression: MascotExpression.joy,
          ),
          Positioned(
            left: 16,
            top: 20,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: SastaShadows.float(context),
              ),
              padding: const EdgeInsets.all(8),
              child: const CustomPaint(
                painter: ProductArtPainter(kind: ProductArtKind.milk),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 24,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: SastaShadows.float(context),
              ),
              padding: const EdgeInsets.all(8),
              child: const CustomPaint(
                painter: ProductArtPainter(kind: ProductArtKind.bread),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 32,
            child: Transform.rotate(
              angle: -10 * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: SastaShadows.float(context),
                ),
                child: const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: SastaColors.accentOrange,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 26,
            bottom: 34,
            child: SastaSparkle(size: 20, color: SastaColors.sparkleOrange),
          ),
          const Positioned(
            top: 8,
            right: 76,
            child: SastaSparkle(size: 14, color: SastaColors.zepto),
          ),
          const Positioned(
            bottom: 12,
            left: 84,
            child: SastaSparkle(size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
