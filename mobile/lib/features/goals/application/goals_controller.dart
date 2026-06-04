import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/goal_models.dart';
import '../data/goals_api.dart';

part 'goals_controller.freezed.dart';

@freezed
abstract class GoalsState with _$GoalsState {
  const GoalsState._();

  const factory GoalsState({
    required List<Goal> items,
    required bool isLoading,
    String? errorMessage,
  }) = _GoalsState;

  factory GoalsState.initial() =>
      const GoalsState(items: [], isLoading: false);

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;
}

class GoalsController extends Notifier<GoalsState> {
  @override
  GoalsState build() => GoalsState.initial();

  GoalsApi get _api => ref.read(goalsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _api.list();
      state = state.copyWith(items: items, isLoading: false);
    } on GoalsApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<Goal> create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
  }) async {
    final created = await _api.create(
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<Goal> update(
    int id, {
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    bool clearDeadline = false,
  }) async {
    final updated = await _api.update(
      id,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      clearDeadline: clearDeadline,
    );
    final next = [
      for (final g in state.items)
        if (g.id == id) updated else g,
    ];
    state = state.copyWith(items: next);
    return updated;
  }

  Future<void> delete(int id) async {
    await _api.delete(id);
    state = state.copyWith(items: state.items.where((g) => g.id != id).toList());
  }
}

final goalsControllerProvider =
    NotifierProvider<GoalsController, GoalsState>(GoalsController.new);
