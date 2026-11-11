import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/mock_catalog.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';
import 'basket_select_screen.dart';
import 'basket_sheets.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  void _openBasketSwitcher(BuildContext context, SastaAppState state) {
    showSastaSheet(
      context: context,
      builder: (ctx) {
        final palette = ctx.sasta;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
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
              const SizedBox(height: 16),
              Text('Switch basket', style: SastaText.display(ctx, size: 22)),
              const SizedBox(height: 12),
              for (final b in state.savedBaskets)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.pastel(b.pastel),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      color: palette.pastelAccent(b.pastel),
                    ),
                  ),
                  title: Text(
                    b.name,
                    style: SastaText.body(ctx, size: 15, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${b.uniqueProducts} products · ${b.totalItems} items',
                    style: SastaText.muted(ctx, size: 12),
                  ),
                  trailing: b.id == state.activeBasket.id
                      ? Icon(Icons.check_circle_rounded, color: palette.ink)
                      : null,
                  onTap: () {
                    state.selectActiveBasket(b.id);
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 10),
              SastaOutlineButton(
                label: '+ Create new basket',
                height: 48,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showCreateBasketDialog(context);
                },
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
    final basket = state.activeBasket;

    if (basket.entries.isEmpty) {
      return _EmptyBasketView(basket: basket);
    }

    final comparison = state.computeBasketComparison();
    final cheapestTotal =
        comparison.cheapestCompleteStore?.totalPrice ?? comparison.splitTotal;
    final singleAppOnlyCount = basket.entries.where((e) {
      final p = state.productById(e.productId);
      if (p == null) return false;
      return p.availableAppCount(
            e.variantIndex,
            enabledRetailers: state.enabledRetailers,
          ) ==
          1;
    }).length;
    final multiAppCount = basket.entries.where((e) {
      final p = state.productById(e.productId);
      if (p == null) return false;
      return p.availableAppCount(
            e.variantIndex,
            enabledRetailers: state.enabledRetailers,
          ) >=
          2;
    }).length;
    final unavailableCount = comparison.unavailableProducts.length;

    final basketIds = basket.entries.map((e) => e.productId).toSet();
    final suggestions = state.products
        .where((p) =>
            !basketIds.contains(p.id) &&
            !state.dismissedSuggestionIds.contains(p.id))
        .take(4)
        .toList();

    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            14,
            SastaSpace.page,
            SastaSpace.basketBarClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Basket',
                      style: SastaText.display(context, size: 35),
                    ),
                  ),
                  SastaCircleIconButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'Basket options',
                    onPressed: () => showBasketOptionsSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openBasketSwitcher(context, state),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.iconButtonBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: SastaShadows.float(context),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${basket.name} ▾',
                              style: SastaText.body(
                                context,
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${basket.uniqueProducts} products · ${basket.totalItems} items',
                      style: SastaText.muted(context, size: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.basketOfflineError)
                _BasketErrorCard(
                  onRetry: () {
                    state.setBasketOfflineError(false);
                    showSastaToast(context, 'Price data refreshed');
                  },
                )
              else
                FadeUp(
                  child: SastaCard(
                    color: palette.lavender,
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated cheapest basket',
                                    style: SastaText.body(
                                      context,
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: palette.muted,
                                    ),
                                  ),
                                  PriceGradientText('~₹$cheapestTotal', size: 40),
                                ],
                              ),
                            ),
                            SastaCircleIconButton(
                              icon: Icons.refresh_rounded,
                              tooltip: 'Refresh basket prices',
                              onPressed: () => showSastaToast(
                                context,
                                'Prices verified for ${state.activeLocation.pincode}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            SastaTag(
                              label: 'Updated recently',
                              backgroundColor: palette.isDark
                                  ? palette.surface
                                  : Colors.white,
                              textColor: palette.ink,
                            ),
                            if (unavailableCount > 0)
                              SastaTag(
                                label:
                                    '$unavailableCount item${unavailableCount > 1 ? 's' : ''} unavailable',
                                backgroundColor: palette.dangerBg,
                                textColor: palette.dangerText,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estimate across ${state.enabledRetailers.length} apps. Delivery fees and final checkout charges not included.',
                          style: SastaText.muted(context, size: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Add products',
                style: SastaText.display(context, size: 20),
              ),
              const SizedBox(height: 10),
              SastaSearchPill(
                readOnly: true,
                hintText: 'Search groceries, brands…',
                onTap: () => SastaNav.openHomeSearch(context),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  children: [
                    SastaChip(
                      label: 'Favourites',
                      leading: const Icon(Icons.favorite_border_rounded),
                      onTap: () => SastaNav.push(
                        context,
                        SastaRouteNames.favouritesPush,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SastaChip(
                      label: 'Recently compared',
                      leading: const Icon(Icons.history_rounded),
                      onTap: () =>
                          SastaNav.push(context, SastaRouteNames.searchHistory),
                    ),
                    const SizedBox(width: 8),
                    SastaChip(
                      label: 'Browse',
                      leading: const Icon(Icons.grid_view_rounded),
                      onTap: () => SastaNav.openCategories(context),
                    ),
                    const SizedBox(width: 8),
                    SastaChip(
                      label: 'Previous baskets',
                      onTap: () =>
                          SastaNav.push(context, SastaRouteNames.savedBaskets),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your items',
                      style: SastaText.display(context, size: 20),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BasketSelectScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        'Select',
                        style: SastaText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w700,
                          color: palette.linkText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final entry in basket.entries)
                Builder(builder: (context) {
                  final product = state.productById(entry.productId);
                  if (product == null) return const SizedBox.shrink();
                  final variant = product.variantAt(entry.variantIndex);
                  final cheapest = product.cheapestQuote(
                    entry.variantIndex,
                    enabledRetailers: state.enabledRetailers,
                  );
                  final isUnavailable = cheapest == null;

                  if (isUnavailable) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SastaCard(
                        color: palette.unavailableBg,
                        shadow: false,
                        dashedBorderColor: palette.unavailableBorder,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ProductArtTile(
                                  kind: product.artKind,
                                  pastel: product.pastel,
                                  size: 60,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: SastaText.body(
                                          context,
                                          size: 15,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${product.brand} · ${variant.label}',
                                        style: SastaText.muted(
                                          context,
                                          size: 12,
                                        ),
                                      ),
                                      Text(
                                        'Unavailable on all selected apps',
                                        style: SastaText.body(
                                          context,
                                          size: 12,
                                          weight: FontWeight.w700,
                                          color: palette.dangerText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SastaStepper(
                                  quantity: entry.quantity,
                                  onDecrement: () =>
                                      state.updateBasketItemQuantity(
                                    product.id,
                                    entry.quantity - 1,
                                  ),
                                  onIncrement: () =>
                                      state.updateBasketItemQuantity(
                                    product.id,
                                    entry.quantity + 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: SastaPrimaryButton(
                                    label: 'Find alternatives',
                                    height: 40,
                                    onPressed: () =>
                                        SastaNav.openSearchResults(
                                      context,
                                      categoryId: product.categoryId,
                                      titleOverride: 'Alternatives',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SastaChip(
                                  label: 'Keep',
                                  height: 40,
                                  onTap: () => showSastaToast(
                                    context,
                                    'Kept in basket to recheck later',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => state.updateBasketItemQuantity(
                                    product.id,
                                    0,
                                  ),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: palette.dangerBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: palette.dangerText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SastaCard(
                      onTap: () => SastaNav.openProductCompare(
                        context,
                        product.id,
                        variantIndex: entry.variantIndex,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductArtTile(
                            kind: product.artKind,
                            pastel: product.pastel,
                            size: 64,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: SastaText.body(
                                    context,
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.brand} · ${variant.label}',
                                  style: SastaText.muted(context, size: 12),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      state.basketOfflineError
                                          ? 'Not refreshed'
                                          : '₹${cheapest.price}',
                                      style: SastaText.display(
                                        context,
                                        size: 20,
                                      ),
                                    ),
                                    if (!state.basketOfflineError)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RetailerAvatar(
                                            retailer: cheapest.retailer,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              cheapest.retailer.shortName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: SastaText.muted(
                                                context,
                                                size: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if (product.trendTag != null) ...[
                                  const SizedBox(height: 6),
                                  SastaTag(
                                    label: product.trendTag!,
                                    backgroundColor:
                                        product.trendTag!.startsWith('↑')
                                            ? palette.dangerBg
                                            : palette.mint,
                                    textColor: product.trendTag!.startsWith('↑')
                                        ? palette.dangerText
                                        : palette.successText,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SastaStepper(
                                quantity: entry.quantity,
                                onDecrement: () =>
                                    state.updateBasketItemQuantity(
                                  product.id,
                                  entry.quantity - 1,
                                ),
                                onIncrement: () =>
                                    state.updateBasketItemQuantity(
                                  product.id,
                                  entry.quantity + 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 20,
                                  color: palette.muted,
                                ),
                                onPressed: () => SastaNav.openProductDetails(
                                  context,
                                  product.id,
                                  variantIndex: entry.variantIndex,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 10),
              Text(
                'Availability overview',
                style: SastaText.display(context, size: 20),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _AvailTile(
                      count: '$multiAppCount',
                      label: 'on several apps',
                      bg: palette.mint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AvailTile(
                      count: '$singleAppOnlyCount',
                      label: 'on one app only',
                      bg: palette.butter,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AvailTile(
                      count: '$unavailableCount',
                      label: 'unavailable',
                      bg: palette.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SastaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your basket summary',
                      style: SastaText.display(context, size: 19),
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Unique products',
                      value: '${basket.uniqueProducts}',
                    ),
                    _SummaryRow(
                      label: 'Total items',
                      value: '${basket.totalItems}',
                    ),
                    _SummaryRow(
                      label: 'Products with prices',
                      value:
                          '${basket.uniqueProducts - unavailableCount} of ${basket.uniqueProducts}',
                    ),
                    _SummaryRow(
                      label: 'Unavailable',
                      value: '$unavailableCount',
                      valueColor: unavailableCount > 0
                          ? palette.dangerText
                          : palette.ink,
                    ),
                    Divider(height: 18, color: palette.divider),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Estimated subtotal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SastaText.body(
                              context,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '~₹$cheapestTotal',
                          style: SastaText.display(context, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estimate only · ${basket.updatedLabel}',
                      style: SastaText.muted(context, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SastaCard(
                color: palette.peach,
                shadow: false,
                onTap: () => SastaNav.openBasketCompare(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compare across ${state.enabledRetailers.length} apps',
                            style: SastaText.display(context, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See totals, splits and savings.',
                            style: SastaText.muted(context, size: 13),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              SastaTag(
                                label: 'Single store',
                                backgroundColor: palette.isDark
                                    ? palette.surface
                                    : Colors.white,
                                textColor: palette.ink,
                              ),
                              SastaTag(
                                label: 'Split basket',
                                backgroundColor: palette.isDark
                                    ? palette.surface
                                    : Colors.white,
                                textColor: palette.ink,
                              ),
                              SastaTag(
                                label: 'Savings',
                                backgroundColor: palette.isDark
                                    ? palette.surface
                                    : Colors.white,
                                textColor: palette.ink,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const BasketHeroIllustration(size: 86),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'My saved baskets',
                      style: SastaText.display(context, size: 20),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        SastaNav.push(context, SastaRouteNames.savedBaskets),
                    child: Text(
                      'Manage',
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
              const SizedBox(height: 10),
              SizedBox(
                height: 162,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: state.savedBaskets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final sb = state.savedBaskets[i];
                    final isCurrent = sb.id == basket.id;
                    return SastaCard(
                      color: palette.pastel(sb.pastel),
                      shadow: false,
                      child: SizedBox(
                        width: 210,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCurrent)
                              SastaTag(
                                label: 'Current',
                                backgroundColor: palette.ink,
                                textColor: palette.primaryCtaFg,
                              )
                            else
                              const SizedBox(height: 18),
                            const SizedBox(height: 6),
                            Text(
                              sb.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.body(
                                context,
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${sb.uniqueProducts} products · ${sb.updatedLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.muted(context, size: 12),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Expanded(
                                  child: SastaPrimaryButton(
                                    label: isCurrent ? 'Compare' : 'Open',
                                    height: 36,
                                    onPressed: () {
                                      if (isCurrent) {
                                        SastaNav.openBasketCompare(context);
                                      } else {
                                        state.selectActiveBasket(sb.id);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SastaOutlineButton(
                label: '+ Create new basket',
                height: 48,
                onPressed: () => showCreateBasketDialog(context),
              ),
              const SizedBox(height: 22),
              Text(
                'Quick start with a basket',
                style: SastaText.display(context, size: 20),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 146,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  itemCount: MockCatalog.templates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final t = MockCatalog.templates[i];
                    return SastaCard(
                      color: palette.pastel(t.pastel),
                      shadow: false,
                      child: SizedBox(
                        width: 184,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.body(
                                context,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t.productIds.length} products',
                              style: SastaText.muted(context, size: 12),
                            ),
                            const Spacer(),
                            SastaChip(
                              label: 'Preview',
                              selected: true,
                              height: 36,
                              onTap: () =>
                                  showTemplatePreviewSheet(context, t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Recent basket activity',
                style: SastaText.display(context, size: 20),
              ),
              const SizedBox(height: 8),
              for (final act in state.basketActivities.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: act.kind == 'removed'
                              ? palette.dangerBg
                              : palette.mint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          act.kind == 'removed'
                              ? Icons.delete_outline_rounded
                              : (act.kind == 'compared'
                                  ? Icons.schedule_rounded
                                  : Icons.add_rounded),
                          size: 19,
                          color: act.kind == 'removed'
                              ? palette.dangerText
                              : palette.successText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: SastaText.body(
                                context,
                                size: 14,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              act.subtitle,
                              style: SastaText.muted(context, size: 12),
                            ),
                          ],
                        ),
                      ),
                      if (act.kind == 'removed' && act.productId != null)
                        SastaChip(
                          label: 'Restore',
                          height: 34,
                          onTap: () {
                            state.addToBasket(act.productId!);
                            showSastaToast(context, 'Restored to basket');
                          },
                        )
                      else if (act.kind == 'compared')
                        SastaChip(
                          label: 'Reopen',
                          height: 34,
                          onTap: () => SastaNav.openBasketCompare(context),
                        ),
                    ],
                  ),
                ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Complete your basket',
                  style: SastaText.display(context, size: 20),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 206,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final s = suggestions[i];
                      final q = s.cheapestQuote(s.defaultVariantIndex);
                      return SastaCard(
                        color: palette.pastel(s.pastel),
                        shadow: false,
                        child: SizedBox(
                          width: 170,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: ProductArtTile(
                                  kind: s.artKind,
                                  pastel: s.pastel,
                                  size: 56,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SastaText.body(
                                  context,
                                  size: 14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                q != null ? '₹${q.price} · ${q.retailer.shortName}' : '—',
                                style: SastaText.muted(context, size: 12),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: SastaPrimaryButton(
                                      label: 'Add',
                                      height: 36,
                                      onPressed: () {
                                        state.addToBasket(s.id);
                                        showSastaToast(
                                          context,
                                          'Added ${s.name}',
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        state.dismissBasketSuggestion(s.id),
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: palette.isDark
                                            ? palette.surface
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                'Share your shopping list',
                style: SastaText.display(context, size: 20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickShareIcon(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      bg: palette.mint,
                      fg: palette.successText,
                      onTap: () => showBasketShareSheet(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickShareIcon(
                      label: 'Copy list',
                      icon: Icons.copy_rounded,
                      bg: palette.lavender,
                      fg: palette.lavenderText,
                      onTap: () => showBasketShareSheet(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickShareIcon(
                      label: 'Export',
                      icon: Icons.file_upload_outlined,
                      bg: palette.sky,
                      fg: palette.skyText,
                      onTap: () => showBasketShareSheet(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _QuickShareIcon(
                      label: 'Print',
                      icon: Icons.print_outlined,
                      bg: palette.peach,
                      fg: palette.linkText,
                      onTap: () => showBasketShareSheet(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: SastaSizes.navHeight + 24,
          child: BasketFloatingBar(
            productCount: basket.uniqueProducts,
            estimateTotal: cheapestTotal,
            onCompare: () => SastaNav.openBasketCompare(context),
          ),
        ),
      ],
    );
  }
}

class _EmptyBasketView extends StatelessWidget {
  const _EmptyBasketView({required this.basket});
  final SavedBasket basket;

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.read(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SastaSpace.page,
        14,
        SastaSpace.page,
        SastaSpace.navClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Basket',
                  style: SastaText.display(context, size: 35),
                ),
              ),
              SastaCircleIconButton(
                icon: Icons.more_horiz_rounded,
                tooltip: 'Basket options',
                onPressed: () => showBasketOptionsSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Center(
            child: FloatBob(
              amplitude: 7,
              child: BasketHeroIllustration(size: 190),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your basket is empty!',
            textAlign: TextAlign.center,
            style: SastaText.display(context, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding products to "${basket.name}" to see the cheapest store and split options.',
            textAlign: TextAlign.center,
            style: SastaText.muted(context, size: 14),
          ),
          const SizedBox(height: 22),
          SastaPrimaryButton(
            label: 'Start adding products',
            onPressed: () => SastaNav.openHomeSearch(context),
          ),
          const SizedBox(height: 10),
          SastaOutlineButton(
            label: 'Explore categories',
            onPressed: () => SastaNav.openCategories(context),
          ),
          const SizedBox(height: 26),
          Text(
            'Popular products',
            style: SastaText.display(context, size: 20),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: state.products.length.clamp(0, 4),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = state.products[i];
                final q = p.cheapestQuote(p.defaultVariantIndex);
                return SastaCard(
                  color: context.sasta.pastel(p.pastel),
                  shadow: false,
                  child: SizedBox(
                    width: 154,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProductArtTile(
                              kind: p.artKind,
                              pastel: p.pastel,
                              size: 44,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => state.addToBasket(p.id),
                              icon: const Icon(Icons.add_circle_rounded),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SastaText.body(
                            context,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          q != null ? '₹${q.price}' : '—',
                          style: SastaText.display(context, size: 18),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketErrorCard extends StatelessWidget {
  const _BasketErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      color: palette.pink,
      shadow: false,
      child: Column(
        children: [
          const SastaMascot(
            size: 86,
            color: SastaColors.mutedGrey,
            expression: MascotExpression.sad,
          ),
          const SizedBox(height: 10),
          Text(
            'Comparison unavailable',
            style: SastaText.display(context, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'We can’t reach price data right now. Your basket items are safe.',
            textAlign: TextAlign.center,
            style: SastaText.muted(context, size: 13),
          ),
          const SizedBox(height: 14),
          SastaPrimaryButton(
            label: 'Try again',
            height: 46,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _AvailTile extends StatelessWidget {
  const _AvailTile({
    required this.count,
    required this.label,
    required this.bg,
  });

  final String count;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count, style: SastaText.display(context, size: 24)),
          const SizedBox(height: 2),
          Text(
            label,
            style: SastaText.body(
              context,
              size: 12,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SastaText.muted(context, size: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: SastaText.body(
              context,
              size: 14,
              weight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickShareIcon extends StatelessWidget {
  const _QuickShareIcon({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: SastaText.body(context, size: 12, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
