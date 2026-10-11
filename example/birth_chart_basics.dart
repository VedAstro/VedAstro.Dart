import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Reads a full birth chart: every planet's sign, degree and constellation, plus the
/// house cusps.
///
///     dart run example/birth_chart_basics.dart
Future<void> main() async {
  final client = demoClient();
  final birth = demoBirth();
  final pace = demoShouldPace(client);

  demoHeading('Planets');
  for (final planet in [
    PlanetName.sun,
    PlanetName.moon,
    PlanetName.mars,
    PlanetName.mercury,
    PlanetName.jupiter,
    PlanetName.venus,
    PlanetName.saturn,
  ]) {
    final result = await client.calculate().planetRasiD1Sign(planet, birth);
    demoField(
      planet.wireName,
      '${Response.string(result, 'Name')} '
      '${Response.string(result, ['DegreesIn', 'DegreeMinuteSecond'])}',
    );
    await demoPace(enabled: pace);
  }

  demoHeading('House signs');
  for (final house in [
    HouseName.house1,
    HouseName.house4,
    HouseName.house7,
    HouseName.house10
  ]) {
    final sign = await client.calculate().houseSignName(house, birth);
    demoField(house.wireName, sign);
    await demoPace(enabled: pace);
  }

  demoHeading('Constellations');
  for (final planet in [PlanetName.sun, PlanetName.moon]) {
    final star = await client.calculate().planetConstellation(planet, birth);
    demoField(planet.wireName, star);
    await demoPace(enabled: pace);
  }

  client.close();
}
