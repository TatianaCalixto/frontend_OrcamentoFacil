import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';

/// Placeholder do Dashboard. Implementação real em sprints futuras.
class DashboardPlaceholder extends ConsumerWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final userName = state is AuthAuthenticated ? state.user.name : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('OrçaFácil'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            userName.isEmpty
                ? 'Bem-vindo! (Dashboard em construção)'
                : 'Olá, $userName! (Dashboard em construção)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
