import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_motion.dart';
import '../../widgets/sasta_sheets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Unread', 'Price alerts', 'Updates'];

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final items = state.notifications.where((n) {
      return switch (_filter) {
        'Unread' => n.isUnread,
        'Price alerts' => n.kind == NotificationKind.priceDrop ||
            n.kind == NotificationKind.targetReached ||
            n.kind == NotificationKind.backInStock,
        'Updates' => n.kind == NotificationKind.update ||
            n.kind == NotificationKind.savings,
        _ => true,
      };
    }).toList();

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
                SastaHeaderBar(
                  title: 'Alerts',
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(44, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: state.unreadNotificationCount == 0
                        ? null
                        : () {
                            state.markAllNotificationsRead();
                            showSastaToast(context, 'All alerts marked read');
                          },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mark all read',
                        maxLines: 1,
                        style: SastaText.body(
                          context,
                          size: 13,
                          weight: FontWeight.w700,
                          color: state.unreadNotificationCount == 0
                              ? palette.muted
                              : palette.linkText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    clipBehavior: Clip.none,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      return SastaChip(
                        label: f,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'Nothing under "$_filter" right now.',
                            style: SastaText.muted(context, size: 14),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 12,
                            color: palette.divider,
                          ),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final badge = switch (item.kind) {
                              NotificationKind.priceDrop => (
                                  bg: palette.pink,
                                  fg: palette.pinkText,
                                  icon: Icons.trending_down_rounded,
                                ),
                              NotificationKind.targetReached => (
                                  bg: palette.mint,
                                  fg: palette.successText,
                                  icon: Icons.check_circle_outline_rounded,
                                ),
                              NotificationKind.backInStock => (
                                  bg: palette.butter,
                                  fg: palette.warningAccent,
                                  icon: Icons.inventory_2_outlined,
                                ),
                              NotificationKind.savings => (
                                  bg: palette.lavender,
                                  fg: palette.lavenderText,
                                  icon: Icons.savings_outlined,
                                ),
                              NotificationKind.update => (
                                  bg: palette.sky,
                                  fg: palette.skyText,
                                  icon: Icons.system_update_rounded,
                                ),
                            };
                            return InkWell(
                              onTap: () {
                                state.markNotificationRead(item.id);
                                if (item.productId != null) {
                                  SastaNav.openPriceHistory(
                                    context,
                                    item.productId!,
                                  );
                                } else if (item.kind ==
                                    NotificationKind.savings) {
                                  showMonthlySavingsSheet(context);
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: badge.bg,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        badge.icon,
                                        size: 22,
                                        color: badge.fg,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: SastaText.body(
                                              context,
                                              size: 14,
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${item.subtitle} · ${item.timeLabel}',
                                            style: SastaText.muted(
                                              context,
                                              size: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.isUnread) ...[
                                      const SizedBox(width: 8),
                                      const PulseDot(),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                SastaOutlineButton(
                  label: '+ Create new price alert',
                  height: 48,
                  onPressed: () => showCreatePriceAlertSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
