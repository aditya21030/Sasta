import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class PaySuccessScreen extends StatefulWidget {
  const PaySuccessScreen({super.key, this.planType = SastaPlanType.yearly});

  final SastaPlanType planType;

  @override
  State<PaySuccessScreen> createState() => _PaySuccessScreenState();
}

class _PaySuccessScreenState extends State<PaySuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _backToHome() {
    SastaScope.read(context).setActiveTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isYearly = widget.planType != SastaPlanType.monthly;
    final planName = isYearly ? 'Sasta+ Yearly' : 'Sasta+ Monthly';
    final nextRenewal = isYearly ? '8 Nov 2027' : '8 Dec 2026';

    return Scaffold(
      body: SastaBackground(
        child: Stack(
          children: [
            if (!disabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiCtrl,
                    builder: (context, _) => CustomPaint(
                      painter: _ConfettiPainter(_confettiCtrl.value),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  20,
                  SastaSpace.page,
                  SastaSpace.bottomMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    FadeUp(
                      child: Column(
                        children: [
                          FloatBob(
                            amplitude: 6,
                            child: SastaMascot(
                              size: 120,
                              color: SastaColors.gold,
                              expression: MascotExpression.joy,
                              hasCrown: true,
                              haloColor: palette.butter,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'You’re on Sasta+!',
                            style: SastaText.display(context, size: 36),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Payment received. Your premium tools are ready.',
                            style: SastaText.muted(context, size: 15),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeUp(
                      delay: const Duration(milliseconds: 90),
                      child: SastaCard(
                        color: palette.lavender,
                        shadow: false,
                        child: Column(
                          children: [
                            _InfoRow(label: 'Plan', value: planName),
                            const SizedBox(height: 10),
                            const _InfoRow(
                              label: 'Started',
                              value: '8 Nov 2026',
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              label: 'Next renewal',
                              value: nextRenewal,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    SastaPrimaryButton(
                      label: 'Start using Sasta+',
                      onPressed: _backToHome,
                    ),
                    const SizedBox(height: 10),
                    SastaOutlineButton(
                      label: 'View membership',
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(SastaRouteNames.plusManage),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: _backToHome,
                        child: Text(
                          'Back to Home',
                          style: SastaText.body(
                            context,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: SastaText.muted(context, size: 14)),
        ),
        Text(
          value,
          style: SastaText.body(
            context,
            size: 14,
            weight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.progress);
  final double progress;

  static const _colors = [
    SastaColors.flipkartMinutes,
    SastaColors.sparkleOrange,
    SastaColors.gold,
    SastaColors.zepto,
    Color(0xFFFF5A8A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 18; i++) {
      final seed = i * 0.6180339;
      final x = ((seed * 1.7 + math.sin(progress * math.pi * 2 + i) * 0.04) %
              1.0) *
          size.width;
      final y = ((seed + progress) % 1.0) * (size.height * 0.68);
      paint.color = _colors[i % _colors.length].withValues(alpha: 0.78);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * math.pi * 2 + i * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -8, 8, 16),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
