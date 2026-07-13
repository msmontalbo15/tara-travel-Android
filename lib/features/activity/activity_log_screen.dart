import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/activity_provider.dart';
import '../../core/models/activity_model.dart';

// Standalone screen (with back button)
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.deepEarth,
        foregroundColor: Colors.white,
        title: const Text('Activity Log', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: _ActivityList(),
    );
  }
}

// Inline version (no app bar, for embedding in TripDetailScreen)
class ActivityLogScreenInline extends ConsumerWidget {
  const ActivityLogScreenInline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ActivityList();
  }
}

class _ActivityList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityProvider);
    return activityAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Unable to load activity')),
      data: (state) {
        final items = state.filtered;
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No activity yet.',
              style: TextStyle(fontFamily: 'DM Sans', color: AppColors.warmMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _ActivityRow(item: items[i], isLast: i == items.length - 1),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;
  final bool isLast;

  const _ActivityRow({required this.item, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Color(item.actorColor), shape: BoxShape.circle),
                  child: Center(child: Text(item.actorInitials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.dividerLight),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 12, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'DM Sans', fontSize: 13, color: AppColors.deepEarth),
                      children: [
                        TextSpan(text: '${item.type.emoji}  '),
                        TextSpan(text: item.actorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ' ${item.description}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatTime(item.timestamp), style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, color: AppColors.warmMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
