import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, DateMode, LocalDate, MoneyAmount, MoneyRange;

import 'client_scope.dart';

/// The Brief (ADR 0007 D3): what the couple is looking for. Every Brief-aware read sends `date`, `guests` and `audience` (and the venue
/// list filters by `areaIds` and `budget`). [dateMode] says how firm the date is.
@immutable
final class SearchBrief {
  const SearchBrief({this.date, this.guests, this.audience, this.areaIds = const <String>[], this.budget, this.dateMode = DateMode.undecided});

  static const SearchBrief empty = SearchBrief();

  final LocalDate? date;
  final int? guests;
  final Audience? audience;
  final List<String> areaIds;
  final MoneyRange? budget;
  final DateMode dateMode;

  /// Nothing is set (the Discover header shows "Add your date").
  bool get isEmpty => date == null && guests == null && audience == null && areaIds.isEmpty && budget == null;

  /// Date, guests and audience: enough for a Brief price.
  bool get hasQuoteInputs => date != null && guests != null && audience != null;

  /// The Brief a wedding profile implies (`storyBrief` of the prototype): the date, the women's guest count, the first audience searched
  /// (none when the answers have no audience yet).
  factory SearchBrief.fromWedding({
    required LocalDate? weddingDate,
    required DateMode dateMode,
    required int? womenGuests,
    required List<Audience> searching,
    required List<String> areaIds,
    required MoneyRange? venueBudget,
  }) =>
      SearchBrief(
        date: weddingDate,
        guests: womenGuests,
        audience: searching.isEmpty ? null : searching.first,
        areaIds: List<String>.unmodifiable(areaIds),
        budget: venueBudget,
        dateMode: dateMode,
      );

  /// Changes some fields; the `clear*` flags set a field back to null.
  SearchBrief copyWith({
    LocalDate? date,
    int? guests,
    Audience? audience,
    List<String>? areaIds,
    MoneyRange? budget,
    DateMode? dateMode,
    bool clearDate = false,
    bool clearGuests = false,
    bool clearAudience = false,
    bool clearBudget = false,
  }) =>
      SearchBrief(
        date: clearDate ? null : (date ?? this.date),
        guests: clearGuests ? null : (guests ?? this.guests),
        audience: clearAudience ? null : (audience ?? this.audience),
        areaIds: areaIds ?? this.areaIds,
        budget: clearBudget ? null : (budget ?? this.budget),
        dateMode: dateMode ?? this.dateMode,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'date': date?.toJson(),
        'guests': guests,
        'audience': audience?.value,
        'areaIds': areaIds,
        'budget': budget == null ? null : <String, Object?>{'min': budget!.min.fils, 'max': budget!.max.fils},
        'dateMode': dateMode.value,
      };

  static SearchBrief fromJson(Map<String, Object?> json) {
    final b = json['budget'];
    final audience = Audience.fromJson(json['audience']);
    final mode = DateMode.fromJson(json['dateMode']);
    return SearchBrief(
      date: json['date'] is String ? LocalDate.parse(json['date']! as String) : null,
      guests: json['guests'] as int?,
      audience: json['audience'] == null || audience == Audience.unknown ? null : audience,
      areaIds: List<String>.unmodifiable(((json['areaIds'] as List?) ?? const <Object?>[]).cast<String>()),
      budget: b is Map ? MoneyRange(min: MoneyAmount((b['min']! as num).toInt()), max: MoneyAmount((b['max']! as num).toInt())) : null,
      dateMode: mode == DateMode.unknown ? DateMode.undecided : mode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SearchBrief &&
      other.date == date &&
      other.guests == guests &&
      other.audience == audience &&
      listEquals(other.areaIds, areaIds) &&
      other.budget == budget &&
      other.dateMode == dateMode;

  @override
  int get hashCode => Object.hash(date, guests, audience, Object.hashAll(areaIds), budget, dateMode);
}

/// The Brief draft of this device. Persisted (shared_preferences key `gz.state.brief`), so it survives a restart; a guest and a signed-in
/// client share it (the wedding profile seeds it when it is empty).
final NotifierProvider<SearchBriefNotifier, SearchBrief> searchBriefProvider = NotifierProvider<SearchBriefNotifier, SearchBrief>(SearchBriefNotifier.new);

class SearchBriefNotifier extends Notifier<SearchBrief> {
  static const String _key = 'brief';

  @override
  SearchBrief build() {
    final raw = ref.read(stateBoxProvider).getString(_key);
    if (raw == null) return SearchBrief.empty;
    try {
      return SearchBrief.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return SearchBrief.empty;
    }
  }

  void _put(SearchBrief next) {
    state = next;
    ref.read(stateBoxProvider).setString(_key, next.isEmpty && next.dateMode == DateMode.undecided ? null : jsonEncode(next.toJson()));
  }

  /// Applies [change] to the current Brief (`b.copyWith(guests: 350)`), persists the result.
  void update(SearchBrief Function(SearchBrief current) change) => _put(change(state));

  /// Replaces the whole Brief.
  void set(SearchBrief brief) => _put(brief);

  /// "Clear all": back to nothing set.
  void clear() => _put(SearchBrief.empty);

  /// Fills the blanks of the Brief from [seed] (the wedding profile or the onboarding answers): a field the person already set is never
  /// overwritten, so a search edit survives and a half-finished onboarding can complete the rest later.
  void fillBlanks(SearchBrief seed) {
    final b = state;
    _put(SearchBrief(
      date: b.date ?? seed.date,
      guests: b.guests ?? seed.guests,
      audience: b.audience ?? seed.audience,
      areaIds: b.areaIds.isEmpty ? seed.areaIds : b.areaIds,
      budget: b.budget ?? seed.budget,
      dateMode: b.date == null && seed.date != null ? seed.dateMode : b.dateMode,
    ));
  }
}
