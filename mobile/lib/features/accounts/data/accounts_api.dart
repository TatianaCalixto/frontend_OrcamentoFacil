import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'account_models.dart';

/// Exceção amigável para erros do endpoint `/accounts`.
class AccountsApiException implements Exception {
  AccountsApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => 'AccountsApiException($statusCode/$code): $message';
}

/// Cliente HTTP para `/accounts`.
class AccountsApi {
  AccountsApi(this._dio);
  final Dio _dio;

  Future<List<AccountFull>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/accounts');
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AccountFull.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar contas.');
    }
  }

  Future<AccountFull> get(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/accounts/$id');
      return AccountFull.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar conta.');
    }
  }

  Future<AccountFull> create({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/accounts',
        data: <String, dynamic>{
          'name': name,
          'type': type.apiValue,
          'initial_balance': initialBalance,
        },
      );
      return AccountFull.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao criar conta.');
    }
  }

  Future<AccountFull> update(
    int id, {
    String? name,
    AccountType? type,
    bool? isActive,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/accounts/$id',
        data: <String, dynamic>{
          'name': ?name,
          'type': ?type?.apiValue,
          'is_active': ?isActive,
        },
      );
      return AccountFull.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao atualizar conta.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/accounts/$id');
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao excluir conta.');
    }
  }

  AccountsApiException _toException(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;
    String? detail;
    String? code;
    if (data is Map) {
      final rawDetail = data['detail'];
      if (rawDetail is String) {
        detail = rawDetail;
      } else if (rawDetail != null) {
        detail = rawDetail.toString();
      }
      final rawCode = data['code'];
      if (rawCode is String) code = rawCode;
    }
    return AccountsApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

final accountsApiProvider = Provider<AccountsApi>((ref) {
  return AccountsApi(ref.watch(apiClientProvider));
});
