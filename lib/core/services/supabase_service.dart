import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String get currentUserId {
    return currentUser?.id ?? LocalStorageService.getString('dummy_user_id') ?? 'dummy_user_123';
  }

  static bool get isAuthenticated =>
      currentUser != null || LocalStorageService.getBool('is_dummy_logged_in');

  static Future<void> setDummyLoggedIn(bool value) async {
    await LocalStorageService.saveBool('is_dummy_logged_in', value);
    if (value && LocalStorageService.getString('dummy_user_id') == null) {
      await LocalStorageService.saveString(
          'dummy_user_id', 'dummy_user_${DateTime.now().millisecondsSinceEpoch}');
    }
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}
