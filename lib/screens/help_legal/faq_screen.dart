import 'package:flutter/material.dart';

import '../../data/mock_catalog.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchCtrl = TextEditingController();
  late String _category;
  String _query = '';
  final Set<String> _expandedIds = {};

  static const _categories = [
    'All',
    'Getting started',
    'Price comparison',
    'Baskets',
    'Alerts',
  ];

  @override
  void initState() {
    super.initState();
    _category = (widget.initialCategory != null &&
            _categories.contains(widget.initialCategory))
        ? widget.initialCategory!
        : 'All';
    if (MockCatalog.faqs.isNotEmpty) {
      _expandedIds.add(MockCatalog.faqs.first.id);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    final items = MockCatalog.faqs.where((faq) {
      if (_category != 'All' && faq.category != _category) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        return faq.question.toLowerCase().contains(q) ||
            faq.answer.toLowerCase().contains(q);
      }
      return true;
    }).toList();

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
                const SastaHeaderBar(title: 'FAQs'),
                const SizedBox(height: 16),
                SastaSearchPill(
                  controller: _searchCtrl,
                  hintText: 'Search questions',
                  showClear: _query.isNotEmpty,
                  showMic: false,
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final cat in _categories) ...[
                        SastaChip(
                          label: cat,
                          selected: _category == cat,
                          onTap: () => setState(() => _category = cat),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  SastaCard(
                    color: palette.field,
                    shadow: false,
                    child: Text(
                      'No FAQs matched "$_query". Try clearing your filter.',
                      style: SastaText.muted(context, size: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final faq in items) ...[
                    Builder(
                      builder: (context) {
                        final expanded = _expandedIds.contains(faq.id);
                        return SastaCard(
                          color: expanded ? palette.lavender : palette.surface,
                          shadow: !expanded,
                          padding: const EdgeInsets.all(16),
                          onTap: () {
                            setState(() {
                              if (expanded) {
                                _expandedIds.remove(faq.id);
                              } else {
                                _expandedIds.add(faq.id);
                              }
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq.question,
                                      style: SastaText.body(
                                        context,
                                        size: 15,
                                        weight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: expanded
                                          ? palette.primaryCtaBg
                                          : palette.field,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      expanded
                                          ? Icons.close_rounded
                                          : Icons.add_rounded,
                                      size: 18,
                                      color: expanded
                                          ? palette.primaryCtaFg
                                          : palette.ink,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedSize(
                                duration: SastaMotion.fast,
                                curve: SastaMotion.curve,
                                alignment: Alignment.topLeft,
                                child: expanded
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          faq.answer,
                                          style: SastaText.muted(
                                            context,
                                            size: 13,
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        );
                      },
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
