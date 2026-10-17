import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_message.dart';
import '../../domain/chat_session.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String currentLanguage;
  final String? errorMessage;

  ChatState({
    required this.sessions,
    this.currentSession,
    required this.messages,
    this.isLoading = false,
    this.isStreaming = false,
    this.currentLanguage = 'English',
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? currentLanguage,
    String? errorMessage,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      errorMessage: errorMessage,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatController(this._repository)
      : super(ChatState(sessions: [], messages: [])) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    final sessions = await _repository.getSessions(userId);
    if (sessions.isNotEmpty) {
      state = state.copyWith(
        sessions: sessions,
        currentSession: sessions.first,
        isLoading: false,
      );
      await loadMessages(sessions.first.id);
    } else {
      await createNewSession();
    }
  }

  Future<void> createNewSession() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    final newSession = await _repository.createSession(userId);
    final updatedSessions = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: updatedSessions,
      currentSession: newSession,
      messages: [],
      isLoading: false,
    );
  }

  Future<void> selectSession(ChatSession session) async {
    state = state.copyWith(currentSession: session);
    await loadMessages(session.id);
  }

  Future<void> loadMessages(String sessionId) async {
    state = state.copyWith(isLoading: true);
    final messages = await _repository.getMessages(sessionId);
    state = state.copyWith(messages: messages, isLoading: false);
  }

  void setLanguage(String lang) {
    state = state.copyWith(currentLanguage: lang);
  }

  bool _checkCrisisKeywords(String text) {
    final lower = text.toLowerCase();
    final crisisWords = [
      'suicide',
      'kill myself',
      'want to die',
      'end my life',
      'self harm',
      'hurt myself',
      'no reason to live'
    ];
    return crisisWords.any((w) => lower.contains(w));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.currentSession == null) return;

    final sessionId = state.currentSession!.id;

    // Check for crisis trigger
    if (_checkCrisisKeywords(text)) {
      final userMsg = await _repository.saveMessage(
        sessionId: sessionId,
        sender: 'user',
        content: text,
      );
      final crisisMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        sender: 'assistant',
        content:
            "I'm so sorry you're going through this, but please know you are not alone. There is help available right now.",
        createdAt: DateTime.now(),
        isCrisisAlert: true,
      );
      await _repository.saveMessage(
        sessionId: sessionId,
        sender: 'assistant',
        content: crisisMsg.content,
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, crisisMsg],
      );
      return;
    }

    // Normal flow
    final userMsg = await _repository.saveMessage(
      sessionId: sessionId,
      sender: 'user',
      content: text,
    );

    // Placeholder for assistant streaming
    final placeholderAssistant = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      sender: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, placeholderAssistant],
      isStreaming: true,
    );

    String accumulatedContent = '';

    try {
      final stream = _repository.streamChatFromEdgeFunction(
        sessionId: sessionId,
        messageContent: text,
        language: state.currentLanguage,
      );

      await for (final token in stream) {
        accumulatedContent += token;
        final updatedList = List<ChatMessage>.from(state.messages);
        final lastIdx = updatedList.length - 1;
        if (lastIdx >= 0) {
          updatedList[lastIdx] = updatedList[lastIdx].copyWith(content: accumulatedContent);
          state = state.copyWith(messages: updatedList);
        }
      }

      // Save complete assistant message to Supabase
      if (accumulatedContent.isNotEmpty) {
        final savedAssistantMsg = await _repository.saveMessage(
          sessionId: sessionId,
          sender: 'assistant',
          content: accumulatedContent,
        );
        final updatedList = List<ChatMessage>.from(state.messages);
        updatedList[updatedList.length - 1] = savedAssistantMsg;
        state = state.copyWith(messages: updatedList, isStreaming: false);
      } else {
        state = state.copyWith(isStreaming: false);
      }
    } catch (e) {
      state = state.copyWith(isStreaming: false, errorMessage: e.toString());
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider));
});
