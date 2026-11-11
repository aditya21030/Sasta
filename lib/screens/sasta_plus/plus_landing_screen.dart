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

class PlusLandingScreen extends StatefulWidget {
  const PlusLandingScreen({super.key});

  @override
  State<PlusLandingScreen> createState() => _PlusLandingScreenState();
}

class _PlusLandingScreenState extends State<PlusLandingScreen> {
  SastaPlanType _selectedPlan = SastaPlanType.yearly;

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final planLabel = switch (state.planType) {
      SastaPlanType.free => 'Your plan: Free',
      SastaPlanType.monthly => 'Your plan: Sasta+ Monthly',
      SastaPlanType.yearly => 'Your plan: Sasta+ Yearly',
    };

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SastaHeaderBar(),
                const SizedBox(height: 12),
                FadeUp(
                  child: Column(
                    children: [
                      FloatBob(
                        amplitude: 6,
                        child: SastaMascot(
                          size: 112,
                          color: SastaColors.gold,
                          expression: MascotExpression.joy,
                          hasCrown: true,
                          haloColor: palette.butter,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sasta+',
                        style: SastaText.display(context, size: 52),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save smarter, every week.',
                        style: SastaText.muted(context, size: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SastaTag(
                        label: planLabel,
                        backgroundColor: state.isPlusActive
                            ? palette.mint
                            : palette.lavender,
                        textColor: state.isPlusActive
                            ? palette.successText
                            : palette.lavenderText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FadeUp(
                  delay: const Duration(milliseconds: 60),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                    children: [
                      _BenefitCard(
                        color: palette.sky,
                        iconBg: Colors.white.withValues(alpha: 0.7),
                        iconColor: palette.skyText,
                        icon: Icons.show_chart_rounded,
                        title: 'Advanced price tracking',
                        subtitle: 'Full price history & more drop alerts',
                      ),
                      _BenefitCard(
                        color: palette.mint,
                        iconBg: Colors.white.withValues(alpha: 0.7),
                        iconColor: palette.successText,
                        icon: Icons.call_split_rounded,
                        title: 'Smarter baskets',
                        subtitle: 'Compare more split-store options',
                      ),
                      _BenefitCard(
                        color: palette.pink,
                        iconBg: Colors.white.withValues(alpha: 0.7),
                        iconColor: palette.pinkText,
                        icon: Icons.auto_awesome_rounded,
                        title: 'Personal nudges',
                        subtitle: 'Best-time-to-buy cues on staples',
                      ),
                      _BenefitCard(
                        color: palette.butter,
                        iconBg: Colors.white.withValues(alpha: 0.7),
                        iconColor: palette.warningText,
                        icon: Icons.savings_outlined,
                        title: 'Savings insights',
                        subtitle: 'Detailed weekly & monthly breakdowns',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeUp(
                  delay: const Duration(milliseconds: 110),
                  child: SastaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                'Free vs Premium',
                                style: SastaText.display(context, size: 18),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Free',
                                textAlign: TextAlign.center,
                                style: SastaText.eyebrow(context),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Sasta+',
                                textAlign: TextAlign.center,
                                style: SastaText.eyebrow(
                                  context,
                                  color: SastaColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const _ComparisonMatrixRow(
                          feature: 'Price comparison',
                          freeVal: 'Included',
                          plusVal: 'Included',
                        ),
                        const _ComparisonMatrixRow(
                          feature: 'Price history',
                          freeVal: '7 days',
                          plusVal: 'Full',
                        ),
                        const _ComparisonMatrixRow(
                          feature: 'Price alerts',
                          freeVal: '3',
                          plusVal: 'More',
                        ),
                        const _ComparisonMatrixRow(
                          feature: 'Split-basket options',
                          freeVal: '1',
                          plusVal: 'Many',
                        ),
                        const _ComparisonMatrixRow(
                          feature: 'Savings report',
                          freeVal: 'Basic',
                          plusVal: 'Detailed',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeUp(
                  delay: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CompactPlanTile(
                          title: 'Monthly',
                          price: '₹49',
                          caption: 'Billed monthly',
                          selected: _selectedPlan == SastaPlanType.monthly,
                          onTap: () => setState(
                            () => _selectedPlan = SastaPlanType.monthly,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactPlanTile(
                          title: 'Yearly',
                          price: '₹399',
                          caption: 'About ₹33 / mo',
                          badge: 'Save 32%',
                          selected: _selectedPlan == SastaPlanType.yearly,
                          onTap: () => setState(
                            () => _selectedPlan = SastaPlanType.yearly,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Sample pricing · Cancel anytime',
                    style: SastaText.muted(context, size: 12),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.isPlusActive) ...[
                  SastaPrimaryButton(
                    label: 'Manage membership',
                    onPressed: () => SastaNav.push(
                      context,
                      SastaRouteNames.plusManage,
                    ),
                  ),
                ] else ...[
                  SastaPrimaryButton(
                    label: 'Subscribe to Sasta+',
                    onPressed: () => SastaNav.push(
                      context,
                      SastaRouteNames.plusPlans,
                      arguments: CheckoutArgs(planType: _selectedPlan),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => showSastaToast(
                      context,
                      state.isPlusActive
                          ? 'Your Sasta+ membership is active on this account.'
                          : 'No previous Sasta+ purchases found.',
                    ),
                    child: Text(
                      'Restore purchases',
                      style: SastaText.body(
                        context,
                        size: 14,
                        weight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.color,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      color: color,
      shadow: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.isDark
                  ? palette.surface.withValues(alpha: 0.7)
                  : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const Spacer(),
          Text(
            title,
            style: SastaText.body(
              context,
              size: 14,
              weight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: SastaText.muted(context, size: 12, height: 1.25),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ComparisonMatrixRow extends StatelessWidget {
  const _ComparisonMatrixRow({
    required this.feature,
    required this.freeVal,
    required this.plusVal,
    this.isLast = false,
  });

  final String feature;
  final String freeVal;
  final String plusVal;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  feature,
                  style: SastaText.body(
                    context,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  freeVal,
                  textAlign: TextAlign.center,
                  style: SastaText.muted(context, size: 12),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  plusVal,
                  textAlign: TextAlign.center,
                  style: SastaText.body(
                    context,
                    size: 12,
                    weight: FontWeight.w800,
                    color: palette.successText,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: palette.divider),
      ],
    );
  }
}

class _CompactPlanTile extends StatelessWidget {
  const _CompactPlanTile({
    required this.title,
    required this.price,
    required this.caption,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String caption;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      onTap: onTap,
      color: selected ? palette.lavender : palette.surface,
      border: Border.all(
        color: selected ? palette.primaryCtaBg : palette.divider,
        width: selected ? 2 : 1.2,
      ),
      shadow: false,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: SastaText.body(
                    context,
                    size: 14,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              if (badge != null)
                SastaTag(
                  label: badge!,
                  backgroundColor: SastaColors.gold,
                  textColor: SastaColors.ink,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: SastaText.display(context, size: 28),
          ),
          const SizedBox(height: 2),
          Text(caption, style: SastaText.muted(context, size: 12)),
        ],
      ),
    );
  }
}
