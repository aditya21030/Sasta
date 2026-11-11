import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

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
                const SastaHeaderBar(title: 'Notifications'),
                const SizedBox(height: 18),
                SastaCard(
                  color: palette.lavender,
                  shadow: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All notifications',
                              style: SastaText.display(context, size: 19),
                            ),
                            Text(
                              'Master switch for price & basket alerts',
                              style: SastaText.muted(context, size: 12),
                            ),
                          ],
                        ),
                      ),
                      SastaSwitch(
                        value: state.pushNotificationsAll,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(all: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Opacity(
                  opacity: state.pushNotificationsAll ? 1.0 : 0.45,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('PRICE', style: SastaText.eyebrow(context)),
                      _NotifRow(
                        title: 'Price drops on saved items',
                        value: state.priceDropsNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(priceDrops: v),
                      ),
                      _NotifRow(
                        title: 'Target price reached',
                        value: state.targetAlertsNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(targetAlerts: v),
                      ),
                      const SizedBox(height: 12),
                      Text('PRODUCT', style: SastaText.eyebrow(context)),
                      _NotifRow(
                        title: 'Back in stock alerts',
                        value: state.backInStockNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(backInStock: v),
                      ),
                      _NotifRow(
                        title: 'Featured deal drops',
                        value: state.newDealsNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(newDeals: v),
                      ),
                      const SizedBox(height: 12),
                      Text('SHOPPING & SAVINGS', style: SastaText.eyebrow(context)),
                      _NotifRow(
                        title: 'Smart Basket savings updates',
                        value: state.basketSavingsNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(basketSavings: v),
                      ),
                      _NotifRow(
                        title: 'Weekly savings summary',
                        value: state.weeklySummaryNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(weeklySummary: v),
                      ),
                      const SizedBox(height: 12),
                      Text('GENERAL', style: SastaText.eyebrow(context)),
                      _NotifRow(
                        title: 'App updates & tips',
                        value: state.appUpdatesNotif,
                        onChanged: (v) =>
                            state.updateNotificationPrefs(appUpdates: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SastaPrimaryButton(
                  label: 'Save preferences',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSastaToast(context, 'Notification settings saved');
                  },
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      state.resetNotificationPrefs();
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

class _NotifRow extends StatelessWidget {
  const _NotifRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: SastaText.body(
                context,
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
          ),
          SastaSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
