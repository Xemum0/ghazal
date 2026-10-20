/// ADR 0008 D3: one SLA rule shared by the bar, the badge and notification escalation. Port of engine/sla.ts.
library;

import 'dates.dart';
import 'json.dart';

/// `{state, elapsed, minutesLeft, minutesWaiting}`: neutral below 50% elapsed, gold from 50%, danger from 80% or under 1 hour left; expired at 100%.
Json slaReading(String raisedAt, String dueAt, String now, {int goldPct = 50, int dangerPct = 80}) {
  final total = diffMinutes(raisedAt, dueAt);
  final waited = diffMinutes(raisedAt, now);
  final left = diffMinutes(now, dueAt);
  final elapsed = total <= 0 ? 1.0 : waited / total;
  var state = 'neutral';
  if (left <= 0) {
    state = 'expired';
  } else if (elapsed >= dangerPct / 100 || left < 60) {
    state = 'danger';
  } else if (elapsed >= goldPct / 100) {
    state = 'gold';
  }
  return {'state': state, 'elapsed': elapsed, 'minutesLeft': left, 'minutesWaiting': waited};
}
