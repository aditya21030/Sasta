import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

/// Multi-select basket action mode matching BasketSelect.dc.html (no bottom nav!).
class BasketSelectScreen extends StatefulWidget {
  const BasketSelectScreen({super.key});

  @override
  State<BasketSelectScreen> createState() => _BasketSelectScreenState();
}

class _BasketSelectScreenState extends State<BasketSelectScreen> {
  final Set<String> _selectedIds = {};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final entries = SastaScope.read(context).activeBasket.entries;
      _selectedIds.addAll(entries.take(3).map((e) => e.productId));
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final entries = state.activeBasket.entries;
    final allSelected =
        entries.isNotEmpty && _selectedIds.length == entries.length;
    final selectedEntries =
        entries.where((e) => _selectedIds.contains(e.productId)).toList();
    final selectedCount = selectedEntries.length;
    final selectedItemsCount =
        selectedEntries.fold(0, (s, e) => s + e.quantity);
    final comp =
        state.computeBasketComparison(customEntries: selectedEntries);
    final estTotal =
        comp.cheapestCompleteStore?.totalPrice ?? comp.splitTotal;

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  14,
                  SastaSpace.page,
                  12,
                ),
                child: SastaHeaderBar(
                  title: '$selectedCount selected',
                  onBack: () => Navigator.of(context).pop(),
                  trailing: TextButton(
                    onPressed: () => setState(() {
                      if (allSelected) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(entries.map((e) => e.productId));
                      }
                    }),
                    child: Text(
                      allSelected ? 'None' : 'All',
                      style: SastaText.body(
                        context,
                        size: 14,
                        weight: FontWeight.w700,
                        color: palette.linkText,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    SastaSpace.page,
                    4,
                    SastaSpace.page,
                    20,
                  ),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final p = state.productById(e.productId);
                    if (p == null) return const SizedBox.shrink();
                    final checked = _selectedIds.contains(e.productId);
                    final cheapest = p.cheapestQuote(
                      e.variantIndex,
                      enabledRetailers: state.enabledRetailers,
                    );
                    return SastaCard(
                      onTap: () => setState(() {
                        if (checked) {
                          _selectedIds.remove(e.productId);
                        } else {
                          _selectedIds.add(e.productId);
                        }
                      }),
                      border: Border.all(
                        color: checked ? palette.ink : Colors.transparent,
                        width: 2,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: checked
                                  ? palette.primaryCtaBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: checked
                                    ? palette.primaryCtaBg
                                    : palette.muted,
                                width: 2,
                              ),
                            ),
                            child: checked
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: palette.primaryCtaFg,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          ProductArtTile(
                            kind: p.artKind,
                            pastel: p.pastel,
                            size: 52,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: SastaText.body(
                                    context,
                                    size: 15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${p.variantAt(e.variantIndex).label} · qty ${e.quantity}',
                                  style: SastaText.muted(context, size: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            cheapest != null
                                ? '₹${cheapest.price! * e.quantity}'
                                : '—',
                            style: SastaText.display(context, size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  8,
                  SastaSpace.page,
                  22,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SastaColors.ink,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: SastaShadows.cta(context),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$selectedCount products · $selectedItemsCount items',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '~₹$estTotal est.',
                                style: SastaText.display(
                                  context,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ActionCircle(
                          icon: Icons.favorite_border_rounded,
                          tooltip: 'Save selected to Favourites',
                          onTap: () {
                            for (final id in _selectedIds) {
                              if (!state.isFavourite(id)) {
                                state.toggleFavourite(id);
                              }
                            }
                            showSastaToast(
                              context,
                              'Added $selectedCount items to Saved',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _ActionCircle(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Remove selected',
                          onTap: () {
                            state.removeBasketItems(_selectedIds);
                            Navigator.of(context).pop();
                            showSastaToast(context, 'Removed selected items');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SastaPrimaryButton(
                      label: 'Compare selected items',
                      backgroundColor: SastaColors.gold,
                      foregroundColor: SastaColors.ink,
                      height: 50,
                      onPressed: selectedEntries.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              SastaNav.openBasketCompare(
                                context,
                                customEntries: selectedEntries,
                              );
                            },
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

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFF2E2E2E),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
