import 'dart:developer' as dev;

class AppLogger {
  const AppLogger._();

  static void info(String message, [Object? data]) {
    dev.log(message, name: 'MyWay', error: data);
  }

  static void warn(String message, [Object? data]) {
    dev.log('[WARN] $message', name: 'MyWay', error: data);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    dev.log('[ERROR] $message', name: 'MyWay', error: error, stackTrace: stackTrace);
  }
}
