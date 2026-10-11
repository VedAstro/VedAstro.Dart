/// Base class for every failure this package raises.
///
/// The message never contains an API key: the client redacts it before a failure
/// is built, so a logged exception cannot leak a paid key.
class VedAstroException implements Exception {
  VedAstroException(this.message, [this.cause]);

  /// What went wrong, in a form safe to log.
  final String message;

  /// The underlying error, when there was one (a socket failure, a parse error).
  final Object? cause;

  @override
  String toString() {
    final base = 'VedAstroException: $message';
    return cause == null ? base : '$base (cause: $cause)';
  }
}
