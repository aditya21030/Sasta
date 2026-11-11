import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key, this.isTabRoot = true});

  final bool isTabRoot;

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final favourites =
        state.products.where((p) => state.isFavourite(p.id)).toList();

    final body = SafeArea(
      bottom: !isTabRoot,
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
                if (!isTabRoot) ...[
                  const SastaHeaderBar(title: 'My favourites'),
                  const SizedBox(height: 12),
                ] else ...[
                  Text('Saved', style: SastaText.display(context, size: 35)),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${favourites.length} products · we’ll flag price drops',
                  style: SastaText.muted(context, size: 14),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          Expanded(
            child: favourites.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SastaMascot(
                            size: 124,
                            color: SastaColors.pink,
                            expression: MascotExpression.happy,
                            haloColor: context.sasta.lavender,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved items yet',
                            style: SastaText.display(context, size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the heart on any product to track drops across stores.',
                            textAlign: TextAlign.center,
                            style: SastaText.muted(context, size: 14),
                          ),
                          const SizedBox(height: 18),
                          SastaPrimaryButton(
                            label: 'Explore deals',
                            onPressed: () =>
                                SastaNav.openSearchResults(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      SastaSpace.page,
                      0,
                      SastaSpace.page,
                      isTabRoot
                          ? SastaSpace.navClearance
                          : SastaSpace.bottomMargin,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: favourites.length,
                    itemBuilder: (context, i) {
                      final product = favourites[i];
                      return ProductGridCard(
                        product: product,
                        enabledRetailers: state.enabledRetailers,
                        isFavourite: true,
                        showFavouriteButton: true,
                        badgeText: product.isLowestIn30Days
                            ? 'Lowest'
                            : (product.trendTag != null ? '↓ Drop' : null),
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
    );

    if (isTabRoot) return body;

    return Scaffold(
      body: SastaBackground(child: body),
    );
  }
}
