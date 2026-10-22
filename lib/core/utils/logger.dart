import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class AppLogger {
  static void log(String message, {LogLevel level = LogLevel.info, dynamic error, StackTrace? stackTrace}) {
    if (kReleaseMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.name.toUpperCase();

    final fullMessage = '[$timestamp] [$prefix] $message';

    if (error != null) {
      debugPrint('$fullMessage | Error: $error');
      if (stackTrace != null) debugPrint(stackTrace.toString());
    } else {
      debugPrint(fullMessage);
    }
  }

  static void debug(String message) => log(message, level: LogLevel.debug);
  static void info(String message) => log(message, level: LogLevel.info);
  static void warning(String message) => log(message, level: LogLevel.warning);
  static void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);
}
