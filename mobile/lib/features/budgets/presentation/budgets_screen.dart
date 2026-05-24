import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../categories/application/categories_controller.dart';
import '../../categories/data/category_models.dart';
import '../../dashboard/presentation/dashboard_screen.dart' show formatBrl;
import '../application/budgets_controller.dart';
import '../data/budget_models.dart';

/// Tela de Orçamentos do mês corrente. Cada card mostra categoria, limite e
/// progresso de uso com cor por status (verde/amarelo/vermelho).
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetsControllerProvider.notifier).refresh();
      ref.read(categoriesControllerProvider.notifier).refresh();
    });
  }

  Future<void> _pickPeriod() async {
    final st = ref.read(budgetsControllerProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(st.year, st.month),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione mês/ano',
    );
    if (picked != null) {
      await ref
          .read(budgetsControllerProvider.notifier)
          .changePeriod(month: picked.month, year: picked.year);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetsControllerProvider);
    final categories = ref.watch(categoriesControllerProvider).items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            key: const Key('budget-btn-period'),
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Período',
            onPressed: _pickPeriod,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('budget-btn-new'),
        onPressed: () => context.go('/budgets/new'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _periodLabel(state.month, state.year),
                    key: const Key('budget-period-label'),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(budgetsControllerProvider.notifier).refresh(),
                child: _body(state, categories),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BudgetsState state, List<CategoryFull> categories) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        key: const Key('budget-loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (state.hasError && state.items.isEmpty) {
      return ListView(
        key: const Key('budget-error'),
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
                  ref.read(budgetsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }
    if (state.isEmpty) {
      return ListView(
        key: const Key('budget-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sem orçamentos cadastrados para o período.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      key: const Key('budget-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = state.items[i];
        final category =
            categories.where((c) => c.id == b.categoryId).cast<CategoryFull?>().firstOrNull;
        return BudgetCard(budget: b, category: category);
      },
    );
  }
}

String _periodLabel(int month, int year) {
  const names = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  final name = names[(month - 1).clamp(0, 11)];
  return '$name / $year';
}

/// Card individual de orçamento — exposto para reuso e teste.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, this.category});

  final BudgetWithUsage budget;
  final CategoryFull? category;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(budget.status);
    final pct = (budget.percentUsed / 100).clamp(0.0, 1.5);
    return Card(
      key: Key('budget-card-${budget.id}'),
      child: InkWell(
        onTap: () =>
            Navigator.of(context, rootNavigator: true).maybePop(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category?.name ?? 'Categoria #${budget.categoryId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StatusChip(status: budget.status),
                  IconButton(
                    key: Key('budget-edit-${budget.id}'),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Editar',
                    onPressed: () => GoRouter.of(context)
                        .go('/budgets/${budget.id}/edit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  key: Key('budget-progress-${budget.id}'),
                  value: pct > 1.0 ? 1.0 : pct,
                  minHeight: 10,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${formatBrl(budget.usedAmount)} / ${formatBrl(budget.limitAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${budget.percentUsed.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(BudgetStatus s) => switch (s) {
      BudgetStatus.ok => Colors.green,
      BudgetStatus.warning => Colors.orange,
      BudgetStatus.critical => Colors.red,
    };

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      key: Key('budget-status-${status.apiValue}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
