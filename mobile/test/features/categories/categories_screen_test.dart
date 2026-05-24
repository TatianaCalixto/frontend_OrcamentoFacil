import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/categories/data/categories_api.dart';
import 'package:orcafacil_mobile/features/categories/data/category_models.dart';
import 'package:orcafacil_mobile/features/categories/presentation/categories_screen.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';

import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/categories',
    routes: [
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH_STUB'))),
      ),
      GoRoute(
        path: '/categories/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NEW_STUB'))),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('EDIT_${state.pathParameters['id']}')),
        ),
      ),
    ],
  );
}

Widget _wrap(FakeCategoriesApi api) {
  return ProviderScope(
    overrides: [categoriesApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  group('CategoriesScreen', () {
    testWidgets('estado vazio: mostra mensagem amigável', (tester) async {
      final api = FakeCategoriesApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cat-empty')), findsOneWidget);
      expect(find.text('Nenhuma categoria cadastrada.'), findsOneWidget);
    });

    testWidgets('estado de loading aparece antes da resposta', (tester) async {
      final completer = Completer<List<CategoryFull>>();
      final api = FakeCategoriesApi(listHandler: () => completer.future);
      await tester.pumpWidget(_wrap(api));
      await tester.pump();
      expect(find.byKey(const Key('cat-loading')), findsOneWidget);
      completer.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cat-empty')), findsOneWidget);
    });

    testWidgets('estado com dados: separa por seções e mostra padrão',
        (tester) async {
      final api = FakeCategoriesApi(
        listHandler: () async => [
          sampleCategory(id: 1, name: 'Mercado'),
          sampleCategory(
            id: 2,
            name: 'Salário',
            type: TransactionType.income,
            color: '#3B82F6',
          ),
          sampleCategory(id: 3, name: 'Outros', isDefault: true),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cat-list')), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Salário'), findsOneWidget);
      expect(find.text('Despesas'), findsOneWidget);
      expect(find.text('Receitas'), findsOneWidget);
      expect(find.text('Padrão'), findsOneWidget);
      // Categoria padrão não tem botão de delete.
      expect(find.byKey(const Key('cat-delete-3')), findsNothing);
      expect(find.byKey(const Key('cat-delete-1')), findsOneWidget);
    });

    testWidgets('estado de erro mostra mensagem e botão de tentar novamente',
        (tester) async {
      var calls = 0;
      final api = FakeCategoriesApi(
        listHandler: () async {
          calls++;
          if (calls == 1) {
            throw CategoriesApiException('falha de rede', statusCode: 500);
          }
          return [sampleCategory(id: 1, name: 'OK')];
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cat-error')), findsOneWidget);
      expect(find.text('falha de rede'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      expect(calls, 2);
    });

    testWidgets('confirmar delete remove item da lista', (tester) async {
      final api = FakeCategoriesApi(
        listHandler: () async => [
          sampleCategory(id: 1, name: 'Mercado'),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cat-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cat-confirm-delete')));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, [1]);
      expect(find.text('Mercado'), findsNothing);
    });

    testWidgets('FAB navega para /categories/new', (tester) async {
      final api = FakeCategoriesApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cat-btn-new')));
      await tester.pumpAndSettle();
      expect(find.text('NEW_STUB'), findsOneWidget);
    });
  });
}
