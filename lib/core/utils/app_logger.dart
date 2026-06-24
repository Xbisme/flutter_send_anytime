import 'dart:developer' as developer;

/// Centralized logging. Never use `print`/`debugPrint` directly (Constitution
/// I/IV). Privacy rule: never log file contents, peer identifiers, IPs, or
/// rendezvous secrets.
abstract final class AppLogger {
  static const _name = 'SafeSend';

  /// Informational message.
  static void info(String message) =>
      developer.log(message, name: _name, level: 800);

  /// Warning message.
  static void warning(String message) =>
      developer.log(message, name: _name, level: 900);

  /// Error message with optional [error]/[stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      developer.log(
        message,
        name: _name,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
}
