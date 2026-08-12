/// token_service.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Stateless JWT utility class — the Token Service block from the
/// Middleware/Gateway layer of the architecture diagram.
///
/// All methods operate on raw JWT strings without any network calls.
/// Signature validation is intentionally omitted here — Supabase's server
/// performs RS256 signature verification on every protected API request.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

class TokenService {
  TokenService._();

  // ── JWT Parsing ────────────────────────────────────────────────────────────

  /// Decodes the payload section of a JWT without verifying the signature.
  /// Returns an empty map on any parse error.
  static Map<String, dynamic> parseJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      // Base64url decode the payload (index 1)
      String payload = parts[1];
      // Pad to a multiple of 4 for base64 decoding
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[TokenService] parseJwtClaims error: $e');
      return {};
    }
  }

  // ── Expiry ─────────────────────────────────────────────────────────────────

  /// Returns `true` if the JWT [token] is expired based on its `exp` claim.
  /// Returns `true` (treats as expired) if the claim is missing or malformed.
  static bool isTokenExpired(String token) {
    try {
      final claims = parseJwtClaims(token);
      final exp = claims['exp'];
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(
          (exp as int) * 1000,
          isUtc: true);
      return DateTime.now().toUtc().isAfter(expiry);
    } catch (e) {
      return true;
    }
  }

  /// Returns the expiry [DateTime] of a JWT, or `null` if unavailable.
  static DateTime? getTokenExpiry(String token) {
    try {
      final claims = parseJwtClaims(token);
      final exp = claims['exp'];
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(
          (exp as int) * 1000,
          isUtc: true);
    } catch (_) {
      return null;
    }
  }

  // ── Scopes / Roles ─────────────────────────────────────────────────────────

  /// Returns the list of scopes from the JWT `scope` claim (space-separated).
  static List<String> getScopes(String token) {
    final claims = parseJwtClaims(token);
    final scope = claims['scope'] as String?;
    if (scope == null || scope.isEmpty) return [];
    return scope.split(' ');
  }

  /// Returns `true` if the JWT contains [requiredScope] in its scope claim.
  static bool hasScope(String token, String requiredScope) {
    return getScopes(token).contains(requiredScope);
  }

  /// Returns the `role` claim from the JWT, defaulting to `'anon'`.
  static String getRole(String token) {
    final claims = parseJwtClaims(token);
    return (claims['role'] as String?) ?? 'anon';
  }

  /// Returns the `sub` (subject / user ID) claim from the JWT.
  static String? getUserId(String token) {
    final claims = parseJwtClaims(token);
    return claims['sub'] as String?;
  }

  // ── Auth Header ────────────────────────────────────────────────────────────

  /// Builds the standard `Authorization: Bearer <token>` header map.
  static Map<String, String> buildAuthHeader(String token) {
    return {'Authorization': 'Bearer $token'};
  }
}
