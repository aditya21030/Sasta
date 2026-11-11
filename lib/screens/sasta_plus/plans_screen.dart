import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_motion.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, this.initialPlan = SastaPlanType.yearly});

  final SastaPlanType initialPlan;

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late SastaPlanType _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan == SastaPlanType.free
        ? SastaPlanType.yearly
        : widget.initialPlan;
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
                const SastaHeaderBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        FadeUp(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pick a plan',
                                style: SastaText.display(context, size: 32),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Cancel any time from Manage membership.',
                                style: SastaText.muted(context, size: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        FadeUp(
                          delay: const Duration(milliseconds: 70),
                          child: _PlanOptionCard(
                            title: 'Monthly',
                            price: '₹49',
                            unit: '/ month',
                            description: 'Flexible month-to-month access to full price history and unlimited alerts.',
                            selected: _selectedPlan == SastaPlanType.monthly,
                            onTap: () => setState(
                              () => _selectedPlan = SastaPlanType.monthly,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeUp(
                          delay: const Duration(milliseconds: 120),
                          child: _PlanOptionCard(
                            title: 'Yearly',
                            price: '₹399',
                            unit: '/ year',
                            badge: 'Save 32%',
                            description: '12 months · about ₹33 a month. Our best-value grocery savings plan.',
                            selected: _selectedPlan == SastaPlanType.yearly,
                            onTap: () => setState(
                              () => _selectedPlan = SastaPlanType.yearly,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SastaCard(
                          color: palette.field,
                          shadow: false,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: palette.muted,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Sample pricing shown for preview. Plans renew automatically unless turned off before the renewal date.',
                                  style: SastaText.muted(context, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 18,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  SastaNav.push(context, SastaRouteNames.terms),
                              child: Text(
                                'Terms of subscription',
                                style: SastaText.body(
                                  context,
                                  size: 13,
                                  weight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => SastaNav.push(
                                context,
                                SastaRouteNames.privacy,
                              ),
                              child: Text(
                                'Privacy policy',
                                style: SastaText.body(
                                  context,
                                  size: 13,
                                  weight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SastaPrimaryButton(
                  label: 'Continue to checkout',
                  onPressed: () => SastaNav.push(
                    context,
                    SastaRouteNames.plusCheckout,
                    arguments: CheckoutArgs(planType: _selectedPlan),
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

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.title,
    required this.price,
    required this.unit,
    required this.description,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String unit;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Semantics(
      selected: selected,
      button: true,
      child: SastaCard(
        onTap: onTap,
        color: selected ? palette.lavender : palette.surface,
        border: Border.all(
          color: selected ? palette.primaryCtaBg : palette.divider,
          width: selected ? 2.2 : 1.2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? palette.primaryCtaBg : palette.muted,
                  width: 2,
                ),
                color: selected ? palette.primaryCtaBg : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.primaryCtaFg,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: SastaText.display(context, size: 22),
                      ),
                      if (badge != null)
                        SastaTag(
                          label: badge!,
                          backgroundColor: SastaColors.gold,
                          textColor: SastaColors.ink,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            price,
                            style: SastaText.display(context, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SastaText.muted(context, size: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: SastaText.muted(context, size: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
