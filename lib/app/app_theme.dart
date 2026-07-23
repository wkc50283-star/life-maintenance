import 'package:flutter/material.dart';

import 'ui_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: UiColors.seed,
        brightness: Brightness.light,
        surface: UiColors.canvas,
        primary: UiColors.primary,
        secondary: UiColors.accent,
      ),
      scaffoldBackgroundColor: UiColors.canvas,
      fontFamily: 'Roboto',
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UiColors.canvas,
        foregroundColor: UiColors.textPrimary,
        toolbarHeight: 52,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: UiColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: UiColors.primary, size: 22),
        actionsIconTheme: IconThemeData(color: UiColors.primary, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: UiColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.card),
          side: const BorderSide(color: UiColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: UiColors.divider,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: UiColors.surface,
        indicatorColor: UiColors.selectedSurface,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? UiColors.primary
                : UiColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? UiColors.accent
                : UiColors.iconMuted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UiColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.control),
          ),
          textStyle: UiType.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UiColors.primary,
          minimumSize: const Size(48, 46),
          side: const BorderSide(color: UiColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.control),
          ),
          textStyle: UiType.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UiColors.primary,
          minimumSize: const Size(48, 48),
          textStyle: UiType.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UiColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: UiSpace.md,
          vertical: 12,
        ),
        labelStyle: UiType.body,
        hintStyle: UiType.body.copyWith(color: UiColors.iconMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.control),
          borderSide: const BorderSide(color: UiColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.control),
          borderSide: const BorderSide(color: UiColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiRadius.control),
          borderSide: const BorderSide(color: UiColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
