import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import 'auth_api.dart';

/// Orquestra chamadas do `AuthApi` com o `TokenStorage`.
///
/// Responsabilidades:
/// - login: chama API, salva token no storage e retorna o usuário (via /me).
/// - register: chama API e retorna o usuário criado (sem login automático —
///   o usuário é redirecionado para Login após cadastro).
/// - logout: limpa o storage.
/// - currentUser: tenta `/users/me` se houver token; caso contrário, null.
class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage storage})
      : _api = api,
        _storage = storage;

  final AuthApi _api;
  final TokenStorage _storage;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final token = await _api.login(email: email, password: password);
    await _storage.write(token.accessToken);
    // Carrega o usuário corrente para confirmar a sessão.
    return _api.me();
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _api.register(name: name, email: email, password: password);
  }

  Future<void> logout() => _storage.clear();

  /// Retorna o usuário corrente quando há token válido. Em caso de qualquer
  /// erro (token ausente, expirado, rede), retorna `null` — o caller decide
  /// para onde navegar.
  Future<AuthUser?> currentUser() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return null;
    try {
      return await _api.me();
    } on AuthApiException {
      await _storage.clear();
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});
