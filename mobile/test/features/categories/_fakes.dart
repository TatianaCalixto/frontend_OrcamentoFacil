import 'package:orcafacil_mobile/features/categories/data/categories_api.dart';
import 'package:orcafacil_mobile/features/categories/data/category_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';

/// Fake configurável do `CategoriesApi` para uso em widget/unit tests.
class FakeCategoriesApi implements CategoriesApi {
  FakeCategoriesApi({
    this.listHandler,
    this.createHandler,
    this.updateHandler,
    this.deleteHandler,
  });

  Future<List<CategoryFull>> Function()? listHandler;
  Future<CategoryFull> Function({
    required String name,
    required TransactionType type,
    String? color,
    String? icon,
  })? createHandler;
  Future<CategoryFull> Function(
    int id, {
    String? name,
    TransactionType? type,
    String? color,
    String? icon,
  })? updateHandler;
  Future<void> Function(int id)? deleteHandler;

  final List<Map<String, dynamic>> createCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  final List<int> deleteCalls = [];
  int listCalls = 0;

  @override
  Future<List<CategoryFull>> list() {
    listCalls++;
    if (listHandler != null) return listHandler!();
    return Future.value(const []);
  }

  @override
  Future<CategoryFull> create({
    required String name,
    required TransactionType type,
    String? color,
    String? icon,
  }) {
    createCalls.add({
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    });
    if (createHandler != null) {
      return createHandler!(name: name, type: type, color: color, icon: icon);
    }
    return Future.value(sampleCategory(
      id: 999,
      name: name,
      type: type,
      color: color,
      icon: icon,
    ));
  }

  @override
  Future<CategoryFull> update(
    int id, {
    String? name,
    TransactionType? type,
    String? color,
    String? icon,
  }) {
    updateCalls.add({
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
    });
    if (updateHandler != null) {
      return updateHandler!(
        id,
        name: name,
        type: type,
        color: color,
        icon: icon,
      );
    }
    return Future.value(sampleCategory(
      id: id,
      name: name ?? 'Atualizada',
      type: type ?? TransactionType.expense,
      color: color,
      icon: icon,
    ));
  }

  @override
  Future<void> delete(int id) {
    deleteCalls.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    return Future.value();
  }
}

CategoryFull sampleCategory({
  required int id,
  String name = 'Categoria',
  TransactionType type = TransactionType.expense,
  String? color = '#10B981',
  String? icon = 'shopping_cart',
  bool isDefault = false,
}) {
  return CategoryFull(
    id: id,
    userId: 1,
    name: name,
    type: type,
    color: color,
    icon: icon,
    isDefault: isDefault,
  );
}
