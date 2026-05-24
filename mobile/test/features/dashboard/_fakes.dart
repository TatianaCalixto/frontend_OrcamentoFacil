import 'package:orcafacil_mobile/features/dashboard/data/dashboard_api.dart';

/// Fake configurável para o `DashboardApi`. Permite simular sucesso, erro e
/// retornos vazios sem dependência do Dio real.
class FakeDashboardApi implements DashboardApi {
  FakeDashboardApi({
    this.summaryHandler,
    this.breakdownHandler,
  });

  Future<MonthlySummary> Function({int? month, int? year})? summaryHandler;
  Future<CategoryBreakdown> Function({int? month, int? year})?
      breakdownHandler;

  final List<Map<String, int?>> summaryCalls = [];
  final List<Map<String, int?>> breakdownCalls = [];

  @override
  Future<MonthlySummary> monthlySummary({int? month, int? year}) {
    summaryCalls.add({'month': month, 'year': year});
    if (summaryHandler != null) {
      return summaryHandler!(month: month, year: year);
    }
    return Future.value(_defaultSummary);
  }

  @override
  Future<CategoryBreakdown> categoryBreakdown({int? month, int? year}) {
    breakdownCalls.add({'month': month, 'year': year});
    if (breakdownHandler != null) {
      return breakdownHandler!(month: month, year: year);
    }
    return Future.value(_defaultBreakdown);
  }
}

final _defaultSummary = MonthlySummary(
  month: 5,
  year: 2026,
  receitaTotal: 5000,
  despesaTotal: 3200,
  saldo: 1800,
  contas: [
    AccountSummary(accountId: 1, name: 'Conta principal', currentBalance: 7200),
  ],
);

final _defaultBreakdown = CategoryBreakdown(
  month: 5,
  year: 2026,
  items: [
    CategoryBreakdownItem(
      categoryId: 1,
      name: 'Alimentação',
      color: '#FF5722',
      total: 1500,
    ),
    CategoryBreakdownItem(
      categoryId: 2,
      name: 'Transporte',
      color: '#3F51B5',
      total: 800,
    ),
    CategoryBreakdownItem(
      categoryId: 3,
      name: 'Lazer',
      color: null,
      total: 900,
    ),
  ],
);
