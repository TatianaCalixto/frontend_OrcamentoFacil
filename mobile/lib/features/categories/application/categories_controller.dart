import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../transactions/data/transaction_models.dart' show TransactionType;
import '../data/categories_api.dart';
import '../data/category_models.dart';

part 'categories_controller.freezed.dart';

/// Estado da listagem de categorias.
@freezed
abstract class CategoriesState with _$CategoriesState {
  const CategoriesState._();

  const factory CategoriesState({
    required List<CategoryFull> items,
    required bool isLoading,
    String? errorMessage,
  }) = _CategoriesState;

  factory CategoriesState.initial() =>
      const CategoriesState(items: [], isLoading: false);

  bool get isEmpty => !isLoading && items.isEmpty && errorMessage == null;
  bool get hasError => errorMessage != null;
}

/// Controller que mantém a lista de categorias e expõe CRUD.
class CategoriesController extends Notifier<CategoriesState> {
  @override
  CategoriesState build() => CategoriesState.initial();

  CategoriesApi get _api => ref.read(categoriesApiProvider);

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
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
