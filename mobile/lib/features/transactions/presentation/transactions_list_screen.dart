import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/async_view.dart';
import '../../dashboard/presentation/dashboard_screen.dart' show formatBrl;
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import '../data/transactions_api.dart';

/// Tela de Lista de Transações:
/// - filtros (data range, conta, categoria, tipo, busca textual)
/// - paginação por scroll infinito
/// - estados loading/empty/error
class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(transactionsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final current = ref.read(transactionsControllerProvider).filters;
    final accounts = await ref.read(accountsProvider.future);
    final categories = await ref.read(categoriesProvider.future);
    if (!mounted) return;
    final next = await showModalBottomSheet<TransactionFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiltersSheet(
        initial: current,
        accounts: accounts,
        categories: categories,
      ),
    );
    if (next != null) {
      await ref
          .read(transactionsControllerProvider.notifier)
          .applyFilters(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            key: const Key('btn-open-filters'),
            tooltip: 'Filtros',
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('btn-new-transaction'),
        onPressed: () => context.go('/transactions/new'),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const Key('search-field'),
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Buscar descrição…',
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref
                                .read(transactionsControllerProvider.notifier)
                                .applyFilters(
                                  state.filters
                                      .copyWith(clearSearch: true),
                                );
                          },
                        ),
                ),
                onSubmitted: (value) {
                  ref
                      .read(transactionsControllerProvider.notifier)
                      .applyFilters(
                        state.filters.copyWith(search: value),
                      );
                },
              ),
            ),
            if (_hasActiveFilters(state.filters))
              _ActiveFiltersBar(filters: state.filters),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(transactionsControllerProvider.notifier)
                    .refresh(),
                child: _body(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TransactionsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingView(key: Key('transactions-loading'), scrollable: true);
    }
    if (state.hasError && state.items.isEmpty) {
      return ErrorView(
        key: const Key('transactions-error'),
        message: state.errorMessage!,
        scrollable: true,
        onRetry: () => ref.read(transactionsControllerProvider.notifier).refresh(),
      );
    }
    if (state.isEmpty) {
      return const EmptyView(
        key: Key('transactions-empty'),
        message: 'Nenhuma transação encontrada.',
        icon: Icons.receipt_long_outlined,
        scrollable: true,
      );
    }
    return ListView.separated(
      key: const Key('transactions-list'),
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            key: Key('loading-more'),
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tx = state.items[index];
        return _TransactionTile(transaction: tx);
      },
    );
  }
}

bool _hasActiveFilters(TransactionFilters f) {
  return f.dateFrom != null ||
      f.dateTo != null ||
      f.accountId != null ||
      f.categoryId != null ||
      f.type != null ||
      (f.search != null && f.search!.isNotEmpty);
}

class _ActiveFiltersBar extends ConsumerWidget {
  const _ActiveFiltersBar({required this.filters});
  final TransactionFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <Widget>[];
    if (filters.type != null) {
      chips.add(Chip(label: Text(filters.type!.label)));
    }
    if (filters.dateFrom != null || filters.dateTo != null) {
      chips.add(Chip(
        label: Text(
          'Data: ${_fmt(filters.dateFrom)} a ${_fmt(filters.dateTo)}',
        ),
      ));
    }
    if (filters.accountId != null) {
      chips.add(Chip(label: Text('Conta #${filters.accountId}')));
    }
    if (filters.categoryId != null) {
      chips.add(Chip(label: Text('Categoria #${filters.categoryId}')));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...chips,
          ActionChip(
            avatar: const Icon(Icons.clear_all, size: 16),
            label: const Text('Limpar'),
            onPressed: () => ref
                .read(transactionsControllerProvider.notifier)
                .applyFilters(const TransactionFilters()),
          ),
        ],
      ),
    );
  }
}

String _fmt(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.danger;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(
          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
          color: color,
        ),
      ),
      title: Text(transaction.description ?? '(sem descrição)'),
      subtitle: Text(_fmt(transaction.date)),
      trailing: Text(
        '${isIncome ? '+' : '-'} ${formatBrl(transaction.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () => context.go('/transactions/${transaction.id}/edit'),
    );
  }
}

/// Bottom-sheet de filtros. Devolve `TransactionFilters` ao chamador via pop.
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({
    super.key,
    required this.initial,
    required this.accounts,
    required this.categories,
  });

  final TransactionFilters initial;
  final List<Account> accounts;
  final List<Category> categories;

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late DateTime? _dateFrom = widget.initial.dateFrom;
  late DateTime? _dateTo = widget.initial.dateTo;
  late int? _accountId = widget.initial.accountId;
  late int? _categoryId = widget.initial.categoryId;
  late TransactionType? _type = widget.initial.type;

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateFrom = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateTo = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Filtros',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('filter-date-from'),
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.date_range),
                    label: Text('De: ${_fmt(_dateFrom)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('filter-date-to'),
                    onPressed: _pickTo,
                    icon: const Icon(Icons.date_range),
                    label: Text('Até: ${_fmt(_dateTo)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionType?>(
              key: const Key('filter-type'),
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final t in TransactionType.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: const Key('filter-account'),
              initialValue: _accountId,
              decoration: const InputDecoration(
                labelText: 'Conta',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final a in widget.accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _accountId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: const Key('filter-category'),
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (final c in widget.categories)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('filter-clear'),
                    onPressed: () {
                      Navigator.of(context).pop(const TransactionFilters());
                    },
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('filter-apply'),
                    onPressed: () {
                      Navigator.of(context).pop(
                        widget.initial.copyWith(
                          dateFrom: _dateFrom,
                          dateTo: _dateTo,
                          accountId: _accountId,
                          categoryId: _categoryId,
                          type: _type,
                          clearDateFrom: _dateFrom == null,
                          clearDateTo: _dateTo == null,
                          clearAccountId: _accountId == null,
                          clearCategoryId: _categoryId == null,
                          clearType: _type == null,
                        ),
                      );
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
