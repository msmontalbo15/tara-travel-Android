import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable Tara Travel Brand Logo Widget
/// Renders the official brand logo (with optional wordmark) across app headers,
/// onboarding, auth screens, and empty state branding.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool isDark;
  final String? subtitle;

  const AppBrandLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.isDark = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final logoImage = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            Icons.flight_takeoff_rounded,
            color: isDark ? AppColors.deepEarth : Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );

    if (!showWordmark) {
      return logoImage;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoImage,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tara',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontFamilyFallback: const ['Georgia', 'serif'],
                fontSize: size * 0.65,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
                height: 1.0,
              ),
            ),
            Text(
              subtitle ?? 'TRAVEL',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontFamilyFallback: const ['Georgia', 'serif'],
                fontSize: (size * 0.28).clamp(9.0, 13.0),
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
                color: isDark ? AppColors.primaryLight : AppColors.darkAccent,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
