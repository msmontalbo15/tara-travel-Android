import 'package:flutter/material.dart';
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
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Setting your home location helps us recommend local transport and currency conversions for your trips.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
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
                  style: TextStyle(fontFamily: 'Playfair Display', fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your GCash number is missing. Adding payment info lets your travel group settle expenses directly with you.',
              style: TextStyle(fontFamily: 'DM Sans', fontSize: 14, color: AppColors.textPrimary),
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
}
