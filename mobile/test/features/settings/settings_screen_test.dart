import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/application/auth_controller.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/features/settings/application/settings_controller.dart';
import 'package:orcafacil_mobile/features/settings/presentation/settings_screen.dart';

import '../../support/fakes.dart';
import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
      GoRoute(
        path: '/profile',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('PROFILE'))),
      ),
      GoRoute(
        path: '/imports/csv',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('IMPORT'))),
      ),
    ],
  );
}

void main() {
  group('SettingsScreen', () {
    testWidgets('mostra opções de tema, idioma e logout', (tester) async {
      final storage = InMemorySettingsStorage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStorageProvider.overrideWithValue(storage),
            authApiProvider.overrideWithValue(FakeAuthApi()),
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorageWrapped()),
          ],
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-list')), findsOneWidget);
      expect(find.byKey(const Key('settings-theme')), findsOneWidget);
      expect(find.byKey(const Key('settings-language')), findsOneWidget);
      expect(find.byKey(const Key('settings-logout')), findsOneWidget);
    });

    testWidgets('alterar tema persiste no storage', (tester) async {
      final storage = InMemorySettingsStorage();
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
          authApiProvider.overrideWithValue(FakeAuthApi()),
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorageWrapped()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-theme-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro').last);
      await tester.pumpAndSettle();

      final settings = container.read(settingsControllerProvider);
      expect(settings.themeMode, AppThemeMode.dark);
      // Persistiu
      expect(await storage.read('app.theme_mode'), 'dark');
    });

    testWidgets('estado inicial hidrata a partir do storage', (tester) async {
      final storage = InMemorySettingsStorage();
      await storage.write('app.theme_mode', 'dark');

      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
          authApiProvider.overrideWithValue(FakeAuthApi()),
          tokenStorageProvider.overrideWithValue(InMemoryTokenStorageWrapped()),
        ],
      );
      addTearDown(container.dispose);

      // pumpWidget é necessário para inicializar o binding; depois pumpAndSettle
      // garante que microtasks/futures (incluindo a hidratação) sejam executados.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(settingsControllerProvider).themeMode,
        AppThemeMode.dark,
      );
    });

    testWidgets('clicar em Sair dispara logout', (tester) async {
      final storage = InMemorySettingsStorage();
      final tokenStorage = InMemoryTokenStorageWrapped()..token = 'tok';
      final api = FakeAuthApi(
        meHandler: () async => AuthUser(id: 1, name: 'X', email: 'x@e'),
      );
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(storage),
          authApiProvider.overrideWithValue(api),
          tokenStorageProvider.overrideWithValue(tokenStorage),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).bootstrap();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-logout')));
      await tester.pumpAndSettle();

      expect(tokenStorage.token, isNull);
      expect(
        container.read(authControllerProvider),
        isA<AuthUnauthenticated>(),
      );
    });

    testWidgets('item Importar CSV navega para /imports/csv', (tester) async {
      final storage = InMemorySettingsStorage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsStorageProvider.overrideWithValue(storage),
            authApiProvider.overrideWithValue(FakeAuthApi()),
            tokenStorageProvider.overrideWithValue(InMemoryTokenStorageWrapped()),
          ],
          child: MaterialApp.router(routerConfig: _router()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-import-csv')));
      await tester.pumpAndSettle();
      expect(find.text('IMPORT'), findsOneWidget);
    });
  });
}
