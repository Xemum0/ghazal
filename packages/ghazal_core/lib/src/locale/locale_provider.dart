import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics.dart';
import '../env/app_env.dart';
import '../format/config.dart';
import '../format/gz_format.dart';

/// Supported UI locales (ADR 0022 E): Arabic first, English second. `ar_KW` has no distinct data.
const List<Locale> gzSupportedLocales = [Locale('ar'), Locale('en')];

/// First-run locale when the device language is neither Arabic nor English.
const Locale gzDefaultLocale = Locale('ar');

const String kPrefLocale = 'gz.locale';
const String kPrefDigitStyle = 'gz.digit_style';

/// The opened preferences, or null when not wired (unit tests, the shot harness: nothing is persisted then). The app
/// bootstrap overrides it with [loadPreferencesOverride].
final Provider<SharedPreferences?> sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Opens shared_preferences once and returns the override for the root `ProviderScope`:
/// `ProviderScope(overrides: [await loadPreferencesOverride()], child: ...)`.
Future<Override> loadPreferencesOverride() async {
  final prefs = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(prefs);
}

/// The build-time environment. Override in tests: `appEnvProvider.overrideWithValue(const AppEnv(...))`.
final Provider<AppEnv> appEnvProvider = Provider<AppEnv>((ref) => AppEnv.fromEnvironment());

/// Device language if Arabic or English, otherwise Arabic (ADR 0022 E).
Locale deviceLocaleOrDefault([Locale? device]) {
  final code = (device ?? PlatformDispatcher.instance.locale).languageCode;
  return switch (code) {
    'en' => const Locale('en'),
    'ar' => const Locale('ar'),
    _ => gzDefaultLocale,
  };
}

/// The UI locale. Resolution order: an explicit [LocaleNotifier] argument (tests, the shot harness), the `GZ_LOCALE`
/// define outside prod, the persisted choice, the device language if `ar` or `en`, otherwise Arabic.
/// Tests and the harness override it with `localeProvider.overrideWith(() => LocaleNotifier(const Locale('en')))`.
final NotifierProvider<LocaleNotifier, Locale> localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  LocaleNotifier([this._forced]);

  final Locale? _forced;

  @override
  Locale build() {
    if (_forced != null) return _forced;
    final env = ref.read(appEnvProvider).localeOverride;
    if (env != null) return Locale(env);
    final stored = ref.read(sharedPreferencesProvider)?.getString(kPrefLocale);
    if (stored == 'ar' || stored == 'en') return Locale(stored!);
    return deviceLocaleOrDefault();
  }

  /// Changes the UI language, persists it and tells analytics.
  void setLocale(Locale locale) {
    if (locale.languageCode == state.languageCode) return;
    state = Locale(locale.languageCode);
    ref.read(sharedPreferencesProvider)?.setString(kPrefLocale, state.languageCode);
    ref.read(analyticsProvider)
      ..setCommonProperty('lang', state.languageCode)
      ..track(AnalyticsEvent(GzEvents.languageChanged, {'lang': state.languageCode}));
  }
}

/// The Eastern-digits switch (ADR 0010 D2): meaningful in Arabic only, off by default, persisted.
final NotifierProvider<DigitStyleNotifier, DigitStyle> digitStyleProvider =
    NotifierProvider<DigitStyleNotifier, DigitStyle>(DigitStyleNotifier.new);

class DigitStyleNotifier extends Notifier<DigitStyle> {
  DigitStyleNotifier([this._forced]);

  final DigitStyle? _forced;

  @override
  DigitStyle build() {
    if (_forced != null) return _forced;
    return DigitStyle.fromName(ref.read(sharedPreferencesProvider)?.getString(kPrefDigitStyle));
  }

  void setStyle(DigitStyle style) {
    if (style == state) return;
    state = style;
    ref.read(sharedPreferencesProvider)?.setString(kPrefDigitStyle, style.name);
    ref.read(analyticsProvider)
      ..setCommonProperty('digit_style', style.name)
      ..track(AnalyticsEvent(GzEvents.digitStyleChanged, {'digit_style': style.name}));
  }
}

/// The clock every formatter reads. Production: the device clock; tests and shots override it with a fixed time
/// (`clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 12, 13))`).
final Provider<DateTime Function()> clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The formatter for the current locale, digit style and clock. Rebuilds when any of them changes.
final Provider<GzFormat> gzFormatProvider = Provider<GzFormat>((ref) {
  return GzFormat(
    locale: ref.watch(localeProvider),
    digitStyle: ref.watch(digitStyleProvider),
    now: ref.watch(clockProvider),
  );
});
