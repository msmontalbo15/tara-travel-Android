import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_responsive.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/itinerary_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/packing_model.dart';
import '../../../core/providers/repository_providers.dart';

class ChatAttachmentPickerSheet extends ConsumerWidget {
  final TripModel trip;
  final VoidCallback onCreatePoll;
  final ValueChanged<String> onQuickPreset;
  final Function(ItineraryStop stop, int dayNumber) onShareItineraryStop;
  final ValueChanged<ExpenseModel> onShareExpense;
  final ValueChanged<PackingItem> onSharePackingItem;
  final Function(double lat, double lng, String label) onDropLocation;
  final ValueChanged<String> onSharePhoto;
  final ValueChanged<String> onSendMorningBriefing;

  const ChatAttachmentPickerSheet({
    super.key,
    required this.trip,
    required this.onCreatePoll,
    required this.onQuickPreset,
    required this.onShareItineraryStop,
    required this.onShareExpense,
    required this.onSharePackingItem,
    required this.onDropLocation,
    required this.onSharePhoto,
    required this.onSendMorningBriefing,
  });

  // ── 1. PICK ITINERARY STOP ────────────────────────────────────────────────
  void _openStopPicker(BuildContext context, WidgetRef ref) async {
    final itineraryRepo = ref.read(itineraryRepositoryProvider);
    final days = await itineraryRepo.getItinerary(
      trip.id,
      startDate: trip.fromDate,
      endDate: trip.toDate,
    );

    if (!context.mounted) return;

    final allStopsWithDay = <({ItineraryStop stop, int dayNumber})>[];
    for (final day in days) {
      for (final stop in day.stops) {
        allStopsWithDay.add((stop: stop, dayNumber: day.dayNumber));
      }
    }

    if (allStopsWithDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No stops found in the itinerary yet.'),
          backgroundColor: AppColors.deepEarth,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: ctx.sheetMaxHeight(0.7),
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Itinerary Stop to Share',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: allStopsWithDay.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.dividerLight),
                itemBuilder: (c, i) {
                  final item = allStopsWithDay[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      item.stop.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Day ${item.dayNumber} · ${(item.stop.location != null && item.stop.location!.isNotEmpty) ? item.stop.location! : 'No location specified'}',
                      style: const TextStyle( fontSize: 11, color: AppColors.muted),
                    ),
                    trailing: const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      onShareItineraryStop(item.stop, item.dayNumber);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. PICK EXPENSE ───────────────────────────────────────────────────────
  void _openExpensePicker(BuildContext context, WidgetRef ref) async {
    final expenseRepo = ref.read(expenseRepositoryProvider);
    final expenses = await expenseRepo.getExpenses(trip.id);

    if (!context.mounted) return;

    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses logged in this trip yet.'),
          backgroundColor: AppColors.deepEarth,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: ctx.sheetMaxHeight(0.7),
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Expense / Bill to Share',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.dividerLight),
                itemBuilder: (c, i) {
                  final exp = expenses[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.amberBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.amber, size: 20),
                    ),
                    title: Text(
                      exp.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '₱${exp.amount.toStringAsFixed(2)} · ${exp.category.name.toUpperCase()}',
                      style: const TextStyle( fontSize: 11, color: AppColors.muted),
                    ),
                    trailing: const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      onShareExpense(exp);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. PICK PACKING ITEM ──────────────────────────────────────────────────
  void _openPackingPicker(BuildContext context, WidgetRef ref) async {
    final packingRepo = ref.read(packingRepositoryProvider);
    final categories = await packingRepo.getCategories(trip.id);
    final items = categories.expand((c) => c.items).toList();

    if (!context.mounted) return;

    final unassignedItems = items.where((item) => !item.isAssigned).toList();
    final displayItems = unassignedItems.isNotEmpty ? unassignedItems : items;

    if (displayItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No packing items in this trip checklist.'),
          backgroundColor: AppColors.deepEarth,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: ctx.sheetMaxHeight(0.7),
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Urgent Packing Item',
              style: TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: displayItems.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.dividerLight),
                itemBuilder: (c, i) {
                  final item = displayItems[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.backpack_outlined, color: AppColors.blue, size: 20),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      item.isAssigned ? 'Assigned' : '⚠️ Needs someone to bring this',
                      style: TextStyle(
                        fontSize: 11,
                        color: item.isAssigned ? AppColors.muted : AppColors.primary,
                      ),
                    ),
                    trailing: const Icon(Icons.send_rounded, color: AppColors.primary, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      onSharePackingItem(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. PICK & SEND PHOTO ──────────────────────────────────────────────────
  void _pickPhoto(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      onSharePhoto(picked.path);
    }
  }

  // ── 5. DROP LOCATION ──────────────────────────────────────────────────────
  void _dropCurrentLocation(BuildContext context) async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to drop GPS pin.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final label = (trip.departurePoint != null && trip.departurePoint!.isNotEmpty)
          ? trip.departurePoint!
          : 'Current Meeting Location';
      onDropLocation(pos.latitude, pos.longitude, label);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not obtain GPS location: $e')),
        );
      }
    }
  }

  // ── 6. GENERATE MORNING BRIEFING ──────────────────────────────────────────
  void _generateBriefing(BuildContext context, WidgetRef ref) async {
    final itineraryRepo = ref.read(itineraryRepositoryProvider);
    final days = await itineraryRepo.getItinerary(trip.id, startDate: trip.fromDate, endDate: trip.toDate);

    final now = DateTime.now();
    ItineraryDay? todayDay;
    for (final day in days) {
      if (day.date.year == now.year && day.date.month == now.month && day.date.day == now.day) {
        todayDay = day;
        break;
      }
    }
    todayDay ??= days.isNotEmpty ? days.first : null;

    final stopCount = todayDay?.stops.length ?? 0;
    final stopNames = todayDay?.stops.take(3).map((s) => s.title).join(', ') ?? 'Free exploration';

    final text = '☀️ Good morning travel crew! Today is Day ${todayDay?.dayNumber ?? 1} in ${trip.name}.\n'
        '📍 $stopCount stops planned: $stopNames.\n'
        'Remember to stay hydrated, keep receipts for splits, and have an awesome day!';

    onSendMorningBriefing(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Trip Actions & Attachments',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontHeading,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepEarth,
                ),
              ),
              const SizedBox(height: 14),

              // Action Grid Row 1: Poll & Itinerary Stop
              Row(
                children: [
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.how_to_vote_rounded,
                      iconBg: AppColors.sand,
                      iconColor: AppColors.primary,
                      title: 'Group Poll',
                      subtitle: 'Crowdsource decisions',
                      onTap: () {
                        Navigator.pop(context);
                        onCreatePoll();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.place_rounded,
                      iconBg: AppColors.sand,
                      iconColor: AppColors.primary,
                      title: 'Share Stop',
                      subtitle: 'Itinerary card with GPS',
                      onTap: () {
                        Navigator.pop(context);
                        _openStopPicker(context, ref);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Grid Row 2: Expense Bill & Packing Alert
              Row(
                children: [
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.receipt_long_rounded,
                      iconBg: AppColors.amberBg,
                      iconColor: AppColors.amber,
                      title: 'Share Expense',
                      subtitle: 'Split bill request',
                      onTap: () {
                        Navigator.pop(context);
                        _openExpensePicker(context, ref);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.backpack_outlined,
                      iconBg: AppColors.blueLight,
                      iconColor: AppColors.blue,
                      title: 'Packing Ping',
                      subtitle: "Claim item to bring",
                      onTap: () {
                        Navigator.pop(context);
                        _openPackingPicker(context, ref);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Grid Row 3: Photo Upload & GPS Drop
              Row(
                children: [
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.photo_camera_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      title: 'Photo / Receipt',
                      subtitle: 'Upload trip picture',
                      onTap: () {
                        Navigator.pop(context);
                        _pickPhoto(context, ImageSource.gallery);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AttachmentTile(
                      icon: Icons.share_location_rounded,
                      iconBg: AppColors.greenBg,
                      iconColor: AppColors.green,
                      title: 'Drop GPS Pin',
                      subtitle: 'Share live meeting point',
                      onTap: () {
                        Navigator.pop(context);
                        _dropCurrentLocation(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Grid Row 4: Morning Briefing Bot
              _AttachmentTile(
                icon: Icons.wb_sunny_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                title: '🤖 Tara Bot Morning Briefing',
                subtitle: 'Summarize today’s schedule and stops for the group',
                onTap: () {
                  Navigator.pop(context);
                  _generateBriefing(context, ref);
                },
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.dividerLight),
              const SizedBox(height: 8),

              // Quick presets row
              const Text(
                'QUICK TRAVEL ALERTS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkAccent,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    emoji: '⏰',
                    text: 'Running 10m late',
                    onTap: () {
                      Navigator.pop(context);
                      onQuickPreset('⏰ Running 10 mins late! Meet you at the lobby.');
                    },
                  ),
                  _QuickChip(
                    emoji: '📍',
                    text: 'At meeting spot',
                    onTap: () {
                      Navigator.pop(context);
                      onQuickPreset('📍 Arrived at the meeting spot! Where are you guys?');
                    },
                  ),
                  _QuickChip(
                    emoji: '🍽️',
                    text: 'Where to eat?',
                    onTap: () {
                      Navigator.pop(context);
                      onQuickPreset('🍽️ Who has food recommendations for our next stop?');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String emoji;
  final String text;
  final VoidCallback onTap;

  const _QuickChip({
    required this.emoji,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.deepEarth,
            ),
          ),
        ],
      ),
    );
  }
}
