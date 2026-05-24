import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';

/// AuthApi falso e configurável para testes — evita depender de Dio real
/// e simplifica os widget tests dos formulários.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({
    this.loginHandler,
    this.registerHandler,
    this.meHandler,
  });

  Future<AuthToken> Function({required String email, required String password})?
      loginHandler;

  Future<AuthUser> Function({
    required String name,
    required String email,
    required String password,
  })? registerHandler;

  Future<AuthUser> Function()? meHandler;

  final List<Map<String, String>> loginCalls = [];
  final List<Map<String, String>> registerCalls = [];
  int meCalls = 0;

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    loginCalls.add({'email': email, 'password': password});
    if (loginHandler != null) {
      return loginHandler!(email: email, password: password);
    }
    return AuthToken(accessToken: 'fake-token', tokenType: 'bearer');
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls.add({'name': name, 'email': email, 'password': password});
    if (registerHandler != null) {
      return registerHandler!(name: name, email: email, password: password);
    }
    return AuthUser(id: 1, name: name, email: email);
  }

  @override
  Future<AuthUser> me() async {
    meCalls++;
    if (meHandler != null) return meHandler!();
    return AuthUser(id: 1, name: 'Tati', email: 'tati@example.com');
  }
}

/// TokenStorage em memória para testes (implementa a interface real).
class InMemoryTokenStorageWrapped implements TokenStorage {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String t) async {
    token = t;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}
