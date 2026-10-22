import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void init() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError(details.exception, details.stack, fatal: true);
    };

    // Replace Red Screen with user-friendly UI
    ErrorWidget.builder = errorWidgetBuilder;

    // Capture platform-agnostic errors (async, etc.)
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError(error, stack, fatal: true);
      return true;
    };
  }

  static void _logError(dynamic error, StackTrace? stack, {bool fatal = false}) {
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    } else {
      debugPrint('--- ERROR CAPTURED ---');
      debugPrint(error.toString());
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static void recordNonFatalError(dynamic error, StackTrace? stack) {
    _logError(error, stack, fatal: false);
  }

  static Widget errorWidgetBuilder(FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.red[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              kReleaseMode
                ? 'We have been notified and are fixing it. Please restart the app.'
                : details.exception.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
