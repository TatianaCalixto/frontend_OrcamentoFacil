import '../../transactions/data/transaction_models.dart' show TransactionType, TransactionTypeX;

/// Categoria completa retornada por `GET /categories`.
class CategoryFull {
  CategoryFull({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.color,
    this.icon,
    required this.isDefault,
  });

  factory CategoryFull.fromJson(Map<String, dynamic> json) {
    return CategoryFull(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      type: TransactionTypeX.fromApi(json['type'] as String),
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      isDefault: (json['is_default'] as bool?) ?? false,
    );
  }

  final int id;
  final int userId;
  final String name;
  final TransactionType type;
  final String? color;
  final String? icon;
  final bool isDefault;
}
