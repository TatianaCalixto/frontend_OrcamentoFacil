import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';

/// Item de navegação principal do app. A ordem define o `selectedIndex` do
/// `NavigationDrawer` — não reordene sem atualizar `routeToIndex`.
class _DrawerItem {
  const _DrawerItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.route,
  });
  final String key;
  final IconData icon;
  final String label;
  final String route;
}

const List<_DrawerItem> _lancamentosItems = [
  _DrawerItem(key: 'drawer-dashboard', icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
  _DrawerItem(key: 'drawer-transactions', icon: Icons.list_alt, label: 'Transações', route: '/transactions'),
  _DrawerItem(key: 'drawer-accounts', icon: Icons.account_balance, label: 'Contas', route: '/accounts'),
  _DrawerItem(key: 'drawer-categories', icon: Icons.category, label: 'Categorias', route: '/categories'),
  _DrawerItem(key: 'drawer-budgets', icon: Icons.account_balance_wallet, label: 'Orçamentos', route: '/budgets'),
  _DrawerItem(key: 'drawer-goals', icon: Icons.flag, label: 'Metas', route: '/goals'),
  _DrawerItem(key: 'drawer-import-csv', icon: Icons.upload_file, label: 'Importar CSV', route: '/imports/csv'),
];

const List<_DrawerItem> _contaItems = [
  _DrawerItem(key: 'drawer-profile', icon: Icons.person, label: 'Perfil', route: '/profile'),
  _DrawerItem(key: 'drawer-settings', icon: Icons.settings, label: 'Configurações', route: '/settings'),
];

/// Posição do item de logout no índice global do NavigationDrawer.
/// Deve permanecer igual a `_lancamentosItems.length + _contaItems.length`.
/// Não tem rota — clique chama `authController.logout()`.
const int _logoutIndex = 9;

/// Retorna o `selectedIndex` para a rota atual, ou `null` se a rota não
/// estiver no drawer (mantém nada selecionado).
int? routeToDrawerIndex(String location) {
  final all = [..._lancamentosItems, ..._contaItems];
  for (var i = 0; i < all.length; i++) {
    // Prefixo permite que /transactions/new ainda destaque "Transações".
    if (location == all[i].route || location.startsWith('${all[i].route}/')) {
      return i;
    }
  }
  return null;
}

/// Drawer principal do app — usa `NavigationDrawer` (Material 3) com highlight
/// automático do item correspondente à rota atual. Item de logout fica no
/// final, fora das rotas selecionáveis.
class AppNavigationDrawer extends ConsumerWidget {
  const AppNavigationDrawer({super.key, required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [..._lancamentosItems, ..._contaItems];
    final selected = routeToDrawerIndex(currentLocation);

    return NavigationDrawer(
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i == _logoutIndex) {
          ref.read(authControllerProvider.notifier).logout();
          return;
        }
        if (i < all.length) {
          context.go(all[i].route);
        }
      },
      children: [
        const DrawerHeader(
          child: Text(
            'OrçaFácil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        const _DrawerSectionHeader(
          key: Key('drawer-section-lancamentos'),
          title: 'Lançamentos',
        ),
        for (final item in _lancamentosItems)
          NavigationDrawerDestination(
            key: Key(item.key),
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
        const Divider(key: Key('drawer-divider')),
        const _DrawerSectionHeader(
          key: Key('drawer-section-conta'),
          title: 'Conta',
        ),
        for (final item in _contaItems)
          NavigationDrawerDestination(
            key: Key(item.key),
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
        const NavigationDrawerDestination(
          key: Key('drawer-logout'),
          icon: Icon(Icons.logout),
          label: Text('Sair'),
        ),
      ],
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
