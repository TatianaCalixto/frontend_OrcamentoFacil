import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('settings-list'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const _SectionHeader(title: 'Aparência'),
            ListTile(
              key: const Key('settings-theme'),
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Tema'),
              subtitle: Text(settings.themeMode.label),
              trailing: DropdownButton<AppThemeMode>(
                key: const Key('settings-theme-dropdown'),
                value: settings.themeMode,
                onChanged: (v) {
                  if (v == null) return;
                  ref
                      .read(settingsControllerProvider.notifier)
                      .setThemeMode(v);
                },
                items: [
                  for (final m in AppThemeMode.values)
                    DropdownMenuItem(value: m, child: Text(m.label)),
                ],
              ),
            ),
            const _SectionHeader(title: 'Idioma'),
            ListTile(
              key: const Key('settings-language'),
              leading: const Icon(Icons.language),
              title: const Text('Idioma'),
              subtitle: Text(settings.language),
              trailing: const Text('Em breve'),
            ),
            const _SectionHeader(title: 'Dados'),
            ListTile(
              key: const Key('settings-import-csv'),
              leading: const Icon(Icons.upload_file),
              title: const Text('Importar CSV'),
              subtitle: const Text('Importar transações de um arquivo CSV.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/imports/csv'),
            ),
            const _SectionHeader(title: 'Conta'),
            ListTile(
              key: const Key('settings-profile'),
              leading: const Icon(Icons.person_outline),
              title: const Text('Perfil'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/profile'),
            ),
            ListTile(
              key: const Key('settings-logout'),
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
