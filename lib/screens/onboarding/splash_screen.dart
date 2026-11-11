import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_motion.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _advanceTimer;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _advanceTimer = Timer(const Duration(milliseconds: 1650), _finish);
  }

  void _finish() {
    if (!mounted) return;
    SastaScope.read(context).completeSplash();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      onTap: _finish,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: SastaBackground(
          isSplash: true,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SastaSpace.page,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            const FloatBob(
                              amplitude: 8,
                              child: SplashHeroArtwork(),
                            ),
                            const SizedBox(height: 18),
                            FadeUp(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  text: TextSpan(
                                    style: SastaText.display(
                                      context,
                                      size: 68,
                                      color: palette.ink,
                                    ),
                                    children: const [
                                      TextSpan(text: 'sasta'),
                                      TextSpan(
                                        text: '.',
                                        style: TextStyle(
                                          color: SastaColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FadeUp(
                              delay: const Duration(milliseconds: 90),
                              child: Text(
                                'Search once. Compare everywhere.',
                                textAlign: TextAlign.center,
                                style: SastaText.body(
                                  context,
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (!disabled)
                              AnimatedBuilder(
                                animation: _dotsController,
                                builder: (context, _) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(3, (i) {
                                      final phase =
                                          (_dotsController.value - i * 0.2)
                                              .clamp(0.0, 1.0);
                                      final wave = 0.5 +
                                          0.5 *
                                              Curves.easeInOut.transform(
                                                phase < 0.5
                                                    ? phase * 2
                                                    : (1 - phase) * 2,
                                              );
                                      final colors = [
                                        SastaColors.blinkit,
                                        SastaColors.zepto,
                                        SastaColors.instamart,
                                      ];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        child: Transform.scale(
                                          scale: 0.85 + wave * 0.35,
                                          child: Opacity(
                                            opacity: 0.45 + wave * 0.55,
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: colors[i],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
