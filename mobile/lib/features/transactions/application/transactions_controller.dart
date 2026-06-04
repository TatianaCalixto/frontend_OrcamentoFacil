import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/transaction_models.dart';
import '../data/transactions_api.dart';

part 'transactions_controller.freezed.dart';

/// Estado da lista paginada de transações.
@freezed
abstract class TransactionsState with _$TransactionsState {
  const TransactionsState._();

  const factory TransactionsState({
    required TransactionFilters filters,
    required List<Transaction> items,
    required int page,
    required int total,
    required bool isLoading,
    required bool isLoadingMore,
    required bool hasMore,
    String? errorMessage,
  }) = _TransactionsState;

  factory TransactionsState.initial() => const TransactionsState(
        filters: TransactionFilters(),
        items: [],
        page: 0,
        total: 0,
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
      );

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;
}

/// Controller de lista de transações com paginação por scroll infinito.
class TransactionsController extends Notifier<TransactionsState> {
  static const _pageSize = 20;

  @override
  TransactionsState build() => TransactionsState.initial();

  TransactionsApi get _api => ref.read(transactionsApiProvider);

  /// Substitui os filtros e recarrega da página 1.
  Future<void> applyFilters(TransactionFilters filters) async {
    state = state.copyWith(
      filters: filters,
      items: [],
      page: 0,
      hasMore: true,
      errorMessage: null,
    );
    await refresh();
  }

  /// Recarrega da página 1 mantendo os filtros atuais.
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      page: 0,
      errorMessage: null,
    );
    try {
      final result = await _api.list(
        filters: state.filters,
        page: 1,
        pageSize: _pageSize,
      );
      state = state.copyWith(
        items: result.items,
        page: result.page,
        total: result.total,
        hasMore: result.items.length >= _pageSize &&
            result.items.length < result.total,
        isLoading: false,
      );
    } on TransactionsApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    }
  }

  /// Avança para a próxima página (scroll infinito). Não faz nada quando já
  /// não há mais resultados ou há outro carregamento em andamento.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final result = await _api.list(
        filters: state.filters,
        page: nextPage,
        pageSize: _pageSize,
      );
      final all = [...state.items, ...result.items];
      state = state.copyWith(
        items: all,
        page: result.page,
        total: result.total,
        hasMore: result.items.length >= _pageSize && all.length < result.total,
        isLoadingMore: false,
      );
    } on TransactionsApiException catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.message,
      );
    }
  }

  /// Remove uma transação por id e atualiza a lista localmente.
  Future<void> delete(int id) async {
    await _api.delete(id);
    final next = state.items.where((t) => t.id != id).toList();
    state = state.copyWith(
      items: next,
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }
}

final transactionsControllerProvider =
    NotifierProvider<TransactionsController, TransactionsState>(
  TransactionsController.new,
);

/// Provider que carrega contas para popular o filtro/select.
final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.watch(transactionsApiProvider).listAccounts();
});

/// Provider que carrega categorias.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(transactionsApiProvider).listCategories();
});
