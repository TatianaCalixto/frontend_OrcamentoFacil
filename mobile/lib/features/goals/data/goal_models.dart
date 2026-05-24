enum GoalStatus { inProgress, completed }

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

class Goal {
  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.status,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    final rawDeadline = json['deadline'] as String?;
    return Goal(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      targetAmount: _toDouble(json['target_amount']),
      currentAmount: _toDouble(json['current_amount']),
      deadline: rawDeadline == null ? null : DateTime.parse(rawDeadline),
      status: GoalStatusX.fromApi(json['status'] as String),
    );
  }

  final int id;
  final int userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalStatus status;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1).toDouble();
  }
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
