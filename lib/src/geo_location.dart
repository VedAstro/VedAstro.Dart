/// A place on Earth, as the API expects it.
///
/// The name is a label for your own reference - the API places a chart by the
/// longitude and latitude. Longitude runs east-positive, latitude north-positive.
class GeoLocation {
  /// Creates a location.
  ///
  /// Longitude and latitude are validated here, so a transposed pair fails at the
  /// call site rather than as a confusing API error.
  GeoLocation(this.name, this.longitude, this.latitude) {
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'must be between -180 and 180 degrees',
      );
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'must be between -90 and 90 degrees',
      );
    }
  }

  /// Names the place in the same call, which reads better at the call site:
  ///
  /// ```dart
  /// GeoLocation.of('Mumbai', 72.8777, 19.0760);
  /// ```
  factory GeoLocation.of(String name, double longitude, double latitude) =>
      GeoLocation(name, longitude, latitude);

  /// A label for the place, for your own reference.
  final String name;

  /// Degrees east of the prime meridian, in the range -180 to 180.
  final double longitude;

  /// Degrees north of the equator, in the range -90 to 90.
  final double latitude;

  /// The API's wire shape: `{"Name": ..., "Longitude": ..., "Latitude": ...}`.
  Map<String, Object?> toJson() => {
        'Name': name,
        'Longitude': longitude,
        'Latitude': latitude,
      };

  @override
  String toString() => '$name ($longitude, $latitude)';

  @override
  bool operator ==(Object other) =>
      other is GeoLocation &&
      other.name == name &&
      other.longitude == longitude &&
      other.latitude == latitude;

  @override
  int get hashCode => Object.hash(name, longitude, latitude);
}
