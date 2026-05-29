import 'package:orcafacil_mobile/features/accounts/data/account_models.dart';
import 'package:orcafacil_mobile/features/accounts/data/accounts_api.dart';

/// Fake configurável do `AccountsApi` para uso em widget/unit tests.
class FakeAccountsApi implements AccountsApi {
  FakeAccountsApi({
    this.listHandler,
    this.getHandler,
    this.createHandler,
    this.updateHandler,
    this.deleteHandler,
  });

  Future<List<AccountFull>> Function()? listHandler;
  Future<AccountFull> Function(int id)? getHandler;
  Future<AccountFull> Function({
    required String name,
    required AccountType type,
    required double initialBalance,
  })? createHandler;
  Future<AccountFull> Function(
    int id, {
    String? name,
    AccountType? type,
    bool? isActive,
  })? updateHandler;
  Future<void> Function(int id)? deleteHandler;

  final List<Map<String, dynamic>> createCalls = [];
  final List<Map<String, dynamic>> updateCalls = [];
  final List<int> deleteCalls = [];
  final List<int> getCalls = [];
  int listCalls = 0;

  @override
  Future<List<AccountFull>> list() {
    listCalls++;
    if (listHandler != null) return listHandler!();
    return Future.value(const []);
  }

  @override
  Future<AccountFull> get(int id) {
    getCalls.add(id);
    if (getHandler != null) return getHandler!(id);
    return Future.value(sampleAccount(id: id));
  }

  @override
  Future<AccountFull> create({
    required String name,
    required AccountType type,
    required double initialBalance,
  }) {
    createCalls.add({
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
    });
    if (createHandler != null) {
      return createHandler!(
        name: name,
        type: type,
        initialBalance: initialBalance,
      );
    }
    return Future.value(sampleAccount(
      id: 999,
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
    ));
  }

  @override
  Future<AccountFull> update(
    int id, {
    String? name,
    AccountType? type,
    bool? isActive,
  }) {
    updateCalls.add({
      'id': id,
      'name': name,
      'type': type,
      'is_active': isActive,
    });
    if (updateHandler != null) {
      return updateHandler!(
        id,
        name: name,
        type: type,
        isActive: isActive,
      );
    }
    return Future.value(sampleAccount(
      id: id,
      name: name ?? 'Atualizada',
      type: type ?? AccountType.checking,
      isActive: isActive ?? true,
    ));
  }

  @override
  Future<void> delete(int id) {
    deleteCalls.add(id);
    if (deleteHandler != null) return deleteHandler!(id);
    return Future.value();
  }
}

AccountFull sampleAccount({
  required int id,
  String name = 'Conta',
  AccountType type = AccountType.checking,
  double initialBalance = 100.0,
  double currentBalance = 100.0,
  bool isActive = true,
}) {
  return AccountFull(
    id: id,
    userId: 1,
    name: name,
    type: type,
    initialBalance: initialBalance,
    currentBalance: currentBalance,
    isActive: isActive,
  );
}
