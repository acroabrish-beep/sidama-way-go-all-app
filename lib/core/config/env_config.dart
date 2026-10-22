import 'package:flutter/foundation.dart';

class EnvConfig {
  /// Check if production mode
  static const bool isProduction = kReleaseMode;

  /// AI is configured on the backend only; the client never holds an AI key.
  static void verifyConfig() {
    if (kDebugMode) {
      debugPrint('AI is configured server-side (no client AI key is used).');
    }
  }
}
