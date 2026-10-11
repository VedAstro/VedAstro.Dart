import 'dart:convert';
import 'dart:typed_data';

import 'package:vedastro/vedastro.dart';

/// A [Transport] that answers from memory and records what it was asked.
///
/// The whole stack above the transport is the real one, so the tests exercise the
/// actual request encoding, response unwrapping and error handling without a socket.
class FakeTransport implements Transport {
  FakeTransport(
      {this.statusCode = 200,
      this.contentType = 'application/json',
      String? body})
      : _body = body;

  int statusCode;
  String contentType;
  String? _body;

  /// Every request the client made, in order.
  final List<Uri> urls = [];

  /// The decoded JSON body of every request, in order.
  final List<Map<String, Object?>> bodies = [];

  /// The headers of every request, in order.
  final List<Map<String, String>> headers = [];

  bool closed = false;

  /// Sets the raw response body.
  set body(String value) => _body = value;

  Uri get lastUrl => urls.last;
  Map<String, Object?> get lastBody => bodies.last;
  Map<String, String> get lastHeaders => headers.last;

  /// Wraps [payload] in the API's envelope, nesting it under [method] as the
  /// service does.
  void respondWith(String method, Object? payload) {
    statusCode = 200;
    contentType = 'application/json';
    _body = jsonEncode({
      'Status': 'Pass',
      'Input': {'CalculatorName': method, 'Type': 'SingleCall'},
      'Payload': {method: payload},
    });
  }

  /// Answers with the API's own failure envelope.
  void respondFailure(String message) {
    statusCode = 200;
    contentType = 'application/json';
    _body = jsonEncode({'Status': 'Fail', 'Payload': message});
  }

  @override
  Future<TransportResponse> post(
    Uri url,
    String body,
    Map<String, String> headerMap,
  ) async {
    urls.add(url);
    headers.add(headerMap);
    final decoded = jsonDecode(body);
    bodies.add(
        decoded is Map ? decoded.cast<String, Object?>() : <String, Object?>{});

    return TransportResponse(
      statusCode,
      Uint8List.fromList(utf8.encode(_body ?? '{}')),
      contentType,
    );
  }

  @override
  void close() => closed = true;
}

/// A birth moment used across the tests: Mumbai, 25 October 1992 at 14:30 IST.
Time sampleBirth() => Time.of(
      '14:30 25/10/1992 +05:30',
      GeoLocation.of('Mumbai', 72.8777, 19.0760),
    );

/// Builds a client wired to [transport], matching how the demos construct one.
VedAstroClient clientWith(FakeTransport transport, {Ayanamsa? ayanamsa}) =>
    VedAstroClient(
      apiKey: 'test-key',
      baseUrl: 'https://example.test/api/Calculate',
      silent: true,
      defaultAyanamsa: ayanamsa,
      buildTransport: (_) => transport,
    );
