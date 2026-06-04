import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/json/converters.dart';

part 'transaction_models.freezed.dart';
part 'transaction_models.g.dart';

/// Tipo da transação no backend.
enum TransactionType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

extension TransactionTypeX on TransactionType {
  String get apiValue => switch (this) {
        TransactionType.income => 'income',
        TransactionType.expense => 'expense',
      };

  String get label => switch (this) {
        TransactionType.income => 'Receita',
        TransactionType.expense => 'Despesa',
      };

  static TransactionType fromApi(String raw) => switch (raw) {
        'income' => TransactionType.income,
        'expense' => TransactionType.expense,
        _ => TransactionType.expense,
      };
}

/// Forma de pagamento.
enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('debit')
  debit,
  @JsonValue('credit')
  credit,
  @JsonValue('pix')
  pix,
  @JsonValue('transfer')
  transfer,
  @JsonValue('other')
  other,
}

extension PaymentMethodX on PaymentMethod {
  String get apiValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.debit => 'debit',
        PaymentMethod.credit => 'credit',
        PaymentMethod.pix => 'pix',
        PaymentMethod.transfer => 'transfer',
        PaymentMethod.other => 'other',
      };

  String get label => switch (this) {
        PaymentMethod.cash => 'Dinheiro',
        PaymentMethod.debit => 'Débito',
        PaymentMethod.credit => 'Crédito',
        PaymentMethod.pix => 'PIX',
        PaymentMethod.transfer => 'Transferência',
        PaymentMethod.other => 'Outro',
      };

  static PaymentMethod? fromApi(String? raw) {
    if (raw == null) return null;
    return switch (raw) {
      'cash' => PaymentMethod.cash,
      'debit' => PaymentMethod.debit,
      'credit' => PaymentMethod.credit,
      'pix' => PaymentMethod.pix,
      'transfer' => PaymentMethod.transfer,
      'other' => PaymentMethod.other,
      _ => null,
    };
  }
}

/// Representação do `TransactionRead`.
@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required int id,
    required int userId,
    required int accountId,
    required int categoryId,
    @JsonKey(unknownEnumValue: TransactionType.expense) required TransactionType type,
    @DecimalToDoubleConverter() required double amount,
    required DateTime date,
    String? description,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) PaymentMethod? paymentMethod,
    @Default(false) bool isRecurring,
    required DateTime createdAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
}

/// Página retornada por `GET /transactions`.
@freezed
abstract class TransactionPage with _$TransactionPage {
  const factory TransactionPage({
    @Default(<Transaction>[]) List<Transaction> items,
    required int total,
    required int page,
    required int pageSize,
  }) = _TransactionPage;

  factory TransactionPage.fromJson(Map<String, dynamic> json) => _$TransactionPageFromJson(json);
}

/// Conta (`AccountRead`) — modelo mínimo usado para popular selects/filtros.
@freezed
abstract class Account with _$Account {
  const factory Account({required int id, required String name}) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);
}

/// Categoria (`CategoryRead`) — modelo mínimo.
@freezed
abstract class Category with _$Category {
  const factory Category({
    required int id,
    required String name,
    @JsonKey(unknownEnumValue: TransactionType.expense) required TransactionType type,
    String? color,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}
