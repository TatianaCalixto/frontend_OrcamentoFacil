import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/budgets/data/budget_models.dart';
import 'package:orcafacil_mobile/features/budgets/data/budgets_api.dart';
import 'package:orcafacil_mobile/features/budgets/presentation/budgets_screen.dart';
import 'package:orcafacil_mobile/features/categories/data/categories_api.dart';

import '../categories/_fakes.dart' as cat_fakes;
import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/budgets',
    routes: [
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH'))),
      ),
      GoRoute(
        path: '/budgets/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NEW'))),
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('EDIT_${state.pathParameters['id']}')),
        ),
      ),
    ],
  );
}

Widget _wrap({
  required FakeBudgetsApi api,
  cat_fakes.FakeCategoriesApi? catsApi,
}) {
  return ProviderScope(
    overrides: [
      budgetsApiProvider.overrideWithValue(api),
      categoriesApiProvider.overrideWithValue(catsApi ?? cat_fakes.FakeCategoriesApi()),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  group('BudgetsScreen', () {
    testWidgets('estado vazio: mostra mensagem amigável', (tester) async {
      final api = FakeBudgetsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('budget-empty')), findsOneWidget);
    });

    testWidgets('estado loading aparece antes da resposta', (tester) async {
      final c = Completer<List<BudgetWithUsage>>();
      final api = FakeBudgetsApi(
        listHandler: ({required month, required year}) => c.future,
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pump();
      expect(find.byKey(const Key('budget-loading')), findsOneWidget);
      c.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('estado de erro mostra mensagem e botão tentar novamente',
        (tester) async {
      var calls = 0;
      final api = FakeBudgetsApi(
        listHandler: ({required month, required year}) async {
          calls++;
          if (calls == 1) {
            throw BudgetsApiException('falha', statusCode: 500);
          }
          return [sampleBudget(id: 1)];
        },
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('budget-error')), findsOneWidget);
      expect(find.text('falha'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('budget-list')), findsOneWidget);
    });

    testWidgets('mostra status ok/warning/critical com cores próprias',
        (tester) async {
      final api = FakeBudgetsApi(
        listHandler: ({required month, required year}) async => [
          sampleBudget(
            id: 1,
            categoryId: 10,
            limit: 800,
            used: 200,
            percent: 25,
            status: BudgetStatus.ok,
          ),
          sampleBudget(
            id: 2,
            categoryId: 11,
            limit: 500,
            used: 400,
            percent: 80,
            status: BudgetStatus.warning,
          ),
          sampleBudget(
            id: 3,
            categoryId: 12,
            limit: 300,
            used: 350,
            percent: 117,
            status: BudgetStatus.critical,
          ),
        ],
      );
      final catsApi = cat_fakes.FakeCategoriesApi(
        listHandler: () async => [
          cat_fakes.sampleCategory(id: 10, name: 'Mercado'),
          cat_fakes.sampleCategory(id: 11, name: 'Lazer'),
          cat_fakes.sampleCategory(id: 12, name: 'Transporte'),
        ],
      );
      await tester.pumpWidget(_wrap(api: api, catsApi: catsApi));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('budget-list')), findsOneWidget);
      // Os três status estão renderizados
      expect(find.byKey(const Key('budget-status-ok')), findsOneWidget);
      expect(find.byKey(const Key('budget-status-warning')), findsOneWidget);
      expect(find.byKey(const Key('budget-status-critical')), findsOneWidget);
      // Nomes de categorias resolvidos via categoriesController
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Lazer'), findsOneWidget);
      // Porcentagens
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('117%'), findsOneWidget);
    });

    testWidgets('FAB navega para /budgets/new', (tester) async {
      final api = FakeBudgetsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('budget-btn-new')));
      await tester.pumpAndSettle();
      expect(find.text('NEW'), findsOneWidget);
    });
  });
}
