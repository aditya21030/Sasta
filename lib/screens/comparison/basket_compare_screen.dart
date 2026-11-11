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

/// Section 05 Basket comparison screen combining Single store, Split basket, and Savings views.
class BasketCompareScreen extends StatefulWidget {
  const BasketCompareScreen({super.key, this.args});
  final BasketCompareArgs? args;

  @override
  State<BasketCompareScreen> createState() => _BasketCompareScreenState();
}

class _BasketCompareScreenState extends State<BasketCompareScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.args?.initialTab ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final comp = state.computeBasketComparison(
      customEntries: widget.args?.customEntries,
    );
    final cheapest = comp.cheapestCompleteStore;
    final basketQuery = state.activeBasket.entries
        .map((e) => state.productById(e.productId)?.name)
        .whereType<String>()
        .take(2)
        .join(' ');

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  14,
                  SastaSpace.page,
                  0,
                ),
                child: Column(
                  children: [
                    const SastaHeaderBar(title: 'Compare basket'),
                    const SizedBox(height: 16),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: palette.field,
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: Row(
                        children: [
                          _SegTab(
                            label: '1 Store',
                            selected: _tabIndex == 0,
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                          _SegTab(
                            label: 'Mix Stores',
                            selected: _tabIndex == 1,
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                          _SegTab(
                            label: 'Savings',
                            selected: _tabIndex == 2,
                            onTap: () => setState(() => _tabIndex = 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    SastaSpace.page,
                    0,
                    SastaSpace.page,
                    20,
                  ),
                  child: switch (_tabIndex) {
                    0 => _SingleStoreBody(
                        comparison: comp,
                        searchQuery: basketQuery,
                      ),
                    1 => _SplitBasketBody(comparison: comp),
                    _ => _SavingsBody(comparison: comp),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  8,
                  SastaSpace.page,
                  22,
                ),
                child: _buildBottomCta(context, cheapest, comp, basketQuery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCta(
    BuildContext context,
    StoreBasketTotal? cheapest,
    BasketComparisonResult comp,
    String basketQuery,
  ) {
    final queryOrNull = basketQuery.trim().isEmpty ? null : basketQuery;
    if (_tabIndex == 1 && cheapest != null) {
      return SastaPrimaryButton(
        label: '${cheapest.retailer.shortName} only · ₹${cheapest.totalPrice}',
        onPressed: () => showRetailerHandoffSheet(
          context,
          retailer: cheapest.retailer,
          estimatedAmount: cheapest.totalPrice,
          searchQuery: queryOrNull,
        ),
      );
    }
    if (cheapest != null) {
      return SastaPrimaryButton(
        label: 'Open ${cheapest.retailer.shortName} app ↗',
        onPressed: () => showRetailerHandoffSheet(
          context,
          retailer: cheapest.retailer,
          estimatedAmount: cheapest.totalPrice,
          searchQuery: queryOrNull,
        ),
      );
    }
    return SastaPrimaryButton(
      label: 'Open ${comp.splitSlices.firstOrNull?.retailer.shortName ?? 'store'} ↗',
      onPressed: comp.splitSlices.isEmpty
          ? null
          : () => showRetailerHandoffSheet(
                context,
                retailer: comp.splitSlices.first.retailer,
                estimatedAmount: comp.splitSlices.first.subtotal,
                searchQuery: queryOrNull,
              ),
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: SastaMotion.fast,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.primaryCtaBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SastaText.body(
              context,
              size: 13,
              weight: FontWeight.w700,
              color: selected ? palette.primaryCtaFg : palette.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SingleStoreBody extends StatelessWidget {
  const _SingleStoreBody({
    required this.comparison,
    this.searchQuery,
  });
  final BasketComparisonResult comparison;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final winner = comparison.cheapestCompleteStore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (winner != null)
          FadeUp(
            child: SastaCard(
              color: palette.lavender,
              shadow: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SastaTag(
                          label: 'Cheapest on 1 app',
                          backgroundColor: palette.mint,
                          textColor: palette.successText,
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PriceGradientText(
                            '₹${winner.totalPrice}',
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${winner.retailer.name} · est. item total',
                          style: SastaText.body(
                            context,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatBob(
                    amplitude: 5,
                    child: RetailerAvatar(
                      retailer: winner.retailer,
                      size: 76,
                      showBorder: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        for (final store in comparison.storeTotals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SastaCard(
              onTap: store.availableCount > 0
                  ? () => showRetailerHandoffSheet(
                        context,
                        retailer: store.retailer,
                        estimatedAmount: store.totalPrice,
                        searchQuery: searchQuery?.trim().isEmpty == true
                            ? null
                            : searchQuery,
                      )
                  : null,
              border: store == winner
                  ? Border.all(color: palette.ink, width: 2)
                  : null,
              child: Opacity(
                opacity: store.isComplete ? 1.0 : 0.72,
                child: Row(
                  children: [
                    RetailerAvatar(
                      retailer: store.retailer,
                      size: 44,
                      expression: store.isComplete
                          ? MascotExpression.happy
                          : MascotExpression.sad,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.retailer.name,
                            style: SastaText.body(
                              context,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            store.isComplete
                                ? 'All ${store.totalProducts} available · ${store.retailer.eta}'
                                : '${store.missingProductNames.first} unavailable · ${store.availableCount} of ${store.totalProducts}',
                            style: SastaText.muted(context, size: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      store.availableCount > 0 ? '₹${store.totalPrice}' : '—',
                      style: SastaText.display(context, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'Totals show estimated item subtotals only. Delivery, surge, and small-cart fees are calculated at retailer checkout.',
          style: SastaText.muted(context, size: 12),
        ),
      ],
    );
  }
}

class _SplitBasketBody extends StatelessWidget {
  const _SplitBasketBody({required this.comparison});
  final BasketComparisonResult comparison;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final splitWorthIt = comparison.isSplitWorthIt;
    final splitSavings = comparison.splitSavingsOverBestSingle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeUp(
          child: SastaCard(
            color: splitWorthIt ? palette.mint : palette.peach,
            shadow: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        splitWorthIt
                            ? 'Mix apps to save ₹$splitSavings'
                            : 'Better in 1 store',
                        style: SastaText.display(context, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        splitWorthIt
                            ? 'Ordering across ${comparison.splitSlices.length} apps saves ₹$splitSavings on item prices.'
                            : 'Mixing apps saves ₹$splitSavings on items, which may get used up by a second delivery fee.',
                        style: SastaText.body(
                          context,
                          size: 13,
                          color: palette.ink.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const SastaMascot(
                  size: 72,
                  color: SastaColors.instamart,
                  expression: MascotExpression.happy,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final slice in comparison.splitSlices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SastaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RetailerAvatar(retailer: slice.retailer, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slice.retailer.name,
                              style: SastaText.body(
                                context,
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${slice.lines.length} product${slice.lines.length > 1 ? 's' : ''}',
                              style: SastaText.muted(context, size: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹${slice.subtotal}',
                        style: SastaText.display(context, size: 22),
                      ),
                    ],
                  ),
                  Divider(height: 18, color: palette.divider),
                  for (final line in slice.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.product.name} (${line.pack}) ×${line.quantity}',
                              style: SastaText.body(
                                context,
                                size: 13,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '₹${line.lineTotal}',
                            style: SastaText.body(
                              context,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        SastaCard(
          color: palette.field,
          shadow: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Items total · fees not included',
                  style:
                      SastaText.body(context, size: 14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${comparison.splitTotal}',
                style: SastaText.display(context, size: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SavingsBody extends StatelessWidget {
  const _SavingsBody({required this.comparison});
  final BasketComparisonResult comparison;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final bestSingle = comparison.cheapestCompleteStore?.totalPrice ??
        comparison.splitTotal;
    final priciest = comparison.priciestCompleteStore?.totalPrice ?? bestSingle;
    final maxBar = priciest > 0 ? priciest : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeUp(
          child: SastaCard(
            color: palette.butter,
            shadow: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Potential savings',
                        style: SastaText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: PriceGradientText(
                          '₹${comparison.savingsVsPriciest}',
                          size: 52,
                        ),
                      ),
                      Text(
                        '${comparison.percentSavedVsPriciest}% less than the costliest app',
                        style: SastaText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SastaMascot(
                  size: 80,
                  color: SastaColors.gold,
                  expression: MascotExpression.joy,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SastaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basket total comparison',
                style: SastaText.display(context, size: 18),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _CompareBar(
                      label: '1 Store',
                      amount: '₹$bestSingle',
                      ratio: bestSingle / maxBar,
                      color: SastaColors.instamart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompareBar(
                      label: 'Mix*',
                      amount: '₹${comparison.splitTotal}*',
                      ratio: comparison.splitTotal / maxBar,
                      color: SastaColors.chartLinePurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CompareBar(
                      label: 'Costliest',
                      amount: '₹$priciest',
                      ratio: 1.0,
                      color: SastaColors.mutedGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '*Mix total counts groceries only. Ordering from 2+ apps adds extra delivery fees.',
                style: SastaText.muted(context, size: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Per-item comparison',
          style: SastaText.display(context, size: 18),
        ),
        const SizedBox(height: 10),
        for (final item in comparison.perItemSavings)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: SastaText.body(
                          context,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Best ₹${item.bestUnitPrice} vs highest ₹${item.worstUnitPrice} (×${item.quantity})',
                        style: SastaText.muted(context, size: 12),
                      ),
                    ],
                  ),
                ),
                SastaTag(
                  label: item.totalSaved > 0
                      ? 'Save ₹${item.totalSaved}'
                      : 'Best matched',
                  backgroundColor:
                      item.totalSaved > 0 ? palette.mint : palette.field,
                  textColor:
                      item.totalSaved > 0 ? palette.successText : palette.muted,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeRatio = ratio.clamp(0.35, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amount,
            style: SastaText.body(context, size: 13, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 100 * safeRatio,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: SastaText.muted(context, size: 12)),
        ),
      ],
    );
  }
}
