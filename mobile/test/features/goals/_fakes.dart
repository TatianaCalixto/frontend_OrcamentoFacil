import 'package:orcafacil_mobile/features/goals/data/goal_models.dart';
import 'package:orcafacil_mobile/features/goals/data/goals_api.dart';

class FakeGoalsApi implements GoalsApi {
  FakeGoalsApi({
    this.listHandler,
    this.createHandler,
    this.updateHandler,
    this.deleteHandler,
  });

  Future<List<Goal>> Function()? listHandler;
  Future<Goal> Function({
    required String name,
    required double targetAmount,
    double currentAmount,
    DateTime? deadline,
  })? createHandler;
  Future<Goal> Function(
    int id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    bool clearDeadline,
  })? updateHandler;
  Future<void> Function(int id)? deleteHandler;

  final List<Map<String, dynamic>> createCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  final List<int> deleteCalls = [];

  @override
  Future<List<Goal>> list() {
    if (listHandler != null) return listHandler!();
    return Future.value(const []);
  }

  @override
  Future<Goal> create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
  }) {
    createCalls.add({
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline,
    });
    if (createHandler != null) {
      return createHandler!(
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
      );
    }
    return Future.value(sampleGoal(
      id: 999,
      name: name,
      target: targetAmount,
      current: currentAmount,
      deadline: deadline,
    ));
  }

  @override
  Future<Goal> update(
    int id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    bool clearDeadline = false,
  }) {
    updateCalls.add({
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline,
      'clearDeadline': clearDeadline,
    });
    if (updateHandler != null) {
      return updateHandler!(
        id,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        clearDeadline: clearDeadline,
      );
    }
    return Future.value(sampleGoal(
      id: id,
      name: name ?? 'Meta',
      target: targetAmount ?? 1000,
      current: currentAmount ?? 0,
      deadline: deadline,
    ));
  }

  @override
  Future<void> delete(int id) {
    deleteCalls.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    return Future.value();
  }
}

Goal sampleGoal({
  required int id,
  String name = 'Viagem',
  double target = 5000,
  double current = 1000,
  DateTime? deadline,
  GoalStatus status = GoalStatus.inProgress,
}) {
  return Goal(
    id: id,
    userId: 1,
    name: name,
    targetAmount: target,
    currentAmount: current,
    deadline: deadline,
    status: status,
  );
}
