/// The mock's controllable clock. Default: the prototype's fixed story time 2026-11-12T16:00+03:00, so countdowns match the design. It only
/// moves when the control surface says so (`setClock`, `advance`): handlers never read the system clock.
library;

import '../engine/dates.dart';

class MockClock {
  MockClock(DateTime start) : _ms = start.millisecondsSinceEpoch;

  int _ms;

  /// The current story instant as an Asia/Kuwait string (`2026-11-12T16:00:00+03:00`).
  String get now => toKuwaitInstant(_ms);

  int get millis => _ms;

  String get today => kuwaitDateOf(now);

  void set(DateTime at) => _ms = at.millisecondsSinceEpoch;

  void advance(Duration d) => _ms += d.inMilliseconds;

  /// An instant [d] from now.
  String after(Duration d) => toKuwaitInstant(_ms + d.inMilliseconds);
}
