// Sasta design tokens + ThemeData (starting point, v1.0)
// Requires: google_fonts. Keep all colour/size values here, never inline in widgets.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SastaColors {
  static const ink = Color(0xFF151515);
  static const muted = Color(0xFF6A6578);
  static const surface = Color(0xFFFFFFFF);
  static const field = Color(0xFFF4F1FB);
  static const divider = Color(0xFFEFEBF7);
  static const link = Color(0xFFB4380A);
  static const accent = Color(0xFFFF7A1A); // decorative only, never text
  // Pastel surfaces
  static const lavender = Color(0xFFEFE9FF);
  static const peach = Color(0xFFFFEBDC);
  static const mint = Color(0xFFE3F6EC);
  static const butter = Color(0xFFFFF3C4);
  static const sky = Color(0xFFE4F1FF);
  static const pink = Color(0xFFFFE4EE);
  // Semantic
  static const successText = Color(0xFF14683F);
  static const warningText = Color(0xFF6B5200);
  static const dangerText = Color(0xFFC0262D);
  static const dangerBg = Color(0xFFFFE4E4);
  // Retailers (mascot colours until real logos are supplied)
  static const blinkit = Color(0xFFFFD21F);
  static const zepto = Color(0xFFA98BFF);
  static const instamart = Color(0xFFFF8A3D);
  static const flipkartMinutes = Color(0xFF4FB3FF);
  static const priceGradient = LinearGradient(colors: [Color(0xFFE5560A), Color(0xFFD6338A)]);
}

class SastaSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, page = 22.0, xl = 28.0, xxl = 40.0;
  static const pageTop = 54.0, navClearance = 96.0, bottomMargin = 30.0;
}

class SastaRadius {
  static const screen = 44.0, sheet = 36.0, card = 28.0, pill = 28.0, pillL = 29.0, tile = 22.0, chip = 22.0, nav = 33.0;
}

class SastaShadows {
  static const card = [BoxShadow(color: Color(0x1F783C0A), blurRadius: 22, offset: Offset(0, 8))];
  static const float = [BoxShadow(color: Color(0x333C2878), blurRadius: 36, offset: Offset(0, 16))];
  static const cta = [BoxShadow(color: Color(0x40151515), blurRadius: 26, offset: Offset(0, 14))];
}

class SastaMotion {
  static const fadeUp = Duration(milliseconds: 700);
  static const stagger = Duration(milliseconds: 80);
  static const curve = Cubic(0.2, 0.8, 0.2, 1);
  static const float = Duration(milliseconds: 3400);
}

TextStyle _display(double size, {double height = 1.05}) => GoogleFonts.bricolageGrotesque(
    fontSize: size, fontWeight: FontWeight.w800, height: height, letterSpacing: size * -0.03, color: SastaColors.ink);
TextStyle _body(double size, FontWeight w, {double height = 1.4, Color color = SastaColors.ink}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, height: height, color: color);

ThemeData sastaTheme() {
  final text = TextTheme(
    displayLarge: _display(72),
    displayMedium: _display(52),
    headlineLarge: _display(36),
    headlineMedium: _display(28),
    headlineSmall: _display(22),
    titleLarge: _display(24, height: 1.1),
    titleMedium: _body(16, FontWeight.w700),
    bodyLarge: _body(16, FontWeight.w500),
    bodyMedium: _body(15, FontWeight.w600),
    labelLarge: _body(14, FontWeight.w700, height: 1.25),
    bodySmall: _body(13, FontWeight.w500, color: SastaColors.muted),
    labelSmall: _body(12, FontWeight.w500, color: SastaColors.muted),
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: SastaColors.surface,
    colorScheme: const ColorScheme.light(
      primary: SastaColors.ink, onPrimary: Colors.white,
      secondary: SastaColors.blinkit, onSecondary: SastaColors.ink,
      surface: SastaColors.surface, onSurface: SastaColors.ink,
      error: SastaColors.dangerText, onError: Colors.white,
    ),
    textTheme: text,
    dividerColor: SastaColors.divider,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SastaColors.ink, foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SastaRadius.pillL)),
        textStyle: _body(16, FontWeight.w700), elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SastaColors.ink, minimumSize: const Size.fromHeight(58),
        side: const BorderSide(color: SastaColors.ink, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SastaRadius.pillL)),
        textStyle: _body(16, FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: SastaColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(SastaRadius.pill), borderSide: BorderSide.none),
      hintStyle: _body(16, FontWeight.w600, color: const Color(0xFF6F6A7C)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SastaColors.field, selectedColor: SastaColors.ink,
      labelStyle: _body(13, FontWeight.w700), secondaryLabelStyle: _body(13, FontWeight.w700, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SastaRadius.chip)),
      side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    cardTheme: CardThemeData(
      color: SastaColors.surface, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SastaRadius.card)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? SastaColors.ink : const Color(0xFFD9D3EA)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
