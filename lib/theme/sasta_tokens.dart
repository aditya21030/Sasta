import 'package:flutter/material.dart';

/// Core brand and semantic color constants for Sasta, derived from DESIGN.md & tokens.json.
abstract final class SastaColors {
  static const ink = Color(0xFF151515);
  static const muted = Color(0xFF6A6578);
  static const placeholder = Color(0xFF6F6A7C);
  static const surface = Color(0xFFFFFFFF);
  static const field = Color(0xFFF4F1FB);
  static const divider = Color(0xFFEFEBF7);
  static const link = Color(0xFFB4380A);
  static const accent = Color(0xFFFF7A1A);
  static const accentOrange = Color(0xFFFF6A00);
  static const sparkleOrange = Color(0xFFFF8A3D);
  static const heartPink = Color(0xFFFF4D6D);
  static const unreadCoral = Color(0xFFFF5A3D);
  static const mutedGrey = Color(0xFFC9C2DC);
  static const gold = Color(0xFFFFD21F);
  static const goldDeep = Color(0xFFFFB020);
  static const promoDarkStart = Color(0xFF34285E);
  static const promoDarkEnd = Color(0xFF151515);

  // Light pastel surfaces
  static const lavender = Color(0xFFEFE9FF);
  static const peach = Color(0xFFFFEBDC);
  static const mint = Color(0xFFE3F6EC);
  static const butter = Color(0xFFFFF3C4);
  static const sky = Color(0xFFE4F1FF);
  static const pink = Color(0xFFFFE4EE);

  // Radial backdrop glows
  static const auraLavender = Color(0xFFE9DFFF);
  static const auraPeach = Color(0xFFFFE5D1);
  static const splashCream = Color(0xFFFFF3C4);
  static const splashLavender = Color(0xFFEFE4FF);
  static const splashPeach = Color(0xFFFFE4D6);

  // Semantic accents (light)
  static const successText = Color(0xFF14683F);
  static const warningText = Color(0xFF6B5200);
  static const warningAccent = Color(0xFF8A6A00);
  static const dangerText = Color(0xFFC0262D);
  static const dangerBg = Color(0xFFFFE4E4);
  static const pinkText = Color(0xFFB0245C);
  static const skyText = Color(0xFF1F6FB5);
  static const lavenderText = Color(0xFF5B3FD0);

  // Retailer mascots
  static const blinkit = Color(0xFFFFD21F);
  static const zepto = Color(0xFFA98BFF);
  static const instamart = Color(0xFFFF8A3D);
  static const flipkartMinutes = Color(0xFF4FB3FF);

  // Gradients
  static const priceGradient = [Color(0xFFE5560A), Color(0xFFD6338A)];
  static const chartLinePurple = Color(0xFF7C5CFF);
  static const chartLineAmber = Color(0xFFFFB020);

  // Dark palette bases
  static const darkScreen = Color(0xFF121118);
  static const darkSurface = Color(0xFF1C1A24);
  static const darkField = Color(0xFF2A2735);
  static const darkDivider = Color(0xFF343043);
  static const darkInk = Color(0xFFF4F1FB);
  static const darkMuted = Color(0xFFA9A4BB);
}

enum SastaPastel { lavender, peach, mint, butter, sky, pink }

