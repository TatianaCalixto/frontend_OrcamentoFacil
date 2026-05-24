import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'unauthorized_interceptor.dart';

/// Fábrica do cliente HTTP autenticado do OrçaFácil.
///
/// Constrói um `Dio` com `baseUrl` derivado do `.env`, interceptor de injeção
/// de Bearer token e interceptor de tratamento de 401.
Dio buildApiClient({
  required TokenStorage storage,
  required OnUnauthorized onUnauthorized,
  String? baseUrl,
  Dio? dio,
}) {
  final client = dio ?? Dio();
  client.options
    ..baseUrl = baseUrl ?? AppEnv.apiBaseUrl
    ..connectTimeout = const Duration(seconds: 10)
    ..receiveTimeout = const Duration(seconds: 10)
    ..contentType = Headers.jsonContentType
    ..responseType = ResponseType.json;
  client.interceptors
    ..add(AuthInterceptor(storage))
    ..add(UnauthorizedInterceptor(
      storage: storage,
      onUnauthorized: onUnauthorized,
    ));
  return client;
}

/// Callback global de unauthorized — substituído pelo router em runtime via
/// `ProviderScope` overrides. Em testes, basta sobrescrever este provider.
final onUnauthorizedProvider = Provider<OnUnauthorized>((ref) {
  return () {
    // Default: noop. O router (S11-T03) sobrescreve este provider para
    // navegar para a rota de Login.
  };
});

/// Provider Riverpod do `Dio` autenticado.
final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final onUnauthorized = ref.watch(onUnauthorizedProvider);
  return buildApiClient(storage: storage, onUnauthorized: onUnauthorized);
});
