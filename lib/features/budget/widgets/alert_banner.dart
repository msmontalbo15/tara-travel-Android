import 'package:flutter/material.dart';
import '../../../core/widgets/feedback/app_banner.dart';
import '../../../core/widgets/feedback/feedback_type.dart';

/// Legacy AlertBanner wrapping AppBanner for backward compatibility.
class AlertBanner extends StatelessWidget {
  final String message;
  final bool isDanger;

  const AlertBanner({
    super.key,
    required this.message,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return AppBanner(
      message: message,
      type: isDanger ? FeedbackType.error : FeedbackType.warning,
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
