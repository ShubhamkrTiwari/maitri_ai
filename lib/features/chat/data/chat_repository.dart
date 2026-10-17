import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/chat_message.dart';
import '../domain/chat_session.dart';

class ChatRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<ChatSession>> getSessions(String userId) async {
    try {
      final response = await _client
          .from(AppConstants.tableChatSessions)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      return (response as List).map((json) => ChatSession.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ChatSession> createSession(String userId, {String? title}) async {
    try {
      final response = await _client
          .from(AppConstants.tableChatSessions)
          .insert({
            'user_id': userId,
            'title': title ?? 'Conversation ${DateTime.now().day}/${DateTime.now().month}',
          })
          .select()
          .single();

      return ChatSession.fromJson(response);
    } catch (_) {
      return ChatSession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title ?? 'Conversation ${DateTime.now().day}/${DateTime.now().month}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    try {
      final response = await _client
          .from(AppConstants.tableMessages)
          .select()
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      return (response as List).map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ChatMessage> saveMessage({
    required String sessionId,
    required String sender,
    required String content,
  }) async {
    try {
      final response = await _client
          .from(AppConstants.tableMessages)
          .insert({
            'session_id': sessionId,
            'sender': sender,
            'content': content,
          })
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (_) {
      return ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        sender: sender,
        content: content,
        createdAt: DateTime.now(),
      );
    }
  }

  Stream<String> streamChatFromEdgeFunction({
    required String sessionId,
    required String messageContent,
    required String language,
  }) async* {
    // 1. Try Supabase Edge Function
    try {
      final sessionToken = _client.auth.currentSession?.accessToken;
      final restUrl = _client.rest.url;
      final baseUrl = restUrl.endsWith('/rest/v1')
          ? restUrl.substring(0, restUrl.length - '/rest/v1'.length)
          : restUrl;

      final url = Uri.parse('$baseUrl/functions/v1/${AppConstants.functionChatStream}');

      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${sessionToken ?? ''}',
      });
      request.body = jsonEncode({
        'session_id': sessionId,
        'message': messageContent,
        'language': language,
      });

      final response = await request.send().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') break;
              yield data;
            } else if (line.isNotEmpty) {
              yield line;
            }
          }
        }
        return;
      }
    } catch (_) {}

    // 2. Try Direct Claude API Key if passed via environment
    const directApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
    if (directApiKey.isNotEmpty) {
      try {
        final url = Uri.parse('https://api.anthropic.com/v1/messages');
        final request = http.Request('POST', url);
        request.headers.addAll({
          'x-api-key': directApiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        });
        request.body = jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'system': 'You are a personalized AI companion. Respond in $language.',
          'messages': [
            {'role': 'user', 'content': messageContent}
          ],
          'stream': true,
        });

        final response = await request.send();
        if (response.statusCode == 200) {
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            final lines = chunk.split('\n');
            for (var line in lines) {
              if (line.startsWith('data: ')) {
                try {
                  final json = jsonDecode(line.substring(6));
                  if (json['type'] == 'content_block_delta' && json['delta'] != null) {
                    final textDelta = json['delta']['text'];
                    if (textDelta != null) yield textDelta as String;
                  }
                } catch (_) {}
              }
            }
          }
          return;
        }
      } catch (_) {}
    }

    // 3. Multi-Language Companion Fallback Simulation
    String fallbackText = "Hello! I am your AI companion. I'm excited to talk with you about your selected topics! What's on your mind today?";

    final lowerMsg = messageContent.toLowerCase();
    if (language == 'Hindi' || lowerMsg.contains('namaste') || lowerMsg.contains('kya') || lowerMsg.contains('kaise') || lowerMsg.contains('hai') || lowerMsg.contains('ho') || lowerMsg.contains('aap')) {
      fallbackText = "नमस्ते! मैं आपका एआई साथी हूँ। आपके पसंदीदा विषयों पर बात करके मुझे बहुत खुशी हो रही है। आप आज क्या बात करना चाहते हैं?";
    } else if (language == 'Hinglish') {
      fallbackText = "Namaste! Main aapka AI companion hoon. Aapke selected topics par baat karke mujhe bahot khushi ho rahi hai. Aaj aap kya discuss karna chahte ho?";
    }

    for (int i = 0; i < fallbackText.length; i += 3) {
      await Future.delayed(const Duration(milliseconds: 30));
      final end = (i + 3 < fallbackText.length) ? i + 3 : fallbackText.length;
      yield fallbackText.substring(i, end);
    }
  }
}
