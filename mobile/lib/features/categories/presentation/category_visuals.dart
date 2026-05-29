import 'package:flutter/material.dart';

/// Paleta padrão sugerida (hex sem `#`) — usuário pode selecionar uma delas.
const List<String> kCategoryColorPalette = [
  '#EF4444', // vermelho
  '#F59E0B', // laranja
  '#FBBF24', // amarelo
  '#10B981', // verde
  '#14B8A6', // teal
  '#3B82F6', // azul
  '#6366F1', // indigo
  '#8B5CF6', // roxo
  '#EC4899', // rosa
  '#64748B', // cinza
];

/// Ícones disponíveis identificados pela chave que persiste no backend.
const Map<String, IconData> kCategoryIcons = {
  'shopping_cart': Icons.shopping_cart,
  'restaurant': Icons.restaurant,
  'home': Icons.home,
  'directions_car': Icons.directions_car,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'sports_esports': Icons.sports_esports,
  'flight': Icons.flight,
  'pets': Icons.pets,
  'attach_money': Icons.attach_money,
  'card_giftcard': Icons.card_giftcard,
  'movie': Icons.movie,
  'subscriptions': Icons.subscriptions,
  'fitness_center': Icons.fitness_center,
  'local_gas_station': Icons.local_gas_station,
  'phone_android': Icons.phone_android,
  'water_drop': Icons.water_drop,
  'bolt': Icons.bolt,
  'savings': Icons.savings,
  'work': Icons.work,
  'category': Icons.category,
};

/// Converte string `#RRGGBB` ou `RRGGBB` para `Color`. Default cinza quando
/// inválido ou nulo.
Color parseCategoryColor(String? raw) {
  if (raw == null || raw.isEmpty) return Colors.grey;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  final intColor = int.tryParse(hex, radix: 16);
  if (intColor == null) return Colors.grey;
  return Color(intColor);
}

/// Resolve a `IconData` da categoria. Se a key não existir no mapa, retorna o
/// ícone genérico.
IconData iconForCategory(String? key) {
  if (key == null) return Icons.category;
  return kCategoryIcons[key] ?? Icons.category;
}
