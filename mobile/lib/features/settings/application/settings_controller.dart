import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_controller.freezed.dart';

/// Modo de tema persistente.
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  ThemeMode get materialMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  String get label => switch (this) {
        AppThemeMode.system => 'Sistema',
        AppThemeMode.light => 'Claro',
        AppThemeMode.dark => 'Escuro',
      };
}

/// Estado das preferências do app.
@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('pt-BR') String language,
  }) = _SettingsState;
}

/// Storage abstrato de preferências (key/value). Implementação padrão usa
/// `FlutterSecureStorage`; em testes pode ser substituído por um in-memory.
abstract class SettingsStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class _SecureSettingsStorage implements SettingsStorage {
  const _SecureSettingsStorage();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final settingsStorageProvider = Provider<SettingsStorage>(
  (ref) => const _SecureSettingsStorage(),
);

const String _kThemeKey = 'app.theme_mode';
const String _kLanguageKey = 'app.language';

AppThemeMode _parseThemeMode(String? raw) {
  switch (raw) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    case 'system':
    default:
      return AppThemeMode.system;
  }
}

String _themeModeToString(AppThemeMode m) => switch (m) {
      AppThemeMode.system => 'system',
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
    };

/// Controller de preferências com persistência via SettingsStorage.
class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Dispara hidratação assíncrona sem bloquear o build.
    Future.microtask(_hydrate);
    return const SettingsState();
  }

  SettingsStorage get _storage => ref.read(settingsStorageProvider);

  Future<void> _hydrate() async {
    try {
      final t = await _storage.read(_kThemeKey);
      final l = await _storage.read(_kLanguageKey);
      state = state.copyWith(
        themeMode: _parseThemeMode(t),
        language: l ?? state.language,
      );
    } catch (_) {
      // Storage indisponível (ex: testes sem plugin): mantém defaults.
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      await _storage.write(_kThemeKey, _themeModeToString(mode));
    } catch (_) {
      // ignora — preferência ainda vale para a sessão.
    }
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    try {
      await _storage.write(_kLanguageKey, lang);
    } catch (_) {}
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
