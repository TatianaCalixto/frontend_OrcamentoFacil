import 'package:orcafacil_mobile/features/settings/application/settings_controller.dart';

class InMemorySettingsStorage implements SettingsStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}
