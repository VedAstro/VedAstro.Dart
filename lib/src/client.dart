import 'dart:convert';

import 'api_exception.dart';
import 'generated/calculators.dart';
import 'generated/enums.dart';
import 'geo_location.dart';
import 'http_transport.dart';
import 'time.dart';
import 'transport.dart';
import 'vedastro_exception.dart';

export 'api_exception.dart';
export 'generated/calculators.dart';
export 'generated/enums.dart';
export 'geo_location.dart';
export 'response.dart';
export 'time.dart';
export 'transport.dart';
export 'vedastro_exception.dart';

/// Talks to the VedAstro API.
///
/// One instance owns its configuration and holds no per-request state, so a server
/// can build it once at start-up and reuse it for every incoming request.
///
/// ```dart
/// final client = VedAstroClient(apiKey: Platform.environment['VEDASTRO_API_KEY']);
/// final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
/// ```
///
/// **No request timeout is applied by default.** A calculation can take
/// milliseconds or minutes depending on the endpoint and the load on the service,
/// and only you know what is acceptable for your workload, so this library does not
/// guess. Pass [timeout] when your own budget demands a deadline.
class VedAstroClient {
  /// Creates a client.
  ///
  /// [apiKey] may be empty, which uses the service's free tier. [timeout] is optional.
  /// [buildTransport] supplies a custom transport, for a proxy or a test double.
  VedAstroClient({
    this.apiKey = '',
    this.timeout,
    this.silent = false,
    this.defaultAyanamsa,
    Transport Function(Duration? timeout)? buildTransport,
  }) : _transport = (buildTransport ?? _defaultTransport)(timeout) {
    if (timeout != null && timeout! <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'must be positive when set, or null for no deadline',
      );
    }
    _calculators = Calculators(this);
    if (!silent) _printBannerOnce();
  }

  /// Builds a client from `VEDASTRO_API_KEY` when set.
  ///
  /// The environment is passed in rather than read here, so this library does not
  /// force a `dart:io` import on you and stays usable in the browser:
  ///
  /// ```dart
  /// final client = VedAstroClient.fromEnvironment(Platform.environment);
  /// ```
  factory VedAstroClient.fromEnvironment(
    Map<String, String> environment, {
    String apiKeyVariable = 'VEDASTRO_API_KEY',
    Duration? timeout,
    bool silent = false,
  }) {
    final key = environment[apiKeyVariable];
    return VedAstroClient(
      apiKey: key ?? '',
      timeout: timeout,
      silent: silent,
    );
  }

  /// The public calculator service.
  static const String _apiEndpoint =
      'https://vedastro.zaishi.net/api/Calculate';

  /// The release version.
  static const String version = '1.0.0';

  /// Your API key, or an empty string for the free tier.
  final String apiKey;

  /// The per-call deadline, or `null` - the default - for none.
  final Duration? timeout;

  /// Whether the one-line start-up banner is suppressed.
  final bool silent;

  /// An ayanamsa sent with every request from this client.
  final Ayanamsa? defaultAyanamsa;

  final Transport _transport;
  late final Calculators _calculators;

  static bool _bannerPrinted = false;

  /// The 684 calculators, used as `client.calculate().planetRasiD1Sign(...)`.
  Calculators calculate() => _calculators;

  /// Whether a non-empty API key is configured.
  bool get hasApiKey => apiKey.isNotEmpty;

  /// The ayanamsa sent with this client's requests, or `null` for the API's own
  /// default.
  Ayanamsa? get ayanamsa => defaultAyanamsa;

  /// Calls any endpoint by name, including one with no generated method.
  ///
  /// Prefer the generated methods on [calculate]. This is the escape hatch for a
  /// calculator the service has added before this package caught up.
  ///
  /// [ayanamsa] overrides the client's default for this call only.
  Future<Object?> call(
    String endpoint, {
    Map<String, Object?> parameters = const {},
    Ayanamsa? ayanamsa,
  }) async {
    final response = await _send(endpoint, parameters, ayanamsa);
    return _decode(endpoint, response);
  }

  /// Calls [endpoint] and returns everything the API sent, not only the payload.
  ///
  /// Useful for diagnostics, or when the HTTP status matters to you.
  Future<ApiResponse> callWithResponse(
    String endpoint, {
    Map<String, Object?> parameters = const {},
    Ayanamsa? ayanamsa,
  }) async {
    final response = await _send(endpoint, parameters, ayanamsa);
    return ApiResponse(
      endpoint: endpoint,
      statusCode: response.statusCode,
      payload: _decode(endpoint, response),
      contentType: response.contentType,
    );
  }

  /// Releases the transport's resources.
  ///
  /// Call this when shutting down. A server that lives as long as the process does
  /// never needs to.
  void close() => _transport.close();

  /// Builds the request and sends it, so `call` and `callWithResponse` share one
  /// code path.
  Future<TransportResponse> _send(
    String endpoint,
    Map<String, Object?> parameters,
    Ayanamsa? ayanamsa,
  ) async {
    if (endpoint.trim().isEmpty) {
      throw ArgumentError.value(endpoint, 'endpoint', 'must not be blank');
    }

    final body = <String, Object?>{
      // A null value means "omit this argument", so the server applies its own
      // default. That is also how the generated methods express an absent optional.
      for (final entry in parameters.entries)
        if (entry.value != null) entry.key: _wireValue(entry.value),
    };

    if (apiKey.isNotEmpty) body['APIKey'] = apiKey;
    final scoped = ayanamsa ?? defaultAyanamsa;
    if (scoped != null && !body.containsKey('Ayanamsa')) {
      body['Ayanamsa'] = scoped.wireName;
    }

    final url = Uri.parse(
      '${_apiEndpoint}/$endpoint',
    );

    try {
      return await _transport.post(url, jsonEncode(body), {
        'Content-Type': 'application/json',
        'Accept': 'application/json, image/svg+xml',
      });
    } catch (failure) {
      // Shape every transport failure the same way, and make sure the key cannot
      // leak through a message a transport chose to build.
      final detail = failure is VedAstroException
          ? failure.message
          : 'vedastro: request to $url failed ($failure)';
      throw VedAstroException(
        _redact(detail),
        failure is VedAstroException ? failure.cause : failure,
      );
    }
  }

  /// Turns a transport response into the value the caller asked for.
  Object? _decode(String endpoint, TransportResponse response) {
    final text = response.text;

    // Chart endpoints answer with SVG markup rather than an envelope.
    if (response.contentType.contains('image/svg+xml') ||
        RegExp(r'^\s*<svg[\s>]', caseSensitive: false).hasMatch(text)) {
      if (!response.isSuccess) {
        throw ApiException(
          'the chart endpoint returned HTTP ${response.statusCode}',
          endpoint: endpoint,
          statusCode: response.statusCode,
        );
      }
      return text;
    }

    if (!response.isSuccess) {
      throw ApiException(
        _summarise(text),
        endpoint: endpoint,
        statusCode: response.statusCode,
        payload: text,
      );
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(text);
    } on FormatException catch (failure) {
      throw ApiException(
        'the API returned invalid JSON: ${failure.message}',
        endpoint: endpoint,
        statusCode: response.statusCode,
        cause: failure,
      );
    }

    if (parsed is! Map<String, Object?>) {
      throw ApiException(
        'the API returned an unexpected top-level type (${parsed.runtimeType})',
        endpoint: endpoint,
        statusCode: response.statusCode,
      );
    }
    final decoded = parsed;

    if (decoded['Status'] == 'Fail') {
      throw ApiException(
        _redact('${decoded['Payload'] ?? 'Unknown error'}'),
        endpoint: endpoint,
        payload: decoded['Payload']?.toString(),
      );
    }

    if (!decoded.containsKey('Payload') || decoded['Payload'] == null) {
      throw ApiException(
        'the API response is missing its Payload',
        endpoint: endpoint,
        statusCode: response.statusCode,
      );
    }

    final payload = decoded['Payload'];

    // The API nests every result under the method name. A payload object with
    // exactly one property is unwrapped to that property, which is why most
    // calculators hand back the inner value directly - sometimes a bare string.
    if (payload is Map && payload.length == 1) return payload.values.first;
    return payload;
  }

  /// Converts a Dart value into the JSON the API expects.
  static Object? _wireValue(Object? value) {
    if (value is Ayanamsa) return value.wireName;
    if (value is PlanetName) return value.wireName;
    if (value is Time) return value.toJson();
    if (value is GeoLocation) return value.toJson();
    if (value is Enum) return value.name;
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _wireValue(entry.value),
      };
    }
    if (value is Iterable) return value.map(_wireValue).toList();
    return value;
  }

  /// A short, key-free summary of an error body, for an exception message.
  ///
  /// An instance method rather than a static one, because redaction needs the key.
  String _summarise(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'the API returned an empty error body';
    final clipped =
        trimmed.length > 300 ? '${trimmed.substring(0, 300)}...' : trimmed;
    return _redact(clipped);
  }

  /// Removes the API key from a message. The key itself is never echoed.
  String _redact(String message) {
    if (apiKey.isEmpty) return message;
    return message.replaceAll(apiKey, '[redacted]');
  }

  static Transport _defaultTransport(Duration? timeout) =>
      HttpTransport(timeout: timeout);

  static void _printBannerOnce() {
    if (_bannerPrinted) return;
    _bannerPrinted = true;
    // The family prints this once per process; `silent: true` suppresses it for
    // anything that writes a response body.
    // ignore: avoid_print
    print('VedAstro : Easy To Use Advanced Astrology API');
  }
}

/// Everything the API sent for one call, returned by
/// [VedAstroClient.callWithResponse].
class ApiResponse {
  const ApiResponse({
    required this.endpoint,
    required this.statusCode,
    required this.payload,
    required this.contentType,
  });

  /// The endpoint that was called.
  final String endpoint;

  /// The HTTP status code.
  final int statusCode;

  /// The unwrapped payload, exactly as [VedAstroClient.call] would return it.
  final Object? payload;

  /// The response's content type.
  final String contentType;

  @override
  String toString() => 'ApiResponse($endpoint, HTTP $statusCode)';
}
