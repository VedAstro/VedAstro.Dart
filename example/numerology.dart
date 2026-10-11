import 'package:vedastro/vedastro.dart';

import 'support.dart';

/// Numerology: the numbers derived from a birth moment and a name.
///
///     dart run example/numerology.dart
Future<void> main() async {
  final client = demoClient();
  final birth = demoBirth();

  demoHeading('From the birth moment');
  demoField('Birth number', await client.calculate().birthNumber(birth));
  demoField('Destiny number', await client.calculate().destinyNumber(birth));

  demoHeading('From a name');
  final prediction =
      await client.calculate().nameNumberPrediction('Ada Lovelace');
  demoField(
      'Name number', Response.get(prediction, 'NameNumber') ?? prediction);
  demoField('Meaning', Response.string(prediction, 'Meaning'));

  client.close();
}
