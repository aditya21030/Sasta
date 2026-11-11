import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sasta_app_state.dart';
import '../models/models.dart';
import '../theme/sasta_theme.dart';
import '../theme/sasta_tokens.dart';
import 'product_art.dart';
import 'sasta_components.dart';
import 'sasta_mascot.dart';

/// Shared modal bottom sheet frame matching Sasta's 36dp rounded top container.
Future<T?> showSastaSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final palette = context.sasta;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(SastaRadius.sheet),
      ),
    ),
    builder: (ctx) {
      final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.9;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

/// Interactive Price Alert creation modal sheet (referenced in Home, Product Details, Price History).
Future<void> showCreatePriceAlertSheet(
  BuildContext context, {
  Product? initialProduct,
}) async {
  final state = SastaScope.read(context);
  final product = initialProduct ??
      state.productById('amul_milk')!;
  final cheapest = product.cheapestQuote(product.defaultVariantIndex);
  final currentPrice = cheapest?.price ?? 30;
  var target = (currentPrice - 2).clamp(1, currentPrice);

  await showSastaSheet(
    context: context,
    builder: (ctx) {
      final palette = ctx.sasta;
      return StatefulBuilder(
        builder: (ctx, setState) {
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
                  'Create price alert',
                  style: SastaText.display(ctx, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll notify you when this product drops to or below your target price.',
                  style: SastaText.muted(ctx, size: 13),
                ),
                const SizedBox(height: 16),
                SastaCard(
                  color: palette.lavender,
                  shadow: false,
                  child: Row(
                    children: [
                      ProductArtTile(
                        kind: product.artKind,
                        pastel: product.pastel,
                        size: 52,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: SastaText.body(
                                ctx,
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Currently ₹$currentPrice · ${product.variantAt(product.defaultVariantIndex).label}',
                              style: SastaText.muted(ctx, size: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Notify me below',
                        style: SastaText.body(ctx, size: 15, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: PriceGradientText('₹$target', size: 30),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: target.toDouble(),
                  min: (currentPrice * 0.65).floorToDouble().clamp(1, 5000),
                  max: currentPrice.toDouble(),
                  divisions: (currentPrice - (currentPrice * 0.65).floor())
                      .clamp(1, 50),
                  activeColor: SastaColors.accent,
                  onChanged: (v) => setState(() => target = v.round()),
                ),
                const SizedBox(height: 14),
                SastaPrimaryButton(
                  label: 'Save alert for ₹$target',
                  onPressed: () {
                    state.addPriceAlert(product.id, target);
                    Navigator.of(ctx).pop();
                    showSastaToast(
                      context,
                      'Alert set for ${product.name} at ₹$target',
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Retailer redirection handoff modal respecting DESIGN.md §9.3 & §9.4.
Future<void> showRetailerHandoffSheet(
  BuildContext context, {
  required RetailerId retailer,
  required int estimatedAmount,
  String? itemLabel,
  String? searchQuery,
}) async {
  final state = SastaScope.read(context);
  await showSastaSheet(
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
            Center(
              child: SastaMascot(
                size: 86,
                color: retailer.color,
                expression: MascotExpression.joy,
                haloColor: palette.lavender,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Opening ${retailer.name}',
              textAlign: TextAlign.center,
              style: SastaText.display(ctx, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              itemLabel != null
                  ? '$itemLabel · estimated ~₹$estimatedAmount (excluding delivery fees & retailer checkout charges).'
                  : 'Estimated basket subtotal ~₹$estimatedAmount (excluding delivery fees & retailer checkout charges).',
              textAlign: TextAlign.center,
              style: SastaText.muted(ctx, size: 14),
            ),
            const SizedBox(height: 14),
            SastaCard(
              color: palette.butter,
              shadow: false,
              child: Text(
                'Sasta never processes grocery orders or payments. Your checkout happens directly on ${retailer.name}.',
                style: SastaText.body(
                  ctx,
                  size: 13,
                  color: palette.warningText,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SastaPrimaryButton(
              label: 'Launch ${retailer.shortName} ↗',
              onPressed: () async {
                Navigator.of(ctx).pop();
                final outcome = await state.retailerLauncher.openRetailer(
                  retailer,
                  query: searchQuery ?? itemLabel,
                );
                await Clipboard.setData(
                  ClipboardData(text: outcome.targetUri.toString()),
                );
                if (!context.mounted) return;
                showSastaToast(
                  context,
                  outcome.launched
                      ? 'Opening ${retailer.name} (${retailer.eta})'
                      : 'Link copied for ${retailer.name}: ${outcome.targetUri}',
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Interactive Savings Breakdown Sheet referenced from "Full report" / "Monthly savings report".
Future<void> showMonthlySavingsSheet(BuildContext context) async {
  await showSastaSheet(
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
              'Monthly savings report',
              style: SastaText.display(ctx, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Estimated, not confirmed purchases',
              style: SastaText.muted(ctx, size: 13),
            ),
            const SizedBox(height: 14),
            SastaCard(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE9A8), Color(0xFFFFD27A)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nov estimated savings',
                          style: SastaText.body(
                            ctx,
                            size: 13,
                            weight: FontWeight.w700,
                            color: SastaColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PriceGradientText('₹312', size: 42),
                        ),
                        Text(
                          '16% higher than Oct (₹268)',
                          style: SastaText.body(
                            ctx,
                            size: 12,
                            weight: FontWeight.w600,
                            color: SastaColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SastaMascot(
                    size: 72,
                    color: Colors.white,
                    expression: MascotExpression.joy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SavingsBarRow(label: 'Zepto (14 wins)', value: '₹148', ratio: 0.9),
            const SizedBox(height: 8),
            const _SavingsBarRow(label: 'Blinkit (9 wins)', value: '₹94', ratio: 0.58),
            const SizedBox(height: 8),
            const _SavingsBarRow(
              label: 'Swiggy Instamart (4 wins)',
              value: '₹46',
              ratio: 0.3,
            ),
            const SizedBox(height: 8),
            const _SavingsBarRow(
              label: 'Flipkart Minutes (3 wins)',
              value: '₹24',
              ratio: 0.18,
            ),
            const SizedBox(height: 18),
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

class _SavingsBarRow extends StatelessWidget {
  const _SavingsBarRow({
    required this.label,
    required this.value,
    required this.ratio,
  });

  final String label;
  final String value;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SastaText.body(context, size: 13, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: SastaText.body(context, size: 13, weight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: palette.field,
            valueColor: const AlwaysStoppedAnimation(SastaColors.chartLinePurple),
          ),
        ),
      ],
    );
  }
}
