# VedAstro Dart SDK

**The official Dart client for the VedAstro Vedic astrology API.** Calculate birth charts, planetary
positions, dashas, panchanga, compatibility and more — **685 calculations** from one dependency-light
package.

[![CI](https://github.com/VedAstro/VedAstro.Dart/actions/workflows/ci.yml/badge.svg)](https://github.com/VedAstro/VedAstro.Dart/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/vedastro.svg)](https://pub.dev/packages/vedastro)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## ⚡ 30-Second Quick Start

```bash
dart pub add vedastro
```

```dart
import 'package:vedastro/vedastro.dart';

Future<void> main() async {
  final client = VedAstroClient(apiKey: 'FreeAPIUser');

  final birth = Time.of(
    '14:30 25/10/1992 +05:30',
    GeoLocation.of('Mumbai', 72.8777, 19.0760),
  );

  final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
  print(Response.string(sun, 'Name')); // Libra

  client.close();
}
```

That is the whole API: build a client, describe a moment, call a calculator, read the result.

---

## 🎯 Why VedAstro?

- **685 calculations** — birth charts, divisional charts, dashas, panchanga, shadbala, ashtakavarga,
  yogas, transits, prashna, numerology, compatibility and astrology-grounded semantic search.
- **One dependency.** `package:http`, the Dart team's own client. No FFI, no native bindings, no
  ephemeric data files to ship.
- **Compile-time safety.** 19 enums mean a typo like `PlanetName.sunn` is a build error, not a 3 a.m.
  API failure. Dart's null safety does the rest.
- **Server-first.** Immutable client, no per-request state, **no request timeout** unless you ask for
  one, and a transport you can swap for a proxy or a test double.
- **Reads like Dart.** Positional required arguments, named optional ones, `Future`-based, and
  documented at every method so your editor's tooltip is the manual.
- **Never silently wrong.** A bad date, a transposed latitude or a mis-typed enum fails at the call
  site, where the fix is obvious.

---

## 📦 Installation

```yaml
# pubspec.yaml
dependencies:
  vedastro: ^1.0.0
```

```bash
dart pub get
```

**Requirements:** Dart 3.0 or newer. The package runs anywhere Dart runs on a server — a plain VM, a
Shelf or Dart Frog app, Cloud Run, a Docker container, or a worker behind your own queue.

---

## 🔑 Getting an API Key

```dart
// The free tier: 5 calls per minute, fine for development.
final client = VedAstroClient(apiKey: 'FreeAPIUser');

// A paid key, read from the environment rather than committed.
final client = VedAstroClient.fromEnvironment(Platform.environment);
```

`VedAstroClient.fromEnvironment` reads `VEDASTRO_API_KEY`. An **empty key**
uses the service's free tier.

> **Never commit a paid key.** Read it from the environment or your platform's secret store. The SDK
> redacts the key from every message it raises, so a logged exception cannot leak it.

---

## 📖 What Can You Calculate? (685 Methods)

| Area | Methods | Examples |
|------|---------|----------|
| 🪐 **Core chart** | 225 | `planetRasiD1Sign`, `houseSignName`, `allPlanetData`, `planetConstellation` |
| 🔢 **Divisional / varga** | 102 | `allPlanetNavamshaSign`, `allPlanetDashamamshaSign`, `allHouseDwadashamshaSign` |
| ⏰ **Panchanga & time** | 65 | `lunarDay`, `nithyaYoga`, `karana`, `sunriseTime`, `sunsetTime`, `rahuKala` |
| 💪 **Strength & shadbala** | 62 | `allPlanetStrength`, `allPlanetOrderedByStrength`, `beneficPlanetListByShadbala` |
| 📊 **Charts, aspects & events** | 55 | `southIndianChart` (SVG), `northIndianChart`, `kalaSarpaYoga` |
| ❓ **Prashna (horary)** | 28 | `chapter10PrashnaMargaPredictions`, `chapter15PrashnaMargaPredictions` |
| 🎯 **Ashtakavarga** | 20 | `bhinnashtakavargaChart`, `ashtakavargaTransitPrediction` |
| ⏳ **Dasa systems** | 20 | `dasaForLife`, `dasaAtTime`, `calculateShoolaDasa` |
| 🌍 **Earthquake** | 20 | `calculateEarthquakeRiskScore`, `isEarthquakeJupiterSaturnConjunction` |
| 🧬 **Longevity** | 18 | `ashtakavargaLongevity`, `detailedAshtakavargaLongevity` |
| 🌑 **Upagraha** | 15 | `gulikaLongitude`, `dhumaLongitude`, `upagrahaLongitude` |
| 🔄 **Transit** | 13 | `angaGrahaTransit`, `planetSignTransit`, `transitHouseFromLagna` |
| 🧘 **Yogas** | 12 | `kalaSarpaYoga`, `jHoraYogaList`, `kujaDosaScore` |
| 🕉️ **Jaimini** | 8 | `jaiminiRasiDrishti`, `jaiminiGrahaStrength` |
| 🤖 **AI & ML** | 7 | `horoscopePredictions`, `matchReport` |
| 🔢 **Numerology** | 6 | `birthNumber`, `destinyNumber`, `nameNumberPrediction` |
| 💑 **Matching** | 4 | `matchReport`, `yoniKutaAnimal` |
| 🏥 **Health** | 4 | `predictMedicalHealthConditions` |
| 🗺️ **Astrocartography** | 1 | `astrocartography` — planetary lines across the globe |

Plus **47 ayanamsa systems** via the `Ayanamsa` enum, and astrology-grounded RAG search over classical
texts with `searchSourceText` and `getAvailableSourceTexts`.

---

## 🚀 Common Tasks

### Birth chart basics

```dart
final sun = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
print('Sun: ${Response.string(sun, 'Name')} '
      '${Response.string(sun, ['DegreesIn', 'DegreeMinuteSecond'])}');

final ascendant = await client.calculate().houseSignName(HouseName.house1, birth);
print('Ascendant: $ascendant');
```

### Today's panchanga

```dart
final now = Time.now(GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390));
final tithi = await client.calculate().lunarDay(now);
print('${Response.string(tithi, 'Name')} (${Response.string(tithi, 'Paksha')})');
```

### A chart as SVG

Chart endpoints answer with markup rather than an object:

```dart
final svg = await client.calculate().southIndianChart(birth);
File('chart.svg').writeAsStringSync(svg! as String);
```

### Marriage compatibility

```dart
final report = await client.calculate().matchReport(
  Time.of(
    '14:30 25/10/1992 +05:30',
    GeoLocation.of('Mumbai', 72.8777, 19.0760),
  ),
  Time.of(
    '09:15 12/03/1995 +05:30',
    GeoLocation.of('Delhi', 77.2090, 28.6139),
  ),
);

print('Score: ${Response.doubleValue(report, 'KutaScore')} of 100');
print('Summary: ${Response.string(report, ['Summary', 'ScoreSummary'])}');

for (final kuta in Response.list(report, 'PredictionList')) {
  print('- ${Response.string(kuta, 'Name')}: ${Response.string(kuta, 'Nature')}');
}
```

### Choosing an ayanamsa

```dart
final client = VedAstroClient(
  apiKey: key,
  defaultAyanamsa: Ayanamsa.lahiri,   // the usual choice for Indian astrology
);
```

There are 47 systems in the `Ayanamsa` enum, from `lahiri` and `raman` to `faganBradley` and
`krishnamurti`.

### RAG search over classical texts

```dart
final passages = await client.calculate().searchSourceText(
  'effects of Saturn in the 7th house',
  topK: 3,
);

for (final passage in Response.list(passages, [])) {
  print('${Response.string(passage, 'sourceName')} '
        '(p.${Response.intValue(passage, 'pageNumber')})');
  print(Response.string(passage, 'text'));
}
```

Which texts are indexed is itself a calculator:

```dart
final sources = await client.calculate().getAvailableSourceTexts();
print(Response.count(sources, [])); // 7 classical works
```

👉 **See the runnable versions in [`example/`](example/).** Twelve programs, each one focused.

---

## ⏳ There Is No Request Timeout by Default

Deliberately. A VedAstro calculation can take milliseconds or minutes depending on the endpoint and
the load on the service, and this library has no way to know what is acceptable for your workload. A
built-in deadline would be exactly the kind of brittle logic that silently truncates a valid answer,
so **none is applied**. If a call is still running, it is still working.

When you want a deadline — because your own request or job budget demands one — set it explicitly:

```dart
final client = VedAstroClient(
  apiKey: key,
  timeout: const Duration(seconds: 30), // only because *you* decided 30s is too long
);
```

---

## 🧵 Using It in a Server

The client is immutable and holds no per-request state, so build it once and share it.

```dart
import 'dart:io';
import 'package:vedastro/vedastro.dart';

// Created once, when the isolate starts.
final vedAstro = VedAstroClient.fromEnvironment(Platform.environment, silent: true);

Future<Response> sunSign(Request request) async {
  final birth = Time.of(
    request.url.queryParameters['when']!,
    GeoLocation.of(
      'query',
      double.parse(request.url.queryParameters['lon']!),
      double.parse(request.url.queryParameters['lat']!),
    ),
  );

  try {
    final result = await vedAstro.calculate().planetRasiD1Sign(PlanetName.sun, birth);
    return Response.ok(
      jsonEncode({'sign': Response.string(result, 'Name')}),
      headers: {'content-type': 'application/json'},
    );
  } on ApiException catch (failure) {
    // The request reached the API and was rejected.
    stderr.writeln(failure); // the key is already redacted
    return Response.badRequest;
  } on VedAstroException catch (failure) {
    // The request never completed: DNS, TLS, connection reset.
    stderr.writeln(failure);
    return Response.internalServerError;
  }
}
```

Good practice on a server:

- **One client per isolate, injected.** Not one per request — you would lose connection reuse.
- **Do not set a timeout unless you mean it.** The library applies none, so a slow calculation
  completes. A fixed deadline only ever truncates a valid answer.
- **Silence the banner** (`silent: true`) in anything that writes a response body.
- **Cache by chart input.** The same birth details recur, and a cache hit costs nothing.
- **Do not retry blindly.** Only idempotent reads are safe, and only on `VedAstroException` — an
  `ApiException` means the API actively rejected the call.
- **Never log the key.** The SDK already redacts it from every message it raises.
- **Call `close()` on shutdown** to release the HTTP client, if your server has a shutdown hook.

👉 **See the full example:** [`example/server_usage.dart`](example/server_usage.dart)

---

## 📚 Response Handling

The API nests each result under the method name. A payload object with exactly one property is
unwrapped to that property, which is why most calculators hand back the inner value directly —
sometimes a bare `String`, sometimes a `num`, sometimes a `Map`.

`Response` reads any shape without throwing, which matters in a service that must stay up:

```dart
final result = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);

Response.string(result, 'Name');                            // 'Libra'
Response.doubleValue(result, ['DegreesIn', 'TotalDegrees']); // 8.4419...
Response.intValue(result, ['DegreesIn', 'TotalDegrees']);    // 8
Response.list(result, 'SomeList');                           // [] when absent
Response.map(result, 'SomeMap');                             // {} when absent
Response.has(result, 'Name');                                // true
Response.get(result, ['DegreesIn', 'DegreeMinuteSecond']);   // "8° 26' 31"
```

Each accessor returns a null-or-default value rather than throwing, and `doubleValue` accepts the
numeric strings the API sometimes sends — exactly the case that otherwise becomes a runtime cast
error in production.

---

## 🧯 Errors

Two exception types, and the distinction tells you whether retrying can help:

| Type | Meaning | Retry? |
|------|---------|--------|
| `VedAstroException` | The request never completed (DNS, TLS, connection reset, timeout) | Sometimes |
| `ApiException` | The API answered and rejected the call, or the body could not be decoded | No |

```dart
try {
  final result = await client.calculate().planetRasiD1Sign(PlanetName.sun, birth);
} on ApiException catch (failure) {
  print('${failure.endpoint} failed: ${failure.message}');
  print('HTTP status: ${failure.statusCode}'); // 0 when the API sent Status: Fail
} on VedAstroException catch (failure) {
  print('transport problem: ${failure.message}');
}
```

`ApiException` also carries `payload` (the API's own error text) and `isHttpFailure`.

---

## 🧪 Testing

```bash
dart pub get
dart analyze
dart test
dart format --output=none --set-exit-if-changed .
```

The suite needs no network, no API key and no credentials. It drives the real client through
`MockClient` from `package:http`, so request encoding, response unwrapping, SVG handling and every
error path are exercised without a socket.

To check the live API instead (this spends free-tier calls):

```bash
dart run example/live_check.dart
```

---

## 🗺️ All 685 Methods, and 47 Ayanamsas

- **[`lib/src/generated/calculators.dart`](lib/src/generated/calculators.dart)** — every calculator,
  documented, with its required and optional arguments.
- **[`lib/src/generated/enums.dart`](lib/src/generated/enums.dart)** — 19 enums: `PlanetName`,
  `HouseName`, `ZodiacName`, `Ayanamsa`, `ChartType`, `DasaType` and the rest.
- **[`lib/src/generated/api_manifest.json`](lib/src/generated/api_manifest.json)** — the same surface
  as data, for tooling.

The generated surface is produced from the server's own metadata, so it cannot drift from the API.

---

## 🤝 Other VedAstro SDKs

Same API, same wire format, same vocabulary, in the language you already use:

- 🐍 **Python SDK**: [VedAstro.Python](https://github.com/VedAstro/VedAstro.Python)
- ⬢ **Node.js SDK**: [VedAstro.NodeJS](https://github.com/VedAstro/VedAstro.NodeJS)
- 🐹 **Go SDK**: [VedAstro.Go](https://github.com/VedAstro/VedAstro.Go)
- ☕ **Java SDK**: [VedAstro.Java](https://github.com/VedAstro/VedAstro.Java)
- 🐘 **PHP SDK**: [VedAstro.PHP](https://github.com/VedAstro/VedAstro.PHP)

---

## 🙋 FAQ

See **[FAQ.md](FAQ.md)** for the questions that come up most: ayanamsa choice, rate limits, the
free tier, `Map` versus typed results, and what to do when the API answers `Status: Fail`.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

Built with care for the Vedic astrology community. 🕉️
