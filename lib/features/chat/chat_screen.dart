import 'package:tara_travel/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_responsive.dart';
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
import 'widgets/chat_embed_cards.dart';
import 'widgets/chat_attachment_picker_sheet.dart';

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
  bool _showScrollToBottom = false;
  bool _isComposing = false;

  // Track resolved polls to prevent duplicate additions
  final Set<String> _resolvedItineraryPollIds = {};
  final Set<String> _resolvedExpensePollIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripId = ref.read(selectedTripIdProvider);
      if (tripId != null) {
        ModuleViewTrackerService.instance.markViewed('chat', tripId);
      }
    });

    _scrollCtrl.addListener(_onScrollChanged);
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScrollChanged);
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentOffset = _scrollCtrl.offset;
    final distanceFromBottom = maxScroll - currentOffset;
    final shouldShow = distanceFromBottom > 240;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.trim().isNotEmpty;
    if (hasText != _isComposing) {
      setState(() => _isComposing = hasText);
    }
  }

  void _scrollToBottom({bool force = false}) {
    // Only auto-scroll if the user is already near the bottom or force is true
    if (!force && _showScrollToBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
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

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);
    _ctrl.clear();

    await ref.read(chatProvider.notifier).sendMessage(text, senderName);

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom(force: true);
  }

  Future<void> _sendQuickTravelMessage(String text) async {
    HapticFeedback.mediumImpact();
    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Anonymous';

    await ref
        .read(chatProvider.notifier)
        .sendQuickTravel(text, senderName);
    _scrollToBottom(force: true);
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
        _scrollToBottom(force: true);
      },
    );
  }

  void _openAttachmentMenu() {
    HapticFeedback.lightImpact();
    final trip = ref.read(activeTripProvider).value;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an active trip to share attachments.')),
      );
      return;
    }

    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Traveler';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChatAttachmentPickerSheet(
        trip: trip,
        onCreatePoll: _openCreatePoll,
        onQuickPreset: _sendQuickTravelMessage,
        onShareItineraryStop: (stop, dayNumber) async {
          await ref.read(chatProvider.notifier).sendRichCard(
                type: ChatMessageType.itinerarySnippet,
                text: '📍 Shared stop: ${stop.title}',
                senderName: senderName,
                metadata: {
                  'stop_id': stop.id,
                  'title': stop.title,
                  'location': stop.location,
                  'type': stop.type.label,
                  'day_number': dayNumber,
                  'notes': stop.notes,
                },
              );
          _scrollToBottom(force: true);
        },
        onShareExpense: (expense) async {
          await ref.read(chatProvider.notifier).sendRichCard(
                type: ChatMessageType.expenseRequest,
                text: '💸 Expense: ${expense.description}',
                senderName: senderName,
                metadata: {
                  'expense_id': expense.id,
                  'description': expense.description,
                  'amount': expense.amount,
                  'category': expense.category.name,
                  'payer_name': senderName,
                },
              );
          _scrollToBottom(force: true);
        },
        onSharePackingItem: (item) async {
          await ref.read(chatProvider.notifier).sendRichCard(
                type: ChatMessageType.packingAlert,
                text: '🎒 Packing needed: ${item.name}',
                senderName: senderName,
                metadata: {
                  'item_id': item.id,
                  'item_name': item.name,
                  'category': item.subCategory ?? 'General',
                  'is_claimed': item.isAssigned,
                  'claimed_by': item.assignedMemberName,
                },
              );
          _scrollToBottom(force: true);
        },
        onDropLocation: (lat, lng, label) async {
          await ref.read(chatProvider.notifier).sendRichCard(
                type: ChatMessageType.locationDrop,
                text: '📍 Meeting Location: $label',
                senderName: senderName,
                metadata: {
                  'lat': lat,
                  'lng': lng,
                  'label': label,
                },
              );
          _scrollToBottom(force: true);
        },
        onSharePhoto: (localPath) async {
          await ref.read(chatProvider.notifier).sendMediaMessage(
                localPath: localPath,
                senderName: senderName,
              );
          _scrollToBottom(force: true);
        },
        onSendMorningBriefing: (briefingText) async {
          await ref.read(chatProvider.notifier).sendRichCard(
                type: ChatMessageType.taraBot,
                text: briefingText,
                senderName: '🤖 Tara Bot',
                metadata: {'briefing': true},
              );
          _scrollToBottom(force: true);
        },
      ),
    );
  }

  Future<void> _handleClaimPackingItem(ChatMessage msg) async {
    final trip = ref.read(activeTripProvider).value;
    if (trip == null || msg.metadata == null) return;

    final itemId = msg.metadata!['item_id']?.toString() ?? '';
    final itemName = msg.metadata!['item_name']?.toString() ?? 'item';
    final profile = ref.read(profileProvider);
    final myName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'A traveler';
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.id ?? '';

    if (itemId.isEmpty || currentUserId.isEmpty) return;

    HapticFeedback.mediumImpact();

    try {
      final packingRepo = ref.read(packingRepositoryProvider);
      await packingRepo.assignItem(
        itemId: itemId,
        memberId: currentUserId,
        memberName: myName,
      );

      await ref.read(chatProvider.notifier).sendMessage(
            '🙋‍♂️ $myName claimed to bring "$itemName"!',
            myName,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You claimed to bring "$itemName"!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error claiming packing item: $e');
    }
  }

  void _showTripInfoModal(String tripTitle, int memberCount, dynamic trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TripInfoSheet(
        tripTitle: tripTitle,
        memberCount: memberCount,
        trip: trip,
      ),
    );
  }

  void _showPinnedMessagesModal(List<ChatMessage> pinnedMessages, bool isOrganizer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PinnedMessagesSheet(
        messages: pinnedMessages,
        isOrganizer: isOrganizer,
        onUnpin: (id) {
          ref.read(chatProvider.notifier).togglePin(id, false);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showMessageActionsModal(ChatMessage msg, bool isOrganizer, String currentUserId) {
    HapticFeedback.mediumImpact();
    final isMe = msg.isMe || msg.userId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MessageActionSheet(
        message: msg,
        isMe: isMe,
        canPin: isOrganizer || isMe,
        onSelectReaction: (emoji) {
          ref.read(chatProvider.notifier).toggleReaction(
                messageId: msg.id,
                emoji: emoji,
                userId: currentUserId,
              );
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: msg.text));
          HapticFeedback.selectionClick();
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Message copied to clipboard'),
                ],
              ),
              backgroundColor: AppColors.deepEarth,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onTogglePin: () {
          Navigator.pop(ctx);
          ref.read(chatProvider.notifier).togglePin(msg.id, !msg.isPinned);
        },
        onDelete: isMe
            ? () {
                Navigator.pop(ctx);
                _confirmDeleteMessage(msg.id);
              }
            : null,
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Message?',
            style: TextStyle(fontFamily: AppTextStyles.fontHeading, fontWeight: FontWeight.bold)),
        content: const Text('This will delete this message for everyone in the group chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider.notifier).deleteMessage(messageId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Convert Winning Poll to Itinerary Stop ────────────────────────
  Future<void> _handleWinnerToItinerary(TripPoll poll, PollOption winner) async {
    if (_resolvedItineraryPollIds.contains(poll.id)) return;

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

    setState(() {
      _resolvedItineraryPollIds.add(poll.id);
    });

    // Send an automated rich card to chat for the winning option
    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Organizer';

    await ref.read(chatProvider.notifier).sendRichCard(
          type: ChatMessageType.itinerarySnippet,
          text: '🏆 Added winning option to Day ${targetDay.dayNumber} Itinerary',
          senderName: senderName,
          metadata: {
            'stop_id': newStop.id,
            'title': newStop.title,
            'location': newStop.location,
            'type': newStop.type.label,
            'day_number': targetDay.dayNumber,
            'notes': newStop.notes,
            'is_poll_winner': true,
            'poll_question': poll.question,
            'poll_category': poll.category.name,
            'winner_votes': winner.voteCount,
            'total_votes': poll.totalVotes,
          },
        );
    _scrollToBottom(force: true);

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
    if (_resolvedExpensePollIds.contains(poll.id)) return;

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

    setState(() {
      _resolvedExpensePollIds.add(poll.id);
    });

    final profile = ref.read(profileProvider);
    final senderName = profile.effectiveName.isNotEmpty
        ? MemberModel.formatDisplayName(profile.effectiveName,
            hideSurname: profile.hideSurname)
        : 'Organizer';

    await ref.read(chatProvider.notifier).sendRichCard(
          type: ChatMessageType.expenseRequest,
          text: '🏆 Added winning option to Trip Expenses',
          senderName: senderName,
          metadata: {
            'expense_id': newExpense.id,
            'description': newExpense.description,
            'amount': newExpense.amount,
            'category': newExpense.category.name,
            'payer_name': senderName,
            'is_poll_winner': true,
            'poll_question': poll.question,
            'poll_category': poll.category.name,
            'winner_votes': winner.voteCount,
            'total_votes': poll.totalVotes,
          },
        );
    _scrollToBottom(force: true);

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

    // Auto-scroll when new messages arrive (only if already near bottom)
    ref.listen<AsyncValue<List<ChatMessage>>>(chatProvider, (_, next) {
      if (next.hasValue) _scrollToBottom(force: false);
    });

    final currentUserId = ref.watch(authRepositoryProvider).currentUser?.id ?? '';
    final trip = tripAsync.value;
    final currentMember = trip != null ? ref.watch(currentMemberProvider(trip)) : null;
    final isOrganizer = (currentMember?.canManageMembers ?? false) ||
        (currentMember?.isTripCreator(trip?.ownerId ?? '') ?? false);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _ChatHeader(
            showHeader: widget.showHeader,
            tripTitle: trip?.name ?? 'Group Chat',
            tripId: tripId,
            memberCount: trip?.members.length ?? 0,
            pinnedCount: pinnedMessages.length,
            onTapPinned: () {
              if (pinnedMessages.isNotEmpty) {
                _showPinnedMessagesModal(pinnedMessages, isOrganizer);
              }
            },
            onTapInfo: () {
              _showTripInfoModal(trip?.name ?? 'Trip', trip?.members.length ?? 0, trip);
            },
          ),

          // ── Pinned Announcements Top Banner ──────────────────────
          if (pinnedMessages.isNotEmpty && _showPinnedDrawer)
            _PinnedAnnouncementBanner(
              messages: pinnedMessages,
              onDismiss: () => setState(() => _showPinnedDrawer = false),
              onTapBanner: () => _showPinnedMessagesModal(pinnedMessages, isOrganizer),
              onUnpin: (msgId) =>
                  ref.read(chatProvider.notifier).togglePin(msgId, false),
            ),

          // ── Message & Poll Stream ────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Container(
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
                          onQuickStart: _sendQuickTravelMessage,
                        );
                      }

                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final msg = messages[i];
                          final prevMsg = i > 0 ? messages[i - 1] : null;

                          final showDate = i == 0 ||
                              !_isSameDay(prevMsg!.createdAt, msg.createdAt);

                          // Consecutive check: same sender within 2 minutes on the same day
                          final isConsecutive = prevMsg != null &&
                              !showDate &&
                              (prevMsg.userId == msg.userId || prevMsg.senderName == msg.senderName) &&
                              msg.createdAt.difference(prevMsg.createdAt).inMinutes < 2;

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
                                    onAddOption: (optionText) {
                                      ref.read(pollsProvider.notifier).addOption(
                                            pollId: poll.id,
                                            optionText: optionText,
                                          );
                                    },
                                    onClose: () => ref
                                        .read(pollsProvider.notifier)
                                        .closePoll(poll.id),
                                    onAddToItinerary: _resolvedItineraryPollIds.contains(poll.id)
                                        ? null
                                        : () {
                                            final winner = poll.winnerOption;
                                            if (winner != null) {
                                              _handleWinnerToItinerary(poll, winner);
                                            }
                                          },
                                    onAddToExpenses: _resolvedExpensePollIds.contains(poll.id)
                                        ? null
                                        : () {
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

                          // If message is a Tara Bot briefing, render special full-width embed
                          if (msg.messageType == ChatMessageType.taraBot) {
                            return Column(
                              children: [
                                if (showDate) _dateDivider(msg.createdAt),
                                TaraBotBriefingEmbed(
                                  text: msg.text,
                                  metadata: msg.metadata,
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              if (showDate) _dateDivider(msg.createdAt),
                              msg.isMe
                                  ? _MyBubble(
                                      msg: msg,
                                      isConsecutive: isConsecutive,
                                      currentUserId: currentUserId,
                                      onTapActions: () => _showMessageActionsModal(
                                          msg, isOrganizer, currentUserId),
                                      onToggleReaction: (emoji) =>
                                          ref.read(chatProvider.notifier).toggleReaction(
                                                messageId: msg.id,
                                                emoji: emoji,
                                                userId: currentUserId,
                                              ),
                                      onClaimPackingItem: msg.messageType == ChatMessageType.packingAlert
                                          ? () => _handleClaimPackingItem(msg)
                                          : null,
                                    )
                                  : _TheirBubble(
                                      msg: msg,
                                      isConsecutive: isConsecutive,
                                      currentUserId: currentUserId,
                                      onTapActions: () => _showMessageActionsModal(
                                          msg, isOrganizer, currentUserId),
                                      onToggleReaction: (emoji) =>
                                          ref.read(chatProvider.notifier).toggleReaction(
                                                messageId: msg.id,
                                                emoji: emoji,
                                                userId: currentUserId,
                                              ),
                                      onClaimPackingItem: msg.messageType == ChatMessageType.packingAlert
                                          ? () => _handleClaimPackingItem(msg)
                                          : null,
                                    ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                // ── Floating Scroll-to-Bottom Button ────────────────
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _ScrollToBottomButton(
                      onTap: () => _scrollToBottom(force: true),
                    ),
                  ),
              ],
            ),
          ),

          // ── Quick Travel Action Chips ────────────────────────────
          _QuickActionChips(
            onCreatePoll: _openCreatePoll,
            onQuickMessage: _sendQuickTravelMessage,
          ),

          // ── Input Bar (Calm, Soft & Non-Intimidating Design) ───────
          _InputBar(
            controller: _ctrl,
            isSending: _isSending,
            isComposing: _isComposing,
            isOffline: tripId == null,
            onSend: _sendMessage,
            onOpenAttachment: _openAttachmentMenu,
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Widget _dateDivider(DateTime dt) {
    final text = _isToday(dt)
        ? 'Today'
        : (_isYesterday(dt) ? 'Yesterday' : DateFormat('EEE, MMM d').format(dt));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.darkAccent,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chat Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final bool showHeader;
  final String tripTitle;
  final String? tripId;
  final int memberCount;
  final int pinnedCount;
  final VoidCallback onTapPinned;
  final VoidCallback onTapInfo;

  const _ChatHeader({
    required this.showHeader,
    required this.tripTitle,
    required this.tripId,
    required this.memberCount,
    required this.pinnedCount,
    required this.onTapPinned,
    required this.onTapInfo,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        showHeader ? (topPadding + 10) : 16,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF190903), AppColors.deepEarth],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            const AppBackButton(variant: AppBackButtonVariant.glass),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: onTapInfo,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFE56338)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTapInfo,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tripTitle,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontHeading,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          size: 16, color: Colors.white60),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (tripId != null) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.greenBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          tripId != null
                              ? '$memberCount travelers  ·  Live Chat & Polls'
                              : 'Select a trip to start chatting',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Pinned messages button with badge
          if (pinnedCount > 0)
            GestureDetector(
              onTap: onTapPinned,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.sand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.push_pin_rounded,
                        color: AppColors.primaryLight, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$pinnedCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Info icon button
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: Colors.white70, size: 20),
            onPressed: onTapInfo,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ── Pinned Announcement Top Banner ─────────────────────────────────────────────

class _PinnedAnnouncementBanner extends StatelessWidget {
  final List<ChatMessage> messages;
  final VoidCallback onDismiss;
  final VoidCallback onTapBanner;
  final ValueChanged<String> onUnpin;

  const _PinnedAnnouncementBanner({
    required this.messages,
    required this.onDismiss,
    required this.onTapBanner,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final pinned = messages.first;

    return Container(
      width: double.infinity,
      color: const Color(0xFF22130D),
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
      child: GestureDetector(
        onTap: onTapBanner,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.push_pin_rounded,
                    color: AppColors.primary, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PINNED ANNOUNCEMENT · ${pinned.senderName}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkAccent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (messages.length > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${messages.length - 1} more',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pinned.text,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepEarth,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.deepEarth),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Create Poll CTA Chip (clean, flat, non-intimidating)
            GestureDetector(
              onTap: onCreatePoll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.how_to_vote_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Create Poll',
                      style: TextStyle(
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
              emoji: '⏰',
              text: 'Running 10m late',
              onTap: () => onQuickMessage('⏰ Running 10 mins late! Meet you at the lobby.'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              emoji: '📍',
              text: 'At meeting spot',
              onTap: () => onQuickMessage('📍 Arrived at the meeting spot! Where are you guys?'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              emoji: '🍽️',
              text: 'Where to eat?',
              onTap: () => onQuickMessage('🍽️ Anyone hungry? Where are we eating next?'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              emoji: '💸',
              text: 'Split bills',
              onTap: () => onQuickMessage('💸 Friendly reminder: please upload expenses to the Budget tab!'),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              emoji: '🏄',
              text: 'Ready for next stop',
              onTap: () => onQuickMessage('🏄 All packed and ready for our next excursion!'),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
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
      ),
    );
  }
}

// ── Input Bar (Calm, Soft & Non-Intimidating Design) ───────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isComposing;
  final bool isOffline;
  final VoidCallback onSend;
  final VoidCallback onOpenAttachment;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isComposing,
    required this.isOffline,
    required this.onSend,
    required this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Fix double-padding: Scaffold already handles viewInsets when resizeToAvoidBottomInset is true
    final effectiveBottom = bottomInset > 0 ? 8.0 : (bottomPadding > 0 ? bottomPadding : 8.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 12, effectiveBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment / Quick action button (Flat, soft, non-intimidating)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: isOffline ? null : onOpenAttachment,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Multi-line expandable text field (Clean soft pill, no harsh shadow)
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 40,
                maxHeight: 120,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isComposing
                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: !isOffline,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.deepEarth,
                ),
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: isOffline
                      ? 'Select a trip to chat...'
                      : 'Send message to group...',
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Flat, Friendly Send Button (No intimidating drop shadow or harsh glow)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: GestureDetector(
              onTap: (isOffline || isSending || !isComposing) ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isComposing ? AppColors.primary : AppColors.cardBorder,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: isComposing ? Colors.white : AppColors.muted,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Message Bubble (Brand Coral) ───────────────────────────────────────────

class _MyBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isConsecutive;
  final String currentUserId;
  final VoidCallback onTapActions;
  final ValueChanged<String> onToggleReaction;
  final VoidCallback? onClaimPackingItem;

  const _MyBubble({
    required this.msg,
    required this.isConsecutive,
    required this.currentUserId,
    required this.onTapActions,
    required this.onToggleReaction,
    this.onClaimPackingItem,
  });

  @override
  Widget build(BuildContext context) {
    final isQuickTravel = msg.messageType == ChatMessageType.quickTravel;
    final hasMetadata = msg.metadata != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isConsecutive ? 3 : 8,
        left: 48,
      ),
      child: GestureDetector(
        onLongPress: onTapActions,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    decoration: BoxDecoration(
                      color: isQuickTravel ? const Color(0xFFD35400) : AppColors.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: isConsecutive ? const Radius.circular(6) : const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pinned badge
                        if (msg.isPinned)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded, size: 11, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Quick travel badge
                        if (isQuickTravel)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me_rounded, size: 11, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'TRAVEL ALERT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Message text
                        if (msg.text.isNotEmpty)
                          Text(
                            msg.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),

                        // Rich embeds
                        if (hasMetadata) ...[
                          if (msg.messageType == ChatMessageType.itinerarySnippet)
                            ItineraryStopEmbed(metadata: msg.metadata!, isMe: true),
                          if (msg.messageType == ChatMessageType.expenseRequest)
                            ExpenseRequestEmbed(metadata: msg.metadata!, isMe: true),
                          if (msg.messageType == ChatMessageType.packingAlert)
                            PackingAlertEmbed(
                              metadata: msg.metadata!,
                              isMe: true,
                              onClaim: onClaimPackingItem,
                            ),
                          if (msg.messageType == ChatMessageType.locationDrop)
                            LocationDropEmbed(metadata: msg.metadata!, isMe: true),
                          if (msg.messageType == ChatMessageType.media)
                            MediaAttachmentEmbed(metadata: msg.metadata!, isMe: true),
                        ],

                        const SizedBox(height: 4),

                        // Timestamp and delivery status integrated neatly
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (msg.isPending)
                              const Icon(Icons.schedule_rounded,
                                  size: 11, color: Colors.white70)
                            else
                              const Icon(Icons.done_all_rounded,
                                  size: 12, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Persistent emoji reaction chips
                  ReactionPillsRow(
                    reactions: msg.reactions,
                    currentUserId: currentUserId,
                    onToggleReaction: onToggleReaction,
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

// ── Their Message Bubble ───────────────────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isConsecutive;
  final String currentUserId;
  final VoidCallback onTapActions;
  final ValueChanged<String> onToggleReaction;
  final VoidCallback? onClaimPackingItem;

  const _TheirBubble({
    required this.msg,
    required this.isConsecutive,
    required this.currentUserId,
    required this.onTapActions,
    required this.onToggleReaction,
    this.onClaimPackingItem,
  });

  @override
  Widget build(BuildContext context) {
    final isQuickTravel = msg.messageType == ChatMessageType.quickTravel;
    final hasMetadata = msg.metadata != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isConsecutive ? 3 : 8,
        right: 48,
      ),
      child: GestureDetector(
        onLongPress: onTapActions,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Sender Avatar (hidden if consecutive from same user)
            if (!isConsecutive)
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  color: AppColors.deepEarth,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    msg.initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),

            // Content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name (only if not consecutive)
                  if (!isConsecutive)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkAccent,
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    decoration: BoxDecoration(
                      color: isQuickTravel ? const Color(0xFFFFF8F4) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: isConsecutive ? const Radius.circular(6) : const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: const Radius.circular(4),
                        bottomRight: const Radius.circular(16),
                      ),
                      border: Border.all(
                        color: isQuickTravel
                            ? AppColors.primaryLight
                            : AppColors.cardBorder,
                        width: isQuickTravel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pinned badge
                        if (msg.isPinned)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 11, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Quick travel alert badge
                        if (isQuickTravel)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sand,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me_rounded,
                                    size: 11, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'TRAVEL ALERT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkAccent,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Message text
                        if (msg.text.isNotEmpty)
                          Text(
                            msg.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.deepEarth,
                              height: 1.35,
                            ),
                          ),

                        // Rich embeds
                        if (hasMetadata) ...[
                          if (msg.messageType == ChatMessageType.itinerarySnippet)
                            ItineraryStopEmbed(metadata: msg.metadata!, isMe: false),
                          if (msg.messageType == ChatMessageType.expenseRequest)
                            ExpenseRequestEmbed(metadata: msg.metadata!, isMe: false),
                          if (msg.messageType == ChatMessageType.packingAlert)
                            PackingAlertEmbed(
                              metadata: msg.metadata!,
                              isMe: false,
                              onClaim: onClaimPackingItem,
                            ),
                          if (msg.messageType == ChatMessageType.locationDrop)
                            LocationDropEmbed(metadata: msg.metadata!, isMe: false),
                          if (msg.messageType == ChatMessageType.media)
                            MediaAttachmentEmbed(metadata: msg.metadata!, isMe: false),
                        ],

                        const SizedBox(height: 4),

                        // Timestamp
                        Text(
                          _formatTime(msg.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Persistent emoji reaction chips
                  ReactionPillsRow(
                    reactions: msg.reactions,
                    currentUserId: currentUserId,
                    onToggleReaction: onToggleReaction,
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

// ── Scroll-to-Bottom Floating Button ──────────────────────────────────────────

class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_downward_rounded,
            color: AppColors.primary, size: 20),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String? tripId;
  final VoidCallback onCreatePoll;
  final ValueChanged<String> onQuickStart;

  const _EmptyChat({
    required this.tripId,
    required this.onCreatePoll,
    required this.onQuickStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.sand,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.forum_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              tripId != null
                  ? 'No messages yet!'
                  : 'Select a trip to see group chat',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tripId != null
                  ? 'Start the conversation, coordinate meetup spots, or poll the group to decide your itinerary!'
                  : 'Join or select an active trip from the Home screen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.warmMuted,
                height: 1.4,
              ),
            ),
            if (tripId != null) ...[
              const SizedBox(height: 24),
              const Text(
                'QUICK ICEBREAKERS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkAccent,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _IcebreakerChip(
                    text: '👋 Say hello to everyone',
                    onTap: () => onQuickStart('👋 Hello travel crew! So excited for our adventure together!'),
                  ),
                  _IcebreakerChip(
                    text: '⏰ What time are we meeting?',
                    onTap: () => onQuickStart('⏰ Hey guys, what time should we all meet up on Day 1?'),
                  ),
                  _IcebreakerChip(
                    text: '🍽️ Who has food recommendations?',
                    onTap: () => onQuickStart('🍽️ Anyone have restaurant or street food recommendations in mind?'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onCreatePoll,
                icon: const Icon(Icons.how_to_vote_rounded, size: 18),
                label: const Text('Create First Travel Poll'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

class _IcebreakerChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _IcebreakerChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.deepEarth,
        ),
      ),
    );
  }
}

// ── Message Context Action Sheet ───────────────────────────────────────────────

class _MessageActionSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool canPin;
  final ValueChanged<String>? onSelectReaction;
  final VoidCallback onCopy;
  final VoidCallback onTogglePin;
  final VoidCallback? onDelete;

  const _MessageActionSheet({
    required this.message,
    required this.isMe,
    required this.canPin,
    this.onSelectReaction,
    required this.onCopy,
    required this.onTogglePin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Quick emoji reactions bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '👍', '✈️', '🌴', '😂', '🔥'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onSelectReaction?.call(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Copy Action
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.deepEarth),
              title: const Text(
                'Copy text',
                style: TextStyle( fontWeight: FontWeight.w600),
              ),
              onTap: onCopy,
            ),

            // Pin / Unpin Action
            if (canPin)
              ListTile(
                leading: Icon(
                  message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  message.isPinned ? 'Unpin message' : 'Pin message as announcement',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: onTogglePin,
              ),

            // Delete Action
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444)),
                title: const Text(
                  'Delete message',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned Messages Modal Sheet ───────────────────────────────────────────────

class _PinnedMessagesSheet extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isOrganizer;
  final ValueChanged<String> onUnpin;

  const _PinnedMessagesSheet({
    required this.messages,
    required this.isOrganizer,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: context.sheetMaxHeight(0.7),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
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
                const Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pinned Announcements (${messages.length})',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontHeading,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepEarth,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.dividerLight),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final msg = messages[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sand,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              msg.senderName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkAccent,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(msg.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                            if (isOrganizer) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => onUnpin(msg.id),
                                child: const Icon(Icons.close_rounded,
                                    size: 16, color: AppColors.deepEarth),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.deepEarth,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip & Members Info Sheet ─────────────────────────────────────────────────

class _TripInfoSheet extends StatelessWidget {
  final String tripTitle;
  final int memberCount;
  final dynamic trip;

  const _TripInfoSheet({
    required this.tripTitle,
    required this.memberCount,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
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
            Text(
              tripTitle,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontHeading,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepEarth,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$memberCount travelers connected in this trip',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.warmMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.dividerLight),
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.people_outline_rounded, color: AppColors.primary),
              title: const Text('View All Members & Permissions',
                  style: TextStyle( fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/members');
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined, color: AppColors.amber),
              title: const Text('Open Trip Details',
                  style: TextStyle( fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/trip-detail');
              },
            ),
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
