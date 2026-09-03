import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/models/trip_poll_model.dart';
import '../../core/models/itinerary_model.dart';
import '../../core/models/expense_model.dart';
import '../../core/models/member_model.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/poll_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/providers/trip_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/repositories/chat_repository.dart';
import '../../core/services/module_view_tracker_service.dart';
import '../../core/widgets/buttons/app_back_button.dart';
import 'widgets/poll_card.dart';
import 'widgets/create_poll_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const ChatScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _showPinnedDrawer = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripId = ref.read(selectedTripIdProvider);
      if (tripId != null) {
        ModuleViewTrackerService.instance.markViewed('chat', tripId);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;

    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Anonymous';

    setState(() => _isSending = true);
    _ctrl.clear();

    await ref.read(chatProvider.notifier).sendMessage(text, senderName);

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _sendQuickTravelMessage(String text) async {
    HapticFeedback.lightImpact();
    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Anonymous';

    await ref
        .read(chatProvider.notifier)
        .sendQuickTravel(text, senderName);
    _scrollToBottom();
  }

  void _openCreatePoll() {
    HapticFeedback.mediumImpact();
    CreatePollSheet.show(
      context,
      onSubmit: ({
        required String question,
        required List<String> options,
        required String category,
        required bool allowMultiple,
      }) async {
        final profile = ref.read(profileProvider);
        final creatorName = profile.effectiveName.isNotEmpty
            ? MemberModel.formatDisplayName(profile.effectiveName,
                hideSurname: profile.hideSurname)
            : 'Organizer';

        await ref.read(pollsProvider.notifier).createPoll(
              question: question,
              optionTexts: options,
              category: category,
              creatorName: creatorName,
              allowMultiple: allowMultiple,
            );
        _scrollToBottom();
      },
    );
  }

  // ── Convert Winning Poll to Itinerary Stop ────────────────────────
  Future<void> _handleWinnerToItinerary(TripPoll poll, PollOption winner) async {
    final trip = await ref.read(activeTripProvider.future);
    if (trip == null) return;

    final itineraryRepo = ref.read(itineraryRepositoryProvider);
    final days = await itineraryRepo.getItinerary(trip.id,
        startDate: trip.fromDate, endDate: trip.toDate);
    final targetDay = days.isNotEmpty
        ? days.first
        : ItineraryDay(
            dayNumber: 1,
            date: trip.fromDate,
            stops: const [],
          );

    StopType stopType = StopType.activity;
    if (poll.category == PollCategory.food) {
      stopType = StopType.food;
    } else if (poll.category == PollCategory.departure) {
      stopType = StopType.transport;
    }

    final newStop = ItineraryStop(
      id: const Uuid().v4(),
      title: winner.text,
      notes: 'Decided by group poll: "${poll.question}"',
      type: stopType,
      location: winner.text,
    );

    final updatedStops = [...targetDay.stops, newStop];
    final updatedDay = targetDay.copyWith(stops: updatedStops);

    await itineraryRepo.saveItineraryDay(trip.id, updatedDay);

    // Send an automated notification message to chat
    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Organizer';

    await ref.read(chatProvider.notifier).sendMessage(
          '📌 Added winning option "${winner.text}" to Day ${targetDay.dayNumber} Itinerary!',
          senderName,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${winner.text}" to Day ${targetDay.dayNumber} Itinerary!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  // ── Convert Winning Poll to Expense Draft ─────────────────────────
  Future<void> _handleWinnerToExpense(TripPoll poll, PollOption winner) async {
    final trip = await ref.read(activeTripProvider.future);
    if (trip == null) return;

    final currentMember = ref.read(currentMemberProvider(trip));
    final expenseRepo = ref.read(expenseRepositoryProvider);

    ExpenseCategory cat = ExpenseCategory.custom;
    if (poll.category == PollCategory.food) {
      cat = ExpenseCategory.food;
    } else if (poll.category == PollCategory.activity) {
      cat = ExpenseCategory.activities;
    }

    final newExpense = ExpenseModel(
      id: const Uuid().v4(),
      description: '${winner.text} (Group Poll)',
      amount: 0.0, // editable in budget tab
      category: cat,
      paidById: currentMember?.id ?? '',
      date: DateTime.now(),
    );

    await expenseRepo.addExpense(trip.id, newExpense);

    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Organizer';

    await ref.read(chatProvider.notifier).sendMessage(
          '💸 Logged expense draft for "${winner.text}". Fill in the final cost in Budget!',
          senderName,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged "${winner.text}" in Trip Expenses!'),
          backgroundColor: AppColors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripId = ref.watch(selectedTripIdProvider);
    final tripAsync = ref.watch(activeTripProvider);
    final chatAsync = ref.watch(chatProvider);
    final pollsAsync = ref.watch(pollsProvider);
    final pinnedMessages = ref.watch(pinnedMessagesProvider);
    final profile = ref.watch(profileProvider);

    // Auto-scroll when new messages arrive
    ref.listen<AsyncValue<List<ChatMessage>>>(chatProvider, (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id ?? '';
    final trip = tripAsync.value;
    final currentMember = trip != null ? ref.watch(currentMemberProvider(trip)) : null;
    final isOrganizer = (currentMember?.canManageMembers ?? false) ||
        (currentMember?.isTripCreator(trip?.ownerId ?? '') ?? false);

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _ChatHeader(
            showHeader: widget.showHeader,
            tripTitle: trip?.name ?? 'Group Chat',
            tripId: tripId,
            memberCount: trip?.members.length ?? 0,
          ),

          // ── Pinned Announcements Drawer ──────────────────────────
          if (pinnedMessages.isNotEmpty && _showPinnedDrawer)
            _PinnedAnnouncementDrawer(
              messages: pinnedMessages,
              onDismiss: () => setState(() => _showPinnedDrawer = false),
              onUnpin: (msgId) =>
                  ref.read(chatProvider.notifier).togglePin(msgId, false),
            ),

          // ── Message & Poll Stream ────────────────────────────────
          Expanded(
            child: Container(
              color: AppColors.surfaceLight,
              child: chatAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: AppColors.warmMuted, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load messages.\nSign in to access group chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: AppColors.warmMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (messages) {
                  final polls = pollsAsync.value ?? [];

                  if (messages.isEmpty && polls.isEmpty) {
                    return _EmptyChat(
                      tripId: tripId,
                      onCreatePoll: _openCreatePoll,
                    );
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final showDate = i == 0 ||
                          !_isSameDay(messages[i - 1].createdAt, msg.createdAt);

                      // If message has an associated poll, render PollCard
                      if (msg.pollId != null) {
                        final poll = polls.where((p) => p.id == msg.pollId).firstOrNull;
                        if (poll != null) {
                          return Column(
                            children: [
                              if (showDate) _dateDivider(msg.createdAt),
                              PollCard(
                                poll: poll,
                                currentUserId: currentUserId,
                                isOrganizer: isOrganizer,
                                onVote: (optionId) {
                                  final voterName = profile.effectiveName.isNotEmpty
                                      ? MemberModel.formatDisplayName(
                                          profile.effectiveName,
                                          hideSurname: profile.hideSurname)
                                      : 'Anonymous';

                                  ref.read(pollsProvider.notifier).toggleVote(
                                        poll: poll,
                                        optionId: optionId,
                                        currentUserId: currentUserId,
                                        voterName: voterName,
                                      );
                                },
                                onClose: () => ref
                                    .read(pollsProvider.notifier)
                                    .closePoll(poll.id),
                                onAddToItinerary: () {
                                  final winner = poll.winnerOption;
                                  if (winner != null) {
                                    _handleWinnerToItinerary(poll, winner);
                                  }
                                },
                                onAddToExpenses: () {
                                  final winner = poll.winnerOption;
                                  if (winner != null) {
                                    _handleWinnerToExpense(poll, winner);
                                  }
                                },
                              ),
                            ],
                          );
                        }
                      }

                      return Column(
                        children: [
                          if (showDate) _dateDivider(msg.createdAt),
                          msg.isMe
                              ? _MyBubble(
                                  msg: msg,
                                  onDelete: () => ref
                                      .read(chatProvider.notifier)
                                      .deleteMessage(msg.id),
                                  onTogglePin: () => ref
                                      .read(chatProvider.notifier)
                                      .togglePin(msg.id, !msg.isPinned),
                                )
                              : _TheirBubble(
                                  msg: msg,
                                  onTogglePin: isOrganizer
                                      ? () => ref
                                          .read(chatProvider.notifier)
                                          .togglePin(msg.id, !msg.isPinned)
                                      : null,
                                ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ── Quick Travel Action Chips ────────────────────────────
          _QuickActionChips(
            onCreatePoll: _openCreatePoll,
            onQuickMessage: _sendQuickTravelMessage,
          ),

          // ── Input Bar ────────────────────────────────────────────
          _InputBar(
            controller: _ctrl,
            isSending: _isSending,
            isOffline: tripId == null,
            onSend: _sendMessage,
            onCreatePoll: _openCreatePoll,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateDivider(DateTime dt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.dividerLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isToday(dt) ? 'Today' : DateFormat('MMM d').format(dt),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.dividerLight)),
          ],
        ),
      );

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

// ── Chat Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final bool showHeader;
  final String tripTitle;
  final String? tripId;
  final int memberCount;

  const _ChatHeader({
    required this.showHeader,
    required this.tripTitle,
    required this.tripId,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, showHeader ? 54 : 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A04), AppColors.deepEarth],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            const AppBackButton(variant: AppBackButtonVariant.glass),
            const SizedBox(width: 12),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_rounded, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripTitle,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tripId != null
                      ? 'Live Chat & Polls  ·  $memberCount members'
                      : 'Select a trip to start chatting',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          if (tripId != null)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.greenBright,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x6610B981),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Pinned Announcement Drawer ─────────────────────────────────────────────────

class _PinnedAnnouncementDrawer extends StatelessWidget {
  final List<ChatMessage> messages;
  final VoidCallback onDismiss;
  final ValueChanged<String> onUnpin;

  const _PinnedAnnouncementDrawer({
    required this.messages,
    required this.onDismiss,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final pinned = messages.first; // show most recent pinned

    return Container(
      width: double.infinity,
      color: AppColors.deepEarth,
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PINNED ANNOUNCEMENT · ${pinned.senderName}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    pinned.text,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepEarth,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.deepEarth),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Chips ─────────────────────────────────────────────────────────

class _QuickActionChips extends StatelessWidget {
  final VoidCallback onCreatePoll;
  final ValueChanged<String> onQuickMessage;

  const _QuickActionChips({
    required this.onCreatePoll,
    required this.onQuickMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Create Poll CTA Chip
            GestureDetector(
              onTap: onCreatePoll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFE6683E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33D85A30),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.how_to_vote_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Create Poll',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Quick travel presets
            _QuickChip(
              text: '⏰ Running 10 mins late!',
              onTap: () => onQuickMessage('⏰ Running 10 mins late! Meet you at the lobby.'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              text: '📍 Arrived at meeting spot',
              onTap: () => onQuickMessage('📍 Arrived at the meeting spot! Where are you guys?'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              text: '🍽️ Where are we eating?',
              onTap: () => onQuickMessage('🍽️ Anyone hungry? Where are we eating next?'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.deepEarth,
          ),
        ),
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isOffline;
  final VoidCallback onSend;
  final VoidCallback onCreatePoll;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isOffline,
    required this.onSend,
    required this.onCreatePoll,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 6, 12, 8 + math.max(bottomInset, bottomPadding)),
      child: Row(
        children: [
          // Attachment / Poll icon button
          GestureDetector(
            onTap: isOffline ? null : onCreatePoll,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.sand,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: controller,
                enabled: !isOffline,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: AppColors.deepEarth,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: isOffline
                      ? 'Select a trip to chat...'
                      : 'Send message to group...',
                  hintStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: (isOffline || isSending) ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isOffline || isSending)
                    ? AppColors.warmMuted
                    : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33D85A30),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Message Bubble (Brand Coral Gradient) ───────────────────────────────────

class _MyBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _MyBubble({
    required this.msg,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: GestureDetector(
        onLongPress: () => _showActionsSheet(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0xFFE6683E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22D85A30),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (msg.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded,
                                  size: 12, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        msg.text,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (msg.isPending)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.access_time_rounded,
                            size: 10, color: AppColors.muted),
                      ),
                    Text(
                      _formatTime(msg.createdAt),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                msg.isPinned ? 'Unpin message' : 'Pin message as announcement',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onTogglePin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444)),
              title: const Text(
                'Delete message',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Their Message Bubble ───────────────────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback? onTogglePin;

  const _TheirBubble({required this.msg, this.onTogglePin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 48),
      child: GestureDetector(
        onLongPress: onTogglePin != null
            ? () => _showActionsSheet(context)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar with initials
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.deepEarth,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  msg.initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.isPinned)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            color: AppColors.deepEarth,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(msg.createdAt),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: ListTile(
          leading: Icon(
            msg.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            color: AppColors.primary,
          ),
          title: Text(
            msg.isPinned ? 'Unpin message' : 'Pin message as announcement',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onTogglePin?.call();
          },
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String? tripId;
  final VoidCallback onCreatePoll;

  const _EmptyChat({required this.tripId, required this.onCreatePoll});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              tripId != null
                  ? 'No messages yet!'
                  : 'Select a trip to see group chat',
              style: const TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tripId != null
                  ? 'Say hello to your travel group or create a poll to decide your next destination.'
                  : 'Join or select an active trip from the Home screen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.warmMuted,
              ),
            ),
            if (tripId != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onCreatePoll,
                icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                label: const Text('Create First Travel Poll'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $p';
}
