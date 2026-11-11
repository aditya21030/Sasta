import 'package:flutter/material.dart';

import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
    required this.icon,
    required this.pastel,
  });

  final String title;
  final String body;
  final IconData icon;
  final SastaPastel pastel;
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    _LegalSection(
      title: '1. Information we collect',
      body:
          'We store the saved delivery pincodes, baskets, favourited products, and optional price alert targets you create to compare grocery prices across platforms.',
      icon: Icons.badge_outlined,
      pastel: SastaPastel.lavender,
    ),
    _LegalSection(
      title: '2. Location permissions',
      body:
          'Location or pincode data is used solely to estimate store availability and quick-commerce pricing near you. You can switch pincodes manually at any time.',
      icon: Icons.location_on_outlined,
      pastel: SastaPastel.mint,
    ),
    _LegalSection(
      title: '3. How we use information',
      body:
          'Your preferences power personalised comparison sorting, split-basket savings calculations, and opt-in price-drop alerts.',
      icon: Icons.tune_rounded,
      pastel: SastaPastel.sky,
    ),
    _LegalSection(
      title: '4. Data protection',
      body:
          'Account details and saved preferences are protected in transit and kept minimal so only essential grocery comparison state is retained.',
      icon: Icons.shield_outlined,
      pastel: SastaPastel.butter,
    ),
    _LegalSection(
      title: '5. Third-party services',
      body:
          'When you tap out to Blinkit, Zepto, Swiggy Instamart, or Flipkart Minutes to place an order, your session continues under that retailer’s own privacy policy.',
      icon: Icons.open_in_new_rounded,
      pastel: SastaPastel.peach,
    ),
    _LegalSection(
      title: '6. Your privacy rights',
      body:
          'You may update personal details, manage notification opt-ins, or clear search history directly inside Sasta settings.',
      icon: Icons.verified_user_outlined,
      pastel: SastaPastel.pink,
    ),
    _LegalSection(
      title: '7. Data deletion',
      body:
          'You can remove saved locations, clear search history, or delete all locally stored data from Profile → Account security.',
      icon: Icons.delete_outline_rounded,
      pastel: SastaPastel.lavender,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScaffold(
      title: 'Privacy policy',
      heading: 'Your privacy',
      sections: _sections,
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _LegalSection(
      title: '1. Using Sasta',
      body:
          'Sasta provides quick-commerce grocery price comparisons for personal, non-commercial household shopping across supported cities and pincodes.',
      icon: Icons.storefront_outlined,
      pastel: SastaPastel.butter,
    ),
    _LegalSection(
      title: '2. Prices are estimates',
      body:
          'Displayed prices, surge fees, and discounts are comparison estimates gathered for your selected pincode and may update at retailer checkout.',
      icon: Icons.currency_rupee_rounded,
      pastel: SastaPastel.peach,
    ),
    _LegalSection(
      title: '3. Availability',
      body:
          'Dark-store inventory changes rapidly. An item marked In stock or Low stock on Sasta reflects the latest check and is confirmed on the retailer app.',
      icon: Icons.inventory_2_outlined,
      pastel: SastaPastel.mint,
    ),
    _LegalSection(
      title: '4. Retailer responsibility',
      body:
          'Orders, payments, substitutions, and 10-minute deliveries are fulfilled directly by the chosen retailer platform.',
      icon: Icons.local_shipping_outlined,
      pastel: SastaPastel.sky,
    ),
    _LegalSection(
      title: '5. Leaving Sasta',
      body:
          'We show a clear handoff notice before redirecting you to an external retailer app or website.',
      icon: Icons.exit_to_app_rounded,
      pastel: SastaPastel.lavender,
    ),
    _LegalSection(
      title: '6. Sasta+ subscription',
      body:
          'Sasta+ unlocks 90-day price history, unlimited price alerts, and unlimited live price checks. Plan renewals and cancellations can be managed anytime in Manage Sasta+.',
      icon: Icons.workspace_premium_outlined,
      pastel: SastaPastel.pink,
    ),
    _LegalSection(
      title: '7. Payments',
      body:
          'Subscription charges, when enabled, follow your selected billing interval with transparent invoice records in Subscription history.',
      icon: Icons.payments_outlined,
      pastel: SastaPastel.mint,
    ),
    _LegalSection(
      title: '8. Limitation of liability',
      body:
          'Sasta is not responsible for stockouts, delivery delays, or final checkout pricing applied by external quick-commerce retailers.',
      icon: Icons.gavel_outlined,
      pastel: SastaPastel.lavender,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _LegalDocumentScaffold(
      title: 'Terms of use',
      heading: 'Terms of use',
      sections: _sections,
    );
  }
}

class _LegalDocumentScaffold extends StatelessWidget {
  const _LegalDocumentScaffold({
    required this.title,
    required this.heading,
    required this.sections,
  });

  final String title;
  final String heading;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
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
                SastaHeaderBar(title: title),
                const SizedBox(height: 18),
                Text(heading, style: SastaText.display(context, size: 30)),
                const SizedBox(height: 6),
                Text(
                  'How Sasta handles grocery comparison data and retailer handoffs.',
                  style: SastaText.muted(context, size: 14),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SastaTag(
                    label: 'Last updated: 8 Nov 2026',
                    backgroundColor: palette.butter,
                    textColor: palette.warningText,
                  ),
                ),
                const SizedBox(height: 18),
                for (final section in sections) ...[
                  SastaCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: palette.pastel(section.pastel),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            section.icon,
                            size: 20,
                            color: palette.pastelAccent(section.pastel),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: SastaText.body(
                                  context,
                                  size: 15,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                section.body,
                                style: SastaText.muted(context, size: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
