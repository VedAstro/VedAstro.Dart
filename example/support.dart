import 'dart:io';

import 'package:vedastro/vedastro.dart';

/// Shared helpers for the examples in this folder.
///
/// Every example is a standalone program: `dart run example/quick_start.dart`.
/// They default to the free tier, and honour two environment variables:
///
/// - `VEDASTRO_API_KEY` — use your own key instead of the free tier.
///
/// The free tier allows five calls per minute, so the examples that make several
/// calls pace themselves with [demoPace].
const double demoFreeTierGapSeconds = 13.0;

/// Builds a client for the examples.
///
/// The banner is silenced by default: in a server it would corrupt a response body,
/// and in a demo it is noise.
VedAstroClient demoClient({bool silent = true}) {
  final client =
      VedAstroClient.fromEnvironment(Platform.environment, silent: silent);
  return client;
}

/// A birth moment to calculate with: Mumbai, 25 October 1992 at 14:30 IST.
Time demoBirth() => Time.of(
      '14:30 25/10/1992 +05:30',
      GeoLocation.of('Mumbai', 72.8777, 19.0760),
    );

/// A second birth moment, for the compatibility example.
Time demoPartner() => Time.of(
      '09:15 12/03/1995 +05:30',
      GeoLocation.of('Delhi', 77.2090, 28.6139),
    );

/// Prints a section heading so the output of a demo is easy to scan.
void demoHeading(String title) {
  // ignore: avoid_print
  print('\n── $title');
}

/// Prints a labelled line.
void demoField(String label, Object? value) {
  // ignore: avoid_print
  print('   ${label.padRight(18)} $value');
}

/// Waits out the free tier's per-minute allowance.
///
/// `usleep` rather than `sleep` is not needed in Dart, but the gap is: the limit is
/// counted per key across every process, so a tight loop fails even on one machine.
Future<void> demoPace({bool enabled = true}) async {
  if (!enabled) return;
  await Future<void>.delayed(
    Duration(milliseconds: (demoFreeTierGapSeconds * 1000).round()),
  );
}

/// Whether the examples should pace themselves, which they skip for a paid key.
bool demoShouldPace(VedAstroClient client) => !client.hasApiKey;

/// Truncates long text so a demo's output stays readable.
String demoTruncate(Object? value, [int limit = 120]) {
  final text = value?.toString() ?? '';
  return text.length <= limit ? text : '${text.substring(0, limit)}...';
}
