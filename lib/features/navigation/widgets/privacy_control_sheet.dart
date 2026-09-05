import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../models/navigation_models.dart';
import '../providers/navigation_provider.dart';

class PrivacyControlSheet extends ConsumerWidget {
  const PrivacyControlSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PrivacyControlSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        context.safeBottomPadding(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Privacy & Battery',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Control how and when your GPS coordinates are shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Precision Selector
          const Text(
            'GPS PRECISION LEVEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          _OptionCard(
            title: 'Exact Location (Recommended for Convoys)',
            subtitle: 'Shares high-accuracy real-time GPS coordinates with turn-by-turn routing.',
            icon: Icons.gps_fixed_rounded,
            isSelected: nav.privacyMode == LocationPrivacyMode.exact,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setPrivacyMode(LocationPrivacyMode.exact);
            },
          ),
          const SizedBox(height: 8),

          _OptionCard(
            title: 'Approximate Bubble (~500m Fuzzing)',
            subtitle: 'Masks exact location within a 500-meter general area.',
            icon: Icons.blur_on_rounded,
            isSelected: nav.privacyMode == LocationPrivacyMode.approximate,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setPrivacyMode(LocationPrivacyMode.approximate);
            },
          ),
          const SizedBox(height: 8),

          _OptionCard(
            title: 'Ghost Mode (Pause Broadcast)',
            subtitle: 'Temporarily pause location broadcasting to all trip companions.',
            icon: Icons.visibility_off_outlined,
            isSelected: nav.isGhostActive,
            onTap: () {
              HapticFeedback.selectionClick();
              _showGhostDurationPicker(context, notifier);
            },
          ),
          const SizedBox(height: 16),

          // Battery Saver Mode Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFECE5DE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.battery_saver_rounded,
                    color: Color(0xFF34A853), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery Saver Polling',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Reduces GPS polling frequency to preserve battery',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: nav.isBatterySaver,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) {
                    HapticFeedback.selectionClick();
                    notifier.toggleBatterySaver();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGhostDurationPicker(
      BuildContext context, NavigationNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          ctx.safeBottomPadding(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pause Location Sharing Duration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _durationTile(
                ctx, notifier, 'For 15 Minutes', const Duration(minutes: 15)),
            _durationTile(
                ctx, notifier, 'For 1 Hour', const Duration(hours: 1)),
            _durationTile(ctx, notifier, 'Until End of Day (8 Hours)',
                const Duration(hours: 8)),
            _durationTile(ctx, notifier, 'Indefinitely (Until I Resume)', null),
          ],
        ),
      ),
    );
  }

  Widget _durationTile(
    BuildContext ctx,
    NavigationNotifier notifier,
    String label,
    Duration? duration,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () {
        notifier.setPrivacyMode(LocationPrivacyMode.ghost, duration: duration);
        Navigator.pop(ctx);
        Navigator.pop(ctx);
      },
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF9F7F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : const Color(0xFFECE5DE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF8E8E93),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
