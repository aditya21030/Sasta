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
      state.productById('amul_milk') ??
      state.products.firstOrNull;
  if (product == null) {
    showSastaToast(context, 'No products available for an alert');
    return;
  }
  final cheapest = product.cheapestQuote(product.defaultVariantIndex);
  final currentPrice = cheapest?.price ?? 30;
  final sliderMax = currentPrice < 2 ? 2.0 : currentPrice.toDouble();
  final sliderMin =
      (sliderMax * 0.65).floorToDouble().clamp(1.0, sliderMax - 1.0);
  var target = (currentPrice - 2).clamp(sliderMin.round(), sliderMax.round());

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
                        imageUrl: product.bestImageUrl,
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
                  min: sliderMin,
                  max: sliderMax,
                  divisions: (sliderMax - sliderMin).round().clamp(1, 50),
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
  String? productUrl,
  String? etaOverride,
}) async {
  final state = SastaScope.read(context);
  final etaText = etaOverride ?? state.etaFor(retailer);
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
              child: RetailerAvatar(
                retailer: retailer,
                size: 78,
                showBorder: true,
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
                  productUrl: productUrl,
                );
                if (!outcome.launched) {
                  await Clipboard.setData(
                    ClipboardData(text: outcome.targetUri.toString()),
                  );
                }
                if (!context.mounted) return;
                showSastaToast(
                  context,
                  outcome.launched
                      ? 'Opening ${retailer.name} ($etaText)'
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
  final state = SastaScope.read(context);
  final comp = state.computeBasketComparison();
  final weeklySavings = comp.savingsVsPriciest;
  final monthlyEstimate = weeklySavings * 4;
  final storeRows = comp.storeTotals
      .where((s) => s.availableCount > 0)
      .toList()
    ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
  final maxTotal = storeRows.isEmpty ? 0 : storeRows.last.totalPrice;

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
              'Estimated from ${state.activeBasket.name} (${state.activeBasket.uniqueProducts} items)',
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
                          'Monthly basket savings (~4×/mo)',
                          style: SastaText.body(
                            ctx,
                            size: 13,
                            weight: FontWeight.w700,
                            color: SastaColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PriceGradientText('₹$monthlyEstimate', size: 42),
                        ),
                        Text(
                          weeklySavings > 0
                              ? '₹$weeklySavings saved per basket (${comp.percentSavedVsPriciest}%) · ${state.priceAlerts.length} alerts active'
                              : '${state.priceAlerts.length} price alerts active across ${state.enabledRetailers.length} stores',
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
            if (storeRows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add items to your active basket to see store-by-store total comparisons.',
                  style: SastaText.muted(ctx, size: 13),
                ),
              )
            else
              for (final row in storeRows) ...[
                _SavingsBarRow(
                  label:
                      '${row.retailer.name} (${row.availableCount}/${row.totalProducts} items)',
                  value: '₹${row.totalPrice}',
                  ratio: maxTotal > 0
                      ? (row.totalPrice / maxTotal).clamp(0.08, 1.0)
                      : 0.0,
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 10),
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
