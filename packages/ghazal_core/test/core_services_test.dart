import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  intlInitTests();
  group('AppEnv', () {
    test('defaults', () {
      const e = AppEnv();
      expect(e.useMock, isTrue);
      expect(e.environment, GzEnvironment.dev);
      expect(e.mockLatencyMs, 0);
    });
    test('GZ_LOCALE is honoured outside prod only', () {
      expect(AppEnv.fromValues(env: 'dev', locale: 'en').localeOverride, 'en');
      expect(AppEnv.fromValues(env: 'staging', locale: 'ar').localeOverride, 'ar');
      expect(AppEnv.fromValues(env: 'prod', locale: 'en').localeOverride, isNull);
      expect(AppEnv.fromValues(locale: 'fr').localeOverride, isNull);
    });
    test('parses values', () {
      final e = AppEnv.fromValues(apiBaseUrl: 'https://api.example.test', useMock: false, env: 'prod', mockLatencyMs: -5);
      expect(e.apiBaseUrl, 'https://api.example.test');
      expect(e.isProd, isTrue);
      expect(e.mockLatencyMs, 0);
      expect(AppEnv.fromEnvironment().useMock, isTrue);
    });
  });

  group('ApiProblem', () {
    test('parses problem+json with params, alternatives and field errors', () {
      final p = ApiProblem.fromResponse(status: 409, headers: {'retry-after': '7'}, body: {
        'type': 'https://api.x/problems/slot-unavailable',
        'title': 'Slot unavailable',
        'status': 409,
        'code': 'SLOT_UNAVAILABLE',
        'requestId': 'r1',
        'params': {'eventDate': '2027-01-14'},
        'alternatives': [
          {'eventDate': '2027-01-21'}
        ],
        'errors': [
          {'path': 'guests', 'code': 'GUESTS_OUT_OF_RANGE', 'params': {'min': 300}}
        ],
      });
      expect(p.code, ApiProblemCode.slotUnavailable);
      expect(p.messageKey, 'apiErrorSlotUnavailable');
      expect(p.params['eventDate'], '2027-01-14');
      expect(p.alternatives.single['eventDate'], '2027-01-21');
      expect(p.errors.single.code, ApiProblemCode.guestsOutOfRange);
      expect(p.errors.single.params['min'], 300);
      expect(p.retryAfterSeconds, 7);
      expect(p.requestId, 'r1');
    });
    test('accepts a JSON string, falls back to UNKNOWN, maps flags', () {
      expect(ApiProblem.fromResponse(status: 401, body: '{"code":"TOKEN_EXPIRED"}').requiresRefresh, isTrue);
      expect(ApiProblem.fromResponse(status: 401, body: '{"code":"SESSION_REVOKED"}').requiresSignOut, isTrue);
      final html = ApiProblem.fromResponse(status: 502, body: '<html>');
      expect(html.code, ApiProblemCode.unknown);
      expect(html.isTransient, isTrue);
      expect(const ApiProblem.offline().isOffline, isTrue);
      expect(ApiProblemCode.parse('NOPE'), ApiProblemCode.unknown);
    });
    test('every documented code round-trips by its wire name', () {
      for (final c in ApiProblemCode.values) {
        expect(ApiProblemCode.parse(c.wire), c);
      }
      expect(ApiProblemCode.values.length, greaterThanOrEqualTo(32));
    });
  });

  group('RetryPolicy', () {
    const policy = RetryPolicy();
    test('only idempotent GETs on network errors and 5xx, max 3', () {
      expect(policy.shouldRetry(method: 'GET', status: 503, attempt: 0), isTrue);
      expect(policy.shouldRetry(method: 'GET', status: null, attempt: 2), isTrue);
      expect(policy.shouldRetry(method: 'GET', status: 503, attempt: 3), isFalse);
      expect(policy.shouldRetry(method: 'GET', status: 404, attempt: 0), isFalse);
      expect(policy.shouldRetry(method: 'POST', status: 503, attempt: 0), isFalse);
      expect(policy.shouldRetry(method: 'DELETE', status: null, attempt: 0), isFalse);
    });
    test('backoff grows and is capped', () {
      expect(policy.delayFor(0, random: () => 0), const Duration(milliseconds: 300));
      expect(policy.delayFor(1, random: () => 0), const Duration(milliseconds: 600));
      expect(policy.delayFor(10, random: () => 0), const Duration(seconds: 4));
    });
    test('run retries then succeeds, and never retries a POST', () async {
      var calls = 0;
      final slept = <Duration>[];
      final v = await policy.run<int>(
        () async {
          calls++;
          if (calls < 3) throw const ApiProblem(status: 503, code: ApiProblemCode.unknown);
          return 7;
        },
        method: 'GET',
        statusOf: (e) => (e as ApiProblem).status,
        sleep: (d) async => slept.add(d),
      );
      expect((v, calls, slept.length), (7, 3, 2));
      calls = 0;
      await expectLater(
        policy.run<int>(() async {
          calls++;
          throw const ApiProblem(status: 503, code: ApiProblemCode.unknown);
        }, method: 'POST', statusOf: (e) => (e as ApiProblem).status, sleep: (_) async {}),
        throwsA(isA<ApiProblem>()),
      );
      expect(calls, 1);
    });
  });

  group('GzLogger and Analytics', () {
    test('logger respects the level and the sink', () {
      final seen = <String>[];
      final oldSink = GzLogger.sink;
      final oldMin = GzLogger.minLevel;
      GzLogger.sink = (l, t, m, e, s) => seen.add('${l.name}:$t:$m');
      GzLogger.minLevel = GzLogLevel.info;
      const GzLogger('x')
        ..debug('hidden')
        ..info('shown')
        ..error('bad');
      GzLogger.sink = oldSink;
      GzLogger.minLevel = oldMin;
      expect(seen, ['info:x:shown', 'error:x:bad']);
    });
    test('recording analytics carries common properties and rejects unregistered events', () {
      final a = RecordingAnalytics()..setCommonProperty('lang', 'ar');
      a.track(const AnalyticsEvent(GzEvents.venueViewed, {'venue_id': 'v1'}));
      expect(a.events.single.properties, {'lang': 'ar', 'venue_id': 'v1'});
      expect(() => a.track(const AnalyticsEvent('Venue Viewed')), throwsArgumentError);
      const NoopAnalytics().track(const AnalyticsEvent('anything'));
      expect(GzEvents.all.toSet().length, GzEvents.all.length);
      expect(GzEvents.all.every((e) => RegExp(r'^[a-z]+(_[a-z]+)+$').hasMatch(e)), isTrue);
    });
  });

  group('ScreenState', () {
    test('maps the five states', () {
      expect(ScreenState.from<int>(const AsyncLoading()), isA<ScreenLoading<int>>());
      expect(ScreenState.from<int>(const AsyncData(1)), isA<ScreenData<int>>());
      expect(ScreenState.from<List<int>>(const AsyncData([]), isEmpty: (d) => d.isEmpty), isA<ScreenEmpty<List<int>>>());
      expect(ScreenState.from<int>(AsyncError(const ApiProblem.offline(), StackTrace.empty)), isA<ScreenOffline<int>>());
      final err = ScreenState.from<int>(AsyncError(const ApiProblem(status: 500, code: ApiProblemCode.unknown), StackTrace.empty));
      expect(err, isA<ScreenError<int>>());
      final text = err.when(loading: () => 'l', data: (d) => 'd', empty: () => 'e', error: (p) => 'x${p.status}', offline: (s) => 'o');
      expect(text, 'x500');
    });
  });

  group('parseRichTags', () {
    test('splits tags and keeps plain text', () {
      expect(parseRichTags('This holds <f>Sun 15 Nov</f> for <n>Sara</n>.'), const [
        RichPart('This holds '),
        RichPart('Sun 15 Nov', 'f'),
        RichPart(' for '),
        RichPart('Sara', 'n'),
        RichPart('.'),
      ]);
      expect(parseRichTags('no tags'), const [RichPart('no tags')]);
      expect(parseRichTags('a < b'), const [RichPart('a < b')]);
      expect(parseRichTags(''), isEmpty);
    });
  });

  group('providers', () {
    test('locale defaults to Arabic or the device language, persists, honours GZ_LOCALE', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      expect(deviceLocaleOrDefault(const Locale('fr')), const Locale('ar'));
      expect(deviceLocaleOrDefault(const Locale('en', 'GB')), const Locale('en'));
      final target = c.read(localeProvider).languageCode == 'en' ? const Locale('ar') : const Locale('en');
      c.read(localeProvider.notifier).setLocale(target);
      expect(c.read(localeProvider), target);
      await pumpEventQueue();
      expect(prefs.getString(kPrefLocale), target.languageCode);
      final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c2.dispose);
      expect(c2.read(localeProvider), target);
      final c3 = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appEnvProvider.overrideWithValue(AppEnv.fromValues(locale: 'ar')),
      ]);
      addTearDown(c3.dispose);
      expect(c3.read(localeProvider), const Locale('ar'));
    });

    test('digit style persists and gzFormatProvider follows locale, style and clock', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fixed = DateTime.parse('2026-11-12T16:00:00+03:00');
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => fixed),
        localeProvider.overrideWith(() => LocaleNotifier(const Locale('ar'))),
      ]);
      addTearDown(c.dispose);
      expect(c.read(gzFormatProvider).money(2000), '\u20662\u2069 د.ك');
      c.read(digitStyleProvider.notifier).setStyle(DigitStyle.easternArabic);
      await pumpEventQueue();
      expect(prefs.getString(kPrefDigitStyle), 'easternArabic');
      expect(c.read(gzFormatProvider).money(2000), '\u2066٢\u2069 د.ك');
      expect(c.read(gzFormatProvider).relativeDay('2026-11-12T20:00'), 'اليوم');
      c.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(c.read(gzFormatProvider).money(2000), 'KD 2');
    });
  });
}

void intlInitTests() {
  test('initGzIntl initialises ar and en date symbols', () async {
    await initGzIntl(defaultLocale: 'en');
    expect(DateFormat.MMMM('ar').dateSymbols.MONTHS.length, 12);
    expect(DateFormat.MMMM('en').format(DateTime(2027, 1, 14)), 'January');
  });
}
