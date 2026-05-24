import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/application/auth_controller.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/features/profile/presentation/profile_screen.dart';

import '../../support/fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH'))),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LOGIN'))),
      ),
    ],
  );
}

ProviderContainer _container({
  required AuthApi api,
  required TokenStorage storage,
}) {
  return ProviderContainer(
    overrides: [
      authApiProvider.overrideWithValue(api),
      tokenStorageProvider.overrideWithValue(storage),
    ],
  );
}

void main() {
  group('ProfileScreen', () {
    testWidgets('estado loading enquanto AuthInitial', (tester) async {
      final api = FakeAuthApi();
      final storage = InMemoryTokenStorageWrapped();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authApiProvider.overrideWithValue(api),
            tokenStorageProvider.overrideWithValue(storage),
          ],
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      // Sem bootstrap, fica AuthInitial -> loading
      await tester.pump();
      expect(find.byKey(const Key('profile-loading')), findsOneWidget);
    });

    testWidgets('mostra nome e e-mail do usuário autenticado',
        (tester) async {
      final api = FakeAuthApi(
        meHandler: () async => AuthUser(
          id: 42,
          name: 'Tatiana Calixto',
          email: 'tati@example.com',
        ),
      );
      final storage = InMemoryTokenStorageWrapped()..token = 'fake-token';
      final container = _container(api: api, storage: storage);
      addTearDown(container.dispose);

      // Bootstrap pra ficar AuthAuthenticated
      await container.read(authControllerProvider.notifier).bootstrap();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-loaded')), findsOneWidget);
      expect(find.text('Tatiana Calixto'), findsOneWidget);
      expect(find.text('tati@example.com'), findsOneWidget);
    });

    testWidgets('logout limpa storage e estado vai para Unauthenticated',
        (tester) async {
      final api = FakeAuthApi(
        meHandler: () async => AuthUser(id: 1, name: 'Tati', email: 't@e'),
      );
      final storage = InMemoryTokenStorageWrapped()..token = 'fake-token';
      final container = _container(api: api, storage: storage);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).bootstrap();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-logout')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pumpAndSettle();

      expect(storage.token, isNull);
      final auth = container.read(authControllerProvider);
      expect(auth, isA<AuthUnauthenticated>());
    });

    testWidgets('estado unauth mostra mensagem de sessão expirada',
        (tester) async {
      final api = FakeAuthApi();
      final storage = InMemoryTokenStorageWrapped();
      final container = _container(api: api, storage: storage);
      addTearDown(container.dispose);
      // bootstrap sem token -> AuthUnauthenticated
      await container.read(authControllerProvider.notifier).bootstrap();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-unauth')), findsOneWidget);
    });
  });
}
