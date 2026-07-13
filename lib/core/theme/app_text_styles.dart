import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles matching the Tara Travel brand identity.
/// Playfair Display → Headlines & taglines
/// DM Sans → UI labels, body copy, buttons
class AppTextStyles {
  AppTextStyles._();

  // ── Headlines (Playfair Display Bold) ────────────────────────
  static const TextStyle headline1 = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle headlineWhite = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
  );

  // ── Tagline (Playfair Display Italic) ────────────────────────
  static const TextStyle tagline = TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.darkAccent,
    letterSpacing: 2,
  );

  // ── Section Label ────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.warmMuted,
    letterSpacing: 1.5,
  );

  // ── Body (DM Sans) ──────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.7,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Caption ──────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  // ── Button ───────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ── Badge / Chip ─────────────────────────────────────────────
  static const TextStyle badge = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ── Nav Label ────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
