import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orcafacil_mobile/core/network/api_client.dart';
import 'package:orcafacil_mobile/core/network/auth_interceptor.dart';
import 'package:orcafacil_mobile/core/network/unauthorized_interceptor.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  group('buildApiClient', () {
    test('configura baseUrl e registra ambos interceptors', () {
      final storage = _MockTokenStorage();
      final dio = buildApiClient(
        storage: storage,
        onUnauthorized: () {},
        baseUrl: 'https://api.example.com',
      );

      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.contentType, Headers.jsonContentType);
      expect(
        dio.interceptors.whereType<AuthInterceptor>().length,
        1,
        reason: 'AuthInterceptor deve estar registrado',
      );
      expect(
        dio.interceptors.whereType<UnauthorizedInterceptor>().length,
        1,
        reason: 'UnauthorizedInterceptor deve estar registrado',
      );
    });
  });
}
