import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Resumo mensal do dashboard (`GET /dashboard/monthly-summary`).
class MonthlySummary {
  MonthlySummary({
    required this.month,
    required this.year,
    required this.receitaTotal,
    required this.despesaTotal,
    required this.saldo,
    required this.contas,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    final rawContas = (json['contas'] as List?) ?? const [];
    return MonthlySummary(
      month: json['month'] as int,
      year: json['year'] as int,
      receitaTotal: _toDouble(json['receita_total']),
      despesaTotal: _toDouble(json['despesa_total']),
      saldo: _toDouble(json['saldo']),
      contas: rawContas
          .whereType<Map<String, dynamic>>()
          .map(AccountSummary.fromJson)
          .toList(growable: false),
    );
  }

  final int month;
  final int year;
  final double receitaTotal;
  final double despesaTotal;
  final double saldo;
  final List<AccountSummary> contas;

  double get saldoTotalContas =>
      contas.fold<double>(0, (sum, c) => sum + c.currentBalance);
}

class AccountSummary {
  AccountSummary({
    required this.accountId,
    required this.name,
    required this.currentBalance,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    return AccountSummary(
      accountId: json['account_id'] as int,
      name: json['name'] as String,
      currentBalance: _toDouble(json['current_balance']),
    );
  }

  final int accountId;
  final String name;
  final double currentBalance;
}

/// Quebra por categoria (`GET /dashboard/category-breakdown`).
class CategoryBreakdown {
  CategoryBreakdown({
    required this.month,
    required this.year,
    required this.items,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return CategoryBreakdown(
      month: json['month'] as int,
      year: json['year'] as int,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(CategoryBreakdownItem.fromJson)
          .toList(growable: false),
    );
  }

  final int month;
  final int year;
  final List<CategoryBreakdownItem> items;
}

class CategoryBreakdownItem {
  CategoryBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.total,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      color: json['color'] as String?,
      total: _toDouble(json['total']),
    );
  }

  final int categoryId;
  final String name;
  final String? color;
  final double total;
}

/// Exceção de erros da API de dashboard, com mensagem amigável.
class DashboardApiException implements Exception {
  DashboardApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'DashboardApiException($statusCode/$code): $message';
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Cliente HTTP para os endpoints `/dashboard/*`.
class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<MonthlySummary> monthlySummary({int? month, int? year}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/dashboard/monthly-summary',
        queryParameters: <String, dynamic>{
          'month': ?month,
          'year': ?year,
        },
      );
      return MonthlySummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Não foi possível carregar o resumo.');
    }
  }

  Future<CategoryBreakdown> categoryBreakdown({int? month, int? year}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/dashboard/category-breakdown',
        queryParameters: <String, dynamic>{
          'month': ?month,
          'year': ?year,
        },
      );
      return CategoryBreakdown.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(
        e,
        fallback: 'Não foi possível carregar a quebra por categoria.',
      );
    }
  }

  DashboardApiException _toException(
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
    return DashboardApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  final dio = ref.watch(apiClientProvider);
  return DashboardApi(dio);
});
