/// Reads values out of a decoded API payload without throwing on a wrong shape.
///
/// PHP, Python and Node callers can index a decoded payload and risk a crash on an
/// unexpected shape. Dart is null-safe, so this class does the same job with the
/// compiler's help: every accessor returns a null-or-default value and never
/// throws, which means a service can stay up when the API changes shape.
///
/// The payload from most calculators is a `Map<String, Object?>`. Chart
/// endpoints return SVG markup as a bare `String`, and a few return a number or a
/// list, so the accessors accept any `Object?`.
///
/// ```dart
/// final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
/// final sign = Response.string(sun, 'Name');                  // "Libra"
/// final degree = Response.doubleValue(sun, ['DegreesIn', 'TotalDegrees']);
/// ```
abstract final class Response {
  /// The value at [path], or `null` when any step is missing.
  ///
  /// [path] is a key, a list of keys for a nested lookup, or an index list
  /// (strings address map keys, integers address list positions).
  static Object? get(Object? payload, Object path) {
    if (path is Iterable) {
      Object? current = payload;
      for (final Object? step in path) {
        current = _step(current, step);
        if (current == null) return null;
      }
      return current;
    }
    return _step(payload, path);
  }

  /// Whether [path] resolves to a non-null value.
  static bool has(Object? payload, Object path) => get(payload, path) != null;

  /// The value at [path] as a `String`, or [fallback] when it is absent or a
  /// different type.
  static String string(Object? payload, Object path, {String fallback = ''}) {
    final value = get(payload, path);
    if (value is String) return value;
    // A number or bool is still useful as text; anything else is not.
    if (value is num || value is bool) return value.toString();
    return fallback;
  }

  /// The value at [path] as a `double`.
  ///
  /// The API sends some numbers as strings (`"8.441944444444445"`), so both are
  /// accepted - which is exactly the kind of thing that otherwise becomes a
  /// runtime cast error in production.
  static double? doubleValue(Object? payload, Object path) {
    final value = get(payload, path);
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// The value at [path] as an `int`, rounding a fractional number and parsing a
  /// numeric string.
  static int? intValue(Object? payload, Object path) {
    final value = get(payload, path);
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round();
    }
    return null;
  }

  /// The value at [path] as a `bool`.
  static bool? boolValue(Object? payload, Object path) {
    final value = get(payload, path);
    if (value is bool) return value;
    if (value is String) {
      final normalised = value.trim().toLowerCase();
      if (normalised == 'true') return true;
      if (normalised == 'false') return false;
    }
    return null;
  }

  /// The value at [path] as a list, or an empty list when it is absent or not a
  /// list.
  static List<Object?> list(Object? payload, Object path) {
    final value = get(payload, path);
    return value is List ? value.cast<Object?>() : const <Object?>[];
  }

  /// The value at [path] as a map, or an empty map when it is absent or not a map.
  static Map<String, Object?> map(Object? payload, Object path) {
    final value = get(payload, path);
    if (value is Map) return value.cast<String, Object?>();
    return const <String, Object?>{};
  }

  /// The number of entries in the list or map at [path], or 0.
  static int count(Object? payload, Object path) {
    final value = get(payload, path);
    if (value is List) return value.length;
    if (value is Map) return value.length;
    if (value is String) return value.length;
    return 0;
  }

  static Object? _step(Object? current, Object? step) {
    if (step is int) {
      if (current is List && step >= 0 && step < current.length) {
        return current[step];
      }
      return null;
    }
    if (current is Map) return current[step.toString()];
    return null;
  }
}
