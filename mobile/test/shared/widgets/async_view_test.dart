import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/shared/widgets/async_view.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AsyncView — 3 estados', () {
    testWidgets('LoadingView exibe CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingView()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('EmptyView exibe ícone e mensagem', (tester) async {
      await tester.pumpWidget(
        _wrap(const EmptyView(message: 'Nada por aqui', icon: Icons.receipt_long_outlined)),
      );
      expect(find.text('Nada por aqui'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('ErrorView exibe mensagem e botão que dispara onRetry', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(ErrorView(message: 'Falhou', onRetry: () => taps++)));
      expect(find.text('Falhou'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      expect(taps, 1);
    });

    testWidgets('ErrorView sem onRetry não exibe botão de retry', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorView(message: 'Falhou')));
      expect(find.text('Tentar novamente'), findsNothing);
    });

    testWidgets('variante scrollable mantém o conteúdo rolável', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyView(message: 'Vazio', scrollable: true)));
      expect(find.byType(Scrollable), findsWidgets);
      expect(find.text('Vazio'), findsOneWidget);
    });
  });
}
