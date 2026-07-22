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
        secondary: UiColors.secondary,
      ),
      scaffoldBackgroundColor: UiColors.canvas,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: UiColors.canvas,
        foregroundColor: UiColors.textPrimary,
        titleTextStyle: TextStyle(
          color: UiColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: UiColors.surfaceWarm,
        indicatorColor: UiColors.selectedSurface,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? UiColors.textPrimary
                : UiColors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? UiColors.primary
                : UiColors.iconMuted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: UiColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiRadius.control),
          ),
          textStyle: UiType.button,
        ),
      ),
    );
  }
}
