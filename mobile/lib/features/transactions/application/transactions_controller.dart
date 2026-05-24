import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_models.dart';
import '../data/transactions_api.dart';

/// Estado da lista paginada de transações.
class TransactionsState {
  const TransactionsState({
    required this.filters,
    required this.items,
    required this.page,
    required this.total,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.errorMessage,
  });

  factory TransactionsState.initial() => const TransactionsState(
        filters: TransactionFilters(),
        items: [],
        page: 0,
        total: 0,
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
      );

  final TransactionFilters filters;
  final List<Transaction> items;
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  TransactionsState copyWith({
    TransactionFilters? filters,
    List<Transaction>? items,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TransactionsState(
      filters: filters ?? this.filters,
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
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
      clearError: true,
    );
    await refresh();
  }

  /// Recarrega da página 1 mantendo os filtros atuais.
  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      page: 0,
      clearError: true,
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
    state = state.copyWith(isLoadingMore: true, clearError: true);
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
