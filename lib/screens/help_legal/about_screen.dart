import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _copyValue(BuildContext context, String label, String val) async {
    await Clipboard.setData(ClipboardData(text: val));
    if (context.mounted) {
      showSastaToast(context, 'Copied $label: $val');
    }
  }

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
                const SastaHeaderBar(title: 'About Sasta'),
                const SizedBox(height: 16),
                FadeUp(
                  child: Column(
                    children: [
                      FloatBob(
                        amplitude: 6,
                        child: SastaMascot(
                          size: 108,
                          color: SastaColors.gold,
                          expression: MascotExpression.joy,
                          haloColor: palette.butter,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'sasta.',
                        style: SastaText.display(context, size: 48),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mehenga Kyun? Sasta Hai Na!',
                        style: SastaText.body(
                          context,
                          size: 15,
                          weight: FontWeight.w700,
                          color: SastaColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SastaCard(
                  color: palette.lavender,
                  shadow: false,
                  child: Text(
                    'Sasta helps Indian households compare everyday groceries, snacks, dairy, beverages, and essentials across quick-commerce apps in one place — so you can save money without switching apps.',
                    style: SastaText.body(
                      context,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SUPPORTED RETAILERS',
                  style: SastaText.eyebrow(context),
                ),
                const SizedBox(height: 10),
                SastaCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final r in RetailerId.values)
                        Expanded(
                          child: Column(
                            children: [
                              RetailerAvatar(retailer: r, size: 42),
                              const SizedBox(height: 8),
                              Text(
                                r.shortName,
                                style: SastaText.body(
                                  context,
                                  size: 12,
                                  weight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'CONNECT',
                  style: SastaText.eyebrow(context),
                ),
                const SizedBox(height: 10),
                SastaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      SastaListRow(
                        title: 'Website',
                        subtitle: 'sasta.example',
                        icon: Icons.language_rounded,
                        badgeBackground: palette.sky,
                        badgeForeground: palette.skyText,
                        onTap: () => _copyValue(
                          context,
                          'website',
                          'https://sasta.example',
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Social media',
                        subtitle: '@sasta',
                        icon: Icons.alternate_email_rounded,
                        badgeBackground: palette.pink,
                        badgeForeground: palette.pinkText,
                        onTap: () => _copyValue(context, 'handle', '@sasta'),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Contact',
                        subtitle: 'hello@sasta.example',
                        icon: Icons.mail_outline_rounded,
                        badgeBackground: palette.mint,
                        badgeForeground: palette.successText,
                        onTap: () => _copyValue(
                          context,
                          'email',
                          'hello@sasta.example',
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
