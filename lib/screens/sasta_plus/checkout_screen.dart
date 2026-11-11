import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.planType});

  final SastaPlanType planType;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'upi';
  bool _acceptedTerms = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final state = SastaScope.read(context);
    final isYearly = widget.planType == SastaPlanType.yearly;
    final planName = isYearly ? 'Sasta+ Yearly' : 'Sasta+ Monthly';
    final duration = isYearly ? '12 months' : '1 month';
    final amount = isYearly ? 399 : 49;

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
                const SastaHeaderBar(title: 'Checkout'),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        SastaCard(
                          color: palette.lavender,
                          shadow: false,
                          child: Column(
                            children: [
                              _SummaryRow(label: 'Plan', value: planName),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Duration', value: duration),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Price', value: '₹$amount'),
                              const SizedBox(height: 10),
                              const _SummaryRow(
                                label: 'Taxes',
                                value: 'Included',
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  height: 1,
                                  color: palette.divider,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total payable',
                                      style: SastaText.body(
                                        context,
                                        size: 16,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹$amount',
                                    style: SastaText.display(
                                      context,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'PAYMENT METHOD',
                          style: SastaText.eyebrow(context),
                        ),
                        const SizedBox(height: 10),
                        _PaymentMethodTile(
                          title: 'UPI',
                          subtitle: 'Pay with any UPI app',
                          icon: Icons.qr_code_2_rounded,
                          badgeBg: palette.mint,
                          badgeFg: palette.successText,
                          selected: _paymentMethod == 'upi',
                          onTap: () => setState(() => _paymentMethod = 'upi'),
                        ),
                        const SizedBox(height: 10),
                        _PaymentMethodTile(
                          title: 'Card',
                          subtitle: 'Debit or credit card',
                          icon: Icons.credit_card_rounded,
                          badgeBg: palette.sky,
                          badgeFg: palette.skyText,
                          selected: _paymentMethod == 'card',
                          onTap: () => setState(() => _paymentMethod = 'card'),
                        ),
                        const SizedBox(height: 10),
                        _PaymentMethodTile(
                          title: 'Net banking',
                          subtitle: 'Choose your bank',
                          icon: Icons.account_balance_rounded,
                          badgeBg: palette.peach,
                          badgeFg: palette.linkText,
                          selected: _paymentMethod == 'netbanking',
                          onTap: () =>
                              setState(() => _paymentMethod = 'netbanking'),
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: () => setState(
                            () => _acceptedTerms = !_acceptedTerms,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _acceptedTerms
                                        ? palette.primaryCtaBg
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _acceptedTerms
                                          ? palette.primaryCtaBg
                                          : palette.muted,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: _acceptedTerms
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: palette.primaryCtaFg,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'I agree to the Sasta+ subscription terms and sample billing schedule.',
                                    style: SastaText.muted(context, size: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SastaPrimaryButton(
                  label: 'Confirm & pay ₹$amount',
                  onPressed: _acceptedTerms
                      ? () {
                          state.subscribeToPlan(widget.planType);
                          Navigator.of(context).pushReplacementNamed(
                            SastaRouteNames.plusSuccess,
                            arguments: CheckoutArgs(planType: widget.planType),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Cancel checkout',
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
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
            weight: FontWeight.w700,
            tabular: true,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeBg,
    required this.badgeFg,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeBg;
  final Color badgeFg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      onTap: onTap,
      border: Border.all(
        color: selected ? palette.primaryCtaBg : palette.divider,
        width: selected ? 2 : 1,
      ),
      shadow: selected,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: badgeFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SastaText.body(
                    context,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: SastaText.muted(context, size: 13)),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primaryCtaFg,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
