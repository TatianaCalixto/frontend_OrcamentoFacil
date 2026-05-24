import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/features/auth/presentation/register_screen.dart';

import '../../support/fakes.dart';

GoRouter _stubRouter(Widget child) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LOGIN_STUB'))),
      ),
    ],
  );
}

void main() {
  testWidgets('valida campos do formulário', (tester) async {
    final api = FakeAuthApi();
    final storage = InMemoryTokenStorageWrapped();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child:
            MaterialApp.router(routerConfig: _stubRouter(const RegisterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.pump();

    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(api.registerCalls, isEmpty);
  });

  testWidgets('cadastro bem-sucedido navega para /login com snackbar',
      (tester) async {
    final api = FakeAuthApi();
    final storage = InMemoryTokenStorageWrapped();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child:
            MaterialApp.router(routerConfig: _stubRouter(const RegisterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Tati');
    await tester.enterText(find.byType(TextFormField).at(1), 'tati@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'segredo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.pumpAndSettle();

    expect(api.registerCalls.length, 1);
    expect(api.registerCalls.first['name'], 'Tati');
    expect(api.registerCalls.first['email'], 'tati@example.com');
    expect(find.text('LOGIN_STUB'), findsOneWidget);
  });

  testWidgets('erro de cadastro exibe mensagem do backend', (tester) async {
    final api = FakeAuthApi(
      registerHandler: ({required name, required email, required password}) async {
        throw AuthApiException('E-mail já cadastrado',
            code: 'http_409', statusCode: 409);
      },
    );
    final storage = InMemoryTokenStorageWrapped();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child:
            MaterialApp.router(routerConfig: _stubRouter(const RegisterScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Tati');
    await tester.enterText(find.byType(TextFormField).at(1), 'tati@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'segredo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail já cadastrado'), findsOneWidget);
    // Continua na mesma tela (não navega).
    expect(find.text('LOGIN_STUB'), findsNothing);
  });
}
