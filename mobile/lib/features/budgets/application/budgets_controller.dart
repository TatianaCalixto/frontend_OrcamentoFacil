import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/budget_models.dart';
import '../data/budgets_api.dart';

class BudgetsState {
  const BudgetsState({
    required this.month,
    required this.year,
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  factory BudgetsState.initial() {
    final now = DateTime.now();
    return BudgetsState(
      month: now.month,
      year: now.year,
      items: const [],
      isLoading: false,
    );
  }

  final int month;
  final int year;
  final List<BudgetWithUsage> items;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  BudgetsState copyWith({
    int? month,
    int? year,
    List<BudgetWithUsage>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BudgetsState(
      month: month ?? this.month,
      year: year ?? this.year,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BudgetsController extends Notifier<BudgetsState> {
  @override
  BudgetsState build() => BudgetsState.initial();

  BudgetsApi get _api => ref.read(budgetsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
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
