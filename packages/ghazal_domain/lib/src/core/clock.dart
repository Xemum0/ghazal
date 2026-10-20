/// The only source of "now" for domain and presentation code. Nothing reads `DateTime.now()` directly, so a test, the shot harness or the
/// mock can pin time (the prototype story clock is 2026-11-12T16:00+03:00; the mock and the harness configure it, not this package).
abstract class Clock {
  /// The current instant (UTC [DateTime]).
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

/// A clock that stands still until moved. [FixedClock.parse] takes an ISO 8601 instant with offset.
final class FixedClock implements Clock {
  FixedClock(DateTime instant) : _now = instant.toUtc();

  FixedClock.parse(String iso) : _now = DateTime.parse(iso).toUtc();

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime instant) => _now = instant.toUtc();
}
