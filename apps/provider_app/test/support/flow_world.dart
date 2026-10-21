// The flow test world of the partner app: a mirror of apps/client_app/test/support/flow_world.dart (same API), over `ProviderApp`.
//
// A flow test opens ONE screen of the REAL app (`ProviderApp` over the generated router, the shell, the kit) on the in-process mock, as a
// persona, with the real fonts, no request retry, the prototype's story clock and a base page that is not the first-start screen; it
// then drives the app with real taps. Usage and the full API: docs/engineering/flutter-dev.md, "Shell and test world".
//
//   flowTest('Sort opens a sheet', (tester) async {
//     final c = await openScreen(tester, 'HL-BOOK-01');
//     await tapKey(tester, 'bookings.filter');
//     expect(onScreen('discover.sort'), isTrue);
//   });                                      // flowTest ends with finish(tester)
//
// Rules the world enforces or documents (each one cost a pilot agent an hour):
// - ONE scenario per test: a second `openScreen` in a test throws (the harness builds a fresh container each time, so the second one
//   silently starts from nothing). Split the test, or navigate inside the scenario with the navigator.
// - `flush: true` (opening a screen, `finish`, `flush(tester)`) runs the mock's pending work and ENDS THE 8 s UNDO WINDOW of a partner
//   action: taps and `settle` do not flush unless asked, so Accept, then Undo works; never pass `flush: true` between the two.
// - No real IO in fake async (a widget test body): it never completes (0 % CPU hang). The world does its real-async work inside
//   `tester.runAsync`.
// - `tester.ensureVisible` aligns the target to the TOP of a scroll view and parks it under a pinned top bar: use [scrollTo] (a drag).
// - End every test with [finish] (unmount, pump a second) or use [flowTest], which does: a timer left pending fails the test.
import 'dart:math' as math;

import 'package:provider_app/app/app.dart';
import 'package:provider_app/app/screen_registry.dart';
import 'package:provider_app/l10n/generated/app_localizations_ar.dart';
import 'package:provider_app/l10n/generated/app_localizations_en.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show RestRepositories;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show MockControl;
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_testing/src/world.dart' show GzWorld;
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator, GzParams, GzSheetOptions;

/// The English and Arabic catalogues of the app, for expectations (`en.commonActionContinue`).
final AppL10nEn en = AppL10nEn();
final AppL10nAr ar = AppL10nAr();

/// The first tab root (Today): the base page under a screen that needs one (a screen with route params, a sheet).
const String kFlowBase = 'HL-TODY-01';

/// Set to true by a test once the app has left the flow under test: render errors of another flow's screen are not this test's failure.
/// Reset by every [openScreen].
bool ignoreRenderErrors = false;

GzWorld? _world;
bool _fontsLoaded = false;
_Scenario? _scenario;

class _Scenario {
  _Scenario(this.id, this.flush);

  final String id;
  final Future<void> Function()? flush;
}

_Scenario get _open => _scenario ?? (throw StateError('No screen is open: call openScreen(tester, id) first.'));

/// The mock backend of the process (one per test isolate, seeded from disk). Its control surface: `flowControl.jumpToStory('approved')`.
Future<GzWorld> flowWorld() async => _world ??= await GzWorld.load();

/// The control surface of the mock (clock, story points, scenarios) once a screen is open.
MockControl get flowControl => _world!.control;

/// The real repositories acting as [persona], for reading what a flow wrote (`flowRepos('hotel_manager', venueId: 'V01')`). Real async:
/// call them inside `tester.runAsync`.
RestRepositories flowRepos(String persona, {String? venueId, String? providerId}) => _world!.repos(persona, venueId: venueId, providerId: providerId);

/// A `testWidgets` for a flow: the body, then [finish] when it opened a screen.
void flowTest(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
      if (_scenario != null) await finish(tester);
    } finally {
      // restored here, not only in a tear-down: the binding checks `FlutterError.onError` before the tear-downs run and a failing test
      // would then report that instead of its own error
      _restoreErrorFilter();
    }
  });
}

