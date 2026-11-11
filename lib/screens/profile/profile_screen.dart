import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: SastaText.display(ctx, size: 22)),
        content: Text(body, style: SastaText.muted(ctx, size: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final avatarStyle = _avatarStyleFor(state.avatarStyleIndex, palette);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        SastaSpace.page,
        14,
        SastaSpace.page,
        SastaSpace.navClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profile', style: SastaText.display(context, size: 35)),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                FloatBob(
                  amplitude: 5,
                  child: SastaMascot(
                    size: 108,
                    color: avatarStyle.color,
                    expression: avatarStyle.expression,
                    haloColor: avatarStyle.halo,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  state.fullName,
                  style: SastaText.display(context, size: 24),
                ),
                const SizedBox(height: 2),
                Text(state.email, style: SastaText.muted(context, size: 13)),
                Text(
                  state.maskedPhone,
                  style: SastaText.muted(context, size: 13),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 152,
                  child: SastaOutlineButton(
                    label: 'Edit profile',
                    height: 44,
                    onPressed: () => SastaNav.push(
                      context,
                      SastaRouteNames.personalInfo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SastaCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SastaColors.promoDarkStart, SastaColors.promoDarkEnd],
            ),
            onTap: () => SastaNav.push(
              context,
              state.isPlusActive
                  ? SastaRouteNames.plusManage
                  : SastaRouteNames.plusLanding,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Sasta+',
                            style: SastaText.display(
                              context,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                          SastaTag(
                            label: state.isPlusActive ? 'Active' : 'Free plan',
                            backgroundColor: state.isPlusActive
                                ? SastaColors.mint
                                : SastaColors.butter,
                            textColor: state.isPlusActive
                                ? SastaColors.successText
                                : SastaColors.warningText,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.isPlusActive
                            ? 'Manage renewal, benefits & invoices.'
                            : 'Longer price history, smarter baskets & deeper savings insights.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: SastaColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          state.isPlusActive
                              ? 'Manage Sasta+'
                              : 'Explore Sasta+',
                          style: SastaText.body(
                            context,
                            size: 13,
                            weight: FontWeight.w800,
                            color: SastaColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const SastaMascot(
                  size: 68,
                  color: SastaColors.gold,
                  expression: MascotExpression.joy,
                  hasCrown: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('ACCOUNT', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'Personal information',
            icon: Icons.person_outline_rounded,
            badgeBackground: palette.lavender,
            badgeForeground: palette.lavenderText,
            onTap: () => SastaNav.push(context, SastaRouteNames.personalInfo),
          ),
          SastaListRow(
            title: 'Manage locations',
            subtitle: '${state.activeLocation.pincode} · ${state.activeLocation.area}',
            icon: Icons.location_on_outlined,
            badgeBackground: palette.peach,
            badgeForeground: palette.linkText,
            onTap: () => SastaNav.push(context, SastaRouteNames.locations),
          ),
          SastaListRow(
            title: 'Account security',
            icon: Icons.lock_outline_rounded,
            badgeBackground: palette.mint,
            badgeForeground: palette.successText,
            onTap: () => SastaNav.push(context, SastaRouteNames.security),
          ),
          const SizedBox(height: 16),
          Text('MY SHOPPING', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'My favourites',
            icon: Icons.favorite_border_rounded,
            badgeBackground: palette.pink,
            badgeForeground: palette.pinkText,
            onTap: () => SastaNav.push(context, SastaRouteNames.favouritesPush),
          ),
          SastaListRow(
            title: 'Price drop alerts',
            icon: Icons.notifications_none_rounded,
            badgeBackground: palette.butter,
            badgeForeground: palette.warningAccent,
            onTap: () => SastaNav.push(context, SastaRouteNames.notifications),
          ),
          SastaListRow(
            title: 'Search history',
            icon: Icons.history_rounded,
            badgeBackground: palette.sky,
            badgeForeground: palette.skyText,
            onTap: () => SastaNav.push(context, SastaRouteNames.searchHistory),
          ),
          SastaListRow(
            title: 'Saved baskets',
            icon: Icons.shopping_cart_outlined,
            badgeBackground: palette.mint,
            badgeForeground: palette.successText,
            onTap: () => SastaNav.push(context, SastaRouteNames.savedBaskets),
          ),
          SastaListRow(
            title: 'Monthly savings report',
            icon: Icons.bar_chart_rounded,
            badgeBackground: palette.lavender,
            badgeForeground: palette.lavenderText,
            onTap: () => showMonthlySavingsSheet(context),
          ),
          const SizedBox(height: 16),
          Text('PREFERENCES', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'Comparison preferences',
            icon: Icons.grid_view_rounded,
            badgeBackground: palette.peach,
            badgeForeground: palette.linkText,
            onTap: () => SastaNav.push(
              context,
              SastaRouteNames.comparisonPrefs,
            ),
          ),
          SastaListRow(
            title: 'Notification settings',
            icon: Icons.tune_rounded,
            badgeBackground: palette.butter,
            badgeForeground: palette.warningAccent,
            onTap: () => SastaNav.push(
              context,
              SastaRouteNames.notificationSettings,
            ),
          ),
          SastaListRow(
            title: 'Appearance',
            icon: Icons.wb_sunny_outlined,
            badgeBackground: palette.sky,
            badgeForeground: palette.skyText,
            onTap: () => SastaNav.push(context, SastaRouteNames.appearance),
          ),
          const SizedBox(height: 16),
          Text('HELP & SUPPORT', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'Help centre',
            icon: Icons.support_outlined,
            badgeBackground: palette.mint,
            badgeForeground: palette.successText,
            onTap: () => SastaNav.push(context, SastaRouteNames.helpCentre),
          ),
          SastaListRow(
            title: 'Frequently asked questions',
            icon: Icons.help_outline_rounded,
            badgeBackground: palette.lavender,
            badgeForeground: palette.lavenderText,
            onTap: () => SastaNav.push(context, SastaRouteNames.faq),
          ),
          SastaListRow(
            title: 'Contact support',
            icon: Icons.chat_bubble_outline_rounded,
            badgeBackground: palette.pink,
            badgeForeground: palette.pinkText,
            onTap: () => SastaNav.push(context, SastaRouteNames.contactSupport),
          ),
          SastaListRow(
            title: 'Report a problem',
            icon: Icons.flag_outlined,
            badgeBackground: palette.peach,
            badgeForeground: palette.linkText,
            onTap: () => SastaNav.push(context, SastaRouteNames.contactSupport),
          ),
          SastaListRow(
            title: 'Send feedback',
            icon: Icons.edit_outlined,
            badgeBackground: palette.butter,
            badgeForeground: palette.warningAccent,
            onTap: () => SastaNav.push(context, SastaRouteNames.sendFeedback),
          ),
          SastaListRow(
            title: 'Rate Sasta',
            icon: Icons.star_border_rounded,
            badgeBackground: palette.sky,
            badgeForeground: palette.skyText,
            onTap: () => SastaNav.push(context, SastaRouteNames.sendFeedback),
          ),
          const SizedBox(height: 16),
          Text('ABOUT & LEGAL', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'About Sasta',
            icon: Icons.info_outline_rounded,
            badgeBackground: palette.lavender,
            badgeForeground: palette.lavenderText,
            onTap: () => SastaNav.push(context, SastaRouteNames.about),
          ),
          SastaListRow(
            title: 'Privacy policy',
            icon: Icons.shield_outlined,
            badgeBackground: palette.mint,
            badgeForeground: palette.successText,
            onTap: () => SastaNav.push(context, SastaRouteNames.privacy),
          ),
          SastaListRow(
            title: 'Terms & conditions',
            icon: Icons.description_outlined,
            badgeBackground: palette.peach,
            badgeForeground: palette.linkText,
            onTap: () => SastaNav.push(context, SastaRouteNames.terms),
          ),
          SastaListRow(
            title: 'Open source licences',
            icon: Icons.layers_outlined,
            badgeBackground: palette.butter,
            badgeForeground: palette.warningAccent,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Sasta',
              applicationVersion: '1.0.0 (build 1)',
            ),
          ),
          SastaListRow(
            title: 'App information',
            icon: Icons.smartphone_rounded,
            badgeBackground: palette.sky,
            badgeForeground: palette.skyText,
            onTap: () => SastaNav.push(context, SastaRouteNames.appInfo),
          ),
          const SizedBox(height: 16),
          Text('ACCOUNT ACTIONS', style: SastaText.eyebrow(context)),
          const SizedBox(height: 4),
          SastaListRow(
            title: 'Log out',
            icon: Icons.logout_rounded,
            badgeBackground: palette.field,
            badgeForeground: palette.ink,
            onTap: () => _confirmAction(
              context,
              title: 'Log out of Sasta?',
              body: 'Your local basket and preferences remain saved on this device.',
              confirmLabel: 'Log out',
              confirmColor: palette.ink,
              onConfirm: () => state.logOut(),
            ),
          ),
          SastaListRow(
            title: 'Delete account',
            icon: Icons.delete_outline_rounded,
            badgeBackground: palette.dangerBg,
            badgeForeground: palette.dangerText,
            titleColor: palette.dangerText,
            onTap: () => _confirmAction(
              context,
              title: 'Delete account?',
              body:
                  'This deletes your local baskets, alerts, locations, and profile data.',
              confirmLabel: 'Delete',
              confirmColor: palette.dangerText,
              onConfirm: () {
                state.deleteAccount().then((_) {
                  if (context.mounted) {
                    showSastaToast(context, 'Account data removed');
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

({Color color, MascotExpression expression, Color halo}) _avatarStyleFor(
  int index,
  SastaPalette palette,
) {
  return switch (index % 4) {
    1 => (
        color: SastaColors.zepto,
        expression: MascotExpression.happy,
        halo: palette.lavender,
      ),
    2 => (
        color: SastaColors.blinkit,
        expression: MascotExpression.calm,
        halo: palette.butter,
      ),
    3 => (
        color: SastaColors.instamart,
        expression: MascotExpression.joy,
        halo: palette.peach,
      ),
    _ => (
        color: SastaColors.flipkartMinutes,
        expression: MascotExpression.joy,
        halo: palette.sky,
      ),
  };
}
