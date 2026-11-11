import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/mock_catalog.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class HomeSearchScreen extends StatefulWidget {
  const HomeSearchScreen({super.key});

  @override
  State<HomeSearchScreen> createState() => _HomeSearchScreenState();
}

class _HomeSearchScreenState extends State<HomeSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    SastaScope.read(context).addSearchQuery(q);
    SastaNav.openSearchResults(context, query: q);
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final suggestions = _query.trim().isEmpty
        ? state.products.take(4).toList()
        : state.searchProducts(_query);

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            children: [
              Row(
                children: [
                  const SastaBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SastaSearchPill(
                      controller: _controller,
                      autofocus: true,
                      hintText: 'Search milk, rice, atta…',
                      showClear: _query.isNotEmpty,
                      onChanged: (v) => setState(() => _query = v),
                      onSubmitted: _runSearch,
                      onClear: () => setState(() {
                        _controller.clear();
                        _query = '';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text('SUGGESTIONS', style: SastaText.eyebrow(context)),
                  ),
                  if (_query.trim().isNotEmpty)
                    InkWell(
                      onTap: () => _runSearch(_query),
                      child: Text(
                        'See all results →',
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
              if (suggestions.isEmpty)
                SastaCard(
                  color: palette.field,
                  shadow: false,
                  child: Text(
                    'No exact product match for "$_query". Tap Search to view broader results.',
                    style: SastaText.muted(context, size: 13),
                  ),
                )
              else
                for (final product in suggestions.take(5))
                  InkWell(
                    onTap: () {
                      state.addSearchQuery(product.name);
                      SastaNav.openProductDetails(context, product.id);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          ProductArtTile(
                            kind: product.artKind,
                            pastel: product.pastel,
                            size: 56,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  '${product.categoryLabel} · ${product.variantAt(product.defaultVariantIndex).label}',
                                  style: SastaText.muted(context, size: 12),
                                ),
                              ],
                            ),
                          ),
                          Builder(builder: (context) {
                            final q =
                                product.cheapestQuote(product.defaultVariantIndex);
                            return SastaTag(
                              label: q != null ? 'From ₹${q.price}' : 'Compare',
                              backgroundColor: palette.lavender,
                              textColor: palette.lavenderText,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 22),
              Text('RECENT SEARCHES', style: SastaText.eyebrow(context)),
              const SizedBox(height: 10),
              if (state.searchHistory.isEmpty)
                Text(
                  'No recent searches yet.',
                  style: SastaText.muted(context, size: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.searchHistory.take(6).map((entry) {
                    return SastaChip(
                      label: entry.query,
                      leading: const Icon(Icons.history_rounded),
                      onTap: () => _runSearch(entry.query),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 22),
              Text('TRENDING', style: SastaText.eyebrow(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MockCatalog.popularSearches.take(8).map((term) {
                  return SastaChip(
                    label: term,
                    leading: const Icon(Icons.trending_up_rounded),
                    onTap: () => _runSearch(term),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
