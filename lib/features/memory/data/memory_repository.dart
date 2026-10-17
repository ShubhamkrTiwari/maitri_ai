import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/memory_model.dart';

class MemoryRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<MemoryModel>> getMemories(String userId) async {
    try {
      final response = await _client
          .from(AppConstants.tableMemories)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => MemoryModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<MemoryModel> addMemory(String userId, String content) async {
    try {
      final response = await _client
          .from(AppConstants.tableMemories)
          .insert({
            'user_id': userId,
            'content': content,
          })
          .select()
          .single();

      return MemoryModel.fromJson(response);
    } catch (_) {
      return MemoryModel(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        content: content,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<void> updateMemory(String memoryId, String newContent) async {
    try {
      await _client
          .from(AppConstants.tableMemories)
          .update({'content': newContent})
          .eq('id', memoryId);
    } catch (_) {}
  }

  Future<void> deleteMemory(String memoryId) async {
    try {
      await _client.from(AppConstants.tableMemories).delete().eq('id', memoryId);
    } catch (_) {}
  }

  Future<void> clearAllMemories(String userId) async {
    try {
      await _client.from(AppConstants.tableMemories).delete().eq('user_id', userId);
    } catch (_) {}
  }
}
