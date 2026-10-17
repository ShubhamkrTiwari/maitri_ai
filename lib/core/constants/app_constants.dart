class AppConstants {
  static const String appName = 'Maitri AI';
  static const String appTagline = 'Your Personalized AI Companion';
  
  // Hive Box Names
  static const String chatCacheBox = 'chat_cache_box';
  static const String userPrefsBox = 'user_prefs_box';

  // Supabase Table Names
  static const String tableProfiles = 'profiles';
  static const String tableAvatars = 'avatars';
  static const String tableTopics = 'topics';
  static const String tableUserTopics = 'user_topics';
  static const String tableChatSessions = 'chat_sessions';
  static const String tableMessages = 'messages';
  static const String tableMemories = 'memories';

  // Edge Functions
  static const String functionChatStream = 'chat-stream';
  static const String functionExtractMemory = 'extract-memory';

  // Supported Languages
  static const List<String> supportedLanguages = ['English', 'Hindi', 'Hinglish'];
}
