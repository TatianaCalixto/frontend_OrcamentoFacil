/// Status do orçamento conforme `BudgetWithUsage`.
enum BudgetStatus { ok, warning, critical }

extension BudgetStatusX on BudgetStatus {
  String get apiValue => switch (this) {
        BudgetStatus.ok => 'ok',
        BudgetStatus.warning => 'warning',
        BudgetStatus.critical => 'critical',
      };

  String get label => switch (this) {
        BudgetStatus.ok => 'Em dia',
        BudgetStatus.warning => 'Atenção',
        BudgetStatus.critical => 'Estourado',
      };

  static BudgetStatus fromApi(String raw) => switch (raw) {
        'ok' => BudgetStatus.ok,
        'warning' => BudgetStatus.warning,
        'critical' => BudgetStatus.critical,
        _ => BudgetStatus.ok,
      };
}

/// Orçamento com uso (`BudgetWithUsage` do backend).
class BudgetWithUsage {
  BudgetWithUsage({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitAmount,
    required this.usedAmount,
    required this.percentUsed,
    required this.status,
  });

  factory BudgetWithUsage.fromJson(Map<String, dynamic> json) {
    return BudgetWithUsage(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      limitAmount: _toDouble(json['limit_amount']),
      usedAmount: _toDouble(json['used_amount']),
      percentUsed: _toDouble(json['percent_used']),
      status: BudgetStatusX.fromApi(json['status'] as String),
    );
  }

  final int id;
  final int userId;
  final int categoryId;
  final int month;
  final int year;
  final double limitAmount;
  final double usedAmount;
  final double percentUsed;
  final BudgetStatus status;
}

/// Resposta de criação (`BudgetRead`) — não contém uso.
class BudgetRead {
  BudgetRead({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitAmount,
  });

  factory BudgetRead.fromJson(Map<String, dynamic> json) {
    return BudgetRead(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      limitAmount: _toDouble(json['limit_amount']),
    );
  }

  final int id;
  final int userId;
  final int categoryId;
  final int month;
  final int year;
  final double limitAmount;
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
