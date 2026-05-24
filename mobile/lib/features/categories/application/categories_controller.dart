import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/data/transaction_models.dart' show TransactionType;
import '../data/categories_api.dart';
import '../data/category_models.dart';

/// Estado da listagem de categorias.
class CategoriesState {
  const CategoriesState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  factory CategoriesState.initial() =>
      const CategoriesState(items: [], isLoading: false);

  final List<CategoryFull> items;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;

  CategoriesState copyWith({
    List<CategoryFull>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoriesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Controller que mantém a lista de categorias e expõe CRUD.
class CategoriesController extends Notifier<CategoriesState> {
  @override
  CategoriesState build() => CategoriesState.initial();

  CategoriesApi get _api => ref.read(categoriesApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _api.list();
      state = state.copyWith(items: items, isLoading: false);
    } on CategoriesApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<CategoryFull> create({
    required String name,
    required TransactionType type,
    String? color,
    String? icon,
  }) async {
    final created = await _api.create(
      name: name,
      type: type,
      color: color,
      icon: icon,
    );
    state = state.copyWith(items: [...state.items, created]);
    return created;
  }

  Future<CategoryFull> update(
    int id, {
    String? name,
    TransactionType? type,
    String? color,
    String? icon,
  }) async {
    final updated = await _api.update(
      id,
      name: name,
      type: type,
      color: color,
      icon: icon,
    );
    final next = [
      for (final c in state.items)
        if (c.id == id) updated else c,
    ];
    state = state.copyWith(items: next);
    return updated;
  }

  Future<void> delete(int id) async {
    await _api.delete(id);
    state = state.copyWith(items: state.items.where((c) => c.id != id).toList());
  }
}

final categoriesControllerProvider =
    NotifierProvider<CategoriesController, CategoriesState>(
  CategoriesController.new,
);
