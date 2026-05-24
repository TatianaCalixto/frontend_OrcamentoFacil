import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../transactions/data/transaction_models.dart' show TransactionType, TransactionTypeX;
import 'category_models.dart';

/// Exceção amigável para erros do endpoint `/categories`.
class CategoriesApiException implements Exception {
  CategoriesApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => 'CategoriesApiException($statusCode/$code): $message';
}

/// Cliente HTTP para `/categories`.
class CategoriesApi {
  CategoriesApi(this._dio);
  final Dio _dio;

  Future<List<CategoryFull>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/categories');
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryFull.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar categorias.');
    }
  }

  Future<CategoryFull> create({
    required String name,
    required TransactionType type,
    String? color,
    String? icon,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/categories',
        data: <String, dynamic>{
          'name': name,
          'type': type.apiValue,
          'color': ?color,
          'icon': ?icon,
        },
      );
      return CategoryFull.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao criar categoria.');
    }
  }

  Future<CategoryFull> update(
    int id, {
    String? name,
    TransactionType? type,
    String? color,
    String? icon,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/categories/$id',
        data: <String, dynamic>{
          'name': ?name,
          'type': ?type?.apiValue,
          'color': ?color,
          'icon': ?icon,
        },
      );
      return CategoryFull.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao atualizar categoria.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/categories/$id');
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao excluir categoria.');
    }
  }

  CategoriesApiException _toException(
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
    return CategoriesApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

final categoriesApiProvider = Provider<CategoriesApi>((ref) {
  return CategoriesApi(ref.watch(apiClientProvider));
});
