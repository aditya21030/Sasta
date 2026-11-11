import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/mock_catalog.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;

    return RefreshIndicator(
      onRefresh: () async {
        await state.syncCatalogForLocation();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          0,
          14,
          0,
          SastaSpace.navClearance,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
            child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: SastaText.display(context, size: 28),
                        children: const [
                          TextSpan(text: 'sasta'),
                          TextSpan(
                            text: '.',
                            style: TextStyle(color: SastaColors.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => SastaNav.push(
                            context,
                            SastaRouteNames.locations,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color: palette.iconButtonBg,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: SastaShadows.float(context),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: SastaColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${state.activeLocation.pincode} ▾',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SastaText.body(
                                      context,
                                      size: 13,
                                      weight: FontWeight.w700,
                                      tabular: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SastaCircleIconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Price alerts & notifications',
                badgeCount:
                    state.firstTimeUserMode || state.homeOfflineError
                        ? 0
                        : state.unreadNotificationCount,
                onPressed: () =>
                    SastaNav.push(context, SastaRouteNames.notifications),
              ),
            ],
          ),
          ),
          const SizedBox(height: 18),
          if (state.homeOfflineError) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: SastaSpace.page),
              child: _HomeOfflineSection(),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeUp(
                    child: Text(
                      'What are we\nsaving on today?',
                      style: SastaText.display(context, size: 35),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeUp(
                    delay: const Duration(milliseconds: 50),
                    child: SastaSearchPill(
                      readOnly: true,
                      onTap: () => SastaNav.openHomeSearch(context),
                    ),
                  ),
                  if (state.isCatalogSyncing || state.isLiveCatalogActive) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => SastaNav.push(
                        context,
                        SastaRouteNames.comparisonPrefs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            state.isCatalogSyncing
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded,
                            size: 14,
                            color: state.isLiveCatalogActive
                                ? palette.successText
                                : palette.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              state.isCatalogSyncing
                                  ? 'Checking store prices for ${state.activeLocation.pincode}…'
                                  : 'Live prices updated · ${state.activeLocation.area}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SastaText.body(
                                context,
                                size: 12,
                                weight: FontWeight.w600,
                                color: state.isLiveCatalogActive
                                    ? palette.successText
                                    : palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.firstTimeUserMode) ...[
                    const SizedBox(height: 18),
                    _WelcomeBannerCard(
                      onDismiss: () => state.setFirstTimeUserMode(false),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Shop by category',
                    actionLabel: 'View all',
                    onAction: () => SastaNav.openCategories(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                SastaSpace.page,
                2,
                SastaSpace.page,
                6,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < 6; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      _CategoryRailCard(
                        category: MockCatalog.categories[index],
                        onTap: () => SastaNav.openSearchResults(
                          context,
                          categoryId: MockCatalog.categories[index].id,
                          titleOverride: MockCatalog.categories[index].name,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
              child: _SectionHeader(
                title: 'Popular searches',
                actionLabel: 'More',
                onAction: () => SastaNav.openHomeSearch(context),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                SastaSpace.page,
                2,
                SastaSpace.page,
                6,
              ),
              child: Row(
                children: [
                  for (var index = 0;
                      index < MockCatalog.popularSearches.length;
                      index++) ...[
                    if (index > 0) const SizedBox(width: 8),
                    SastaChip(
                      label: MockCatalog.popularSearches[index],
                      onTap: () {
                        final term = MockCatalog.popularSearches[index];
                        state.addSearchQuery(term);
                        SastaNav.openSearchResults(context, query: term);
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (!state.firstTimeUserMode) ...[
              const SizedBox(height: 24),
              _BestDealsSection(state: state),
              const SizedBox(height: 24),
              _TrendingSection(state: state),
              const SizedBox(height: 24),
              _PricesDroppedSection(state: state),
              const SizedBox(height: 22),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _HomeSmartBasketCard(state: state),
              ),
              const SizedBox(height: 22),
              _SmartPicksSection(state: state),
              const SizedBox(height: 22),
              _ExploreBrandsSection(state: state),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _HomeSavingsCard(),
              ),
              const SizedBox(height: 22),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _HomePriceAlertsCard(state: state),
              ),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _MonthlySavingsCard(),
              ),
              const SizedBox(height: 22),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _SastaPlusPromoCard(state: state),
              ),
              const SizedBox(height: 22),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _RecentlyComparedSection(state: state),
              ),
              const SizedBox(height: 22),
              _RecentlyViewedSection(state: state),
            ] else ...[
              const SizedBox(height: 22),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _FirstTimeBasketEmptyCard(
                  onStart: () => state.setActiveTab(1),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _FirstTimeAlertsEmptyCard(
                  onCreateAlert: () => showCreatePriceAlertSheet(context),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: SastaSpace.page),
                child: _SastaPlusPromoCard(state: state),
              ),
            ],
          ],
        ],
      ),
        ),
    );
  }
}

