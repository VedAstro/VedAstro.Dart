import 'vedastro_exception.dart';

/// Raised when the API was reached but the call did not succeed.
///
/// This covers an HTTP failure (a non-2xx status), the API's own
/// `{"Status":"Fail", ...}` envelope, and a body that could not be decoded. The
/// request was delivered, so retrying the identical call is rarely the fix -
/// unlike [VedAstroException], which means the request never completed.
class ApiException extends VedAstroException {
  ApiException(
    String message, {
    required this.endpoint,
    this.statusCode = 0,
    this.payload,
    Object? cause,
  }) : super(message, cause);

  /// The API endpoint that failed, e.g. `PlanetRasiD1Sign`.
  final String endpoint;

  /// The HTTP status code, or 0 when the failure came from the API's own
  /// `Status: Fail` envelope on an otherwise successful response.
  final int statusCode;

  /// The API's own error text, when it supplied one.
  final String? payload;

  /// Whether the failure was an HTTP-level one (as opposed to a `Status: Fail`).
  bool get isHttpFailure => statusCode != 0;

  @override
  String toString() {
    final where = statusCode == 0 ? endpoint : '$endpoint (HTTP $statusCode)';
    final base = 'ApiException: $where: $message';
    return cause == null ? base : '$base (cause: $cause)';
  }
}
