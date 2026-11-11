import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class ComparisonPrefsScreen extends StatelessWidget {
  const ComparisonPrefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SastaHeaderBar(title: 'Comparison preferences'),
                const SizedBox(height: 18),
                Text('RETAILERS INCLUDED', style: SastaText.eyebrow(context)),
                const SizedBox(height: 6),
                for (final r in RetailerId.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        RetailerAvatar(retailer: r, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.name,
                            style: SastaText.body(
                              context,
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SastaSwitch(
                          value: state.enabledRetailers.contains(r),
                          semanticsLabel: 'Include ${r.name}',
                          onChanged: (v) {
                            if (!v && state.enabledRetailers.length <= 1) {
                              showSastaToast(
                                context,
                                'At least 1 retailer must remain active',
                              );
                              return;
                            }
                            state.toggleRetailer(r, v);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text('DEFAULT SORTING', style: SastaText.eyebrow(context)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      ['Lowest price', 'Best unit price', 'Availability'].map((s) {
                    return SastaChip(
                      label: s,
                      selected: state.defaultSort == s,
                      onTap: () => state.updateComparisonPrefs(defaultSort: s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('PRICE DISPLAY', style: SastaText.eyebrow(context)),
                const SizedBox(height: 6),
                _PrefToggleRow(
                  title: 'Show unit prices',
                  subtitle: 'Display ₹ per 100 ml / 100 g where available',
                  value: state.showUnitPrices,
                  onChanged: (v) =>
                      state.updateComparisonPrefs(showUnitPrices: v),
                ),
                _PrefToggleRow(
                  title: 'Include out-of-stock apps',
                  subtitle: 'Show unavailable retailers below available quotes',
                  value: state.includeUnavailable,
                  onChanged: (v) =>
                      state.updateComparisonPrefs(includeUnavailable: v),
                ),
                const SizedBox(height: 16),
                Text('PRODUCT MATCHING', style: SastaText.eyebrow(context)),
                const SizedBox(height: 6),
                _PrefToggleRow(
                  title: 'Match exact pack sizes',
                  subtitle: 'Avoid comparing 450 ml packs directly as 500 ml',
                  value: state.matchPackSizes,
                  onChanged: (v) =>
                      state.updateComparisonPrefs(matchPackSizes: v),
                ),
                _PrefToggleRow(
                  title: 'Suggest cheaper pack alternatives',
                  subtitle: 'Highlight better value sizes & substitutes',
                  value: state.suggestAlternatives,
                  onChanged: (v) =>
                      state.updateComparisonPrefs(suggestAlternatives: v),
                ),
                const SizedBox(height: 16),
                Text('DEFAULT BASKET MODE', style: SastaText.eyebrow(context)),
                const SizedBox(height: 10),
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: palette.field,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Row(
                    children: [
                      for (final mode in [
                        'Cheapest complete',
                        'Fewer retailers',
                      ])
                        Expanded(
                          child: GestureDetector(
                            onTap: () => state.updateComparisonPrefs(
                              defaultBasketMode: mode,
                            ),
                            child: AnimatedContainer(
                              duration: SastaMotion.fast,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: state.defaultBasketMode == mode
                                    ? palette.primaryCtaBg
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                mode,
                                style: SastaText.body(
                                  context,
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: state.defaultBasketMode == mode
                                      ? palette.primaryCtaFg
                                      : palette.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SastaPrimaryButton(
                  label: 'Save preferences',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSastaToast(context, 'Comparison preferences saved');
                  },
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      state.resetComparisonPrefs();
                      showSastaToast(context, 'Reset to defaults');
                    },
                    child: Text(
                      'Reset to defaults',
                      style: SastaText.body(
                        context,
                        size: 14,
                        weight: FontWeight.w700,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrefToggleRow extends StatelessWidget {
  const _PrefToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SastaText.body(
                    context,
                    size: 15,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: SastaText.muted(context, size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SastaSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
