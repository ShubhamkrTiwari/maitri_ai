import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/default_topics.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/topics_repository.dart';

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  return TopicsRepository();
});

class TopicsState {
  final List<String> selectedTopics;
  final List<String> customTopics;
  final bool isLoading;
  final String? errorMessage;

  TopicsState({
    required this.selectedTopics,
    required this.customTopics,
    this.isLoading = false,
    this.errorMessage,
  });

  TopicsState copyWith({
    List<String>? selectedTopics,
    List<String>? customTopics,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TopicsState(
      selectedTopics: selectedTopics ?? this.selectedTopics,
      customTopics: customTopics ?? this.customTopics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TopicsController extends StateNotifier<TopicsState> {
  final TopicsRepository _repository;

  TopicsController(this._repository)
      : super(
          TopicsState(
            selectedTopics: ['Career', 'Fitness', 'Studies', 'Mental wellness'],
            customTopics: [],
          ),
        ) {
    loadUserTopics();
  }

  Future<void> loadUserTopics() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    final saved = await _repository.getUserSelectedTopics(userId);
    if (saved.isNotEmpty) {
      final custom = <String>[];
      final defaultNames = DefaultTopics.list.map((e) => e.name).toList();

      for (var t in saved) {
        if (!defaultNames.contains(t) && !custom.contains(t)) {
          custom.add(t);
        }
      }

      state = state.copyWith(
        selectedTopics: saved,
        customTopics: custom,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleTopic(String topicName) {
    final current = List<String>.from(state.selectedTopics);
    if (current.contains(topicName)) {
      current.remove(topicName);
    } else {
      current.add(topicName);
    }
    state = state.copyWith(selectedTopics: current);
  }

  void addCustomTopic(String customName) {
    final name = customName.trim();
    if (name.isEmpty) return;

    final customs = List<String>.from(state.customTopics);
    if (!customs.contains(name)) {
      customs.add(name);
    }

    final selected = List<String>.from(state.selectedTopics);
    if (!selected.contains(name)) {
      selected.add(name);
    }

    state = state.copyWith(
      customTopics: customs,
      selectedTopics: selected,
    );
  }

  Future<bool> saveTopics() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.saveUserTopics(userId, state.selectedTopics);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final topicsControllerProvider =
    StateNotifierProvider<TopicsController, TopicsState>((ref) {
  return TopicsController(ref.watch(topicsRepositoryProvider));
});
