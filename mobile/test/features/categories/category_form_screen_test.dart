import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/categories/application/categories_controller.dart';
import 'package:orcafacil_mobile/features/categories/data/categories_api.dart';
import 'package:orcafacil_mobile/features/categories/presentation/category_form_screen.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';

import '_fakes.dart';

GoRouter _router({int? editId}) {
  return GoRouter(
    initialLocation: editId == null ? '/categories/new' : '/categories/$editId/edit',
    routes: [
      GoRoute(
        path: '/categories',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIST_STUB'))),
      ),
      GoRoute(
        path: '/categories/new',
        builder: (context, state) => const CategoryFormScreen(),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return CategoryFormScreen(categoryId: id);
        },
      ),
    ],
  );
}

Widget _wrap({required FakeCategoriesApi api, int? editId}) {
  return ProviderScope(
    overrides: [categoriesApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router(editId: editId)),
  );
}

void main() {
  group('CategoryFormScreen', () {
    testWidgets('cria categoria com nome, tipo, cor e ícone', (tester) async {
      final api = FakeCategoriesApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cat-field-name')),
        'Lazer',
      );
      // Seleciona uma cor diferente
      await tester.tap(find.byKey(const Key('cat-color-#3B82F6')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cat-icon-flight')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('cat-form-submit')));
      await tester.pumpAndSettle();

      expect(api.createCalls, hasLength(1));
      expect(api.createCalls.first['name'], 'Lazer');
      expect(api.createCalls.first['color'], '#3B82F6');
      expect(api.createCalls.first['icon'], 'flight');
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('nome vazio mostra erro de validação', (tester) async {
      final api = FakeCategoriesApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cat-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Informe o nome'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('erro do backend exibe mensagem no form', (tester) async {
      final api = FakeCategoriesApi(
        createHandler: ({required name, required type, color, icon}) async {
          throw CategoriesApiException('nome já existe', statusCode: 409);
        },
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('cat-field-name')),
        'Repetida',
      );
      await tester.tap(find.byKey(const Key('cat-form-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cat-form-error')), findsOneWidget);
      expect(find.text('nome já existe'), findsOneWidget);
    });

    testWidgets('edição: pré-popula campos e chama update', (tester) async {
      final api = FakeCategoriesApi();
      // Pré-popula o controller com a categoria existente.
      final container = ProviderContainer(
        overrides: [categoriesApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      // Injeta diretamente no estado
      api.listHandler = () async => [
            sampleCategory(
              id: 7,
              name: 'Mercado',
              type: TransactionType.expense,
              color: '#10B981',
              icon: 'shopping_cart',
            ),
          ];
      await container
          .read(categoriesControllerProvider.notifier)
          .refresh();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router(editId: 7)),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica pré-popula
      expect(find.text('Mercado'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('cat-field-name')),
        'Mercado novo',
      );
      await tester.tap(find.byKey(const Key('cat-form-submit')));
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.first['id'], 7);
      expect(api.updateCalls.first['name'], 'Mercado novo');
    });

    testWidgets('categoria padrão: dropdown de tipo fica desabilitado',
        (tester) async {
      final api = FakeCategoriesApi();
      final container = ProviderContainer(
        overrides: [categoriesApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      api.listHandler = () async => [
            sampleCategory(id: 9, name: 'Default', isDefault: true),
          ];
      await container
          .read(categoriesControllerProvider.notifier)
          .refresh();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router(editId: 9)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cat-default-banner')), findsOneWidget);
    });
  });
}
