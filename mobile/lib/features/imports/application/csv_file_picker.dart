import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Arquivo CSV selecionado pelo usuário, em memória.
class PickedCsv {
  PickedCsv({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;
}

/// Abstração para escolher um CSV. Sobrescrita em testes via override do
/// provider, sem precisar de `file_picker` real.
abstract class CsvFilePicker {
  Future<PickedCsv?> pick();
}

class DefaultCsvFilePicker implements CsvFilePicker {
  const DefaultCsvFilePicker();

  @override
  Future<PickedCsv?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes == null) return null;
    return PickedCsv(name: f.name, bytes: bytes);
  }
}

final csvFilePickerProvider = Provider<CsvFilePicker>((ref) {
  return const DefaultCsvFilePicker();
});
