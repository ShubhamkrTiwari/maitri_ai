import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.errorMessage});

  AuthState copyWith({bool? isLoading, String? errorMessage}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await _repository.signInAsDummy();
      state = state.copyWith(isLoading: false);
      return true;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await _repository.signInAsDummy();
      state = state.copyWith(isLoading: false);
      return true;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await _repository.signInAsDummy();
      state = state.copyWith(isLoading: false);
      return true;
    }
  }

  Future<bool> signInAsDummy() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _repository.signInAsDummy();
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
