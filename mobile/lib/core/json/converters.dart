import 'package:freezed_annotation/freezed_annotation.dart';

/// Converte o campo monetário do backend (Decimal serializado como String,
/// ex.: `"12.34"`) para `double` no Dart, tolerando também `num`. Replica a
/// semântica do antigo helper `_toDouble`. Na serialização devolve o próprio
/// número (round-trip estável). Centraliza a regra usada por todos os models.
class DecimalToDoubleConverter implements JsonConverter<double, Object?> {
  const DecimalToDoubleConverter();

  @override
  double fromJson(Object? json) {
    if (json == null) return 0;
    if (json is num) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0;
    return 0;
  }

  @override
  Object? toJson(double object) => object;
}
