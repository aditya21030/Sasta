import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_sheets.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

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
                const SastaHeaderBar(title: 'Account security'),
                const SizedBox(height: 18),
                Text(
                  'Keep your account safe',
                  style: SastaText.display(context, size: 30),
                ),
                const SizedBox(height: 18),
                Text('SIGN IN', style: SastaText.eyebrow(context)),
                const SizedBox(height: 4),
                SastaListRow(
                  title: 'Login methods',
                  subtitle: 'Email link · Phone OTP',
                  icon: Icons.key_outlined,
                  badgeBackground: palette.lavender,
                  badgeForeground: palette.lavenderText,
                  onTap: () => showSastaToast(
                    context,
                    'Signed in via ${state.email}',
                  ),
                ),
                SastaListRow(
                  title: 'Change password',
                  icon: Icons.lock_reset_rounded,
                  badgeBackground: palette.sky,
                  badgeForeground: palette.skyText,
                  onTap: () => _openPasswordSheet(context),
                ),
                const SizedBox(height: 16),
                Text('VERIFICATION', style: SastaText.eyebrow(context)),
                const SizedBox(height: 4),
                SastaListRow(
                  title: 'Email address',
                  subtitle: state.email,
                  icon: Icons.mark_email_read_outlined,
                  badgeBackground: palette.mint,
                  badgeForeground: palette.successText,
                  trailing: SastaTag(
                    label: state.emailVerified ? 'Verified' : 'Verify',
                    backgroundColor: palette.mint,
                    textColor: palette.successText,
                  ),
                  onTap: () => showSastaToast(context, 'Email is verified'),
                ),
                SastaListRow(
                  title: 'Mobile number',
                  subtitle: state.maskedPhone,
                  icon: Icons.phone_android_rounded,
                  badgeBackground: palette.butter,
                  badgeForeground: palette.warningAccent,
                  trailing: SastaTag(
                    label: state.phoneVerified ? 'Verified' : 'Verify now',
                    backgroundColor:
                        state.phoneVerified ? palette.mint : palette.butter,
                    textColor: state.phoneVerified
                        ? palette.successText
                        : palette.warningText,
                  ),
                  onTap: () {
                    state.verifyPhoneNow();
                    showSastaToast(context, 'Mobile number verified');
                  },
                ),
                const SizedBox(height: 16),
                Text('DEVICES', style: SastaText.eyebrow(context)),
                const SizedBox(height: 4),
                SastaListRow(
                  title: 'Active sessions',
                  subtitle: 'This device + 1 web session',
                  icon: Icons.devices_rounded,
                  badgeBackground: palette.peach,
                  badgeForeground: palette.linkText,
                  trailing: SastaTag(
                    label: '2 devices',
                    backgroundColor: palette.field,
                    textColor: palette.ink,
                  ),
                  onTap: () => showSastaToast(
                    context,
                    '2 active sessions signed in',
                  ),
                ),
                const SizedBox(height: 26),
                SastaOutlineButton(
                  label: 'Log out from all devices',
                  onPressed: () {
                    state.logOut();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    showSastaToast(context, 'Signed out from all sessions');
                  },
                ),
                const SizedBox(height: 12),
                SastaOutlineButton(
                  label: 'Delete account',
                  borderColor: palette.dangerText,
                  textColor: palette.dangerText,
                  onPressed: () {
                    state.logOut();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    showSastaToast(context, 'Account deletion initiated');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPasswordSheet(BuildContext context) {
    final controller = TextEditingController();
    showSastaSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change password', style: SastaText.display(ctx, size: 22)),
            const SizedBox(height: 12),
            SastaSearchPill(
              controller: controller,
              hintText: 'Enter new password',
              showMic: false,
            ),
            const SizedBox(height: 16),
            SastaPrimaryButton(
              label: 'Update password',
              onPressed: () {
                Navigator.of(ctx).pop();
                showSastaToast(context, 'Password updated');
              },
            ),
          ],
        ),
      ),
    );
  }
}
