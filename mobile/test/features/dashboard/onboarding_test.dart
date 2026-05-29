import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/accounts/data/accounts_api.dart';
import 'package:orcafacil_mobile/features/dashboard/data/dashboard_api.dart';
import 'package:orcafacil_mobile/features/dashboard/presentation/dashboard_screen.dart';

import '../accounts/_fakes.dart' as acc_fakes;
import '_fakes.dart';

Widget _wrapDashboard({
  required acc_fakes.FakeAccountsApi accountsApi,
  FakeDashboardApi? dashboardApi,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
      GoRoute(
        path: '/accounts/new',
        builder: (c, s) =>
            const Scaffold(body: Center(child: Text('ACC_NEW_STUB'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      dashboardApiProvider.overrideWithValue(dashboardApi ?? FakeDashboardApi()),
      accountsApiProvider.overrideWithValue(accountsApi),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('Dashboard onboarding "Crie sua primeira conta"', () {
    testWidgets('usuário SEM conta vê o modal de onboarding', (tester) async {
      final api = acc_fakes.FakeAccountsApi(
        listHandler: () async => const [],
      );
      await tester.pumpWidget(_wrapDashboard(accountsApi: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-create-account')), findsOneWidget);
      expect(find.text('Crie sua primeira conta'), findsOneWidget);
      expect(find.byKey(const Key('onboarding-create')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-skip')), findsOneWidget);
    });

    testWidgets('usuário COM conta NÃO vê o modal de onboarding',
        (tester) async {
      final api = acc_fakes.FakeAccountsApi(
        listHandler: () async => [acc_fakes.sampleAccount(id: 1, name: 'Nubank')],
      );
      await tester.pumpWidget(_wrapDashboard(accountsApi: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-create-account')), findsNothing);
      expect(find.text('Crie sua primeira conta'), findsNothing);
    });

    testWidgets('"Pular por agora" fecha o modal E mostra snackbar de aviso',
        (tester) async {
      final api = acc_fakes.FakeAccountsApi(
        listHandler: () async => const [],
      );
      await tester.pumpWidget(_wrapDashboard(accountsApi: api));
      await tester.pumpAndSettle();

      // Modal está visível.
      expect(find.byKey(const Key('onboarding-create-account')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-skip')));
      // pumpAndSettle resolve a animação de saída do AlertDialog.
      await tester.pumpAndSettle();

      // Modal sumiu.
      expect(find.byKey(const Key('onboarding-create-account')), findsNothing);
      // Snackbar com aviso aparece (já está renderizado após settle).
      expect(
        find.text('Sem conta você não consegue lançar transações.'),
        findsOneWidget,
      );
    });

    testWidgets('"Criar conta" fecha modal e navega para /accounts/new',
        (tester) async {
      final api = acc_fakes.FakeAccountsApi(
        listHandler: () async => const [],
      );
      await tester.pumpWidget(_wrapDashboard(accountsApi: api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-create')));
      await tester.pumpAndSettle();

      expect(find.text('ACC_NEW_STUB'), findsOneWidget);
    });
  });
}
