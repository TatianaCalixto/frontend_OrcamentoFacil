import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'import_models.dart';

class ImportsApiException implements Exception {
  ImportsApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => 'ImportsApiException($statusCode/$code): $message';
}

class ImportsApi {
  ImportsApi(this._dio);
  final Dio _dio;

  /// Envia `POST /imports/csv` multipart com `account_id` e arquivo.
  Future<CsvImportResult> uploadCsv({
    required int accountId,
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final form = FormData.fromMap({
        'account_id': accountId.toString(),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType('text', 'csv'),
        ),
      });
      final res = await _dio.post<Map<String, dynamic>>(
        '/imports/csv',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return CsvImportResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toException(e, fallback: 'Falha ao importar CSV.');
    }
  }

  ImportsApiException _toException(
    DioException e, {
    required String fallback,
  }) {
    final data = e.response?.data;
    String? detail;
    String? code;
    if (data is Map) {
      final rawDetail = data['detail'];
      if (rawDetail is String) {
        detail = rawDetail;
      } else if (rawDetail != null) {
        detail = rawDetail.toString();
      }
      final rawCode = data['code'];
      if (rawCode is String) code = rawCode;
    }
    return ImportsApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

final importsApiProvider = Provider<ImportsApi>((ref) {
  return ImportsApi(ref.watch(apiClientProvider));
});
