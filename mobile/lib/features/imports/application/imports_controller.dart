import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import_models.dart';
import '../data/imports_api.dart';
import 'csv_file_picker.dart';

/// Tamanho máximo aceito (2MB) — mesmo limite do backend.
const int kMaxCsvBytes = 2 * 1024 * 1024;

class ImportState {
  const ImportState({
    this.picked,
    this.accountId,
    this.result,
    this.isUploading = false,
    this.errorMessage,
  });

  final PickedCsv? picked;
  final int? accountId;
  final CsvImportResult? result;
  final bool isUploading;
  final String? errorMessage;

  bool get canSubmit =>
      picked != null && accountId != null && !isUploading && _sizeOk;
  bool get _sizeOk => picked == null || picked!.sizeBytes <= kMaxCsvBytes;
  bool get isTooLarge => picked != null && picked!.sizeBytes > kMaxCsvBytes;

  ImportState copyWith({
    PickedCsv? picked,
    int? accountId,
    CsvImportResult? result,
    bool? isUploading,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
    bool clearPicked = false,
  }) {
    return ImportState(
      picked: clearPicked ? null : (picked ?? this.picked),
      accountId: accountId ?? this.accountId,
      result: clearResult ? null : (result ?? this.result),
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
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
        clearPicked: true,
        clearResult: true,
      );
      return;
    }
    state = state.copyWith(
      picked: picked,
      clearError: true,
      clearResult: true,
    );
  }

  void selectAccount(int accountId) {
    state = state.copyWith(accountId: accountId, clearError: true);
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
    state = state.copyWith(isUploading: true, clearError: true, clearResult: true);
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
