import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../transactions/data/transaction_models.dart';
import '../application/categories_controller.dart';
import '../data/categories_api.dart';
import '../data/category_models.dart';
import 'category_visuals.dart';

/// Tela de Categorias — lista todas as categorias do usuário com indicadores
/// visuais de cor/ícone. Permite criar, editar e excluir (exceto padrões).
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesControllerProvider.notifier).refresh();
    });
  }

  Future<void> _confirmDelete(CategoryFull cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text('Tem certeza que deseja excluir "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('cat-confirm-delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(categoriesControllerProvider.notifier).delete(cat.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria excluída.')),
      );
    } on CategoriesApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('cat-btn-new'),
        onPressed: () => context.go('/categories/new'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(categoriesControllerProvider.notifier).refresh(),
          child: _body(state),
        ),
      ),
    );
  }

  Widget _body(CategoriesState state) {
    if (state.isLoading && state.items.isEmpty) {
      return ListView(
        key: const Key('cat-loading'),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (state.hasError && state.items.isEmpty) {
      return ListView(
        key: const Key('cat-error'),
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
              onPressed: () => ref
                  .read(categoriesControllerProvider.notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      );
    }
    if (state.isEmpty) {
      return ListView(
        key: const Key('cat-empty'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.category_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma categoria cadastrada.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    // Agrupa por tipo para facilitar leitura.
    final income = state.items
        .where((c) => c.type == TransactionType.income)
        .toList(growable: false);
    final expense = state.items
        .where((c) => c.type == TransactionType.expense)
        .toList(growable: false);
    return ListView(
      key: const Key('cat-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (expense.isNotEmpty) ...[
          const _SectionHeader(title: 'Despesas'),
          for (final c in expense)
            _CategoryTile(
              category: c,
              onTap: () => context.go('/categories/${c.id}/edit'),
              onDelete: () => _confirmDelete(c),
            ),
        ],
        if (income.isNotEmpty) ...[
          const _SectionHeader(title: 'Receitas'),
          for (final c in income)
            _CategoryTile(
              category: c,
              onTap: () => context.go('/categories/${c.id}/edit'),
              onDelete: () => _confirmDelete(c),
            ),
        ],
      ],
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final CategoryFull category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = parseCategoryColor(category.color);
    return ListTile(
      key: Key('cat-tile-${category.id}'),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(iconForCategory(category.icon), color: color),
      ),
      title: Row(
        children: [
          Expanded(child: Text(category.name)),
          if (category.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Padrão',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      trailing: category.isDefault
          ? null
          : IconButton(
              key: Key('cat-delete-${category.id}'),
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
      onTap: onTap,
    );
  }
}
