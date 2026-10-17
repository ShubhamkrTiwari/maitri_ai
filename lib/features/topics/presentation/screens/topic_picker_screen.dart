import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/default_topics.dart';
import '../controllers/topics_controller.dart';

class TopicPickerScreen extends ConsumerStatefulWidget {
  const TopicPickerScreen({super.key});

  @override
  ConsumerState<TopicPickerScreen> createState() => _TopicPickerScreenState();
}

class _TopicPickerScreenState extends ConsumerState<TopicPickerScreen> {
  final TextEditingController _customTopicController = TextEditingController();

  @override
  void dispose() {
    _customTopicController.dispose();
    super.dispose();
  }

  void _addCustomTopic() {
    final text = _customTopicController.text.trim();
    if (text.isNotEmpty) {
      ref.read(topicsControllerProvider.notifier).addCustomTopic(text);
      _customTopicController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Topics'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What do you want to talk about?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI companion will stay focused on these topics and politely decline off-topic queries.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Default Topics Chips
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Topics',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DefaultTopics.list.map((item) {
                          final isSelected = topicsState.selectedTopics.contains(item.name);
                          return FilterChip(
                            avatar: Text(item.icon),
                            label: Text(item.name),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.primaryLight : Colors.grey.shade300,
                              ),
                            ),
                            onSelected: (_) {
                              ref
                                  .read(topicsControllerProvider.notifier)
                                  .toggleTopic(item.name);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Custom Topics Section
                      const Text(
                        'Custom Topics',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customTopicController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Astrophysics, Gardening...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _addCustomTopic(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addCustomTopic,
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(backgroundColor: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (topicsState.customTopics.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topicsState.customTopics.map((custom) {
                            final isSelected = topicsState.selectedTopics.contains(custom);
                            return FilterChip(
                              avatar: const Text('✨'),
                              label: Text(custom),
                              selected: isSelected,
                              selectedColor: AppColors.secondaryLight.withOpacity(0.2),
                              checkmarkColor: AppColors.primaryLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primaryLight : Colors.grey.shade300,
                                ),
                              ),
                              onSelected: (_) {
                                ref
                                    .read(topicsControllerProvider.notifier)
                                    .toggleTopic(custom);
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: topicsState.isLoading || topicsState.selectedTopics.isEmpty
                    ? null
                    : () async {
                        final success =
                            await ref.read(topicsControllerProvider.notifier).saveTopics();
                        if (mounted && success) {
                          context.go('/chat');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: topicsState.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Start Chatting (${topicsState.selectedTopics.length} selected)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
