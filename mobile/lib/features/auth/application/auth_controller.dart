import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../data/auth_repository.dart';

/// Estado de autenticação observado pela UI e pelo router.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage});
  final String? errorMessage;
}

/// Notifier que centraliza ações de autenticação. A UI dispara métodos e
/// observa `state`; o router observa o tipo do estado para decidir rotas.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Tenta restaurar a sessão a partir do storage (chamado pela Splash).
  Future<void> bootstrap() async {
    state = const AuthLoading();
    final user = await _repo.currentUser();
    state =
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } on AuthApiException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
    }
  }

  /// Faz cadastro. Em sucesso, deixa o estado como `AuthUnauthenticated` (sem
  /// mensagem) — a UI navega de volta para Login com uma snackbar de sucesso.
  /// Em erro, devolve a mensagem para a tela exibir.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repo.register(
        name: name,
        email: email,
        password: password,
      );
      state = const AuthUnauthenticated();
      return user;
    } on AuthApiException catch (e) {
      state = AuthUnauthenticated(errorMessage: e.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthUnauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
