import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/json/converters.dart';

part 'goal_models.freezed.dart';
part 'goal_models.g.dart';

enum GoalStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
}

extension GoalStatusX on GoalStatus {
  String get apiValue => switch (this) {
        GoalStatus.inProgress => 'in_progress',
        GoalStatus.completed => 'completed',
      };

  String get label => switch (this) {
        GoalStatus.inProgress => 'Em andamento',
        GoalStatus.completed => 'Concluída',
      };

  static GoalStatus fromApi(String raw) => switch (raw) {
        'in_progress' => GoalStatus.inProgress,
        'completed' => GoalStatus.completed,
        _ => GoalStatus.inProgress,
      };
}

@freezed
abstract class Goal with _$Goal {
  // Construtor privado: habilita getters/metodos customizados (progress).
  const Goal._();

  const factory Goal({
    required int id,
    required int userId,
    required String name,
    @DecimalToDoubleConverter() required double targetAmount,
    @DecimalToDoubleConverter() required double currentAmount,
    DateTime? deadline,
    @JsonKey(unknownEnumValue: GoalStatus.inProgress) required GoalStatus status,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1).toDouble();
  }
}
