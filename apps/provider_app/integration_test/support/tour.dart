// Tour helpers shared by both apps (the file is identical in apps/client_app and apps/provider_app): what a person does when they simply use
// the app everywhere: switch tabs, wait for the data, scroll the long lists, open the keyboard, go back. Built on the public API of [Journey].
import 'dart:math' as math;
import 'dart:ui' show FrameTiming;

import 'package:flutter/foundation.dart' show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'journey_world.dart';

extension JourneyTour on Journey {
  /// Waits until the screen has its data (no skeleton left, bounded) and fails on an error or offline state. Returns how many empty states the
  /// screen shows, so a journey can say whether an empty screen is expected there.
  Future<int> loaded({Duration timeout = const Duration(seconds: 12)}) async {
    final end = DateTime.now().add(timeout);
    await pump(const Duration(milliseconds: 400));
    while (find.byType(GzSkeleton).evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(end)) fail('${dump()} is still on its skeleton after ${timeout.inSeconds}s');
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(GzErrorState), findsNothing, reason: 'an error state where data is expected: ${dump()}');
    expect(find.byType(GzOfflineState), findsNothing, reason: 'an offline state in the in-process mock: ${dump()}');
    return find.byType(GzEmptyState).evaluate().length;
  }

  /// Taps the tab [id] and waits for its root screen [root] and its data. Returns the empty-state count of that screen.
  Future<int> openTab(String id, String root) async {
    await tapKey('gz:tab.$id', wait: const Duration(milliseconds: 700));
    await seeScreen(root);
    return loaded();
  }

  /// The view width in logical points.
  double get width => tester.view.physicalSize.width / tester.view.devicePixelRatio;

  /// True when [a] sits nearer the inline-start edge than [b] (left in English, right in Arabic): the reading order of tabs and chips.
  bool startsBefore(Finder a, Finder b) {
    final ax = tester.getCenter(a.first).dx;
    final bx = tester.getCenter(b.first).dx;
    return isArabic ? ax > bx : ax < bx;
  }

  /// Back navigation as the person does it: on an iPhone the edge swipe from the inline-start edge (the right edge in Arabic), elsewhere the
  /// back button. Both end on the previous screen.
  Future<void> goBack({Duration wait = const Duration(milliseconds: 1000)}) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final w = width;
      final from = Offset(isArabic ? w - 3 : 3, 420);
      await tester.dragFrom(from, Offset(isArabic ? -w * 0.7 : w * 0.7, 0));
      await pump(wait);
    } else {
      await back(wait: wait);
    }
  }

  /// Dismisses the top sheet the way a thumb does: a tap on the dimmed screen above it. Fails when the sheet is still there.
  Future<void> dismissSheet() async {
    final before = find.byType(GzSheet).evaluate().length;
    expect(before, greaterThan(0), reason: 'a sheet to dismiss: ${dump()}');
    await tester.tapAt(Offset(width / 2, 36));
    await pump(const Duration(milliseconds: 1000));
    expect(find.byType(GzSheet).evaluate().length, before - 1, reason: 'the scrim tap closed the sheet: ${dump()}');
  }

  /// Opens the keyboard on the [index]th text field: on a device the real keyboard rises; on the host the view insets are set to a keyboard's
  /// height (so the screen must spend them like it does on a phone). Returns nothing; [closeKeyboard] puts it away.
  Future<void> openKeyboard(int index, {double height = 300}) async {
    await see(find.byType(EditableText));
    final field = find.byType(EditableText).at(index);
    await scrollTo(field);
    await tester.tap(field, warnIfMissed: false);
    if (onHost) {
      tester.view.viewInsets = FakeViewPadding(bottom: height * tester.view.devicePixelRatio);
    }
    await pump(const Duration(milliseconds: 800));
  }

  Future<void> closeKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (onHost) tester.view.viewInsets = FakeViewPadding.zero;
    await pump(const Duration(milliseconds: 600));
  }

  /// True when the focused text field is fully on screen above the keyboard (the screen made room for it).
  bool focusedFieldVisible() {
    final focused = FocusManager.instance.primaryFocus;
    final ctx = focused?.context;
    if (ctx == null) return false;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final insets = tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    final visibleBottom = tester.view.physicalSize.height / tester.view.devicePixelRatio - insets;
    return rect.top >= 0 && rect.bottom <= visibleBottom + 0.5;
  }

  /// Flings the first vertical list down [rounds] times and back up, in real time: the long lists of the app under a thumb. Frame timings are
  /// collected under [label] and printed (numbers only; the host has no GPU, a simulator gives the real ones).
  Future<void> flingList(String label, {int rounds = 3, Finder? list}) async {
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    try {
      final views = list ?? find.byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical);
      for (var i = 0; i < rounds; i++) {
        await tester.fling(views.first, const Offset(0, -700), 1800, warnIfMissed: false);
        await pump(const Duration(milliseconds: 900));
      }
      for (var i = 0; i < rounds; i++) {
        await tester.fling(views.first, const Offset(0, 700), 1800, warnIfMissed: false);
        await pump(const Duration(milliseconds: 900));
      }
      await pump(const Duration(milliseconds: 1500)); // the engine reports timings in batches
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(collect);
    }
    if (timings.isEmpty) {
      debugPrint('  [frames] $label: no frame timings reported (a headless host reports none)');
      return;
    }
    double ms(Duration d) => d.inMicroseconds / 1000;
    final build = timings.map((t) => ms(t.buildDuration)).toList()..sort();
    final raster = timings.map((t) => ms(t.rasterDuration)).toList()..sort();
    final over = timings.where((t) => ms(t.totalSpan) > 16.7).length;
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    double p90(List<double> v) => v[math.min(v.length - 1, (v.length * 0.9).floor())];
    debugPrint(
      '  [frames] $label: ${timings.length} frames, build avg ${avg(build).toStringAsFixed(1)} / p90 ${p90(build).toStringAsFixed(1)} / worst ${build.last.toStringAsFixed(1)} ms, '
      'raster avg ${avg(raster).toStringAsFixed(1)} / p90 ${p90(raster).toStringAsFixed(1)} / worst ${raster.last.toStringAsFixed(1)} ms, $over over 16.7 ms',
    );
  }
}
