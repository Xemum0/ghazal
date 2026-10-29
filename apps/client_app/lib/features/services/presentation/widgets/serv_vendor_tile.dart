import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/services_providers.dart';
import '../services_glyphs.dart';
import 'serv_price_stack.dart';

/// A provider in the list (web `VendorTile`): an unframed plate (4:5 photograph of the work, radius 12), a heart disk over it, then the
/// wall label: the name in the compare-name face (two lines at most), the facts as glyph and figure (rating, the women's team glyph, the
/// area) and the prices pinned to the foot, so the tiles of a row line up. The whole tile is one press target; the heart sits above it.
class ServVendorTile extends ConsumerWidget {
  const ServVendorTile({required this.vendor, required this.catId, super.key});

  final ServiceProvider vendor;
  final String catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final areas = ref.watch(servicesAreasProvider).value;
    final area = areas?.areas.where((a) => a.id == vendor.areaId).firstOrNull?.name;
    final favourite = ref.watch(isFavouriteProvider((SavedType.vendor, vendor.id)));
    final rating = vendor.rating;
    final voucher = vendor.fromVoucher != null && vendor.fromVoucher!.fils < vendor.from.fils ? vendor.fromVoucher!.fils : null;
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: l.clientServicesOpenName(context.bi(vendor.name)),
        excludeSemantics: true,
        child: GzPressable(
          key: ValueKey<String>('services.vendor.${vendor.id}'),
          onPressed: () => context.gzNav.push('CL-SERV-03', params: <String, Object?>{'vendorId': vendor.id, 'categoryId': catId}),
          borderRadius: GzRadius.mdAll,
          scale: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
                  child: ClipRRect(
                    borderRadius: GzRadius.mdAll,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (vendor.portfolio.isNotEmpty)
                          GzPhoto(src: gzImageSrc(vendor.portfolio.first.file, vendor.portfolio.first.baseUrl), alt: '', fit: BoxFit.cover),
                        PositionedDirectional(
                          top: GzSpace.s1,
                          end: GzSpace.s1,
                          child: GzIconButton(
                            variant: GzIconButtonVariant.overImage,
                            icon: GzIcons.heart,
                            iconActive: GzIcons.heartFill,
                            active: favourite,
                            label: favourite ? context.gzL10n.commonA11yFavouriteRemove : context.gzL10n.commonA11yFavouriteAdd,
                            onPressed: () => _toggleFavourite(context, ref, vendor.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzText(context.bi(vendor.name), role: GzTextRole.compareName, color: c.textStrong, maxLines: 2),
                    const SizedBox(height: GzSpace.s1),
                    Semantics(
                      container: true,
                      label: context.bi(vendor.name),
                      child: Wrap(
                        spacing: GzSpace.s3,
                        runSpacing: GzSpace.s1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (rating == null)
                            GzFactChip(
                              icon: GzIcons.sparkle,
                              label: context.gzL10n.commonLabelNew,
                              value: context.gzL10n.commonLabelNew,
                              tone: GzFactTone.accent,
                            )
                          else
                            GzRating(value: rating.average, count: rating.count),
                          if (vendor.femaleTeamForLadies) GzFactChip(icon: GzIcons.sectionWomen, label: l.clientServicesListFemaleTeam),
                          if (area != null)
                            GzFactChip(icon: GzIcons.pin, label: l.clientServicesArea, value: context.bi(area), tone: GzFactTone.muted),
                        ],
                      ),
                    ),
                    const SizedBox(height: GzSpace.s1),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                      child: ServPriceStack(standard: vendor.from.fils, voucher: voucher, categoryId: vendor.categoryId),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavourite(BuildContext context, WidgetRef ref, String vendorId) async {
    final savedMsg = context.gzL10n.commonStateSaved;
    final nav = context.gzNav;
    final l10n = context.l10n;
    final on = await ref.read(favouritesProvider.notifier).toggle(SavedType.vendor, vendorId);
    nav.toast(
      GzToastSpec(
        message: on ? savedMsg : l10n.clientVenueSavedRemoved,
        icon: on ? GzIcons.heartFill : null,
        action: on ? GzToastAction(label: l10n.clientServicesSavedView, onPressed: () => nav.switchTab('saved')) : null,
      ),
    );
  }
}
