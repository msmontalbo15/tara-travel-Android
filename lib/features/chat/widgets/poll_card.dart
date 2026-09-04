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
  final ValueChanged<String>? onAddOption;

  const PollCard({
    super.key,
    required this.poll,
    required this.currentUserId,
    this.isOrganizer = false,
    required this.onVote,
    this.onClose,
    this.onAddToItinerary,
    this.onAddToExpenses,
    this.onAddOption,
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
            _WinnerCard(
              poll: poll,
              winner: winner,
              onAddToItinerary: onAddToItinerary,
              onAddToExpenses: onAddToExpenses,
            ),

          // ── Crowdsourced "+ Suggest an Option" button ──────────────
          if (!poll.isClosed && onAddOption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: InkWell(
                onTap: () => _showAddOptionDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sand.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Suggest an Option / Spot',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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

  void _showAddOptionDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Suggest Option / Spot',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. Rico\'s Lechon, 8:00 AM, Snorkeling',
            hintStyle: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.muted.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'DM Sans', color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                onAddOption?.call(text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Add Option',
              style: TextStyle(fontFamily: 'DM Sans', fontWeight: FontWeight.bold),
            ),
          ),
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

// ── Winner Card (Clickable to Detail) ─────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  final TripPoll poll;
  final PollOption winner;
  final VoidCallback? onAddToItinerary;
  final VoidCallback? onAddToExpenses;

  const _WinnerCard({
    required this.poll,
    required this.winner,
    this.onAddToItinerary,
    this.onAddToExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final pct = winner.percentage(poll.totalVotes);
    final pctStr = pct > 0 ? '${pct.toStringAsFixed(0)}%' : '—';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showWinnerDetail(context);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D6E0F), // deep green
              Color(0xFF3B8B17), // mid green
              Color(0xFF4CA624), // bright green
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x303B6D11),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle decorative circle in top-right
            Positioned(
              top: -18,
              right: -18,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -12,
              left: -12,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Trophy badge + percentage
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🏆',
                                style: TextStyle(fontSize: 14)),
                            SizedBox(width: 4),
                            Text(
                              'Winner',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        pctStr,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Winner text
                  Text(
                    winner.text,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Vote count + category
                  Row(
                    children: [
                      Icon(Icons.how_to_vote_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${winner.voteCount} ${winner.voteCount == 1 ? 'vote' : 'votes'}',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${poll.category.emoji} ${poll.category.label}',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Voter avatars row
                  if (winner.voterNames.isNotEmpty) ...[
                    _VoterChips(names: winner.voterNames),
                    const SizedBox(height: 12),
                  ],
                  // "Tap for details" hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Tap for results & actions',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWinnerDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WinnerDetailSheet(
        poll: poll,
        winner: winner,
        onAddToItinerary: onAddToItinerary,
        onAddToExpenses: onAddToExpenses,
      ),
    );
  }
}

// ── Voter Chips Row ───────────────────────────────────────────────────────────

class _VoterChips extends StatelessWidget {
  final List<String> names;
  const _VoterChips({required this.names});

  @override
  Widget build(BuildContext context) {
    final displayNames = names.take(4).toList();
    final remaining = names.length - displayNames.length;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...displayNames.map((name) => Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            )),
        if (remaining > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remaining more',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Winner Detail Bottom Sheet ────────────────────────────────────────────────

class _WinnerDetailSheet extends StatelessWidget {
  final TripPoll poll;
  final PollOption winner;
  final VoidCallback? onAddToItinerary;
  final VoidCallback? onAddToExpenses;

  const _WinnerDetailSheet({
    required this.poll,
    required this.winner,
    this.onAddToItinerary,
    this.onAddToExpenses,
  });

  @override
  Widget build(BuildContext context) {
    // Sort options by vote count descending for ranked display
    final rankedOptions = [...poll.options]
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // ── Header ──────────────────────────────────
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3B8B17),
                            Color(0xFF4CA624),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x303B6D11),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child:
                            Text('🏆', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      winner.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepEarth,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Decided by group poll  ·  ${poll.totalVotes} total votes',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        color: AppColors.warmMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Original Question ───────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.sand.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              AppColors.primaryLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(poll.category.emoji,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poll.question,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepEarth,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${poll.creatorName}  ·  ${poll.category.label}',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  color: AppColors.warmMuted
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Results Breakdown ───────────────────────
                  const Text(
                    'Results Breakdown',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...rankedOptions.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final opt = entry.value;
                    final isWinner = opt.id == winner.id;
                    final pct = opt.percentage(poll.totalVotes);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? AppColors.greenBg
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isWinner
                              ? AppColors.green
                              : AppColors.cardBorder,
                          width: isWinner ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Rank circle
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isWinner
                                      ? AppColors.green
                                      : AppColors.muted
                                          .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isWinner
                                          ? Colors.white
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  opt.text,
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: isWinner
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppColors.deepEarth,
                                  ),
                                ),
                              ),
                              if (isWinner)
                                const Text('🏆',
                                    style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isWinner
                                      ? AppColors.green
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: pct / 100),
                              duration:
                                  const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              builder: (_, value, __) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 5,
                                backgroundColor:
                                    AppColors.dividerLight,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  isWinner
                                      ? AppColors.green
                                      : AppColors.muted
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                          // Voter names
                          if (opt.voterNames.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              opt.voterNames.length <= 3
                                  ? opt.voterNames.join(', ')
                                  : '${opt.voterNames.take(3).join(', ')} +${opt.voterNames.length - 3} more',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                color: AppColors.warmMuted
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // ── Resolution Actions ──────────────────────
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepEarth,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (poll.category != PollCategory.budget)
                        Expanded(
                          child: _DetailActionButton(
                            icon: Icons.add_location_alt_rounded,
                            label: 'Add to Itinerary',
                            color: AppColors.primary,
                            onTap: onAddToItinerary != null
                                ? () {
                                    Navigator.pop(context);
                                    onAddToItinerary!();
                                  }
                                : null,
                          ),
                        ),
                      if (poll.category != PollCategory.budget &&
                          (poll.category == PollCategory.budget ||
                              poll.category == PollCategory.food))
                        const SizedBox(width: 10),
                      if (poll.category == PollCategory.budget ||
                          poll.category == PollCategory.food)
                        Expanded(
                          child: _DetailActionButton(
                            icon: Icons.receipt_long_rounded,
                            label: 'Add to Expenses',
                            color: AppColors.amber,
                            onTap: onAddToExpenses != null
                                ? () {
                                    Navigator.pop(context);
                                    onAddToExpenses!();
                                  }
                                : null,
                          ),
                        ),
                    ],
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

// ── Detail Action Button ──────────────────────────────────────────────────────

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final effectiveColor = isDisabled ? const Color(0xFFE8E8E8) : color;
    final effectiveTextColor = isDisabled ? const Color(0xFF888888) : Colors.white;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap?.call();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isDisabled ? Icons.check_circle_rounded : icon,
                color: effectiveTextColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isDisabled
                    ? '${label.replaceAll('Add to ', 'Added to ')} ✓'
                    : label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: effectiveTextColor,
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
