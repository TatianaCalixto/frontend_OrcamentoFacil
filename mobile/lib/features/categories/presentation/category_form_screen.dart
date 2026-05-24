import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../transactions/data/transaction_models.dart';
import '../application/categories_controller.dart';
import '../data/categories_api.dart';
import '../data/category_models.dart';
import 'category_visuals.dart';

/// Form de criar/editar categoria. Quando `categoryId` é nulo, é criação.
class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _color = kCategoryColorPalette.first;
  String? _icon = 'category';

  bool _isDefault = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    if (!_isEdit) return;
    final list = ref.read(categoriesControllerProvider).items;
    CategoryFull? found;
    for (final c in list) {
      if (c.id == widget.categoryId) {
        found = c;
        break;
      }
    }
    if (found == null) return;
    setState(() {
      _isDefault = found!.isDefault;
      _nameCtrl.text = found.name;
      _type = found.type;
      _color = found.color ?? kCategoryColorPalette.first;
      _icon = found.icon ?? 'category';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final controller = ref.read(categoriesControllerProvider.notifier);
    try {
      if (_isEdit) {
        await controller.update(
          widget.categoryId!,
          name: _nameCtrl.text.trim(),
          type: _isDefault ? null : _type,
          color: _color,
          icon: _icon,
        );
      } else {
        await controller.create(
          name: _nameCtrl.text.trim(),
          type: _type,
          color: _color,
          icon: _icon,
        );
      }
      if (!mounted) return;
      context.go('/categories');
    } on CategoriesApiException catch (e) {
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
        title: Text(_isEdit ? 'Editar categoria' : 'Nova categoria'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/categories'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                key: const Key('cat-field-name'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Informe o nome';
                  if (t.length > 60) return 'No máximo 60 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_isDefault)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    key: const Key('cat-default-banner'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Categoria padrão do sistema: o tipo não pode ser alterado.',
                    ),
                  ),
                ),
              DropdownButtonFormField<TransactionType>(
                key: const Key('cat-field-type'),
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in TransactionType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: _isDefault
                    ? null
                    : (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              Text('Cor', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                key: const Key('cat-color-palette'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hex in kCategoryColorPalette)
                    GestureDetector(
                      key: Key('cat-color-$hex'),
                      onTap: () => setState(() => _color = hex),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: parseCategoryColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == hex
                                ? Colors.black87
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Ícone', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                key: const Key('cat-icon-palette'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in kCategoryIcons.entries)
                    GestureDetector(
                      key: Key('cat-icon-${entry.key}'),
                      onTap: () => setState(() => _icon = entry.key),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _icon == entry.key
                              ? parseCategoryColor(_color).withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _icon == entry.key
                                ? parseCategoryColor(_color)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(entry.value, size: 22),
                      ),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  key: const Key('cat-form-error'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('cat-form-submit'),
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
