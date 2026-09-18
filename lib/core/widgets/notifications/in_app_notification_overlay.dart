import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../services/in_app_notification_manager.dart';
import '../../services/notification_router.dart';

/// Global overlay widget inserted into MaterialApp.builder.
/// Displays top slide-down Dynamic Island frosted pill notifications.
class InAppNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const InAppNotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState
    extends ConsumerState<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  InAppNotificationItem? _activeItem;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap(InAppNotificationItem item) {
    HapticFeedback.lightImpact().catchError((_) {});
    ref.read(inAppNotificationProvider.notifier).dismissCurrent();
    NotificationRouter.instance.navigateTo(item.payload);
  }

  void _handleDismiss() {
    HapticFeedback.selectionClick().catchError((_) {});
    ref.read(inAppNotificationProvider.notifier).dismissCurrent();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InAppNotificationState>(inAppNotificationProvider, (prev, next) {
      if (next.current != null) {
        setState(() => _activeItem = next.current);
        _animCtrl.forward(from: 0.0);
        if (next.current!.isUrgent) {
          HapticFeedback.heavyImpact().catchError((_) {});
        } else {
          HapticFeedback.lightImpact().catchError((_) {});
        }
      } else if (prev?.current != null && next.current == null) {
        _animCtrl.reverse().then((_) {
          if (mounted) setState(() => _activeItem = null);
        });
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_activeItem != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _DynamicIslandBannerCard(
                      item: _activeItem!,
                      onTap: () => _handleTap(_activeItem!),
                      onDismiss: _handleDismiss,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DynamicIslandBannerCard extends StatelessWidget {
  final InAppNotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _DynamicIslandBannerCard({
    required this.item,
    required this.onTap,
    required this.onDismiss,
  });

  Color _badgeColor() {
    switch (item.type) {
      case InAppNotificationType.expense:
        return AppColors.greenBright;
      case InAppNotificationType.announcement:
      case InAppNotificationType.convoySos:
        return AppColors.primary;
      case InAppNotificationType.geofenceArrival:
      case InAppNotificationType.weather:
        return AppColors.amber;
      case InAppNotificationType.chat:
        return AppColors.primary;
      case InAppNotificationType.packing:
      case InAppNotificationType.system:
        return AppColors.deepEarth;
    }
  }

  IconData _badgeIcon() {
    switch (item.type) {
      case InAppNotificationType.expense:
        return Icons.attach_money_rounded;
      case InAppNotificationType.announcement:
        return Icons.campaign_rounded;
      case InAppNotificationType.convoySos:
        return Icons.warning_rounded;
      case InAppNotificationType.geofenceArrival:
        return Icons.location_on_rounded;
      case InAppNotificationType.weather:
        return Icons.cloud_outlined;
      case InAppNotificationType.chat:
        return Icons.chat_bubble_rounded;
      case InAppNotificationType.packing:
        return Icons.backpack_rounded;
      case InAppNotificationType.system:
        return Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeCol = _badgeColor();

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: item.isUrgent
                    ? AppColors.primary
                    : AppColors.surfaceLight.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: item.isUrgent
                      ? AppColors.darkAccent
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.isUrgent
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Category Avatar Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.isUrgent
                          ? Colors.white.withValues(alpha: 0.20)
                          : badgeCol.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _badgeIcon(),
                      color: item.isUrgent ? Colors.white : badgeCol,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content Text
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: item.isUrgent
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                item.subtitle!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: item.isUrgent
                                      ? Colors.white70
                                      : AppColors.warmMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: item.isUrgent
                                ? Colors.white.withValues(alpha: 0.90)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Trailing Action Chevron
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: item.isUrgent
                        ? Colors.white70
                        : AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
