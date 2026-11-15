import 'dart:io';

import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Runs the whole stack against the real API, through the real HTTP transport.
///
/// Unlike the test suite - which uses a fake transport and needs no network - this
/// spends real API calls, so it is deliberately not part of CI.
///
///     dart run example/live_check.dart
///
/// Set `VEDASTRO_API_KEY` to use a paid key; otherwise the free tier applies and the
/// checks pace themselves.
Future<void> main() async {
  final client = demoClient(silent: false);
  final birth = demoBirth();
  final pace = demoShouldPace(client);
  final transport =
      client.timeout == null ? 'stream (no deadline)' : 'with a deadline';

  // ignore: avoid_print
  print('VedAstro Dart SDK — live check');
  // ignore: avoid_print
  print('transport: $transport\n');

  var failures = 0;

  Future<void> check(String label, Future<Object?> Function() action) async {
    try {
      final result = await action();
      // ignore: avoid_print
      print('  ✓ ${label.padRight(14)} $result');
    } catch (failure) {
      failures++;
      // ignore: avoid_print
      print('  ✗ ${label.padRight(14)} $failure');
    }
    await demoPace(enabled: pace);
  }

  await check('Sun sign', () async {
    final sun =
        await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
    return '${Response.string(sun, 'Name')} at '
        '${Response.string(sun, ['DegreesIn', 'DegreeMinuteSecond'])}';
  });

  await check('Ascendant', () async {
    final sign =
        await client.calculate().houseSignName(HouseName.house1, birth);
    return sign;
  });

  await check('Panchanga', () async {
    final tithi = await client.calculate().lunarDay(birth);
    return '${Response.string(tithi, 'Name')} (${Response.string(tithi, 'Paksha')})';
  });

  await check('Numerology', () async {
    final number = await client.calculate().birthNumber(birth);
    return 'birth number $number';
  });

  await check('Constellation', () async {
    final star =
        await client.calculate().planetConstellation(PlanetName.moon, birth);
    return star;
  });

  await check('RAG search', () async {
    final passages = await client
        .calculate()
        .searchSourceText('effects of Saturn in the 7th house');
    return '${Response.count(passages, [])} passage(s)';
  });

  client.close();

  // ignore: avoid_print
  print('');
  if (failures > 0) {
    // ignore: avoid_print
    print('$failures live check(s) failed.');
    exitCode = 1;
    return;
  }
  // ignore: avoid_print
  print('All live checks passed.');
}
