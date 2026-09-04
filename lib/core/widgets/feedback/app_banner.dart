import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'feedback_type.dart';

/// Standardized embedded contextual banner for forms, warnings, and empty states.
class AppBanner extends StatelessWidget {
  final String message;
  final String? title;
  final FeedbackType type;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.type = FeedbackType.info,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  });

  const AppBanner.info({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  }) : type = FeedbackType.info;

  const AppBanner.success({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  }) : type = FeedbackType.success;

  const AppBanner.warning({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  }) : type = FeedbackType.warning;

  const AppBanner.error({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
  }) : type = FeedbackType.error;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final Color bgColor = type.backgroundColor;
    final Color borderColor = type.borderColor;
    final Color fgColor = type.foregroundColor;
    final IconData iconData = icon ?? type.icon;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            iconData,
            color: fgColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: fgColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Convenience typedef for InlineAlert
typedef InlineAlert = AppBanner;
