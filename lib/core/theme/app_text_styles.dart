import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles matching the Tara Travel brand identity.
/// Playfair Display — a serif display font mapped for headings/titles (font-heading style token).
/// DM Sans — the main font, used everywhere for body text and UI elements.
/// Georgia — serif fallback for prominent brand display and greeting names.
class AppTextStyles {
  AppTextStyles._();

  // ── Brand Font Family Constants ──────────────────────────────
  static const String fontHeading = 'Playfair Display';
  static const String fontBody = 'DM Sans';
  static const String fontSerifFallback = 'Georgia';

  // ── Headlines (Playfair Display Bold with Georgia Fallback) ──
  static const List<String> serifFallbacks = ['Georgia', 'serif'];

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineWhite = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
  );

  // ── Tagline (Playfair Display Italic with Georgia Fallback) ───
  static const TextStyle tagline = TextStyle(
    fontFamily: fontHeading,
    fontFamilyFallback: serifFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.darkAccent,
    letterSpacing: 2,
  );

  // ── Section Label ────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontBody,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.warmMuted,
    letterSpacing: 1.5,
  );

  // ── Body (DM Sans) ──────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.7,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Caption ──────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  // ── Button ───────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ── Badge / Chip ─────────────────────────────────────────────
  static const TextStyle badge = TextStyle(
    fontFamily: fontBody,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ── Nav Label ────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontBody,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  // ── Numbers / Numeric Stats (Strictly DM Sans) ──────────────
  static const TextStyle statNumberLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle statNumberMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle statNumberSmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
}
