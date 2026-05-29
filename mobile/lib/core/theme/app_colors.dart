import 'package:flutter/material.dart';

/// Cores semânticas do app, independentes de claro/escuro.
///
/// Use estas constantes em vez de `Colors.green/red/...` hardcoded para que
/// uma futura troca de paleta (ou ajuste para WCAG) aconteça num único lugar.
class AppColors {
  AppColors._();

  /// Receita / sucesso / orçamento saudável.
  static const Color success = Color(0xFF4CAF50); // Colors.green
  static const Color successDark = Color(0xFF66BB6A);

  /// Despesa / erro / orçamento crítico.
  static const Color danger = Color(0xFFF44336); // Colors.red
  static const Color dangerDark = Color(0xFFE57373);

  /// Aviso / orçamento próximo do limite.
  static const Color warning = Color(0xFFFF9800); // Colors.orange
  static const Color warningDark = Color(0xFFFFB74D);

  /// Realce neutro / informativo / saldo positivo do mês.
  static const Color info = Color(0xFF009688); // Colors.teal
  static const Color infoDark = Color(0xFF4DB6AC);

  /// Texto/ícone secundário em cards.
  static const Color neutral = Color(0xFF607D8B); // Colors.blueGrey

  /// Banner de atenção (categoria padrão, etc).
  static const Color attention = Color(0xFFFFC107); // Colors.amber

  /// Variante mais escura do vermelho para saldo negativo.
  static Color get dangerStrong => Colors.red.shade700;
}

/// `ColorScheme` claro padrão do app — Material 3 seed-based com a cor
/// primária do projeto (mesmo azul do painel: #1E88E5).
ColorScheme appLightScheme() {
  return ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
  );
}

/// `ColorScheme` escuro com contraste validado para texto normal (WCAG AA
/// > 4.5:1 sobre surface escuro).
ColorScheme appDarkScheme() {
  return ColorScheme.fromSeed(
    seedColor: const Color(0xFF1E88E5),
    brightness: Brightness.dark,
  );
}
