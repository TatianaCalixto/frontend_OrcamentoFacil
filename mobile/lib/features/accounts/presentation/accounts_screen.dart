import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/presentation/dashboard_screen.dart' show formatBrl;
import '../application/accounts_controller.dart';
import '../data/account_models.dart';
import '../data/accounts_api.dart';

/// Tela de Contas — lista todas as contas do usuário com saldo atual.
/// Permite filtrar por ativa/inativa, criar (FAB), editar e excluir.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountsControllerProvider.notifier).refresh();
    });
  }

  Future<void> _confirmDelete(AccountFull acc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Text(
          'Tem certeza que deseja excluir "${acc.name}"?\n\n'
          'Atenção: contas com transações associadas podem não poder ser excluídas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('acc-confirm-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(accountsControllerProvider.notifier).delete(acc.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta excluída.')),
      );
    } on AccountsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('acc-btn-new'),
        onPressed: () => context.go('/accounts/new'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterBar(
              filter: state.filter,
              onChanged: (f) =>
                  ref.read(accountsControllerProvider.notifier).setFilter(f),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(accountsControllerProvider.notifier).refresh(),
                child: _body(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AccountsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        key: const Key('acc-loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (state.hasError && state.items.isEmpty) {
      return ListView(
        key: const Key('acc-error'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(state.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(accountsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }
    if (state.isEmpty) {
      return ListView(
        key: const Key('acc-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.account_balance_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma conta cadastrada.\nToque em + para criar a primeira.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    final visible = state.visibleItems;
    if (visible.isEmpty) {
      return ListView(
        key: const Key('acc-filter-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Nenhuma conta para este filtro.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return ListView(
      key: const Key('acc-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final a in visible)
          _AccountCard(
            account: a,
            onTap: () => context.go('/accounts/${a.id}/edit'),
            onDelete: () => _confirmDelete(a),
          ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final AccountsFilter filter;
  final ValueChanged<AccountsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<AccountsFilter>(
        segments: const [
          ButtonSegment(
            value: AccountsFilter.all,
            label: Text('Todas'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(
            value: AccountsFilter.active,
            label: Text('Ativas'),
            icon: Icon(Icons.check_circle_outline),
          ),
          ButtonSegment(
            value: AccountsFilter.inactive,
            label: Text('Inativas'),
            icon: Icon(Icons.cancel_outlined),
          ),
        ],
        selected: {filter},
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.onTap,
    required this.onDelete,
  });

  final AccountFull account;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData get _typeIcon => switch (account.type) {
        AccountType.checking => Icons.account_balance,
        AccountType.savings => Icons.savings,
        AccountType.creditCard => Icons.credit_card,
        AccountType.cash => Icons.payments,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final balanceColor = account.currentBalance < 0
        ? AppColors.dangerStrong
        : cs.onSurface;
    return Card(
      key: Key('acc-card-${account.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(_typeIcon, color: cs.onPrimaryContainer),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (!account.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Inativa',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.type.label),
              const SizedBox(height: 2),
              Text(
                'Saldo atual: ${formatBrl(account.currentBalance)}',
                style: TextStyle(
                  color: balanceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          key: Key('acc-delete-${account.id}'),
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }
}
