import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../dashboard/presentation/dashboard_screen.dart' show formatBrl;
import '../application/goals_controller.dart';
import '../data/goal_models.dart';
import '../data/goals_api.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(goalsControllerProvider.notifier).refresh();
    });
  }

  Future<void> _confirmDelete(Goal g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir meta?'),
        content: Text('Tem certeza que deseja excluir "${g.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('goal-confirm-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(goalsControllerProvider.notifier).delete(g.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta excluída.')),
      );
    } on GoalsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _addProgress(Goal g) async {
    final added = await showDialog<double>(
      context: context,
      builder: (ctx) => _AddProgressDialog(goal: g),
    );
    if (added == null || added <= 0) return;
    try {
      await ref.read(goalsControllerProvider.notifier).update(
            g.id,
            currentAmount: g.currentAmount + added,
          );
    } on GoalsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('goal-btn-new'),
        onPressed: () => context.go('/goals/new'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(goalsControllerProvider.notifier).refresh(),
          child: _body(state),
        ),
      ),
    );
  }

  Widget _body(GoalsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        key: const Key('goal-loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (state.hasError && state.items.isEmpty) {
      return ListView(
        key: const Key('goal-error'),
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
                  ref.read(goalsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }
    if (state.isEmpty) {
      return ListView(
        key: const Key('goal-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.flag_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'Sem metas cadastradas.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView.separated(
      key: const Key('goal-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final g = state.items[i];
        return GoalCard(
          goal: g,
          onAdd: () => _addProgress(g),
          onEdit: () => context.go('/goals/${g.id}/edit'),
          onDelete: () => _confirmDelete(g),
        );
      },
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = goal.status == GoalStatus.completed;
    final color = completed ? Colors.green : Theme.of(context).colorScheme.primary;
    return Card(
      key: Key('goal-card-${goal.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (completed)
                  Container(
                    key: const Key('goal-badge-completed'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Concluída',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  key: Key('goal-edit-${goal.id}'),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  key: Key('goal-delete-${goal.id}'),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: Key('goal-progress-${goal.id}'),
                value: goal.progress,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${formatBrl(goal.currentAmount)} / ${formatBrl(goal.targetAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (goal.deadline != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Prazo: ${_fmtDate(goal.deadline!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (!completed) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: Key('goal-add-${goal.id}'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Somar valor'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

class _AddProgressDialog extends StatefulWidget {
  const _AddProgressDialog({required this.goal});
  final Goal goal;

  @override
  State<_AddProgressDialog> createState() => _AddProgressDialogState();
}

class _AddProgressDialogState extends State<_AddProgressDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar à meta "${widget.goal.name}"'),
      content: TextField(
        key: const Key('goal-add-amount'),
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Valor a adicionar (R\$)',
          hintText: 'Ex: 100,00',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('goal-confirm-add'),
          onPressed: () {
            final raw = _ctrl.text.replaceAll('.', '').replaceAll(',', '.');
            final amt = double.tryParse(raw);
            Navigator.of(context).pop(amt);
          },
          child: const Text('Somar'),
        ),
      ],
    );
  }
}
