import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/avatar_model.dart';

class AvatarRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<AvatarModel?> getAvatarForUser(String userId) async {
    try {
      final response = await _client
          .from(AppConstants.tableAvatars)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return AvatarModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<AvatarModel> saveAvatar(AvatarModel avatar) async {
    try {
      final data = avatar.toJson();
      if (data['id'] == '') {
        data.remove('id');
      }

      final response = await _client
          .from(AppConstants.tableAvatars)
          .upsert(data)
          .select()
          .single();

      return AvatarModel.fromJson(response);
    } catch (e) {
      // In dummy mode or network error, return avatar with fallback ID
      return avatar.copyWith(id: avatar.id.isEmpty ? 'dummy_avatar_1' : avatar.id);
    }
  }
}
