import 'package:flutter/foundation.dart';

enum GzLogLevel { debug, info, warning, error }

typedef GzLogSink = void Function(GzLogLevel level, String tag, String message, Object? error, StackTrace? stack);

/// Minimal logger. Never log a name, phone, email, Civil ID, IBAN, card data, chat or review text (ADR 0019 item 11):
/// pass identifiers and codes only. Debug output goes to `debugPrint` outside release builds; [sink] is the hook for a
/// crash reporter (set it once at bootstrap).
class GzLogger {
  const GzLogger(this.tag);

  final String tag;

  /// Replaceable output (tests capture; bootstrap may forward errors to a crash reporter).
  static GzLogSink sink = _defaultSink;

  /// Minimum level that is emitted.
  static GzLogLevel minLevel = kReleaseMode ? GzLogLevel.warning : GzLogLevel.debug;

  void debug(String message) => _emit(GzLogLevel.debug, message);
  void info(String message) => _emit(GzLogLevel.info, message);
  void warning(String message, [Object? error]) => _emit(GzLogLevel.warning, message, error);
  void error(String message, [Object? error, StackTrace? stack]) => _emit(GzLogLevel.error, message, error, stack);

  void _emit(GzLogLevel level, String message, [Object? error, StackTrace? stack]) {
    if (level.index < minLevel.index) return;
    sink(level, tag, message, error, stack);
  }

  static void _defaultSink(GzLogLevel level, String tag, String message, Object? error, StackTrace? stack) {
    final suffix = error == null ? '' : ' | $error';
    debugPrint('[${level.name}] $tag: $message$suffix');
    if (stack != null && level == GzLogLevel.error) debugPrint('$stack');
  }
}
