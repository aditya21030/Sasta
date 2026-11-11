import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_sheets.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  bool _checkedUpdates = false;

  void _showAcknowledgements(BuildContext context) {
    showSastaSheet(
      context: context,
      builder: (ctx) {
        final palette = ctx.sasta;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Third-party acknowledgements',
                style: SastaText.display(ctx, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                '• Flutter SDK & Material Icons\n'
                '• Bricolage Grotesque & DM Sans via Google Fonts\n'
                '• Retailer names (Blinkit, Zepto, Swiggy Instamart, Flipkart Minutes) belong to their respective owners and are shown with sample comparison prices.',
                style: SastaText.muted(ctx, size: 13),
              ),
              const SizedBox(height: 18),
              SastaPrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
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
                const SastaHeaderBar(title: 'App information'),
                const SizedBox(height: 18),
                Center(
                  child: Column(
                    children: [
                      SastaMascot(
                        size: 92,
                        color: SastaColors.gold,
                        expression: MascotExpression.happy,
                        haloColor: palette.lavender,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'sasta.',
                        style: SastaText.display(context, size: 34),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0 (build 1)',
                        style: SastaText.muted(context, size: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SastaPrimaryButton(
                  label: _checkedUpdates
                      ? 'Up to date (v1.0.0)'
                      : 'Check for updates',
                  onPressed: () {
                    setState(() => _checkedUpdates = true);
                    showSastaToast(
                      context,
                      'You are running the latest version of Sasta.',
                    );
                  },
                ),
                const SizedBox(height: 22),
                Text('MORE', style: SastaText.eyebrow(context)),
                const SizedBox(height: 10),
                SastaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      SastaListRow(
                        title: 'Open-source licences',
                        icon: Icons.code_rounded,
                        badgeBackground: palette.lavender,
                        badgeForeground: palette.lavenderText,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'Sasta',
                          applicationVersion: '1.0.0 (build 1)',
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Third-party acknowledgements',
                        icon: Icons.article_outlined,
                        badgeBackground: palette.sky,
                        badgeForeground: palette.skyText,
                        onTap: () => _showAcknowledgements(context),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Rate Sasta',
                        icon: Icons.star_outline_rounded,
                        badgeBackground: palette.butter,
                        badgeForeground: palette.warningText,
                        onTap: () => SastaNav.push(
                          context,
                          SastaRouteNames.sendFeedback,
                        ),
                      ),
                      Divider(height: 1, color: palette.divider),
                      SastaListRow(
                        title: 'Share Sasta',
                        icon: Icons.ios_share_rounded,
                        badgeBackground: palette.mint,
                        badgeForeground: palette.successText,
                        onTap: () => showSastaToast(
                          context,
                          'Invite link ready: sasta.example/download',
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
