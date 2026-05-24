/// Erro individual de uma linha do CSV.
class CsvImportError {
  CsvImportError({required this.lineNumber, required this.message});

  factory CsvImportError.fromJson(Map<String, dynamic> json) {
    return CsvImportError(
      lineNumber: json['line_number'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }

  final int lineNumber;
  final String message;
}

/// Resultado completo de `POST /imports/csv`.
class CsvImportResult {
  CsvImportResult({
    required this.createdCount,
    required this.skippedCount,
    required this.errors,
  });

  factory CsvImportResult.fromJson(Map<String, dynamic> json) {
    final rawErrors = (json['errors'] as List?) ?? const [];
    return CsvImportResult(
      createdCount: json['created_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      errors: rawErrors
          .whereType<Map<String, dynamic>>()
          .map(CsvImportError.fromJson)
          .toList(growable: false),
    );
  }

  final int createdCount;
  final int skippedCount;
  final List<CsvImportError> errors;
}
