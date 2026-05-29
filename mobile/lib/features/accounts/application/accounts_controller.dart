import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account_models.dart';
import '../data/accounts_api.dart';

/// Filtro de visibilidade da lista.
enum AccountsFilter { all, active, inactive }

/// Estado da listagem de contas.
class AccountsState {
  const AccountsState({
    required this.items,
    required this.isLoading,
    required this.filter,
    this.errorMessage,
  });

  factory AccountsState.initial() => const AccountsState(
        items: [],
        isLoading: false,
        filter: AccountsFilter.all,
      );

  final List<AccountFull> items;
  final bool isLoading;
  final AccountsFilter filter;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  /// Itens após aplicar `filter`.
  List<AccountFull> get visibleItems {
    return switch (filter) {
      AccountsFilter.all => items,
      AccountsFilter.active => items.where((a) => a.isActive).toList(growable: false),
      AccountsFilter.inactive => items.where((a) => !a.isActive).toList(growable: false),
    };
  }

  AccountsState copyWith({
    List<AccountFull>? items,
    bool? isLoading,
    AccountsFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AccountsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Controller que mantém a lista de contas e expõe CRUD.
class AccountsController extends Notifier<AccountsState> {
  @override
  AccountsState build() => AccountsState.initial();

  AccountsApi get _api => ref.read(accountsApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _api.list();
      state = state.copyWith(items: items, isLoading: false);
    } on AccountsApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void setFilter(AccountsFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<AccountFull> create({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) async {
    final created = await _api.create(
      name: name,
      type: type,
      initialBalance: initialBalance,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<AccountFull> update(
    int id, {
    String? name,
    AccountType? type,
    bool? isActive,
  }) async {
    final updated = await _api.update(
      id,
      name: name,
      type: type,
      isActive: isActive,
    );
    final next = [
      for (final a in state.items)
        if (a.id == id) updated else a,
    ];
    state = state.copyWith(items: next);
    return updated;
  }

  Future<void> delete(int id) async {
    await _api.delete(id);
    state = state.copyWith(items: state.items.where((a) => a.id != id).toList());
  }
}

final accountsControllerProvider =
    NotifierProvider<AccountsController, AccountsState>(
  AccountsController.new,
);
