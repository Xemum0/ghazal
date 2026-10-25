// HL-VENU-04 Halls, capacity and amenities (web `HL-VENU-04.tsx`): the venue profile, the list of bookable halls (a single-hall venue lands straight
// in the editor, profile on top) and the hall editor (`widgets/hall_editor.dart`). Param `hallId` opens a hall in the editor.
// Requirements: HA-VMGT-06, HA-VMGT-07, HA-VMGT-09, HA-VMGT-12, HA-CAL-09, HA-AUTH-02 (voucher model, ADR 0033).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/venue_data.dart';
import 'widgets/hall_editor.dart';
import 'widgets/venue_bits.dart';
import 'widgets/venue_labels.dart';
import 'widgets/venue_profile.dart';

class HlVenu04Screen extends ConsumerWidget {
  const HlVenu04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final halls = ref.watch(venueHallsProvider);
    final requested = nav.params['hallId'] as String?;
    final list = halls.value?.halls;
    if (list != null) {
      final single = list.length == 1;
      final open = requested == null ? (single ? list.first : null) : list.where((h) => h.id == requested).firstOrNull;
      if (open != null) return HallEditor(key: ValueKey(open.id), hall: open, single: single);
    }
    final venueName = ref.watch(partnerVenueProvider).value?.venue.name.of(lang);
    return GzScreen(
      top: GzTopBar(title: l.hotelVenueHallsTitle, subtitle: venueName),
      child: GzAsyncView<HallList>(
        value: halls,
        loading: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(blockSize: 24),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
            ],
          ),
        ),
        onRetry: () => ref.invalidate(venueHallsProvider),
        data: (data) {
          final c = context.gz.colors;
          final f = context.gzFormat;
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const VenueProfile(),
                const SizedBox(height: GzSpace.s4),
                VenueSection(
                  title: l.hotelVenueSecHalls,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < data.halls.length; i++)
                          GzListRow(
                            flush: true,
                            last: i == data.halls.length - 1,
                            leading: Container(
                              width: GzSize.thumbSm,
                              height: GzSize.thumbSm,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.smAll),
                              child: GzIcon(GzIcons.hall, size: GzIconSize.md, color: c.iconPrimary),
                            ),
                            title: data.halls[i].name.of(lang),
                            subtitleWidget: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 22,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GzIcon(GzIcons.guests, size: GzIconSize.xs, color: c.iconSecondary),
                                      const SizedBox(width: GzSpace.s1),
                                      GzText(f.integer(data.halls[i].capacity.max), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: GzSpace.s1),
                                SizedBox(
                                  height: 22,
                                  child: GzText(
                                    f.list([for (final s in data.halls[i].sections) audienceLabel(l, s.audience)]),
                                    role: GzTextRole.caption,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            chevron: true,
                            onPressed: () => nav.push('HL-VENU-04', params: {'hallId': data.halls[i].id}),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
