import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Ayanamsa is the difference between the tropical and the sidereal zodiac, and the
/// choice shifts every position by up to a degree. VedAstro supports 47 systems.
///
///     dart run example/custom_ayanamsa.dart
Future<void> main() async {
  final birth = demoBirth();
  final base = demoClient();

  demoHeading('The same moment, read four ways');
  for (final ayanamsa in [
    Ayanamsa.lahiri, // the Indian government standard
    Ayanamsa.raman,
    Ayanamsa.krishnamurti, // KP
    Ayanamsa.faganBradley, // Western sidereal
  ]) {
    // Reuse the same API key; only
    // the ayanamsa differs. The ayanamsa travels with each request, so it is safe to
    // keep several clients side by side.
    final scoped = VedAstroClient(
      apiKey: base.apiKey,
      silent: true,
      defaultAyanamsa: ayanamsa,
    );

    final sun =
        await scoped.calculate().planetRasiD1Sign(PlanetName.sun, birth);
    final ayanamsaValue = await scoped.calculate().ayanamsaDegree(birth);

    demoField(
      ayanamsa.wireName,
      '${Response.string(sun, 'Name')} '
      '${Response.string(sun, ['DegreesIn', 'DegreeMinuteSecond'])} '
      '| ayanamsa $ayanamsaValue',
    );

    scoped.close();
    // Four clients x two calls each outruns the free tier; a paid key would not need
    // this.
    await demoPace(enabled: demoShouldPace(base));
  }

  demoHeading('Which ayanamsa is in force');
  demoField('Client default', base.ayanamsa?.wireName ?? 'the API default');
  demoField('Ayanamsas available', Ayanamsa.values.length);

  base.close();
}
