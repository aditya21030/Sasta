import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sasta_tokens.dart';

/// Typography helpers pairing Bricolage Grotesque display headings with DM Sans body text.
abstract final class SastaText {
  static TextStyle display(
    BuildContext context, {
    double size = 30,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double height = 1.05,
    double letterSpacingFactor = -0.03,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: size * letterSpacingFactor,
      color: color ?? context.sasta.ink,
    );
    return GoogleFonts.bricolageGrotesque(textStyle: base);
  }

  static TextStyle body(
    BuildContext context, {
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double height = 1.4,
    TextDecoration? decoration,
    bool tabular = false,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? context.sasta.ink,
      decoration: decoration,
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
    return GoogleFonts.dmSans(textStyle: base);
  }

  static TextStyle muted(
    BuildContext context, {
    double size = 13,
    FontWeight weight = FontWeight.w500,
    double height = 1.4,
  }) =>
      body(
        context,
        size: size,
        weight: weight,
        color: context.sasta.muted,
        height: height,
      );

  static TextStyle eyebrow(BuildContext context, {Color? color}) => body(
        context,
        size: 11,
        weight: FontWeight.w700,
        color: color ?? context.sasta.muted,
        height: 1.2,
      ).copyWith(letterSpacing: 0.7);
}

ThemeData buildSastaTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? SastaPalette.dark : SastaPalette.light;
  final baseTextTheme = GoogleFonts.dmSansTextTheme(
    isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.screen,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: palette.primaryCtaBg,
      onPrimary: palette.primaryCtaFg,
      secondary: SastaColors.accent,
      onSecondary: Colors.white,
      error: palette.dangerText,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.ink,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: palette.ink,
      displayColor: palette.ink,
    ),
    dividerColor: palette.divider,
    splashColor: Colors.transparent,
    highlightColor: palette.field.withValues(alpha: 0.5),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}
