import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';

class ProductCompareScreen extends StatelessWidget {
  const ProductCompareScreen({super.key, this.args});
  final ProductRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final product =
        state.productById(args?.productId ?? 'amul_milk') ??
            state.products.first;
    final vIdx = args?.variantIndex ?? product.defaultVariantIndex;
    final variant = product.variantAt(vIdx);
    final quotes = product.sortedQuotes(
      vIdx,
      enabledRetailers: state.enabledRetailers,
    );
    final cheapest = product.cheapestQuote(
      vIdx,
      enabledRetailers: state.enabledRetailers,
    );
    final isFav = state.isFavourite(product.id);

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    SastaSpace.page,
                    14,
                    SastaSpace.page,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SastaHeaderBar(
                        title: 'Compare prices',
                        trailing: SastaCircleIconButton(
                          icon: isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor:
                              isFav ? SastaColors.heartPink : palette.ink,
                          tooltip: isFav ? 'Saved' : 'Save',
                          onPressed: () => state.toggleFavourite(product.id),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                                      product.name,
                                      style: SastaText.display(
                                        context,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${variant.label} · ${state.activeLocation.pincode}',
                                      style: SastaText.muted(
                                        context,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () => SastaNav.openPriceHistory(
                                        context,
                                        product.id,
                                        variantIndex: vIdx,
                                      ),
                                      child: Text(
                                        'View price history →',
                                        style: SastaText.body(
                                          context,
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: palette.linkText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ProductArtTile(
                                    kind: product.artKind,
                                    pastel: product.pastel,
                                    size: 76,
                                  ),
                                  const Positioned(
                                    right: -6,
                                    top: -6,
                                    child: SastaSparkle(
                                      size: 18,
                                      color: SastaColors.sparkleOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (cheapest != null) ...[
                        FadeUp(
                          delay: const Duration(milliseconds: 60),
                          child: Row(
                            children: [
                              Flexible(
                                child: SastaTag(
                                  label: 'Cheapest right now',
                                  backgroundColor: palette.mint,
                                  textColor: palette.successText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cheapest.retailer.eta,
                                style: SastaText.muted(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        FadeUp(
                          delay: const Duration(milliseconds: 90),
                          child: InkWell(
                            onTap: () => showRetailerHandoffSheet(
                              context,
                              retailer: cheapest.retailer,
                              estimatedAmount: cheapest.price!,
                              itemLabel:
                                  '${product.name} (${cheapest.packLabel})',
                              searchQuery: product.name,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SastaMascot(
                                    size: 64,
                                    color: cheapest.retailer.color,
                                    expression: MascotExpression.joy,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cheapest.retailer.name,
                                          style: SastaText.display(
                                            context,
                                            size: 22,
                                          ),
                                        ),
                                        Text(
                                          '${cheapest.packLabel}${state.showUnitPrices ? ' · ${cheapest.unitPriceText}' : ''}',
                                          style: SastaText.muted(
                                            context,
                                            size: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: PriceGradientText(
                                        '₹${cheapest.price}',
                                        size: 46,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      Divider(height: 26, color: palette.divider),
                      for (final q in quotes.where((q) => q != cheapest))
                        _RetailerCompareRow(
                          quote: q,
                          showUnitPrice: state.showUnitPrices,
                          onTap: q.isAvailable
                              ? () => showRetailerHandoffSheet(
                                    context,
                                    retailer: q.retailer,
                                    estimatedAmount: q.price!,
                                    itemLabel:
                                        '${product.name} (${q.packLabel})',
                                    searchQuery: product.name,
                                  )
                              : null,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Prices are estimates excluding delivery & handling charges.',
                        style: SastaText.muted(context, size: 12),
                      ),
                    ],
                  ),
                ),
              ),
              if (cheapest != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SastaSpace.page,
                    8,
                    SastaSpace.page,
                    22,
                  ),
                  child: SastaPrimaryButton(
                    label: 'Open ${cheapest.retailer.shortName} app ↗',
                    onPressed: () => showRetailerHandoffSheet(
                      context,
                      retailer: cheapest.retailer,
                      estimatedAmount: cheapest.price!,
                      itemLabel: '${product.name} (${cheapest.packLabel})',
                      searchQuery: product.name,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetailerCompareRow extends StatelessWidget {
  const _RetailerCompareRow({
    required this.quote,
    required this.showUnitPrice,
    this.onTap,
  });

  final RetailerQuote quote;
  final bool showUnitPrice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final available = quote.isAvailable;

    final statusLine = switch (quote.stockStatus) {
      StockStatus.inStock => 'In stock',
      StockStatus.lowStock =>
        '${quote.packLabel} · only ${quote.lowStockCount ?? 2} left',
      StockStatus.outOfStock => 'Out of stock',
    };

    return Opacity(
      opacity: available ? 1.0 : 0.58,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              RetailerAvatar(
                retailer: quote.retailer,
                size: 44,
                expression:
                    available ? MascotExpression.happy : MascotExpression.sad,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.retailer.name,
                      style: SastaText.body(
                        context,
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (quote.stockStatus) {
                              StockStatus.inStock => palette.successText,
                              StockStatus.lowStock => SastaColors.accent,
                              StockStatus.outOfStock => palette.dangerText,
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            showUnitPrice && available
                                ? '$statusLine · ${quote.unitPriceText}'
                                : statusLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SastaText.muted(context, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                available ? '₹${quote.price}' : '—',
                style: SastaText.display(
                  context,
                  size: 22,
                  color: available ? palette.ink : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
