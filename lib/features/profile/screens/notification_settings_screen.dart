import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/profile_card.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const List<({String key, String title, String subtitle, IconData icon})> _categories = [
    (
      key: 'expenses',
      title: 'Expenses & Splits',
      subtitle: 'Alerts when new trip expenses are logged or settled',
      icon: Icons.receipt_long_outlined,
    ),
    (
      key: 'payments',
      title: 'Payment Requests',
      subtitle: 'Reminders for outstanding balances and GCash transfers',
      icon: Icons.payment_rounded,
    ),
    (
      key: 'itinerary',
      title: 'Itinerary Updates',
      subtitle: 'Instant alerts when trip schedules or stops change',
      icon: Icons.map_outlined,
    ),
    (
      key: 'group_location',
      title: 'Group Location & Safety',
      subtitle: 'Proximity alerts and rendezvous checkpoint updates',
      icon: Icons.location_on_outlined,
    ),
    (
      key: 'weather',
      title: 'Weather & Forecasts',
      subtitle: 'Rain alerts and weather warnings for destination stops',
      icon: Icons.thunderstorm_outlined,
    ),
    (
      key: 'reminders',
      title: 'Trip Reminders',
      subtitle: 'Packing checklist reminders and departure countdowns',
      icon: Icons.alarm_rounded,
    ),
    (
      key: 'system',
      title: 'System & Security',
      subtitle: 'Account logins, MPIN updates, and critical notices',
      icon: Icons.notifications_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontFamily: AppTextStyles.fontHeading,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notification Center',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose which alerts you want to receive on your device during trips.',
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
          ),
          const SizedBox(height: 20),
          const ProfileSectionTitle('TRIP ALERTS & REMINDERS'),
          ProfileCard(
            children: [
              for (int i = 0; i < _categories.length; i++) ...[
                Builder(
                  builder: (context) {
                    final item = _categories[i];
                    final isEnabled = profile.notificationPrefs[item.key] ?? true;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isEnabled ? AppColors.sand : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              size: 18,
                              color: isEnabled ? AppColors.primary : AppColors.warmMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isEnabled,
                            onChanged: (v) {
                              ref.read(profileProvider.notifier).toggleNotif(item.key, v);
                            },
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryLight,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (i < _categories.length - 1) const ProfileDivider(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
