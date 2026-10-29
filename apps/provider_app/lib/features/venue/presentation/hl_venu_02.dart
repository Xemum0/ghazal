// HL-VENU-02 Packages (web `HL-VENU-02.tsx`): what the venue sells. Packages with their two prices per set of days (voucher price and standard
// price), one-tap active switches, an honest pointer to the dashboard for the price grids and the door to time-boxed voucher prices (HL-GROW-01).
// Extras and add-on services are not part of a venue (CA-SVC-19, ADR 0038): no Extras tab, no catalogue, no extra editor; a client adds services
// only by choosing a service provider in the Client app.
// Requirements: HA-VMGT-03, HA-VMGT-04, HA-VMGT-05, HA-VMGT-09, HA-VMGT-11, HA-VMGT-12, HA-AUTH-02, CA-SVC-19 (voucher model, ADR 0033).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/venue_data.dart';
import 'widgets/package_rows.dart';
import 'widgets/venue_bits.dart';

class HlVenu02Screen extends ConsumerStatefulWidget {
  const HlVenu02Screen({super.key});

  @override
  ConsumerState<HlVenu02Screen> createState() => _HlVenu02ScreenState();
}

class _HlVenu02ScreenState extends ConsumerState<HlVenu02Screen> {
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
                label: l.hotelVenuePkgNew,
                iconEnd: GzIcons.plus,
                onPressed: () => nav.push('HL-VENU-03', params: {'packageId': 'new'}),
              ),
            ),
      child: GzAsyncView<PackageCatalog>(
        value: value,
        loading: const _ListSkeleton(),
        onRetry: () => ref.invalidate(venueCatalogProvider),
        data: (cat) {
          final packages = cat.packages;
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (packages.isEmpty)
                  GzEmptyState(illustration: GzIllustrationName.emptyListings, title: l.hotelVenuePkgEmptyTitle, fill: false)
                else
                  for (var i = 0; i < packages.length; i++)
                    PackageRow(
                      key: ValueKey(packages[i].package.id),
                      pkg: packages[i],
                      catalog: cat,
                      last: i == packages.length - 1,
                      onOpen: () => nav.push('HL-VENU-03', params: {'packageId': packages[i].package.id}),
                      onActive: (a) => _setPackage(packages[i], a),
                    ),
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
