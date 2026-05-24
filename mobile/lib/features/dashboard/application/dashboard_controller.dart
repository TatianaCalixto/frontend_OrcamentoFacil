import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_api.dart';
import '../data/dashboard_repository.dart';

/// Estado do Dashboard observado pela UI.
sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.data);
  final DashboardData data;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
}

/// Notifier do Dashboard — carrega resumo + breakdown e expõe pull-to-refresh.
class DashboardController extends Notifier<DashboardState> {
  int? _month;
  int? _year;

  @override
  DashboardState build() => const DashboardInitial();

  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  /// Dispara carregamento. Quando `month/year` são `null`, o backend usa o
  /// mês corrente.
  Future<void> load({int? month, int? year}) async {
    _month = month;
    _year = year;
    state = const DashboardLoading();
    try {
      final data = await _repo.load(month: month, year: year);
      state = DashboardLoaded(data);
    } on DashboardApiException catch (e) {
      state = DashboardError(e.message);
    }
  }

  /// Recarrega com os mesmos filtros (usado pelo pull-to-refresh).
  Future<void> refresh() => load(month: _month, year: _year);
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
  DashboardController.new,
);
