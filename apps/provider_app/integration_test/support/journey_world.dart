// The journey world of the PARTNER app: how an integration test starts the app and drives it (a mirror of
// apps/client_app/integration_test/support/journey_world.dart, same API).
//
// A journey starts the app through its REAL entry (`bootstrap()` of lib/bootstrap.dart, that is `runGhazalApp`: binding, locale data,
// preferences, the in-process mock with the story clock, session restore, the router) and then only taps, types and reads what is on screen.
// It runs unchanged in two places:
//   - headless on the host:  `node apps/provider_app/integration_test/headless.mjs <journey>`  (the host test device of `flutter test`; a tiny wrapper
//     in build/journeys calls the same main(), because `flutter test integration_test/<file>` without `-d` fails with "No devices are
//     connected"; this world sets the real fonts and the 390 x 844 phone on the host)
//   - on a simulator:        `flutter test integration_test/<file> -d <device id>`  (the real device size, fonts and keyboard are the device's)
// The binding is `LiveTestWidgetsFlutterBinding`: pumps wait in REAL time and the mock's timers (gateway 1.5 s, undo window 8 s, scripted
// replies 2.5 s) run for real. Nothing here uses `pumpAndSettle` (the app has looping animations): every wait is bounded.
//
//   void main() {
//     journeySetUp();
//     journey('J1 ...', (j) async {
//       await j.start();                        // the app, signed out, in the in-process mock (a fresh story)
//       await j.tap(find.text(en.commonActionContinue));
//       await j.see(find.text(j.t((l) => l.commonActionContinue)));
//     });
//   }
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:provider_app/app/app.dart';
import 'package:provider_app/bootstrap.dart';
import 'package:provider_app/l10n/generated/app_localizations.dart';
import 'package:provider_app/l10n/generated/app_localizations_ar.dart';
import 'package:provider_app/l10n/generated/app_localizations_en.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, GzLogLevel, GzLogSink, GzLogger, gzFormatProvider, localeProvider;
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show MockBackend, MockControl;
import 'package:ghazal_testing/ghazal_testing.dart' show loadAppFonts;
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The English and Arabic catalogues of the app, for expectations (`en.commonActionContinue`).
final AppL10nEn en = AppL10nEn();
final AppL10nAr ar = AppL10nAr();

/// True when the test runs on the host test device of `flutter test` (no `-d`): fonts, view size and the keyboard are then simulated.
final bool onHost = Platform.environment.containsKey('FLUTTER_TEST');

/// The prototype device (iPhone 17e class): 390 x 844 logical points at 3x is what the simulator reports; the host uses 2x like the shots.
const Size kPhone = Size(390, 844);

/// The language a journey picks at the first screen (`--dart-define=JOURNEY_LANG=ar` runs it in Arabic; default English).
const String kJourneyLang = String.fromEnvironment('JOURNEY_LANG', defaultValue: 'en');

/// `--dart-define=JOURNEY_SEMANTICS=true` runs every journey with the semantics tree on (a person using VoiceOver).
const bool kJourneySemantics = bool.fromEnvironment('JOURNEY_SEMANTICS');

/// `--dart-define=JOURNEY_TRACE=true` prints every screen change (to find WHEN an error is raised).
const bool kJourneyTrace = bool.fromEnvironment('JOURNEY_TRACE');

bool _ready = false;

/// Call once at the top of `main()`: the integration binding, the real fonts on the host (the host would draw every glyph with the square
/// test font, which overflows everywhere; a device has the fonts bundled by the engine).
void journeySetUp() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (onHost) await loadAppFonts();
    _ready = true;
  });
}

/// One journey: starts a fresh [Journey], runs [body], then checks that the app raised no framework error and shut it down.
///
/// [semantics] builds the semantics tree on every frame, as for a person using VoiceOver (the default of `testWidgets`, but NOT of a phone
/// without a screen reader, so a journey leaves it off unless `--dart-define=JOURNEY_SEMANTICS=true` or the journey asks for it).
void journey(
  String description,
  Future<void> Function(Journey j) body, {
  Duration timeout = const Duration(minutes: 8),
  bool semantics = kJourneySemantics,
}) {
  testWidgets(description, timeout: Timeout(timeout), semanticsEnabled: semantics, (tester) async {
    expect(_ready, isTrue, reason: 'journeySetUp() was not called');
    final j = Journey._(tester);
    try {
      await body(j);
      j.expectNoErrors();
    } finally {
      await j._dispose();
    }
  });
}

/// The app under test and the helpers to drive it. Every wait is bounded and fails with a readable list of what the screen shows.
class Journey {
  Journey._(this.tester);

