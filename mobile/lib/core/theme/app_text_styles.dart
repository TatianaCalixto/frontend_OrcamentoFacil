import 'package:flutter/material.dart';

/// Resolvers tipográficos do app. Para casos comuns, prefira o `textTheme`
/// do `Theme.of(context)` — esta classe centraliza variantes que aparecem
/// repetidas no app.
class AppTextStyles {
  AppTextStyles._();

  /// Título de seção dentro de cards/drawers — sm + bold + cor `outline`.
  static TextStyle sectionHeader(BuildContext context) {
    final base = Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    return base.copyWith(
      color: Theme.of(context).colorScheme.outline,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    );
  }

  /// Valor monetário em destaque — copyWith bold sobre o estilo base.
  static TextStyle money(BuildContext context, {Color? color}) {
    final base = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return base.copyWith(fontWeight: FontWeight.w600, color: color);
  }
}
