import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'budget_models.dart';

class BudgetsApiException implements Exception {
  BudgetsApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => 'BudgetsApiException($statusCode/$code): $message';
}

class BudgetsApi {
  BudgetsApi(this._dio);
  final Dio _dio;

  Future<List<BudgetWithUsage>> list({required int month, required int year}) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/budgets',
        queryParameters: {'month': month, 'year': year},
      );
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BudgetWithUsage.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar orçamentos.');
    }
  }

  Future<BudgetRead> create({
    required int categoryId,
    required int month,
    required int year,
    required double limitAmount,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/budgets',
        data: {
          'category_id': categoryId,
          'month': month,
          'year': year,
          'limit_amount': limitAmount.toStringAsFixed(2),
        },
      );
      return BudgetRead.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao criar orçamento.');
    }
  }

  Future<BudgetRead> update(int id, {required double limitAmount}) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/budgets/$id',
        data: {'limit_amount': limitAmount.toStringAsFixed(2)},
      );
      return BudgetRead.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao atualizar orçamento.');
    }
  }

  Future<BudgetWithUsage> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/budgets/$id');
      return BudgetWithUsage.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar orçamento.');
    }
  }

  BudgetsApiException _toException(
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
    return BudgetsApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

final budgetsApiProvider = Provider<BudgetsApi>((ref) {
  return BudgetsApi(ref.watch(apiClientProvider));
});
