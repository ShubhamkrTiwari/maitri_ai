import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/memory_repository.dart';
import '../../domain/memory_model.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

class MemoryState {
  final List<MemoryModel> memories;
  final bool isLoading;
  final String? errorMessage;

  MemoryState({
    required this.memories,
    this.isLoading = false,
    this.errorMessage,
  });

  MemoryState copyWith({
    List<MemoryModel>? memories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MemoryController extends StateNotifier<MemoryState> {
  final MemoryRepository _repository;

  MemoryController(this._repository) : super(MemoryState(memories: [])) {
    loadMemories();
  }

  Future<void> loadMemories() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    final memories = await _repository.getMemories(userId);
    state = state.copyWith(memories: memories, isLoading: false);
  }

  Future<void> addMemory(String content) async {
    final userId = SupabaseService.currentUserId;
    if (content.trim().isEmpty) return;

    state = state.copyWith(isLoading: true);
    final newMem = await _repository.addMemory(userId, content.trim());
    state = state.copyWith(
      memories: [newMem, ...state.memories],
      isLoading: false,
    );
  }

  Future<void> updateMemory(String id, String newContent) async {
    if (newContent.trim().isEmpty) return;

    state = state.copyWith(isLoading: true);
    await _repository.updateMemory(id, newContent.trim());
    final updated = state.memories.map((m) {
      if (m.id == id) {
        return m.copyWith(content: newContent.trim());
      }
      return m;
    }).toList();
    state = state.copyWith(memories: updated, isLoading: false);
  }

  Future<void> deleteMemory(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteMemory(id);
    final updated = state.memories.where((m) => m.id != id).toList();
    state = state.copyWith(memories: updated, isLoading: false);
  }

  Future<void> clearAllMemories() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    await _repository.clearAllMemories(userId);
    state = state.copyWith(memories: [], isLoading: false);
  }
}

final memoryControllerProvider =
    StateNotifierProvider<MemoryController, MemoryState>((ref) {
  return MemoryController(ref.watch(memoryRepositoryProvider));
});
