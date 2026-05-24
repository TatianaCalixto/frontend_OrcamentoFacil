import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acesso tipado às variáveis de ambiente do app.
///
/// Em runtime as variáveis são carregadas do arquivo `.env` na inicialização
/// (ver `main.dart`). Em testes, o `.env` pode ser substituído por
/// `dotenv.testLoad('API_BASE_URL=...')`.
class AppEnv {
  AppEnv._();

  /// URL base do backend OrçaFácil.
  ///
  /// Default: `http://localhost:8000` quando a variável não está definida —
  /// útil para testes e para builds locais de desenvolvimento.
  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'http://localhost:8000';
}
