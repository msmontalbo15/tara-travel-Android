import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks whether the app is in pure offline mode (no Supabase auth).
/// All repositories read this before making remote calls.
final offlineModeProvider = Provider<bool>((ref) {
  return Supabase.instance.client.auth.currentUser == null;
});

/// The current authenticated Supabase user (null when offline/unauthenticated).
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// Stream of auth state changes — use to rebuild on sign-in/sign-out.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
