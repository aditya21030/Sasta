import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_sheets.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.args});

  final SearchResultsArgs? args;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _controller;
  late String _query;
  String? _categoryId;
  RetailerId? _retailerFilter;
  bool _inStockOnly = false;
  bool _under50 = false;
  late String _sortBy;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _query = widget.args?.query ?? '';
    _categoryId = widget.args?.categoryId;
    _controller = TextEditingController(text: _query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = SastaScope.read(context);
      _sortBy = state.defaultSort;
      _initialized = true;
      if (state.isApiConfigured &&
          !state.onDemandLiveMode &&
          (_query.trim().isNotEmpty || (_categoryId?.isNotEmpty ?? false))) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          state.searchProductsRemote(_query, categoryId: _categoryId);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    await showSastaSheet(
      context: context,
      builder: (ctx) {
        final palette = ctx.sasta;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
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
                  Text('Filter & sort', style: SastaText.display(ctx, size: 24)),
                  const SizedBox(height: 16),
                  Text('RETAILER', style: SastaText.eyebrow(ctx)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SastaChip(
                        label: 'All apps',
                        selected: _retailerFilter == null,
                        onTap: () {
                          setModalState(() {});
                          setState(() => _retailerFilter = null);
                        },
                      ),
                      for (final r in RetailerId.values)
                        SastaChip(
                          label: r.shortName,
                          selected: _retailerFilter == r,
                          onTap: () {
                            setModalState(() {});
                            setState(() => _retailerFilter = r);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('SORT BY', style: SastaText.eyebrow(ctx)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Lowest price',
                      'Best unit price',
                      'Discount',
                      'Availability',
                    ].map((s) {
                      return SastaChip(
                        label: s,
                        selected: _sortBy == s,
                        onTap: () {
                          setModalState(() {});
                          setState(() => _sortBy = s);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SastaPrimaryButton(
                    label: 'Apply filters',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    var results = state.searchProducts(
      _query,
      categoryId: _categoryId,
      retailerFilter: _retailerFilter,
      inStockOnly: _inStockOnly,
      maxPrice: _under50 ? 50 : null,
      sortBy: _sortBy,
    );
    if (widget.args?.dealsOnly == true && _query.isEmpty && _categoryId == null) {
      results = results.where((p) => p.isDeal).toList();
    } else if (widget.args?.trendingOnly == true &&
        _query.isEmpty &&
        _categoryId == null) {
      results = results.where((p) => p.isTrending).toList();
    }

    final headingText = _query.trim().isNotEmpty
        ? '${results.length} results for "${_query.trim()}"'
        : widget.args?.titleOverride != null
            ? '${results.length} in ${widget.args!.titleOverride}'
            : '${results.length} products near ${state.activeLocation.pincode}';

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  14,
                  SastaSpace.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SastaBackButton(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SastaSearchPill(
                            controller: _controller,
                            hintText: 'Search products…',
                            showClear: _query.isNotEmpty,
                            onChanged: (v) => setState(() => _query = v),
                            onSubmitted: (v) {
                              state.addSearchQuery(v);
                              setState(() => _query = v);
                              if (state.isApiConfigured) {
                                final hasCached = state.hasFreshCacheFor(
                                  query: v,
                                  categoryId: _categoryId,
                                );
                                if (!hasCached && state.isLiveQuotaExhausted) {
                                  showSastaToast(
                                    context,
                                    'Daily ${SastaAppState.freeDailyLiveSearchLimit}/${SastaAppState.freeDailyLiveSearchLimit} free live searches used. Showing cached prices.',
                                  );
                                } else {
                                  state.searchProductsRemote(
                                    v,
                                    categoryId: _categoryId,
                                  );
                                }
                              }
                            },
                            onClear: () => setState(() {
                              _controller.clear();
                              _query = '';
                              _categoryId = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SastaChip(
                            label: _retailerFilter?.shortName ?? 'All apps',
                            selected: _retailerFilter == null,
                            onTap: () => setState(() => _retailerFilter = null),
                          ),
                          const SizedBox(width: 8),
                          SastaChip(
                            label: 'Filter',
                            leading: const Icon(Icons.tune_rounded),
                            onTap: _openFilterSheet,
                          ),
                          const SizedBox(width: 8),
                          SastaChip(
                            label: 'In stock',
                            selected: _inStockOnly,
                            onTap: () =>
                                setState(() => _inStockOnly = !_inStockOnly),
                          ),
                          const SizedBox(width: 8),
                          SastaChip(
                            label: 'Under ₹50',
                            selected: _under50,
                            onTap: () => setState(() => _under50 = !_under50),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state.isApiConfigured &&
                        (_query.trim().isNotEmpty ||
                            (_categoryId?.isNotEmpty ?? false))) ...[
                      _LiveFetchBanner(
                        hasFreshCache: state.hasFreshCacheFor(
                          query: _query,
                          categoryId: _categoryId,
                        ),
                        estimatedCredits: state.estimatedCreditsPerSearch,
                        hasUnlimited: state.hasUnlimitedLiveSearches,
                        remainingFree: state.remainingFreeLiveSearches,
                        isLoading: state.isSearchingRemote,
                        onFetchLive: () {
                          if (state.isSearchingRemote) return;
                          if (state.isLiveQuotaExhausted) {
                            showSastaToast(
                              context,
                              'Daily ${SastaAppState.freeDailyLiveSearchLimit}/${SastaAppState.freeDailyLiveSearchLimit} free live searches used. Showing cached prices.',
                            );
                            return;
                          }
                          state.searchProductsRemote(
                            _query,
                            categoryId: _categoryId,
                            forceRefresh: true,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            headingText,
                            style: SastaText.muted(context, size: 13),
                          ),
                        ),
                        if (state.isSearchingRemote)
                          Text(
                            'Updating live…',
                            style: SastaText.muted(
                              context,
                              size: 12,
                              weight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (state.isSearchingRemote) ...[
                      const SizedBox(height: 6),
                      const ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SastaMascot(
                                size: 96,
                                color: SastaColors.mutedGrey,
                                expression: MascotExpression.sad,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No products matched',
                                style: SastaText.display(context, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try clearing a filter or searching for milk, rice, bread or oil.',
                                textAlign: TextAlign.center,
                                style: SastaText.muted(context, size: 14),
                              ),
                              const SizedBox(height: 16),
                              if (state.isApiConfigured &&
                                  (_query.trim().isNotEmpty ||
                                      (_categoryId?.isNotEmpty ?? false))) ...[
                                SastaPrimaryButton(
                                  label: state.isSearchingRemote
                                      ? 'Searching live stores…'
                                      : 'Fetch live store results',
                                  onPressed: state.isSearchingRemote
                                      ? null
                                      : () => state.searchProductsRemote(
                                            _query,
                                            categoryId: _categoryId,
                                            forceRefresh: true,
                                          ),
                                ),
                                const SizedBox(height: 10),
                              ] else if (!state.isApiConfigured) ...[
                                SastaPrimaryButton(
                                  label: 'Connect API for live search',
                                  onPressed: () => SastaNav.push(
                                    context,
                                    SastaRouteNames.comparisonPrefs,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              SastaChip(
                                label: 'Reset filters',
                                selected: true,
                                onTap: () => setState(() {
                                  _controller.clear();
                                  _query = '';
                                  _categoryId = null;
                                  _retailerFilter = null;
                                  _inStockOnly = false;
                                  _under50 = false;
                                  _sortBy = state.defaultSort;
                                }),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          SastaSpace.page,
                          0,
                          SastaSpace.page,
                          SastaSpace.bottomMargin,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 234 +
                              54 *
                                  MediaQuery.textScalerOf(context)
                                      .scale(1.0)
                                      .clamp(1.0, 2.8),
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final product = results[i];
                          final cheapest = product.cheapestQuote(
                            product.defaultVariantIndex,
                            enabledRetailers: state.enabledRetailers,
                          );
                          final availCount = product.availableAppCount(
                            product.defaultVariantIndex,
                            enabledRetailers: state.enabledRetailers,
                          );
                          final pct = cheapest?.discountPercent;
                          final badge = pct != null
                              ? '-$pct%'
                              : product.isLowestIn30Days
                                  ? 'Lowest'
                                  : (availCount >= 3 &&
                                          product.trendTag ==
                                              'Widely available'
                                      ? '$availCount apps'
                                      : null);
                          return ProductGridCard(
                            product: product,
                            enabledRetailers: state.enabledRetailers,
                            isFavourite: state.isFavourite(product.id),
                            showFavouriteButton: true,
                            badgeText: badge,
                            onToggleFavourite: () =>
                                state.toggleFavourite(product.id),
                            onTap: () => SastaNav.openProductDetails(
                              context,
                              product.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveFetchBanner extends StatelessWidget {
  const _LiveFetchBanner({
    required this.hasFreshCache,
    required this.estimatedCredits,
    required this.hasUnlimited,
    required this.remainingFree,
    required this.isLoading,
    required this.onFetchLive,
  });

  final bool hasFreshCache;
  final int estimatedCredits;
  final bool hasUnlimited;
  final int? remainingFree;
  final bool isLoading;
  final VoidCallback onFetchLive;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final statusLabel = hasFreshCache
        ? 'Cached live prices · 0 credits'
        : hasUnlimited
            ? 'Cached catalog · Fetch live prices'
            : 'Saved catalog · Live ~$estimatedCredits cr (${remainingFree ?? 0}/${SastaAppState.freeDailyLiveSearchLimit} left)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Icon(
            hasFreshCache
                ? Icons.offline_pin_outlined
                : Icons.bolt_rounded,
            size: 16,
            color: hasFreshCache ? palette.successText : palette.warningAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusLabel,
              style: SastaText.muted(context, size: 12, weight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onFetchLive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: hasFreshCache ? Colors.transparent : palette.primaryCtaBg,
                borderRadius: BorderRadius.circular(14),
                border: hasFreshCache
                    ? Border.all(color: palette.divider)
                    : null,
              ),
              child: Text(
                isLoading
                    ? 'Loading…'
                    : hasFreshCache
                        ? 'Refresh'
                        : 'Fetch live',
                style: SastaText.body(
                  context,
                  size: 11,
                  weight: FontWeight.w700,
                  color: hasFreshCache
                      ? palette.ink
                      : palette.primaryCtaFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
