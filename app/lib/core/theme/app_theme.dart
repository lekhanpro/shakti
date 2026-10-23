import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    bg: ShaktiColors.bg,
    surface: ShaktiColors.surface,
    surfaceHigh: ShaktiColors.surfaceHigh,
    outline: ShaktiColors.outline,
    hi: ShaktiColors.textHi,
    mid: ShaktiColors.textMid,
    lo: ShaktiColors.textLo,
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    bg: ShaktiColors.lightBg,
    surface: ShaktiColors.lightSurface,
    surfaceHigh: ShaktiColors.lightSurfaceHigh,
    outline: ShaktiColors.lightOutline,
    hi: ShaktiColors.lightTextHi,
    mid: ShaktiColors.lightTextMid,
    lo: ShaktiColors.lightTextLo,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceHigh,
    required Color outline,
    required Color hi,
    required Color mid,
    required Color lo,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: brightness == Brightness.dark
          ? ShaktiColors.lilac
          : ShaktiColors.actionDeep,
      onPrimary: brightness == Brightness.dark ? ShaktiColors.bg : Colors.white,
      primaryContainer: dark
          ? ShaktiColors.darkAccentContainer
          : ShaktiColors.lightAccentContainer,
      onPrimaryContainer: hi,
      secondary: dark ? ShaktiColors.darkSafe : ShaktiColors.lightSafe,
      secondaryContainer: dark
          ? ShaktiColors.darkSafeContainer
          : ShaktiColors.lightSafeContainer,
      onSecondaryContainer: dark
          ? ShaktiColors.darkSafe
          : ShaktiColors.lightSafe,
      onSecondary: dark ? ShaktiColors.bg : Colors.white,
      tertiary: dark ? ShaktiColors.darkWarn : ShaktiColors.lightWarn,
      tertiaryContainer: dark
          ? ShaktiColors.darkWarningContainer
          : ShaktiColors.lightWarningContainer,
      onTertiaryContainer: dark
          ? ShaktiColors.darkWarn
          : ShaktiColors.lightWarn,
      onTertiary: dark ? ShaktiColors.bg : Colors.white,
      error: ShaktiColors.sos,
      onError: Colors.white,
      errorContainer: ShaktiColors.sos.withValues(alpha: 0.16),
      onErrorContainer: hi,
      surface: surface,
      onSurface: hi,
      onSurfaceVariant: mid,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHigh,
      outline: dark ? ShaktiColors.textLo : ShaktiColors.lightStrongOutline,
      outlineVariant: outline,
    );

    TextStyle h(
      double size,
      FontWeight w, {
      double height = 1.18,
      double ls = -0.4,
    }) => TextStyle(
      fontFamily: ShaktiFonts.heading,
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: ls,
      color: hi,
    );
    TextStyle b(
      double size,
      FontWeight w, {
      Color? color,
      double height = 1.5,
    }) => TextStyle(
      fontFamily: ShaktiFonts.body,
      fontSize: size,
      fontWeight: w,
      height: height,
      color: color ?? mid,
    );

    final text = TextTheme(
      displayLarge: h(48, FontWeight.w700, height: 1.05, ls: -1),
      displayMedium: h(36, FontWeight.w700, height: 1.1, ls: -0.8),
      displaySmall: h(30, FontWeight.w700, ls: -0.5),
      headlineLarge: h(26, FontWeight.w700),
      headlineMedium: h(23, FontWeight.w600),
      headlineSmall: h(20, FontWeight.w600),
      titleLarge: h(18, FontWeight.w600, ls: 0),
      titleMedium: b(16, FontWeight.w700, color: hi),
      titleSmall: b(14, FontWeight.w700, color: hi),
      bodyLarge: b(16, FontWeight.w400, color: hi),
      bodyMedium: b(14, FontWeight.w400),
      bodySmall: b(12, FontWeight.w400, color: lo),
      labelLarge: b(15, FontWeight.w700, color: hi, height: 1.2),
      labelMedium: b(13, FontWeight.w600, color: mid, height: 1.2),
      labelSmall: b(11, FontWeight.w700, color: lo, height: 1.2),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ShaktiRadius.md),
    );
    const minSize = Size(ShaktiSize.minTap, ShaktiSize.minTap);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: ShaktiFonts.body,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        foregroundColor: hi,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.card),
          side: BorderSide(color: outline.withValues(alpha: 0.7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(ShaktiSize.minTap, 56),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: shape,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(ShaktiSize.minTap, 56),
          shape: shape,
          side: BorderSide(
            color: brightness == Brightness.dark
                ? ShaktiColors.glassEdge
                : outline,
          ),
          foregroundColor: hi,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          textStyle: text.labelLarge,
          shape: shape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh.withValues(
          alpha: brightness == Brightness.dark ? 0.7 : 1,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ShaktiSpace.md,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
          borderSide: const BorderSide(color: ShaktiColors.sos),
        ),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium?.copyWith(color: lo),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? hi : lo,
            letterSpacing: 0.2,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? hi : lo,
            size: 24,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : lo,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? scheme.primary : surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: ShaktiSpace.sm,
        iconColor: mid,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        side: BorderSide(color: outline),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: scheme.onPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: ShaktiSpace.sm,
          vertical: ShaktiSpace.xs,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: text.bodyMedium?.copyWith(color: hi),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ShaktiRadius.lg),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShaktiRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
