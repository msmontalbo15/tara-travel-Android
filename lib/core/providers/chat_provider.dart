import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import 'selected_trip_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

// ── Chat AsyncNotifier ────────────────────────────────────────────────────────

class ChatNotifier extends AsyncNotifier<List<ChatMessage>> {
  StreamSubscription<List<ChatMessage>>? _sub;

  @override
  Future<List<ChatMessage>> build() async {
    final tripId = ref.watch(selectedTripIdProvider);

    // Cancel previous subscription when tripId changes
    _sub?.cancel();
    _sub = null;

    if (tripId == null) return [];

    final repo = ref.read(chatRepositoryProvider);

    // Initial load
    final messages = await repo.getMessages(tripId);

    // Subscribe to real-time updates
    _sub = repo.messagesStream(tripId).listen(
      (list) => state = AsyncData(list),
      onError: (e) {
        // Keep last good state on error; don't crash
      },
    );

    // Cancel subscription when provider is disposed
    ref.onDispose(() => _sub?.cancel());

    return messages;
  }

  /// Sends a message with optimistic local rendering.
  /// The bubble appears instantly; the server-confirmed version replaces it
  /// when the real-time stream delivers the authoritative record.
  Future<void> sendMessage(String text, String senderName) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null || text.trim().isEmpty) return;

    // ── Optimistic insert ─────────────────────────────────────
    final tempId = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: tempId,
      tripId: tripId,
      userId: '', // will be replaced by server
      senderName: senderName,
      text: text.trim(),
      createdAt: DateTime.now(),
      isMe: true,
      isPending: true,
    );
    final current = state.value ?? [];
    state = AsyncData([...current, optimistic]);

    // ── Async dispatch ────────────────────────────────────────
    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(
      tripId: tripId,
      text: text,
      senderName: senderName,
    );
    // Real-time stream will push the confirmed message automatically,
    // replacing the optimistic entry via full list refresh.
  }

  /// Sends a quick travel message with a preset type.
  Future<void> sendQuickTravel(String text, String senderName) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null) return;

    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(
      tripId: tripId,
      text: text,
      senderName: senderName,
      messageType: ChatMessageType.quickTravel,
    );
  }

  /// Deletes a message.
  Future<void> deleteMessage(String messageId) async {
    await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    final current = state.value ?? [];
    state = AsyncData(current.where((m) => m.id != messageId).toList());
  }

  /// Toggles a message pin state.
  Future<void> togglePin(String messageId, bool isPinned) async {
    await ref.read(chatRepositoryProvider).togglePinMessage(messageId, isPinned);
    // Real-time stream refreshes state
  }
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

// ── Pinned Messages Provider ──────────────────────────────────────────────────

/// Derived provider that filters only pinned messages from the chat stream.
final pinnedMessagesProvider = Provider<List<ChatMessage>>((ref) {
  final messages = ref.watch(chatProvider).value ?? [];
  return messages.where((m) => m.isPinned).toList();
});
