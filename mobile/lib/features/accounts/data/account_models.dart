import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/json/converters.dart';

part 'account_models.freezed.dart';
part 'account_models.g.dart';

/// Tipos de conta suportados pelo backend (`AccountType`).
enum AccountType {
  @JsonValue('checking')
  checking,
  @JsonValue('savings')
  savings,
  @JsonValue('credit_card')
  creditCard,
  @JsonValue('cash')
  cash,
}

extension AccountTypeX on AccountType {
  String get apiValue => switch (this) {
        AccountType.checking => 'checking',
        AccountType.savings => 'savings',
        AccountType.creditCard => 'credit_card',
        AccountType.cash => 'cash',
      };

  String get label => switch (this) {
        AccountType.checking => 'Corrente',
        AccountType.savings => 'Poupança',
        AccountType.creditCard => 'Cartão',
        AccountType.cash => 'Dinheiro',
      };

  static AccountType fromApi(String raw) => switch (raw) {
        'checking' => AccountType.checking,
        'savings' => AccountType.savings,
        'credit_card' => AccountType.creditCard,
        'cash' => AccountType.cash,
        _ => AccountType.checking,
      };
}

/// Conta completa retornada por `GET /accounts`.
@freezed
abstract class AccountFull with _$AccountFull {
  const factory AccountFull({
    required int id,
    required int userId,
    required String name,
    @JsonKey(unknownEnumValue: AccountType.checking) required AccountType type,
    @DecimalToDoubleConverter() required double initialBalance,
    @DecimalToDoubleConverter() required double currentBalance,
    @Default(true) bool isActive,
  }) = _AccountFull;

  factory AccountFull.fromJson(Map<String, dynamic> json) => _$AccountFullFromJson(json);
}
