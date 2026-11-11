import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_sheets.dart';

class SubHistoryScreen extends StatelessWidget {
  const SubHistoryScreen({super.key});

  void _showInvoiceSheet(
    BuildContext context,
    SubscriptionInvoice invoice,
  ) {
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
              Text('Invoice summary', style: SastaText.display(ctx, size: 24)),
              const SizedBox(height: 14),
              SastaCard(
                color: palette.lavender,
                shadow: false,
                child: Column(
                  children: [
                    _InvoiceRow(label: 'Plan', value: invoice.planName),
                    const SizedBox(height: 8),
                    _InvoiceRow(label: 'Date', value: invoice.dateLabel),
                    const SizedBox(height: 8),
                    _InvoiceRow(label: 'Reference', value: invoice.txnCode),
                    const SizedBox(height: 8),
                    _InvoiceRow(label: 'Status', value: invoice.status),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: palette.divider),
                    ),
                    _InvoiceRow(
                      label: 'Total (incl. taxes)',
                      value: '₹${invoice.amount}',
                      bold: true,
                    ),
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
                const SastaHeaderBar(title: 'Subscription history'),
                const SizedBox(height: 18),
                if (state.invoices.isEmpty)
                  SastaCard(
                    color: palette.field,
                    shadow: false,
                    child: Column(
                      children: [
                        const SastaMascot(
                          size: 72,
                          color: SastaColors.gold,
                          expression: MascotExpression.calm,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No billing history yet',
                          textAlign: TextAlign.center,
                          style: SastaText.display(context, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your Sasta+ billing receipts will appear here after you subscribe.',
                          textAlign: TextAlign.center,
                          style: SastaText.muted(context, size: 13),
                        ),
                        const SizedBox(height: 16),
                        SastaPrimaryButton(
                          label: 'Explore Sasta+',
                          onPressed: () => SastaNav.push(
                            context,
                            SastaRouteNames.plusLanding,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  for (final invoice in state.invoices) ...[
                    SastaCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.planName,
                                  style: SastaText.body(
                                    context,
                                    size: 16,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '₹${invoice.amount}',
                                style: SastaText.display(context, size: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invoice.dateLabel} · ${invoice.txnCode}',
                            style: SastaText.muted(context, size: 13),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _StatusTag(status: invoice.status),
                                TextButton(
                                  onPressed: () =>
                                      _showInvoiceSheet(context, invoice),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(44, 36),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'View invoice',
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Receipts are saved locally on this device for your reference.',
                    style: SastaText.muted(
                      context,
                      size: 12,
                    ).copyWith(color: palette.muted),
                    textAlign: TextAlign.center,
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

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final (bg, fg) = switch (status.toLowerCase()) {
      'paid' => (palette.mint, palette.successText),
      'failed' => (palette.dangerBg, palette.dangerText),
      _ => (palette.sky, palette.skyText),
    };
    return SastaTag(label: status, backgroundColor: bg, textColor: fg);
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold
                ? SastaText.body(context, size: 14, weight: FontWeight.w800)
                : SastaText.muted(context, size: 13),
          ),
        ),
        Text(
          value,
          style: SastaText.body(
            context,
            size: bold ? 16 : 14,
            weight: bold ? FontWeight.w800 : FontWeight.w700,
            tabular: true,
          ),
        ),
      ],
    );
  }
}
