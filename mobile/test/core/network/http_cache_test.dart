// Cache HTTP no Dio (S25-T05): GET dentro do TTL é servido do cache (hit) e
// não refaz a chamada HTTP; mutações invalidam o cache (próximo GET = miss).
//
// Usa um HttpClientAdapter falso que conta as chamadas reais e devolve
// `Cache-Control: private, max-age=30` (mesmo contrato do backend).

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/core/network/api_client.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';

class _FakeStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
}

/// Adapter que conta as chamadas HTTP reais por método e devolve um 200 com
/// `Cache-Control: private, max-age=30`.
class _CountingAdapter implements HttpClientAdapter {
  int getCount = 0;
  int postCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final method = options.method.toUpperCase();
    if (method == 'GET') getCount++;
    if (method == 'POST') postCount++;
    return ResponseBody.fromString(
      '{"ok": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'cache-control': ['private, max-age=30'],
      },
    );
  }
}

void main() {
  late _CountingAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = _CountingAdapter();
    dio = buildApiClient(
      storage: _FakeStorage(),
      onUnauthorized: () {},
      baseUrl: 'https://api.test',
      cacheStore: MemCacheStore(),
    )..httpClientAdapter = adapter;
  });

  test('GET dentro do TTL é servido do cache (hit) — não refaz HTTP', () async {
    await dio.get<dynamic>('/accounts');
    await dio.get<dynamic>('/accounts');
    expect(adapter.getCount, 1, reason: 'o 2o GET deve ser cache hit');
  });

  test('GET de URLs distintas são misses independentes', () async {
    await dio.get<dynamic>('/accounts');
    await dio.get<dynamic>('/categories');
    expect(adapter.getCount, 2);
  });

  test('mutação invalida o cache — próximo GET refaz HTTP (miss)', () async {
    await dio.get<dynamic>('/accounts'); // miss -> 1
    await dio.get<dynamic>('/accounts'); // hit  -> 1
    expect(adapter.getCount, 1);

    await dio.post<dynamic>('/accounts', data: {'name': 'x'}); // mutação -> clean
    expect(adapter.postCount, 1);

    await dio.get<dynamic>('/accounts'); // miss após invalidação -> 2
    expect(adapter.getCount, 2);
  });
}
