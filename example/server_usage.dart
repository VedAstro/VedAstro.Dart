import 'dart:convert';
import 'dart:io';

import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// How to use the SDK inside a long-running server.
///
/// This file is written to be **read** — the handler below is the shape you would
/// paste into a Shelf, Dart Frog or `HttpServer` app. Run it to see the same logic
/// print its answers instead of serving them:
///
///     dart run example/server_usage.dart
Future<void> main() async {
  // ONE CLIENT, CREATED ONCE -------------------------------------------------
  //
  // The client is immutable and holds no per-request state, so build it when the
  // isolate starts and share it. Building one per request would throw away the
  // connection pool and add a TLS handshake to every call.
  //
  // `silent: true` matters on a server: the start-up banner would otherwise be
  // written into a response body.
  final vedAstro = VedAstroClient.fromEnvironment(
    Platform.environment,
    silent: true,
  );

  // WHAT A HANDLER LOOKS LIKE ------------------------------------------------
  Future<(int, String)> sunSignHandler(Map<String, String> query) async {
    try {
      final birth = Time.of(
        query['when']!,
        GeoLocation.of(
          'query',
          double.parse(query['lon']!),
          double.parse(query['lat']!),
        ),
      );

      final result = await vedAstro.calculate().planetRasiD1Sign(
            PlanetName.sun,
            birth,
          );

      return (200, jsonEncode({'sign': Response.string(result, 'Name')}));
    } on ArgumentError catch (failure) {
      // The caller sent something malformed. Their fault, and cheap to answer.
      return (400, jsonEncode({'error': failure.message}));
    } on ApiException catch (failure) {
      // The API answered and rejected the call. Do not retry the same request.
      stderr.writeln(failure); // the key is already redacted
      return (502, jsonEncode({'error': 'upstream rejected the request'}));
    } on VedAstroException catch (failure) {
      // The request never completed. This one is worth a bounded retry.
      stderr.writeln(failure);
      return (503, jsonEncode({'error': 'upstream unavailable'}));
    }
  }

  // The rest of this file just drives that handler so the output is visible.
  demoHeading('A well-formed request');
  final ok = await sunSignHandler({
    'when': '14:30 25/10/1992 +05:30',
    'lon': '72.8777',
    'lat': '19.0760',
  });
  demoField('status', ok.$1);
  demoField('body', ok.$2);

  demoHeading('A malformed request');
  final bad = await sunSignHandler({
    'when': '25/10/1992 14:30', // the wrong date order
    'lon': '72.8777',
    'lat': '19.0760',
  });
  demoField('status', bad.$1);
  demoField('body', demoTruncate(bad.$2, 90));

  // NOTES WORTH KEEPING ------------------------------------------------------
  //
  // - NO REQUEST TIMEOUT is applied by default, on purpose. A calculation can take
  //   minutes, and a fixed deadline would only ever truncate a valid answer. Set
  //   `timeout: const Duration(seconds: 30)` only when your own request budget
  //   demands one.
  //
  // - CACHE BY CHART INPUT. The same birth details recur constantly, and a cache hit
  //   costs no API calls at all. A `Map` keyed by the wire time string is enough to
  //   start; move it to Redis when you run more than one isolate.
  //
  // - THE FREE TIER IS 5 CALLS PER MINUTE, counted per key across every process. Pace
  //   centrally rather than per isolate, or two workers will throttle each other.
  //
  // - RETRY ONLY VedAstroException, and only a bounded number of times with backoff.
  //   An ApiException means the API actively rejected the call.
  //
  // - CALL close() ON SHUTDOWN so the HTTP client's connections are released.
  //
  // - THROW AWAY NOTHING. The SDK never retries and never throttles, so your queue,
  //   your framework and your observability see exactly what the API did.

  demoHeading('Shutting down');
  vedAstro.close();
  // ignore: avoid_print
  print('   client closed');
}
