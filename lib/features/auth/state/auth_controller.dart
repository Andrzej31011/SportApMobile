import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/core/network/api_exception.dart';
import 'package:sport_ap_mobile/core/providers.dart';
import 'package:sport_ap_mobile/core/storage/token_storage.dart';
import 'package:sport_ap_mobile/features/auth/data/auth_repository.dart';
import 'package:sport_ap_mobile/features/auth/state/auth_state.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       super(AuthState.initial());

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;

  bool _sessionRestored = false;

  Future<void> restoreSession() async {
    if (_sessionRestored) {
      return;
    }
    _sessionRestored = true;

    state = state.copyWith(isLoading: true, clearError: true);

    final token = await _tokenStorage.readToken();
    if (token == null || token.trim().isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
      );
      return;
    }

    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
        clearError: true,
      );
    } catch (_) {
      await _tokenStorage.clearToken();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
      );
    }
  }

  Future<bool> login({required String nick, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authResponse = await _authRepository.login(
        nick: nick,
        password: password,
      );

      if (authResponse.token.isNotEmpty) {
        await _tokenStorage.saveToken(authResponse.token);
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        isLoading: false,
      );
      return true;
    } on ApiException catch (exception) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: exception.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: 'Nie udalo sie zalogowac.',
      );
      return false;
    }
  }

  Future<bool> register(RegisterPayload payload) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authResponse = await _authRepository.register(payload);

      if (authResponse.token.isNotEmpty) {
        await _tokenStorage.saveToken(authResponse.token);
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        isLoading: false,
      );
      return true;
    } on ApiException catch (exception) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: exception.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        isLoading: false,
        errorMessage: 'Nie udalo sie zarejestrowac.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.logout();
    } catch (_) {
      // Ignore backend logout failure and force local logout.
    }

    await _tokenStorage.clearToken();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      isLoading: false,
    );
  }

  Future<void> refreshCurrentUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
    } catch (_) {
      await handleUnauthorizedSession();
    }
  }

  Future<void> handleUnauthorizedSession() async {
    await _tokenStorage.clearToken();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
      isLoading: false,
      errorMessage: 'Sesja wygasla. Zaloguj sie ponownie.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final controller = AuthController(
      authRepository: ref.watch(authRepositoryProvider),
      tokenStorage: ref.watch(tokenStorageProvider),
    );

    ref.listen<int>(sessionExpiredProvider, (previous, next) {
      controller.handleUnauthorizedSession();
    });

    controller.restoreSession();
    return controller;
  },
);
