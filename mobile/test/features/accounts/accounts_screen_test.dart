import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/accounts/data/account_models.dart';
import 'package:orcafacil_mobile/features/accounts/data/accounts_api.dart';
import 'package:orcafacil_mobile/features/accounts/presentation/accounts_screen.dart';

import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/accounts',
    routes: [
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH_STUB'))),
      ),
      GoRoute(
        path: '/accounts/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NEW_STUB'))),
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('EDIT_${state.pathParameters['id']}')),
        ),
      ),
    ],
  );
}

Widget _wrap(FakeAccountsApi api) {
  return ProviderScope(
    overrides: [accountsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  group('AccountsScreen', () {
    testWidgets('estado vazio: mostra mensagem amigável', (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acc-empty')), findsOneWidget);
      expect(find.textContaining('Nenhuma conta cadastrada'), findsOneWidget);
    });

    testWidgets('estado de loading aparece antes da resposta', (tester) async {
      final completer = Completer<List<AccountFull>>();
      final api = FakeAccountsApi(listHandler: () => completer.future);
      await tester.pumpWidget(_wrap(api));
      await tester.pump();
      expect(find.byKey(const Key('acc-loading')), findsOneWidget);
      completer.complete(const []);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('acc-empty')), findsOneWidget);
    });

    testWidgets('estado com dados: lista contas e mostra saldo', (tester) async {
      final api = FakeAccountsApi(
        listHandler: () async => [
          sampleAccount(id: 1, name: 'Nubank', currentBalance: 1234.56),
          sampleAccount(
            id: 2,
            name: 'Carteira',
            type: AccountType.cash,
            currentBalance: 50.0,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acc-list')), findsOneWidget);
      expect(find.text('Nubank'), findsOneWidget);
      expect(find.text('Carteira'), findsOneWidget);
      // Formatação BRL com vírgula decimal.
      expect(find.textContaining('1.234,56'), findsOneWidget);
      expect(find.textContaining('50,00'), findsOneWidget);
      // Cada conta tem botão de delete.
      expect(find.byKey(const Key('acc-delete-1')), findsOneWidget);
      expect(find.byKey(const Key('acc-delete-2')), findsOneWidget);
    });

    testWidgets('estado de erro mostra mensagem e botão de tentar novamente',
        (tester) async {
      var calls = 0;
      final api = FakeAccountsApi(
        listHandler: () async {
          calls++;
          if (calls == 1) {
            throw AccountsApiException('falha de rede', statusCode: 500);
          }
          return [sampleAccount(id: 1, name: 'OK')];
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('acc-error')), findsOneWidget);
      expect(find.text('falha de rede'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      expect(calls, 2);
    });

    testWidgets('filtro Ativas esconde contas inativas', (tester) async {
      final api = FakeAccountsApi(
        listHandler: () async => [
          sampleAccount(id: 1, name: 'AtivaA', isActive: true),
          sampleAccount(id: 2, name: 'InativaB', isActive: false),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      // Default = Todas: as duas aparecem.
      expect(find.text('AtivaA'), findsOneWidget);
      expect(find.text('InativaB'), findsOneWidget);

      await tester.tap(find.text('Ativas'));
      await tester.pumpAndSettle();
      expect(find.text('AtivaA'), findsOneWidget);
      expect(find.text('InativaB'), findsNothing);

      await tester.tap(find.text('Inativas'));
      await tester.pumpAndSettle();
      expect(find.text('AtivaA'), findsNothing);
      expect(find.text('InativaB'), findsOneWidget);
    });

    testWidgets('confirmar delete remove item da lista', (tester) async {
      final api = FakeAccountsApi(
        listHandler: () async => [
          sampleAccount(id: 1, name: 'Nubank'),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('acc-confirm-delete')));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, [1]);
      expect(find.text('Nubank'), findsNothing);
    });

    testWidgets('cancelar delete mantém o item na lista', (tester) async {
      final api = FakeAccountsApi(
        listHandler: () async => [
          sampleAccount(id: 1, name: 'Nubank'),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, isEmpty);
      expect(find.text('Nubank'), findsOneWidget);
    });

    testWidgets('FAB navega para /accounts/new', (tester) async {
      final api = FakeAccountsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-btn-new')));
      await tester.pumpAndSettle();
      expect(find.text('NEW_STUB'), findsOneWidget);
    });

    testWidgets('tap em card navega para /accounts/:id/edit', (tester) async {
      final api = FakeAccountsApi(
        listHandler: () async => [
          sampleAccount(id: 7, name: 'Nubank'),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('acc-card-7')));
      await tester.pumpAndSettle();
      expect(find.text('EDIT_7'), findsOneWidget);
    });
  });
}
