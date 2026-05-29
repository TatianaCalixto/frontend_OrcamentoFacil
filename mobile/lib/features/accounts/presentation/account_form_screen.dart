import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/accounts_controller.dart';
import '../data/account_models.dart';
import '../data/accounts_api.dart';

enum AccountFormMode { create, edit }

/// Tela única para criar ou editar uma conta. No modo edit, recebe `accountId`
/// pela rota e carrega os dados via `GET /accounts/{id}`. Saldo inicial só
/// pode ser definido na criação (não é editável no PATCH).
class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({
    super.key,
    this.accountId,
  }) : mode = accountId == null ? AccountFormMode.create : AccountFormMode.edit;

  final int? accountId;
  final AccountFormMode mode;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _initialBalanceCtrl = TextEditingController(text: '0,00');

  AccountType _type = AccountType.checking;
  bool _isActive = true;

  bool _isLoadingInitial = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.mode == AccountFormMode.edit;

  @override
  void initState() {
    super.initState();
    if (_isEdit && widget.accountId != null) {
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initialBalanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingInitial = true);
    try {
      final acc = await ref.read(accountsApiProvider).get(widget.accountId!);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = acc.name;
        _type = acc.type;
        _isActive = acc.isActive;
        _initialBalanceCtrl.text =
            acc.initialBalance.toStringAsFixed(2).replaceAll('.', ',');
        _isLoadingInitial = false;
      });
    } on AccountsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInitial = false;
        _errorMessage = e.message;
      });
    }
  }

  /// Aceita `1234,56` ou `1234.56` ou `1.500,75`. Retorna `null` se inválido.
  /// Aceita zero. Se houver vírgula, trata como formato BR (ponto = milhar);
  /// caso contrário, ponto é o separador decimal.
  double? _parseInitialBalance(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.contains(',')
        ? trimmed.replaceAll('.', '').replaceAll(',', '.')
        : trimmed;
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return value;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final controller = ref.read(accountsControllerProvider.notifier);
    try {
      if (_isEdit) {
        await controller.update(
          widget.accountId!,
          name: _nameCtrl.text.trim(),
          type: _type,
          isActive: _isActive,
        );
      } else {
        final initialBalance = _parseInitialBalance(_initialBalanceCtrl.text);
        if (initialBalance == null) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Saldo inicial inválido.';
          });
          return;
        }
        await controller.create(
          name: _nameCtrl.text.trim(),
          type: _type,
          initialBalance: initialBalance,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Conta atualizada.' : 'Conta criada.'),
        ),
      );
      context.go('/accounts');
    } on AccountsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar conta')),
        body: const Center(
          key: Key('acc-form-loading'),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar conta' : 'Nova conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/accounts'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('acc-field-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o nome';
                  if (t.length > 80) return 'No máximo 80 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AccountType>(
                key: const Key('acc-field-type'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in AccountType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('acc-field-initial-balance'),
                controller: _initialBalanceCtrl,
                enabled: !_isEdit,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Saldo inicial (R\$)',
                  helperText: _isEdit
                      ? 'Saldo inicial não pode ser alterado após a criação.'
                      : 'Use vírgula ou ponto. Mínimo 0.',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_isEdit) return null;
                  final parsed = _parseInitialBalance(v ?? '');
                  if (parsed == null) return 'Saldo inicial inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                key: const Key('acc-field-active'),
                title: const Text('Conta ativa'),
                subtitle: Text(
                  _isActive
                      ? 'Aparece nos seletores de transação.'
                      : 'Não aparece nos seletores até reativar.',
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  key: const Key('acc-form-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('acc-form-submit'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
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
