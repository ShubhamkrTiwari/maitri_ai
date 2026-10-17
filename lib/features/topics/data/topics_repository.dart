import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';

class TopicsRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<String>> getUserSelectedTopics(String userId) async {
    try {
      final response = await _client
          .from(AppConstants.tableUserTopics)
          .select('topic_id, custom_topic_name')
          .eq('user_id', userId);

      final List<String> selected = [];
      for (var row in response) {
        if (row['custom_topic_name'] != null && (row['custom_topic_name'] as String).isNotEmpty) {
          selected.add(row['custom_topic_name'] as String);
        } else if (row['topic_id'] != null) {
          selected.add(row['topic_id'] as String);
        }
      }
      return selected;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUserTopics(String userId, List<String> topicNames) async {
    try {
      // First clear existing topics for this user
      await _client.from(AppConstants.tableUserTopics).delete().eq('user_id', userId);

      if (topicNames.isEmpty) return;

      final List<Map<String, dynamic>> records = topicNames.map((t) {
        return {
          'user_id': userId,
          'topic_id': t.toLowerCase().replaceAll(' ', '_'),
          'custom_topic_name': t,
        };
      }).toList();

      await _client.from(AppConstants.tableUserTopics).insert(records);
    } catch (_) {
      // Graceful fallback for dummy mode
    }
  }
}
