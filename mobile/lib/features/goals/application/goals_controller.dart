import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/goal_models.dart';
import '../data/goals_api.dart';

class GoalsState {
  const GoalsState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  factory GoalsState.initial() =>
      const GoalsState(items: [], isLoading: false);

  final List<Goal> items;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  GoalsState copyWith({
    List<Goal>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoalsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class GoalsController extends Notifier<GoalsState> {
  @override
  GoalsState build() => GoalsState.initial();

  GoalsApi get _api => ref.read(goalsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
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
