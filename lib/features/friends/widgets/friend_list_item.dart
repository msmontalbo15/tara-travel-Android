import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/providers/friend_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/feedback/app_dialog.dart';

class FriendListItem extends ConsumerStatefulWidget {
  final FriendModel friend;
  final bool isSearchMode;
  final bool isIncomingRequest;
  final bool isOutgoingRequest;
  final VoidCallback? onActionCompleted;

  const FriendListItem({
    super.key,
    required this.friend,
    this.isSearchMode = false,
    this.isIncomingRequest = false,
    this.isOutgoingRequest = false,
    this.onActionCompleted,
  });

  @override
  ConsumerState<FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends ConsumerState<FriendListItem> {
  bool _isLoading = false;

  void _invalidateAllFriendProviders() {
    ref.invalidate(friendsProvider);
    ref.invalidate(incomingRequestsProvider);
    ref.invalidate(outgoingRequestsProvider);
    widget.onActionCompleted?.call();
  }

  Future<void> _handleAccept() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(friendRepositoryProvider);
      await repo.acceptRequest(widget.friend.id);
      _invalidateAllFriendProviders();
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'You are now friends with ${widget.friend.name}! 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Failed to accept: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeclineOrCancel({bool isCancel = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(friendRepositoryProvider);
      await repo.rejectRequest(widget.friend.id);
      _invalidateAllFriendProviders();
      if (mounted) {
        AppFeedback.showInfo(
          context,
          isCancel ? 'Friend request cancelled.' : 'Friend request declined.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendRequest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(friendRepositoryProvider);
      await repo.sendRequest(widget.friend.id);
      _invalidateAllFriendProviders();
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Friend request sent to ${widget.friend.name}! 🚀',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFriendOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, ctx.safeBottomPadding(24)),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Friend Profile Header
              Row(
                children: [
                  _buildAvatar(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.friend.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.friend.isCurrentlyOnline ? AppColors.green : AppColors.muted,
                                shape: BoxShape.circle,
                                boxShadow: widget.friend.isCurrentlyOnline
                                    ? [
                                        BoxShadow(
                                          color: AppColors.green.withValues(alpha: 0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.friend.presenceStatusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.friend.isCurrentlyOnline ? AppColors.green : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.surfaceLight),
              const SizedBox(height: 8),

              // Option 1: Invite to a Trip
              _sheetTile(
                icon: Icons.flight_takeoff_rounded,
                iconColor: AppColors.primary,
                title: 'Invite to Trip',
                subtitle: 'Add ${widget.friend.name} to one of your trips',
                onTap: () {
                  Navigator.pop(ctx);
                  _showInviteToTripDialog();
                },
              ),

              // Option 2: Copy User ID
              _sheetTile(
                icon: Icons.copy_rounded,
                iconColor: AppColors.blue,
                title: 'Copy User ID',
                subtitle: 'Copy ${widget.friend.name}\'s unique ID',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.friend.id));
                  Navigator.pop(ctx);
                  AppFeedback.showInfo(
                    context,
                    'Friend ID copied to clipboard!',
                  );
                },
              ),

              // Option 3: Remove Friend
              _sheetTile(
                icon: Icons.person_remove_rounded,
                iconColor: AppColors.red,
                title: 'Remove Friend',
                subtitle: 'Remove from your friends list',
                isDestructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmRemoveFriend();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteToTripDialog() {
    final tripsAsync = ref.read(allTripsProvider);
    final trips = tripsAsync.value ?? [];

    if (trips.isEmpty) {
      AppFeedback.showInfo(
        context,
        'You don\'t have any active trips yet. Create one first!',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Invite ${widget.friend.name}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a trip to copy its invite code:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceLight),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.luggage_rounded, color: AppColors.primary, size: 18),
                      ),
                      title: Text(
                        trip.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Code: ${trip.inviteCode.isNotEmpty ? trip.inviteCode : 'N/A'}',
                        style: const TextStyle( fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.send_rounded, size: 16, color: AppColors.primary),
                      onTap: () {
                        if (trip.inviteCode.isNotEmpty) {
                          Clipboard.setData(ClipboardData(
                              text: 'Join my trip "${trip.name}" on Tara Travel! Invite code: ${trip.inviteCode}'));
                          Navigator.pop(ctx);
                          AppFeedback.showSuccess(
                            context,
                            'Trip invite code copied for "${trip.name}"! 📋',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle( color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFriend() {
    AppDialog.showDestructive(
      context,
      title: 'Remove Friend?',
      message: 'Are you sure you want to remove ${widget.friend.name} from your friends list?',
      confirmLabel: 'Remove',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          final repo = ref.read(friendRepositoryProvider);
          await repo.removeFriend(widget.friend.id);
          _invalidateAllFriendProviders();
          if (mounted) {
            AppFeedback.showInfo(
              context,
              'Removed ${widget.friend.name} from friends.',
            );
          }
        } catch (e) {
          if (mounted) {
            AppFeedback.showError(context, 'Error: $e');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.red : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _buildSubtitle(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    if (widget.isIncomingRequest) {
      return const Text(
        'Wants to be your friend',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      );
    }

    if (widget.isOutgoingRequest) {
      return const Text(
        'Request pending approval',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      );
    }

    if (widget.isSearchMode) {
      if (widget.friend.email != null && widget.friend.email!.isNotEmpty) {
        return Text(
          widget.friend.email!,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    // Default Accepted Friend subtitle: Online Presence
    final isOnline = widget.friend.isCurrentlyOnline;
    final statusText = widget.friend.presenceStatusText;

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.green : AppColors.muted,
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isOnline ? FontWeight.w600 : FontWeight.w500,
            color: isOnline ? AppColors.green : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({double size = 46}) {
    final isOnline = widget.friend.isCurrentlyOnline;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.friend.color,
            shape: BoxShape.circle,
            image: widget.friend.profilePhotoUrl != null && widget.friend.profilePhotoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(widget.friend.profilePhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (widget.friend.profilePhotoUrl == null || widget.friend.profilePhotoUrl!.isEmpty)
              ? Center(
                  child: Text(
                    widget.friend.initials,
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        if (!widget.isSearchMode &&
            !widget.isIncomingRequest &&
            !widget.isOutgoingRequest &&
            widget.friend.status == FriendStatus.accepted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.green : AppColors.cardBorder,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
        ),
      );
    }

    // 1. Incoming Friend Request Mode
    if (widget.isIncomingRequest || widget.friend.status == FriendStatus.incoming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decline Button
          _iconButton(
            icon: Icons.close_rounded,
            tooltip: 'Decline',
            color: AppColors.textSecondary,
            bgColor: AppColors.surfaceLight,
            onTap: () => _handleDeclineOrCancel(isCancel: false),
          ),
          const SizedBox(width: 8),
          // Accept Button
          GestureDetector(
            onTap: _handleAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 2. Outgoing Sent Request Mode
    if (widget.isOutgoingRequest) {
      return GestureDetector(
        onTap: () => _handleDeclineOrCancel(isCancel: true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Search Results Mode
    if (widget.isSearchMode) {
      switch (widget.friend.status) {
        case FriendStatus.accepted:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: AppColors.green),
                SizedBox(width: 4),
                Text(
                  'Friends',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          );

        case FriendStatus.pending:
          return GestureDetector(
            onTap: () => _handleDeclineOrCancel(isCancel: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Requested',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          );

        case FriendStatus.incoming:
          return GestureDetector(
            onTap: _handleAccept,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );

        case FriendStatus.none:
        default:
          return GestureDetector(
            onTap: _handleSendRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    }

    // 4. Default Accepted Friend Mode: 3-Dots Action Menu
    return _iconButton(
      icon: Icons.more_vert_rounded,
      tooltip: 'Options',
      color: AppColors.textSecondary,
      bgColor: AppColors.surfaceLight,
      onTap: _showFriendOptionsModal,
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
