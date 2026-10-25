// The venue profile block of HL-VENU-04 (voucher-model section 7): the venue type that drives the client's search filter (Private hall or Hotel;
// a Governmental facility is managed by Ghazal and is not selectable) and the governorate and area the region filter uses. A change of type is sent
// for Ghazal to verify; governorate and area follow the address and are read-only.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/venue_data.dart';
import 'venue_bits.dart';

class VenueProfile extends ConsumerStatefulWidget {
  const VenueProfile({super.key});

  @override
  ConsumerState<VenueProfile> createState() => _VenueProfileState();
}

class _VenueProfileState extends ConsumerState<VenueProfile> {
  VenueType? _asked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final venue = ref.watch(partnerVenueProvider).value?.venue;
    final region = ref.watch(venueRegionProvider).value;
    final current = venue?.type ?? VenueType.privateHall;
    return VenueSection(
      title: l.hotelVenueSecProfile,
      children: [
        GzChipGroup<VenueType>(
          label: l.hotelVenueTypeLabel,
          value: _asked ?? current,
          onChanged: (v) {
            if (v == null || v == current || v == _asked) return;
            setState(() => _asked = v);
            GzNavigatorScope.of(context).toast(GzToastSpec(message: l.hotelVenueToastTypeSent, icon: GzIcons.checkCircle));
          },
          options: [
            GzChipOption<VenueType>(value: VenueType.privateHall, label: l.commonVenueTypePrivateHall, icon: GzIcons.hall),
            GzChipOption<VenueType>(value: VenueType.hotel, label: l.commonVenueTypeHotel, icon: GzIcons.hotel),
          ],
        ),
        if (_asked != null && _asked != current)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.clock, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s1),
                GzText(l.hotelVenueTypePending, role: GzTextRole.pill, color: c.textPrimary),
              ],
            ),
          ),
        if (region != null) FactLine('${region.governorate.of(lang)} · ${region.area.of(lang)}', icon: GzIcons.pin),
      ],
    );
  }
}
