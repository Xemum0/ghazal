import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingChannel, CompareColumn, ImageRef, LocalDate, VenueDayState;

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_segmented_control.dart';
import 'gz_compare_action_bar.dart';
import 'gz_compare_grid_rows.dart';
import 'gz_compare_header.dart';
import 'gz_compare_parts.dart';

export 'gz_compare_grid_rows.dart' show GzCompareGridContext, gzCompareLowestPrice;

/// The hall's objective badge in the grid header: Lowest price, then Closest, then Best rated (web `badgeFor`), as a glyph.
({String label, IconData icon})? _badge(BuildContext context, CompareColumn k, Set<String> lowest, Set<String> rated) {
  final l = context.gzL10n;
  if (lowest.contains(k.venue.id)) return (label: l.uiClientCompareLowest, icon: GzIcons.offer);
  if (k.best.nearest) return (label: l.uiClientCompareClosest, icon: GzIcons.navigate);
  if (rated.contains(k.venue.id)) return (label: l.uiClientCompareBestRated, icon: GzIcons.starFill);
  return null;
}

/// The footer button's kind for a column (web `actionFor`): Official, See dates when the Brief date is not free, else Get voucher.
GzCompareActionKind gzCompareActionFor(CompareColumn k, {required bool hasDate}) {
  if (k.channel == BookingChannel.externalLink) return GzCompareActionKind.official;
  if (hasDate && k.availability != null && k.availability != VenueDayState.available) return GzCompareActionKind.dates;
  return GzCompareActionKind.voucher;
}

/// CompareGrid (web `saved-compare/_components/CompareGrid.tsx`, ADR 0009 and 0034): three fluid thirds, no label column, no row labels,
/// no sideways scroll. A row is one fact in three cells and each cell carries its own glyph; the words are the rows' and cells'
/// accessible names. The header has 4:5 photos with remove and pick, the serif name (2 lines), area and an icon-only objective badge,
/// bottom-aligned across the thirds. "Differences | all" is a two-glyph segmented control with the hidden-row count beside it. The
/// bottom bar is [GzCompareBar], pinned by the screen (`GzScreen.bottom`).
class GzCompareGrid extends StatefulWidget {
  const GzCompareGrid({
    required this.columns,
    required this.origin,
    this.date,
    this.guests,
    this.areaNames = const {},
    this.strips = const {},
    this.pickedId,
    this.onPick,
    this.differencesOnly,
    this.onDifferencesOnlyChange,
    this.onRemove,
    this.onOpen,
    this.onPhoto,
    this.guest = false,
    super.key,
  });

  final List<CompareColumn> columns;

  /// Name of the reference point in "Drive from Salmiya".
  final String origin;
  final LocalDate? date;
  final int? guests;

  /// Area id to its localised name.
  final Map<String, String> areaNames;

  /// Venue id to the photograph strips of the photos row (default: the cover).
  final Map<String, List<ImageRef>> strips;
  final String? pickedId;

  /// The pick disk on each photograph; omit to hide it.
  final ValueChanged<String>? onPick;
  final bool? differencesOnly;
  final ValueChanged<bool>? onDifferencesOnlyChange;
  final ValueChanged<String>? onRemove;
  final ValueChanged<String>? onOpen;

  /// Tap a photograph strip (venue id, index into the gallery).
  final void Function(String venueId, int index)? onPhoto;

  /// Signed out: the voucher price carries the ticket and lock pair.
  final bool guest;

  @override
  State<GzCompareGrid> createState() => _GzCompareGridState();
}

class _GzCompareGridState extends State<GzCompareGrid> {
  bool _inner = true;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final cols = widget.columns;
    final diff = widget.differencesOnly ?? _inner;
    final setDiff = widget.onDifferencesOnlyChange ?? (bool v) => setState(() => _inner = v);
    final rows = gzCompareGridRows(
      context,
      GzCompareGridContext(
        columns: cols,
        date: widget.date,
        guests: widget.guests,
        origin: widget.origin,
        strips: widget.strips,
        guest: widget.guest,
        onPhoto: widget.onPhoto,
      ),
    );
    final hidden = rows.where((r) => r.same).length;
    final shown = diff ? rows.where((r) => !r.same).toList() : rows;
    final owners = [for (final k in cols) k.venue.name.of(context.gz.locale.languageCode)];

