import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Next-Gen iOS 17/18 Glassmorphic Container.
/// Applies a backdrop blur filter with translucent surface overlays,
/// crisp micro-borders, and soft depth shadows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.color,
    this.borderColor,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.glassWhite;
    final effectiveBorderColor = borderColor ?? AppColors.glassBorder;

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorderColor, width: 1.0),
          ),
          child: child,
        ),
      ),
    );

    if (boxShadow != null || margin != null) {
      cardContent = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
        ),
        child: cardContent,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
