import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'transaction_models.dart';

/// Exceção amigável para erros de transactions/accounts/categories.
class TransactionsApiException implements Exception {
  TransactionsApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'TransactionsApiException($statusCode/$code): $message';
}

/// Filtros aplicáveis ao `GET /transactions`.
class TransactionFilters {
  const TransactionFilters({
    this.dateFrom,
    this.dateTo,
    this.accountId,
    this.categoryId,
    this.type,
    this.search,
    this.orderBy = '-date',
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? accountId;
  final int? categoryId;
  final TransactionType? type;
  final String? search;
  final String orderBy;

  TransactionFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    int? accountId,
    int? categoryId,
    TransactionType? type,
    String? search,
    String? orderBy,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearAccountId = false,
    bool clearCategoryId = false,
    bool clearType = false,
    bool clearSearch = false,
  }) {
    return TransactionFilters(
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      type: clearType ? null : (type ?? this.type),
      search: clearSearch ? null : (search ?? this.search),
      orderBy: orderBy ?? this.orderBy,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFilters &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.accountId == accountId &&
        other.categoryId == categoryId &&
        other.type == type &&
        other.search == search &&
        other.orderBy == orderBy;
  }

  @override
  int get hashCode => Object.hash(
        dateFrom,
        dateTo,
        accountId,
        categoryId,
        type,
        search,
        orderBy,
      );
}

/// Cliente HTTP para `/transactions`, `/accounts`, `/categories`.
class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  Future<TransactionPage> list({
    required TransactionFilters filters,
    required int page,
    int pageSize = 20,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: <String, dynamic>{
          'date_from': ?_formatDate(filters.dateFrom),
          'date_to': ?_formatDate(filters.dateTo),
          'account_id': ?filters.accountId,
          'category_id': ?filters.categoryId,
          'type': ?filters.type?.apiValue,
          'search': ?_nonEmpty(filters.search),
          'page': page,
          'page_size': pageSize,
          'order_by': filters.orderBy,
        },
      );
      return TransactionPage.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar transações.');
    }
  }

  Future<Transaction> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/transactions/$id');
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar transação.');
    }
  }

  Future<Transaction> create({
    required int accountId,
    required int categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? description,
    PaymentMethod? paymentMethod,
    bool isRecurring = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/transactions',
        data: <String, dynamic>{
          'account_id': accountId,
          'category_id': categoryId,
          'type': type.apiValue,
          'amount': amount.toStringAsFixed(2),
          'date': _formatDate(date),
          'description': ?_nonEmpty(description),
          'payment_method': ?paymentMethod?.apiValue,
          'is_recurring': isRecurring,
        },
      );
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao criar transação.');
    }
  }

  Future<Transaction> update(
    int id, {
    int? accountId,
    int? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? description,
    PaymentMethod? paymentMethod,
    bool? isRecurring,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/transactions/$id',
        data: <String, dynamic>{
          'account_id': ?accountId,
          'category_id': ?categoryId,
          'type': ?type?.apiValue,
          'amount': ?amount?.toStringAsFixed(2),
          'date': ?_formatDate(date),
          'description': ?description,
          'payment_method': ?paymentMethod?.apiValue,
          'is_recurring': ?isRecurring,
        },
      );
      return Transaction.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao atualizar transação.');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/transactions/$id');
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao excluir transação.');
    }
  }

  Future<List<Account>> listAccounts() async {
    try {
      final res = await _dio.get<List<dynamic>>('/accounts');
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Account.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar contas.');
    }
  }

  Future<List<Category>> listCategories() async {
    try {
      final res = await _dio.get<List<dynamic>>('/categories');
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao carregar categorias.');
    }
  }

  TransactionsApiException _toException(
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
    return TransactionsApiException(
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

String? _nonEmpty(String? v) {
  if (v == null) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

final transactionsApiProvider = Provider<TransactionsApi>((ref) {
  return TransactionsApi(ref.watch(apiClientProvider));
});
