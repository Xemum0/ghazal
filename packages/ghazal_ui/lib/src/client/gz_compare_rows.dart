import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart'
    show AmenityState, BookingChannel, CompareColumn, ImageRef, LocalDate, PhotographyPolicy, PriceStructure, VenueDayState, VenueType;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_compare_header.dart' show gzImageRefSrc;
import 'gz_compare_parts.dart';

/// One row of the compare table: its group band, its label, one cell per hall and the keys that say whether the halls differ.
class GzCompareRowDef {
  const GzCompareRowDef({required this.id, required this.group, required this.label, required this.cells, required this.keys});

  final String id;
  final String group;
  final String label;
  final List<Widget> cells;
  final List<String> keys;

  /// All halls read the same (the row "Differences only" hides).
  bool get same => keys.length > 1 && keys.every((k) => k == keys.first);
}

/// What the rows read besides the columns: the Brief's date and guests, the reference point name, and optional row photographs.
class GzCompareContext {
  const GzCompareContext({required this.columns, required this.date, required this.guests, required this.origin, this.photos = const {}});

  final List<CompareColumn> columns;

  /// The Brief's date; only its presence matters here.
  final LocalDate? date;
  final int? guests;

  /// Name of the reference point in "Drive from Salmiya".
  final String origin;

  /// Venue id to the photograph shown in the photos row (default: the venue's cover).
  final Map<String, ImageRef> photos;
}

Widget _dash(BuildContext context) => GzText('—', role: GzTextRole.bodyS, color: context.gz.colors.textDisabled);

Widget _sub(BuildContext context, String text, {GzTextRole role = GzTextRole.bodyS, bool figures = false}) =>
    GzText(text, role: role, color: context.gz.colors.textSecondary, figures: figures);

Widget _fig(BuildContext context, String text, {GzTextRole role = GzTextRole.bodyS}) =>
    GzText(text, role: role, color: context.gz.colors.textStrong, figures: true);

/// A figure-role value (`gz-t-fig-*`): its own LTR isolate on the physical left (`direction: ltr`), whatever the page direction.
Widget _ltrBlock(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(alignment: Alignment.centerLeft, child: child), // gz-rules-ok: a figure-role value is an LTR island on the physical left (web `direction: ltr`)
);

Widget _fact(BuildContext context, IconData icon, Color iconColor, String text) {
  final c = context.gz.colors;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GzIcon(icon, size: GzIconSize.xs, color: iconColor),
      const SizedBox(width: GzSpace.s1),
      Expanded(
        child: GzText(text, role: GzTextRole.bodyS, color: c.textStrong),
      ),
    ],
  );
}

