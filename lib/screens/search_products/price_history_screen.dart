import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';

class PriceHistoryScreen extends StatefulWidget {
  const PriceHistoryScreen({super.key, this.args});
  final ProductRouteArgs? args;

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  String _range = '30D';
  static const _ranges = ['7D', '30D', '90D', 'All'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = SastaScope.read(context);
      final pId = widget.args?.productId;
      if (pId != null && state.isApiConfigured) {
        state.refreshProductDetails(pId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final product = state.productById(widget.args?.productId ?? 'amul_milk') ??
        state.products.first;
    final vIdx = widget.args?.variantIndex ?? product.defaultVariantIndex;
    final variant = product.variantAt(vIdx);
    final cheapest = product.cheapestQuote(vIdx);
    final series = product.historyByRange[_range] ??
        product.historyByRange.values.first;

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
                      const SastaHeaderBar(title: 'Price history'),
                      const SizedBox(height: 18),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: SastaText.display(context, size: 20),
                                ),
                                Text(
                                  '${variant.label} · ${cheapest?.retailer.shortName ?? 'Compare'}',
                                  style: SastaText.muted(context, size: 13),
                                ),
                              ],
                            ),
                          ),
                          PriceGradientText(
                            cheapest != null ? '₹${cheapest.price}' : '—',
                            size: 36,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: _ranges.map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SastaChip(
                              label: r,
                              selected: _range == r,
                              onTap: () => setState(() => _range = r),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      AnimatedPriceLineChart(
                        primaryPoints: series.primaryPoints,
                        secondaryPoints: series.secondaryPoints,
                        startLabel: series.startLabel,
                        endLabel: series.endLabel,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCol(
                              label: 'Lowest',
                              value: '₹${series.lowest}',
                              color: palette.successText,
                            ),
                          ),
                          Expanded(
                            child: _StatCol(
                              label: 'Highest',
                              value: '₹${series.highest}',
                              color: palette.pinkText,
                            ),
                          ),
                          Expanded(
                            child: _StatCol(
                              label: 'Average',
                              value: '₹${series.average.toStringAsFixed(1)}',
                              color: palette.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Sample data · ${series.startLabel.toLowerCase()} to today · tap chart points to inspect.',
                        style: SastaText.muted(context, size: 12),
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
                child: SastaPrimaryButton(
                  label: 'Create price alert',
                  onPressed: () => showCreatePriceAlertSheet(
                    context,
                    initialProduct: product,
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

class _StatCol extends StatelessWidget {
  const _StatCol({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SastaText.muted(context, size: 13)),
        const SizedBox(height: 2),
        Text(
          value,
          style: SastaText.display(
            context,
            size: 24,
            color: color,
          ),
        ),
      ],
    );
  }
}
