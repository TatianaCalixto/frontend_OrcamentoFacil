import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/goals/data/goal_models.dart';
import 'package:orcafacil_mobile/features/goals/data/goals_api.dart';
import 'package:orcafacil_mobile/features/goals/presentation/goals_screen.dart';

import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/goals',
    routes: [
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH'))),
      ),
      GoRoute(
        path: '/goals/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('NEW_STUB'))),
      ),
      GoRoute(
        path: '/goals/:id/edit',
        builder: (context, state) => Scaffold(
          body: Center(child: Text('EDIT_${state.pathParameters['id']}')),
        ),
      ),
    ],
  );
}

Widget _wrap(FakeGoalsApi api) {
  return ProviderScope(
    overrides: [goalsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  group('GoalsScreen', () {
    testWidgets('estado vazio', (tester) async {
      final api = FakeGoalsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goal-empty')), findsOneWidget);
    });

    testWidgets('estado loading', (tester) async {
      final c = Completer<List<Goal>>();
      final api = FakeGoalsApi(listHandler: () => c.future);
      await tester.pumpWidget(_wrap(api));
      await tester.pump();
      expect(find.byKey(const Key('goal-loading')), findsOneWidget);
      c.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('estado de erro mostra mensagem', (tester) async {
      var calls = 0;
      final api = FakeGoalsApi(
        listHandler: () async {
          calls++;
          if (calls == 1) throw GoalsApiException('falha', statusCode: 500);
          return [sampleGoal(id: 1)];
        },
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goal-error')), findsOneWidget);
      expect(find.text('falha'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goal-list')), findsOneWidget);
    });

    testWidgets('progresso parcial e total — badge "Concluída" só quando 100%',
        (tester) async {
      final api = FakeGoalsApi(
        listHandler: () async => [
          sampleGoal(id: 1, name: 'Viagem', target: 5000, current: 1000),
          sampleGoal(
            id: 2,
            name: 'Reserva',
            target: 10000,
            current: 10000,
            status: GoalStatus.completed,
          ),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();
      expect(find.text('Viagem'), findsOneWidget);
      expect(find.text('Reserva'), findsOneWidget);
      // Apenas a concluída exibe o badge
      expect(find.byKey(const Key('goal-badge-completed')), findsOneWidget);
      // Porcentagens
      expect(find.text('20%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      // Botão "Somar valor" só na meta em andamento
      expect(find.byKey(const Key('goal-add-1')), findsOneWidget);
      expect(find.byKey(const Key('goal-add-2')), findsNothing);
    });

    testWidgets('somar valor chama update com soma correta', (tester) async {
      final api = FakeGoalsApi(
        listHandler: () async => [
          sampleGoal(id: 1, name: 'Viagem', target: 5000, current: 1000),
        ],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goal-add-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('goal-add-amount')), '500');
      await tester.tap(find.byKey(const Key('goal-confirm-add')));
      await tester.pumpAndSettle();

      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.first['id'], 1);
      expect(api.updateCalls.first['currentAmount'], 1500.0);
    });

    testWidgets('confirmar delete remove item', (tester) async {
      final api = FakeGoalsApi(
        listHandler: () async => [sampleGoal(id: 1, name: 'Viagem')],
      );
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('goal-delete-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal-confirm-delete')));
      await tester.pumpAndSettle();
      expect(api.deleteCalls, [1]);
      expect(find.text('Viagem'), findsNothing);
    });

    testWidgets('FAB navega para /goals/new', (tester) async {
      final api = FakeGoalsApi();
      await tester.pumpWidget(_wrap(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goal-btn-new')));
      await tester.pumpAndSettle();
      expect(find.text('NEW_STUB'), findsOneWidget);
    });
  });
}
