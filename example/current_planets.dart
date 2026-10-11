import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Every planet's sign right now, from one call.
///
///     dart run example/current_planets.dart
Future<void> main() async {
  final client = demoClient();

  // "Now" at the place you care about. The API needs a location, not just a time.
  final now = Time.now(GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390));
  demoHeading('Now: ${now.stdTime}');

  final signs = await client.calculate().allPlanetRasiSigns(now);
  for (final entry in Response.list(signs, [])) {
    demoField(
      Response.string(entry, 'Planet'),
      Response.string(entry, 'Sign'),
    );
  }

  demoHeading('Full data for the Moon');
  final moon = await client.calculate().allPlanetData(PlanetName.moon, now);
  demoField('Sign', Response.string(moon, 'Sign'));
  demoField('Constellation', Response.string(moon, 'Constellation'));
  demoField(
      'Degrees', Response.string(moon, ['DegreesIn', 'DegreeMinuteSecond']));

  client.close();
}
