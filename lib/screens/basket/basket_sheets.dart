import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_sheets.dart';

/// Basket options sheet matching BasketMenu.dc.html.
Future<void> showBasketOptionsSheet(BuildContext context) async {
  final state = SastaScope.read(context);
  await showSastaSheet(
    context: context,
    builder: (ctx) {
      final palette = ctx.sasta;
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
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
            const SizedBox(height: 16),
            Text('Basket options', style: SastaText.display(ctx, size: 22)),
            const SizedBox(height: 10),
            SastaListRow(
              title: 'Rename basket',
              icon: Icons.edit_outlined,
              badgeBackground: palette.lavender,
              badgeForeground: palette.lavenderText,
              onTap: () {
                Navigator.of(ctx).pop();
                showRenameBasketDialog(context, state.activeBasket);
              },
            ),
            SastaListRow(
              title: 'Save to My Baskets',
              icon: Icons.bookmark_add_outlined,
              badgeBackground: palette.mint,
              badgeForeground: palette.successText,
              onTap: () {
                Navigator.of(ctx).pop();
                SastaNav.push(context, SastaRouteNames.savedBaskets);
              },
            ),
            SastaListRow(
              title: 'Duplicate basket',
              icon: Icons.copy_all_outlined,
              badgeBackground: palette.sky,
              badgeForeground: palette.skyText,
              onTap: () {
                state.duplicateBasket(state.activeBasket.id);
                Navigator.of(ctx).pop();
                showSastaToast(context, 'Created duplicate basket');
              },
            ),
            SastaListRow(
              title: 'Share basket',
              icon: Icons.ios_share_rounded,
              badgeBackground: palette.peach,
              badgeForeground: palette.linkText,
              onTap: () {
                Navigator.of(ctx).pop();
                showBasketShareSheet(context);
              },
            ),
            SastaListRow(
              title: 'Clear basket',
              icon: Icons.delete_outline_rounded,
              badgeBackground: palette.dangerBg,
              badgeForeground: palette.dangerText,
              titleColor: palette.dangerText,
              onTap: () {
                state.clearActiveBasket();
                Navigator.of(ctx).pop();
                showSastaToast(context, 'Basket cleared');
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Share basket sheet matching BasketShare.dc.html with real clipboard copy.
Future<void> showBasketShareSheet(BuildContext context) async {
  final state = SastaScope.read(context);
  final basket = state.activeBasket;
  final comparison = state.computeBasketComparison();
  final total = comparison.cheapestCompleteStore?.totalPrice ??
      comparison.splitTotal;
  final lines = basket.entries.map((e) {
    final p = state.productById(e.productId);
    if (p == null) return '';
    final v = p.variantAt(e.variantIndex);
    final q = p.cheapestQuote(e.variantIndex, enabledRetailers: state.enabledRetailers);
    return '• ${p.name} (${v.label}) ×${e.quantity} — ~₹${(q?.price ?? 0) * e.quantity}';
  }).where((s) => s.isNotEmpty).join('\n');

  final formattedText =
      '${basket.name} · ${state.activeLocation.pincode}\n$lines\nEstimated cheapest: ~₹$total via Sasta';

  await showSastaSheet(
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
            const SizedBox(height: 16),
            Text('Share basket', style: SastaText.display(ctx, size: 22)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.field,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formattedText,
                style: SastaText.body(ctx, size: 13, height: 1.45),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ShareTile(
                  label: 'WhatsApp',
                  icon: Icons.chat_bubble_outline_rounded,
                  bg: palette.mint,
                  fg: palette.successText,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: formattedText));
                    Navigator.of(ctx).pop();
                    showSastaToast(context, 'List copied for WhatsApp sharing');
                  },
                ),
                _ShareTile(
                  label: 'Copy list',
                  icon: Icons.copy_rounded,
                  bg: palette.lavender,
                  fg: palette.lavenderText,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: formattedText));
                    Navigator.of(ctx).pop();
                    showSastaToast(context, 'Shopping list copied to clipboard');
                  },
                ),
                _ShareTile(
                  label: 'Export',
                  icon: Icons.file_upload_outlined,
                  bg: palette.sky,
                  fg: palette.skyText,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: formattedText));
                    Navigator.of(ctx).pop();
                    showSastaToast(context, 'Exported text summary');
                  },
                ),
                _ShareTile(
                  label: 'Print',
                  icon: Icons.print_outlined,
                  bg: palette.peach,
                  fg: palette.linkText,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showSastaToast(context, 'Prepared print layout');
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            SastaOutlineButton(
              label: 'More apps',
              height: 48,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formattedText));
                Navigator.of(ctx).pop();
                showSastaToast(context, 'List copied for sharing');
              },
            ),
          ],
        ),
      );
    },
  );
}

class _ShareTile extends StatelessWidget {
  const _ShareTile({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: SastaText.body(context, size: 12, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Future<void> showCreateBasketDialog(BuildContext context) async {
  final state = SastaScope.read(context);
  final controller = TextEditingController();
  await showSastaSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create new basket', style: SastaText.display(ctx, size: 22)),
          const SizedBox(height: 12),
          SastaSearchPill(
            controller: controller,
            hintText: 'e.g. Weekend Brunch',
            showMic: false,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SastaPrimaryButton(
            label: 'Create basket',
            onPressed: () {
              final created = state.createNewBasket(controller.text);
              Navigator.of(ctx).pop();
              showSastaToast(context, 'Switched to ${created.name}');
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showRenameBasketDialog(
  BuildContext context,
  SavedBasket basket,
) async {
  final state = SastaScope.read(context);
  final controller = TextEditingController(text: basket.name);
  await showSastaSheet(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Rename basket', style: SastaText.display(ctx, size: 22)),
          const SizedBox(height: 12),
          SastaSearchPill(
            controller: controller,
            hintText: 'Basket name',
            showMic: false,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SastaPrimaryButton(
            label: 'Save name',
            onPressed: () {
              state.renameBasket(basket.id, controller.text);
              Navigator.of(ctx).pop();
              showSastaToast(context, 'Basket renamed');
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> showTemplatePreviewSheet(
  BuildContext context,
  BasketTemplate template,
) async {
  final state = SastaScope.read(context);
  await showSastaSheet(
    context: context,
    builder: (ctx) {
      final palette = ctx.sasta;
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
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
            const SizedBox(height: 16),
            Text(template.title, style: SastaText.display(ctx, size: 22)),
            const SizedBox(height: 4),
            Text(template.subtitle, style: SastaText.muted(ctx, size: 13)),
            const SizedBox(height: 14),
            for (final id in template.productIds)
              Builder(builder: (context) {
                final p = state.productById(id);
                if (p == null) return const SizedBox.shrink();
                final q = p.cheapestQuote(p.defaultVariantIndex);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ProductArtTile(
                        kind: p.artKind,
                        pastel: p.pastel,
                        size: 44,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.name,
                          style: SastaText.body(
                            ctx,
                            size: 14,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        q != null ? '~₹${q.price}' : '—',
                        style: SastaText.body(
                          ctx,
                          size: 14,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 18),
            SastaPrimaryButton(
              label: 'Use this basket',
              onPressed: () {
                state.applyTemplateToNewOrActiveBasket(template);
                Navigator.of(ctx).pop();
                showSastaToast(context, 'Loaded "${template.title}"');
              },
            ),
          ],
        ),
      );
    },
  );
}
