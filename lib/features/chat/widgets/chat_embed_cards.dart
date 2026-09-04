import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';

// ── 1. ITINERARY STOP EMBED CARD ──────────────────────────────────────────────

class ItineraryStopEmbed extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isMe;

  const ItineraryStopEmbed({
    super.key,
    required this.metadata,
    this.isMe = false,
  });

  Future<void> _openGoogleMaps(String location) async {
    final query = Uri.encodeComponent(location);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = metadata['title']?.toString() ?? 'Itinerary Stop';
    final location = metadata['location']?.toString() ?? '';
    final typeName = metadata['type']?.toString() ?? 'Activity';
    final dayNumber = metadata['day_number']?.toString() ?? '1';
    final notes = metadata['notes']?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFAF3F0) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DAY $dayNumber · $typeName'.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkAccent,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.place_rounded, color: AppColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.deepEarth,
            ),
          ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.near_me_outlined, size: 12, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.warmMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: location.isNotEmpty ? () => _openGoogleMaps(location) : null,
              icon: const Icon(Icons.directions_rounded, size: 14),
              label: const Text('Open in Google Maps',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. EXPENSE REQUEST EMBED CARD ─────────────────────────────────────────────

class ExpenseRequestEmbed extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isMe;

  const ExpenseRequestEmbed({
    super.key,
    required this.metadata,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final desc = metadata['description']?.toString() ?? 'Trip Expense';
    final amount = (metadata['amount'] as num?)?.toDouble() ?? 0.0;
    final payer = metadata['payer_name']?.toString() ?? 'Traveler';
    final category = metadata['category']?.toString() ?? 'General';
    final formattedAmount = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(amount);

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF9F7F5) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 11, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Paid by $payer',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formattedAmount,
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pushNamed(context, '/budget');
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
              label: const Text('View in Budget Tab',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepEarth,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. PACKING ALERT EMBED CARD ───────────────────────────────────────────────

class PackingAlertEmbed extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isMe;
  final VoidCallback? onClaim;

  const PackingAlertEmbed({
    super.key,
    required this.metadata,
    this.isMe = false,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final itemName = metadata['item_name']?.toString() ?? 'Packing Item';
    final category = metadata['category']?.toString() ?? 'General';
    final isClaimed = metadata['is_claimed'] as bool? ?? false;
    final claimedBy = metadata['claimed_by']?.toString();

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFBF8F6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.backpack_outlined, size: 11, color: AppColors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'PACKING NEEDED · $category'.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.priority_high_rounded, color: AppColors.primary, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemName,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isClaimed
                ? '✅ Claimed by ${claimedBy ?? 'a traveler'}'
                : 'Nobody has claimed to bring this item yet.',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: isClaimed ? AppColors.green : AppColors.warmMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: isClaimed ? null : onClaim,
              icon: Icon(isClaimed ? Icons.check_circle_rounded : Icons.pan_tool_rounded, size: 14),
              label: Text(
                isClaimed ? 'Already Claimed' : "I'll bring this! 🙋‍♂️",
                style: const TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClaimed ? AppColors.greenBg : AppColors.primary,
                foregroundColor: isClaimed ? AppColors.green : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. LOCATION DROP EMBED CARD ───────────────────────────────────────────────

class LocationDropEmbed extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isMe;

  const LocationDropEmbed({
    super.key,
    required this.metadata,
    this.isMe = false,
  });

  Future<void> _openCoordinates(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = (metadata['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (metadata['lng'] as num?)?.toDouble() ?? 0.0;
    final label = metadata['label']?.toString() ?? 'Meeting Location Pin';

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF9F6F2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded, size: 11, color: AppColors.green),
                    SizedBox(width: 4),
                    Text(
                      'GPS LOCATION DROP',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.share_location_rounded, color: AppColors.green, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coordinates: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              onPressed: () => _openCoordinates(lat, lng),
              icon: const Icon(Icons.explore_rounded, size: 14),
              label: const Text('Navigate to Pin',
                  style: TextStyle(fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. MEDIA ATTACHMENT EMBED CARD ────────────────────────────────────────────

class MediaAttachmentEmbed extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isMe;

  const MediaAttachmentEmbed({
    super.key,
    required this.metadata,
    this.isMe = false,
  });

  void _showImageModal(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.white70),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = metadata['photo_url']?.toString() ?? '';
    final caption = metadata['caption']?.toString() ?? '';

    if (photoUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showImageModal(context, photoUrl),
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.sand,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.sand,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.warmMuted),
                ),
              ),
            ),
            if (caption.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xB3000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 6. TARA BOT BRIEFING EMBED CARD ───────────────────────────────────────────

class TaraBotBriefingEmbed extends StatelessWidget {
  final String text;
  final Map<String, dynamic>? metadata;

  const TaraBotBriefingEmbed({
    super.key,
    required this.text,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF23140E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x33FFFFFF)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'TARA BOT BRIEFING',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  'Daily Travel Update',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: Color(0xFFFAF4F0),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7. REACTION PILLS ROW WIDGET ──────────────────────────────────────────────

class ReactionPillsRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final ValueChanged<String> onToggleReaction;

  const ReactionPillsRow({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onToggleReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final activeEntries = reactions.entries.where((e) => e.value.isNotEmpty).toList();
    if (activeEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: activeEntries.map((entry) {
          final emoji = entry.key;
          final userIds = entry.value;
          final isMine = userIds.contains(currentUserId);

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleReaction(emoji);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMine ? AppColors.sand : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMine
                      ? AppColors.primaryLight
                      : AppColors.cardBorder,
                  width: isMine ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    '${userIds.length}',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMine ? AppColors.darkAccent : AppColors.deepEarth,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
