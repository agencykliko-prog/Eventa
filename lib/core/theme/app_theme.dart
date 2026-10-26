import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'eventa_colors.dart';

/// Courbes et durées partagées (ease-out franc, jamais ease-in).
abstract final class Motion {
  static const easeOut = Cubic(0.23, 1, 0.32, 1);
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const drawer = Cubic(0.32, 0.72, 0, 1);
  static const press = Duration(milliseconds: 140);
  static const fast = Duration(milliseconds: 200);
  static const base = Duration(milliseconds: 280);
}

abstract final class AppTheme {
  static const font = 'Inter';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Confetti.coral,
      onPrimary: Colors.white,
      primaryContainer: Confetti.coralTint,
      onPrimaryContainer: Confetti.coralDeep,
      secondary: Confetti.violet,
      onSecondary: Colors.white,
      secondaryContainer: Confetti.violetTint,
      onSecondaryContainer: Confetti.violetDeep,
      tertiary: Confetti.lagoon,
      onTertiary: Colors.white,
      error: Confetti.danger,
      onError: Colors.white,
      surface: Confetti.cream,
      onSurface: Confetti.ink,
      onSurfaceVariant: Confetti.inkMuted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFBFAF8),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: Confetti.lavender,
      outline: Color(0xFFD3CEDF),
      outlineVariant: Confetti.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: font,
      scaffoldBackgroundColor: Confetti.cream,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    final t = base.textTheme.apply(
      fontFamily: font,
      bodyColor: Confetti.ink,
      displayColor: Confetti.ink,
    );

    // Inter : graisses franches, approche resserrée sur les grands corps.
    return base.copyWith(
      extensions: const [EventaColors.light],
      textTheme: t.copyWith(
        displaySmall: t.displaySmall?.copyWith(
          fontSize: 36,
          height: 1.06,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.3,
        ),
        headlineMedium: t.headlineMedium?.copyWith(
          fontSize: 27,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.9,
        ),
        headlineSmall: t.headlineSmall?.copyWith(
          fontSize: 21,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.55,
        ),
        titleLarge: t.titleLarge?.copyWith(
          fontSize: 17.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
        ),
        titleMedium: t.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: t.titleSmall?.copyWith(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        bodyLarge: t.bodyLarge?.copyWith(
          fontSize: 15.5,
          height: 1.5,
          letterSpacing: -0.15,
        ),
        bodyMedium: t.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
          letterSpacing: -0.1,
        ),
        bodySmall: t.bodySmall?.copyWith(
          fontSize: 12.5,
          height: 1.4,
          color: Confetti.inkMuted,
        ),
        labelLarge: t.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
        labelMedium: t.labelMedium?.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: t.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Confetti.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 16.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: Confetti.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Confetti.inkFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Confetti.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Confetti.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Confetti.ink, width: 1.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Confetti.coral,
        selectionColor: Confetti.coral.withValues(alpha: 0.22),
        selectionHandleColor: Confetti.coral,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Confetti.night,
        elevation: 0,
        contentTextStyle: const TextStyle(
          fontFamily: font,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Confetti.lagoon
              : const Color(0xFFD3CEDF),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(color: Confetti.line, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
