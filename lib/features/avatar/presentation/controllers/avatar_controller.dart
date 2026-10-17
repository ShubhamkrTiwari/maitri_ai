import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/avatar_repository.dart';
import '../../domain/avatar_model.dart';

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return AvatarRepository();
});

class AvatarState {
  final AvatarModel avatar;
  final bool isLoading;
  final String? errorMessage;

  AvatarState({
    required this.avatar,
    this.isLoading = false,
    this.errorMessage,
  });

  AvatarState copyWith({
    AvatarModel? avatar,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AvatarState(
      avatar: avatar ?? this.avatar,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AvatarController extends StateNotifier<AvatarState> {
  final AvatarRepository _repository;

  AvatarController(this._repository)
      : super(
          AvatarState(
            avatar: AvatarModel(
              id: '',
              userId: SupabaseService.currentUserId,
              name: 'Maitri',
            ),
          ),
        ) {
    loadAvatar();
  }

  Future<void> loadAvatar() async {
    final userId = SupabaseService.currentUserId;

    state = state.copyWith(isLoading: true);
    final loaded = await _repository.getAvatarForUser(userId);
    if (loaded != null) {
      state = state.copyWith(avatar: loaded, isLoading: false);
    } else {
      state = state.copyWith(
        avatar: state.avatar.copyWith(userId: userId),
        isLoading: false,
      );
    }
  }

  void updateAvatar(AvatarModel updated) {
    state = state.copyWith(avatar: updated);
  }

  Future<bool> saveAvatar() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final saved = await _repository.saveAvatar(state.avatar);
      state = state.copyWith(avatar: saved, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final avatarControllerProvider =
    StateNotifierProvider<AvatarController, AvatarState>((ref) {
  return AvatarController(ref.watch(avatarRepositoryProvider));
});
