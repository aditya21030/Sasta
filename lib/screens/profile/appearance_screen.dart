import 'package:flutter/material.dart';

import '../../data/sasta_app_state.dart';
import '../../theme/sasta_theme.dart';
import '../../theme/sasta_tokens.dart';
import '../../widgets/sasta_background.dart';
import '../../widgets/sasta_components.dart';
import '../../widgets/sasta_mascot.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final palette = context.sasta;
    final current = state.themeMode;

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
                const SastaHeaderBar(title: 'Appearance'),
                const SizedBox(height: 18),
                Text(
                  'Pick your look',
                  style: SastaText.display(context, size: 30),
                ),
                const SizedBox(height: 6),
                Text(
                  'Changes apply instantly.',
                  style: SastaText.muted(context, size: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'Light',
                        previewDark: false,
                        isSplit: false,
                        selected: current == ThemeMode.light,
                        onTap: () => state.setThemeMode(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'Dark',
                        previewDark: true,
                        isSplit: false,
                        selected: current == ThemeMode.dark,
                        onTap: () => state.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'System',
                        previewDark: false,
                        isSplit: true,
                        selected: current == ThemeMode.system,
                        onTap: () => state.setThemeMode(ThemeMode.system),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                              'Preview',
                              style: SastaText.display(context, size: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Soft pastel cards and price gradients adapt cleanly in both light and dark modes.',
                              style: SastaText.muted(context, size: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const SastaMascot(
                        size: 64,
                        color: SastaColors.gold,
                        expression: MascotExpression.joy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SastaPrimaryButton(
                  label: 'Save appearance',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSastaToast(context, 'Appearance saved');
                  },
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      state.setThemeMode(ThemeMode.light);
                      showSastaToast(context, 'Reset to Light theme');
                    },
                    child: Text(
                      'Reset to default',
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

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.label,
    required this.previewDark,
    required this.isSplit,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool previewDark;
  final bool isSplit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.sasta;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: SastaMotion.fast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? palette.ink : palette.divider,
              width: selected ? 3 : 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 82,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: isSplit
                      ? Row(
                          children: [
                            Expanded(child: _MiniPhonePreview(dark: false)),
                            Expanded(child: _MiniPhonePreview(dark: true)),
                          ],
                        )
                      : _MiniPhonePreview(dark: previewDark),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: palette.ink,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: SastaText.body(
                      context,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPhonePreview extends StatelessWidget {
  const _MiniPhonePreview({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? SastaColors.darkScreen : Colors.white;
    final card = dark ? SastaColors.darkField : SastaColors.lavender;
    final line = dark ? SastaColors.darkInk : SastaColors.ink;
    return Container(
      color: bg,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            width: 34,
            decoration: BoxDecoration(
              color: line.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: SastaColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
