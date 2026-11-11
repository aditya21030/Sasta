import 'package:flutter/material.dart';

import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';
import '../../widgets/sasta_motion.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 5;
  String _type = 'Suggest a feature';
  final _notesCtrl = TextEditingController();

  static const _types = ['Suggest a feature', 'Improvement', 'General'];

  String get _moodLabel => switch (_rating) {
        1 => 'Needs work',
        2 => 'Could be better',
        3 => 'Pretty useful',
        4 => 'Really liking it',
        _ => 'Loving it',
      };

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    showSastaToast(context, 'Thanks for your $_rating-star feedback!');
    Navigator.of(context).maybePop();
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
                const SastaHeaderBar(title: 'Send feedback'),
                const SizedBox(height: 16),
                FadeUp(
                  child: Column(
                    children: [
                      FloatBob(
                        amplitude: 5,
                        child: SastaMascot(
                          size: 86,
                          color: SastaColors.gold,
                          expression: _rating >= 4
                              ? MascotExpression.joy
                              : _rating == 3
                                  ? MascotExpression.happy
                                  : MascotExpression.calm,
                          haloColor: palette.butter,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'How’s Sasta so far?',
                        style: SastaText.display(context, size: 30),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final starIndex = i + 1;
                          final filled = starIndex <= _rating;
                          return Semantics(
                            button: true,
                            label: 'Rate $starIndex stars',
                            child: InkWell(
                              onTap: () => setState(() => _rating = starIndex),
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  filled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 38,
                                  color: filled
                                      ? SastaColors.goldDeep
                                      : palette.muted,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      SastaTag(
                        label: _moodLabel,
                        backgroundColor: palette.butter,
                        textColor: palette.warningText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'FEEDBACK TYPE',
                  style: SastaText.eyebrow(context),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _types)
                      SastaChip(
                        label: t,
                        selected: _type == t,
                        onTap: () => setState(() => _type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesCtrl,
                  minLines: 4,
                  maxLines: 6,
                  style: SastaText.body(
                    context,
                    size: 15,
                    weight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts',
                    filled: true,
                    fillColor: palette.field,
                    contentPadding: const EdgeInsets.all(18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(SastaRadius.card),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SastaPrimaryButton(
                  label: 'Submit feedback',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
