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
      _sortBy = SastaScope.read(context).defaultSort;
      _initialized = true;
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
                    children: ['Lowest price', 'Discount', 'Availability'].map((s) {
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
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
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
                    const SizedBox(height: 14),
                    Text(headingText, style: SastaText.muted(context, size: 13)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final product = results[i];
                          final cheapest = product.cheapestQuote(
                            product.defaultVariantIndex,
                            enabledRetailers: state.enabledRetailers,
                          );
                          final pct = cheapest?.discountPercent;
                          return ProductGridCard(
                            product: product,
                            enabledRetailers: state.enabledRetailers,
                            isFavourite: state.isFavourite(product.id),
                            showFavouriteButton: true,
                            badgeText: pct != null ? '-$pct%' : null,
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
