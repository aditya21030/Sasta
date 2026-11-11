import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/sasta_theme.dart';
import '../theme/sasta_tokens.dart';
import 'product_art.dart';
import 'sasta_components.dart';

/// Shared 2-column or rail product card matching Search.dc.html & Favourites.dc.html.
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    this.variantIndex,
    this.enabledRetailers,
    this.isFavourite = false,
    this.showFavouriteButton = false,
    this.badgeText,
    this.badgeIsDark = false,
    this.onToggleFavourite,
    this.onTap,
    this.width,
  });

  final Product product;
  final int? variantIndex;
  final Set<RetailerId>? enabledRetailers;
  final bool isFavourite;
  final bool showFavouriteButton;
  final String? badgeText;
  final bool badgeIsDark;
  final VoidCallback? onToggleFavourite;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final vIdx = variantIndex ?? product.defaultVariantIndex;
    final variant = product.variantAt(vIdx);
    final cheapest = product.cheapestQuote(vIdx, enabledRetailers: enabledRetailers);
    final availableRetailers = variant.quotes
        .where((q) =>
            (enabledRetailers == null || enabledRetailers!.contains(q.retailer)) &&
            q.isAvailable)
        .map((q) => q.retailer)
        .toList();

    final cardContent = Container(
      width: width,
      padding: const EdgeInsets.all(13),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.pastel(product.pastel),
        borderRadius: BorderRadius.circular(SastaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null || showFavouriteButton) ...[
            SizedBox(
              height: 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (badgeText != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: SastaTag(
                            label: badgeText!,
                            backgroundColor: badgeIsDark
                                ? SastaColors.ink
                                : (palette.isDark
                                    ? palette.surface
                                    : Colors.white),
                            textColor:
                                badgeIsDark ? Colors.white : palette.successText,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (showFavouriteButton)
                    InkWell(
                      onTap: onToggleFavourite,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              palette.isDark ? palette.surface : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: SastaShadows.float(context),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: isFavourite
                              ? SastaColors.heartPink
                              : palette.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Center(
            child: SizedBox(
              height: 58,
              width: 58,
              child: product.bestImageUrl != null
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        product.bestImageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ClipRect(
                            child: CustomPaint(
                              size: const Size.square(52),
                              painter: ProductArtPainter(kind: product.artKind),
                            ),
                          ),
                        ),
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ClipRect(
                        child: CustomPaint(
                          size: const Size.square(56),
                          painter: ProductArtPainter(kind: product.artKind),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SastaText.body(
              context,
              size: 14,
              weight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            variant.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SastaText.muted(context, size: 12, height: 1.2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cheapest != null ? '₹${cheapest.price}' : 'Out of stock',
                        style: SastaText.display(
                          context,
                          size: cheapest != null ? 20 : 14,
                          color: cheapest != null
                              ? palette.ink
                              : palette.dangerText,
                        ),
                      ),
                      if (cheapest?.mrp != null &&
                          cheapest!.price != null &&
                          cheapest.mrp! > cheapest.price!)
                        Text(
                          '₹${cheapest.mrp}',
                          style: SastaText.muted(context, size: 11, height: 1.1)
                              .copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (availableRetailers.isNotEmpty) ...[
                const SizedBox(width: 4),
                OverlappingRetailerAvatars(
                  retailers: availableRetailers.take(3).toList(),
                  avatarSize: 22,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(SastaRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SastaRadius.card),
        child: cardContent,
      ),
    );
  }
}
