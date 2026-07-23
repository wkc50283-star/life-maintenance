import 'package:flutter/material.dart';

abstract final class UiColors {
  static const seed = Color(0xFF2F80ED);
  static const canvas = Color(0xFFFAF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF6F3EE);
  static const surfaceBlue = Color(0xFFF3F7FC);
  static const primary = Color(0xFF173B63);
  static const accent = Color(0xFF2F80ED);
  static const secondary = accent;
  static const textPrimary = Color(0xFF18324B);
  static const textSecondary = Color(0xFF52677B);
  static const textSupporting = Color(0xFF66788A);
  static const border = Color(0xFFE1E7ED);
  static const borderStrong = Color(0xFFCDD7E1);
  static const iconSurface = Color(0xFFEAF2FC);
  static const iconMuted = Color(0xFF708397);
  static const divider = Color(0xFFEDF1F5);
  static const selectedSurface = Color(0xFFE5F0FF);
  static const success = Color(0xFF2F7D62);
  static const successSurface = Color(0xFFE7F4EE);
  static const warning = Color(0xFF9A681A);
  static const warningSurface = Color(0xFFFFF2D9);
  static const danger = Color(0xFFB84A4A);
  static const dangerSurface = Color(0xFFFBE8E8);
  static const info = accent;
  static const infoSurface = selectedSurface;
}

abstract final class UiType {
  static const caption = TextStyle(
    color: UiColors.textSupporting,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    color: UiColors.textSecondary,
    fontSize: 13,
    height: 1.42,
  );
  static const button = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );
  static const pageIntro = TextStyle(
    color: UiColors.textSecondary,
    fontSize: 13,
    height: 1.42,
    fontWeight: FontWeight.w500,
  );
  static const cardTitle = TextStyle(
    color: UiColors.textPrimary,
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const sectionTitle = TextStyle(
    color: UiColors.textPrimary,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );
  static const pageTitle = TextStyle(
    color: UiColors.textPrimary,
    fontSize: 20,
    height: 1.25,
    fontWeight: FontWeight.w800,
  );
}

abstract final class UiSpace {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  // Compatibility aliases keep existing page layouts source-compatible while
  // the UI v3 scale is adopted page by page. New UI v3 work must use xs–xl.
  static const xxs = 4.0;
  static const xxl = xl;
}

abstract final class UiRadius {
  static const control = 12.0;
  static const card = 16.0;
  static const hero = 16.0;
  static const pill = 16.0;
}

abstract final class UiInsets {
  static const page = EdgeInsets.fromLTRB(
    UiSpace.md,
    UiSpace.sm,
    UiSpace.md,
    UiSpace.xl,
  );
  static const pageCompact = EdgeInsets.fromLTRB(
    UiSpace.md,
    UiSpace.xs,
    UiSpace.md,
    UiSpace.lg,
  );
  static const card = EdgeInsets.all(UiSpace.md);
}

abstract final class UiShadow {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A173B63), blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const navigation = <BoxShadow>[
    BoxShadow(color: Color(0x0A173B63), blurRadius: 14, offset: Offset(0, -4)),
  ];
}

abstract final class UiMotion {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const emphasized = Duration(milliseconds: 260);
  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeInOutCubic;

  static Duration durationOf(
    BuildContext context, [
    Duration preferred = standard,
  ]) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : preferred;
  }
}
