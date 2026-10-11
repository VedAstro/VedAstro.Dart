import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Divisional (varga) charts: the same moment read at finer resolutions.
///
///     dart run example/divisional_charts.dart
Future<void> main() async {
  final client = demoClient();
  final birth = demoBirth();
  final pace = demoShouldPace(client);

  demoHeading('Navamsha (D9)');
  for (final planet in [PlanetName.sun, PlanetName.moon, PlanetName.jupiter]) {
    final sign = await client.calculate().planetNavamshaD9Sign(planet, birth);
    demoField(planet.wireName, Response.string(sign, 'Name'));
    await demoPace(enabled: pace);
  }

  demoHeading('Every planet, one division at a time');
  demoField(
    'Navamsha D9',
    demoTruncate(await client.calculate().allPlanetNavamshaSign(birth), 90),
  );
  await demoPace(enabled: pace);
  demoField(
    'Dashamamsha D10',
    demoTruncate(await client.calculate().allPlanetDashamamshaSign(birth), 90),
  );
  await demoPace(enabled: pace);
  demoField(
    'Dwadashamsha D12',
    demoTruncate(await client.calculate().allPlanetDwadashamshaSign(birth), 90),
  );

  client.close();
}
