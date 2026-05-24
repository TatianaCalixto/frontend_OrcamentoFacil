import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orcafacil_mobile/core/network/unauthorized_interceptor.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class _FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeDioException());
  });

  DioException errorWithStatus(int status) {
    final options = RequestOptions(path: '/anything');
    return DioException(
      requestOptions: options,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: status,
      ),
    );
  }

  group('UnauthorizedInterceptor.onError', () {
    test('em 401: limpa storage, chama callback e propaga erro', () async {
      final storage = _MockTokenStorage();
      when(storage.clear).thenAnswer((_) async {});
      var triggered = 0;
      final interceptor = UnauthorizedInterceptor(
        storage: storage,
        onUnauthorized: () => triggered++,
      );
      final handler = _MockErrorHandler();
      final err = errorWithStatus(401);

      await interceptor.onError(err, handler);

      verify(storage.clear).called(1);
      expect(triggered, 1);
      verify(() => handler.next(err)).called(1);
    });

    test('em 500: não limpa storage nem dispara callback', () async {
      final storage = _MockTokenStorage();
      when(storage.clear).thenAnswer((_) async {});
      var triggered = 0;
      final interceptor = UnauthorizedInterceptor(
        storage: storage,
        onUnauthorized: () => triggered++,
      );
      final handler = _MockErrorHandler();
      final err = errorWithStatus(500);

      await interceptor.onError(err, handler);

      verifyNever(storage.clear);
      expect(triggered, 0);
      verify(() => handler.next(err)).called(1);
    });

    test('em 403: não trata como unauthorized', () async {
      final storage = _MockTokenStorage();
      when(storage.clear).thenAnswer((_) async {});
      var triggered = 0;
      final interceptor = UnauthorizedInterceptor(
        storage: storage,
        onUnauthorized: () => triggered++,
      );
      final handler = _MockErrorHandler();
      final err = errorWithStatus(403);

      await interceptor.onError(err, handler);

      verifyNever(storage.clear);
      expect(triggered, 0);
    });
  });
}
