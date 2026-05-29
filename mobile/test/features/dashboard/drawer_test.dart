import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/accounts/data/accounts_api.dart';
import 'package:orcafacil_mobile/features/auth/application/auth_controller.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/features/dashboard/data/dashboard_api.dart';
import 'package:orcafacil_mobile/features/dashboard/presentation/app_drawer.dart';
import 'package:orcafacil_mobile/features/dashboard/presentation/dashboard_screen.dart';

import '../../support/fakes.dart';
import '../accounts/_fakes.dart' as acc_fakes;
import '_fakes.dart';

/// Adaptador local: escuta `authControllerProvider` num `ProviderContainer`
/// e notifica o `GoRouter` para reavaliar redirects. Mimetiza o
/// `_RouterRefreshNotifier` do app real.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(ProviderContainer container) {
    _sub = container.listen<AuthState>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
  }
  late final ProviderSubscription<AuthState> _sub;
  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

GoRouter _drawerRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthRefresh(container),
    redirect: (ctx, st) {
      final auth = container.read(authControllerProvider);
      if (auth is AuthUnauthenticated && st.matchedLocation != '/login') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('ACCOUNTS_STUB'))),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('LOGIN_STUB'))),
      ),
    ],
  );
}

Future<ProviderContainer> _pumpDrawer(
  WidgetTester tester, {
  required TokenStorage storage,
  required FakeAuthApi authApi,
  required FakeDashboardApi dashboardApi,
  required acc_fakes.FakeAccountsApi accountsApi,
}) async {
  // Viewport vertical generoso para caber todos os itens do drawer sem scroll
  // (evita que widgets fora da viewport deixem de ser construídos).
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      authApiProvider.overrideWithValue(authApi),
      dashboardApiProvider.overrideWithValue(dashboardApi),
      accountsApiProvider.overrideWithValue(accountsApi),
    ],
  );
  addTearDown(container.dispose);
  // Marca autenticado para que o router não redirecione antes de chegarmos
  // ao /dashboard.
  await container.read(authControllerProvider.notifier).bootstrap();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: _drawerRouter(container)),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('Dashboard drawer', () {
    testWidgets('contém item Contas e navega para /accounts', (tester) async {
      final storage = InMemoryTokenStorageWrapped()..token = 'tok';
      await _pumpDrawer(
        tester,
        storage: storage,
        authApi: FakeAuthApi(),
        dashboardApi: FakeDashboardApi(),
        accountsApi: acc_fakes.FakeAccountsApi(
          listHandler: () async => [acc_fakes.sampleAccount(id: 1)],
        ),
      );

      // Abre o drawer.
      final scaffoldFinder = find.byType(Scaffold).first;
      final state = tester.state<ScaffoldState>(scaffoldFinder);
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer-accounts')), findsOneWidget);
      expect(find.text('Contas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('drawer-accounts')));
      await tester.pumpAndSettle();

      expect(find.text('ACCOUNTS_STUB'), findsOneWidget);
    });

    testWidgets('drawer tem 2 seções (Lançamentos / Conta) com divider',
        (tester) async {
      final storage = InMemoryTokenStorageWrapped()..token = 'tok';
      await _pumpDrawer(
        tester,
        storage: storage,
        authApi: FakeAuthApi(),
        dashboardApi: FakeDashboardApi(),
        accountsApi: acc_fakes.FakeAccountsApi(
          listHandler: () async => [acc_fakes.sampleAccount(id: 1)],
        ),
      );

      final state = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      state.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('LANÇAMENTOS'), findsOneWidget);
      expect(find.text('CONTA'), findsOneWidget);
      expect(find.byKey(const Key('drawer-divider')), findsOneWidget);
      // Itens da seção Lançamentos.
      expect(find.byKey(const Key('drawer-dashboard')), findsOneWidget);
      expect(find.byKey(const Key('drawer-transactions')), findsOneWidget);
      expect(find.byKey(const Key('drawer-accounts')), findsOneWidget);
      expect(find.byKey(const Key('drawer-categories')), findsOneWidget);
      expect(find.byKey(const Key('drawer-budgets')), findsOneWidget);
      expect(find.byKey(const Key('drawer-goals')), findsOneWidget);
      expect(find.byKey(const Key('drawer-import-csv')), findsOneWidget);
      // Itens da seção Conta.
      expect(find.byKey(const Key('drawer-profile')), findsOneWidget);
      expect(find.byKey(const Key('drawer-settings')), findsOneWidget);
      expect(find.byKey(const Key('drawer-logout')), findsOneWidget);
    });

    testWidgets('logout no drawer limpa token e volta para login',
        (tester) async {
      final storage = InMemoryTokenStorageWrapped()..token = 'tok-existente';
      final container = await _pumpDrawer(
        tester,
        storage: storage,
        authApi: FakeAuthApi(),
        dashboardApi: FakeDashboardApi(),
        accountsApi: acc_fakes.FakeAccountsApi(
          listHandler: () async => [acc_fakes.sampleAccount(id: 1)],
        ),
      );

      // Sanity: está autenticado e no dashboard.
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      final scaffoldState =
          tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('drawer-logout')));
      await tester.pumpAndSettle();

      // Token foi limpo.
      expect(storage.token, isNull);
      // Estado virou Unauthenticated.
      expect(
          container.read(authControllerProvider), isA<AuthUnauthenticated>());
      // Router redirecionou para /login (refreshListenable do AuthState).
      expect(find.text('LOGIN_STUB'), findsOneWidget);
    });
  });

  group('AppNavigationDrawer highlight', () {
    Widget wrapStandalone(String currentLocation) {
      // Renderiza o drawer standalone (sem GoRouter) para isolar a lógica
      // de selectedIndex. AppNavigationDrawer só usa GoRouter via onTap,
      // que não é exercitado aqui.
      return ProviderScope(
        overrides: [
          authApiProvider.overrideWithValue(FakeAuthApi()),
          tokenStorageProvider
              .overrideWithValue(InMemoryTokenStorageWrapped()),
        ],
        child: MaterialApp(
          home: Scaffold(
            drawer: AppNavigationDrawer(currentLocation: currentLocation),
            body: const SizedBox.shrink(),
          ),
        ),
      );
    }

    int? selectedIndexFromWidget(WidgetTester tester) {
      final nav = tester.widget<NavigationDrawer>(
        find.byType(NavigationDrawer),
      );
      return nav.selectedIndex;
    }

    testWidgets('em /transactions destaca Transações (index 1)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapStandalone('/transactions'));
      final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(selectedIndexFromWidget(tester), 1);
    });

    testWidgets('em /budgets destaca Orçamentos (index 4)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapStandalone('/budgets'));
      final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(selectedIndexFromWidget(tester), 4);
    });

    testWidgets('em /transactions/new (subrota) ainda destaca Transações',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(wrapStandalone('/transactions/new'));
      final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      expect(selectedIndexFromWidget(tester), 1);
    });

    testWidgets('routeToDrawerIndex retorna null para rota fora do drawer',
        (tester) async {
      expect(routeToDrawerIndex('/login'), isNull);
      expect(routeToDrawerIndex('/'), isNull);
    });
  });
}
