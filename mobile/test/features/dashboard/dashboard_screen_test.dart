import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/features/dashboard/data/dashboard_api.dart';
import 'package:orcafacil_mobile/features/dashboard/presentation/dashboard_screen.dart';

import '_fakes.dart';

Widget _wrap({
  required FakeDashboardApi api,
}) {
  return ProviderScope(
    overrides: [
      dashboardApiProvider.overrideWithValue(api),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
}

void main() {
  group('DashboardScreen', () {
    testWidgets('mostra loading e depois cards + chart', (tester) async {
      // Usa Completers para segurar a resposta da API e poder observar o
      // estado de loading antes da resolução.
      final summaryCompleter = Completer<MonthlySummary>();
      final breakdownCompleter = Completer<CategoryBreakdown>();
      final api = FakeDashboardApi(
        summaryHandler: ({month, year}) => summaryCompleter.future,
        breakdownHandler: ({month, year}) => breakdownCompleter.future,
      );
      await tester.pumpWidget(_wrap(api: api));

      // Dispara o postFrameCallback que chama load() — vai para Loading.
      await tester.pump();
      expect(find.byKey(const Key('dashboard-loading')), findsOneWidget);

      // Resolve as duas promises e deixa a UI assentar.
      summaryCompleter.complete(MonthlySummary(
        month: 5,
        year: 2026,
        receitaTotal: 5000,
        despesaTotal: 3200,
        saldo: 1800,
        contas: [
          AccountSummary(
            accountId: 1,
            name: 'Conta principal',
            currentBalance: 7200,
          ),
        ],
      ));
      breakdownCompleter.complete(CategoryBreakdown(
        month: 5,
        year: 2026,
        items: [
          CategoryBreakdownItem(
            categoryId: 1,
            name: 'Alimentação',
            color: '#FF5722',
            total: 1500,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-loaded')), findsOneWidget);
      expect(find.byKey(const Key('card-saldo-total')), findsOneWidget);
      expect(find.byKey(const Key('card-saldo-mes')), findsOneWidget);
      expect(find.byKey(const Key('card-receita')), findsOneWidget);
      expect(find.byKey(const Key('card-despesa')), findsOneWidget);
      expect(find.byKey(const Key('chart-loaded')), findsOneWidget);
      // Valores formatados em BRL aparecem.
      expect(find.textContaining('R\$'), findsWidgets);
    });

    testWidgets('quando breakdown vem vazio, mostra estado vazio do chart',
        (tester) async {
      final api = FakeDashboardApi(
        breakdownHandler: ({month, year}) async => CategoryBreakdown(
          month: 5,
          year: 2026,
          items: const [],
        ),
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chart-empty')), findsOneWidget);
      expect(find.text('Sem despesas no período.'), findsOneWidget);
      // Cards continuam aparecendo.
      expect(find.byKey(const Key('card-receita')), findsOneWidget);
    });

    testWidgets('em caso de erro mostra mensagem e botão de tentar de novo',
        (tester) async {
      var attempts = 0;
      final api = FakeDashboardApi(
        summaryHandler: ({month, year}) async {
          attempts++;
          if (attempts == 1) {
            throw DashboardApiException('Erro de rede', statusCode: 500);
          }
          return MonthlySummary(
            month: 5,
            year: 2026,
            receitaTotal: 100,
            despesaTotal: 50,
            saldo: 50,
            contas: const [],
          );
        },
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-error')), findsOneWidget);
      expect(find.text('Erro de rede'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      // Após retry bem-sucedido, vai para loaded.
      expect(find.byKey(const Key('dashboard-loaded')), findsOneWidget);
      expect(attempts, 2);
    });

    testWidgets('formatBrl produz string com R\$ e vírgula decimal',
        (tester) async {
      expect(formatBrl(1234.5), 'R\$ 1.234,50');
      expect(formatBrl(0), 'R\$ 0,00');
      expect(formatBrl(-12.3), '-R\$ 12,30');
    });
  });
}
