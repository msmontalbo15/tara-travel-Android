import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';

/// TripAnnouncementsCard
/// ─────────────────────────────────────────────────────────────────────────────
/// Command-center announcement widget mounted on TripDetailScreen (Plan 20):
/// • Subscribes to real-time pinned announcements via `tripAnnouncementsProvider`.
/// • Distinguishes "Urgent Alert" (Coral `#D85A30`) vs "Trip Notice" (Sunset `#EF9F27`).
/// • Multi-item pagination carousel (`1 of N`) if multiple announcements are pinned.
/// • 1-tap "Open in Chat →" navigation that jumps directly to the conversation.
/// • Organizer quick-post button to broadcast directly from the dashboard.
/// • Collapse toggle for travelers who already acknowledged the note.
/// ─────────────────────────────────────────────────────────────────────────────
class TripAnnouncementsCard extends ConsumerStatefulWidget {
  final TripModel trip;

  const TripAnnouncementsCard({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<TripAnnouncementsCard> createState() => _TripAnnouncementsCardState();
}

class _TripAnnouncementsCardState extends ConsumerState<TripAnnouncementsCard> {
  int _currentIndex = 0;
  bool _isCollapsed = false;

  void _openAnnouncementCompose(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String priority = 'urgent';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: priority == 'urgent' ? const Color(0xFFFDE8E1) : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: priority == 'urgent' ? AppColors.primary : const Color(0xFFD97706),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Post Trip Announcement',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Priority selector
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = 'urgent'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: priority == 'urgent' ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: priority == 'urgent' ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🚨 Urgent Alert',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: priority == 'urgent' ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => priority = 'notice'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: priority == 'notice' ? const Color(0xFFEF9F27) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: priority == 'notice' ? const Color(0xFFEF9F27) : AppColors.cardBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '📌 Trip Notice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: priority == 'notice' ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Headline (e.g., Meet at SLEX Petron by 5:30 AM)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Detailed instructions for the group...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = messageController.text.trim();
                    if (title.isEmpty && body.isEmpty) return;

                    Navigator.pop(ctx);
                    final profile = ref.read(profileProvider);
                    final senderName = profile.effectiveName.isNotEmpty
                        ? MemberModel.formatDisplayName(profile.effectiveName,
                            hideSurname: profile.hideSurname)
                        : 'Organizer';

                    await ref.read(chatProvider.notifier).sendAnnouncement(
                          title: title.isNotEmpty ? title : 'Trip Announcement',
                          message: body,
                          senderName: senderName,
                          priority: priority,
                        );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: priority == 'urgent' ? AppColors.primary : const Color(0xFFEF9F27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Broadcast Announcement 📢', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(tripAnnouncementsProvider(widget.trip.id));
    final announcements = announcementsAsync.value ?? [];

    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOrganizer = widget.trip.ownerId == currentUserId ||
        widget.trip.members.any((m) => m.id == currentUserId && m.isOrganizer);

    if (announcements.isEmpty) {
      if (!isOrganizer) return const SizedBox.shrink();

      // Show organizer invitation tile to post the first announcement
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEBE8E3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Announcements',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.deepEarth),
                  ),
                  Text(
                    'Pin urgent notices and meeting guidelines for the squad.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _openAnnouncementCompose(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    final safeIndex = _currentIndex.clamp(0, announcements.length - 1);
    final active = announcements[safeIndex];

    final isUrgent = active.metadata?['priority'] == 'urgent' ||
        active.text.contains('🚨') ||
        active.metadata?['priority'] == null;

    final cardBg = isUrgent ? const Color(0xFFFFF5F2) : const Color(0xFFFFFBF0);
    final borderColor = isUrgent ? const Color(0xFFFFD4C4) : const Color(0xFFFFE8B3);
    final accentColor = isUrgent ? AppColors.primary : const Color(0xFFEF9F27);
    final badgeLabel = isUrgent ? 'URGENT ALERT' : 'TRIP NOTICE';

    final title = active.metadata?['title']?.toString() ?? 'Important Announcement';
    final body = active.metadata?['body']?.toString() ?? active.text;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'by ${active.senderName}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepEarth.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
                if (announcements.length > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                  ),
                  Text(
                    '${safeIndex + 1}/${announcements.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: _currentIndex < announcements.length - 1
                        ? () => setState(() => _currentIndex++)
                        : null,
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                ),
              ],
            ),
          ),

          // Collapsible Content
          if (!_isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.deepEarth,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/chat'),
                        icon: const Icon(Icons.forum_outlined, size: 14),
                        label: const Text('Open in Chat →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: accentColor,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const Spacer(),
                      if (isOrganizer)
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.muted),
                          tooltip: 'Post new announcement',
                          onPressed: () => _openAnnouncementCompose(context),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
