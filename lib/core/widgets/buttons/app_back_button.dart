import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Style variants for the brand [AppBackButton].
enum AppBackButtonVariant {
  /// Frosted glass background with light borders, ideal for dark/hero gradients.
  glass,

  /// Light surface with subtle border, ideal for light backgrounds (e.g. Friends, Notifications).
  light,

  /// Brand tinted (Sand background with light coral border & coral icon).
  brand,

  /// Flat transparent with hover/touch feedback.
  ghost,
}

/// A standardized Tara Travel branded back button conforming to the design tokens:
/// - 12px border radius
/// - 40x40 touch target
/// - Subtle borders and responsive touch feedback
/// - Cohesive icon style (`Icons.arrow_back_ios_new_rounded`)
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final AppBackButtonVariant variant;
  final Color? color;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.variant = AppBackButtonVariant.glass,
    this.color,
    this.iconColor,
    this.size = 40.0,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    Color effectiveBg;
    Color effectiveIcon;
    Border? effectiveBorder;
    bool useBlur = false;

    switch (variant) {
      case AppBackButtonVariant.glass:
        useBlur = true;
        effectiveBg = color ?? Colors.white.withValues(alpha: 0.12);
        effectiveIcon = iconColor ?? Colors.white;
        effectiveBorder = Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        );
        break;

      case AppBackButtonVariant.light:
        effectiveBg = color ?? Colors.white;
        effectiveIcon = iconColor ?? AppColors.deepEarth;
        effectiveBorder = Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        );
        break;

      case AppBackButtonVariant.brand:
        effectiveBg = color ?? AppColors.sand;
        effectiveIcon = iconColor ?? AppColors.primary;
        effectiveBorder = Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1.0,
        );
        break;

      case AppBackButtonVariant.ghost:
        effectiveBg = color ?? Colors.transparent;
        effectiveIcon = iconColor ?? AppColors.primary;
        effectiveBorder = Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.0,
        );
        break;
    }

    Widget buttonContent = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(12),
        border: effectiveBorder,
        boxShadow: variant == AppBackButtonVariant.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 1.5),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: effectiveIcon,
            size: iconSize,
          ),
        ),
      ),
    );

    if (useBlur) {
      buttonContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: buttonContent,
        ),
      );
    } else {
      buttonContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: buttonContent,
      );
    }

    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: buttonContent,
        ),
      ),
    );
  }
}