/// Opens [id] in the real app and lets the world answer. Returns the container of the app (providers: `c.read(sessionProvider)`).
///
/// - [persona]: `guest`, `hotel_manager`, `hotel_admin`, `provider` ... (default: the shot rule, the hotel manager except access, a guest).
/// - [state]: a mock scenario (`loading`, `empty`, `error`, `offline`, `expired`, `slow`) or `guest`.
/// - [story]: moves the hero story to one of its points before the first frame (`approved`, `confirmed`, `lapsed`, `expired` ...).
/// - [params]: the route params of [id]. A screen with params starts on [base] (default Today) and is pushed, the way the app opens it.
/// - [size], [locale], [textScale]: the device (default 390 x 844, English, 1.0). [clock]: the story clock (default 2026-11-12 16:00).
/// - [extraSeconds]: more fake time to wait after the first settle (a retried error state).
/// Throws when a screen is already open in this test.
Future<ProviderContainer> openScreen(
  WidgetTester tester,
  String id, {
  String? persona,
  String state = '',
  GzParams params = const <String, Object?>{},
  String? story,
  String? base,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
  double textScale = 1,
  DateTime? clock,
  int extraSeconds = 0,
  List<Override> overrides = const <Override>[],
}) async {
  if (_scenario != null) {
    throw StateError(
      'openScreen("$id") ran a second time in one test (the first was "${_scenario!.id}"). One scenario per test: the harness builds a '
      'fresh container per pump, so a second scenario starts from nothing. Split the test, or move inside the scenario with the navigator.',
    );
  }
  if (!kScreenRegistry.containsKey(id)) throw ArgumentError('openScreen: $id is not in the partner screen registry');
  final world = await tester.runAsync(flowWorld);
  if (!_fontsLoaded) {
    await tester.runAsync(loadAppFonts); // without the real faces every text is the square test font and overflows
    _fontsLoaded = true;
  }
  ignoreRenderErrors = false;
  late GzShotSetup setup;
  await tester.runAsync(() async {
    setup = await prepareShotWorld(mock: world!.mock, screenId: id, state: state, persona: persona, story: story);
  });
  final scenario = _scenario = _Scenario(id, setup.flush);
  addTearDown(() => _scenario = null);
  _filterRenderErrors();

  final pushed = params.isNotEmpty || base != null;
  final start = pushed ? (base ?? kFlowBase) : id;
  await GzHarness.pump(
    tester,
    app: const ProviderApp(),
    locale: locale,
    width: size.width,
    height: size.height,
    textScale: textScale,
    fixedClock: clock,
    settle: false,
    overrides: <Override>[
      ...setup.overrides,
      partnerRouterOverride(initialLocation: kScreenRegistry[start]!.path),
      ...overrides,
    ],
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(ProviderApp)));
  if (state == 'loading') {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  } else {
    if (pushed && start != id) {
      await settle(tester, flush: true);
      container.read(gzNavigatorProvider).push(id, params: params);
    }
    await settle(tester, flush: true);
    if (extraSeconds > 0) await tester.pump(Duration(seconds: extraSeconds));
    await tester.pump(const Duration(milliseconds: 100));
  }
  assert(identical(_scenario, scenario));
  return container;
}

/// Render errors of a screen that belongs to another flow are not this flow's failures: a test sets [ignoreRenderErrors] once it has left
/// the flow under test. Everything else still fails (an overflow in the screen under test is a defect).
void _filterRenderErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (ignoreRenderErrors) return;
    previous?.call(details);
  };
  _restoreErrorFilter = () {
    FlutterError.onError = previous;
    _restoreErrorFilter = () {};
  };
  addTearDown(() => _restoreErrorFilter());
}

void Function() _restoreErrorFilter = () {};

// ----------------------------------------------------------------------------------------------------------- reading the app

/// The container of the running app.
ProviderContainer container(WidgetTester tester) => ProviderScope.containerOf(tester.element(find.byType(ProviderApp)));

/// The navigator of the app (`push`, `pop`, `closeSheet`, `currentId`).
GzNavigator nav(WidgetTester tester) => container(tester).read(gzNavigatorProvider);

/// The id of the screen the app is on (the top of the navigator).
String currentId(ProviderContainer c) => c.read(gzNavigatorProvider).currentId;

