import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// The smallest useful program: one client, one moment, one calculation.
///
///     dart run example/quick_start.dart
Future<void> main() async {
  final client = demoClient();
  final birth = demoBirth();

  demoHeading('Position of the Sun');
  final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
  demoField('Sign', Response.string(sun, 'Name'));
  demoField('Degrees in sign',
      Response.string(sun, ['DegreesIn', 'DegreeMinuteSecond']));

  demoHeading('Ascendant');
  final ascendant =
      await client.calculate().houseSignName(HouseName.house1, birth);
  demoField('Rising sign', ascendant);

  client.close();
}
