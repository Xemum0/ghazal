import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_flow_model.dart';
import '../booking_glyphs.dart';
import 'booking_fields.dart';

/// One add-on as a ruled row (64 min), spoken in glyphs (ADR 0034): the glyph of what it is in a quiet disk, its name and the price in
/// the unit it is sold in. At inline-end the choice: the whole row is the toggle for a flat extra (a ring that fills with a check), a
/// stepper for a per-hour or per-attendant extra. Anything the chosen package already includes shows a check and no price.
class BookingExtraRow extends ConsumerWidget {
  const BookingExtraRow({required this.choice, required this.onToggle, required this.onQty, super.key});

  final ExtraChoice choice;
  final VoidCallback onToggle;
  final ValueChanged<int> onQty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final extra = choice.extra;
    final perUnit = extra.pricingUnit == PricingUnit.perUnit;
    final body = <Widget>[
      Container(
        width: GzSize.avatarSm,
        height: GzSize.avatarSm,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
        child: Center(
          child: GzIcon(extraGlyph(extra.category), size: GzIconSize.md, color: c.iconPrimary),
        ),
      ),
      const SizedBox(width: GzSpace.s3),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzText(context.bi(extra.name), role: GzTextRole.title, color: c.textStrong),
            if (!choice.included) ...[
              const SizedBox(height: GzSpace.s1),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s2,
                children: [
                  GzPrice(fils: extra.price.fils, size: GzPriceSize.strong),
                  if (perUnit && extra.unitLabel != null) GzText(context.bi(extra.unitLabel!), role: GzTextRole.caption, color: c.textSecondary),
                ],
              ),
            ],
          ],
        ),
      ),
    ];
    Widget row;
    if (choice.included) {
      row = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: _Row(
            trailing: GzIcon(GzIcons.checkCircle, size: GzIconSize.md, color: c.iconSuccess, semanticLabel: l10n.clientBookingExtrasIncluded),
            children: body,
          ),
        ),
      );
    } else if (perUnit) {
      row = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: _Row(
            trailing: SizedBox(
              height: GzSize.touchMin,
              width: 2 * GzSize.touchMin + GzSize.controlLg + 2 * GzSpace.s1 + GzSpace.s4,
              child: GzStepper(
                value: choice.selected ? choice.qty : 0,
                min: 0,
                max: extra.maxQty,
                onChanged: onQty,
                valueText: (n) => '${context.bi(extra.name)} ${f.integer(n)}',
              ),
            ),
            children: body,
          ),
        ),
      );
    } else {
      row = GzPressable(
        onPressed: onToggle,
        semanticLabel: context.bi(extra.name),
        selected: choice.selected,
        minWidth: 0,
        minHeight: 0,
        scale: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: _Row(
              trailing: BookingMark(on: choice.selected),
              children: body,
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: row,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children, required this.trailing});

  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ...children,
      if (trailing != null) ...[const SizedBox(width: GzSpace.s3), trailing!],
    ],
  );
}
