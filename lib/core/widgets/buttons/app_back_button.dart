import 'dart:ui';
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Colors.white.withValues(alpha: 0.15);
    final fgColor = iconColor ?? Colors.white;

    return GestureDetector(
      onTap: onPressed ?? () => Navigator.maybePop(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: fgColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
