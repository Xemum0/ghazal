// What a cross-app journey adds to the journey world: the story clock of the SERVER moved from outside the app (as another phone or an operator
// with curl would). IDENTICAL in both apps (like tour.dart); the app code it needs is `journey_world.dart` only.
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show RichText;
import 'package:flutter_test/flutter_test.dart';

import 'journey_world.dart';
import 'server.dart';

extension CrossApp on Journey {
  /// Moves the story clock of the server by [by] (`POST /__mock/clock`), the way the other phone's Demo tools or curl do. The app does not
  /// hear of it until it comes back to the foreground or refetches: follow with `backgroundAndResume()`.
  Future<String> advanceServer(Duration by) async {
    final answer = await serverCall('clock', body: <String, Object?>{'advanceSeconds': by.inSeconds});
    final now = answer['now']! as String;
    debugPrint('  - the server clock moved by ${by.inHours} h to $now');
    return now;
  }

  /// The first text on screen that matches [pattern] (a request reference `GZ-2611-0147`, a count), or null: what the person reads, to print or compare.
  String? firstMatch(RegExp pattern) {
    for (final e in find.byType(RichText).evaluate()) {
      final text = (e.widget as RichText).text.toPlainText().replaceAll(RegExp(r'[\u2066-\u2069\u200e\u200f]'), '').replaceAll('\u00a0', ' ');
      final m = pattern.firstMatch(text);
      if (m != null) return m.group(0);
    }
    return null;
  }

  /// Waits (bounded, polling) until some text on screen matches [pattern] (bidi marks and non-breaking spaces ignored).
  Future<void> seeMatch(RegExp pattern, {Duration timeout = const Duration(seconds: 15), String? why}) async {
    final end = DateTime.now().add(timeout);
    while (!showsMatch(pattern)) {
      if (DateTime.now().isAfter(end)) fail('${why ?? 'expected'} $pattern not drawn within ${timeout.inSeconds}s: ${dump()}');
      await pump(const Duration(milliseconds: 200));
    }
  }
}
