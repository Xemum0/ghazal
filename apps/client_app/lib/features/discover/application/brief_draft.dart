import 'package:flutter/foundation.dart';

import '../../../app/state/state.dart' show SearchBrief;

/// What the Brief sheet edits: the global Brief plus the one local choice the Brief does not store (separate ladies and men receptions,
/// each with its own guest count). Nothing is applied until the person taps the gold button; dismissing discards it.
@immutable
final class BriefDraft {
  const BriefDraft({required this.brief, required this.split, required this.women, required this.men, this.later = false});

  final SearchBrief brief;

  /// Ladies and men have their own guest counts; the Brief carries the one being searched (ADR 0007 D3).
  final bool split;
  final int women;
  final int men;

  /// The person chose "Not decided yet" (a skipped answer is a different thing: it keeps its placeholder).
  final bool later;

  BriefDraft copyWith({SearchBrief? brief, bool? split, int? women, int? men, bool? later}) =>
      BriefDraft(brief: brief ?? this.brief, split: split ?? this.split, women: women ?? this.women, men: men ?? this.men, later: later ?? this.later);

  @override
  bool operator ==(Object other) => other is BriefDraft && other.brief == brief && other.split == split && other.women == women && other.men == men && other.later == later;

  @override
  int get hashCode => Object.hash(brief, split, women, men, later);
}

/// The four pickers of the Brief sheet.
enum BriefPanel { date, area, guests, budget }
