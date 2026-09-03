import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/trip_poll_model.dart';

/// Interactive in-chat poll card with animated vote progress bars,
/// voter avatar stacks, winner banner, and action resolution buttons.
///
/// Design Tokens:
///   - Category pill: Sand (#FAECE7) bg, Dark Coral (#993C1D) text
///   - Vote progress: Coral (#D85A30) / Amber (#EF9F27) fill
///   - Winner banner: Green accent
///   - Card: White with 16px radius and subtle shadow
class PollCard extends StatelessWidget {
  final TripPoll poll;
  final String currentUserId;
  final bool isOrganizer;
  final ValueChanged<String> onVote;
  final VoidCallback? onClose;
  final VoidCallback? onAddToItinerary;
  final VoidCallback? onAddToExpenses;

  const PollCard({
    super.key,
    required this.poll,
    required this.currentUserId,
    this.isOrganizer = false,
    required this.onVote,
    this.onClose,
    this.onAddToItinerary,
    this.onAddToExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;
    final winner = poll.winnerOption;
    final userVotedIds = poll.userVotedOptionIds(currentUserId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ambientShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Category pill + question ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _CategoryPill(category: poll.category),
                const SizedBox(width: 8),
                if (poll.allowMultiple)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Multi-select',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                const Spacer(),
                if (poll.isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.greenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ Closed',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Question text ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              poll.question,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
          ),

          // ── Creator + vote count ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'by ${poll.creatorName}  ·  $totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.warmMuted.withValues(alpha: 0.8),
              ),
            ),
          ),

          // ── Option vote bars ───────────────────────────────────────
          ...poll.options.map((opt) => _OptionBar(
                option: opt,
                totalVotes: totalVotes,
                isVotedByMe: userVotedIds.contains(opt.id),
                isClosed: poll.isClosed,
                isWinner: poll.isClosed && winner?.id == opt.id,
                onTap: poll.isClosed
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onVote(opt.id);
                      },
              )),

          // ── Winner resolution actions ───────────────────────────────
          if (poll.isClosed && winner != null && (isOrganizer || poll.isCreator(currentUserId)))
            _WinnerActions(
              winnerText: winner.text,
              category: poll.category,
              onAddToItinerary: onAddToItinerary,
              onAddToExpenses: onAddToExpenses,
            ),

          // ── Close poll button (organizer / creator only) ───────────
          if (!poll.isClosed && (isOrganizer || poll.isCreator(currentUserId)))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _confirmClosePoll(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  child: const Text(
                    'Close Poll & Decide Winner',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _confirmClosePoll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Finalize & Close Poll?',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Closing this poll will end voting for all travelers and finalize the winning option.',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.deepEarth,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Open',
                style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onClose?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Finalize Winner',
              style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Pill ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final PollCategory category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${category.emoji} ${category.label}',
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.darkAccent,
        ),
      ),
    );
  }
}

// ── Option Vote Bar ───────────────────────────────────────────────────────────

class _OptionBar extends StatelessWidget {
  final PollOption option;
  final int totalVotes;
  final bool isVotedByMe;
  final bool isClosed;
  final bool isWinner;
  final VoidCallback? onTap;

  const _OptionBar({
    required this.option,
    required this.totalVotes,
    required this.isVotedByMe,
    required this.isClosed,
    required this.isWinner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = option.percentage(totalVotes);
    final pctStr = pct > 0 ? '${pct.toStringAsFixed(0)}%' : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isWinner
              ? AppColors.greenBg
              : isVotedByMe
                  ? AppColors.sand
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWinner
                ? AppColors.green
                : isVotedByMe
                    ? AppColors.primary
                    : AppColors.cardBorder,
            width: isVotedByMe || isWinner ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Check/radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isVotedByMe ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isVotedByMe ? AppColors.primary : AppColors.muted,
                      width: 2,
                    ),
                  ),
                  child: isVotedByMe
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                // Option text
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight:
                          isWinner ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.deepEarth,
                    ),
                  ),
                ),
                // Winner badge
                if (isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🏆 Winner',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Vote percentage
                if (pctStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    pctStr,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isWinner ? AppColors.green : AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            // Progress bar
            if (totalVotes > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct / 100),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: AppColors.dividerLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWinner
                          ? AppColors.green
                          : isVotedByMe
                              ? AppColors.primary
                              : AppColors.amber,
                    ),
                  ),
                ),
              ),
            ],
            // Voter names (max 3 shown)
            if (option.voterNames.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _formatVoterNames(option.voterNames),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  color: AppColors.warmMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatVoterNames(List<String> names) {
    if (names.length <= 3) return names.join(', ');
    return '${names.take(3).join(', ')} +${names.length - 3} more';
  }
}

// ── Winner Resolution Actions ─────────────────────────────────────────────────

class _WinnerActions extends StatelessWidget {
  final String winnerText;
  final PollCategory category;
  final VoidCallback? onAddToItinerary;
  final VoidCallback? onAddToExpenses;

  const _WinnerActions({
    required this.winnerText,
    required this.category,
    this.onAddToItinerary,
    this.onAddToExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Resolve "$winnerText"',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.deepEarth,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Add to Itinerary
              if (category != PollCategory.budget)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_location_alt_rounded,
                    label: 'Add to Itinerary',
                    color: AppColors.primary,
                    onTap: onAddToItinerary,
                  ),
                ),
              if (category != PollCategory.budget)
                const SizedBox(width: 8),
              // Add to Expenses
              if (category == PollCategory.budget || category == PollCategory.food)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: 'Add to Expenses',
                    color: AppColors.amber,
                    onTap: onAddToExpenses,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
