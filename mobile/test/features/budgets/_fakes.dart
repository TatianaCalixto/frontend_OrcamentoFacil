import 'package:orcafacil_mobile/features/budgets/data/budget_models.dart';
import 'package:orcafacil_mobile/features/budgets/data/budgets_api.dart';

class FakeBudgetsApi implements BudgetsApi {
  FakeBudgetsApi({
    this.listHandler,
    this.createHandler,
    this.updateHandler,
    this.getByIdHandler,
  });

  Future<List<BudgetWithUsage>> Function({required int month, required int year})?
      listHandler;
  Future<BudgetRead> Function({
    required int categoryId,
    required int month,
    required int year,
    required double limitAmount,
  })? createHandler;
  Future<BudgetRead> Function(int id, {required double limitAmount})?
      updateHandler;
  Future<BudgetWithUsage> Function(int id)? getByIdHandler;

  final List<Map<String, dynamic>> listCalls = [];
  final List<Map<String, dynamic>> createCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<List<BudgetWithUsage>> list({required int month, required int year}) {
    listCalls.add({'month': month, 'year': year});
    if (listHandler != null) return listHandler!(month: month, year: year);
    return Future.value(const []);
  }

  @override
  Future<BudgetRead> create({
    required int categoryId,
    required int month,
    required int year,
    required double limitAmount,
  }) {
    createCalls.add({
      'categoryId': categoryId,
      'month': month,
      'year': year,
      'limitAmount': limitAmount,
    });
    if (createHandler != null) {
      return createHandler!(
        categoryId: categoryId,
        month: month,
        year: year,
        limitAmount: limitAmount,
      );
    }
    return Future.value(BudgetRead(
      id: 1,
      userId: 1,
      categoryId: categoryId,
      month: month,
      year: year,
      limitAmount: limitAmount,
    ));
  }

  @override
  Future<BudgetRead> update(int id, {required double limitAmount}) {
    updateCalls.add({'id': id, 'limitAmount': limitAmount});
    if (updateHandler != null) {
      return updateHandler!(id, limitAmount: limitAmount);
    }
    return Future.value(BudgetRead(
      id: id,
      userId: 1,
      categoryId: 1,
      month: 5,
      year: 2026,
      limitAmount: limitAmount,
    ));
  }

  @override
  Future<BudgetWithUsage> getById(int id) {
    if (getByIdHandler != null) return getByIdHandler!(id);
    return Future.value(sampleBudget(id: id));
  }
}

BudgetWithUsage sampleBudget({
  required int id,
  int categoryId = 1,
  int month = 5,
  int year = 2026,
  double limit = 800,
  double used = 200,
  double percent = 25,
  BudgetStatus status = BudgetStatus.ok,
}) {
  return BudgetWithUsage(
    id: id,
    userId: 1,
    categoryId: categoryId,
    month: month,
    year: year,
    limitAmount: limit,
    usedAmount: used,
    percentUsed: percent,
    status: status,
  );
}
