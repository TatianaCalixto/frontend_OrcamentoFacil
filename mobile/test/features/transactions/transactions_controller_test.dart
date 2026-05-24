import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/features/transactions/application/transactions_controller.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transactions_api.dart';

import '_fakes.dart';

void main() {
  group('TransactionsController', () {
    test('refresh() carrega página 1 e marca hasMore=false quando vem menos '
        'que o pageSize', () async {
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: [sampleTransaction(id: 1)],
            total: 1,
            page: 1,
            pageSize: pageSize,
          );
        },
      );
      final container = ProviderContainer(
        overrides: [transactionsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await container.read(transactionsControllerProvider.notifier).refresh();
      final state = container.read(transactionsControllerProvider);
      expect(state.items, hasLength(1));
      expect(state.page, 1);
      expect(state.total, 1);
      expect(state.hasMore, isFalse);
      expect(state.errorMessage, isNull);
      expect(api.listCalls, hasLength(1));
      expect(api.listCalls.first['page'], 1);
    });

    test('loadMore() avança para a página 2 e concatena resultados', () async {
      final pages = <int, List<Transaction>>{
        1: List.generate(20, (i) => sampleTransaction(id: i + 1)),
        2: List.generate(5, (i) => sampleTransaction(id: 21 + i)),
      };
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: pages[page] ?? const [],
            total: 25,
            page: page,
            pageSize: pageSize,
          );
        },
      );
      final container = ProviderContainer(
        overrides: [transactionsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(transactionsControllerProvider.notifier);
      await ctrl.refresh();
      expect(
          container.read(transactionsControllerProvider).items, hasLength(20));
      expect(container.read(transactionsControllerProvider).hasMore, isTrue);

      await ctrl.loadMore();
      final st = container.read(transactionsControllerProvider);
      expect(st.items, hasLength(25));
      expect(st.page, 2);
      expect(st.hasMore, isFalse);
    });

    test('applyFilters() reseta para página 1 com os novos filtros', () async {
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: [sampleTransaction(id: 1)],
            total: 1,
            page: 1,
            pageSize: pageSize,
          );
        },
      );
      final container = ProviderContainer(
        overrides: [transactionsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(transactionsControllerProvider.notifier);
      await ctrl.applyFilters(const TransactionFilters(
        accountId: 7,
        type: TransactionType.income,
        search: 'aluguel',
      ));
      final st = container.read(transactionsControllerProvider);
      expect(st.filters.accountId, 7);
      expect(st.filters.type, TransactionType.income);
      expect(st.filters.search, 'aluguel');
      expect(api.listCalls.last['page'], 1);
      final f = api.listCalls.last['filters'] as TransactionFilters;
      expect(f.accountId, 7);
      expect(f.type, TransactionType.income);
      expect(f.search, 'aluguel');
    });

    test('erro em refresh() preenche errorMessage e isLoading=false', () async {
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          throw TransactionsApiException('offline', statusCode: 0);
        },
      );
      final container = ProviderContainer(
        overrides: [transactionsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      await container.read(transactionsControllerProvider.notifier).refresh();
      final st = container.read(transactionsControllerProvider);
      expect(st.errorMessage, 'offline');
      expect(st.isLoading, isFalse);
      expect(st.items, isEmpty);
    });

    test('delete() remove da lista e decrementa total', () async {
      final api = FakeTransactionsApi(
        listHandler: ({required filters, required page, pageSize = 20}) async {
          return TransactionPage(
            items: [sampleTransaction(id: 1), sampleTransaction(id: 2)],
            total: 2,
            page: 1,
            pageSize: pageSize,
          );
        },
      );
      final container = ProviderContainer(
        overrides: [transactionsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(transactionsControllerProvider.notifier);
      await ctrl.refresh();
      await ctrl.delete(1);
      final st = container.read(transactionsControllerProvider);
      expect(st.items.map((t) => t.id), [2]);
      expect(st.total, 1);
      expect(api.deleteCalls, [1]);
    });
  });
}
