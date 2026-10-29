import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show HomeShelfItem, ShelfId, VenueResult;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief, compareProvider, favouritesProvider;
import '../../../../l10n/l10n.dart';
import '../../application/discover_filters.dart';
import '../../application/discover_home.dart';
import '../../application/discover_search.dart';
import 'discover_venue_card.dart';
import 'rail.dart';

/// "Thu 14 Jan" / «14 يناير»: the short day of a shelf title or a chip (Arabic drops the weekday so the title holds one line beside the
/// chevron).
String shelfDayLabel(BuildContext context, String iso) {
  final f = context.gzFormat;
  final c = f.civil(iso);
  final dm = '${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
  return f.isArabic ? dm : '${f.weekdayName(c.weekday, NameStyle.short)} $dm';
}

/// The Brief-aware shelves under the status card, in the order of the inventory: free on the date (hidden without one), saved, featured
/// (one large card), voucher prices, this week, for you, trending, nearby. Each shelf reads its own `AsyncValue` and draws nothing while it
/// has nothing to show; every header has a chevron that opens Results with the equivalent filters.
class HomeShelves extends ConsumerWidget {
  const HomeShelves({required this.brief, required this.onSeeAll, super.key});

  final SearchBrief brief;
  final ValueChanged<ShelfId> onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final w = railItemWidth(width);
    final date = brief.date;
    final dateText = date == null ? '' : shelfDayLabel(context, date.toString());
    Widget shelf(ShelfId id, String title, Widget Function(List<HomeShelfItem> items) build, {bool lead = false}) {
      return Consumer(
        builder: (context, ref, _) {
          final items = ref.watch(homeShelfProvider((brief, id))).value ?? const <HomeShelfItem>[];
          if (items.isEmpty) return const SizedBox.shrink();
          return ShelfSection(title: title, onSeeAll: () => onSeeAll(id), child: build(items));
        },
      );
    }

    Widget cards(List<HomeShelfItem> items, String label, {bool own = false}) => Rail(
      label: label,
      width: w,
      children: [for (final i in items) DiscoverVenueCard(row: i.row, date: own ? i.date : null)],
    );

    return Column(
      key: const ValueKey<String>('discover.shelves'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (date != null) shelf(ShelfId.free, l.clientDiscoverFreeTitle(dateText), (items) => cards(items, l.clientDiscoverFreeTitle(dateText))),
        _Shortlist(brief: brief, width: w),
        shelf(
          ShelfId.featured,
          l.clientDiscoverFeaturedTitle,
          (items) => Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: DiscoverVenueCard(row: items.first.row, variant: GzVenueCardVariant.feature),
          ),
        ),
        shelf(ShelfId.voucher, l.clientDiscoverVoucherTitle, (items) => cards(items, l.clientDiscoverVoucherTitle)),
        shelf(ShelfId.week, l.clientDiscoverWeekTitle, (items) => cards(items, l.clientDiscoverWeekTitle, own: true)),
        shelf(ShelfId.recommended, l.clientDiscoverRecommendedTitle, (items) => cards(items, l.clientDiscoverRecommendedTitle)),
        shelf(ShelfId.trending, l.clientDiscoverTrendingTitle, (items) => cards(items, l.clientDiscoverTrendingTitle)),
        shelf(ShelfId.nearby, l.clientDiscoverNearbyTitle, (items) => _Nearby(items: items, width: w)),
      ],
    );
  }
}

/// "Saved": the halls the couple hearted, as compact cards, with a Compare button once there are two.
class _Shortlist extends ConsumerWidget {
  const _Shortlist({required this.brief, required this.width});

  final SearchBrief brief;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The rows are asked for at the first frame (not after the hearts arrive), so the shelf never starts a request late.
    final all = ref.watch(discoverSearchProvider(DiscoverQuery(brief: brief, filters: const DiscoverFilters(governorateIds: <String>[])))).value ?? const <VenueResult>[];
    final saved = ref.watch(favouritesProvider.select((a) => a.value?.venue.toList() ?? const <String>[]));
    if (saved.isEmpty) return const SizedBox.shrink();
    final rows = <VenueResult>[for (final id in saved) ...[for (final r in all) if (r.venue.id == id) r]].take(3).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final nav = context.gzNav;
    return ShelfSection(
      title: l.clientDiscoverShortlistTitle,
      onSeeAll: () => nav.push('CL-SAVD-01'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Rail(
            label: l.clientDiscoverShortlistTitle,
            width: width,
            children: [for (final r in rows) DiscoverVenueCard(row: r, variant: GzVenueCardVariant.compact)],
          ),
          if (rows.length > 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzButton(
                  key: const ValueKey<String>('discover.shortlist.compare'),
                  label: l.clientDiscoverShortlistCompare,
                  variant: GzButtonVariant.secondary,
                  iconStart: GzIcons.compare,
                  onPressed: () {
                    final tray = ref.read(compareProvider.notifier);
                    if (ref.read(compareProvider).length < 2) tray.setAll(rows.map((r) => r.venue.id));
                    nav.push('CL-SAVD-04', params: const <String, Object?>{'from': 'discover'});
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Nearby: a card with its drive time (a car and a figure, a cursor and a figure) under it, and "My location" asked in context.
class _Nearby extends StatefulWidget {
  const _Nearby({required this.items, required this.width});

  final List<HomeShelfItem> items;
  final double width;

  @override
  State<_Nearby> createState() => _NearbyState();
}

class _NearbyState extends State<_Nearby> {
  bool _located = false;

  Future<void> _ask() async {
    final l = context.l10n;
    final nav = context.gzNav;
    final r = await nav.openDialog(
      GzDialogSpec(title: l.clientDiscoverLocateDialogTitle, icon: GzIcons.pin, confirmLabel: l.clientDiscoverLocateAllow, cancelLabel: l.clientDiscoverLocateNotNow),
    );
    if (r == GzDialogResult.confirm && mounted) setState(() => _located = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Rail(
          label: l.clientDiscoverNearbyTitle,
          width: widget.width,
          children: [
            for (final i in widget.items)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DiscoverVenueCard(row: i.row),
                  if (i.row.distance != null) ...[const SizedBox(height: GzSpace.s2), DriveFacts(minutes: i.row.distance!.minutes, km: i.row.distance!.km)],
                ],
              ),
          ],
        ),
        if (!_located)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzChip(key: const ValueKey<String>('discover.locate'), label: l.clientDiscoverMapLocate, iconStart: GzIcons.navigate, onPressed: _ask),
            ),
          ),
      ],
    );
  }
}

/// How far a hall is, as two facts: the drive time with a car glyph and the distance with the navigate glyph (units only). Kuwait's halls sit
/// 10 to 45 minutes apart, so the drive time leads.
class DriveFacts extends StatelessWidget {
  const DriveFacts({required this.minutes, required this.km, super.key});

  final int minutes;
  final double km;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    return GzFactRow(
      label: l.clientDiscoverA11yDrive,
      children: [
        GzFactChip(icon: GzIcons.car, label: l.clientDiscoverA11yDrive, value: l.clientDiscoverMinutes(f.integer(minutes)), small: true, tone: GzFactTone.muted),
        GzFactChip(icon: GzIcons.navigate, label: l.clientDiscoverA11yDistance, value: l.clientDiscoverKm(km), small: true, tone: GzFactTone.muted),
      ],
    );
  }
}

/// Short date for chips (`Thu 14 Jan`).
String chipDate(BuildContext context, String iso) => context.gzFormat.date(iso, DateStyle.short);
