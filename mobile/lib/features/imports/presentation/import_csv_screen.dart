import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../transactions/application/transactions_controller.dart';
import '../../transactions/data/transaction_models.dart';
import '../application/imports_controller.dart';
import '../data/import_models.dart';

/// Tela de Importação de CSV — seleção de conta, file picker e exibição do
/// resultado (created/skipped/erros).
class ImportCsvScreen extends ConsumerWidget {
  const ImportCsvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importsControllerProvider);
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar CSV'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Envie um arquivo .csv (máx 2MB) com colunas: '
              'date, type, amount, category, description (opcional), '
              'payment_method (opcional).',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            accountsAsync.when(
              loading: () => const Padding(
                key: Key('import-accounts-loading'),
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                key: const Key('import-accounts-error'),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Falha ao carregar contas: $err',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              data: (accounts) => _AccountPicker(
                accounts: accounts,
                value: state.accountId,
                onChanged: (v) {
                  if (v == null) return;
                  ref
                      .read(importsControllerProvider.notifier)
                      .selectAccount(v);
                },
              ),
            ),
            const SizedBox(height: 16),
            _FilePickerArea(state: state),
            if (state.isTooLarge)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Arquivo maior que 2MB.',
                  key: const Key('import-size-warning'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('import-error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(state.errorMessage!)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('import-btn-submit'),
              onPressed: state.canSubmit
                  ? () =>
                      ref.read(importsControllerProvider.notifier).submit()
                  : null,
              icon: state.isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(state.isUploading ? 'Enviando…' : 'Enviar'),
            ),
            if (state.result != null) ...[
              const SizedBox(height: 24),
              ImportResultPanel(result: state.result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.value,
    required this.onChanged,
  });

  final List<Account> accounts;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const Key('import-field-account'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Conta de destino',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final a in accounts)
          DropdownMenuItem(value: a.id, child: Text(a.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _FilePickerArea extends ConsumerWidget {
  const _FilePickerArea({required this.state});
  final ImportState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = state.picked;
    return Card(
      key: const Key('import-file-area'),
      child: InkWell(
        onTap: () =>
            ref.read(importsControllerProvider.notifier).pickFile(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                picked == null ? Icons.upload_file : Icons.description,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                picked == null
                    ? 'Toque para escolher um arquivo .csv'
                    : picked.name,
                key: const Key('import-file-label'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (picked != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${(picked.sizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Painel de resultado exposto separadamente para reuso em testes.
class ImportResultPanel extends StatelessWidget {
  const ImportResultPanel({super.key, required this.result});
  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('import-result'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultado da importação',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(
                  key: const Key('import-stat-created'),
                  label: 'Criadas',
                  value: '${result.createdCount}',
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  key: const Key('import-stat-skipped'),
                  label: 'Ignoradas',
                  value: '${result.skippedCount}',
                  color: Colors.orange,
                  icon: Icons.skip_next,
                ),
                const SizedBox(width: 12),
                _StatBox(
                  key: const Key('import-stat-errors'),
                  label: 'Erros',
                  value: '${result.errors.length}',
                  color: Colors.red,
                  icon: Icons.error_outline,
                ),
              ],
            ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Erros por linha:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  key: const Key('import-errors-list'),
                  shrinkWrap: true,
                  itemCount: result.errors.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = result.errors[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            Colors.red.withValues(alpha: 0.15),
                        child: Text(
                          '${e.lineNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(e.message),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
