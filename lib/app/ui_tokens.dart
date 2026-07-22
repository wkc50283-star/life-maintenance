import 'package:flutter/material.dart';

abstract final class UiColors {
  static const seed = Color(0xFF6F8FAF);
  static const canvas = Color(0xFFF7F3EA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFCF6);
  static const primary = Color(0xFF5D7893);
  static const secondary = Color(0xFF8FA4B8);
  static const textPrimary = Color(0xFF263746);
  static const textSecondary = Color(0xFF687887);
  static const textSupporting = Color(0xFF526575);
  static const border = Color(0xFFE4E0D8);
  static const iconSurface = Color(0xFFE8F0F6);
  static const iconMuted = Color(0xFF7C8995);
  static const selectedSurface = Color(0xFFDCE8F2);
}

abstract final class UiType {
  static const pageTitle = TextStyle(
    color: UiColors.textPrimary,
    fontSize: 26,
    height: 1.18,
    fontWeight: FontWeight.w800,
  );
  static const pageIntro = TextStyle(
    color: UiColors.textSecondary,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const cardTitle = TextStyle(
    color: UiColors.textPrimary,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w800,
  );
  static const body = TextStyle(
    color: UiColors.textSecondary,
    fontSize: 14,
    height: 1.5,
  );
  static const button = TextStyle(fontWeight: FontWeight.w700);
}

abstract final class UiSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class UiRadius {
  static const control = 14.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const pill = 999.0;
}

abstract final class UiShadow {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x12263746), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

abstract final class UiMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const emphasized = Duration(milliseconds: 280);
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
