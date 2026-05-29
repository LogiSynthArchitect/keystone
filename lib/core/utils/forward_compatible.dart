/// Static utilities for forward-compatible JSON serialization.
///
/// Preserves unknown fields through round-trips so that fields added
/// by future client versions survive any save/load cycle by any version.
///
/// Usage:
/// ```dart
/// class MyModel {
///   static const _kKnown = {'id', 'name', 'created_at'};
///   final Map<String, dynamic> _preserved;
///
///   factory MyModel.fromJson(Map<String, dynamic> json) => MyModel(
///     ... known fields ...,
///     _preserved: ForwardCompatible.extractPreserved(json, _kKnown),
///   );
///
///   Map<String, dynamic> toJson() => ForwardCompatible.buildJson(_preserved, {
///     'id': id,
///     'name': name,
///     'created_at': createdAt,
///   });
/// }
/// ```
class ForwardCompatible {
  /// Extract keys NOT in [knownKeys] from [json] into a preservation map.
  /// These keys survive the next [toJson] call without being stripped.
  static Map<String, dynamic> extractPreserved(Map<String, dynamic> json, Set<String> knownKeys) {
    final preserved = <String, dynamic>{};
    for (final key in json.keys) {
      if (!knownKeys.contains(key)) {
        preserved[key] = json[key];
      }
    }
    return preserved;
  }

  /// Build a JSON map starting from [preserved] then overlaying [knownFields].
  /// Unknown fields from the original parse survive the round-trip.
  static Map<String, dynamic> buildJson(Map<String, dynamic> preserved, Map<String, dynamic> knownFields) {
    final result = Map<String, dynamic>.from(preserved);
    result.addAll(knownFields);
    return result;
  }
}
