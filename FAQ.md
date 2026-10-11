# VedAstro Dart SDK — FAQ

The questions that come up most, answered with runnable snippets.

---

## Getting started

**What do I need?** Dart 3.0 or newer, and the package:

```yaml
dependencies:
  vedastro: ^1.0.0
```

**Do I need an API key to try it?** No. An empty key uses the free tier:

```dart
final client = VedAstroClient(apiKey: 'FreeAPIUser');
```

**Which Dart versions are covered?** 3.0 and newer. CI runs the suite on 3.0, 3.3 and the current
stable, on Linux, Windows and macOS.

**Does it work in Flutter?** Yes — nothing here is server-only. The package does no `dart:io`
imports itself, so it compiles for the web too, where `package:http` uses the browser's fetch. Only
the example scripts read `Platform.environment`.

---

## Time and location

**What is the time format?** `HH:mm dd/MM/yyyy +HH:mm` — the **day comes before the month**:

```dart
Time.of('14:30 25/10/1992 +05:30', GeoLocation.of('Mumbai', 72.8777, 19.0760));
```

`25/10/1992` is 25 October 1992. Reading it as a US date is the single most common way to get a
plausible but wrong chart, so `Time.of` validates the format and the date and throws at the call
site rather than letting the API quietly calculate something else.

**Can I avoid the string entirely?** Yes:

```dart
Time.ofFields(
  year: 1992, month: 10, day: 25, hour: 14, minute: 30,
  location: GeoLocation.of('Mumbai', 72.8777, 19.0760),
  offset: 5.5, // +05:30
);

Time.fromDateTime(DateTime.parse('1992-10-25T09:00:00Z'), location, utcOffset: 5.5);

Time.now(GeoLocation.of('Kuala Lumpur', 101.6869, 3.1390));
```

**Why does `Time` need a location?** A chart is cast for a place: the ascendant and all twelve house
cusps depend on latitude and longitude. The API requires them, so the type does too.

**Which way round are longitude and latitude?** Longitude first, and east/north are positive:

```dart
GeoLocation.of('Mumbai', 72.8777, 19.0760); // lon, lat
```

Both are range-checked, so a transposed pair fails immediately instead of producing a chart for a
point in the ocean.

---

## Ayanamsa

**Which ayanamsa should I use?**

- 🇮🇳 **In India** → `Ayanamsa.lahiri` (the government standard)
- 🌐 **Unsure** → `Ayanamsa.lahiri` (also the API default)
- 📐 **KP** → `Ayanamsa.krishnamurti`
- 🌍 **Western sidereal** → `Ayanamsa.faganBradley`

```dart
final client = VedAstroClient(apiKey: key, defaultAyanamsa: Ayanamsa.lahiri);
```

All 47 systems are in the `Ayanamsa` enum, and `ayanamsa.wireName` gives the string the API expects.

**Can two calls use different ayanamsas at once?** Yes — build two clients, or pass `ayanamsa:` to
`client.call(...)`. Both are safe to use concurrently, unlike a global setting, which is why this SDK
has none.

---

## Timeouts and long calls

**Is there a request timeout?** No, deliberately. A calculation can take milliseconds or minutes
depending on the endpoint and the load on the service, and this library cannot know what is
acceptable for your workload. A built-in deadline would only ever truncate a valid answer.

**How do I stop a call that runs too long?** Set one yourself, because your own budget says so:

```dart
final client = VedAstroClient(apiKey: key, timeout: const Duration(seconds: 30));
```

**My call takes a long time — is that normal?** Some calculators are heavy (`astrocartography`
returns hundreds of kilobytes; `horoscopePredictions` runs a model). Let them finish, or move the
work behind a queue so a page request is not waiting on it.

---

## Results

**Why does a calculator return `Object?` and not a typed class?** Because the API's result shapes
vary widely — a string here, a number there, a deeply nested object elsewhere — and 685 hand-written
result classes would be a maintenance burden that drifts from the server. `Response` gives you safe,
typed access instead:

```dart
Response.string(result, 'Name');                            // '' when absent
Response.doubleValue(result, ['DegreesIn', 'TotalDegrees']); // null when absent
Response.intValue(result, 'Count');
Response.boolValue(result, 'IsRetrograde');
Response.list(result, 'PredictionList');                     // [] when absent
Response.map(result, 'Summary');                             // {} when absent
Response.get(result, ['Summary', 'ScoreSummary']);
```

**Why is my result sometimes a bare `String`?** The API nests each result under the method name, and
a single-property payload is unwrapped — the same rule the Python, Node.js, Go, Java and PHP SDKs
use. So `houseSignName` returns `"Aquarius"`, while `lunarDay` returns an object.

**Is a number an `int` or a `double`?** Whatever arrived: `7` is an `int`, `7.0` is a `double`. The
API also sends some numbers as strings, so `Response.doubleValue` and `Response.intValue` accept both
— use them rather than casting.

**A chart endpoint returned SVG text.** Correct, and intentional. `southIndianChart` and friends
answer with markup rather than an envelope, so you get a `String` starting with `<svg`:

```dart
final svg = await client.calculate().southIndianChart(birth);
File('chart.svg').writeAsStringSync(svg! as String);
```

---

## Errors

**What does `Status: Fail` mean?** The API received the request and rejected it. The SDK raises an
`ApiException` whose `message` is the API's own explanation, and whose `statusCode` is `0` because
HTTP itself succeeded.

**What is the difference between the two exceptions?**

| Type | Meaning | Retry? |
|------|---------|--------|
| `VedAstroException` | The request never completed (DNS, TLS, reset, timeout) | Sometimes |
| `ApiException` | The API answered and rejected the call, or the body was unreadable | No |

**Is it safe to log an exception?** Yes. The SDK redacts the API key from every message it raises.

**Do errors retry automatically?** No. The SDK never retries and never throttles, so your own
retry policy and observability see exactly what the API did.

---

## Rate limits and keys

**What are the limits?** The free tier allows **5 calls per minute**, counted per key across every
process you run. A paid key (from [vedastro.org/API.html](https://vedastro.org/API.html)) raises this
to 200 calls per minute.

**How should I pace calls?** Centrally, not per isolate — two workers pacing independently will still
exceed the limit together. A token bucket in Redis is the usual answer.

**How do I keep my key out of the source?** Read it from the environment:

```dart
final client = VedAstroClient.fromEnvironment(Platform.environment);
```

**Can I point at a different server?** Yes, `baseUrl` (or `VEDASTRO_BASE_URL`). Useful for a proxy or
a staging deployment.

---

## Servers

**Should I create a client per request?** No. Create one per isolate and share it; the client holds
no per-request state. Building one per request loses the connection pool and adds a TLS handshake to
every call.

**Do I need to close it?** Only at shutdown, to release the HTTP client:

```dart
vedAstro.close();
```

**The banner is polluting my response.** Pass `silent: true`.

**How do I test my own code that uses this?** Inject a transport — that is what the SDK's own suite
does. Implement `Transport`, or pass a `MockClient` to `HttpTransport`:

```dart
final client = VedAstroClient(
  silent: true,
  buildTransport: (_) => HttpTransport(innerClient: MockClient((request) async {
    return http.Response('{"Status":"Pass","Payload":{"HouseSignName":"Aquarius"}}', 200);
  })),
);
```

---

## Still stuck?

Open an issue at [github.com/VedAstro/VedAstro.Dart/issues](https://github.com/VedAstro/VedAstro.Dart/issues).
Including the endpoint, the arguments and the full exception message makes it much faster to help.
