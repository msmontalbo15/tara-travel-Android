import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';

class JitGuard {
  /// Checks if critical trip creation profile data (location / onboarding) is missing.
  /// If missing, shows a dialog prompting the user, allowing continuation.
  static Future<bool> checkCreateTripGuard(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);

    if (profile.hasCompletedOnboarding && profile.homeCity.isNotEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.explore_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Quick Profile Setup',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Setting your home location helps us recommend local transport and currency conversions for your trips.',
          style: TextStyle( fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue anyway', style: TextStyle(color: AppColors.warmMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context, false);
              Navigator.pushNamed(context, '/onboarding');
            },
            child: const Text('Complete Setup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? true;
  }

  /// Checks if payment details (GCash) are present before adding/settling expenses.
  static Future<bool> checkExpensePaymentGuard(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider);

    if (profile.gcashNumber != null && profile.gcashNumber!.isNotEmpty) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Add Payment Info',
                  style: TextStyle(fontFamily: AppTextStyles.fontHeading, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your GCash number is missing. Adding payment info lets your travel group settle expenses directly with you.',
              style: TextStyle( fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Skip for now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context, false);
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: const Text('Add GCash Info', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result ?? true;
  }

  /// Checks if the selected trip dates overlap with existing trips and shows a non-blocking confirmation dialog.
  /// Returns `true` if the user chooses to proceed anyway, or `false` if they cancel/re-adjust.
  static Future<bool> checkDateOverlapGuard(
    BuildContext context, {
    required List<String> conflictingTripNames,
  }) async {
    if (conflictingTripNames.isEmpty) return true;

    final tripListText = conflictingTripNames.map((name) => '• $name').join('\n');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 26),
            SizedBox(width: 10),
            Text(
              'Schedule Conflict',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepEarth,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You already have an existing trip scheduled during these dates:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
              ),
              child: Text(
                tripListText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepEarth,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Do you still want to proceed with these dates?',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.warmMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Change Dates',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.warmMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Proceed Anyway',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
