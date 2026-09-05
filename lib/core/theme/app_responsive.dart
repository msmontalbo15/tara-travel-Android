import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Centralized responsive layout tokens and [BuildContext] extensions
/// that replace hardcoded [MediaQuery] arithmetic scattered across screens.
///
/// Usage:
/// ```dart
/// final hPad = context.responsiveHPad;          // 16dp compact, 20dp standard, 24dp wide
/// final sheetH = context.sheetMaxHeight(0.85);   // safe height minus system insets
/// final bottom = context.safeBottomPadding(24);   // 24 + system bottom inset
/// final kbBot = context.keyboardBottomPadding(24); // keyboard-aware bottom
/// ```
class AppResponsive {
  AppResponsive._();

  // ── Breakpoint Constants (logical dp) ──────────────────────────
  /// Width below which we consider a "compact" phone (iPhone SE, Galaxy A03s,
  /// fold cover screens, small KaiOS-derived devices).
  static const double compactWidth = 360;

  /// Standard phone width bucket (iPhone 14 / Pixel 7 class).
  static const double standardWidth = 414;

  /// Tablet / large foldable inner-screen threshold.
  static const double tabletWidth = 600;

  // ── Text Scale Clamp ───────────────────────────────────────────
  /// Minimum scale factor allowed for accessibility text sizing.
  static const double minTextScale = 0.85;

  /// Maximum scale factor — prevents extreme font enlargement from
  /// breaking fixed-height badges, nav pills, and button containers.
  static const double maxTextScale = 1.20;

  // ── Horizontal Padding Tokens ──────────────────────────────────
  /// Returns responsive horizontal page padding based on screen width.
  static double horizontalPadding(double screenWidth) {
    if (screenWidth < compactWidth) return 16;
    if (screenWidth < standardWidth) return 20;
    return 24;
  }

  // ── Sheet Height ───────────────────────────────────────────────
  /// Computes a safe maximum sheet height as a fraction of the
  /// available viewport (total height minus top + bottom system insets).
  static double sheetMaxHeight(
    BuildContext context, {
    double fraction = 0.85,
  }) {
    final mq = MediaQuery.of(context);
    final available = mq.size.height - mq.padding.top - mq.padding.bottom;
    return math.min(available * fraction, mq.size.height * 0.92);
  }

  /// Returns `base + systemBottomPadding`, providing safe bottom spacing
  /// that accounts for gesture-navigation bars, home indicators, etc.
  static double safeBottomPadding(BuildContext context, double base) {
    return base + MediaQuery.of(context).padding.bottom;
  }

  /// Returns `base + viewInsets.bottom` (keyboard) + padding.bottom,
  /// used inside modals and sheets that contain text inputs.
  static double keyboardBottomPadding(BuildContext context, double base) {
    final mq = MediaQuery.of(context);
    return base + mq.viewInsets.bottom + mq.padding.bottom;
  }

  /// Wraps a child [Widget] in a clamped [MediaQuery] that enforces the
  /// configured text scale bounds. Intended for use in `MaterialApp.builder`.
  static Widget clampedTextScaleBuilder(
    BuildContext context,
    Widget? child,
  ) {
    final mq = MediaQuery.of(context);
    final clamped = mq.textScaler.clamp(
      minScaleFactor: minTextScale,
      maxScaleFactor: maxTextScale,
    );
    return MediaQuery(
      data: mq.copyWith(textScaler: clamped),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// BuildContext extensions — syntactic sugar over AppResponsive statics
// ═════════════════════════════════════════════════════════════════════

extension ResponsiveContext on BuildContext {
  // ── Screen Dimensions ──────────────────────────────────────────
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // ── Breakpoint Queries ─────────────────────────────────────────
  bool get isCompactPhone => screenWidth < AppResponsive.compactWidth;
  bool get isStandardPhone =>
      screenWidth >= AppResponsive.compactWidth &&
      screenWidth < AppResponsive.tabletWidth;
  bool get isTablet => screenWidth >= AppResponsive.tabletWidth;

  // ── Responsive Horizontal Padding ──────────────────────────────
  double get responsiveHPad => AppResponsive.horizontalPadding(screenWidth);

  // ── System Insets ──────────────────────────────────────────────
  double get topInset => MediaQuery.of(this).padding.top;
  double get bottomInset => MediaQuery.of(this).padding.bottom;
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  // ── Sheet Helpers ──────────────────────────────────────────────
  /// Safe maximum height for a modal bottom sheet at the given [fraction]
  /// of available viewport (defaults to 0.85).
  double sheetMaxHeight([double fraction = 0.85]) =>
      AppResponsive.sheetMaxHeight(this, fraction: fraction);

  /// `base` + system bottom padding (gesture bar / home indicator).
  double safeBottomPadding([double base = 24]) =>
      AppResponsive.safeBottomPadding(this, base);

  /// `base` + keyboard inset + system bottom padding.
  double keyboardBottomPadding([double base = 24]) =>
      AppResponsive.keyboardBottomPadding(this, base);
}
