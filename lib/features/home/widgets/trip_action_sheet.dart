import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/trip_types.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/selected_trip_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_colors.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(willArchive ? 'Trip archived 📦' : 'Trip restored ✨'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    Navigator.pop(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Trip',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${trip.name}"? This action cannot be undone.',
          style: const TextStyle(fontFamily: 'DM Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'DM Sans', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(tripRepositoryProvider);
      await repo.deleteTrip(trip.id);
      ref.read(selectedTripIdProvider.notifier).clear();
      ref.invalidate(allTripsProvider);
      ref.invalidate(activeTripProvider);
      ref.invalidate(selectedTripProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trip "${trip.name}" deleted.'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = trip.coverEmoji ?? AppTripTypes.getEmoji(trip.tripType);
    final isArchived = trip.isArchived;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                        fontFamily: 'Playfair Display',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.destination.isNotEmpty ? trip.destination : 'No destination specified',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
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

          _ActionItem(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFEB4D4B),
            title: 'Delete Trip',
            subtitle: 'Permanently remove this trip and its data',
            isDestructive: true,
            onTap: () => _handleDelete(context),
          ),
        ],
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
                        fontFamily: 'DM Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? const Color(0xFFEB4D4B) : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
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
