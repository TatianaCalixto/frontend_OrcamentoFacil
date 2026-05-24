import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../categories/application/categories_controller.dart';
import '../../categories/data/category_models.dart';
import '../../transactions/data/transaction_models.dart';
import '../application/budgets_controller.dart';
import '../data/budgets_api.dart';

/// Form de criar/editar orçamento. Em edição, só permite alterar o limite.
class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final int? budgetId;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitCtrl = TextEditingController();
  int? _categoryId;
  int? _month;
  int? _year;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final st = ref.read(budgetsControllerProvider);
    setState(() {
      _month ??= st.month;
      _year ??= st.year;
    });
    ref.read(categoriesControllerProvider.notifier).refresh();
    if (_isEdit) {
      final matches = st.items.where((b) => b.id == widget.budgetId).toList();
      if (matches.isNotEmpty) {
        final found = matches.first;
        setState(() {
          _categoryId = found.categoryId;
          _limitCtrl.text = found.limitAmount.toStringAsFixed(2);
          _month = found.month;
          _year = found.year;
        });
      }
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final t = raw.replaceAll('.', '').replaceAll(',', '.').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = _parseAmount(_limitCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Informe um valor válido maior que zero.');
      return;
    }
    if (!_isEdit && _categoryId == null) {
      setState(() => _error = 'Selecione uma categoria.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(budgetsControllerProvider.notifier);
    try {
      if (_isEdit) {
        await controller.update(widget.budgetId!, limitAmount: amount);
      } else {
        await controller.create(
          categoryId: _categoryId!,
          limitAmount: amount,
          month: _month,
          year: _year,
        );
      }
      if (!mounted) return;
      context.go('/budgets');
    } on BudgetsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesControllerProvider).items
        .where((c) => c.type == TransactionType.expense)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar orçamento' : 'Novo orçamento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/budgets'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isEdit)
                _CategoryDropdown(
                  categories: categories,
                  value: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              if (!_isEdit) const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('budget-field-month'),
                      initialValue: _month,
                      decoration: const InputDecoration(
                        labelText: 'Mês',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0'))),
                      ],
                      onChanged: _isEdit
                          ? null
                          : (v) => setState(() => _month = v ?? _month),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: const Key('budget-field-year'),
                      initialValue: _year,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var y = DateTime.now().year - 2;
                            y <= DateTime.now().year + 5;
                            y++)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: _isEdit
                          ? null
                          : (v) => setState(() => _year = v ?? _year),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('budget-field-limit'),
                controller: _limitCtrl,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                ],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Limite (R\$)',
                  hintText: 'Ex: 800,00',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final amt = _parseAmount(v ?? '');
                  if (amt == null || amt <= 0) {
                    return 'Informe um valor válido';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  key: const Key('budget-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('budget-form-submit'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Salvar' : 'Criar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<CategoryFull> categories;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const Key('budget-field-category'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Categoria (despesa)',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final c in categories)
          DropdownMenuItem(value: c.id, child: Text(c.name)),
      ],
      onChanged: onChanged,
      validator: (v) {
        if (v == null) return 'Selecione uma categoria';
        return null;
      },
    );
  }
}
