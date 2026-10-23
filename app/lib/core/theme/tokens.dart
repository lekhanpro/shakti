import 'package:flutter/material.dart';

/// Design tokens. Features must use these, never raw hex values.
///
/// Palette intent:
///  * [sos] (rose) is reserved for emergency affordances only.
///  * [action] (plum) for primary non-emergency actions.
///  * [safe] (emerald) for protected / resolved states.
///  * [warn] (amber) for the countdown and caution.
abstract final class ShaktiColors {
  // Brand + semantic
  static const sos = Color(0xFFE11D48);
  static const sosDeep = Color(0xFFBE123C);
  static const sosGlow = Color(0xFFFB7185);
  static const action = Color(0xFF7F4A70);
  static const actionDeep = Color(0xFF6C3B5D);

  // Owner-selected warm ivory/plum scheme; legacy names remain source-compatible.
  static const brand = Color(0xFF6C3B5D);
  static const lilac = Color(0xFFD8B9D0);
  static const safe = Color(0xFF10B981);
  static const safeDeep = Color(0xFF059669);
  static const warn = Color(0xFFF59E0B);
  static const info = Color(0xFF38BDF8);

  // Optional dark surfaces for night use; the default appearance is light.
  static const bg = Color(0xFF17131C);
  static const ambient = Color(0xFF211A26);
  static const surface = Color(0xFF231E29);
  static const surfaceHigh = Color(0xFF302837);
  static const outline = Color(0xFF514451);
  static const glassEdge = Color(0xFF514451);
  static const textHi = Color(0xFFF8F2F5);
  static const textMid = Color(0xFFD4C7D1);
  static const textLo = Color(0xFFBDAEBA);

  // Light surfaces
  static const lightBg = Color(0xFFF8F5EF);
  static const lightSurface = Color(0xFFFFFDFA);
  static const lightSurfaceHigh = Color(0xFFF0EAE4);
  static const lightOutline = Color(0xFFE1D7D4);
  static const lightTextHi = Color(0xFF29232A);
  static const lightTextMid = Color(0xFF615760);
  static const lightTextLo = Color(0xFF756A73);

  static const lightStrongOutline = Color(0xFF94818C);
  static const lightAccentContainer = Color(0xFFEFE1E8);
  static const darkAccentContainer = Color(0xFF473244);
  static const lightSafe = Color(0xFF176A4E);
  static const darkSafe = Color(0xFF8ED0B3);
  static const lightSafeContainer = Color(0xFFE4EFE6);
  static const darkSafeContainer = Color(0xFF223D32);
  static const lightWarn = Color(0xFF855900);
  static const darkWarn = Color(0xFFE6B963);
  static const lightWarningContainer = Color(0xFFF7EDCE);
  static const darkWarningContainer = Color(0xFF44371F);
  static const lightInfo = Color(0xFF286683);
  static const darkInfo = Color(0xFF89C6DB);

  // Stealth / decoy "Notes" look
  static const stealthBg = Color(0xFFF5F5F4);
  static const stealthInk = Color(0xFF292524);

  // Map haven categories (always paired with an icon, never colour alone)
  static const police = Color(0xFF60A5FA);
  static const hospital = Color(0xFFF87171);
  static const pharmacy = Color(0xFF34D399);
  static const shelter = Color(0xFFC084FC);
}

abstract final class ShaktiSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const screen = EdgeInsets.symmetric(horizontal: 24);
  static const dockClearance = 128.0;
}

abstract final class ShaktiRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const card = 20.0;
  static const lg = 28.0;
  static const pill = 999.0;
}

abstract final class ShaktiMotion {
  static const press = Duration(milliseconds: 140);
  static const navigation = Duration(milliseconds: 240);
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const breathe = Duration(milliseconds: 1600);
  static const curve = Curves.easeOutCubic;

  /// True when the OS asks for reduced motion; animations must degrade to
  /// static states.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

abstract final class ShaktiSize {
  static const minTap = 48.0;
  static const sosButton = 220.0;
}

/// Font families bundled in `assets/fonts` (no runtime download).
abstract final class ShaktiFonts {
  static const heading = 'Manrope';
  static const body = 'Inter';
}

/// Semantic colors follow the interpolated Material scheme in either appearance.
class ShaktiPalette {
  ShaktiPalette._(this._scheme);
  final ColorScheme _scheme;
  bool get isDark => _scheme.brightness == Brightness.dark;
  Color get bg => _scheme.surfaceContainerLowest;
  Color get ambient => bg;
  Color get surface => _scheme.surface;
  Color get surfaceHigh => _scheme.surfaceContainerHigh;
  Color get outline => _scheme.outlineVariant;
  Color get glassEdge => _scheme.outlineVariant;
  Color get textHi => _scheme.onSurface;
  Color get textMid => _scheme.onSurfaceVariant;
  Color get textLo => _scheme.onSurfaceVariant;
  Color get accent => _scheme.primary;
  Color get lilac => accent;
  Color get brand => accent;
  Color get action => accent;
  Color get actionDeep => accent;
  Color get onAccent => _scheme.onPrimary;
  Color get accentContainer => _scheme.primaryContainer;
  Color get safe => _scheme.secondary;
  Color get safeDeep => ShaktiColors.lightSafe;
  Color get safeContainer => _scheme.secondaryContainer;
  Color get warn => _scheme.tertiary;
  Color get warningContainer => _scheme.tertiaryContainer;
  Color get info => isDark ? ShaktiColors.darkInfo : ShaktiColors.lightInfo;
  Color get sos => ShaktiColors.sos;
  Color get sosDeep => ShaktiColors.sosDeep;
  Color get sosGlow => isDark ? ShaktiColors.sosGlow : ShaktiColors.sosDeep;
  Color get police => isDark ? ShaktiColors.police : ShaktiColors.lightInfo;
  Color get hospital => sosGlow;
  Color get pharmacy => safe;
  Color get shelter => accent;
}

extension ShaktiThemeContext on BuildContext {
  ShaktiPalette get shakti => ShaktiPalette._(Theme.of(this).colorScheme);
}
