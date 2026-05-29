import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/data/accounts_api.dart';
import '../../dashboard/presentation/dashboard_screen.dart' show formatBrl;
import '../application/transactions_controller.dart';
import '../data/transaction_models.dart';
import '../data/transactions_api.dart';

/// Modo da tela de formulário.
enum TransactionFormMode { create, edit }

/// Tela única para criar ou editar uma transação. No modo edit recebe o
/// `transactionId` via parâmetro de rota e carrega os dados via GET.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.transactionId,
  }) : mode = transactionId == null
            ? TransactionFormMode.create
            : TransactionFormMode.edit;

  final int? transactionId;
  final TransactionFormMode mode;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState
    extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  int? _accountId;
  int? _categoryId;
  DateTime _date = DateTime.now();
  PaymentMethod? _paymentMethod;
  bool _isRecurring = false;

  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.mode == TransactionFormMode.edit && widget.transactionId != null) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingInitial = true);
    try {
      final tx = await ref
          .read(transactionsApiProvider)
          .getById(widget.transactionId!);
      if (!mounted) return;
      setState(() {
        _type = tx.type;
        _accountId = tx.accountId;
        _categoryId = tx.categoryId;
        _amountCtrl.text = tx.amount.toStringAsFixed(2).replaceAll('.', ',');
        _descriptionCtrl.text = tx.description ?? '';
        _date = tx.date;
        _paymentMethod = tx.paymentMethod;
        _isRecurring = tx.isRecurring;
        _isLoadingInitial = false;
      });
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Aceita `1234,56` ou `1234.56`. Retorna `null` se inválido.
  double? _parseAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null || _categoryId == null) {
      setState(() => _errorMessage = 'Selecione conta e categoria.');
      return;
    }
    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null) {
      setState(() => _errorMessage = 'Valor inválido.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(transactionsApiProvider);
      final description = _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim();
      if (widget.mode == TransactionFormMode.create) {
        await api.create(
          accountId: _accountId!,
          categoryId: _categoryId!,
          type: _type,
          amount: amount,
          date: _date,
          description: description,
          paymentMethod: _paymentMethod,
          isRecurring: _isRecurring,
        );
      } else {
        await api.update(
          widget.transactionId!,
          accountId: _accountId,
          categoryId: _categoryId,
          type: _type,
          amount: amount,
          date: _date,
          description: description,
          paymentMethod: _paymentMethod,
          isRecurring: _isRecurring,
        );
      }
      // Atualiza a lista para refletir a nova/editada transação.
      await ref.read(transactionsControllerProvider.notifier).refresh();
      // Busca o saldo atual da conta afetada para mostrar no snackbar.
      // Se falhar, cai para a mensagem genérica (não bloqueia o fluxo).
      String snackText = widget.mode == TransactionFormMode.create
          ? 'Transação criada.'
          : 'Transação atualizada.';
      try {
        final acc = await ref.read(accountsApiProvider).get(_accountId!);
        snackText = 'Transação salva. Saldo de ${acc.name}: '
            '${formatBrl(acc.currentBalance)}';
      } on AccountsApiException {
        // mantém snackText genérico
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('tx-balance-snackbar'),
          content: Text(snackText),
        ),
      );
      context.go('/transactions');
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _deleteWithConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(transactionsControllerProvider.notifier)
          .delete(widget.transactionId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação excluída.')),
      );
      context.go('/transactions');
    } on TransactionsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == TransactionFormMode.edit;
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar transação' : 'Nova transação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/transactions'),
        ),
        actions: [
          if (isEdit)
            IconButton(
              key: const Key('btn-delete'),
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSubmitting ? null : _deleteWithConfirm,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingInitial
            ? const Center(
                key: Key('form-loading'),
                child: CircularProgressIndicator(),
              )
            : _buildForm(accountsAsync, categoriesAsync),
      ),
    );
  }

  Widget _buildForm(
    AsyncValue<List<Account>> accountsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return SingleChildScrollView(
      key: const Key('form-scroll'),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Despesa'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Receita'),
                  icon: Icon(Icons.trending_up),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('field-amount'),
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o valor';
                if (_parseAmount(v) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('field-description'),
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                key: const Key('field-date'),
                decoration: const InputDecoration(
                  labelText: 'Data',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_date.day.toString().padLeft(2, '0')}/'
                  '${_date.month.toString().padLeft(2, '0')}/'
                  '${_date.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _accountsField(accountsAsync),
            const SizedBox(height: 12),
            _categoriesField(categoriesAsync),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod?>(
              key: const Key('field-payment-method'),
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento (opcional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('—')),
                for (final p in PaymentMethod.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('field-recurring'),
              title: const Text('Recorrente'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('btn-submit'),
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                widget.mode == TransactionFormMode.create
                    ? 'Salvar'
                    : 'Atualizar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountsField(AsyncValue<List<Account>> accountsAsync) {
    return accountsAsync.when(
      data: (accounts) => DropdownButtonFormField<int?>(
        key: const Key('field-account'),
        initialValue: _accountId,
        decoration: const InputDecoration(
          labelText: 'Conta',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Selecione…')),
          for (final a in accounts)
            DropdownMenuItem(value: a.id, child: Text(a.name)),
        ],
        validator: (v) => v == null ? 'Selecione uma conta' : null,
        onChanged: (v) => setState(() => _accountId = v),
      ),
      loading: () => const LinearProgressIndicator(
        key: Key('field-account-loading'),
      ),
      error: (e, _) => Text('Erro ao carregar contas: $e'),
    );
  }

  Widget _categoriesField(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        // Filtra por tipo selecionado (income/expense).
        final visible =
            categories.where((c) => c.type == _type).toList(growable: false);
        // Se o categoryId selecionado não pertence ao novo tipo, limpa.
        if (_categoryId != null &&
            !visible.any((c) => c.id == _categoryId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _categoryId = null);
          });
        }
        return DropdownButtonFormField<int?>(
          key: const Key('field-category'),
          initialValue:
              visible.any((c) => c.id == _categoryId) ? _categoryId : null,
          decoration: const InputDecoration(
            labelText: 'Categoria',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Selecione…')),
            for (final c in visible)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          validator: (v) => v == null ? 'Selecione uma categoria' : null,
          onChanged: (v) => setState(() => _categoryId = v),
        );
      },
      loading: () => const LinearProgressIndicator(
        key: Key('field-category-loading'),
      ),
      error: (e, _) => Text('Erro ao carregar categorias: $e'),
    );
  }
}
