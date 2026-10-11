import 'dart:async';

import 'package:http/http.dart' as http;

import 'transport.dart';
import 'vedastro_exception.dart';

/// The default [Transport], built on `package:http`.
///
/// `package:http` is the Dart team's own client. It is the one dependency this
/// package has, and it is what makes the transport swappable in tests: pass a
/// `MockClient` and the whole stack can be exercised without a socket.
///
/// **No deadline is applied unless you supply one.** A VedAstro calculation can
/// take milliseconds or minutes, and a client library cannot know what is
/// acceptable for the caller's workload, so imposing a default would be brittle
/// logic that can truncate a valid answer.
class HttpTransport implements Transport {
  /// Wraps an HTTP client with an optional deadline.
  ///
  /// When an inner client is omitted, this transport owns the one it creates and
  /// releases it on close. When you pass your own - a pooled client, a `MockClient` -
  /// it is left alone, because you own its lifetime.
  HttpTransport({http.Client? innerClient, Duration? timeout})
      : _client = innerClient ?? http.Client(),
        _ownsClient = innerClient == null,
        _timeout = timeout;

  final http.Client _client;
  final bool _ownsClient;
  final Duration? _timeout;

  /// The deadline in force, or `null` when requests may run as long as they need.
  Duration? get timeout => _timeout;

  @override
  Future<TransportResponse> post(
    Uri url,
    String body,
    Map<String, String> headers,
  ) async {
    final Future<http.Response> pending = _client
        .post(url, headers: headers, body: body)
        // A connection-level failure (DNS, TLS, refused) arrives as a ClientException.
        // Turning it into a VedAstroException here means callers never have to know
        // which HTTP library is underneath.
        .onError<http.ClientException>(
          (failure, _) => throw VedAstroException(
            'vedastro: request to $url failed (${failure.message})',
            failure,
          ),
        );

    // Only arm a deadline when the caller asked for one. Read into a local first:
    // field promotion needs Dart 3.2, and this package supports 3.0.
    final deadline = _timeout;
    final http.Response response = deadline == null
        ? await pending
        : await pending.timeout(
            deadline,
            onTimeout: () => throw VedAstroException(
              'vedastro: request to $url exceeded the '
              '${deadline.inMilliseconds} ms timeout',
            ),
          );

    return TransportResponse(
      response.statusCode,
      response.bodyBytes,
      (response.headers['content-type'] ?? '').toLowerCase(),
    );
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
