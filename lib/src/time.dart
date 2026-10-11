import 'geo_location.dart';

/// A moment in time at a place - the input every chart calculator needs.
///
/// The API has its own string format, and getting it wrong is the most common
/// source of confusing results, so this class validates eagerly and offers
/// constructors for the usual ways you already have a time:
/// [Time.of] for the API's own format, [Time.fromDateTime] for a `DateTime`, and
/// [Time.now] for the present moment.
class Time {
  /// Wraps a value that has already been validated.
  const Time._(this.stdTime, this.location);

  /// Parses the API's format: `HH:mm dd/MM/yyyy +HH:mm`, with the UTC offset.
  ///
  /// The day comes before the month, as VedAstro reads it: `25/10/1992` is
  /// 25 October 1992.
  ///
  /// Throws an [ArgumentError] when the text is not in that format or the date does
  /// not exist, rather than sending something the API would reject.
  factory Time.of(String stdTime, GeoLocation location) {
    final match = _wireFormat.firstMatch(stdTime.trim());
    if (match == null) {
      throw ArgumentError.value(
        stdTime,
        'stdTime',
        'must look like "14:30 25/10/1992 +05:30" (HH:mm dd/MM/yyyy +HH:mm)',
      );
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final month = int.parse(match.group(4)!);
    final year = int.parse(match.group(5)!);

    if (hour > 23 || minute > 59) {
      throw ArgumentError.value(
          stdTime, 'stdTime', 'has an hour or minute out of range');
    }
    // Reject 31/02 and friends here, where the error is obvious.
    final probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      throw ArgumentError.value(
          stdTime, 'stdTime', 'is not a real calendar date');
    }

    return Time._(stdTime.trim(), location);
  }

  /// Builds a time from its parts, so you never have to format a string yourself.
  ///
  /// [offset] is the UTC offset in hours, e.g. `5.5` for India (`+05:30`).
  factory Time.ofFields({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    required GeoLocation location,
    double offset = 0,
  }) {
    final probe = DateTime.utc(year, month, day);
    if (probe.year != year || probe.month != month || probe.day != day) {
      throw ArgumentError('$year-$month-$day is not a real calendar date');
    }
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be between 0 and 23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be between 0 and 59');
    }
    if (offset < -12 || offset > 14) {
      throw ArgumentError.value(
          offset, 'offset', 'must be between -12 and 14 hours');
    }

    final sign = offset < 0 ? '-' : '+';
    final absolute = offset.abs();
    final offsetHours = absolute.floor();
    // 5.5 -> 30 minutes. Rounded so floating point noise cannot produce :29.
    final offsetMinutes = ((absolute - offsetHours) * 60).round();

    final text = '${_pad(hour)}:${_pad(minute)} '
        '${_pad(day)}/${_pad(month)}/$year '
        '$sign${_pad(offsetHours)}:${_pad(offsetMinutes)}';

    return Time._(text, location);
  }

  /// Builds a time from a [DateTime].
  ///
  /// A local [DateTime] is already wall-clock time in its own zone, so it is used as
  /// given. A UTC one is shifted into [utcOffset] first. When [utcOffset] is omitted,
  /// the [DateTime]'s own offset is used - which is what you want when it came from
  /// `DateTime.parse` on an offset-bearing string.
  factory Time.fromDateTime(
    DateTime dateTime,
    GeoLocation location, {
    double? utcOffset,
  }) {
    utcOffset ??= dateTime.isUtc ? 0 : dateTime.timeZoneOffset.inMinutes / 60;
    final offset = utcOffset;

    // A UTC instant has to be moved into the target zone to read its wall time.
    final wall = dateTime.isUtc && offset != 0
        ? dateTime.add(Duration(minutes: (offset * 60).round()))
        : dateTime;

    return Time.ofFields(
      year: wall.year,
      month: wall.month,
      day: wall.day,
      hour: wall.hour,
      minute: wall.minute,
      location: location,
      offset: offset,
    );
  }

  /// The current moment at [location].
  ///
  /// The device's own UTC offset is used unless [utcOffset] is given, which is
  /// usually what you want for "now where I am".
  factory Time.now(GeoLocation location, {double? utcOffset}) =>
      Time.fromDateTime(DateTime.now(), location, utcOffset: utcOffset);

  /// The wire format: `HH:mm dd/MM/yyyy +HH:mm`.
  static final RegExp _wireFormat = RegExp(
    r'^(\d{2}):(\d{2}) (\d{2})/(\d{2})/(\d{4}) ([+-]\d{2}:\d{2})$',
  );

  /// The time in the API's own format, e.g. `14:30 25/10/1992 +05:30`.
  final String stdTime;

  /// Where the chart is cast.
  final GeoLocation location;

  /// The API's wire shape: `{"StdTime": ..., "Location": {...}}`.
  Map<String, Object?> toJson() => {
        'StdTime': stdTime,
        'Location': location.toJson(),
      };

  @override
  String toString() => stdTime;

  @override
  bool operator ==(Object other) =>
      other is Time && other.stdTime == stdTime && other.location == location;

  @override
  int get hashCode => Object.hash(stdTime, location);

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
