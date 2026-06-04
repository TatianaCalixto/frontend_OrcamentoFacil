import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/budget_models.dart';
import '../data/budgets_api.dart';

part 'budgets_controller.freezed.dart';

@freezed
abstract class BudgetsState with _$BudgetsState {
  const BudgetsState._();

  const factory BudgetsState({
    required int month,
    required int year,
    required List<BudgetWithUsage> items,
    required bool isLoading,
    String? errorMessage,
  }) = _BudgetsState;

  factory BudgetsState.initial() {
    final now = DateTime.now();
    return BudgetsState(
      month: now.month,
      year: now.year,
      items: const [],
      isLoading: false,
    );
  }

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;
}

class BudgetsController extends Notifier<BudgetsState> {
  @override
  BudgetsState build() => BudgetsState.initial();

  BudgetsApi get _api => ref.read(budgetsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _api.list(month: state.month, year: state.year);
      state = state.copyWith(items: items, isLoading: false);
    } on BudgetsApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> changePeriod({required int month, required int year}) async {
    state = state.copyWith(month: month, year: year, items: const []);
    await refresh();
  }

  Future<BudgetRead> create({
    required int categoryId,
    required double limitAmount,
    int? month,
    int? year,
  }) async {
    final created = await _api.create(
      categoryId: categoryId,
      month: month ?? state.month,
      year: year ?? state.year,
      limitAmount: limitAmount,
    );
    await refresh();
    return created;
  }

  Future<BudgetRead> update(int id, {required double limitAmount}) async {
    final updated = await _api.update(id, limitAmount: limitAmount);
    await refresh();
    return updated;
  }
}

final budgetsControllerProvider =
    NotifierProvider<BudgetsController, BudgetsState>(BudgetsController.new);
