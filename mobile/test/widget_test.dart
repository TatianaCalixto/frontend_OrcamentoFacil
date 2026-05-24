import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orcafacil_mobile/core/storage/token_storage.dart';
import 'package:orcafacil_mobile/features/auth/data/auth_api.dart';
import 'package:orcafacil_mobile/main.dart';

import 'support/fakes.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  testWidgets('App boota e exibe Splash sem token', (tester) async {
    final storage = _MockTokenStorage();
    when(storage.read).thenAnswer((_) async => null);
    when(storage.clear).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          authApiProvider.overrideWithValue(FakeAuthApi()),
        ],
        child: const OrcaFacilApp(),
      ),
    );

    // Splash inicial -> contém o título.
    expect(find.text('OrçaFácil'), findsWidgets);
  });
}
