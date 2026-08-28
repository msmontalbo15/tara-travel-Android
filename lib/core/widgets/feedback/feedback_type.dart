import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Semantic intent of the feedback element (SnackBars, dialogs, banners).
enum FeedbackType {
  info,
  success,
  warning,
  error;

  /// Background color aligned with Brand Identity tokens
  Color get backgroundColor {
    switch (this) {
      case FeedbackType.info:
        return AppColors.sand;
      case FeedbackType.success:
        return AppColors.greenBg;
      case FeedbackType.warning:
        return AppColors.amberBg;
      case FeedbackType.error:
        return AppColors.redLight;
    }
  }

  /// Border and accent color
  Color get borderColor {
    switch (this) {
      case FeedbackType.info:
        return AppColors.primaryLight.withValues(alpha: 0.7);
      case FeedbackType.success:
        return AppColors.greenBright.withValues(alpha: 0.6);
      case FeedbackType.warning:
        return AppColors.amber.withValues(alpha: 0.6);
      case FeedbackType.error:
        return AppColors.red.withValues(alpha: 0.6);
    }
  }

  /// Primary icon and text highlight color
  Color get foregroundColor {
    switch (this) {
      case FeedbackType.info:
        return AppColors.primary;
      case FeedbackType.success:
        return AppColors.green;
      case FeedbackType.warning:
        return AppColors.amberText;
      case FeedbackType.error:
        return AppColors.red;
    }
  }

  /// Default icon matching intent
  IconData get icon {
    switch (this) {
      case FeedbackType.info:
        return Icons.info_outline_rounded;
      case FeedbackType.success:
        return Icons.check_circle_outline_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.error:
        return Icons.error_outline_rounded;
    }
  }

  /// Default semantic title
  String get defaultTitle {
    switch (this) {
      case FeedbackType.info:
        return 'Note';
      case FeedbackType.success:
        return 'Success';
      case FeedbackType.warning:
        return 'Notice';
      case FeedbackType.error:
        return 'Attention';
    }
  }
}
