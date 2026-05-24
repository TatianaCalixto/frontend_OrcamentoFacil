import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Interceptor que injeta o header `Authorization: Bearer <token>` em todas
/// as requisições quando há um token no `TokenStorage`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
