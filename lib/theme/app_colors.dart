import 'package:flutter/material.dart';

/// Design tokens yang match dengan web SuppleWise (Tailwind config).
/// Diambil dari: resources/views/layouts/head.blade.php
class AppColors {
  AppColors._();

  // ─── Primary ──────────────────────────────────────────────────────────────
  static const primary              = Color(0xFF004F35);
  static const onPrimary            = Color(0xFFFFFFFF);
  static const primaryContainer     = Color(0xFF006948);
  static const onPrimaryContainer   = Color(0xFF91E5BC);
  static const primaryFixed         = Color(0xFF9FF4CA);
  static const primaryFixedDim      = Color(0xFF83D7AE);

  // ─── Secondary ────────────────────────────────────────────────────────────
  static const secondary            = Color(0xFF545F73);
  static const onSecondary          = Color(0xFFFFFFFF);
  static const secondaryContainer   = Color(0xFFD5E0F8);
  static const onSecondaryContainer = Color(0xFF586377);
  static const secondaryFixedDim    = Color(0xFFBCC7DE);

  // ─── Tertiary ─────────────────────────────────────────────────────────────
  static const tertiary             = Color(0xFF00418F);
  static const onTertiary           = Color(0xFFFFFFFF);
  static const tertiaryContainer    = Color(0xFF0057BC);
  static const onTertiaryContainer  = Color(0xFFC2D3FF);
  static const tertiaryFixed        = Color(0xFFD8E2FF);
  static const tertiaryFixedDim     = Color(0xFFADC6FF);

  // ─── Error ────────────────────────────────────────────────────────────────
  static const error                = Color(0xFFBA1A1A);
  static const onError              = Color(0xFFFFFFFF);
  static const errorContainer       = Color(0xFFFFDAD6);
  static const onErrorContainer     = Color(0xFF93000A);

  // ─── Surface ──────────────────────────────────────────────────────────────
  static const surface                  = Color(0xFFF8F9FF);
  static const surfaceBright            = Color(0xFFF8F9FF);
  static const onSurface                = Color(0xFF0B1C30);
  static const onSurfaceVariant         = Color(0xFF3F4943);
  static const surfaceContainerLowest   = Color(0xFFFFFFFF);
  static const surfaceContainerLow      = Color(0xFFEFF4FF);
  static const surfaceContainer         = Color(0xFFE5EEFF);
  static const surfaceContainerHigh     = Color(0xFFDCE9FF);
  static const surfaceContainerHighest  = Color(0xFFD3E4FE);

  // ─── Outline ──────────────────────────────────────────────────────────────
  static const outline               = Color(0xFF6F7A72);
  static const outlineVariant        = Color(0xFFBEC9C1);

  // ─── Status / Extra ───────────────────────────────────────────────────────
  static const success   = Color(0xFF2E7D32);
  static const warning   = Color(0xFFED6C02);
}
