import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import '../features/transactions/presentation/transactions_list_screen.dart';

/// Adaptador que faz o `GoRouter` reagir a mudanças no `AuthState`.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (prev, next) => notifyListeners());
  }
  final Ref _ref;
}

/// Constrói o `GoRouter` com redirecionamento baseado no `AuthState`:
/// - `AuthInitial`/`AuthLoading` -> sempre /splash
/// - `AuthAuthenticated` -> /dashboard (de qualquer rota pública)
/// - `AuthUnauthenticated` -> /login (de qualquer rota privada)
GoRouter buildRouter(Ref ref) {
  final refresh = _RouterRefreshNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsListScreen(),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) => const TransactionFormScreen(),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const TransactionFormScreen();
          }
          return TransactionFormScreen(transactionId: id);
        },
      ),
    ],
    redirect: (context, st) {
      final auth = ref.read(authControllerProvider);
      final loc = st.matchedLocation;
      if (auth is AuthInitial || auth is AuthLoading) {
        return loc == '/splash' ? null : '/splash';
      }
      if (auth is AuthAuthenticated) {
        if (loc == '/splash' || loc == '/login' || loc == '/register') {
          return '/dashboard';
        }
        return null;
      }
      // AuthUnauthenticated
      if (loc == '/login' || loc == '/register') return null;
      return '/login';
    },
  );
}

/// Provider Riverpod do router.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
