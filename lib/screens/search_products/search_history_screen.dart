import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/sasta_app_state.dart';
import '../../models/models.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';

class SearchHistoryScreen extends StatelessWidget {
  const SearchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final today = state.searchHistory.where((e) => e.isToday).toList();
    final earlier = state.searchHistory.where((e) => !e.isToday).toList();

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
                  title: 'Search history',
                  trailing: TextButton(
                    onPressed: state.searchHistory.isEmpty
                        ? null
                        : () {
                            state.clearSearchHistory();
                            showSastaToast(context, 'Search history cleared');
                          },
                    child: Text(
                      'Clear all',
                      style: SastaText.body(
                        context,
                        size: 13,
                        weight: FontWeight.w700,
                        color: state.searchHistory.isEmpty
                            ? palette.muted
                            : palette.linkText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: state.searchHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SastaMascot(
                                size: 100,
                                color: SastaColors.zepto,
                                expression: MascotExpression.happy,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No search history',
                                style: SastaText.display(context, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Products you search will appear here for one-tap comparisons.',
                                textAlign: TextAlign.center,
                                style: SastaText.muted(context, size: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (today.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'TODAY',
                                  style: SastaText.eyebrow(context),
                                ),
                              ),
                              for (final entry in today)
                                _HistoryRow(
                                  entry: entry,
                                  onTap: () => SastaNav.openSearchResults(
                                    context,
                                    query: entry.query,
                                  ),
                                  onRemove: () =>
                                      state.removeSearchHistory(entry.id),
                                ),
                              const SizedBox(height: 18),
                            ],
                            if (earlier.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'EARLIER',
                                  style: SastaText.eyebrow(context),
                                ),
                              ),
                              for (final entry in earlier)
                                _HistoryRow(
                                  entry: entry,
                                  onTap: () => SastaNav.openSearchResults(
                                    context,
                                    query: entry.query,
                                  ),
                                  onRemove: () =>
                                      state.removeSearchHistory(entry.id),
                                ),
                            ],
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final SearchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ProductArtTile(
              kind: entry.artKind,
              pastel: entry.pastel,
              size: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.query,
                    style: SastaText.body(
                      context,
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(entry.subtitle, style: SastaText.muted(context, size: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove entry',
              icon: Icon(Icons.close_rounded, size: 19, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
