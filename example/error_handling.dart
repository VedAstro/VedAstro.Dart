import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Every way a call can fail, and what each one tells you.
///
///     dart run example/error_handling.dart
Future<void> main() async {
  final client = demoClient();
  final birth = demoBirth();

  // 1. Client-side validation fails before any network call, which is the cheapest
  //    possible failure: no request, no rate-limit cost, a message naming the field.
  demoHeading('1. Validation, before the network');
  for (final attempt in <void Function()>[
    () =>
        Time.of('25/10/1992 14:30', GeoLocation.of('Mumbai', 72.8777, 19.0760)),
    () => Time.of(
        '10:00 31/02/2020 +00:00', GeoLocation.of('Mumbai', 72.8777, 19.0760)),
    () => GeoLocation.of('Swapped', 19.0760, 72.8777),
  ]) {
    try {
      attempt();
      // ignore: avoid_print
      print('   ✗ accepted something it should have rejected');
    } on ArgumentError catch (failure) {
      // ignore: avoid_print
      print('   ✓ rejected: ${failure.message}');
    }
  }

  // 2. An ApiException means the API answered and rejected the call. Retrying the
  //    identical request will not help.
  demoHeading('2. The API rejected the call');
  try {
    // An intentionally unknown endpoint.
    await client.call('NoSuchCalculatorExists', parameters: {'time': birth});
  } on ApiException catch (failure) {
    demoField('Type', 'ApiException');
    demoField('Endpoint', failure.endpoint);
    demoField('HTTP status', failure.statusCode);
    demoField('Message', demoTruncate(failure.message, 100));
  }

  // 3. A VedAstroException means the request never completed - DNS, TLS, a reset
  //    connection. This is the one worth retrying.
  demoHeading('3. The request never completed');
  final unreachable = VedAstroClient(
    apiKey: client.apiKey,
    buildTransport: (_) => _UnavailableTransport(),
    silent: true,
    timeout: const Duration(seconds: 5),
  );
  try {
    await unreachable.calculate().planetRasiD1Sign(PlanetName.sun, birth);
  } on VedAstroException catch (failure) {
    demoField('Type', failure.runtimeType.toString());
    demoField('Message', demoTruncate(failure.message, 100));
  } finally {
    unreachable.close();
  }

  // 4. The API key never appears in a message, so an exception is safe to log.
  demoHeading('4. The key is redacted');
  // ignore: avoid_print
  print('   configured key: ${client.apiKey.isEmpty ? "(none)" : "[present]"}');
  try {
    await client.call('NoSuchCalculatorExists', parameters: {'time': birth});
  } on ApiException catch (failure) {
    final leaks =
        client.apiKey.isNotEmpty && failure.toString().contains(client.apiKey);
    // ignore: avoid_print
    print('   ${leaks ? "✗ LEAKED" : "✓ not present in the message"}');
  }

  client.close();
}

// Demonstrate a connection failure without depending on a particular DNS service.
class _UnavailableTransport implements Transport {
  @override
  Future<TransportResponse> post(
      Uri url, String body, Map<String, String> headers) async {
    throw VedAstroException('Simulated connection failure');
  }

  @override
  void close() {}
}
