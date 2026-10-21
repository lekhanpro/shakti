import 'package:flutter/material.dart';

/// Design tokens. Features must use these, never raw hex values.
///
/// Palette intent:
///  * [sos] (rose) is reserved for emergency affordances only.
///  * [action] (indigo) for primary non-emergency actions.
///  * [safe] (emerald) for protected / resolved states.
///  * [warn] (amber) for the countdown and caution.
abstract final class ShaktiColors {
  // Brand + semantic
  static const sos = Color(0xFFE11D48);
  static const sosDeep = Color(0xFFBE123C);
  static const sosGlow = Color(0xFFFB7185);
  static const action = Color(0xFF6366F1);
  static const actionDeep = Color(0xFF4F46E5);

  // Brand kit (brand/tokens.json): indigo identity, lilac for quiet structure.
  static const brand = Color(0xFF4F46E5);
  static const lilac = Color(0xFFA5B4FC);
  static const safe = Color(0xFF10B981);
  static const safeDeep = Color(0xFF059669);
  static const warn = Color(0xFFF59E0B);
  static const info = Color(0xFF38BDF8);

  // Dark surfaces (default theme; used at night and under stress)
  static const bg = Color(0xFF070B14);
  static const surface = Color(0xFF0F172A);
  static const surfaceHigh = Color(0xFF1E293B);
  static const outline = Color(0xFF334155);
  static const textHi = Color(0xFFF8FAFC);
  static const textMid = Color(0xFFCBD5E1);
  static const textLo = Color(0xFF94A3B8);

  // Light surfaces
  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFF1F5F9);
  static const lightOutline = Color(0xFFE2E8F0);
  static const lightTextHi = Color(0xFF0F172A);
  static const lightTextMid = Color(0xFF334155);
  static const lightTextLo = Color(0xFF64748B);

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
  static const screen = EdgeInsets.symmetric(horizontal: 20);
}

abstract final class ShaktiRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const card = 20.0;
  static const lg = 28.0;
  static const pill = 999.0;
}

abstract final class ShaktiMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const breathe = Duration(milliseconds: 1600);
  static const curve = Curves.easeOutCubic;

  /// True when the OS asks for reduced motion; animations must degrade to
  /// static states.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

abstract final class ShaktiSize {
  static const minTap = 48.0;
  static const sosButton = 220.0;
}

/// Font families bundled in `assets/fonts` (no runtime download).
abstract final class ShaktiFonts {
  static const heading = 'Poppins';
  static const body = 'Nunito';
}
