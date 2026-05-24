/// Tipo da transação no backend.
enum TransactionType { income, expense }

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
enum PaymentMethod { cash, debit, credit, pix, transfer, other }

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

/// Representação do TransactionRead.
class Transaction {
  Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.paymentMethod,
    required this.isRecurring,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      accountId: json['account_id'] as int,
      categoryId: json['category_id'] as int,
      type: TransactionTypeX.fromApi(json['type'] as String),
      amount: _toDouble(json['amount']),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      paymentMethod: PaymentMethodX.fromApi(json['payment_method'] as String?),
      isRecurring: (json['is_recurring'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int userId;
  final int accountId;
  final int categoryId;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? description;
  final PaymentMethod? paymentMethod;
  final bool isRecurring;
  final DateTime createdAt;
}

/// Página retornada por `GET /transactions`.
class TransactionPage {
  TransactionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory TransactionPage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return TransactionPage(
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(Transaction.fromJson)
          .toList(growable: false),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
    );
  }

  final List<Transaction> items;
  final int total;
  final int page;
  final int pageSize;
}

/// Conta (`AccountRead`) — modelo mínimo usado para popular selects/filtros.
class Account {
  Account({required this.id, required this.name});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

/// Categoria (`CategoryRead`) — modelo mínimo.
class Category {
  Category({
    required this.id,
    required this.name,
    required this.type,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      type: TransactionTypeX.fromApi(json['type'] as String),
      color: json['color'] as String?,
    );
  }

  final int id;
  final String name;
  final TransactionType type;
  final String? color;
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
