import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transactions_api.dart';
import 'package:orcafacil_mobile/features/transactions/presentation/transactions_list_screen.dart';

import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/transactions',
    routes: [
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsListScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASHBOARD_STUB'))),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NEW_STUB'))),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) =>
            Scaffold(body: Center(child: Text('EDIT_${state.pathParameters['id']}'))),
      ),
    ],
  );
}

Widget _wrap(FakeTransactionsApi api) {
  return ProviderScope(
    overrides: [transactionsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  group('TransactionsListScreen', () {
    testWidgets('estado vazio: mostra mensagem amigável', (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactions-empty')), findsOneWidget);
      expect(find.text('Nenhuma transação encontrada.'), findsOneWidget);
    });

    testWidgets('estado com dados: renderiza tiles e tem FAB para novo',
        (tester) async {
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: [
              sampleTransaction(id: 1, description: 'Mercado'),
              sampleTransaction(
                id: 2,
                description: 'Salário',
                type: TransactionType.income,
                amount: 5000,
              ),
            ],
            total: 2,
            page: 1,
            pageSize: pageSize,
          );
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactions-list')), findsOneWidget);
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Salário'), findsOneWidget);
      expect(find.byKey(const Key('btn-new-transaction')), findsOneWidget);
    });

    testWidgets('estado de loading aparece antes da resposta', (tester) async {
      final completer = Completer<TransactionPage>();
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) =>
            completer.future,
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pump(); // dispara postFrameCallback -> refresh -> loading

      expect(find.byKey(const Key('transactions-loading')), findsOneWidget);
      completer.complete(const TransactionPage(
        items: [],
        total: 0,
        page: 1,
        pageSize: 20,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('transactions-empty')), findsOneWidget);
    });

    testWidgets('estado de erro mostra mensagem e botão de tentar de novo',
        (tester) async {
      var calls = 0;
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          calls++;
          if (calls == 1) {
            throw TransactionsApiException('falha de rede', statusCode: 500);
          }
          return TransactionPage(
            items: [sampleTransaction(id: 1, description: 'OK')],
            total: 1,
            page: 1,
            pageSize: pageSize,
          );
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactions-error')), findsOneWidget);
      expect(find.text('falha de rede'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
      expect(calls, 2);
    });

    testWidgets('aplicar filtro de tipo via bottom-sheet reflete no payload',
        (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-open-filters')));
      await tester.pumpAndSettle();

      // Seleciona "Receita" no dropdown de tipo.
      await tester.tap(find.byKey(const Key('filter-type')));
      await tester.pumpAndSettle();
      // O DropdownButton abre overlay com items — duplicatas possíveis.
      await tester.tap(find.text('Receita').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();

      // A última chamada à API deve ter type=income.
      final lastFilters = api.listCalls.last['filters'] as TransactionFilters;
      expect(lastFilters.type, TransactionType.income);
    });

    testWidgets('busca textual via submit do TextField vira filtro.search',
        (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search-field')), 'aluguel');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final f = api.listCalls.last['filters'] as TransactionFilters;
      expect(f.search, 'aluguel');
    });

    testWidgets('scroll infinito chama loadMore quando chega no final',
        (tester) async {
      // Page 1 cheia (20 items) com total=25 -> hasMore=true.
      // Após scroll, page 2 com 5 items finaliza paginação.
      final page1 =
          List.generate(20, (i) => sampleTransaction(id: i + 1));
      final page2 =
          List.generate(5, (i) => sampleTransaction(id: 21 + i));
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: page == 1 ? page1 : page2,
            total: 25,
            page: page,
            pageSize: pageSize,
          );
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactions-list')), findsOneWidget);
      // Rola a lista até o final.
      await tester.drag(
          find.byKey(const Key('transactions-list')), const Offset(0, -5000));
      await tester.pumpAndSettle();

      // Deve ter chamado API duas vezes (page 1 + page 2).
      expect(api.listCalls.where((c) => c['page'] == 2), isNotEmpty);
    });
  });
}
