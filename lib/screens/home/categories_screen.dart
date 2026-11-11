import 'package:flutter/material.dart';

import '../../app/sasta_routes.dart';
import '../../data/mock_catalog.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/product_art.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_motion.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final filtered = MockCatalog.categories.where((c) {
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.subtitle.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: SastaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SastaSpace.page,
                  14,
                  SastaSpace.page,
                  0,
                ),
                child: Column(
                  children: [
                    const SastaHeaderBar(title: 'All categories'),
                    const SizedBox(height: 16),
                    SastaSearchPill(
                      controller: _controller,
                      hintText: 'Search categories',
                      showMic: false,
                      showClear: _query.isNotEmpty,
                      onChanged: (v) => setState(() => _query = v),
                      onClear: () => setState(() {
                        _controller.clear();
                        _query = '';
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching categories',
                          style: SastaText.muted(context, size: 15),
                        ),
                      )
                    : GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          SastaSpace.page,
                          4,
                          SastaSpace.page,
                          SastaSpace.bottomMargin,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final cat = filtered[index];
                          final bg = palette.pastel(cat.pastel);
                          final fg = palette.pastelAccent(cat.pastel);
                          return FadeUp(
                            delay: Duration(milliseconds: 30 * index),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => SastaNav.openSearchResults(
                                  context,
                                  categoryId: cat.id,
                                  titleOverride: cat.name,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: palette.isDark
                                              ? palette.surface
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(13),
                                        ),
                                        alignment: Alignment.center,
                                        child: CategoryGlyph(
                                          kind: cat.iconKind,
                                          color: fg,
                                          size: 20,
                                        ),
                                      ),
                                      Text(
                                        cat.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: SastaText.body(
                                          context,
                                          size: 12,
                                          weight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
