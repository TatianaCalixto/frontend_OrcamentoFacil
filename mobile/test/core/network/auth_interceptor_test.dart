import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orcafacil_mobile/core/network/auth_interceptor.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockRequestHandler extends Mock implements RequestInterceptorHandler {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequestOptions());
  });

  group('AuthInterceptor.onRequest', () {
    test('injeta header Bearer quando há token no storage', () async {
      final storage = _MockTokenStorage();
      when(storage.read).thenAnswer((_) async => 'jwt-abc-123');
      final interceptor = AuthInterceptor(storage);
      final options = RequestOptions(path: '/users/me');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer jwt-abc-123');
      verify(() => handler.next(options)).called(1);
    });

    test('não adiciona header quando storage está vazio', () async {
      final storage = _MockTokenStorage();
      when(storage.read).thenAnswer((_) async => null);
      final interceptor = AuthInterceptor(storage);
      final options = RequestOptions(path: '/auth/login');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
      verify(() => handler.next(options)).called(1);
    });

    test('não adiciona header quando token é string vazia', () async {
      final storage = _MockTokenStorage();
      when(storage.read).thenAnswer((_) async => '');
      final interceptor = AuthInterceptor(storage);
      final options = RequestOptions(path: '/categories');
      final handler = _MockRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
