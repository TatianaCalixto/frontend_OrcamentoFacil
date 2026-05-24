import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/goals/application/goals_controller.dart';
import 'package:orcafacil_mobile/features/goals/data/goals_api.dart';
import 'package:orcafacil_mobile/features/goals/presentation/goal_form_screen.dart';

import '_fakes.dart';

GoRouter _router({int? editId}) {
  return GoRouter(
    initialLocation: editId == null ? '/goals/new' : '/goals/$editId/edit',
    routes: [
      GoRoute(
        path: '/goals',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LIST_STUB'))),
      ),
      GoRoute(
        path: '/goals/new',
        builder: (context, state) => const GoalFormScreen(),
      ),
      GoRoute(
        path: '/goals/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return GoalFormScreen(goalId: id);
        },
      ),
    ],
  );
}

Widget _wrap({required FakeGoalsApi api, int? editId}) {
  return ProviderScope(
    overrides: [goalsApiProvider.overrideWithValue(api)],
    child: MaterialApp.router(routerConfig: _router(editId: editId)),
  );
}

void main() {
  group('GoalFormScreen', () {
    testWidgets('cria meta com nome + alvo + atual', (tester) async {
      final api = FakeGoalsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('goal-field-name')),
        'Viagem',
      );
      await tester.enterText(
        find.byKey(const Key('goal-field-target')),
        '5000',
      );
      await tester.enterText(
        find.byKey(const Key('goal-field-current')),
        '500',
      );
      await tester.tap(find.byKey(const Key('goal-form-submit')));
      await tester.pumpAndSettle();

      expect(api.createCalls, hasLength(1));
      expect(api.createCalls.first['name'], 'Viagem');
      expect(api.createCalls.first['targetAmount'], 5000.0);
      expect(api.createCalls.first['currentAmount'], 500.0);
    });

    testWidgets('alvo zero/inválido bloqueia submit', (tester) async {
      final api = FakeGoalsApi();
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('goal-field-name')),
        'X',
      );
      await tester.tap(find.byKey(const Key('goal-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Informe um valor válido'), findsOneWidget);
      expect(api.createCalls, isEmpty);
    });

    testWidgets('erro do backend exibe mensagem', (tester) async {
      final api = FakeGoalsApi(
        createHandler: ({
          required name,
          required targetAmount,
          currentAmount = 0,
          deadline,
        }) async {
          throw GoalsApiException('payload inválido', statusCode: 422);
        },
      );
      await tester.pumpWidget(_wrap(api: api));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('goal-field-name')),
        'M',
      );
      await tester.enterText(
        find.byKey(const Key('goal-field-target')),
        '100',
      );
      await tester.tap(find.byKey(const Key('goal-form-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('goal-form-error')), findsOneWidget);
      expect(find.text('payload inválido'), findsOneWidget);
    });

    testWidgets('edição pré-popula e chama update', (tester) async {
      final api = FakeGoalsApi();
      final container = ProviderContainer(
        overrides: [goalsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      api.listHandler = () async => [
            sampleGoal(id: 7, name: 'Reserva', target: 10000, current: 2000),
          ];
      await container.read(goalsControllerProvider.notifier).refresh();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router(editId: 7)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reserva'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('goal-field-current')),
        '3000',
      );
      await tester.tap(find.byKey(const Key('goal-form-submit')));
      await tester.pumpAndSettle();
      expect(api.updateCalls, hasLength(1));
      expect(api.updateCalls.first['id'], 7);
      expect(api.updateCalls.first['currentAmount'], 3000.0);
    });
  });
}
