import 'package:freezed_annotation/freezed_annotation.dart';

import '../../transactions/data/transaction_models.dart' show TransactionType;

part 'category_models.freezed.dart';
part 'category_models.g.dart';

/// Categoria completa retornada por `GET /categories`.
@freezed
abstract class CategoryFull with _$CategoryFull {
  const factory CategoryFull({
    required int id,
    required int userId,
    required String name,
    @JsonKey(unknownEnumValue: TransactionType.expense) required TransactionType type,
    String? color,
    String? icon,
    @Default(false) bool isDefault,
  }) = _CategoryFull;

  factory CategoryFull.fromJson(Map<String, dynamic> json) => _$CategoryFullFromJson(json);
}
