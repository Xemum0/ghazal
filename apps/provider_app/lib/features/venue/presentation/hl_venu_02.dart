// HL-VENU-02 Packages and extras (web `HL-VENU-02.tsx`): what the venue sells. Packages with their two prices per set of days (voucher price and
// standard price), the extras couples add, one-tap active switches, an honest pointer to the dashboard for the price grids and the door to
// time-boxed voucher prices (HL-GROW-01).
// Requirements: HA-VMGT-03, HA-VMGT-04, HA-VMGT-05, HA-VMGT-09, HA-VMGT-11, HA-VMGT-12, HA-AUTH-02 (voucher model, ADR 0033).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/venue_data.dart';
import 'widgets/extra_sheet.dart';
import 'widgets/package_rows.dart';
import 'widgets/venue_bits.dart';

enum _Tab { packages, extras }

class HlVenu02Screen extends ConsumerStatefulWidget {
  const HlVenu02Screen({super.key});

  @override
  ConsumerState<HlVenu02Screen> createState() => _HlVenu02ScreenState();
}

class _HlVenu02ScreenState extends ConsumerState<HlVenu02Screen> {
  _Tab _tab = _Tab.packages;

  void _openExtra(Extra? e) {
    final l = context.l10n;
    GzNavigatorScope.of(context).openSheetBuilder((_) => ExtraSheet(extra: e), options: GzSheetOptions(title: e == null ? l.hotelVenueExtraNewTitle : l.hotelVenueExtraEditTitle));
  }

  Future<void> _setPackage(PackageEditor e, bool active) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final name = e.package.name.of(context.gz.locale.languageCode);
    final res = await ref.read(venueActionsProvider.notifier).savePackage(e.package.id, packageInputOf(e, active: active));
    if (!mounted) return;
    toastResult(context, res);
    if (!res.isSuccess) return;
    nav.toast(
      GzToastSpec(
        message: active ? l.hotelVenueToastPkgShown(name) : l.hotelVenueToastPkgHidden(name),
        undo: !active,
        action: active ? null : GzToastAction(label: l.commonActionUndo, onPressed: () => ref.read(venueActionsProvider.notifier).savePackage(e.package.id, packageInputOf(e, active: true))),
      ),
    );
  }

  Future<void> _setExtra(Extra e, bool active) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final name = e.name.of(context.gz.locale.languageCode);
    ExtraInput body(bool a) => ExtraInput(
      category: e.category,
      name: e.name,
      description: e.description,
      pricingUnit: e.pricingUnit,
      price: e.price,
      priceMin: e.priceMin,
      priceMax: e.priceMax,
      maxQty: e.maxQty,
      includedInPackageIds: e.includedInPackageIds,
      audiences: e.audiences,
      unitLabel: e.unitLabel,
      active: a,
    );
    final res = await ref.read(venueActionsProvider.notifier).saveExtra(e.id, body(active));
    if (!mounted) return;
    toastResult(context, res);
    if (!res.isSuccess) return;
    nav.toast(
      GzToastSpec(
        message: active ? l.hotelVenueToastExtraShown(name) : l.hotelVenueToastExtraHidden(name),
        undo: !active,
        action: active ? null : GzToastAction(label: l.commonActionUndo, onPressed: () => ref.read(venueActionsProvider.notifier).saveExtra(e.id, body(true))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final value = ref.watch(venueCatalogProvider);
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(lang);
    final catalog = value.value;
    final loaded = catalog != null;
    return GzScreen(
      top: GzTopBar(title: l.hotelVenuePackagesTitle, subtitle: venueName),
      bottom: !loaded
          ? null
          : GzActionBar(
              action: GzActionBarAction(
                label: _tab == _Tab.packages ? l.hotelVenuePkgNew : l.hotelVenueExtraAdd,
                iconEnd: GzIcons.plus,
                onPressed: _tab == _Tab.packages ? () => nav.push('HL-VENU-03', params: {'packageId': 'new'}) : () => _openExtra(null),
              ),
            ),
      child: GzAsyncView<PackageCatalog>(
        value: value,
        loading: const _ListSkeleton(),
        onRetry: () => ref.invalidate(venueCatalogProvider),
        data: (cat) {
          final packages = cat.packages;
          final extras = cat.extras;
          final empty = _tab == _Tab.packages ? packages.isEmpty : extras.isEmpty;
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzSegmentedControl<_Tab>(
                  label: l.hotelVenuePackagesTabs,
                  value: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                  options: [
                    GzSegmentedOption(value: _Tab.packages, label: l.hotelVenueTabPackages(packages.length)),
                    GzSegmentedOption(value: _Tab.extras, label: l.hotelVenueTabExtras(extras.length)),
                  ],
                ),
                const SizedBox(height: GzSpace.s4),
                if (empty)
                  GzEmptyState(illustration: GzIllustrationName.emptyListings, title: _tab == _Tab.packages ? l.hotelVenuePkgEmptyTitle : l.hotelVenueExtraEmptyTitle, fill: false)
                else if (_tab == _Tab.packages)
                  for (var i = 0; i < packages.length; i++)
                    PackageRow(
                      key: ValueKey(packages[i].package.id),
                      pkg: packages[i],
                      catalog: cat,
                      last: i == packages.length - 1,
                      onOpen: () => nav.push('HL-VENU-03', params: {'packageId': packages[i].package.id}),
                      onActive: (a) => _setPackage(packages[i], a),
                    )
                else
                  for (var i = 0; i < extras.length; i++) ExtraRow(key: ValueKey(extras[i].id), extra: extras[i], last: i == extras.length - 1, onOpen: () => _openExtra(extras[i]), onActive: (a) => _setExtra(extras[i], a)),
                const SizedBox(height: GzSpace.s4),
                const DashboardNote(),
                const SizedBox(height: GzSpace.s2),
                GzListRow(flush: true, last: true, leading: const GzIcon(GzIcons.ticket, size: GzIconSize.md), title: l.hotelVenueWindowsRow, chevron: true, onPressed: () => nav.push('HL-GROW-01')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 52),
        for (var i = 0; i < 4; i++) ...const [
          SizedBox(height: GzSpace.s4),
          Padding(padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4), child: Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(blockSize: 24, inlineSize: 220))),
          Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(blockSize: 20, inlineSize: 140)),
          SizedBox(height: GzSpace.s2),
          Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(blockSize: 20, inlineSize: 180)),
        ],
      ],
    ),
  );
}
