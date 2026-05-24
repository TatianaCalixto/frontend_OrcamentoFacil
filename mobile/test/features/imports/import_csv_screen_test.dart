import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orcafacil_mobile/features/imports/application/csv_file_picker.dart';
import 'package:orcafacil_mobile/features/imports/data/import_models.dart';
import 'package:orcafacil_mobile/features/imports/data/imports_api.dart';
import 'package:orcafacil_mobile/features/imports/presentation/import_csv_screen.dart';
import 'package:orcafacil_mobile/features/transactions/data/transaction_models.dart';
import 'package:orcafacil_mobile/features/transactions/data/transactions_api.dart';

import '../transactions/_fakes.dart' as tx_fakes;
import '_fakes.dart';

GoRouter _router() {
  return GoRouter(
    initialLocation: '/imports/csv',
    routes: [
      GoRoute(
        path: '/imports/csv',
        builder: (context, state) => const ImportCsvScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('DASH'))),
      ),
    ],
  );
}

Widget _wrap({
  required FakeImportsApi api,
  required FakeCsvFilePicker picker,
  tx_fakes.FakeTransactionsApi? txApi,
}) {
  final fakeTxApi = txApi ??
      tx_fakes.FakeTransactionsApi(
        accountsHandler: () async => [
          Account(id: 1, name: 'Conta principal'),
          Account(id: 2, name: 'Poupança'),
        ],
      );
  return ProviderScope(
    overrides: [
      importsApiProvider.overrideWithValue(api),
      csvFilePickerProvider.overrideWithValue(picker),
      transactionsApiProvider.overrideWithValue(fakeTxApi),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

PickedCsv _csv({String name = 'transacoes.csv', int size = 100}) {
  return PickedCsv(name: name, bytes: Uint8List(size));
}

void main() {
  group('ImportCsvScreen', () {
    testWidgets('renderiza picker de conta + área de arquivo', (tester) async {
      final api = FakeImportsApi();
      final picker = FakeCsvFilePicker();
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-field-account')), findsOneWidget);
      expect(find.byKey(const Key('import-file-area')), findsOneWidget);
      expect(find.text('Toque para escolher um arquivo .csv'), findsOneWidget);
      // Sem arquivo nem conta, o botão está desabilitado
      final btn = tester.widget<FilledButton>(
        find.byKey(const Key('import-btn-submit')),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('escolher arquivo .csv mostra nome e tamanho', (tester) async {
      final api = FakeImportsApi();
      final picker = FakeCsvFilePicker(
        next: _csv(name: 'extrato.csv', size: 2048),
      );
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();
      expect(find.text('extrato.csv'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('arquivo com extensão errada exibe erro amigável',
        (tester) async {
      final api = FakeImportsApi();
      final picker = FakeCsvFilePicker(next: _csv(name: 'invalido.txt'));
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-error')), findsOneWidget);
      expect(find.text('Selecione um arquivo .csv.'), findsOneWidget);
    });

    testWidgets('upload sucesso exibe contadores no painel de resultado',
        (tester) async {
      final api = FakeImportsApi(
        uploadHandler: ({required accountId, required filename, required bytes}) async {
          return CsvImportResult(
            createdCount: 10,
            skippedCount: 2,
            errors: const [],
          );
        },
      );
      final picker = FakeCsvFilePicker(next: _csv());
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();

      // Seleciona conta
      await tester.tap(find.byKey(const Key('import-field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();
      // Pega arquivo
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();
      // Envia
      await tester.tap(find.byKey(const Key('import-btn-submit')));
      await tester.pumpAndSettle();

      expect(api.uploadCalls, hasLength(1));
      expect(api.uploadCalls.first['accountId'], 1);
      expect(find.byKey(const Key('import-result')), findsOneWidget);
      expect(find.byKey(const Key('import-stat-created')), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('upload com erros mostra lista por linha', (tester) async {
      final api = FakeImportsApi(
        uploadHandler: ({required accountId, required filename, required bytes}) async {
          return CsvImportResult(
            createdCount: 5,
            skippedCount: 0,
            errors: [
              CsvImportError(lineNumber: 3, message: 'Data inválida'),
              CsvImportError(lineNumber: 7, message: 'Categoria não existe'),
            ],
          );
        },
      );
      final picker = FakeCsvFilePicker(next: _csv());
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-btn-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import-errors-list')), findsOneWidget);
      expect(find.text('Data inválida'), findsOneWidget);
      expect(find.text('Categoria não existe'), findsOneWidget);
    });

    testWidgets('erro do backend exibe mensagem amigável', (tester) async {
      final api = FakeImportsApi(
        uploadHandler: ({required accountId, required filename, required bytes}) async {
          throw ImportsApiException('formato inválido', statusCode: 400);
        },
      );
      final picker = FakeCsvFilePicker(next: _csv());
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-btn-submit')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-error')), findsOneWidget);
      expect(find.text('formato inválido'), findsOneWidget);
    });

    testWidgets('arquivo maior que 2MB bloqueia submit', (tester) async {
      final api = FakeImportsApi();
      // 2MB + 1 byte
      final picker = FakeCsvFilePicker(next: _csv(size: 2 * 1024 * 1024 + 1));
      await tester.pumpWidget(_wrap(api: api, picker: picker));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-field-account')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conta principal').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-file-area')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import-size-warning')), findsOneWidget);
      // Botão desabilitado
      final btn = tester.widget<FilledButton>(
        find.byKey(const Key('import-btn-submit')),
      );
      expect(btn.onPressed, isNull);
      expect(api.uploadCalls, isEmpty);
    });
  });
}
