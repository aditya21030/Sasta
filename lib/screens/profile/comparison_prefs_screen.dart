import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class ComparisonPrefsScreen extends StatefulWidget {
  const ComparisonPrefsScreen({super.key});

  @override
  State<ComparisonPrefsScreen> createState() => _ComparisonPrefsScreenState();
}

class _ComparisonPrefsScreenState extends State<ComparisonPrefsScreen> {
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _apiKeyCtrl;
  bool _initialized = false;
  bool _savingApi = false;

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = SastaScope.read(context);
      _baseUrlCtrl.text = state.apiBaseUrl;
      _apiKeyCtrl.text = state.apiKey;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndSyncApi() async {
    if (_savingApi) return;
    setState(() => _savingApi = true);
    final state = SastaScope.read(context);
    final synced = await state.updateApiConfig(
      baseUrl: _baseUrlCtrl.text,
      apiKey: _apiKeyCtrl.text,
      syncNow: true,
    );
    if (!mounted) return;
    setState(() => _savingApi = false);
    if (!state.isApiConfigured) {
      showSastaToast(context, 'Cleared API endpoint · using local catalog cache');
    } else if (synced) {
      showSastaToast(
        context,
        'Synced ${state.products.length} products for ${state.activeLocation.pincode}',
      );
    } else {
      showSastaToast(
        context,
        state.lastSyncError ?? 'Saved API settings · sync failed',
      );
    }
  }

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
                const SizedBox(height: 22),
                Text('QUICK-COMMERCE API', style: SastaText.eyebrow(context)),
                const SizedBox(height: 8),
                SastaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.isLiveCatalogActive
                                ? Icons.cloud_done_rounded
                                : Icons.cloud_queue_rounded,
                            size: 18,
                            color: state.isLiveCatalogActive
                                ? palette.successText
                                : palette.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.isLiveCatalogActive
                                  ? 'Live catalog active'
                                  : (state.isApiConfigured
                                      ? 'API configured · ready to sync'
                                      : 'Using cached local catalog'),
                              style: SastaText.body(
                                context,
                                size: 13,
                                weight: FontWeight.w700,
                                color: state.isLiveCatalogActive
                                    ? palette.successText
                                    : palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (state.lastSyncError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          state.lastSyncError!,
                          style: SastaText.body(
                            context,
                            size: 12,
                            color: palette.dangerText,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _ApiTextField(
                        controller: _baseUrlCtrl,
                        hint: 'https://api.yourdomain.com',
                        label: 'API Base URL',
                      ),
                      const SizedBox(height: 10),
                      _ApiTextField(
                        controller: _apiKeyCtrl,
                        hint: 'Optional Bearer / X-API-Key',
                        label: 'API Key',
                      ),
                      const SizedBox(height: 12),
                      SastaOutlineButton(
                        label: (_savingApi || state.isCatalogSyncing)
                            ? 'Syncing live prices…'
                            : 'Save & sync live prices',
                        height: 44,
                        onPressed: (_savingApi || state.isCatalogSyncing)
                            ? null
                            : _saveAndSyncApi,
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

class _ApiTextField extends StatelessWidget {
  const _ApiTextField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SastaText.body(
            context,
            size: 12,
            weight: FontWeight.w700,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: palette.field,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            style: SastaText.body(context, size: 13, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: SastaText.muted(context, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}
