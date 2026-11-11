import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, this.args});
  final ProductRouteArgs? args;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int? _selectedVariantIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pId = widget.args?.productId;
      if (pId != null) {
        final state = SastaScope.read(context);
        state.addToRecentlyViewed(pId);
        if (state.isApiConfigured) {
          state.refreshProductDetails(pId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final product = state.productById(widget.args?.productId ?? 'amul_milk') ??
        state.products.first;
    final vIdx = _selectedVariantIndex ??
        widget.args?.variantIndex ??
        product.defaultVariantIndex;
    final variant = product.variantAt(vIdx);
    final cheapest = product.cheapestQuote(
      vIdx,
      enabledRetailers: state.enabledRetailers,
    );
    final appCount = product.availableAppCount(
      vIdx,
      enabledRetailers: state.enabledRetailers,
    );
    final isFav = state.isFavourite(product.id);
    final qtyInBasket = state.quantityInActiveBasket(product.id);

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
                      const SizedBox(height: 16),
                      Center(
                        child: FloatBob(
                          amplitude: 6,
                          child: SizedBox(
                            width: 240,
                            height: 210,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 204,
                                  height: 204,
                                  decoration: BoxDecoration(
                                    color: palette.lavender,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 152,
                                  height: 152,
                                  decoration: BoxDecoration(
                                    color: palette.isDark
                                        ? palette.surface
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                CustomPaint(
                                  size: const Size.square(102),
                                  painter: ProductArtPainter(
                                    kind: product.artKind,
                                  ),
                                ),
                                const Positioned(
                                  right: 18,
                                  top: 18,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: SastaColors.gold,
                                    child: Icon(
                                      Icons.bolt_rounded,
                                      size: 16,
                                      color: SastaColors.ink,
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  left: 20,
                                  top: 32,
                                  child: SastaSparkle(
                                    size: 18,
                                    color: SastaColors.sparkleOrange,
                                  ),
                                ),
                                const Positioned(
                                  right: 26,
                                  bottom: 24,
                                  child: SastaSparkle(
                                    size: 15,
                                    color: SastaColors.zepto,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: SastaText.display(context, size: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.subtitle,
                                  style: SastaText.muted(context, size: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Lowest',
                                style: SastaText.muted(context, size: 12),
                              ),
                              PriceGradientText(
                                cheapest != null ? '₹${cheapest.price}' : '—',
                                size: 36,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('PACK SIZE', style: SastaText.eyebrow(context)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(product.variants.length, (i) {
                          final v = product.variants[i];
                          return SastaChip(
                            label: v.saveBadge != null
                                ? '${v.label} · ${v.saveBadge}'
                                : v.label,
                            selected: i == vIdx,
                            onTap: () =>
                                setState(() => _selectedVariantIndex = i),
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      if (cheapest != null)
                        SastaCard(
                          color: palette.mint,
                          shadow: false,
                          onTap: () => SastaNav.openProductCompare(
                            context,
                            product.id,
                            variantIndex: vIdx,
                          ),
                          child: Row(
                            children: [
                              RetailerAvatar(
                                retailer: cheapest.retailer,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Cheapest on ${cheapest.retailer.shortName} · +${(appCount - 1).clamp(0, 3)} more apps to compare',
                                  style: SastaText.body(
                                    context,
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: palette.successText,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: palette.successText,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SastaCard(
                        color: palette.field,
                        shadow: false,
                        onTap: () => SastaNav.openPriceHistory(
                          context,
                          product.id,
                          variantIndex: vIdx,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.show_chart_rounded,
                              color: palette.lavenderText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'View 30-day price history & alerts',
                                style: SastaText.body(
                                  context,
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: palette.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  8,
                  SastaSpace.page,
                  22,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SastaOutlineButton(
                        label: qtyInBasket > 0
                            ? 'In basket ($qtyInBasket) +'
                            : 'Add to basket',
                        onPressed: () {
                          state.addToBasket(
                            product.id,
                            variantIndex: vIdx,
                          );
                          showSastaToast(
                            context,
                            'Added ${product.name} (${variant.label}) to ${state.activeBasket.name}',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SastaPrimaryButton(
                        label: 'Compare',
                        onPressed: () => SastaNav.openProductCompare(
                          context,
                          product.id,
                          variantIndex: vIdx,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
