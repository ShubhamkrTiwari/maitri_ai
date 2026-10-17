import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../avatar/presentation/controllers/avatar_controller.dart';
import '../../../avatar/presentation/widgets/animated_avatar_widget.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/chat_message.dart';
import '../controllers/chat_controller.dart';
import 'sessions_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with SingleTickerProviderStateMixin {
  final SttService _sttService = SttService();
  final TtsService _ttsService = TtsService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isTtsActive = true;
  bool _isListening = false;
  String _lastSpokenUserText = '';
  int _spokenCharIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sttService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _sttService.stopListening();
      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _isListening = false;
      });

      // Automatically send recognized speech if present
      if (_lastSpokenUserText.trim().isNotEmpty) {
        ref.read(chatControllerProvider.notifier).sendMessage(_lastSpokenUserText);
      }
    } else {
      await _ttsService.stop();
      setState(() {
        _isListening = true;
        _lastSpokenUserText = '';
      });
      _pulseController.repeat(reverse: true);

      final lang = ref.read(chatControllerProvider).currentLanguage;
      String localeId = 'en_US';
      if (lang == 'Hindi') localeId = 'hi_IN';

      await _sttService.startListening(
        localeId: localeId,
        onResult: (text) {
          if (mounted) {
            setState(() {
              _lastSpokenUserText = text;
            });
            // Auto submit when final sentence recognized
            if (text.length > 5) {
              Future.delayed(const Duration(seconds: 2), () {
                if (_isListening && _lastSpokenUserText == text) {
                  _stopAndSend();
                }
              });
            }
          }
        },
      );
    }
  }

  void _stopAndSend() async {
    await _sttService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }

    if (_lastSpokenUserText.trim().isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(_lastSpokenUserText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarState = ref.watch(avatarControllerProvider);
    final chatState = ref.watch(chatControllerProvider);
    final topicsState = ref.watch(topicsControllerProvider);

    final avatar = avatarState.avatar;

    // Voice response trigger when companion response finishes generating
    ref.listen<ChatState>(chatControllerProvider, (previous, next) {
      if (!_isTtsActive) return;

      final lastMsg = next.messages.isNotEmpty ? next.messages.last : null;
      if (lastMsg == null || lastMsg.sender != 'assistant' || lastMsg.content.isEmpty) return;

      // Speak full response clearly when generation finishes
      if (previous?.isStreaming == true && next.isStreaming == false) {
        _ttsService.speak(
          lastMsg.content,
          pitch: avatar.voicePitch,
          rate: avatar.voiceSpeed,
          language: next.currentLanguage,
        );
      }
    });

    // Determine current avatar anim state
    AvatarAnimState animState = AvatarAnimState.idle;
    String statusText = 'Tap microphone to speak';

    if (_isListening) {
      animState = AvatarAnimState.happy;
      statusText = 'Listening to you...';
    } else if (chatState.isStreaming) {
      animState = AvatarAnimState.talking;
      statusText = '${avatar.name} is speaking...';
    } else if (chatState.isLoading) {
      animState = AvatarAnimState.thinking;
      statusText = '${avatar.name} is thinking...';
    }

    // Latest messages
    final ChatMessage? lastAssistantMsg = chatState.messages.where((m) => m.sender == 'assistant').isNotEmpty
        ? chatState.messages.lastWhere((m) => m.sender == 'assistant')
        : (chatState.messages.isNotEmpty ? chatState.messages.last : null);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              avatar.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Voice Companion • ${chatState.currentLanguage}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTtsActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _isTtsActive ? AppColors.primaryLight : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isTtsActive = !_isTtsActive;
                if (_isTtsActive) {
                  _ttsService.speak(
                    'Voice audio enabled',
                    pitch: avatar.voicePitch,
                    rate: avatar.voiceSpeed,
                    language: chatState.currentLanguage,
                  );
                } else {
                  _ttsService.stop();
                }
              });
            },
            tooltip: 'TTS Audio Toggle',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded),
            onSelected: (lang) {
              ref.read(chatControllerProvider.notifier).setLanguage(lang);
            },
            itemBuilder: (context) => AppConstants.supportedLanguages
                .map((lang) => PopupMenuItem(
                      value: lang,
                      child: Text(lang),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/avatar-builder'),
            tooltip: 'Customize Avatar',
          ),
        ],
      ),
      drawer: const SessionsDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Active Topics Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              'Topics: ${topicsState.selectedTopics.take(3).join(", ")}${topicsState.selectedTopics.length > 3 ? "..." : ""}',
                              style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Main Visual Expressive Avatar
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isListening)
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 210,
                                      height: 210,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent.withOpacity(0.15),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            AnimatedAvatarWidget(
                              avatar: avatar,
                              state: animState,
                              size: 170,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Voice Companion Status Label
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _isListening ? Colors.redAccent : AppColors.primaryLight,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Live Spoken Transcript & Subtitles Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color ?? Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isListening && _lastSpokenUserText.isNotEmpty) ...[
                                const Text(
                                  'YOU SAID:',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastSpokenUserText,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                              ],
                              const Text(
                                'COMPANION RESPONSE:',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastAssistantMsg != null
                                    ? lastAssistantMsg.content
                                    : "Hello! I am ${avatar.name}. Tap the mic button below to talk with me!",
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Big Voice Mic Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isListening
                                ? const LinearGradient(colors: [Colors.redAccent, Colors.deepOrangeAccent])
                                : AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: _isListening
                                    ? Colors.redAccent.withOpacity(0.4)
                                    : AppColors.primaryLight.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        _isListening ? 'TAP TO FINISH & SEND' : 'TAP TO TALK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: _isListening ? Colors.redAccent : Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
