import 'dart:typed_data';

import 'package:orcafacil_mobile/features/imports/application/csv_file_picker.dart';
import 'package:orcafacil_mobile/features/imports/data/import_models.dart';
import 'package:orcafacil_mobile/features/imports/data/imports_api.dart';

class FakeCsvFilePicker implements CsvFilePicker {
  FakeCsvFilePicker({this.next});

  PickedCsv? next;
  int calls = 0;

  @override
  Future<PickedCsv?> pick() async {
    calls++;
    return next;
  }
}

class FakeImportsApi implements ImportsApi {
  FakeImportsApi({this.uploadHandler});

  Future<CsvImportResult> Function({
    required int accountId,
    required String filename,
    required Uint8List bytes,
  })? uploadHandler;

  final List<Map<String, dynamic>> uploadCalls = [];

  @override
  Future<CsvImportResult> uploadCsv({
    required int accountId,
    required String filename,
    required Uint8List bytes,
  }) {
    uploadCalls.add({
      'accountId': accountId,
      'filename': filename,
      'bytes': bytes.length,
    });
    if (uploadHandler != null) {
      return uploadHandler!(
        accountId: accountId,
        filename: filename,
        bytes: bytes,
      );
    }
    return Future.value(CsvImportResult(
      createdCount: 0,
      skippedCount: 0,
      errors: const [],
    ));
  }
}
