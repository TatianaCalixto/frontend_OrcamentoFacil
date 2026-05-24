import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/features/dashboard/application/dashboard_controller.dart';
import 'package:orcafacil_mobile/features/dashboard/data/dashboard_api.dart';

import '_fakes.dart';

void main() {
  group('DashboardController', () {
    test('estado inicial é DashboardInitial', () {
      final container = ProviderContainer(
        overrides: [
          dashboardApiProvider.overrideWithValue(FakeDashboardApi()),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(dashboardControllerProvider),
          isA<DashboardInitial>());
    });

    test('load() bem-sucedido transita para DashboardLoaded', () async {
      final api = FakeDashboardApi();
      final container = ProviderContainer(
        overrides: [dashboardApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final future =
          container.read(dashboardControllerProvider.notifier).load();
      expect(container.read(dashboardControllerProvider),
          isA<DashboardLoading>());
      await future;

      final state = container.read(dashboardControllerProvider);
      expect(state, isA<DashboardLoaded>());
      final loaded = state as DashboardLoaded;
      expect(loaded.data.summary.receitaTotal, 5000);
      expect(loaded.data.breakdown.items, hasLength(3));
      expect(api.summaryCalls, hasLength(1));
      expect(api.breakdownCalls, hasLength(1));
    });

    test('load() com falha vira DashboardError com mensagem', () async {
      final api = FakeDashboardApi(
        summaryHandler: ({month, year}) async {
          throw DashboardApiException('falha', statusCode: 500);
        },
      );
      final container = ProviderContainer(
        overrides: [dashboardApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await container.read(dashboardControllerProvider.notifier).load();
      final state = container.read(dashboardControllerProvider);
      expect(state, isA<DashboardError>());
      expect((state as DashboardError).message, 'falha');
    });

    test('refresh() repassa os mesmos month/year do último load', () async {
      final api = FakeDashboardApi();
      final container = ProviderContainer(
        overrides: [dashboardApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final controller =
          container.read(dashboardControllerProvider.notifier);
      await controller.load(month: 3, year: 2026);
      await controller.refresh();

      expect(api.summaryCalls, hasLength(2));
      expect(api.summaryCalls.last, {'month': 3, 'year': 2026});
      expect(api.breakdownCalls.last, {'month': 3, 'year': 2026});
    });
  });
}
