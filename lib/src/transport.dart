import 'dart:typed_data';

/// What a [Transport] returns: the raw bytes, the status and the content type.
///
/// Kept deliberately small so a custom transport (a proxy, an in-process stub) has
/// almost nothing to implement.
class TransportResponse {
  TransportResponse(this.statusCode, this.body, this.contentType);

  /// The HTTP status code, or 0 when the transport could not obtain one.
  final int statusCode;

  /// The raw response body.
  ///
  /// Bytes rather than a `String`, because chart endpoints answer with SVG and the
  /// transport should not have to guess an encoding.
  final Uint8List body;

  /// The `Content-Type` header, lower-cased, or an empty string.
  final String contentType;

  /// Whether the status is a success status.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// The body decoded as UTF-8 text.
  String get text => String.fromCharCodes(body);
}

/// Where the client sends its requests.
///
/// Implement this to route VedAstro traffic through a proxy, a mock, or a shared
/// connection pool you already own. The default is `HttpTransport`.
abstract interface class Transport {
  /// Sends a POST and returns the response.
  ///
  /// [headers] carries the content type and the API key, so an implementation that
  /// logs should treat them as sensitive. Throw a `VedAstroException` when the
  /// request cannot be completed at all.
  Future<TransportResponse> post(
    Uri url,
    String body,
    Map<String, String> headers,
  );

  /// Releases any resources the transport holds.
  ///
  /// The default implementation owns an HTTP client, so call this when you are
  /// finished with the client - for example in a server's shutdown hook.
  void close() {}
}
