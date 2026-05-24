import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'goal_models.dart';

class GoalsApiException implements Exception {
  GoalsApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => 'GoalsApiException($statusCode/$code): $message';
}

class GoalsApi {
  GoalsApi(this._dio);
  final Dio _dio;

  Future<List<Goal>> list() async {
    try {
      final res = await _dio.get<List<dynamic>>('/goals');
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Goal.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar metas.');
    }
  }

  Future<Goal> create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/goals',
        data: {
          'name': name,
          'target_amount': targetAmount.toStringAsFixed(2),
          'current_amount': currentAmount.toStringAsFixed(2),
          'deadline': ?_formatDate(deadline),
        },
      );
      return Goal.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao criar meta.');
    }
  }

  Future<Goal> update(
    int id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    bool clearDeadline = false,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/goals/$id',
        data: {
          'name': ?name,
          'target_amount': ?targetAmount?.toStringAsFixed(2),
          'current_amount': ?currentAmount?.toStringAsFixed(2),
          if (clearDeadline)
            'deadline': null
          else if (deadline != null)
            'deadline': _formatDate(deadline),
        },
      );
      return Goal.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao atualizar meta.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/goals/$id');
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao excluir meta.');
    }
  }

  GoalsApiException _toException(DioException e, {required String fallback}) {
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
    return GoalsApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

String? _formatDate(DateTime? d) {
  if (d == null) return null;
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

final goalsApiProvider = Provider<GoalsApi>((ref) {
  return GoalsApi(ref.watch(apiClientProvider));
});
