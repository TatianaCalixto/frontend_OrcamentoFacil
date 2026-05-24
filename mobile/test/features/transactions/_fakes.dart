import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transactions_api.dart';

/// Fake configurável do `TransactionsApi` para uso em widget e unit tests.
class FakeTransactionsApi implements TransactionsApi {
  FakeTransactionsApi({
    this.listHandler,
    this.getByIdHandler,
    this.createHandler,
    this.updateHandler,
    this.deleteHandler,
    this.accountsHandler,
    this.categoriesHandler,
  });

  Future<TransactionPage> Function({
    required TransactionFilters filters,
    required int page,
    int pageSize,
  })? listHandler;

  Future<Transaction> Function(int id)? getByIdHandler;

  Future<Transaction> Function({
    required int accountId,
    required int categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? description,
    PaymentMethod? paymentMethod,
    bool isRecurring,
  })? createHandler;

  Future<Transaction> Function(
    int id, {
    int? accountId,
    int? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? description,
    PaymentMethod? paymentMethod,
    bool? isRecurring,
  })? updateHandler;

  Future<void> Function(int id)? deleteHandler;
  Future<List<Account>> Function()? accountsHandler;
  Future<List<Category>> Function()? categoriesHandler;

  final List<Map<String, dynamic>> listCalls = [];
  final List<int> deleteCalls = [];
  final List<Map<String, dynamic>> createCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];

  @override
  Future<TransactionPage> list({
    required TransactionFilters filters,
    required int page,
    int pageSize = 20,
  }) {
    listCalls.add({
      'filters': filters,
      'page': page,
      'pageSize': pageSize,
    });
    if (listHandler != null) {
      return listHandler!(filters: filters, page: page, pageSize: pageSize);
    }
    return Future.value(TransactionPage(
      items: const [],
      total: 0,
      page: page,
      pageSize: pageSize,
    ));
  }

  @override
  Future<Transaction> getById(int id) {
    if (getByIdHandler != null) return getByIdHandler!(id);
    return Future.value(sampleTransaction(id: id));
  }

  @override
  Future<Transaction> create({
    required int accountId,
    required int categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? description,
    PaymentMethod? paymentMethod,
    bool isRecurring = false,
  }) {
    createCalls.add({
      'accountId': accountId,
      'categoryId': categoryId,
      'type': type,
      'amount': amount,
      'date': date,
      'description': description,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
    });
    if (createHandler != null) {
      return createHandler!(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
      );
    }
    return Future.value(sampleTransaction(
      id: 999,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date,
      description: description,
    ));
  }

  @override
  Future<Transaction> update(
    int id, {
    int? accountId,
    int? categoryId,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? description,
    PaymentMethod? paymentMethod,
    bool? isRecurring,
  }) {
    updateCalls.add({
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'type': type,
      'amount': amount,
      'date': date,
      'description': description,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
    });
    if (updateHandler != null) {
      return updateHandler!(
        id,
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        isRecurring: isRecurring,
      );
    }
    return Future.value(sampleTransaction(id: id));
  }

  @override
  Future<void> delete(int id) {
    deleteCalls.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    return Future.value();
  }

  @override
  Future<List<Account>> listAccounts() {
    if (accountsHandler != null) return accountsHandler!();
    return Future.value([Account(id: 1, name: 'Conta principal')]);
  }

  @override
  Future<List<Category>> listCategories() {
    if (categoriesHandler != null) return categoriesHandler!();
    return Future.value([
      Category(id: 1, name: 'Alimentação', type: TransactionType.expense),
    ]);
  }
}

/// Helper para construir transações nos testes.
Transaction sampleTransaction({
  required int id,
  int accountId = 1,
  int categoryId = 1,
  TransactionType type = TransactionType.expense,
  double amount = 100,
  DateTime? date,
  String? description,
}) {
  return Transaction(
    id: id,
    userId: 1,
    accountId: accountId,
    categoryId: categoryId,
    type: type,
    amount: amount,
    date: date ?? DateTime(2026, 5, 1),
    description: description ?? 'Transação $id',
    paymentMethod: PaymentMethod.pix,
    isRecurring: false,
    createdAt: DateTime(2026, 5, 1, 10),
  );
}
