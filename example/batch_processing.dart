import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// A batch of charts, paced for the free tier.
///
///     dart run example/batch_processing.dart
///
/// The point of this example is not the loop; it is what the loop does *not* do. The
/// SDK never retries and never throttles, so pacing is yours to own - and it has to
/// be central, because the per-key limit is shared across every process you run.
Future<void> main() async {
  final client = demoClient();
  final pace = demoShouldPace(client);

  // A small set of people to chart.
  final people = <String, Time>{
    'Asha': Time.of(
      '14:30 25/10/1992 +05:30',
      GeoLocation.of('Mumbai', 72.8777, 19.0760),
    ),
    'Bala': Time.of(
      '06:45 02/07/1988 +08:00',
      GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390),
    ),
    'Chen': Time.of(
      '21:10 19/12/2000 +08:00',
      GeoLocation.of('Singapore', 103.8198, 1.3521),
    ),
  };

  demoHeading('Ascendants');
  for (final entry in people.entries) {
    final sign =
        await client.calculate().houseSignName(HouseName.house1, entry.value);
    demoField(entry.key, sign);
    // The free tier allows five calls a minute; a paid key does not need this.
    await demoPace(enabled: pace);
  }

  demoHeading('Suns');
  for (final entry in people.entries) {
    final sun =
        await client.calculate().planetRasiD1Sign(PlanetName.sun, entry.value);
    demoField(entry.key, Response.string(sun, 'Name'));
    await demoPace(enabled: pace);
  }

  // WHAT A PRODUCTION BATCH WOULD ADD ---------------------------------------
  //
  // - A CONCURRENCY LIMIT. Six calls at once is fine; six hundred is not. A
  //   fixed-size pool (or a package such as `pool`) keeps the pressure bounded.
  //
  // - A RETRY ON VedAstroException ONLY. That means the request never completed, so
  //   trying again is reasonable. An ApiException means the API rejected the call -
  //   repeating it verbatim will fail the same way.
  //
  // - CACHING KEYED BY THE CHART INPUT. `birth.stdTime` plus the location is the
  //   natural key; the same person is charted many times.
  //
  // - PROGRESS AND A FAILURE LIST, so one bad date does not abandon the whole run:
  //
  //     final failures = <String, Object>{};
  //     for (final entry in people.entries) {
  //       try { ... } catch (failure) { failures[entry.key] = failure; }
  //     }

  demoHeading('Done');
  // ignore: avoid_print
  print('   charted ${people.length} people, ${people.length * 2} calls');

  client.close();
}
