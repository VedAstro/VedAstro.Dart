import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// The five limbs of the day, plus the inauspicious windows that depend on sunrise.
///
///     dart run example/daily_panchanga.dart
Future<void> main() async {
  final client = demoClient();
  final now = Time.now(GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390));
  final pace = demoShouldPace(client);

  demoHeading('Panchanga for ${now.stdTime}');

  final tithi = await client.calculate().lunarDay(now);
  demoField('Tithi', Response.string(tithi, 'Name'));
  demoField('Paksha', Response.string(tithi, 'Paksha'));
  demoField('Phase', Response.string(tithi, 'Phase'));
  await demoPace(enabled: pace);

  final yoga = await client.calculate().nithyaYoga(now);
  demoField('Nithya yoga', Response.string(yoga, 'Name'));
  await demoPace(enabled: pace);

  final karana = await client.calculate().karana(now);
  demoField('Karana', karana);
  await demoPace(enabled: pace);

  demoHeading('Sun and Rahu');
  demoField('Sunrise', await client.calculate().sunriseTime(now));
  await demoPace(enabled: pace);
  demoField('Sunset', await client.calculate().sunsetTime(now));
  await demoPace(enabled: pace);
  demoField('Rahu kala', await client.calculate().rahuKala(now));

  client.close();
}
