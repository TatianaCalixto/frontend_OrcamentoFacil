import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Callback chamado quando o backend retorna 401.
///
/// A navegação real (para tela de Login) é injetada pelo `main.dart`/router
/// — o interceptor não conhece detalhes de UI, mantendo testabilidade.
typedef OnUnauthorized = void Function();

/// Interceptor que detecta respostas 401 (Unauthorized), limpa o token do
/// storage e dispara o callback de logout/redirecionamento.
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({
    required TokenStorage storage,
    required OnUnauthorized onUnauthorized,
  })  : _storage = storage,
        _onUnauthorized = onUnauthorized;

  final TokenStorage _storage;
  final OnUnauthorized _onUnauthorized;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.clear();
      _onUnauthorized();
    }
    handler.next(err);
  }
}
