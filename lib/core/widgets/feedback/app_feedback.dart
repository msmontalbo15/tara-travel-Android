import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import 'feedback_type.dart';

/// Centralized, brand-unified feedback service for floating SnackBars and toasts.
class AppFeedback {
  AppFeedback._();

  /// Shows a success feedback message (green palette with check icon).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSuccess(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 3200),
    bool enableHaptic = true,
  }) {
    return show(
      context,
      message: message,
      type: FeedbackType.success,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration,
      enableHaptic: enableHaptic,
    );
  }

  /// Shows an error feedback message (coral-red palette with error icon).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showError(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onRetry,
    String? retryLabel,
    Duration duration = const Duration(milliseconds: 4000),
    bool enableHaptic = true,
  }) {
    return show(
      context,
      message: message,
      type: FeedbackType.error,
      title: title,
      onAction: onRetry,
      actionLabel: retryLabel ?? (onRetry != null ? 'Retry' : null),
      duration: duration,
      enableHaptic: enableHaptic,
    );
  }

  /// Shows a warning feedback message (amber palette with warning icon).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showWarning(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 3500),
    bool enableHaptic = true,
  }) {
    return show(
      context,
      message: message,
      type: FeedbackType.warning,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration,
      enableHaptic: enableHaptic,
    );
  }

  /// Shows an informational feedback message (sand/coral palette with info icon).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showInfo(
    BuildContext context,
    String message, {
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 3000),
    bool enableHaptic = true,
  }) {
    return show(
      context,
      message: message,
      type: FeedbackType.info,
      title: title,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration,
      enableHaptic: enableHaptic,
    );
  }

  /// Displays a customized, brand-styled floating SnackBar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    BuildContext context, {
    required String message,
    FeedbackType type = FeedbackType.info,
    String? title,
    IconData? customIcon,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(milliseconds: 3200),
    bool enableHaptic = true,
    EdgeInsetsGeometry? margin,
  }) {
    if (!context.mounted) return null;

    if (enableHaptic) {
      HapticFeedback.lightImpact().catchError((_) {});
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return null;

    messenger.hideCurrentSnackBar();

    final Color bgColor = type.backgroundColor;
    final Color borderColor = type.borderColor;
    final Color fgColor = type.foregroundColor;
    final IconData iconData = customIcon ?? type.icon;

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      padding: EdgeInsets.zero,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ambientShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fgColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: fgColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.trim().isNotEmpty) ...[
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: fgColor,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );

    return messenger.showSnackBar(snackBar);
  }
}
