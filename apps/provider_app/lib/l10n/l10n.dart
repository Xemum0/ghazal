import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.someKey` (or `context.l10n.someKey(args)`): the compile-time-safe strings of this app. Prices, dates,
/// times and phones are never formatted inside a message; pass the finished string from `gzFormatProvider`.
extension AppL10nContext on BuildContext {
  AppL10n get l10n => AppL10n.of(this);
}
