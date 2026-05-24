import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';

/// Tela de Perfil — mostra dados do usuário logado e oferece logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: switch (auth) {
          AuthAuthenticated(:final user) => _ProfileBody(
              userName: user.name,
              userEmail: user.email,
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          AuthLoading() || AuthInitial() => const Center(
              key: Key('profile-loading'),
              child: CircularProgressIndicator(),
            ),
          AuthUnauthenticated() => const Center(
              key: Key('profile-unauth'),
              child: Text('Sessão expirada. Faça login novamente.'),
            ),
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('profile-loaded'),
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            child: Text(
              _initials(userName),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ListTile(
          key: const Key('profile-name'),
          leading: const Icon(Icons.person_outline),
          title: const Text('Nome'),
          subtitle: Text(userName),
        ),
        ListTile(
          key: const Key('profile-email'),
          leading: const Icon(Icons.mail_outline),
          title: const Text('E-mail'),
          subtitle: Text(userEmail),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          key: const Key('profile-logout'),
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Sair'),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
