import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported UI locales (ADR 0022 E): Arabic first, English second. `ar_KW` has no distinct data.
const List<Locale> gzSupportedLocales = [Locale('ar'), Locale('en')];

/// First-run locale: Arabic (ADR 0022 E: device language if ar or en, otherwise Arabic; the device probe arrives with F1b).
const Locale gzDefaultLocale = Locale('ar');

/// The UI locale. Persistence (shared_preferences) and the device-language probe are added in phase F1b.
/// Tests and the shot harness override it with `localeProvider.overrideWith(() => LocaleNotifier(const Locale('en')))`.
final NotifierProvider<LocaleNotifier, Locale> localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  LocaleNotifier([this._initial = gzDefaultLocale]);

  final Locale _initial;

  @override
  Locale build() => _initial;

  void setLocale(Locale locale) => state = locale;
}
