import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart'
    show AmenityState, BookingChannel, CompareColumn, ImageRef, LocalDate, PhotographyPolicy, VenueDayState;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_compare_header.dart' show gzImageRefSrc;
import 'gz_compare_parts.dart';
import 'gz_compare_rows.dart' show GzCompareRowDef;

/// What the CompareGrid rows read besides the columns (the web `CompareGrid` props).
class GzCompareGridContext {
  const GzCompareGridContext({
    required this.columns,
    required this.date,
    required this.guests,
    required this.origin,
    this.strips = const {},
    this.guest = false,
    this.onPhoto,
  });

  final List<CompareColumn> columns;
  final LocalDate? date;
  final int? guests;
  final String origin;

  /// Venue id to the photograph strips of the photos row (default: the venue's cover).
  final Map<String, List<ImageRef>> strips;

  /// Signed out: the voucher price carries the ticket and lock pair.
  final bool guest;
  final void Function(String venueId, int index)? onPhoto;
}

/// A cell of the grid: 12 around, centred on the row's height, 4 between children, children stretched (the web
/// `.svd-row4 .gz-cmpr__cell`). A row of one dash is 48 high.
class GzCompareGridCell extends StatelessWidget {
  const GzCompareGridCell({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(GzSpace.s3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s1), children[i]],
          ],
        ),
      ),
    );
  }
}

/// Keeps a figure group on one line inside a narrow cell (never overflows under a larger text scale).
Widget _fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: child);

Widget _dash(BuildContext context) => GzText('—', role: GzTextRole.bodyS, color: context.gz.colors.textDisabled);

/// A glyph that is the whole value or a glyph with its state mark; the words are the accessible name.
Widget _glyphs(BuildContext context, String name, List<(IconData, GzIconSize, Color)> parts) => Semantics(
  label: name,
  excludeSemantics: true,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0) const SizedBox(width: GzSpace.s1),
        GzIcon(parts[i].$1, size: parts[i].$2, color: parts[i].$3),
      ],
    ],
  ),
);

/// Venues that win the price row: the lowest headline price (the voucher price, else the standard one) among the halls that can
/// be priced for the Brief date, at least two of them (web `winners().price`, ADR 0009 D6). A hall that is booked, on hold or an
/// official channel has no price to win with; the endpoint's `best.price` still counts a held hall, so the grid decides here.
Set<String> gzCompareLowestPrice(List<CompareColumn> cols) {
  final priced = [
    for (final k in cols)
      if (k.channel != BookingChannel.externalLink &&
          k.availability != VenueDayState.unavailable &&
          k.availability != VenueDayState.held &&
          k.price != null)
        k,
  ];
  if (priced.length < 2) return <String>{};
  int headline(CompareColumn k) => (k.voucherPrice ?? k.price)!.fils;
  final low = priced.map(headline).reduce((a, b) => a < b ? a : b);
  return {
    for (final k in priced)
      if (headline(k) == low) k.venue.id,
  };
}

