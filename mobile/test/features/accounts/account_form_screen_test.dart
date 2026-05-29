import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/accounts/data/account_models.dart';
import 'package:orcafacil_mobile/features/accounts/data/accounts_api.dart';
import 'package:orcafacil_mobile/features/accounts/presentation/account_form_screen.dart';

import '_fakes.dart';

GoRouter _router({int? editId}) {
  return GoRouter(
    initialLocation: editId == null ? '/accounts/new' : '/accounts/$editId/edit',
    routes: [
      GoRoute(
        path: '/accounts',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIST_STUB'))),
      ),
      GoRoute(
        path: '/accounts/new',
        builder: (context, state) => const AccountFormScreen(),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AccountFormScreen(accountId: id);
        },
      ),
    ],
  );
}

Widget _wrap({required FakeAccountsApi api, int? editId}) {
  return ProviderScope(
    overrides: [accountsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router(editId: editId)),
  );
}

void main() {
  group('AccountFormScreen — criar', () {
    testWidgets('cria conta com nome, tipo e saldo inicial e navega para lista',
        (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acc-field-name')),
        'Nubank',
      );
      // Saldo inicial via vírgula (formato BR).
      await tester.enterText(
        find.byKey(const Key('acc-field-initial-balance')),
        '1.500,75',
      );

      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(api.createCalls, hasLength(1));
      expect(api.createCalls.first['name'], 'Nubank');
      expect(api.createCalls.first['type'], AccountType.checking);
      expect(api.createCalls.first['initial_balance'], 1500.75);
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('aceita saldo inicial com ponto decimal', (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acc-field-name')),
        'Carteira',
      );
      await tester.enterText(
        find.byKey(const Key('acc-field-initial-balance')),
        '50.25',
      );
      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(api.createCalls.first['initial_balance'], 50.25);
    });

    testWidgets('nome vazio mostra erro de validação e não chama API',
        (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      // Mantém valor default no saldo (0,00) e nome vazio.
      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('saldo inválido (texto) mostra erro e não chama API',
        (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acc-field-name')),
        'Qualquer',
      );
      await tester.enterText(
        find.byKey(const Key('acc-field-initial-balance')),
        'abc',
      );
      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Saldo inicial inválido'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('erro do backend exibe mensagem no form', (tester) async {
      final api = FakeAccountsApi(
        createHandler: ({required name, required type, required initialBalance}) async {
          throw AccountsApiException('nome já existe', statusCode: 409);
        },
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('acc-field-name')),
        'Repetida',
      );
      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acc-form-error')), findsOneWidget);
      expect(find.text('nome já existe'), findsOneWidget);
      expect(find.text('LIST_STUB'), findsNothing);
    });
  });

  group('AccountFormScreen — editar', () {
    testWidgets('pré-popula campos do GET e envia PATCH apenas com campos editáveis',
        (tester) async {
      final api = FakeAccountsApi(
        getHandler: (id) async => sampleAccount(
          id: id,
          name: 'Antigo',
          type: AccountType.savings,
          initialBalance: 200.00,
          currentBalance: 350.00,
          isActive: true,
        ),
      );
      await tester.pumpWidget(_wrap(api: api, editId: 7));
      await tester.pumpAndSettle();

      // Pré-população
      expect(find.text('Antigo'), findsOneWidget);
      // O campo de saldo inicial deve estar desabilitado mas mostrar o valor.
      final balanceField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('acc-field-initial-balance')),
          matching: find.byType(TextField),
        ),
      );
      expect(balanceField.enabled, isFalse);
      expect(balanceField.controller!.text, '200,00');

      // Edita o nome e o switch ativa.
      await tester.enterText(
        find.byKey(const Key('acc-field-name')),
        'Novo nome',
      );
      await tester.tap(find.byKey(const Key('acc-field-active')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      final call = api.updateCalls.first;
      expect(call['id'], 7);
      expect(call['name'], 'Novo nome');
      expect(call['type'], AccountType.savings);
      expect(call['is_active'], false);
      // Nenhuma chamada de create durante edição.
      expect(api.createCalls, isEmpty);
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('erro do backend durante PATCH exibe mensagem', (tester) async {
      final api = FakeAccountsApi(
        getHandler: (id) async => sampleAccount(id: id, name: 'Conta'),
        updateHandler: (id, {name, type, isActive}) async {
          throw AccountsApiException('falha PATCH', statusCode: 500);
        },
      );
      await tester.pumpWidget(_wrap(api: api, editId: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('falha PATCH'), findsOneWidget);
      expect(find.text('LIST_STUB'), findsNothing);
    });

    testWidgets('GET inicial com erro exibe mensagem no form', (tester) async {
      final api = FakeAccountsApi(
        getHandler: (id) async {
          throw AccountsApiException('conta não encontrada', statusCode: 404);
        },
      );
      await tester.pumpWidget(_wrap(api: api, editId: 99));
      await tester.pumpAndSettle();

      expect(find.text('conta não encontrada'), findsOneWidget);
    });
  });
}
