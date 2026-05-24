import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transactions_api.dart';
import 'package:orcafacil_mobile/features/transactions/presentation/transaction_form_screen.dart';

import '_fakes.dart';

GoRouter _router(Widget child) {
  return GoRouter(
    initialLocation: '/x',
    routes: [
      GoRoute(path: '/x', builder: (context, state) => child),
      GoRoute(
        path: '/transactions',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIST_STUB'))),
      ),
    ],
  );
}

Widget _wrap(FakeTransactionsApi api, Widget child) {
  return ProviderScope(
    overrides: [transactionsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router(child)),
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  // O formulário é mais alto que a viewport de teste (600px). Garante que o
  // botão fique visível antes de tapar para evitar warning de hit-test.
  await tester.ensureVisible(find.byKey(const Key('btn-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('btn-submit')));
}

void main() {
  group('TransactionFormScreen - criar', () {
    testWidgets('validação: campos obrigatórios bloqueiam submit',
        (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api, const TransactionFormScreen()));
      await tester.pumpAndSettle();

      await _tapSubmit(tester);
      await tester.pump();

      expect(find.text('Informe o valor'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('valor inválido (zero ou texto) é rejeitado', (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api, const TransactionFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field-amount')), '0');
      await _tapSubmit(tester);
      await tester.pump();
      expect(find.text('Valor inválido'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('cria transação com sucesso e navega para a lista',
        (tester) async {
      final api = FakeTransactionsApi();
      await tester.pumpWidget(_wrap(api, const TransactionFormScreen()));
      await tester.pumpAndSettle();

      // Preenche o valor.
      await tester.enterText(find.byKey(const Key('field-amount')), '123,45');
      await tester.enterText(
          find.byKey(const Key('field-description')), 'Mercado');

      // Seleciona conta no dropdown.
      await tester.tap(find.byKey(const Key('field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();

      // Seleciona categoria.
      await tester.tap(find.byKey(const Key('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alimentação').last);
      await tester.pumpAndSettle();

      // Submete.
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.createCalls, hasLength(1));
      final call = api.createCalls.first;
      expect(call['accountId'], 1);
      expect(call['categoryId'], 1);
      expect(call['type'], TransactionType.expense);
      expect(call['amount'], 123.45);
      expect(call['description'], 'Mercado');
      // Após sucesso, navega para a lista (stub renderiza 'LIST_STUB').
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('erro de criação exibe mensagem do backend', (tester) async {
      final api = FakeTransactionsApi(
        createHandler: ({
          required accountId,
          required categoryId,
          required type,
          required amount,
          required date,
          description,
          paymentMethod,
          isRecurring = false,
        }) async {
          throw TransactionsApiException('valor muito alto', statusCode: 422);
        },
      );
      await tester.pumpWidget(_wrap(api, const TransactionFormScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field-amount')), '50');
      await tester.tap(find.byKey(const Key('field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alimentação').last);
      await tester.pumpAndSettle();

      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('valor muito alto'), findsOneWidget);
    });
  });

  group('TransactionFormScreen - editar', () {
    testWidgets('carrega dados existentes e atualiza ao salvar',
        (tester) async {
      final api = FakeTransactionsApi(
        getByIdHandler: (id) async => sampleTransaction(
          id: id,
          amount: 75,
          description: 'Padaria',
        ),
      );
      await tester
          .pumpWidget(_wrap(api, const TransactionFormScreen(transactionId: 42)));
      await tester.pumpAndSettle();

      // O valor pré-carregado aparece formatado com vírgula.
      expect(find.text('75,00'), findsOneWidget);
      expect(find.text('Padaria'), findsOneWidget);
      expect(find.text('Atualizar'), findsOneWidget);

      // Submete sem alterar nada.
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.first['id'], 42);
      expect(api.updateCalls.first['amount'], 75.0);
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('botão excluir confirma e chama API', (tester) async {
      final api = FakeTransactionsApi(
        getByIdHandler: (id) async => sampleTransaction(id: id),
      );
      await tester
          .pumpWidget(_wrap(api, const TransactionFormScreen(transactionId: 9)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-delete')));
      await tester.pumpAndSettle();

      // Diálogo de confirmação.
      expect(find.text('Excluir transação?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(api.deleteCalls, [9]);
      expect(find.text('LIST_STUB'), findsOneWidget);
    });

    testWidgets('erro no GET inicial exibe mensagem e mantém formulário vazio',
        (tester) async {
      final api = FakeTransactionsApi(
        getByIdHandler: (id) async {
          throw TransactionsApiException('não encontrado', statusCode: 404);
        },
      );
      await tester
          .pumpWidget(_wrap(api, const TransactionFormScreen(transactionId: 7)));
      await tester.pumpAndSettle();

      expect(find.text('não encontrado'), findsOneWidget);
    });
  });
}
