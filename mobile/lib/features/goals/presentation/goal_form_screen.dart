import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/goals_controller.dart';
import '../data/goal_models.dart';
import '../data/goals_api.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({super.key, this.goalId});

  final int? goalId;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;
  String? _error;
  Goal? _existing;

  bool get _isEdit => widget.goalId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!_isEdit) return;
    final state = ref.read(goalsControllerProvider);
    Goal? found;
    for (final g in state.items) {
      if (g.id == widget.goalId) {
        found = g;
        break;
      }
    }
    if (found == null) return;
    setState(() {
      _existing = found;
      _nameCtrl.text = found!.name;
      _targetCtrl.text = found.targetAmount.toStringAsFixed(2);
      _currentCtrl.text = found.currentAmount.toStringAsFixed(2);
      _deadline = found.deadline;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final t = raw.replaceAll('.', '').replaceAll(',', '.').trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final target = _parseAmount(_targetCtrl.text);
    if (target == null || target <= 0) {
      setState(() => _error = 'Informe um valor-alvo válido.');
      return;
    }
    final current = _parseAmount(_currentCtrl.text) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(goalsControllerProvider.notifier);
    try {
      if (_isEdit) {
        await controller.update(
          widget.goalId!,
          name: _nameCtrl.text.trim(),
          targetAmount: target,
          currentAmount: current,
          deadline: _deadline,
          clearDeadline: _deadline == null && _existing?.deadline != null,
        );
      } else {
        await controller.create(
          name: _nameCtrl.text.trim(),
          targetAmount: target,
          currentAmount: current,
          deadline: _deadline,
        );
      }
      if (!mounted) return;
      context.go('/goals');
    } on GoalsApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar meta' : 'Nova meta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/goals'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('goal-field-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da meta',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o nome';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('goal-field-target'),
                controller: _targetCtrl,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                ],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor-alvo (R\$)',
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
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('goal-field-current'),
                controller: _currentCtrl,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
                ],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor atual (R\$)',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('goal-field-deadline'),
                onPressed: _pickDeadline,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _deadline == null
                      ? 'Prazo: opcional'
                      : 'Prazo: ${_fmt(_deadline!)}',
                ),
              ),
              if (_deadline != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('goal-deadline-clear'),
                    onPressed: () => setState(() => _deadline = null),
                    child: const Text('Remover prazo'),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  key: const Key('goal-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('goal-form-submit'),
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

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';
