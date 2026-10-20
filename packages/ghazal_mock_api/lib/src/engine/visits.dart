/// Visit slots: the partner's weekly windows cut into 30-minute arrival windows (voucher-model section 11.1). Port of engine/visits.ts.
library;

import 'dates.dart';
import 'json.dart';

int _toMinutes(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String _toTime(int min) => '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

/// Slot start times of a date from the rules (the last slot must end by `to`), sorted.
List<String> slotTimesOn(List<Json> rules, String date) {
  final wd = weekdayOf(date);
  final out = <String>{};
  for (final r in rules) {
    if (!r.ints('days').contains(wd)) continue;
    final len = r.integer('slotMinutes');
    for (var t = _toMinutes(r.str('from')); t + len <= _toMinutes(r.str('to')); t += len) {
      out.add(_toTime(t));
    }
  }
  return out.toList()..sort();
}

String slotEnd(String start, [int slotMinutes = 30]) => addMinutes(start, slotMinutes);

String slotStartAt(String date, String time) => atTime(date, time);
