import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/selected_trip_provider.dart';
import '../../core/repositories/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const ChatScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl        = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _isSending    = false;

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

    final profile   = ref.read(profileProvider);
    final senderName = profile.displayName.isNotEmpty ? profile.displayName : 'Anonymous';

    setState(() => _isSending = true);
    _ctrl.clear();

    await ref.read(chatProvider.notifier).sendMessage(text, senderName);

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final tripId    = ref.watch(selectedTripIdProvider);
    final chatAsync = ref.watch(chatProvider);

    // Auto-scroll when new messages arrive
    ref.listen<AsyncValue<List<ChatMessage>>>(chatProvider, (_, next) {
      if (next.hasValue) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: AppColors.deepEarth,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          _ChatHeader(showHeader: widget.showHeader, tripId: tripId),

          // ── Messages ─────────────────────────────────────────────
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
                  if (messages.isEmpty) {
                    return _EmptyChat(tripId: tripId);
                  }
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg      = messages[i];
                      final showDate = i == 0 ||
                          !_isSameDay(messages[i - 1].createdAt, msg.createdAt);
                      return Column(
                        children: [
                          if (showDate) _dateDivider(msg.createdAt),
                          msg.isMe
                              ? _MyBubble(
                                  msg: msg,
                                  onDelete: () => ref
                                      .read(chatProvider.notifier)
                                      .deleteMessage(msg.id),
                                )
                              : _TheirBubble(msg: msg),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ── Input bar ────────────────────────────────────────────
          _InputBar(
            controller: _ctrl,
            isSending: _isSending,
            isOffline: tripId == null,
            onSend: _sendMessage,
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
            const Expanded(
                child: Divider(color: AppColors.dividerLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isToday(dt)
                    ? 'Today'
                    : DateFormat('MMM d').format(dt),
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: AppColors.muted),
              ),
            ),
            const Expanded(
                child: Divider(color: AppColors.dividerLight)),
          ],
        ),
      );

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
}

// ── Chat Header ───────────────────────────────────────────────────────────────

class _ChatHeader extends ConsumerWidget {
  final bool showHeader;
  final String? tripId;
  const _ChatHeader({required this.showHeader, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, showHeader ? 56 : 16, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A04), AppColors.deepEarth],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Chat',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  tripId != null
                      ? 'Live · messages sync in real-time'
                      : 'Select a trip to start chatting',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          // Online indicator
          if (tripId != null)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String? tripId;
  const _EmptyChat({required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              tripId != null
                  ? 'No messages yet.\nSay hello to your travel group! 👋'
                  : 'Select a trip to see the group chat.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.warmMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isOffline;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isOffline,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                enabled: !isOffline,
                style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    color: AppColors.deepEarth),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: isOffline
                      ? 'Select a trip to chat...'
                      : 'Send a message...',
                  hintStyle: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.muted,
                      fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: (isOffline || isSending) ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isOffline || isSending)
                    ? AppColors.warmMuted
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My message bubble ─────────────────────────────────────────────────────────

class _MyBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onDelete;
  const _MyBubble({required this.msg, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 48),
      child: GestureDetector(
        onLongPress: () => _showDeleteSheet(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(msg.text,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: Colors.white)),
                ),
                const SizedBox(height: 2),
                Text(_formatTime(msg.createdAt),
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444)),
            title: const Text('Delete message',
                style: TextStyle(
                    fontFamily: 'DM Sans',
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ),
      ),
    );
  }
}

// ── Their message bubble ──────────────────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  final ChatMessage msg;
  const _TheirBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 30,
            height: 30,
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
                    color: Colors.white),
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
                      color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(msg.text,
                      style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          color: AppColors.deepEarth)),
                ),
                const SizedBox(height: 2),
                Text(_formatTime(msg.createdAt),
                    style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatTime(DateTime dt) {
  final h = dt.hour > 12
      ? dt.hour - 12
      : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $p';
}
