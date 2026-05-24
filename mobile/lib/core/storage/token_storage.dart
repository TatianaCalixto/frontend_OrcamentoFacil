import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato para armazenar/recuperar/limpar o token de acesso (JWT).
///
/// Abstrair `flutter_secure_storage` permite testar interceptors e fluxos
/// de autenticação sem depender de plugins nativos.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Implementação real baseada em `flutter_secure_storage`.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'orcafacil.access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// Provider Riverpod do `TokenStorage`. Pode ser sobrescrito em testes via
/// `ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(...)])`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});
