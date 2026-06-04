import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/json/converters.dart';

part 'budget_models.freezed.dart';
part 'budget_models.g.dart';

/// Status do orçamento conforme `BudgetWithUsage`.
enum BudgetStatus {
  @JsonValue('ok')
  ok,
  @JsonValue('warning')
  warning,
  @JsonValue('critical')
  critical,
}

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
@freezed
abstract class BudgetWithUsage with _$BudgetWithUsage {
  const factory BudgetWithUsage({
    required int id,
    required int userId,
    required int categoryId,
    required int month,
    required int year,
    @DecimalToDoubleConverter() required double limitAmount,
    @DecimalToDoubleConverter() required double usedAmount,
    @DecimalToDoubleConverter() required double percentUsed,
    @JsonKey(unknownEnumValue: BudgetStatus.ok) required BudgetStatus status,
  }) = _BudgetWithUsage;

  factory BudgetWithUsage.fromJson(Map<String, dynamic> json) => _$BudgetWithUsageFromJson(json);
}

/// Resposta de criação (`BudgetRead`) — não contém uso.
@freezed
abstract class BudgetRead with _$BudgetRead {
  const factory BudgetRead({
    required int id,
    required int userId,
    required int categoryId,
    required int month,
    required int year,
    @DecimalToDoubleConverter() required double limitAmount,
  }) = _BudgetRead;

  factory BudgetRead.fromJson(Map<String, dynamic> json) => _$BudgetReadFromJson(json);
}
