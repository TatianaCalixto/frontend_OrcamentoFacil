import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orcafacil_mobile/main.dart';

void main() {
  testWidgets('App inicializa e renderiza placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrcaFacilApp()));

    expect(find.text('OrçaFácil — estrutura inicial'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