/// Opens the sheet [id] over the current screen.
Future<void> openSheetOf(WidgetTester tester, ProviderContainer c, String id, [GzParams params = const <String, Object?>{}]) async {
  c.read(gzNavigatorProvider).openSheet(id, options: GzSheetOptions(params: params));
  await settle(tester, flush: true);
}

/// True when a widget with `ValueKey<String>(key)` is in the tree.
bool onScreen(String key) => find.byKey(ValueKey<String>(key)).evaluate().isNotEmpty;

/// True when some widget draws [text] (plain or rich; bidi marks ignored).
bool shows(String text) => find
    .byWidgetPredicate((w) => w is RichText && w.text.toPlainText().replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f]'), '').contains(text))
    .evaluate()
    .isNotEmpty;

/// The accessible name of the widget with [key] (what a screen reader says): the text of a control whose value is rich text.
String labelOf(WidgetTester tester, String key) => tester.getSemantics(find.byKey(ValueKey<String>(key))).label;

// ----------------------------------------------------------------------------------------------------------- waiting

/// Lets the in-process mock answer and the screen build: [wait] of fake time in 100 ms pumps with a real-async turn between (the mock
/// answers in real async). Bounded: nothing here waits for a looping animation. Pass a longer [wait] for a state that needs seconds.
///
/// With [flush] (default false: a pure, exact wait, so a timed state such as a success seal can still be asserted) the mock's pending work
/// then runs and a bounded settle of images and entry animations follows (up to 2 s more of fake time). [flush] ENDS THE 8 s UNDO WINDOW
/// of a partner action and runs scripted replies: leave it false between an action and its Undo.
Future<void> settle(WidgetTester tester, {Duration wait = const Duration(milliseconds: 1200), bool flush = false}) async {
  for (var t = 0; t < wait.inMilliseconds; t += 100) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  final run = _scenario?.flush;
  if (!flush) return;
  if (run != null) {
    await tester.runAsync(run);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await GzHarness.settle(tester, max: const Duration(seconds: 2));
}

/// Runs the mock's pending work now (gateway, scripted replies, undo windows) in real async, then pumps. WARNING: this ENDS THE 8 s UNDO
/// WINDOW of an Accept: never between Accept and Undo.
Future<void> flush(WidgetTester tester) async {
  final run = _open.flush;
  if (run != null) await tester.runAsync(run);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Ends a test cleanly: lets the mock answer what is in flight, unmounts the app and runs out the zero-length timers of Riverpod's
/// auto-dispose and of the dio adapter (a widget test fails on a pending timer). [flowTest] calls it.
Future<void> finish(WidgetTester tester) async {
  await settle(tester, wait: const Duration(milliseconds: 300), flush: true);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

// ----------------------------------------------------------------------------------------------------------- scrolling

bool _verticalScrollable(Widget w) => w is Scrollable && (w.axis == Axis.vertical);

/// Brings [target] into the middle of its scroll view with a DRAG (`ensureVisible` aligns it to the top and parks it under a pinned top bar).
/// A row that a lazy list has not built yet is found by dragging toward it. Bounded: at most 40 drags. [scrollable] picks the scroll
/// view (default: the one that holds the target, else the first vertical one).
Future<void> scrollTo(WidgetTester tester, Finder target, {Finder? scrollable}) async {
  if (target.evaluate().isNotEmpty && target.hitTestable().evaluate().isNotEmpty) return;
  if (target.evaluate().isNotEmpty && find.ancestor(of: target.first, matching: find.byWidgetPredicate(_verticalScrollable)).evaluate().isEmpty) {
    return _alongRow(tester, target);
  }
  final scrollViews = find.byWidgetPredicate(_verticalScrollable);
  Finder view = scrollable ?? scrollViews;
  if (scrollable == null && target.evaluate().isNotEmpty) {
    final holders = find.ancestor(of: target.first, matching: scrollViews);
    if (holders.evaluate().isEmpty) return; // not in a scroll view: nothing to drag
    view = holders.first;
  } else if (view.evaluate().isEmpty) {
    return;
  } else {
    view = view.first;
  }
  if (target.evaluate().isEmpty) {
    await tester.dragUntilVisible(target.first, view, const Offset(0, -240), maxIteration: 40);
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 6; i++) {
    final rect = tester.getRect(view);
    final at = tester.getCenter(target.first);
    if (at.dy > rect.top + 24 && at.dy < rect.bottom - 24 && target.hitTestable().evaluate().isNotEmpty) return;
    final delta = rect.center.dy - at.dy;
    await tester.drag(view, Offset(0, delta.clamp(-rect.height * 0.8, rect.height * 0.8)), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
  }
  await _alongRow(tester, target);
}

/// A target inside a horizontal rail (a chip row) still off screen sideways: the framework's own `ensureVisible` moves rails correctly
/// (it only fails the pinned-bar case above, which is vertical).
Future<void> _alongRow(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty || target.hitTestable().evaluate().isNotEmpty) return;
  await tester.ensureVisible(target.first);
  await tester.pump(const Duration(milliseconds: 100));
}

// ----------------------------------------------------------------------------------------------------------- tapping

/// Taps the first widget [finder] matches (scrolled into view first) and lets the world answer: the generic form of [tapKey], [tapLabel]
/// and [tapText], for `find.byType`, `find.byIcon` and the like. [flush] as in [settle].
Future<void> tap(WidgetTester tester, Finder finder, {bool flush = false, int ms = 1200}) async {
  final f = finder.first;
  await scrollTo(tester, f);
  final hit = f.hitTestable();
  await tester.tap(hit.evaluate().isEmpty ? f : hit, warnIfMissed: false);
  await settle(
    tester,
    wait: Duration(milliseconds: ms),
    flush: flush,
  );
}

/// Taps the widget with `ValueKey<String>(key)` (scrolled into view first) and lets the world answer. Exactly one widget carries a key.
Future<void> tapKey(WidgetTester tester, String key, {bool flush = false, int ms = 1200}) async {
  final f = find.byKey(ValueKey<String>(key));
  expect(f, findsOneWidget, reason: 'the control $key is on screen');
  await tap(tester, f, flush: flush, ms: ms);
}

/// Taps the control whose accessible name matches [label] (a string: exact; a RegExp: partial), the way a screen reader finds it.
Future<void> tapLabel(WidgetTester tester, Pattern label, {bool flush = false, int ms = 1200, int index = 0}) async {
  final handle = tester.ensureSemantics();
  try {
    final f = find.bySemanticsLabel(label);
    expect(f, findsWidgets, reason: 'a control named "$label" is on screen');
    await tap(tester, f.at(index), flush: flush, ms: ms);
  } finally {
    handle.dispose();
  }
}

/// Taps the control that draws [text] (rich text included; a number inside a figure island is found by containment). A chip draws its label
/// twice (a hidden copy reserves the selected width): [last] picks the visible one.
Future<void> tapText(WidgetTester tester, String text, {bool flush = false, int ms = 1200, bool last = true}) async {
  final exact = find.text(text, findRichText: true);
  final all = exact.evaluate().isNotEmpty ? exact : find.textContaining(text, findRichText: true);
  expect(all, findsWidgets, reason: 'a control "$text" is on screen');
  final visible = all.hitTestable();
  final pool = visible.evaluate().isNotEmpty ? visible : all;
  await tap(tester, last ? pool.last : pool.first, flush: flush, ms: ms);
}

/// Taps a calendar day by its spoken name (`25 November 2026`): the calendar paints its days, it has no keys.
Future<void> tapDay(WidgetTester tester, String spoken) => tapLabel(tester, RegExp(spoken), ms: 400);

/// Writes the root of the app as a PNG (`build/test-shots/<name>.png`) for a human to read: the proof of a state `pnpm fshot` cannot reach.
Future<void> shoot(WidgetTester tester, String name) async {
  await GzHarness.shoot(tester, 'build/test-shots/$name.png');
}

/// Pumps [seconds] of fake time in one-second steps (a toast, a countdown, an undo window).
Future<void> pumpSeconds(WidgetTester tester, int seconds) async {
  for (var i = 0; i < math.max(1, seconds); i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}