  final WidgetTester tester;

  /// Framework, platform and logged errors the app raised since [start] (render overflow, build errors, uncaught async errors).
  final List<String> errors = <String>[];
  FlutterExceptionHandler? _testOnError;
  GzLogSink? _oldSink;
  bool _started = false;

  // ------------------------------------------------------------------------------------------------------------- start and stop

  /// Starts the app through its real entry (`bootstrap()`), signed out, or, with [persona] (`hotel_manager`), signed in as that demo
  /// person (the session is the mock's own, the way the Demo tools switch persona) and in the language of `JOURNEY_LANG`.
  Future<ProviderContainer> start({String? persona, Size size = kPhone}) async {
    expect(_started, isFalse, reason: 'one app start per journey');
    _started = true;
    if (onHost) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final view = tester.view;
      view
        ..devicePixelRatio = 2
        ..physicalSize = Size(size.width * 2, size.height * 2)
        ..padding = const FakeViewPadding(top: 94, bottom: 68)
        ..viewPadding = const FakeViewPadding(top: 94, bottom: 68);
    } else {
      // a device keeps the app's preferences between runs: a journey starts as a first-time user
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
    _testOnError = FlutterError.onError;
    _oldSink = GzLogger.sink;
    GzLogger.sink = (level, tag, message, error, stack) {
      if (level == GzLogLevel.error) errors.add('[$tag] $message${error == null ? '' : ' | $error'}');
    };
    await bootstrap();
    // the bootstrap installed its own error hooks (log and carry on): from here the journey collects every framework error itself
    FlutterError.onError = (details) {
      final at = details.stack.toString().split('\n').where((l) => l.contains('package:')).take(3).join(' <- ');
      errors.add('FlutterError after "$_lastStep" on $_lastScreen: ${details.exceptionAsString().split('\n').first} (${details.library ?? '-'}) at $at');
    };
    // the collector must really see an error: a probe goes through the same hook a layout overflow or a build error takes
    FlutterError.reportError(FlutterErrorDetails(exception: 'journey probe', library: 'journey world'));
    expect(errors, hasLength(1), reason: 'the journey error collector is wired');
    errors.clear();
    await pump(const Duration(milliseconds: 1500));
    final c = container;
    // the story: fresh (the mock was built by this start) and, for a persona, signed in
    await control.reset();
    if (persona != null && persona != 'guest') {
      await c.read(sessionProvider.notifier).loadPersona(persona);
      // a journey that starts signed in (no language screen) takes its language from `JOURNEY_LANG` through the app's own setting
      if (locale.languageCode != kJourneyLang) c.read(localeProvider.notifier).setLocale(Locale(kJourneyLang));
      await pump(const Duration(milliseconds: 1500));
    }
    return c;
  }

  String _lastScreen = '-';

  Future<void> _dispose() async {
    if (!_started) return;
    try {
      await tester.pumpWidget(const SizedBox.shrink());
      await pump(const Duration(milliseconds: 300));
    } finally {
      FlutterError.onError = _testOnError;
      if (_oldSink != null) GzLogger.sink = _oldSink!;
      if (onHost) tester.view.reset();
    }
  }

  /// Fails when the app raised an error since [start] (an overflow is a `FlutterError` too).
  void expectNoErrors({String? where}) {
    expect(errors, isEmpty, reason: 'the app raised errors${where == null ? '' : ' $where'}:\n${errors.join('\n')}');
  }

  // ------------------------------------------------------------------------------------------------------------------- reading

  ProviderContainer get container => ProviderScope.containerOf(tester.element(find.byType(ProviderApp)));
  GzNavigator get nav => container.read(gzNavigatorProvider);
  String get screen => nav.currentId;
  MockBackend get mock => container.read(mockBackendProvider)!;
  MockControl get control => mock.control;
  Locale get locale => container.read(localeProvider);
  bool get isArabic => locale.languageCode == 'ar';

  /// The app's own formatter (prices, dates, numbers in the running language): the expected text of anything that is data, not words.
  GzFormat get format => container.read(gzFormatProvider);

  /// The accessible name of a calendar day button (`Thursday 21 January 2027`), as the calendar builds it, safe for a `RegExp`.
  RegExp dayLabel(String iso) => RegExp(RegExp.escape(format.plain(format.date(iso, DateStyle.full))));

  /// Switches the app to [code] (`en` or `ar`) through its own language setting, like the language row of the profile does, and lets it mirror.
  Future<void> useLanguage(String code) async {
    container.read(localeProvider.notifier).setLocale(Locale(code));
    await pump(const Duration(milliseconds: 1200));
    expect(locale.languageCode, code);
  }

