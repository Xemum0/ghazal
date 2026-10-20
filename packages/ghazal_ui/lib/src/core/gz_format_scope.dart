import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;

import '../foundation.dart';

/// The formatter the core components use (`useFormat()` on the web). The app installs it once above the router with the format
/// from `gzFormatProvider` (so the Eastern-digits switch and the fixed clock reach every component):
///
/// ```dart
/// GzFormatScope(format: ref.watch(gzFormatProvider), child: ...)
/// ```
///
/// Without a scope the components fall back to a default `GzFormat` for the ambient locale (Western digits, the device clock),
/// which is also what tests and galleries get.
class GzFormatScope extends InheritedWidget {
  const GzFormatScope({required this.format, required super.child, super.key});

  final GzFormat format;

  static final Map<String, GzFormat> _fallback = <String, GzFormat>{};

  /// The scoped formatter, else the default one for the ambient locale.
  static GzFormat of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GzFormatScope>();
    if (scope != null) return scope.format;
    final locale = context.gz.locale;
    return _fallback.putIfAbsent(locale.languageCode, () => GzFormat(locale: Locale(locale.languageCode)));
  }

  @override
  bool updateShouldNotify(GzFormatScope oldWidget) => oldWidget.format != format;
}

extension GzFormatContext on BuildContext {
  /// The shared formatter (see [GzFormatScope]).
  GzFormat get gzFormat => GzFormatScope.of(this);
}

// The formatter wraps digits in LRI/PDI isolates in Arabic and joins number and unit with a no-break space.
final RegExp _emptyTail = RegExp(' \u2066?[0\u0660]\u2069?\u00a0(?:m|\u062f|h|\u0633)\$');

extension GzDurationContext on BuildContext {
  /// A compact duration for facts and deadlines: `23 h`, `1 d 4 h`, `45 m` (the formatter's compact duration with an empty
  /// trailing unit dropped, so a whole number of hours reads `23 h`, not `23 h 0 m`). Always the shared formatter.
  String gzDuration(int ms) => gzFormat.duration(ms).replaceFirst(_emptyTail, '');
}
