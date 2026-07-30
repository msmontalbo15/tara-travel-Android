import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/providers/friend_provider.dart';

class FriendListItem extends ConsumerWidget {
  final FriendModel friend;
  final bool isSearchMode;

  const FriendListItem({
    super.key,
    required this.friend,
    this.isSearchMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
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
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!isSearchMode && friend.status == FriendStatus.accepted)
                  Text(
                    friend.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: friend.isOnline ? AppColors.green : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          _buildActionButtons(ref),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: friend.color,
            shape: BoxShape.circle,
            image: friend.profilePhotoUrl != null
                ? DecorationImage(
                    image: NetworkImage(friend.profilePhotoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: friend.profilePhotoUrl == null
              ? Center(
                  child: Text(
                    friend.initials,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        ),
        if (!isSearchMode && friend.status == FriendStatus.accepted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: friend.isOnline ? AppColors.green : AppColors.cardBorder,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    if (isSearchMode) {
      if (friend.status == FriendStatus.pending) {
        return _buildButton('Pending', null, isOutlined: true);
      } else if (friend.status == FriendStatus.accepted) {
        return const Icon(Icons.check_circle, color: AppColors.primary);
      }
      return _buildButton('Add', () {
        ref.read(friendRepositoryProvider).sendRequest(friend.id);
        ref.invalidate(friendsProvider);
      });
    }

    if (friend.status == FriendStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconButton(Icons.close, () {
            ref.read(friendRepositoryProvider).rejectRequest(friend.id);
            ref.invalidate(friendsProvider);
          }, color: AppColors.red),
          const SizedBox(width: 8),
          _buildIconButton(Icons.check, () {
            ref.read(friendRepositoryProvider).acceptRequest(friend.id);
            ref.invalidate(friendsProvider);
          }, color: AppColors.primary),
        ],
      );
    }

    return _buildIconButton(Icons.more_horiz, () {
      // Show options like remove friend
    }, color: AppColors.textSecondary);
  }

  Widget _buildButton(String label, VoidCallback? onTap, {bool isOutlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : AppColors.primary,
          border: Border.all(color: isOutlined ? AppColors.textSecondary : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isOutlined ? AppColors.textSecondary : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