class _HomeOfflineSection extends StatelessWidget {
  const _HomeOfflineSection();

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final state = SastaScope.read(context);
    return Column(
      children: [
        const SizedBox(height: 16),
        Center(
          child: FloatBob(
            amplitude: 5,
            child: SastaMascot(
              size: 132,
              color: SastaColors.mutedGrey,
              expression: MascotExpression.sad,
              haloColor: palette.pink,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No connection',
          textAlign: TextAlign.center,
          style: SastaText.display(context, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          'We couldn’t load your deals. Check your internet and try again.',
          textAlign: TextAlign.center,
          style: SastaText.muted(context, size: 15),
        ),
        const SizedBox(height: 20),
        SastaPrimaryButton(
          label: 'Try again',
          onPressed: () {
            state.setHomeOfflineError(false);
            showSastaToast(context, 'Back online · prices refreshed');
          },
        ),
        const SizedBox(height: 24),
        const SkeletonBlock(height: 92, radius: 26),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: SkeletonBlock(height: 140, radius: 26)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBlock(height: 140, radius: 26)),
          ],
        ),
      ],
    );
  }
}

class _WelcomeBannerCard extends StatelessWidget {
  const _WelcomeBannerCard({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.lavender, palette.peach],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Sasta',
                  style: SastaText.display(context, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  'Search any grocery once to compare live prices across 4 quick-commerce stores.',
                  style: SastaText.body(
                    context,
                    size: 13,
                    color: palette.ink.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onDismiss,
                  child: Text(
                    'Show personalized feed →',
                    style: SastaText.body(
                      context,
                      size: 13,
                      weight: FontWeight.w800,
                      color: palette.linkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SastaMascot(
            size: 76,
            color: SastaColors.gold,
            expression: MascotExpression.joy,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: SastaText.display(context, size: 20),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                actionLabel!,
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
    );
  }
}

class _CategoryRailCard extends StatelessWidget {
  const _CategoryRailCard({required this.category, required this.onTap});
  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final bg = palette.pastel(category.pastel);
    final fg = palette.pastelAccent(category.pastel);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.isDark ? palette.surface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: CategoryGlyph(
                  kind: category.iconKind,
                  color: fg,
                  size: 20,
                ),
              ),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SastaText.body(
                  context,
                  size: 13,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestDealsSection extends StatelessWidget {
  const _BestDealsSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final deals = state.products.where((p) => p.isDeal).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(
            title: 'Best deals for you',
            actionLabel: 'View all deals',
            onAction: () => SastaNav.openSearchResults(
              context,
              titleOverride: 'Best deals',
              dealsOnly: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < deals.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final p = deals[i];
                      final cheapest = p.cheapestQuote(
                        p.defaultVariantIndex,
                        enabledRetailers: state.enabledRetailers,
                      );
                      final pct = cheapest?.discountPercent;
                      return ProductGridCard(
                        width: 196,
                        product: p,
                        enabledRetailers: state.enabledRetailers,
                        badgeText: pct != null ? '-$pct%' : null,
                        onTap: () => SastaNav.openProductDetails(context, p.id),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.products.where((p) => p.isTrending).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(
            title: 'Trending now',
            actionLabel: 'See all',
            onAction: () => SastaNav.openSearchResults(
              context,
              titleOverride: 'Trending now',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  ProductGridCard(
                    width: 162,
                    product: items[i],
                    enabledRetailers: state.enabledRetailers,
                    onTap: () =>
                        SastaNav.openProductDetails(context, items[i].id),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PricesDroppedSection extends StatelessWidget {
  const _PricesDroppedSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final drops = state.products.where((p) => p.isPriceDrop).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(
            title: 'Prices dropped',
            actionLabel: 'View all',
            onAction: () => SastaNav.push(context, SastaRouteNames.notifications),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < drops.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final p = drops[i];
                      final cheapest = p.cheapestQuote(p.defaultVariantIndex);
                      return SastaCard(
                        color: palette.surface,
                        onTap: () => SastaNav.openPriceHistory(context, p.id),
                        child: SizedBox(
                          width: 236,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ProductArtTile(
                                        kind: p.artKind,
                                        pastel: p.pastel,
                                        size: 52,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: SastaText.body(
                                                context,
                                                size: 14,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${p.variantAt(p.defaultVariantIndex).label} · ${cheapest?.retailer.shortName ?? ''}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: SastaText.muted(
                                                context,
                                                size: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        cheapest != null
                                            ? '₹${cheapest.price}'
                                            : '—',
                                        style:
                                            SastaText.display(context, size: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      if (p.isLowestIn30Days)
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: SastaTag(
                                              label: 'Lowest in 30 days',
                                              backgroundColor: palette.mint,
                                              textColor: palette.successText,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => SastaNav.openPriceHistory(
                                        context,
                                        p.id,
                                      ),
                                      child: Text(
                                        'Price history →',
                                        style: SastaText.body(
                                          context,
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: palette.linkText,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => showCreatePriceAlertSheet(
                                      context,
                                      initialProduct: p,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: palette.field,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.notifications_active_outlined,
                                        size: 18,
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
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeSmartBasketCard extends StatelessWidget {
  const _HomeSmartBasketCard({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final basket = state.activeBasket;
    final comparison = state.computeBasketComparison();
    final cheapest = comparison.cheapestCompleteStore?.totalPrice ??
        comparison.splitTotal;

    return SastaCard(
      color: palette.peach,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Smart Basket',
                  style: SastaText.display(context, size: 21),
                ),
              ),
              GestureDetector(
                onTap: () => state.setActiveTab(1),
                child: Text(
                  'Open',
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
          const SizedBox(height: 6),
          Text(
            '${basket.uniqueProducts} products · ${basket.totalItems} items · est. cheapest ~₹$cheapest',
            style: SastaText.body(context, size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${basket.name} · ${basket.updatedLabel}',
            style: SastaText.muted(context, size: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SastaPrimaryButton(
                  label: 'Compare basket',
                  height: 46,
                  onPressed: () {
                    if (basket.entries.isEmpty) {
                      state.setActiveTab(1);
                    } else {
                      SastaNav.openBasketCompare(context);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SastaOutlineButton(
                  label: 'Add items',
                  height: 46,
                  onPressed: () => SastaNav.openHomeSearch(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartPicksSection extends StatelessWidget {
  const _SmartPicksSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final picks = [
      (
        id: 'pick_dahi',
        title: 'Switch to Amul Dahi 400 g',
        subtitle: 'Save ₹6 compared to your recent curd check',
        tag: 'Save ₹6 · Blinkit',
        pastel: SastaPastel.mint,
        productId: 'amul_dahi',
        variantIdx: 0,
      ),
      (
        id: 'pick_milk1l',
        title: 'Try 1 L Taaza Milk pack',
        subtitle: 'Lower unit price at ₹5.2 / 100 ml on Zepto',
        tag: 'Save ₹8 · Zepto',
        pastel: SastaPastel.lavender,
        productId: 'amul_milk',
        variantIdx: 2,
      ),
    ].where((p) => !state.dismissedPickIds.contains(p.id)).toList();

    if (picks.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(
            title: 'Smart picks for you',
            actionLabel: 'View all',
            onAction: () => SastaNav.openSearchResults(
              context,
              titleOverride: 'Smart picks',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < picks.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final pick = picks[i];
                      return SastaCard(
                        color: palette.pastel(pick.pastel),
                        shadow: false,
                        onTap: () => SastaNav.openProductDetails(
                          context,
                          pick.productId,
                          variantIndex: pick.variantIdx,
                        ),
                        child: SizedBox(
                          width: 244,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: SastaTag(
                                          label: pick.tag,
                                          backgroundColor: palette.isDark
                                              ? palette.surface
                                              : Colors.white,
                                          textColor: palette.pastelAccent(
                                            pick.pastel,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        state.dismissSmartPick(pick.id),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: palette.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pick.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: SastaText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pick.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: SastaText.muted(context, size: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreBrandsSection extends StatelessWidget {
  const _ExploreBrandsSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(title: 'Explore more brands'),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: Row(
            children: [
              for (var i = 0; i < MockCatalog.popularBrands.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SastaChip(
                  label: MockCatalog.popularBrands[i].name,
                  backgroundColor:
                      palette.pastel(MockCatalog.popularBrands[i].pastel),
                  onTap: () {
                    final name = MockCatalog.popularBrands[i].name;
                    state.addSearchQuery(name);
                    SastaNav.openSearchResults(context, query: name);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeSavingsCard extends StatelessWidget {
  const _HomeSavingsCard();

  @override
  Widget build(BuildContext context) {
    return SastaCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE9A8), Color(0xFFFFD27A)],
      ),
      onTap: () => showMonthlySavingsSheet(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        'Your savings',
                        style: SastaText.body(
                          context,
                          size: 14,
                          weight: FontWeight.w700,
                          color: SastaColors.ink,
                        ),
                      ),
                      Text(
                        'Full report →',
                        style: SastaText.body(
                          context,
                          size: 12,
                          weight: FontWeight.w700,
                          color: SastaColors.link,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PriceGradientText('₹312', size: 42),
                ),
                Text(
                  'Most economical so far: Zepto\nEstimated, not confirmed purchases',
                  style: SastaText.body(
                    context,
                    size: 12,
                    weight: FontWeight.w600,
                    color: SastaColors.ink.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const SastaMascot(
            size: 74,
            color: Colors.white,
            expression: MascotExpression.joy,
          ),
        ],
      ),
    );
  }
}

class _HomePriceAlertsCard extends StatelessWidget {
  const _HomePriceAlertsCard({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final alerts = state.priceAlerts.take(2).toList();
    return SastaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Your price alerts',
            actionLabel: 'View all',
            onAction: () =>
                SastaNav.push(context, SastaRouteNames.notifications),
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            Text(
              'No active alerts yet.',
              style: SastaText.muted(context, size: 13),
            )
          else
            for (final alert in alerts) ...[
              Builder(builder: (context) {
                final product = state.productById(alert.productId);
                if (product == null) return const SizedBox.shrink();
                final current = product
                        .cheapestQuote(product.defaultVariantIndex)
                        ?.price ??
                    alert.targetPrice;
                final progress =
                    (alert.targetPrice / current).clamp(0.45, 1.0);
                return InkWell(
                  onTap: () => SastaNav.openPriceHistory(context, product.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
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
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₹$current → target ₹${alert.targetPrice}',
                                  maxLines: 1,
                                  style: SastaText.muted(context, size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: palette.field,
                            valueColor: const AlwaysStoppedAnimation(
                              SastaColors.chartLinePurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          const SizedBox(height: 12),
          SastaChip(
            label: '+ Create price alert',
            onTap: () => showCreatePriceAlertSheet(context),
          ),
        ],
      ),
    );
  }
}

class _MonthlySavingsCard extends StatelessWidget {
  const _MonthlySavingsCard();

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      color: palette.lavender,
      shadow: false,
      onTap: () => showMonthlySavingsSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your monthly savings',
                  style: SastaText.display(context, size: 19),
                ),
              ),
              SastaTag(
                label: '+16%',
                backgroundColor: palette.mint,
                textColor: palette.successText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _MonthBar(
                  label: 'Oct · ₹268',
                  fraction: 0.72,
                  color: SastaColors.mutedGrey,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: _MonthBar(
                  label: 'Nov · ₹312',
                  fraction: 0.92,
                  color: SastaColors.chartLinePurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 58 * fraction,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: SastaText.body(context, size: 12, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SastaPlusPromoCard extends StatelessWidget {
  const _SastaPlusPromoCard({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    return SastaCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [SastaColors.promoDarkStart, SastaColors.promoDarkEnd],
      ),
      onTap: () => SastaNav.push(
        context,
        state.isPlusActive
            ? SastaRouteNames.plusManage
            : SastaRouteNames.plusLanding,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Sasta+',
                      style: SastaText.display(
                        context,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    SastaTag(
                      label: state.isPlusActive ? 'Active' : 'Free plan',
                      backgroundColor: state.isPlusActive
                          ? SastaColors.mint
                          : SastaColors.butter,
                      textColor: state.isPlusActive
                          ? SastaColors.successText
                          : SastaColors.warningText,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.isPlusActive
                      ? 'Your extended history, alerts & smarter splits are active.'
                      : 'Longer price history, smarter baskets & deeper savings insights.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: SastaColors.gold,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    state.isPlusActive ? 'Manage Sasta+' : 'Explore Sasta+',
                    style: SastaText.body(
                      context,
                      size: 13,
                      weight: FontWeight.w800,
                      color: SastaColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const FloatBob(
            amplitude: 5,
            child: SastaMascot(
              size: 74,
              color: SastaColors.gold,
              expression: MascotExpression.joy,
              hasCrown: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyComparedSection extends StatelessWidget {
  const _RecentlyComparedSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.searchHistory.take(3).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _SectionHeader(
          title: 'Recently compared',
          actionLabel: 'View all',
          onAction: () => SastaNav.push(context, SastaRouteNames.searchHistory),
        ),
        const SizedBox(height: 8),
        for (final entry in entries)
          InkWell(
            onTap: () =>
                SastaNav.openSearchResults(context, query: entry.query),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  ProductArtTile(
                    kind: entry.artKind,
                    pastel: entry.pastel,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.query,
                          style: SastaText.body(
                            context,
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          entry.subtitle,
                          style: SastaText.muted(context, size: 12),
                        ),
                      ],
                    ),
                  ),
                  SastaChip(
                    label: 'Again',
                    height: 36,
                    onTap: () =>
                        SastaNav.openSearchResults(context, query: entry.query),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentlyViewedSection extends StatelessWidget {
  const _RecentlyViewedSection({required this.state});
  final SastaAppState state;

  @override
  Widget build(BuildContext context) {
    final items = state.recentlyViewedProducts;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SastaSpace.page),
          child: _SectionHeader(
            title: 'Recently viewed',
            actionLabel: 'View all',
            onAction: () => SastaNav.openSearchResults(context),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            SastaSpace.page,
            2,
            SastaSpace.page,
            6,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                GestureDetector(
                  onTap: () =>
                      SastaNav.openProductDetails(context, items[i].id),
                  child: ProductArtTile(
                    kind: items[i].artKind,
                    pastel: items[i].pastel,
                    size: 96,
                    borderRadius: 28,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FirstTimeBasketEmptyCard extends StatelessWidget {
  const _FirstTimeBasketEmptyCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      color: palette.peach,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your basket is waiting!',
            style: SastaText.display(context, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your regular groceries once and compare your entire shopping list in one tap.',
            style: SastaText.muted(context, size: 13),
          ),
          const SizedBox(height: 14),
          SastaPrimaryButton(
            label: 'Start adding products',
            height: 48,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _FirstTimeAlertsEmptyCard extends StatelessWidget {
  const _FirstTimeAlertsEmptyCard({required this.onCreateAlert});
  final VoidCallback onCreateAlert;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return SastaCard(
      color: palette.sky,
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nothing you’re tracking yet.',
            style: SastaText.display(context, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Set a target price on milk, rice or oil to hear the moment it drops.',
            style: SastaText.muted(context, size: 13),
          ),
          const SizedBox(height: 12),
          SastaChip(
            label: 'Create price alert',
            selected: true,
            onTap: onCreateAlert,
          ),
        ],
      ),
    );
  }
}
