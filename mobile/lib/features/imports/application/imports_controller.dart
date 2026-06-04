import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/import_models.dart';
import '../data/imports_api.dart';
import 'csv_file_picker.dart';

part 'imports_controller.freezed.dart';

/// Tamanho máximo aceito (2MB) — mesmo limite do backend.
const int kMaxCsvBytes = 2 * 1024 * 1024;

@freezed
abstract class ImportState with _$ImportState {
  const ImportState._();

  const factory ImportState({
    PickedCsv? picked,
    int? accountId,
    CsvImportResult? result,
    @Default(false) bool isUploading,
    String? errorMessage,
  }) = _ImportState;

  bool get canSubmit =>
      picked != null && accountId != null && !isUploading && _sizeOk;
  bool get _sizeOk => picked == null || picked!.sizeBytes <= kMaxCsvBytes;
  bool get isTooLarge => picked != null && picked!.sizeBytes > kMaxCsvBytes;
}

class ImportsController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  Future<void> pickFile() async {
    final picker = ref.read(csvFilePickerProvider);
    final picked = await picker.pick();
    if (picked == null) return;
    final lower = picked.name.toLowerCase();
    if (!lower.endsWith('.csv')) {
      state = state.copyWith(
        errorMessage: 'Selecione um arquivo .csv.',
        picked: null,
        result: null,
      );
      return;
    }
    state = state.copyWith(
      picked: picked,
      errorMessage: null,
      result: null,
    );
  }

  void selectAccount(int accountId) {
    state = state.copyWith(accountId: accountId, errorMessage: null);
  }

  Future<void> submit() async {
    final picked = state.picked;
    final accountId = state.accountId;
    if (picked == null || accountId == null) return;
    if (picked.sizeBytes > kMaxCsvBytes) {
      state = state.copyWith(
        errorMessage: 'Arquivo maior que 2MB. Reduza e tente novamente.',
      );
      return;
    }
    state = state.copyWith(isUploading: true, errorMessage: null, result: null);
    try {
      final api = ref.read(importsApiProvider);
      final res = await api.uploadCsv(
        accountId: accountId,
        filename: picked.name,
        bytes: picked.bytes,
      );
      state = state.copyWith(isUploading: false, result: res);
    } on ImportsApiException catch (e) {
      state = state.copyWith(isUploading: false, errorMessage: e.message);
    }
  }

  void reset() {
    state = const ImportState();
  }
}

final importsControllerProvider =
    NotifierProvider<ImportsController, ImportState>(ImportsController.new);