/// ThemeExtension holding adaptive Light & Dark tokens for Sasta components.
@immutable
class SastaPalette extends ThemeExtension<SastaPalette> {
  const SastaPalette({
    required this.isDark,
    required this.screen,
    required this.surface,
    required this.field,
    required this.divider,
    required this.ink,
    required this.muted,
    required this.primaryCtaBg,
    required this.primaryCtaFg,
    required this.navSurface,
    required this.iconButtonBg,
    required this.auraLeft,
    required this.auraRight,
    required this.lavender,
    required this.peach,
    required this.mint,
    required this.butter,
    required this.sky,
    required this.pink,
    required this.successText,
    required this.warningText,
    required this.warningAccent,
    required this.dangerText,
    required this.dangerBg,
    required this.linkText,
    required this.skyText,
    required this.lavenderText,
    required this.pinkText,
    required this.unavailableBg,
    required this.unavailableBorder,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  final bool isDark;
  final Color screen;
  final Color surface;
  final Color field;
  final Color divider;
  final Color ink;
  final Color muted;
  final Color primaryCtaBg;
  final Color primaryCtaFg;
  final Color navSurface;
  final Color iconButtonBg;
  final Color auraLeft;
  final Color auraRight;
  final Color lavender;
  final Color peach;
  final Color mint;
  final Color butter;
  final Color sky;
  final Color pink;
  final Color successText;
  final Color warningText;
  final Color warningAccent;
  final Color dangerText;
  final Color dangerBg;
  final Color linkText;
  final Color skyText;
  final Color lavenderText;
  final Color pinkText;
  final Color unavailableBg;
  final Color unavailableBorder;
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const light = SastaPalette(
    isDark: false,
    screen: Colors.white,
    surface: Colors.white,
    field: SastaColors.field,
    divider: SastaColors.divider,
    ink: SastaColors.ink,
    muted: SastaColors.muted,
    primaryCtaBg: SastaColors.ink,
    primaryCtaFg: Colors.white,
    navSurface: Colors.white,
    iconButtonBg: Colors.white,
    auraLeft: SastaColors.auraLavender,
    auraRight: SastaColors.auraPeach,
    lavender: SastaColors.lavender,
    peach: SastaColors.peach,
    mint: SastaColors.mint,
    butter: SastaColors.butter,
    sky: SastaColors.sky,
    pink: SastaColors.pink,
    successText: SastaColors.successText,
    warningText: SastaColors.warningText,
    warningAccent: SastaColors.warningAccent,
    dangerText: SastaColors.dangerText,
    dangerBg: SastaColors.dangerBg,
    linkText: SastaColors.link,
    skyText: SastaColors.skyText,
    lavenderText: SastaColors.lavenderText,
    pinkText: SastaColors.pinkText,
    unavailableBg: Color(0xFFFBF8F4),
    unavailableBorder: Color(0xFFE2D6C6),
    skeletonBase: Color(0xFFF1EEF8),
    skeletonHighlight: Color(0xFFFBF9FF),
  );

  static const dark = SastaPalette(
    isDark: true,
    screen: SastaColors.darkScreen,
    surface: SastaColors.darkSurface,
    field: SastaColors.darkField,
    divider: SastaColors.darkDivider,
    ink: SastaColors.darkInk,
    muted: SastaColors.darkMuted,
    primaryCtaBg: SastaColors.darkInk,
    primaryCtaFg: SastaColors.ink,
    navSurface: Color(0xFF221F2C),
    iconButtonBg: Color(0xFF262332),
    auraLeft: Color(0xFF2E224A),
    auraRight: Color(0xFF3A241A),
    lavender: Color(0xFF2B2442),
    peach: Color(0xFF38271F),
    mint: Color(0xFF1A3529),
    butter: Color(0xFF38301B),
    sky: Color(0xFF1C2E3F),
    pink: Color(0xFF38202D),
    successText: Color(0xFF6CE0A2),
    warningText: Color(0xFFFFDC73),
    warningAccent: Color(0xFFFFCA4D),
    dangerText: Color(0xFFFF8285),
    dangerBg: Color(0xFF3E1F24),
    linkText: Color(0xFFFF9666),
    skyText: Color(0xFF7AC2FF),
    lavenderText: Color(0xFFBFAFFF),
    pinkText: Color(0xFFFF88B5),
    unavailableBg: Color(0xFF24201E),
    unavailableBorder: Color(0xFF4F4336),
    skeletonBase: Color(0xFF262332),
    skeletonHighlight: Color(0xFF343043),
  );

  Color pastel(SastaPastel kind) {
    return switch (kind) {
      SastaPastel.lavender => lavender,
      SastaPastel.peach => peach,
      SastaPastel.mint => mint,
      SastaPastel.butter => butter,
      SastaPastel.sky => sky,
      SastaPastel.pink => pink,
    };
  }

  Color pastelAccent(SastaPastel kind) {
    return switch (kind) {
      SastaPastel.lavender => lavenderText,
      SastaPastel.peach => linkText,
      SastaPastel.mint => successText,
      SastaPastel.butter => warningAccent,
      SastaPastel.sky => skyText,
      SastaPastel.pink => pinkText,
    };
  }

  @override
  SastaPalette copyWith({bool? isDark}) => this;

  @override
  SastaPalette lerp(covariant ThemeExtension<SastaPalette>? other, double t) {
    if (other is! SastaPalette) return this;
    return SastaPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      screen: Color.lerp(screen, other.screen, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      field: Color.lerp(field, other.field, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      primaryCtaBg: Color.lerp(primaryCtaBg, other.primaryCtaBg, t)!,
      primaryCtaFg: Color.lerp(primaryCtaFg, other.primaryCtaFg, t)!,
      navSurface: Color.lerp(navSurface, other.navSurface, t)!,
      iconButtonBg: Color.lerp(iconButtonBg, other.iconButtonBg, t)!,
      auraLeft: Color.lerp(auraLeft, other.auraLeft, t)!,
      auraRight: Color.lerp(auraRight, other.auraRight, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      butter: Color.lerp(butter, other.butter, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningAccent: Color.lerp(warningAccent, other.warningAccent, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      linkText: Color.lerp(linkText, other.linkText, t)!,
      skyText: Color.lerp(skyText, other.skyText, t)!,
      lavenderText: Color.lerp(lavenderText, other.lavenderText, t)!,
      pinkText: Color.lerp(pinkText, other.pinkText, t)!,
      unavailableBg: Color.lerp(unavailableBg, other.unavailableBg, t)!,
      unavailableBorder: Color.lerp(unavailableBorder, other.unavailableBorder, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

extension SastaContextTheme on BuildContext {
  SastaPalette get sasta =>
      Theme.of(this).extension<SastaPalette>() ?? SastaPalette.light;
}

abstract final class SastaSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double page = 22;
  static const double xl = 28;
  static const double xxl = 40;
  static const double pageTop = 54;
  static const double navClearance = 104;
  static const double basketBarClearance = 180;
  static const double bottomMargin = 30;
}

abstract final class SastaRadius {
  static const double screen = 44;
  static const double sheet = 36;
  static const double card = 28;
  static const double pill = 28;
  static const double pillL = 29;
  static const double tile = 22;
  static const double chip = 22;
  static const double nav = 33;
  static const double iconBadge = 16;
  static const double tag = 999;
}

abstract final class SastaSizes {
  static const double button = 58;
  static const double iconButton = 48;
  static const double input = 56;
  static const double chipMin = 44;
  static const double toggleW = 50;
  static const double toggleH = 30;
  static const double stepper = 36;
  static const double navHeight = 66;
  static const double navItem = 50;
  static const double listRowMin = 60;
  static const double touchMin = 44;
}

abstract final class SastaMotion {
  static const Duration fadeUp = Duration(milliseconds: 520);
  static const Duration stagger = Duration(milliseconds: 65);
  static const Curve curve = Cubic(0.2, 0.8, 0.2, 1);
  static const Duration float = Duration(milliseconds: 3400);
  static const Duration fast = Duration(milliseconds: 200);
}

abstract final class SastaShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = context.sasta.isDark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x40000000) : const Color(0x143C2878),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> float(BuildContext context) {
    final isDark = context.sasta.isDark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x55000000) : const Color(0x1A3C2878),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static List<BoxShadow> nav(BuildContext context) {
    final isDark = context.sasta.isDark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x66000000) : const Color(0x333C2878),
        blurRadius: 36,
        offset: const Offset(0, 16),
      ),
    ];
  }

  static List<BoxShadow> cta(BuildContext context) {
    final isDark = context.sasta.isDark;
    return [
      BoxShadow(
        color: isDark ? const Color(0x4D000000) : const Color(0x40151515),
        blurRadius: 26,
        offset: const Offset(0, 14),
      ),
    ];
  }
}
