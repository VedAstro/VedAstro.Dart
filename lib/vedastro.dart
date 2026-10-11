/// Official Dart client for the [VedAstro](https://vedastro.org) Vedic astrology API.
///
/// A single client wraps 684 calculators, 47 ayanamsa systems and every vocabulary
/// the API accepts, with no schema duplication: the calculator surface is generated
/// from the server's own metadata.
///
/// ```dart
/// import 'package:vedastro/vedastro.dart';
///
/// final client = VedAstroClient(apiKey: 'FreeAPIUser');
///
/// final birth = Time.of(
///   '14:30 25/10/1992 +05:30',
///   GeoLocation.of('Mumbai', 72.8777, 19.0760),
/// );
///
/// final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
/// print(Response.string(sun, 'Name')); // Libra
/// ```
///
/// Designed for servers: the client is immutable after construction, holds no
/// per-request state, and applies **no request timeout** unless you ask for one.
library;

export 'src/api_exception.dart';
export 'src/client.dart';
export 'src/generated/calculators.dart';
export 'src/generated/enums.dart';
export 'src/geo_location.dart';
export 'src/http_transport.dart';
export 'src/response.dart';
export 'src/time.dart';
export 'src/transport.dart';
export 'src/vedastro_exception.dart';
