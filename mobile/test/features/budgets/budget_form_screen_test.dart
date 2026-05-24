import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/budgets/application/budgets_controller.dart';
import 'package:orcafacil_mobile/features/budgets/data/budgets_api.dart';
import 'package:orcafacil_mobile/features/budgets/presentation/budget_form_screen.dart';
import 'package:orcafacil_mobile/features/categories/data/categories_api.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';

import '../categories/_fakes.dart' as cat_fakes;
import '_fakes.dart';

GoRouter _router({int? editId}) {
  return GoRouter(
    initialLocation: editId == null ? '/budgets/new' : '/budgets/$editId/edit',
    routes: [
      GoRoute(
        path: '/budgets',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIST_STUB'))),
      ),
      GoRoute(
        path: '/budgets/new',
        builder: (context, state) => const BudgetFormScreen(),
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BudgetFormScreen(budgetId: id);
        },
      ),
    ],
  );
}

Widget _wrap({
  required FakeBudgetsApi api,
  required cat_fakes.FakeCategoriesApi catsApi,
  int? editId,
}) {
  return ProviderScope(
    overrides: [
      budgetsApiProvider.overrideWithValue(api),
      categoriesApiProvider.overrideWithValue(catsApi),
    ],
    child: MaterialApp.router(routerConfig: _router(editId: editId)),
  );
}

void main() {
  group('BudgetFormScreen', () {
    testWidgets('cria orçamento com categoria + limite', (tester) async {
      final api = FakeBudgetsApi();
      final catsApi = cat_fakes.FakeCategoriesApi(
        listHandler: () async => [
          cat_fakes.sampleCategory(
            id: 5,
            name: 'Mercado',
            type: TransactionType.expense,
          ),
          // Receita não aparece no dropdown
          cat_fakes.sampleCategory(
            id: 6,
            name: 'Salário',
            type: TransactionType.income,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(api: api, catsApi: catsApi));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('budget-field-category')));
      await tester.pumpAndSettle();
      // Salário (income) NÃO deve estar na lista de opções (despesa-only)
      expect(find.text('Salário'), findsNothing);
      await tester.tap(find.text('Mercado').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('budget-field-limit')),
        '500,00',
      );
      await tester.tap(find.byKey(const Key('budget-form-submit')));
      await tester.pumpAndSettle();

      expect(api.createCalls, hasLength(1));
      expect(api.createCalls.first['categoryId'], 5);
      expect(api.createCalls.first['limitAmount'], 500.0);
    });

    testWidgets('limite inválido bloqueia submit', (tester) async {
      final api = FakeBudgetsApi();
      final catsApi = cat_fakes.FakeCategoriesApi(
        listHandler: () async => [cat_fakes.sampleCategory(id: 5, name: 'Mercado')],
      );
      await tester.pumpWidget(_wrap(api: api, catsApi: catsApi));
      await tester.pumpAndSettle();

      // sem selecionar categoria e sem limite
      await tester.tap(find.byKey(const Key('budget-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Informe um valor válido'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('erro do backend exibe mensagem no form', (tester) async {
      final api = FakeBudgetsApi(
        createHandler: ({
          required categoryId,
          required month,
          required year,
          required limitAmount,
        }) async {
          throw BudgetsApiException('já existe', statusCode: 409);
        },
      );
      final catsApi = cat_fakes.FakeCategoriesApi(
        listHandler: () async => [cat_fakes.sampleCategory(id: 5, name: 'Mercado')],
      );
      await tester.pumpWidget(_wrap(api: api, catsApi: catsApi));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('budget-field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mercado').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('budget-field-limit')),
        '300,00',
      );
      await tester.tap(find.byKey(const Key('budget-form-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('budget-form-error')), findsOneWidget);
      expect(find.text('já existe'), findsOneWidget);
    });

    testWidgets('edição pré-popula limite e chama update', (tester) async {
      final api = FakeBudgetsApi();
      final catsApi = cat_fakes.FakeCategoriesApi();
      final container = ProviderContainer(
        overrides: [
          budgetsApiProvider.overrideWithValue(api),
          categoriesApiProvider.overrideWithValue(catsApi),
        ],
      );
      addTearDown(container.dispose);

      api.listHandler = ({required month, required year}) async => [
            sampleBudget(id: 99, categoryId: 1, limit: 800, used: 400),
          ];
      await container.read(budgetsControllerProvider.notifier).refresh();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router(editId: 99)),
        ),
      );
      await tester.pumpAndSettle();

      // Pré-popula
      expect(find.text('800.00'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('budget-field-limit')),
        '1000,00',
      );
      await tester.tap(find.byKey(const Key('budget-form-submit')));
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.first['id'], 99);
      expect(api.updateCalls.first['limitAmount'], 1000.0);
    });
  });
}