  /// The words of the running language, typed: `j.t((l) => l.commonActionContinue)`, `j.t((l) => l.commonCountHalls(3))`.
  String t(String Function(AppL10n l) pick) => pick(isArabic ? ar : en);

  /// A progress line in the test output (a journey is long and silent otherwise): what the journey is about to do.
  void step(String what) {
    _lastStep = what;
    _lastScreen = screen;
    debugPrint('  - $what  [$_lastScreen]');
  }

  /// True when some widget draws [text] (plain or rich; bidi marks ignored).
  bool shows(String text) => find
      .byWidgetPredicate((w) => w is RichText && _plain(w).contains(text))
      .evaluate()
      .isNotEmpty;

  /// True when some widget draws text that matches [pattern] (non-breaking spaces count as spaces).
  bool showsMatch(RegExp pattern) => find
      .byWidgetPredicate((w) => w is RichText && pattern.hasMatch(_plain(w).replaceAll('\u00a0', ' ')))
      .evaluate()
      .isNotEmpty;

  static String _plain(RichText w) => w.text.toPlainText().replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f]'), '');

  /// Everything written under the widget with [key], bidi marks removed and blanks collapsed (a card, a row, a sheet).
  String textUnder(String key) {
    final parts = find
        .descendant(of: find.byKey(ValueKey<String>(key)), matching: find.byType(RichText))
        .evaluate()
        .map((e) => _plain(e.widget as RichText))
        .where((s) => s.trim().isNotEmpty);
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ');
  }

  bool onScreen(String key) => find.byKey(ValueKey<String>(key)).evaluate().isNotEmpty;

  /// The texts on screen, for a failure message (what the person would read).
  String dump() {
    final seen = <String>{};
    for (final e in find.byType(RichText).evaluate()) {
      final w = e.widget as RichText;
      final s = _plain(w).trim();
      if (s.isNotEmpty && seen.length < 60) seen.add(s.length > 50 ? '${s.substring(0, 50)}...' : s);
    }
    return 'screen "${nav.currentId}" shows: ${seen.join(' | ')}';
  }

  // ------------------------------------------------------------------------------------------------------------------- waiting

  /// Lets real time pass for [d], one frame per 100 ms (the mock answers in real async, the app animates in real time).
  Future<void> pump([Duration d = const Duration(milliseconds: 800)]) async {
    final steps = math.max(1, d.inMilliseconds ~/ 100);
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      _watch();
    }
  }

  int _reported = 0;

  /// Prints the moment an error is raised and where the app was, so a failing journey says WHEN, not only what.
  String _seenScreen = '';

  void _watch() {
    if (kJourneyTrace) {
      try {
        if (screen != _seenScreen) debugPrint('    . screen ${_seenScreen = screen} (errors ${errors.length})');
      } on Object {
        // mid-frame
      }
    }
    if (errors.length == _reported) return;
    _reported = errors.length;
    String now;
    try {
      now = screen;
    } on Object {
      now = '?';
    }
    debugPrint('  ! error #$_reported after "$_lastStep" on $now: ${errors.last.split(' at ').first}');
  }

  String _lastStep = '-';

  /// Waits (polling every 100 ms, at most [timeout]) until [finder] matches, and fails with what the screen shows when it never does.
  Future<void> see(Finder finder, {Duration timeout = const Duration(seconds: 12), String? why}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) fail('${why ?? 'expected'} $finder not found within ${timeout.inSeconds}s: ${dump()}');
      await tester.pump(const Duration(milliseconds: 100));
    }
    _lastScreen = screen;
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Taps the control that draws [text] when it shows up within [timeout] (a prompt that may or may not come, such as the Face ID offer);
  /// returns whether it did.
  Future<bool> tapTextIfShown(String text, {Duration timeout = const Duration(seconds: 4)}) async {
    final end = DateTime.now().add(timeout);
    while (!shows(text)) {
      if (DateTime.now().isAfter(end)) return false;
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tapText(text);
    return true;
  }

  /// Waits until [finder] no longer matches.
  Future<void> gone(Finder finder, {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(end)) fail('$finder still on screen after ${timeout.inSeconds}s: ${dump()}');
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Waits until the app is on screen [id].
  Future<void> seeScreen(String id, {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (screen != id) {
      if (DateTime.now().isAfter(end)) fail('expected screen $id within ${timeout.inSeconds}s, found ${dump()}');
      await tester.pump(const Duration(milliseconds: 100));
    }
    _lastScreen = screen;
    await pump(const Duration(milliseconds: 500));
  }

  /// Waits until [text] is drawn.
  Future<void> seeText(String text, {Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    while (!shows(text)) {
      if (DateTime.now().isAfter(end)) fail('"$text" not drawn within ${timeout.inSeconds}s: ${dump()}');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  // ------------------------------------------------------------------------------------------------------------------- driving

  bool _vertical(Widget w) => w is Scrollable && w.axis == Axis.vertical;

  /// Brings [target] into the middle of its scroll view with drags (a lazy list builds the row when it comes near). Bounded.
  Future<void> scrollTo(Finder target, {Finder? within}) async {
    if (target.evaluate().isNotEmpty && target.hitTestable().evaluate().isNotEmpty) return;
    final views = find.byWidgetPredicate(_vertical);
    if (views.evaluate().isEmpty) return;
    final view = within ?? (target.evaluate().isNotEmpty ? find.ancestor(of: target.first, matching: views) : views);
    if (view.evaluate().isEmpty) return;
    if (target.evaluate().isEmpty) {
      await tester.dragUntilVisible(target.first, view.first, const Offset(0, -240), maxIteration: 40);
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 6; i++) {
      final rect = tester.getRect(view.first);
      final at = tester.getCenter(target.first);
      if (at.dy > rect.top + 80 && at.dy < rect.bottom - 80 && target.hitTestable().evaluate().isNotEmpty) return;
      final delta = rect.center.dy - at.dy;
      await tester.drag(view.first, Offset(0, delta.clamp(-rect.height * 0.7, rect.height * 0.7)), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  /// Scrolls to and taps the first match of [finder], then lets the app answer for [wait].
  Future<void> tap(Finder finder, {Duration wait = const Duration(milliseconds: 900)}) async {
    await see(finder);
    final f = finder.first;
    await scrollTo(f);
    final hit = f.hitTestable();
    await tester.tap(hit.evaluate().isEmpty ? f : hit, warnIfMissed: false);
    await pump(wait);
  }

  /// Taps the control that draws [text] (a chip draws its label twice: the visible copy is the last).
  Future<void> tapText(String text, {Duration wait = const Duration(milliseconds: 900), bool last = true}) async {
    await seeText(text);
    final exact = find.text(text, findRichText: true);
    final all = exact.evaluate().isNotEmpty ? exact : find.textContaining(text, findRichText: true);
    final visible = all.hitTestable();
    final pool = visible.evaluate().isNotEmpty ? visible : all;
    await tap(last ? pool.last : pool.first, wait: wait);
  }

  Future<void> tapKey(String key, {Duration wait = const Duration(milliseconds: 900)}) => tap(find.byKey(ValueKey<String>(key)), wait: wait);

  /// Types into the [index]th text field on screen and lets the app answer.
  Future<void> type(int index, String text, {Duration wait = const Duration(milliseconds: 400)}) async {
    await see(find.byType(EditableText));
    final field = find.byType(EditableText).at(index);
    await tester.tap(field, warnIfMissed: false);
    await pump(const Duration(milliseconds: 200));
    await tester.enterText(field, text);
    await pump(wait);
  }

  /// Taps the control with the accessible name [label] (a calendar day paints itself, its name is its only handle): the semantics tree is
  /// built for the tap and released right after.
  Future<void> tapNamed(Pattern label, {Duration wait = const Duration(milliseconds: 600)}) async {
    final handle = tester.ensureSemantics();
    try {
      await pump(const Duration(milliseconds: 300));
      await tap(find.bySemanticsLabel(label), wait: wait);
    } finally {
      handle.dispose();
    }
  }

  /// Goes back the way the person does: the top bar back button (what an RTL swipe-back triggers too).
  Future<void> back({Duration wait = const Duration(milliseconds: 900)}) async {
    await tap(find.byKey(const ValueKey<String>('gz:bar.back')), wait: wait);
  }

  // ------------------------------------------------------------------------------------------------------------------- the mock

  /// The person leaves the app and comes back (the lifecycle the OS reports): what the app refetches on return shows up.
  Future<void> backgroundAndResume() async {
    // no pump while the app is paused: a paused binding schedules no frame and a pump would wait for one for ever
    final b = tester.binding;
    for (final s in const [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      b.handleAppLifecycleStateChanged(s);
    }
    await pump(const Duration(seconds: 2));
  }

  /// Runs [action] on the story clock and lets the app see it (the clock only moves through the control surface).
  Future<void> advance(Duration d) async {
    control.advance(d);
    await pump(const Duration(milliseconds: 600));
  }
}