/// Builds the rows of the CompareGrid (web `CompareGrid.tsx` `rows`): availability, price, capacity, facilities, rating, distance,
/// packages, how you book, photos. Rows with a data gap in the contract (setting, parking, bridal suite, buffet, package names) are left
/// out until the endpoint carries them.
List<GzCompareRowDef> gzCompareGridRows(BuildContext context, GzCompareGridContext x) {
  final f = context.gzFormat;
  final l = context.gzL10n;
  final c = context.gz.colors;
  final cols = x.columns;
  final guests = x.guests;
  final hasDate = x.date != null;
  bool official(CompareColumn k) => k.channel == BookingChannel.externalLink;
  bool booked(CompareColumn k) => !official(k) && k.availability == VenueDayState.unavailable;
  bool held(CompareColumn k) => !official(k) && k.availability == VenueDayState.held;

  final maxPrice = [1, ...cols.map((k) => k.price?.fils ?? 0)].reduce((a, b) => a > b ? a : b);
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

  final lowest = gzCompareLowestPrice(cols);
  Widget best(bool on, Widget node) => on ? GzBestInRow(child: node) : node;
  List<Widget> all(Widget Function(CompareColumn k) fn) => [for (final k in cols) fn(k)];
  List<String> keys(String Function(CompareColumn k) fn) => [for (final k in cols) fn(k)];
  final rows = <GzCompareRowDef>[];
  void add(String id, String label, List<Widget> cells, List<String> k, {bool always = false}) =>
      rows.add(GzCompareRowDef(id: id, group: '', label: label, cells: cells, keys: always ? [for (var i = 0; i < k.length; i++) '$i'] : k));
  Widget cell(List<Widget> kids) => GzCompareGridCell(children: kids);

  add(
    'availability',
    l.uiClientCompareRowAvailability,
    all((k) {
      if (official(k) || !hasDate || k.availability == null) return cell([_dash(context)]);
      final s = booked(k) ? GzStatus.unavailable : (held(k) ? GzStatus.held : GzStatus.available);
      return cell([GzStatusPill(status: s, label: s == GzStatus.available ? l.commonAvailabilityFree : null)]);
    }),
    keys((k) => '${official(k)}|${k.availability}'),
  );

  if (hasDate) {
    add(
      'price',
      l.uiClientCompareRowPriceDate,
      all((k) {
        final standard = k.price;
        if (official(k) || booked(k) || held(k) || standard == null) return cell([_dash(context)]);
        final voucher = k.voucherPrice;
        if (voucher == null) return cell([GzPrice(fils: standard.fils, size: GzPriceSize.strong)]);
        final save = k.savings;
        return cell([
          best(lowest.contains(k.venue.id), GzPrice(fils: voucher.fils, size: GzPriceSize.strong, was: standard.fils, wrap: true)),
          GzRangeBar(decorative: true, value: voucher.fils, max: maxPrice, label: f.money(voucher.fils)),
          if (save != null)
            Semantics(
              label: l.commonYouSave(f.money(save.fils)),
              excludeSemantics: true,
              child: Row(
                children: [
                  GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.iconSuccess, mirror: false),
                  const SizedBox(width: GzSpace.s1),
                  Flexible(child: _fit(GzPrice(fils: save.fils))),
                ],
              ),
            ),
          if (x.guest)
            _glyphs(context, l.commonLabelGuestVoucher, [
              (GzIcons.ticket, GzIconSize.xs, c.iconSecondary),
              (GzIcons.lock, GzIconSize.xs, c.iconSecondary),
            ]),
        ]);
      }),
      keys((k) => '${k.availability}|${k.price?.fils}|${k.voucherPrice?.fils}'),
      always: true,
    );
  } else {
    add(
      'priceFrom',
      l.uiClientCompareRowPriceFrom,
      all((k) {
        final standard = k.fromPerGuest;
        final rate = k.fromVoucherPerGuest ?? standard;
        if (official(k) || rate == null) return cell([_dash(context)]);
        return cell([
          GzText(l.uiSharedFrom, role: GzTextRole.caption, color: c.textSecondary),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzIcon(GzIcons.perGuest, size: GzIconSize.sm, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s1),
              Flexible(
                child: GzPrice(
                  fils: rate.fils,
                  size: GzPriceSize.strong,
                  was: k.fromVoucherPerGuest != null && standard != null ? standard.fils : null,
                ),
              ),
            ],
          ),
        ]);
      }),
      keys((k) => '${k.fromVoucherPerGuest?.fils ?? k.fromPerGuest?.fils}'),
      always: true,
    );
  }

  add(
    'capacity',
    l.uiClientCompareRowCapacity,
    all((k) {
      final chip = GzFactChip(icon: GzIcons.usersThree, label: l.uiClientCompareRowCapacity, value: f.integer(k.maxGuests));
      return cell([
        best(k.best.fit, chip),
        GzRangeBar(
          decorative: true,
          value: k.maxGuests,
          max: maxCap,
          mark: guests,
          markLabel: guests != null ? f.integer(guests) : null,
          label: f.guests(k.maxGuests),
        ),
        if (guests != null && !k.fits)
          _glyphs(context, l.uiClientCompareBelow(f.integer(guests)), [(GzIcons.warningCircle, GzIconSize.sm, c.iconSecondary)]),
      ]);
    }),
    keys((k) => '${k.maxGuests}|${k.fits}'),
    always: true,
  );

  String state(AmenityState? s) =>
      s == AmenityState.included ? l.uiClientCompareIncluded : (s == AmenityState.extra ? l.uiClientCompareExtra : l.uiClientCompareNotOffered);
  add(
    'valet',
    l.uiClientCompareRowValet,
    all((k) {
      final v = k.valet;
      if (official(k) || v == null) return cell([_dash(context)]);
      final mark = v == AmenityState.included ? GzIcons.check : (v == AmenityState.extra ? GzIcons.coins : GzIcons.minus);
      final tone = v == AmenityState.included ? c.iconSuccess : (v == AmenityState.extra ? c.iconAccent : c.iconDisabled);
      return cell([
        _glyphs(context, '${l.uiClientCompareRowValet}: ${state(v)}', [
          (GzIcons.valet, GzIconSize.sm, v == AmenityState.notOffered ? c.iconDisabled : c.iconPrimary),
          (mark, GzIconSize.xs, tone),
        ]),
      ]);
    }),
    keys((k) => '${k.valet}'),
  );

  add(
    'photography',
    l.uiClientCompareRowPhotography,
    all((k) {
      final p = k.photography;
      if (official(k) || p == null) return cell([_dash(context)]);
      final word = p == PhotographyPolicy.femaleOnly
          ? l.uiClientCompareWomenOnly
          : (p == PhotographyPolicy.allowed ? l.uiClientCompareAllowed : l.uiClientCompareNotAllowed);
      final none = p == PhotographyPolicy.none;
      return cell([
        _glyphs(context, '${l.uiClientCompareRowPhotography}: $word', [
          (GzIcons.camera, GzIconSize.sm, none ? c.iconDisabled : c.iconPrimary),
          (
            p == PhotographyPolicy.femaleOnly ? GzIcons.sectionWomen : (none ? GzIcons.minus : GzIcons.check),
            GzIconSize.xs,
            p == PhotographyPolicy.allowed ? c.iconSuccess : (none ? c.iconDisabled : c.iconSecondary),
          ),
        ]),
      ]);
    }),
    keys((k) => '${official(k)}|${k.photography}'),
  );

  add(
    'rating',
    l.uiClientCompareRating,
    all((k) {
      final avg = k.rating.average;
      if (official(k) || avg == null) return cell([_dash(context)]);
      return cell([best(bestRated.contains(k.venue.id), _fit(GzRating(value: avg, count: k.rating.count)))]);
    }),
    keys((k) => '${k.rating.average}|${k.rating.count}'),
    always: true,
  );

  add(
    'distance',
    l.uiClientCompareRowDistance(x.origin),
    all((k) {
      final d = k.distance;
      if (d == null) return cell([_dash(context)]);
      return cell([
        best(
          k.best.nearest,
          _fit(GzFactChip(icon: GzIcons.route, label: l.uiClientCompareRowDistance(x.origin), value: l.uiClientCompareDriveMinutes(d.minutes))),
        ),
      ]);
    }),
    keys((k) => '${k.distance?.minutes}'),
  );

  add(
    'packages',
    l.uiClientCompareRowPackages,
    all((k) {
      if (official(k) || k.packages.count == 0) return cell([_dash(context)]);
      return cell([GzFactChip(icon: GzIcons.package, label: l.uiClientCompareRowPackages, value: f.integer(k.packages.count))]);
    }),
    keys((k) => '${k.packages.count}'),
  );

  add(
    'how',
    l.uiClientCompareRowHow,
    all((k) {
      if (official(k)) {
        return cell([
          _glyphs(context, l.uiClientCompareTypeOfficial, [(GzIcons.bank, GzIconSize.sm, c.iconPrimary)]),
        ]);
      }
      final voucher = k.voucherPrice != null || k.packages.fromVoucher != null;
      return cell([
        voucher
            ? _glyphs(context, l.uiClientCompareHowVoucher, [(GzIcons.ticket, GzIconSize.sm, c.iconPrimary)])
            : _glyphs(context, l.uiClientCompareHowStandard, [(GzIcons.minus, GzIconSize.sm, c.iconSecondary)]),
      ]);
    }),
    keys((k) => '${official(k)}|${k.voucherPrice != null || k.packages.fromVoucher != null}'),
  );

  add(
    'photos',
    l.uiClientComparePhotos,
    all((k) {
      final shots = x.strips[k.venue.id] ?? [if (k.venue.cover != null) k.venue.cover!];
      if (shots.isEmpty) return cell([_dash(context)]);
      final lang = context.gz.locale.languageCode;
      return cell([
        for (var i = 0; i < shots.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s1),
          Semantics(
            button: x.onPhoto != null,
            label: shots[i].alt.of(lang),
            excludeSemantics: true,
            child: GzPressable(
              onPressed: x.onPhoto == null ? null : () => x.onPhoto!(k.venue.id, i + 1),
              child: AspectRatio(
                aspectRatio: GzLayout.aspect4x3,
                child: ClipRRect(
                  borderRadius: GzRadius.xsAll,
                  child: ColoredBox(
                    color: c.surfacePlaceholder,
                    child: GzPhoto(src: gzImageRefSrc(shots[i]), alt: ''),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]);
    }),
    keys((k) => k.venue.id),
    always: true,
  );

  return rows;
}
