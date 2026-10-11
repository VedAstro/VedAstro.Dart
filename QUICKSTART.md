# VedAstro Dart SDK — Quick Start

From nothing to your first chart in about two minutes.

---

## 1. Add the package

```bash
dart pub add vedastro
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  vedastro: ^1.0.0
```

Requires Dart 3.0 or newer.

---

## 2. Your first calculation

```dart
import 'package:vedastro/vedastro.dart';

Future<void> main() async {
  final client = VedAstroClient(apiKey: 'FreeAPIUser');

  final birth = Time.of(
    '14:30 25/10/1992 +05:30',            // HH:mm dd/MM/yyyy +HH:mm
    GeoLocation.of('Mumbai', 72.8777, 19.0760), // name, longitude, latitude
  );

  final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
  print(Response.string(sun, 'Name'));                        // Libra
  print(Response.string(sun, ['DegreesIn', 'DegreeMinuteSecond']));

  client.close();
}
```

Run it:

```bash
dart run your_file.dart
```

`FreeAPIUser` is the free tier: **5 calls per minute**, plenty for development. For production, get a
key from [vedastro.org/API.html](https://vedastro.org/API.html) and read it from the environment
rather than hard-coding it.

---

## 3. The four ideas you need

Everything else in this SDK is a variation on these.

**The client** holds your key and settings, is immutable, and is safe to share:

```dart
final client = VedAstroClient(
  apiKey: key,
  defaultAyanamsa: Ayanamsa.lahiri,  // optional
  silent: true,                      // suppress the start-up banner
);
```

**A moment** is a time plus a place. The whole chart depends on both:

```dart
Time.of('14:30 25/10/1992 +05:30', GeoLocation.of('Mumbai', 72.8777, 19.0760));
```

**A calculator** is an `async` method. Required arguments are positional; optional ones are named:

```dart
await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);        // 2 required
await client.calculate().searchSourceText('saturn in 7th', topK: 3);     // 1 required, named optional
```

**A result** is read with `Response`, which never throws on an unexpected shape:

```dart
Response.string(result, 'Name');
Response.doubleValue(result, ['DegreesIn', 'TotalDegrees']);
Response.list(result, 'PredictionList');
```

---

## 4. Ten more lines, five more answers

```dart
// Every planet's sign, in one call.
final signs = await client.calculate().allPlanetRasiSigns(birth);
for (final entry in Response.list(signs, [])) {
  print('${Response.string(entry, 'Planet')}: ${Response.string(entry, 'Sign')}');
}

// The ascendant.
print(await client.calculate().houseSignName(HouseName.house1, birth));

// Today's tithi.
final now = Time.now(GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390));
final tithi = await client.calculate().lunarDay(now);
print('${Response.string(tithi, 'Name')} (${Response.string(tithi, 'Paksha')})');

// Numerology.
print(await client.calculate().birthNumber(birth));

// A chart as SVG, ready to write to a file.
final svg = await client.calculate().southIndianChart(birth);
```

---

## 5. Where to go next

- **[README.md](README.md)** — the full guide: every area of the API, servers, response handling,
  errors, and the timeout rule.
- **[example/](example/)** — twelve runnable programs, one per idea. Start with
  `example/quick_start.dart`, then `example/server_usage.dart` if you are building a service.
- **[FAQ.md](FAQ.md)** — ayanamsa choice, rate limits, result shapes, retries.

Common commands:

```bash
dart run example/quick_start.dart     # one calculation, end to end
dart run example/live_check.dart      # verify against the real API
dart test                             # run the suite (no network needed)
dart analyze                          # static analysis
```

---

## Troubleshooting in 30 seconds

| Symptom | Cause |
|---------|-------|
| `ArgumentError: ... must look like "14:30 25/10/1992 +05:30"` | Wrong time format, or the date is not real |
| `ApiException: ... rate limit ...` | Free tier allows 5 calls/minute — pace your calls |
| `ApiException: ... missing its Payload` | The service is unhealthy; check the endpoint name |
| `VedAstroException: ... failed` | The request never completed — DNS, TLS, or no network |
| A result is a bare `String` instead of an object | Correct: a single-property payload is unwrapped |

> **Remember: the day comes before the month.** `25/10/1992` is 25 October 1992.