/// Builds every row of the compare table for [x] (the web `rows` memo of `CompareTable`).
List<GzCompareRowDef> gzCompareRows(BuildContext context, GzCompareContext x) {
  final f = context.gzFormat;
  final l = context.gzL10n;
  final c = context.gz.colors;
  final cols = x.columns;
  final guests = x.guests;
  bool official(CompareColumn k) => k.channel == BookingChannel.externalLink;

  final maxPrice = [1, ...cols.map((k) => k.voucherPrice?.fils ?? k.price?.fils ?? 0)].reduce((a, b) => a > b ? a : b);
  final maxCap = [1, ...cols.map((k) => k.maxGuests), guests ?? 0].reduce((a, b) => a > b ? a : b);
  final eligible = cols.where((k) => k.rating.average != null && k.rating.count >= 5).toList();
  final Set<String> bestRated = () {
    if (eligible.length < 2) return <String>{};
    final top = eligible.map((k) => k.rating.average!).reduce((a, b) => a > b ? a : b);
    return {
      for (final k in eligible)
        if (k.rating.average == top) k.venue.id,
    };
  }();

  Widget cell(List<Widget> children) => GzCompareCell(children: children);
  List<Widget> all(Widget Function(CompareColumn k) fn) => [for (final k in cols) fn(k)];
  List<String> keys(String Function(CompareColumn k) fn) => [for (final k in cols) fn(k)];

  final rows = <GzCompareRowDef>[];
  void add(String id, String group, String label, List<Widget> cells, List<String> k) =>
      rows.add(GzCompareRowDef(id: id, group: group, label: label, cells: cells, keys: k));

  final gDate = l.uiClientCompareGroupDate;

  add(
    'availability',
    gDate,
    l.uiClientCompareRowAvailability,
    all((k) {
      if (official(k)) return cell([_dash(context)]);
      if (x.date == null || k.availability == null) return cell([_sub(context, l.uiClientComparePickDate)]);
      final s = switch (k.availability!) {
        VenueDayState.available => GzStatus.available,
        VenueDayState.held => GzStatus.held,
        _ => GzStatus.unavailable,
      };
      return cell([GzStatusPill(status: s, compact: true)]);
    }),
    keys((k) => '${k.availability}'),
  );

  add(
    'price',
    gDate,
    x.date != null && guests != null ? l.uiClientCompareRowPriceDate : l.uiClientCompareRowPriceFrom,
    all((k) {
      final headline = k.voucherPrice;
      if (official(k) || headline == null) {
        return cell([official(k) || k.price == null ? _dash(context) : _sub(context, l.uiClientCompareNoVoucher)]);
      }
      final price = GzPrice(fils: headline.fils, size: GzPriceSize.strong);
      return cell([
        if (k.best.price) GzBestInRow(child: price) else price,
        GzRangeBar(decorative: true, value: headline.fils, max: maxPrice, label: f.money(headline.fils)),
      ]);
    }),
    keys((k) => '${k.voucherPrice?.fils ?? '-'}'),
  );

  add(
    'standard',
    gDate,
    l.uiClientCompareRowStandard,
    all((k) {
      if (official(k) || k.price == null) return cell([_dash(context)]);
      return cell([GzMoney(fils: k.price!.fils, amountColor: c.textSecondary)]);
    }),
    keys((k) => '${k.price?.fils ?? '-'}'),
  );

  add(
    'savings',
    gDate,
    l.uiClientCompareRowSavings,
    all((k) {
      if (official(k) || k.savings == null) return cell([_dash(context)]);
      return cell([GzPrice(fils: k.savings!.fils, size: GzPriceSize.strong)]);
    }),
    keys((k) => '${k.savings?.fils ?? '-'}'),
  );

  add(
    'perGuest',
    l.uiClientCompareGroupPrice,
    l.uiClientCompareRowPerGuest,
    all((k) {
      if (official(k) || k.fromPerGuest == null) return cell([_dash(context)]);
      return cell([
        GzPrice(fils: k.fromPerGuest!.fils, size: GzPriceSize.strong),
        _sub(context, l.uiClientComparePerGuestUnit, role: GzTextRole.caption),
      ]);
    }),
    keys((k) => '${k.fromPerGuest?.fils ?? '-'}'),
  );

  add(
    'capacity',
    l.uiClientCompareGroupCapacity,
    l.uiClientCompareRowCapacity,
    all((k) {
      final upTo = _fig(context, l.uiClientCompareUpTo(f.integer(k.maxGuests)), role: GzTextRole.figBodyS);
      return cell([
        _ltrBlock(k.best.fit ? GzBestInRow(role: GzTextRole.figBodyS, child: upTo) : upTo),
        GzRangeBar(
          decorative: true,
          value: k.maxGuests,
          max: maxCap,
          mark: guests,
          markLabel: guests != null ? l.uiClientCompareYours(f.integer(guests)) : null,
          label: f.guests(k.maxGuests),
        ),
        if (guests != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzIcon(k.fits ? GzIcons.checkCircle : GzIcons.info, size: GzIconSize.xs, color: k.fits ? c.iconSuccess : c.iconSecondary),
              const SizedBox(width: GzSpace.s1),
              Expanded(
                child: _sub(
                  context,
                  k.fits ? l.uiClientCompareFits(f.integer(guests)) : l.uiClientCompareBelow(f.integer(guests)),
                  role: GzTextRole.caption,
                  figures: true,
                ),
              ),
            ],
          ),
      ]);
    }),
    keys((k) => '${k.maxGuests}|${k.fits}'),
  );

  String state(AmenityState? s) =>
      s == AmenityState.included ? l.uiClientCompareIncluded : (s == AmenityState.extra ? l.uiClientCompareExtra : l.uiClientCompareNotOffered);
  add(
    'valet',
    l.uiClientCompareGroupFacilities,
    l.uiClientCompareRowValet,
    all((k) {
      final v = k.valet;
      if (v == null) return cell([_dash(context)]);
      final icon = v == AmenityState.included ? GzIcons.check : (v == AmenityState.extra ? GzIcons.plus : GzIcons.minus);
      return cell([_fact(context, icon, v == AmenityState.included ? c.iconSuccess : c.iconSecondary, state(v))]);
    }),
    keys((k) => '${k.valet}'),
  );

  add(
    'photography',
    l.uiClientCompareGroupFacilities,
    l.uiClientCompareRowPhotography,
    all((k) {
      final p = k.photography;
      if (p == null) return cell([_dash(context)]);
      final text = p == PhotographyPolicy.femaleOnly
          ? l.uiClientCompareWomenOnly
          : (p == PhotographyPolicy.allowed ? l.uiClientCompareAllowed : l.uiClientCompareNotAllowed);
      return cell([_fact(context, GzIcons.camera, c.iconSecondary, text)]);
    }),
    keys((k) => '${k.photography}'),
  );

  add(
    'rating',
    l.uiClientCompareRating,
    l.uiClientCompareRating,
    all((k) {
      final avg = k.rating.average;
      if (avg == null) return cell([_sub(context, l.commonLabelNew)]);
      final rating = GzRating(value: avg, count: k.rating.count);
      return cell([if (bestRated.contains(k.venue.id)) GzBestInRow(child: rating) else rating]);
    }),
    keys((k) => '${k.rating.average}|${k.rating.count}'),
  );

  add(
    'distance',
    l.uiClientCompareGroupDistance,
    l.uiClientCompareRowDistance(x.origin),
    all((k) {
      final d = k.distance;
      if (d == null) return cell([_dash(context)]);
      final text = _fig(context, l.commonCountMinutes(d.minutes));
      return cell([if (k.best.nearest) GzBestInRow(child: text) else text]);
    }),
    keys((k) => '${k.distance?.minutes ?? '-'}'),
  );

  add(
    'packages',
    l.uiClientCompareGroupBooking,
    l.uiClientCompareRowPackages,
    all((k) {
      if (official(k) || k.packages.count == 0) return cell([_dash(context)]);
      final from = k.packages.from;
      return cell([
        _fig(context, l.commonCountPackages(k.packages.count)),
        if (from != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GzText(l.uiSharedFrom, role: GzTextRole.caption, color: c.textSecondary),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzPrice(fils: from.fils, size: GzPriceSize.strong),
              ),
            ],
          ),
      ]);
    }),
    keys((k) => '${k.packages.count}|${k.packages.from?.fils ?? '-'}'),
  );

  String typeName(CompareColumn k) => switch (k.venue.type) {
    VenueType.hotel => l.commonVenueTypeHotel,
    VenueType.governmental => l.commonVenueTypeGovernmental,
    _ => l.commonVenueTypePrivateHall,
  };
  add(
    'how',
    l.uiClientCompareGroupBooking,
    l.uiClientCompareRowType,
    all((k) {
      final sub = official(k)
          ? l.uiClientCompareTypeOfficial
          : (k.structures.length > 1
                ? l.uiClientCompareBoth
                : (k.structures.firstOrNull == PriceStructure.package ? l.uiClientComparePackagesWord : l.uiClientComparePerPerson));
      return cell([GzText(typeName(k), role: GzTextRole.bodyS, color: c.textStrong), _sub(context, sub, role: GzTextRole.caption)]);
    }),
    keys((k) => '${k.venue.type}|${k.structures.map((s) => s.value).join(',')}'),
  );

  add(
    'photos',
    l.uiClientComparePhotos,
    l.uiClientComparePhotos,
    all((k) {
      final shot = x.photos[k.venue.id] ?? k.venue.cover;
      if (shot == null) return cell([_dash(context)]);
      return cell([
        AspectRatio(
          aspectRatio: GzLayout.aspect4x3,
          child: ClipRRect(
            borderRadius: GzRadius.xsAll,
            child: ColoredBox(
              color: c.surfacePlaceholder,
              child: GzPhoto(src: gzImageRefSrc(shot), alt: shot.alt.of(context.gz.locale.languageCode)),
            ),
          ),
        ),
      ]);
    }),
    keys((k) => k.venue.id),
  );

  return rows;
}
