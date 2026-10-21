import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingChannel, CompareColumn, ImageRef, LocalDate, VenueDayState;

import '../foundation.dart';
import 'gz_compare_action_bar.dart';
import 'gz_compare_header.dart';
import 'gz_compare_parts.dart';
import 'gz_compare_rows.dart';

/// CompareTable (web `CompareTable`, CL-SAVD compare, ADR 0009 D4-D9): the halls side by side in fluid thirds, built from the compare
/// parts. There is no label column and no sideways scroll (the web CSS is the spec: equal flex columns, 130 / 120 / 143 dp at 390 /
/// 360 / 430 wide); labels sit above the values, so the table is a plain column that grows with the page. Objective rows carry the
/// Best-in-row bead; the header carries one outline badge per hall (Best rated, Lowest price, Closest); "Differences only" hides the
/// rows where every hall reads the same and says how many. A hall turns gold only after it is picked.
///
/// Takes the generated `CompareColumn`s of `compareVenues` and the Brief's [date] and [guests]; names of areas arrive in [areaNames]
/// (area id to the localised name) and the reference point of "Drive from ..." in [origin]. [pinned] is the screen's job (pinned
/// slivers); the table draws the same box either way. Controlled ([differencesOnly] + [onDifferencesOnlyChange]) or uncontrolled
/// (starts on).
class GzCompareTable extends StatefulWidget {
  const GzCompareTable({
    required this.columns,
    required this.origin,
    this.date,
    this.guests,
    this.areaNames = const {},
    this.photos = const {},
    this.pickedId,
    this.differencesOnly,
    this.onDifferencesOnlyChange,
    this.compactHeader = false,
    this.onRemove,
    this.onOpen,
    this.onAction,
    this.pinned = false,
    super.key,
  });

  final List<CompareColumn> columns;

  /// Name of the reference point in "Drive from Salmiya".
  final String origin;

  /// The Brief's date and guests; with no date, price rows say "From" and availability says "Pick a date".
  final LocalDate? date;
  final int? guests;

  /// Area id to its localised name (header, under each hall's name).
  final Map<String, String> areaNames;

  /// Venue id to the photograph of the photos row (default: the venue's cover).
  final Map<String, ImageRef> photos;

  /// The hall the couple picked (turns its action gold).
  final String? pickedId;
  final bool? differencesOnly;
  final ValueChanged<bool>? onDifferencesOnlyChange;
  final bool compactHeader;
  final ValueChanged<String>? onRemove;

  /// Tap a hall's photograph or name in the header to open it.
  final ValueChanged<String>? onOpen;
  final void Function(String venueId, GzCompareActionKind kind)? onAction;
  final bool pinned;

  @override
  State<GzCompareTable> createState() => _GzCompareTableState();
}

class _GzCompareTableState extends State<GzCompareTable> {
  bool _inner = true;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final cols = widget.columns;
    final diff = widget.differencesOnly ?? _inner;
    final setDiff = widget.onDifferencesOnlyChange ?? (bool v) => setState(() => _inner = v);
    final rows = gzCompareRows(
      context,
      GzCompareContext(columns: cols, date: widget.date, guests: widget.guests, origin: widget.origin, photos: widget.photos),
    );
    final hidden = rows.where((r) => r.same).length;
    final shown = diff ? rows.where((r) => !r.same).toList() : rows;

    bool official(CompareColumn k) => k.channel == BookingChannel.externalLink;
    final topRating = cols.map((k) => k.rating.average ?? 0).fold<double>(0, (a, b) => a > b ? a : b);
    String? badge(CompareColumn k) {
      if (k.best.price) return l.uiClientCompareLowest;
      if (k.best.nearest) return l.uiClientCompareClosest;
      if (k.rating.average != null && k.rating.count >= 5 && k.rating.average == topRating) return l.uiClientCompareBestRated;
      return null;
    }

    final header = [for (final k in cols) GzCompareHeaderColumn(venue: k.venue, areaName: widget.areaNames[k.venue.areaId], badge: badge(k))];
    final actions = [
      for (final k in cols)
        () {
          final kind = official(k)
              ? GzCompareActionKind.official
              : (widget.date != null && k.availability != null && k.availability != VenueDayState.available
                    ? GzCompareActionKind.dates
                    : GzCompareActionKind.voucher);
          final label = switch (kind) {
            GzCompareActionKind.official => l.uiClientCompareOfficial,
            GzCompareActionKind.dates => l.uiClientCompareSeeDates,
            _ => l.uiClientCompareGetVoucher,
          };
          return GzCompareActionColumn(id: k.venue.id, name: k.venue.name.of(lang), kind: kind, label: label);
        }(),
    ];
    final owners = [for (final k in cols) k.venue.name.of(lang)];

    var lastGroup = '';
    final body = <Widget>[];
    for (final r in shown) {
      if (r.group != lastGroup) body.add(GzCompareBand(label: r.group));
      lastGroup = r.group;
      body.add(GzCompareRow(label: r.label, cells: r.cells, owners: owners));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCompareHeader(columns: header, compact: widget.compactHeader, onRemove: widget.onRemove, onOpen: widget.onOpen, pinned: widget.pinned),
        GzDifferencesToggle(checked: diff, onChanged: setDiff, hidden: hidden),
        ...body,
        GzCompareActionBar(columns: actions, pickedId: widget.pickedId, onAction: widget.onAction, pinned: widget.pinned),
      ],
    );
  }
}
