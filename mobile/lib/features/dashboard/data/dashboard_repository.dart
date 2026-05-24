import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_api.dart';

/// Conjunto carregado pelo Dashboard — combina resumo mensal e quebra por
/// categoria em uma única estrutura para a UI consumir.
class DashboardData {
  DashboardData({
    required this.summary,
    required this.breakdown,
  });

  final MonthlySummary summary;
  final CategoryBreakdown breakdown;
}

/// Orquestra as chamadas paralelas dos endpoints do dashboard.
class DashboardRepository {
  DashboardRepository(this._api);

  final DashboardApi _api;

  Future<DashboardData> load({int? month, int? year}) async {
    final results = await Future.wait([
      _api.monthlySummary(month: month, year: year),
      _api.categoryBreakdown(month: month, year: year),
    ]);
    return DashboardData(
      summary: results[0] as MonthlySummary,
      breakdown: results[1] as CategoryBreakdown,
    );
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardApiProvider));
});
