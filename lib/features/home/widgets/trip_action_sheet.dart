import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/selected_trip_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback/app_feedback.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/share/share_trip_modal.dart';
import '../../trip_detail/widgets/edit_trip_sheet.dart';

class TripActionSheet extends StatelessWidget {
  final TripModel trip;
  final WidgetRef ref;

  const TripActionSheet({
    super.key,
    required this.trip,
    required this.ref,
  });

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    TripModel trip,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TripActionSheet(trip: trip, ref: ref),
    );
  }

  Future<void> _handleNavigation(BuildContext context) async {
    Navigator.pop(context);
    ref.read(selectedTripIdProvider.notifier).select(trip.id);
    Navigator.pushNamed(context, '/navigation');
  }

  Future<void> _handleEdit(BuildContext context) async {
    Navigator.pop(context);
    await EditTripSheet.show(context, trip);
  }

  Future<void> _handleShare(BuildContext context) async {
    Navigator.pop(context);
    await ShareTripModal.show(
      context,
      ref,
      trip,
      initialScope: ShareScope.overview,
    );
  }

  Future<void> _handleArchive(BuildContext context) async {
    Navigator.pop(context);
    final willArchive = !trip.isArchived;
    final repo = ref.read(tripRepositoryProvider);
    final updated = trip.copyWith(isArchived: willArchive);
    await repo.updateTrip(updated);

    ref.invalidate(allTripsProvider);
    ref.invalidate(activeTripProvider);
    ref.invalidate(selectedTripProvider);

    if (context.mounted) {
      AppFeedback.showSuccess(
        context,
        willArchive ? 'Trip archived 📦' : 'Trip restored ✨',
      );
    }
  }

  Future<void> _handleLeave(BuildContext context) async {
    Navigator.pop(context);
    final confirm = await AppDialog.showDestructive(
      context,
      title: 'Leave Trip',
      message:
          'Are you sure you want to leave "${trip.name}"? You will need an invite code to rejoin.',
      confirmLabel: 'Leave Trip',
      icon: Icons.exit_to_app_rounded,
    );

    if (confirm == true && context.mounted) {
      try {
        final repo = ref.read(tripRepositoryProvider);
        await repo.leaveTrip(trip.id);
        ref.read(selectedTripIdProvider.notifier).clear();
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        ref.invalidate(selectedTripProvider);

        if (context.mounted) {
          AppFeedback.showInfo(
            context,
            'You left "${trip.name}".',
            title: 'Trip Exited',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
            title: 'Failed to Leave Trip',
          );
        }
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    Navigator.pop(context);
    AppDialog.showDestructive(
      context,
      title: 'Delete Trip',
      message: 'Are you sure you want to delete "${trip.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      onConfirm: () async {
        final repo = ref.read(tripRepositoryProvider);
        await repo.deleteTrip(trip.id);
        ref.read(selectedTripIdProvider.notifier).clear();
        ref.invalidate(allTripsProvider);
        ref.invalidate(activeTripProvider);
        ref.invalidate(selectedTripProvider);

        if (context.mounted) {
          AppFeedback.showInfo(
            context,
            'Trip "${trip.name}" deleted.',
            title: 'Trip Deleted',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = trip.coverEmoji;
    final isArchived = trip.isArchived;
    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id;
    final isOwner = trip.ownerId == currentUserId;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Trip summary header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          trip.destination.isNotEmpty
                              ? '${trip.destination} · ${DateFormat('MMM d').format(trip.fromDate)} - ${DateFormat('MMM d, yyyy').format(trip.toDate)}'
                              : '${DateFormat('MMM d').format(trip.fromDate)} - ${DateFormat('MMM d, yyyy').format(trip.toDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.cardBorder),
              const SizedBox(height: 10),

              // Action Items
              _ActionItem(
                icon: Icons.navigation_rounded,
                iconColor: AppColors.primary,
                title: 'Live Navigation & Radar',
                subtitle: 'Real-time group location sharing & convoy alerts',
                onTap: () => _handleNavigation(context),
              ),

              _ActionItem(
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF2E86DE),
                title: 'Edit Trip Details',
                subtitle: 'Update dates, destination, budget or type',
                onTap: () => _handleEdit(context),
              ),

              if (trip.inviteCode.isNotEmpty)
                _ActionItem(
                  icon: Icons.copy_rounded,
                  iconColor: AppColors.primary,
                  title: 'Copy Invite Code',
                  subtitle: 'Code: ${trip.inviteCode}',
                  onTap: () => _handleShare(context),
                ),

              _ActionItem(
                icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                iconColor: AppColors.amberText,
                title: isArchived ? 'Restore Trip' : 'Archive Trip',
                subtitle: isArchived ? 'Move back to active trips' : 'Move to archived archive storage',
                onTap: () => _handleArchive(context),
              ),

              if (isOwner)
                _ActionItem(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEB4D4B),
                  title: 'Delete Trip',
                  subtitle: 'Permanently remove this trip and its data',
                  isDestructive: true,
                  onTap: () => _handleDelete(context),
                )
              else
                _ActionItem(
                  icon: Icons.exit_to_app_rounded,
                  iconColor: const Color(0xFFE67E22),
                  title: 'Leave Trip',
                  subtitle: 'Remove yourself from this trip',
                  isDestructive: true,
                  onTap: () => _handleLeave(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEB4D4B) : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.warmMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
