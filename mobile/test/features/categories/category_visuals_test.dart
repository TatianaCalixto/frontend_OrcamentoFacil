import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/features/categories/presentation/category_visuals.dart';

void main() {
  group('iconForCategory', () {
    test('chave conhecida retorna o IconData mapeado', () {
      expect(iconForCategory('shopping_cart'), Icons.shopping_cart);
      expect(iconForCategory('restaurant'), Icons.restaurant);
      expect(iconForCategory('local_hospital'), Icons.local_hospital);
      expect(iconForCategory('savings'), Icons.savings);
    });

    test('chave desconhecida cai no fallback Icons.category', () {
      expect(iconForCategory('inexistente_xyz'), Icons.category);
    });

    test('chave nula cai no fallback Icons.category', () {
      expect(iconForCategory(null), Icons.category);
    });

    test('catálogo cobre pelo menos 20 ícones', () {
      expect(kCategoryIcons.length, greaterThanOrEqualTo(20));
    });
  });

  group('parseCategoryColor', () {
    test('hex com # produz Color válido', () {
      expect(parseCategoryColor('#EF4444').toARGB32(), 0xFFEF4444);
    });
    test('hex sem # também funciona', () {
      expect(parseCategoryColor('10B981').toARGB32(), 0xFF10B981);
    });
    test('valor nulo retorna cinza', () {
      expect(parseCategoryColor(null), Colors.grey);
    });
    test('valor inválido retorna cinza', () {
      expect(parseCategoryColor('zzz'), Colors.grey);
    });
  });
}
