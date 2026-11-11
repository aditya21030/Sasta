import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class HelpCentreScreen extends StatefulWidget {
  const HelpCentreScreen({super.key});

  @override
  State<HelpCentreScreen> createState() => _HelpCentreScreenState();
}

class _HelpCentreScreenState extends State<HelpCentreScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final topics = [
      (
        title: 'Getting started',
        subtitle: 'Pincodes & supported platforms',
        icon: Icons.rocket_launch_outlined,
        bg: palette.butter,
        fg: palette.warningText,
        faqCat: 'Getting started',
      ),
      (
        title: 'Product comparison',
        subtitle: 'Prices, variants & unit cost',
        icon: Icons.compare_arrows_rounded,
        bg: palette.lavender,
        fg: palette.lavenderText,
        faqCat: 'Price comparison',
      ),
      (
        title: 'Smart Basket',
        subtitle: 'Building & saving weekly lists',
        icon: Icons.shopping_basket_outlined,
        bg: palette.mint,
        fg: palette.successText,
        faqCat: 'Baskets',
      ),
      (
        title: 'Split basket',
        subtitle: 'Multi-store savings explained',
        icon: Icons.call_split_rounded,
        bg: palette.peach,
        fg: palette.linkText,
        faqCat: 'Baskets',
      ),
      (
        title: 'Price alerts',
        subtitle: 'Target drop notifications',
        icon: Icons.notifications_active_outlined,
        bg: palette.pink,
        fg: palette.pinkText,
        faqCat: 'Alerts',
      ),
      (
        title: 'Sasta+',
        subtitle: 'Plans, billing & cancellation',
        icon: Icons.workspace_premium_outlined,
        bg: palette.sky,
        fg: palette.skyText,
        faqCat: 'Getting started',
      ),
      (
        title: 'Location & availability',
        subtitle: 'Stock changes across areas',
        icon: Icons.location_on_outlined,
        bg: palette.mint,
        fg: palette.successText,
        faqCat: 'Price comparison',
      ),
      (
        title: 'Retailer redirection',
        subtitle: 'Opening items in store apps',
        icon: Icons.open_in_new_rounded,
        bg: palette.lavender,
        fg: palette.lavenderText,
        faqCat: 'Price comparison',
      ),
    ];

    final filtered = topics.where((t) {
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.subtitle.toLowerCase().contains(q);
    }).toList();

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
                const SastaHeaderBar(title: 'Help centre'),
                const SizedBox(height: 16),
                SastaSearchPill(
                  controller: _searchCtrl,
                  hintText: 'Search help topics',
                  showClear: _query.isNotEmpty,
                  showMic: false,
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  SastaCard(
                    color: palette.field,
                    shadow: false,
                    child: Column(
                      children: [
                        Text(
                          'No matching topics',
                          style: SastaText.display(context, size: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try searching FAQs or reach out directly below.',
                          style: SastaText.muted(context, size: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 112 +
                          44 *
                              MediaQuery.textScalerOf(context)
                                  .scale(1.0)
                                  .clamp(1.0, 2.0),
                    ),
                    itemBuilder: (context, index) {
                      final topic = filtered[index];
                      return FadeUp(
                        delay: Duration(milliseconds: index * 35),
                        child: SastaCard(
                          color: topic.bg,
                          shadow: false,
                          padding: const EdgeInsets.all(14),
                          onTap: () {
                            if (topic.title == 'Sasta+') {
                              SastaNav.push(
                                context,
                                SastaRouteNames.plusLanding,
                              );
                            } else {
                              SastaNav.push(
                                context,
                                SastaRouteNames.faq,
                                arguments: topic.faqCat,
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: palette.isDark
                                      ? palette.surface.withValues(alpha: 0.7)
                                      : Colors.white.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  topic.icon,
                                  size: 20,
                                  color: topic.fg,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                topic.title,
                                style: SastaText.body(
                                  context,
                                  size: 14,
                                  weight: FontWeight.w800,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                topic.subtitle,
                                style: SastaText.muted(
                                  context,
                                  size: 12,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                SastaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      SastaListRow(
                        title: 'Browse all FAQs',
                        subtitle: 'Quick answers on prices & baskets',
                        icon: Icons.help_outline_rounded,
                        badgeBackground: palette.sky,
                        badgeForeground: palette.skyText,
                        onTap: () => SastaNav.push(context, SastaRouteNames.faq),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Send feedback',
                        subtitle: 'Rate Sasta or suggest features',
                        icon: Icons.star_border_rounded,
                        badgeBackground: palette.butter,
                        badgeForeground: palette.warningText,
                        onTap: () => SastaNav.push(
                          context,
                          SastaRouteNames.sendFeedback,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SastaCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SastaColors.promoDarkStart,
                      SastaColors.promoDarkEnd,
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  onTap: () => SastaNav.push(
                    context,
                    SastaRouteNames.contactSupport,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Still stuck?',
                              style: SastaText.display(
                                context,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Talk to our support team about incorrect prices or pincodes.',
                              style: SastaText.body(
                                context,
                                size: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SastaTag(
                              label: 'Contact support →',
                              backgroundColor: SastaColors.gold,
                              textColor: SastaColors.ink,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const FloatBob(
                        amplitude: 5,
                        child: SastaMascot(
                          size: 66,
                          color: SastaColors.gold,
                          expression: MascotExpression.happy,
                        ),
                      ),
                    ],
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
