/// audit_logger.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Lightweight structured audit logger for authentication and API gateway events.
///
/// • Holds a circular in-memory buffer of [maxEvents] events.
/// • On sign-out, flushes the buffer to [flutter_secure_storage] as JSON Lines.
/// • Never blocks the calling thread — all writes are fire-and-forget.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Event Model ───────────────────────────────────────────────────────────────

class AuditEvent {
  final String ts;          // ISO-8601 UTC timestamp
  final String method;      // HTTP method: GET | POST | PATCH | DELETE
  final String path;        // URL path (no query string)
  final int? statusCode;    // HTTP response status, null for offline events
  final int? latencyMs;     // Round-trip time in ms
  final String? userId;     // Supabase auth UID
  final bool offline;       // true when served from local cache

  const AuditEvent({
    required this.ts,
    required this.method,
    required this.path,
    this.statusCode,
    this.latencyMs,
    this.userId,
    this.offline = false,
  });

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'method': method,
        'path': path,
        if (statusCode != null) 'status': statusCode,
        if (latencyMs != null) 'latency_ms': latencyMs,
        if (userId != null) 'uid': userId,
        if (offline) 'offline': true,
      };

  @override
  String toString() => json.encode(toJson());
}

// ── Logger ────────────────────────────────────────────────────────────────────

class AuditLogger {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final AuditLogger instance = AuditLogger._();
  AuditLogger._();

  static const int maxEvents = 200;
  static const String _kStorageKey = 'audit_log';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  final List<AuditEvent> _buffer = [];

  // ── Log ────────────────────────────────────────────────────────────────────

  /// Records an API event. Oldest entry is dropped when buffer is full.
  void log(AuditEvent event) {
    if (_buffer.length >= maxEvents) {
      _buffer.removeAt(0);
    }
    _buffer.add(event);
    debugPrint('[AuditLogger] ${event.method} ${event.path} '
        '${event.statusCode ?? "offline"} '
        '${event.latencyMs != null ? "${event.latencyMs}ms" : ""}');
  }

  /// Convenience method for gateway interceptor calls.
  void logRequest({
    required String method,
    required String path,
    required int statusCode,
    required int latencyMs,
    String? userId,
    bool offline = false,
  }) {
    log(AuditEvent(
      ts: DateTime.now().toUtc().toIso8601String(),
      method: method,
      path: path,
      statusCode: statusCode,
      latencyMs: latencyMs,
      userId: userId,
      offline: offline,
    ));
  }

  // ── Flush ──────────────────────────────────────────────────────────────────

  /// Serialises the buffer to JSON Lines and persists to encrypted storage.
  /// Called on sign-out. Non-fatal if storage write fails.
  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    try {
      final lines = _buffer.map((e) => e.toString()).join('\n');
      await _storage.write(key: _kStorageKey, value: lines);
      _buffer.clear();
      debugPrint('[AuditLogger] Flushed ${_buffer.length} events to secure storage.');
    } catch (e) {
      debugPrint('[AuditLogger] flush error: $e');
    }
  }

  /// Clears the in-memory buffer without persisting (e.g., on force reset).
  void clear() => _buffer.clear();

  /// Returns a read-only copy of the current buffer (for testing/debugging).
  List<AuditEvent> get events => List.unmodifiable(_buffer);
}