    final eligible = cols.where((k) => k.rating.average != null && k.rating.count >= 5).toList();
    final top = eligible.length < 2 ? null : eligible.map((k) => k.rating.average!).reduce((a, b) => a > b ? a : b);
    final rated = {
      for (final k in eligible)
        if (top != null && k.rating.average == top) k.venue.id,
    };
    final lowest = gzCompareLowestPrice(cols);
    final header = [
      for (final k in cols)
        () {
          final b = _badge(context, k, lowest, rated);
          return GzCompareHeaderColumn(venue: k.venue, areaName: widget.areaNames[k.venue.areaId], badge: b?.label, badgeIcon: b?.icon);
        }(),
    ];
    final hiddenText = hidden == 1 ? l.uiClientCompareHiddenOne : l.uiClientCompareHidden(f.integer(hidden));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCompareHeader(
          columns: header,
          bottomAlign: true,
          onRemove: widget.onRemove,
          onOpen: widget.onOpen,
          pickedId: widget.pickedId,
          onPick: widget.onPick,
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: GzIconSegmented<bool>(
                  options: [
                    GzIconSegmentedOption(value: true, icon: GzIcons.compare, label: l.uiClientCompareDiffOnly),
                    GzIconSegmentedOption(value: false, icon: GzIcons.list, label: l.uiClientCompareDiffAll),
                  ],
                  label: l.uiClientCompareDiffLabel,
                  value: diff,
                  onChanged: setDiff,
                ),
              ),
              if (diff && hidden > 0) ...[
                const SizedBox(width: GzSpace.s4),
                GzFactChip(icon: GzIcons.eyeOff, label: hiddenText, value: f.integer(hidden), tone: GzFactTone.muted),
              ],
            ],
          ),
        ),
        for (final r in shown)
          Semantics(
            container: true,
            label: r.label,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: GzCompareThirds(
                children: [for (var i = 0; i < r.cells.length; i++) Semantics(container: true, label: owners[i], child: r.cells[i])],
              ),
            ),
          ),
      ],
    );
  }
}

/// CompareBar (web `CompareBar`): three 48 buttons aligned to the thirds, one word each (the hall's name is the accessible name), one
/// gold primary only after a hall is picked (ADR 0009 D8). Never Request or Book. Put it in `GzScreen.bottom`.
class GzCompareBar extends StatelessWidget {
  const GzCompareBar({required this.columns, this.hasDate = false, this.pickedId, this.onAction, super.key});

  final List<CompareColumn> columns;

  /// The Brief has a date (a hall not free on it reads Dates).
  final bool hasDate;
  final String? pickedId;
  final void Function(String venueId, GzCompareActionKind kind)? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceCanvas,
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(top: GzSpace.s3, bottom: GzSpace.s3 + MediaQuery.paddingOf(context).bottom),
          child: Row(
            children: [
              for (final k in columns)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
                    child: Builder(
                      builder: (context) {
                        final kind = gzCompareActionFor(k, hasDate: hasDate);
                        final (label, icon) = switch (kind) {
                          GzCompareActionKind.official => (l.uiClientCompareBarOfficial, null),
                          GzCompareActionKind.dates => (l.uiClientCompareBarDates, GzIcons.calendar),
                          _ => (l.uiClientCompareBarVoucher, GzIcons.ticket),
                        };
                        return Semantics(
                          label: '$label, ${k.venue.name.of(lang)}',
                          excludeSemantics: true,
                          child: GzButton(
                            label: label,
                            iconStart: icon,
                            variant: pickedId == k.venue.id ? GzButtonVariant.primary : GzButtonVariant.secondary,
                            size: GzButtonSize.md,
                            compact: true,
                            tight: true,
                            ellipsize: true,
                            fullWidth: true,
                            onPressed: () => onAction?.call(k.venue.id, kind),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
