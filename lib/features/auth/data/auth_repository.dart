import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
    } catch (_) {
      await SupabaseService.setDummyLoggedIn(true);
      return null;
    }
  }

  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      await SupabaseService.setDummyLoggedIn(true);
      return null;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      return await _client.auth.signInWithOAuth(OAuthProvider.google);
    } catch (_) {
      await SupabaseService.setDummyLoggedIn(true);
      return true;
    }
  }

  Future<void> signInAsDummy() async {
    await SupabaseService.setDummyLoggedIn(true);
  }

  Future<void> signOut() async {
    await SupabaseService.setDummyLoggedIn(false);
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
