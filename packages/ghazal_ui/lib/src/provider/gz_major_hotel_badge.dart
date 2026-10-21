import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// `chip`: crown, "Major hotel" and "Fee exempt" in one 32 dp chip. `note`: the chip plus one sentence of explanation.
enum GzMajorHotelVariant { chip, note }

/// MajorHotelBadge (Partner app only): the marker of a major hotel, exempt from every listing and advertising fee (owner rule,
/// ADR 0033 D7). Clients never see it. It never says the hotel skips review: it is exempt from the fee, not from the moderator.
/// Ink chip on the quiet surface with a 1 dp separator between the two facts; no gold, it is a fact and not a verb.
class GzMajorHotelBadge extends StatelessWidget {
  const GzMajorHotelBadge({this.variant = GzMajorHotelVariant.chip, super.key});

  final GzMajorHotelVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final note = variant == GzMajorHotelVariant.note;
    final chip = DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.xsAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.iconLg),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(GzIcons.crown, size: GzIconSize.xs, color: c.textStrong),
              const SizedBox(width: GzSpace.s2),
              GzText(l.commonMajorHotel, role: GzTextRole.pill, color: c.textStrong, softWrap: false),
              const SizedBox(width: GzSpace.s2),
              Container(width: GzStroke.hair, height: GzSize.iconXs, color: c.borderStrong),
              const SizedBox(width: GzSpace.s2),
              GzText(l.uiProviderMajorHotelExemptFee, role: GzTextRole.pill, color: c.textStrong, softWrap: false),
            ],
          ),
        ),
      ),
    );
    final name = '${l.commonMajorHotel}, ${l.uiProviderMajorHotelExemptFee}';
    if (!note) return Semantics(label: name, excludeSemantics: true, child: chip);
    return Semantics(
      container: true,
      label: '$name. ${l.uiProviderMajorHotelExplain}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chip,
          const SizedBox(height: GzSpace.s2),
          GzText(l.uiProviderMajorHotelExplain, role: GzTextRole.bodyS, color: c.textSecondary),
        ],
      ),
    );
  }
}
