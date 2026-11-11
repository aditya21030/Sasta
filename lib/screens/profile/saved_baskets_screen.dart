import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../basket/basket_sheets.dart';

class SavedBasketsScreen extends StatelessWidget {
  const SavedBasketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SastaSpace.page,
              14,
              SastaSpace.page,
              SastaSpace.bottomMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SastaHeaderBar(title: 'Saved baskets'),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.savedBaskets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final basket = state.savedBaskets[i];
                      final comp = state.computeBasketComparison(
                        customEntries: basket.entries,
                      );
                      final est = comp.cheapestCompleteStore?.totalPrice ??
                          comp.splitTotal;
                      final thumbs = basket.entries
                          .map((e) => state.productById(e.productId))
                          .where((p) => p != null)
                          .take(4)
                          .toList();
                      final isActive = basket.id == state.activeBasket.id;

                      return SastaCard(
                        color: palette.pastel(basket.pastel),
                        shadow: false,
                        onTap: () {
                          state.selectActiveBasket(basket.id);
                          state.setActiveTab(1);
                          Navigator.of(context).popUntil((r) => r.isFirst);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    basket.name,
                                    style: SastaText.display(
                                      context,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  SastaTag(
                                    label: 'Current',
                                    backgroundColor: palette.primaryCtaBg,
                                    textColor: palette.primaryCtaFg,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${basket.uniqueProducts} products · ${basket.totalItems} items · ~₹$est',
                              style: SastaText.muted(context, size: 13),
                            ),
                            const SizedBox(height: 12),
                            if (thumbs.isNotEmpty)
                              Row(
                                children: [
                                  for (final p in thumbs) ...[
                                    ProductArtTile(
                                      kind: p!.artKind,
                                      pastel: p.pastel,
                                      size: 40,
                                      borderRadius: 12,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: SastaChip(
                                      label: 'Compare',
                                      selected: true,
                                      height: 40,
                                      onTap: () => SastaNav.openBasketCompare(
                                        context,
                                        customEntries: basket.entries,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _MiniActionCircle(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'Rename basket',
                                      onTap: () => showRenameBasketDialog(
                                        context,
                                        basket,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _MiniActionCircle(
                                      icon: Icons.copy_rounded,
                                      tooltip: 'Duplicate basket',
                                      onTap: () {
                                        state.duplicateBasket(basket.id);
                                        showSastaToast(
                                          context,
                                          'Basket duplicated',
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _MiniActionCircle(
                                      icon: Icons.delete_outline_rounded,
                                      tooltip: 'Delete basket',
                                      iconColor: palette.dangerText,
                                      onTap: () {
                                        state.deleteBasket(basket.id);
                                        showSastaToast(
                                          context,
                                          'Basket removed',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SastaPrimaryButton(
                  label: '+ Create new basket',
                  onPressed: () => showCreateBasketDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniActionCircle extends StatelessWidget {
  const _MiniActionCircle({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.isDark ? palette.surface : Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor ?? palette.ink),
        ),
      ),
    );
  }
}
