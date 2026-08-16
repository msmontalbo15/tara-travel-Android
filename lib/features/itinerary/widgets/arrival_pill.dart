import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/theme/app_colors.dart';

/// Swipeable floating arrival pill.
///
/// - Swipe RIGHT → triggers [onCheckIn] (check in & fulfill)
/// - Swipe LEFT  → triggers [onDismiss] (snooze / ignore)
/// - Tap [Check In] button → same as swipe right
class ArrivalPill extends StatefulWidget {
  final ItineraryStop stop;
  final List<MemberModel> checkedInMembers;
  final VoidCallback onCheckIn;
  final VoidCallback onDismiss;

  const ArrivalPill({
    super.key,
    required this.stop,
    required this.checkedInMembers,
    required this.onCheckIn,
    required this.onDismiss,
  });

  @override
  State<ArrivalPill> createState() => _ArrivalPillState();
}

class _ArrivalPillState extends State<ArrivalPill>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _confirmed = false;
  bool _dismissed = false;

  late final AnimationController _entryCtrl;
  late final Animation<Offset> _entryAnim;

  static const double _checkInThreshold = 80.0;
  static const double _dismissThreshold = -80.0;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entryAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails d) {
    setState(() => _dragOffset += d.delta.dx);
  }

  void _handleDragEnd(DragEndDetails d) {
    if (_dragOffset >= _checkInThreshold) {
      _triggerCheckIn();
    } else if (_dragOffset <= _dismissThreshold) {
      _triggerDismiss();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _triggerCheckIn() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _confirmed = true;
      _dragOffset = 0;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onCheckIn();
  }

  void _triggerDismiss() async {
    HapticFeedback.lightImpact();
    setState(() {
      _dismissed = true;
      _dragOffset = 0;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final clampedDrag = _dragOffset.clamp(-160.0, 160.0);
    final checkInProgress = (clampedDrag / _checkInThreshold).clamp(0.0, 1.0);
    final dismissProgress = (-clampedDrag / 80.0).clamp(0.0, 1.0);

    return SlideTransition(
      position: _entryAnim,
      child: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        child: AnimatedOpacity(
          opacity: _dismissed ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 280),
          child: Transform.translate(
            offset: Offset(clampedDrag, 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _ActionBackground(
                  checkInProgress: checkInProgress,
                  dismissProgress: dismissProgress,
                ),
                AnimatedScale(
                  scale: _confirmed ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: _confirmed
                              ? AppColors.greenBright.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _confirmed
                                ? AppColors.greenBright
                                : Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _confirmed
                                  ? AppColors.greenBright.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: _confirmed
                            ? _ConfirmedContent(stop: stop)
                            : _PillContent(
                                stop: stop,
                                checkedInMembers: widget.checkedInMembers,
                                onCheckIn: _triggerCheckIn,
                                checkInProgress: checkInProgress,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ActionBackground extends StatelessWidget {
  final double checkInProgress;
  final double dismissProgress;

  const _ActionBackground({
    required this.checkInProgress,
    required this.dismissProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedOpacity(
            opacity: checkInProgress,
            duration: const Duration(milliseconds: 80),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.greenBright.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.greenBright, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Check In',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenBright,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: AnimatedOpacity(
            opacity: dismissProgress,
            duration: const Duration(milliseconds: 80),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dismiss',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.close_rounded, color: AppColors.red, size: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PillContent extends StatelessWidget {
  final ItineraryStop stop;
  final List<MemberModel> checkedInMembers;
  final VoidCallback onCheckIn;
  final double checkInProgress;

  const _PillContent({
    required this.stop,
    required this.checkedInMembers,
    required this.onCheckIn,
    required this.checkInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stop type icon with pulsing beacon
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stop.type.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(stop.type.icon, color: stop.type.color, size: 22),
              ),
              // Pulse ring
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (_, v, __) => Opacity(
                  opacity: (1 - v).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1.0 + v * 0.7,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: stop.type.color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Text info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "YOU'VE ARRIVED",
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenBright,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stop.title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepEarth,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (checkedInMembers.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    _MemberAvatarStack(members: checkedInMembers),
                    const SizedBox(width: 6),
                    Text(
                      '${checkedInMembers.length} already here',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 3),
              const Text(
                '← Dismiss    Check In →',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  color: AppColors.warmMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Check-in button
        GestureDetector(
          onTap: onCheckIn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greenBright
                  .withValues(alpha: 0.12 + checkInProgress * 0.88),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.greenBright
                    .withValues(alpha: 0.4 + checkInProgress * 0.6),
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: AppColors.greenBright, size: 18),
                Text(
                  'Check\nIn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greenBright,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmedContent extends StatelessWidget {
  final ItineraryStop stop;
  const _ConfirmedContent({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CHECKED IN!',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                stop.title,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                'Squad notified 🎉',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MemberAvatarStack extends StatelessWidget {
  final List<MemberModel> members;
  const _MemberAvatarStack({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    return SizedBox(
      width: visible.length * 14.0 + 8,
      height: 20,
      child: Stack(
        children: List.generate(visible.length, (i) {
          final m = visible[i];
          return Positioned(
            left: i * 12.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: m.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                m.initials.substring(0, 1),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
