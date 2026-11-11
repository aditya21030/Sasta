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
import '../../widgets/sasta_sheets.dart';

class ManageMembershipScreen extends StatelessWidget {
  const ManageMembershipScreen({super.key});

  Future<void> _confirmCancel(
    BuildContext context,
    SastaAppState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Sasta+?',
          style: SastaText.display(ctx, size: 22),
        ),
        content: Text(
          'You will return to the Free plan with 7-day price history and 3 active alerts.',
          style: SastaText.muted(ctx, size: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Sasta+'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: ctx.sasta.dangerText,
            ),
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      state.cancelSubscription();
      showSastaToast(context, 'Sasta+ subscription cancelled.');
    }
  }

  void _showBenefitsSheet(BuildContext context) {
    showSastaSheet(
      context: context,
      builder: (ctx) {
        final palette = ctx.sasta;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sasta+ benefits',
                style: SastaText.display(ctx, size: 24),
              ),
              const SizedBox(height: 10),
              SastaCard(
                color: palette.lavender,
                shadow: false,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(label: 'Price history', value: '90 days'),
                    SizedBox(height: 10),
                    _DetailLine(label: 'Price alerts', value: 'Unlimited'),
                    SizedBox(height: 10),
                    _DetailLine(label: 'Live searches', value: 'Unlimited'),
                    SizedBox(height: 10),
                    _DetailLine(label: 'Basket splits', value: 'All stores'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SastaPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final isActive = state.isPlusActive;
    final isYearly = state.planType == SastaPlanType.yearly;
    final latestInvoice = state.invoices.firstOrNull;
    final planSubtitle = switch (state.planType) {
      SastaPlanType.free => 'Free plan',
      SastaPlanType.monthly => 'Monthly plan',
      SastaPlanType.yearly => 'Yearly plan',
    };
    final priceText = switch (state.planType) {
      SastaPlanType.free => '₹0 / month',
      SastaPlanType.monthly => '₹49 / month',
      SastaPlanType.yearly => '₹399 / year',
    };
    final renewalText = !isActive
        ? '—'
        : isYearly
            ? '8 Nov 2027'
            : '8 Dec 2026';

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
                const SastaHeaderBar(title: 'Manage Sasta+'),
                const SizedBox(height: 18),
                FadeUp(
                  child: SastaCard(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SastaColors.promoDarkStart,
                        SastaColors.promoDarkEnd,
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SastaTag(
                                label: isActive ? 'Active' : 'Free tier',
                                backgroundColor: isActive
                                    ? const Color(0xFF1F7A4D)
                                    : Colors.white24,
                                textColor: Colors.white,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sasta+',
                                style: SastaText.display(
                                  context,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                planSubtitle,
                                style: SastaText.body(
                                  context,
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FloatBob(
                          amplitude: 5,
                          child: SastaMascot(
                            size: 74,
                            color: SastaColors.gold,
                            expression: isActive
                                ? MascotExpression.joy
                                : MascotExpression.happy,
                            hasCrown: isActive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SastaCard(
                  color: palette.lavender,
                  shadow: false,
                  child: Column(
                    children: [
                      _DetailLine(
                        label: 'Started',
                        value: isActive ? '8 Nov 2026' : 'Free tier',
                      ),
                      const SizedBox(height: 10),
                      _DetailLine(label: 'Next renewal', value: renewalText),
                      const SizedBox(height: 10),
                      _DetailLine(label: 'Price', value: priceText),
                      const SizedBox(height: 10),
                      _DetailLine(
                        label: 'Payment',
                        value: isActive
                            ? (latestInvoice != null
                                ? 'Paid · ${latestInvoice.txnCode}'
                                : 'Paid')
                            : 'No charge',
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 14),
                  SastaCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-renew',
                                style: SastaText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                state.autoRenew
                                    ? 'Renews automatically on $renewalText'
                                    : 'Turned off · expires $renewalText',
                                style: SastaText.muted(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                        SastaSwitch(
                          value: state.autoRenew,
                          semanticsLabel: 'Auto-renew',
                          onChanged: state.toggleAutoRenew,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SastaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      SastaListRow(
                        title: isActive
                            ? 'Change or upgrade plan'
                            : 'See Sasta+ plans',
                        icon: Icons.workspace_premium_outlined,
                        badgeBackground: palette.butter,
                        badgeForeground: palette.warningText,
                        onTap: () => SastaNav.push(
                          context,
                          SastaRouteNames.plusPlans,
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Restore purchases',
                        icon: Icons.restore_rounded,
                        badgeBackground: palette.sky,
                        badgeForeground: palette.skyText,
                        onTap: () => showSastaToast(
                          context,
                          isActive
                              ? 'Your Sasta+ membership is synced.'
                              : 'No previous Sasta+ purchases found.',
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'View benefits',
                        icon: Icons.auto_awesome_outlined,
                        badgeBackground: palette.lavender,
                        badgeForeground: palette.lavenderText,
                        onTap: () => _showBenefitsSheet(context),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Subscription history',
                        icon: Icons.receipt_long_outlined,
                        badgeBackground: palette.mint,
                        badgeForeground: palette.successText,
                        onTap: () => SastaNav.push(
                          context,
                          SastaRouteNames.plusHistory,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SastaCard(
                  color: palette.butter,
                  shadow: false,
                  child: Text(
                    isActive
                        ? 'Turn off auto-renew to avoid future charges while keeping Sasta+ until $renewalText, or cancel anytime to return to the Free plan immediately.'
                        : 'Upgrade anytime to unlock 90-day price history and unlimited live price checks.',
                    style: SastaText.body(
                      context,
                      size: 13,
                      weight: FontWeight.w600,
                      color: palette.warningText,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (isActive)
                  SastaOutlineButton(
                    label: 'Cancel subscription',
                    borderColor: palette.dangerText,
                    textColor: palette.dangerText,
                    onPressed: () => _confirmCancel(context, state),
                  )
                else
                  SastaPrimaryButton(
                    label: 'Upgrade to Sasta+',
                    onPressed: () => SastaNav.push(
                      context,
                      SastaRouteNames.plusPlans,
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: SastaText.muted(context, size: 13)),
        ),
        Text(
          value,
          style: SastaText.body(
            context,
            size: 14,
            weight: FontWeight.w700,
            tabular: true,
          ),
        ),
      ],
    );
  }
}
