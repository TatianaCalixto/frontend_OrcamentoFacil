/// Tipos de conta suportados pelo backend (`AccountType`).
enum AccountType { checking, savings, creditCard, cash }

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
class AccountFull {
  AccountFull({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.currentBalance,
    required this.isActive,
  });

  factory AccountFull.fromJson(Map<String, dynamic> json) {
    return AccountFull(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      type: AccountTypeX.fromApi(json['type'] as String),
      initialBalance: _toDouble(json['initial_balance']),
      currentBalance: _toDouble(json['current_balance']),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  final int id;
  final int userId;
  final String name;
  final AccountType type;
  final double initialBalance;
  final double currentBalance;
  final bool isActive;
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
