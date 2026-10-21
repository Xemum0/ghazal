import 'package:ghazal_core/ghazal_core.dart' show GzFormat;

import '../foundation.dart';

/// The window the owner fixed: 24 hours from the approval (configuration, not partner-editable).
const int gzConfirmWindowHours = 24;

/// What is left of the confirm window (the web `useConfirmLeft`): whole minutes (rounded up), the share already passed
/// (0..1, drives the thread bar, never turns red), the spoken line and the two flags.
class GzConfirmLeft {
  const GzConfirmLeft({required this.leftMin, required this.passed, required this.text, required this.ended, required this.lastHour});

  final int leftMin;
  final double passed;

  /// `2 hours and 5 minutes remaining`; empty once ended.
  final String text;
  final bool ended;
  final bool lastHour;
}

/// Pure function of the two instants (the web hook read the prototype clock; here the caller passes [now]).
GzConfirmLeft gzConfirmLeft(GzFormat f, GzL10n l, {required DateTime deadline, required DateTime now}) {
  final diffMs = deadline.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
  final leftMin = diffMs <= 0 ? 0 : (diffMs / 60000).ceil();
  const totalMin = gzConfirmWindowHours * 60;
  final passed = (1 - leftMin / totalMin).clamp(0.0, 1.0);
  final hours = leftMin ~/ 60;
  final minutes = leftMin % 60;
  final parts = <String>[
    if (hours > 0) l.commonCountHours(hours),
    if (minutes > 0 || hours == 0) l.commonCountMinutes(minutes),
  ];
  final text = leftMin <= 0 ? '' : l.commonStatusTimeLeft(f.list(parts));
  return GzConfirmLeft(leftMin: leftMin, passed: passed.toDouble(), text: text, ended: leftMin <= 0, lastHour: leftMin > 0 && leftMin <= 60);
}
