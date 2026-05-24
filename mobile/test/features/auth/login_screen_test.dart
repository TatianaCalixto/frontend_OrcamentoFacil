import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/features/auth/presentation/login_screen.dart';

import '../../support/fakes.dart';

GoRouter _stubRouter(Widget child) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => child),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('REGISTER_STUB'))),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderScope scope) async {
  await tester.pumpWidget(scope);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('valida campos vazios e não chama a API', (tester) async {
    final api = FakeAuthApi();
    final storage = InMemoryTokenStorageWrapped();

    await _pump(
      tester,
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(routerConfig: _stubRouter(const LoginScreen())),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(api.loginCalls, isEmpty);
  });

  testWidgets('login bem-sucedido chama API e salva token', (tester) async {
    final api = FakeAuthApi();
    final storage = InMemoryTokenStorageWrapped();

    await _pump(
      tester,
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(routerConfig: _stubRouter(const LoginScreen())),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'tati@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'segredo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(api.loginCalls.length, 1);
    expect(api.loginCalls.first['email'], 'tati@example.com');
    expect(api.loginCalls.first['password'], 'segredo123');
    expect(storage.token, 'fake-token');
    expect(api.meCalls, 1);
  });

  testWidgets('erro de credenciais é exibido na tela', (tester) async {
    final api = FakeAuthApi(
      loginHandler: ({required email, required password}) async {
        throw AuthApiException('Credenciais inválidas',
            code: 'http_401', statusCode: 401);
      },
    );
    final storage = InMemoryTokenStorageWrapped();

    await _pump(
      tester,
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(routerConfig: _stubRouter(const LoginScreen())),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'x@x.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Credenciais inválidas'), findsOneWidget);
    expect(storage.token, isNull);
  });

  testWidgets('botão "Cadastrar" navega para /register', (tester) async {
    final api = FakeAuthApi();
    final storage = InMemoryTokenStorageWrapped();

    await _pump(
      tester,
      ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(routerConfig: _stubRouter(const LoginScreen())),
      ),
    );

    await tester.tap(find.text('Não tenho conta — Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('REGISTER_STUB'), findsOneWidget);
  });
}
