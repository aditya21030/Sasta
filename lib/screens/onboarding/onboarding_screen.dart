import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _slides = [
    (
      title: 'Search once.\nCompare everywhere.',
      subtitle:
          'Check Blinkit, Zepto, Swiggy Instamart and Flipkart Minutes together before you buy.',
    ),
    (
      title: 'One basket.\nSmartest choice.',
      subtitle:
          'See which single app costs least for your whole list, or mix stores when it saves extra.',
    ),
    (
      title: 'Catch price drops.\nSpend less daily.',
      subtitle:
          'Follow simple 30-day price charts and get notified when everyday essentials drop.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_pageIndex < _slides.length - 1) {
      _pageController.animateToPage(
        _pageIndex + 1,
        duration: const Duration(milliseconds: 350),
        curve: SastaMotion.curve,
      );
    } else {
      SastaScope.read(context).completeOnboarding();
    }
  }

  void _skip() {
    SastaScope.read(context).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, 44),
                      foregroundColor: palette.muted,
                    ),
                    child: Text(
                      'Skip',
                      style: SastaText.body(
                        context,
                        size: 15,
                        weight: FontWeight.w700,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: _OnboardingOrb(stepIndex: index)),
                                  const SizedBox(height: 28),
                                  Text(
                                    slide.title,
                                    style: SastaText.display(context, size: 35),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    slide.subtitle,
                                    style: SastaText.muted(
                                      context,
                                      size: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_slides.length, (i) {
                    final active = i == _pageIndex;
                    return AnimatedContainer(
                      duration: SastaMotion.fast,
                      margin: const EdgeInsets.only(right: 8),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? palette.ink : SastaColors.mutedGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SastaPrimaryButton(
                  label: _pageIndex == _slides.length - 1
                      ? 'Get started ↗'
                      : 'Next ↗',
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingOrb extends StatelessWidget {
  const _OnboardingOrb({required this.stepIndex});
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 310,
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: palette.lavender,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: palette.isDark ? palette.surface : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          if (stepIndex == 0) ...[
            const FloatBob(
              amplitude: 6,
              child: SastaMascot(
                size: 112,
                color: SastaColors.gold,
                expression: MascotExpression.joy,
              ),
            ),
            const Positioned(
              left: 10,
              top: 32,
              child: _OrbitRetailerBadge(
                retailer: RetailerId.zepto,
                price: '₹27',
              ),
            ),
            const Positioned(
              right: 8,
              top: 28,
              child: _OrbitRetailerBadge(
                retailer: RetailerId.instamart,
                price: '₹26',
              ),
            ),
            const Positioned(
              left: 6,
              bottom: 34,
              child: _OrbitRetailerBadge(
                retailer: RetailerId.flipkartMinutes,
                price: '₹29',
              ),
            ),
            const Positioned(
              right: 12,
              bottom: 38,
              child: _OrbitRetailerBadge(
                retailer: RetailerId.blinkit,
                price: '₹28',
              ),
            ),
            const Positioned(
              right: 76,
              top: 16,
              child: SastaSparkle(size: 18, color: SastaColors.sparkleOrange),
            ),
            const Positioned(
              left: 64,
              bottom: 18,
              child: SastaSparkle(size: 14, color: SastaColors.zepto),
            ),
          ] else if (stepIndex == 1) ...[
            const FloatBob(
              amplitude: 6,
              child: BasketHeroIllustration(size: 190),
            ),
            Positioned(
              right: 14,
              bottom: 42,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.ink,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: SastaShadows.float(context),
                ),
                child: Text(
                  'Save ~₹8+',
                  style: SastaText.body(
                    context,
                    size: 13,
                    weight: FontWeight.w800,
                    color: SastaColors.gold,
                  ),
                ),
              ),
            ),
          ] else ...[
            const FloatBob(
              amplitude: 6,
              child: SastaMascot(
                size: 112,
                color: SastaColors.zepto,
                expression: MascotExpression.joy,
                hasCrown: true,
              ),
            ),
            Positioned(
              left: 16,
              top: 44,
              child: SastaTag(
                label: '↓ ₹2 dropped',
                backgroundColor: palette.mint,
                textColor: palette.successText,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 48,
              child: SastaTag(
                label: 'Lowest in 30 days',
                backgroundColor: palette.butter,
                textColor: palette.warningText,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _OrbitRetailerBadge extends StatelessWidget {
  const _OrbitRetailerBadge({
    required this.retailer,
    required this.price,
  });

  final RetailerId retailer;
  final String price;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SastaShadows.float(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RetailerAvatar(retailer: retailer, size: 28),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                retailer.shortName,
                style: SastaText.body(
                  context,
                  size: 10,
                  weight: FontWeight.w700,
                  color: palette.muted,
                ),
              ),
              Text(
                price,
                style: SastaText.body(
                  context,
                  size: 13,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
