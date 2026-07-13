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

  /// Sends a message. Optimistically adds to list before Supabase confirms.
  Future<void> sendMessage(String text, String senderName) async {
    final tripId = ref.read(selectedTripIdProvider);
    if (tripId == null || text.trim().isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(
      tripId: tripId,
      text: text,
      senderName: senderName,
    );
    // Real-time stream will push the confirmed message automatically
  }

  /// Deletes a message.
  Future<void> deleteMessage(String messageId) async {
    await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    final current = state.value ?? [];
    state = AsyncData(current.where((m) => m.id != messageId).toList());
  }
}

final chatProvider =
    AsyncNotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);
