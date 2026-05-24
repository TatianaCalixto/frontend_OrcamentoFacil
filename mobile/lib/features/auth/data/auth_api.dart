import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

/// Modelo simples do usuário retornado pelo backend (UserRead).
class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  final int id;
  final String name;
  final String email;
}

/// Resultado de um POST /auth/login bem-sucedido.
class AuthToken {
  AuthToken({required this.accessToken, required this.tokenType});

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
    );
  }

  final String accessToken;
  final String tokenType;
}

/// Exceção que carrega uma mensagem amigável para exibir ao usuário,
/// derivada do payload de erro do backend (`{ detail, code, request_id }`).
class AuthApiException implements Exception {
  AuthApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'AuthApiException($statusCode/$code): $message';
}

/// Wrapper das chamadas HTTP de autenticação contra o backend OrçaFácil.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// POST /auth/register — cria um novo usuário.
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toAuthException(e, fallback: 'Falha ao cadastrar.');
    }
  }

  /// POST /auth/login — retorna access_token JWT.
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthToken.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toAuthException(e, fallback: 'Falha ao entrar.');
    }
  }

  /// GET /users/me — valida o token atual e retorna o usuário logado.
  Future<AuthUser> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw _toAuthException(e, fallback: 'Sessão inválida.');
    }
  }

  AuthApiException _toAuthException(
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
    return AuthApiException(
      detail ?? fallback,
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

/// Provider Riverpod do `AuthApi`.
final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthApi(dio);
});
