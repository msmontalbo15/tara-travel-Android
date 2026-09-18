import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/friend_circle_model.dart';

class FriendCircleRepository {
  static const String _kCirclesPrefix = 'user_friend_circles_';
  final FlutterSecureStorage _storage;

  FriendCircleRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _storageKey(String userId) => '$_kCirclesPrefix$userId';

  /// Loads all travel circles for a user (offline-first from encrypted storage)
  Future<List<FriendCircle>> getCircles(String userId) async {
    try {
      final raw = await _storage.read(key: _storageKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        return decoded
            .map((item) => FriendCircle.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[FriendCircleRepository] Error reading circles: $e');
    }
    return [];
  }

  /// Saves the complete list of circles for a user
  Future<void> saveCircles(String userId, List<FriendCircle> circles) async {
    try {
      final encoded = jsonEncode(circles.map((c) => c.toJson()).toList());
      await _storage.write(key: _storageKey(userId), value: encoded);
    } catch (e) {
      debugPrint('[FriendCircleRepository] Error saving circles: $e');
      rethrow;
    }
  }

  /// Adds or updates a travel circle
  Future<List<FriendCircle>> upsertCircle(String userId, FriendCircle circle) async {
    final list = await getCircles(userId);
    final index = list.indexWhere((c) => c.id == circle.id);

    List<FriendCircle> updatedList;
    if (index >= 0) {
      updatedList = List.from(list)..[index] = circle;
    } else {
      updatedList = [...list, circle];
    }

    await saveCircles(userId, updatedList);
    return updatedList;
  }

  /// Deletes a travel circle
  Future<List<FriendCircle>> deleteCircle(String userId, String circleId) async {
    final list = await getCircles(userId);
    final updatedList = list.where((c) => c.id != circleId).toList();
    await saveCircles(userId, updatedList);
    return updatedList;
  }
}
