import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'unauthorized_interceptor.dart';

/// Fábrica do cliente HTTP autenticado do OrçaFácil.
///
/// Constrói um `Dio` com `baseUrl` derivado do `.env`, interceptor de injeção
/// de Bearer token, cache HTTP (respeitando `Cache-Control` do backend) e
/// interceptor de tratamento de 401.
///
/// Cache (S25-T05): GETs são cacheados conforme o `Cache-Control: max-age=N`
/// enviado pelo backend (política `request`). Qualquer mutação bem-sucedida
/// (POST/PUT/PATCH/DELETE) limpa o cache, garantindo que o próximo GET busque
/// dados frescos (invalidação).
Dio buildApiClient({
  required TokenStorage storage,
  required OnUnauthorized onUnauthorized,
  String? baseUrl,
  Dio? dio,
  CacheStore? cacheStore,
}) {
  final client = dio ?? Dio();
  client.options
    ..baseUrl = baseUrl ?? AppEnv.apiBaseUrl
    ..connectTimeout = const Duration(seconds: 10)
    ..receiveTimeout = const Duration(seconds: 10)
    ..contentType = Headers.jsonContentType
    ..responseType = ResponseType.json;

  final store = cacheStore ?? MemCacheStore();
  final cacheOptions = CacheOptions(
    store: store,
    // Respeita os diretivos HTTP do backend (Cache-Control: max-age=N).
    policy: CachePolicy.request,
    maxStale: const Duration(minutes: 5),
  );

  client.interceptors
    ..add(AuthInterceptor(storage))
    ..add(DioCacheInterceptor(options: cacheOptions))
    ..add(CacheInvalidationInterceptor(store))
    ..add(UnauthorizedInterceptor(
      storage: storage,
      onUnauthorized: onUnauthorized,
    ));
  return client;
}

/// Limpa o cache HTTP após qualquer mutação bem-sucedida (POST/PUT/PATCH/
/// DELETE), garantindo que o próximo GET não sirva dados obsoletos.
class CacheInvalidationInterceptor extends Interceptor {
  CacheInvalidationInterceptor(this._store);

  final CacheStore _store;

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final method = response.requestOptions.method.toUpperCase();
    final status = response.statusCode ?? 0;
    final isMutation = method != 'GET' && method != 'HEAD';
    if (isMutation && status >= 200 && status < 300) {
      await _store.clean();
    }
    handler.next(response);
  }
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
