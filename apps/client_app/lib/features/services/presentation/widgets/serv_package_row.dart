import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../services_glyphs.dart';
import 'serv_price_stack.dart';

/// PackageRow (web CL-SERV-03): a paper panel with a hairline; the chosen one carries the ink ring and the gold bead, opens its
/// inclusions and the others carry a checklist glyph with the count. The panel is a radio; the heart is its own target.
class ServPackageRow extends StatelessWidget {
  const ServPackageRow({
    required this.pkg,
    required this.categoryId,
    required this.chosen,
    required this.onChoose,
    required this.voucher,
    required this.favourite,
    required this.onFavourite,
    super.key,
  });

  final ProviderPackage pkg;
  final ServiceCategoryId categoryId;
  final bool chosen;
  final VoidCallback onChoose;
  final int? voucher;
  final bool favourite;
  final VoidCallback onFavourite;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final name = context.bi(pkg.name);
    final border = chosen ? c.controlChipBorderSelected : c.borderStrong;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: border, width: GzStroke.hair),
            boxShadow: chosen ? [BoxShadow(color: border, spreadRadius: GzStroke.hair)] : null,
          ),
          padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
          child: GzPressable(
            key: ValueKey<String>('services.package.${pkg.id}'),
            onPressed: onChoose,
            semanticLabel: chosen ? l.clientServicesProfilePackageChosen(name) : l.clientServicesProfilePackageChoose(name),
            scale: 1,
            borderRadius: GzRadius.smAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: GzSize.touchMin),
                    child: Row(
                      children: [
                        if (chosen) ...[const GzThreadBead(), const SizedBox(width: GzSpace.s2)],
                        Expanded(child: GzText(name, role: GzTextRole.title, color: c.textStrong)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GzSpace.s3),
                ServPriceStack(standard: pkg.price.fils, voucher: voucher, categoryId: categoryId, package: true),
                const SizedBox(height: GzSpace.s3),
                if (chosen)
                  Container(
                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < pkg.includes.length; i++) ...[
                          if (i > 0) const SizedBox(height: GzSpace.s2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(top: GzStroke.thread),
                                child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconAccent),
                              ),
                              const SizedBox(width: GzSpace.s3),
                              Expanded(child: GzText(context.bi(pkg.includes[i]), role: GzTextRole.bodyS, color: c.textPrimary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GzFactChip(icon: GzIcons.checklist, label: l.clientServicesProfileIncludes, value: context.gzFormat.integer(pkg.includes.length), tone: GzFactTone.muted, small: true),
                  ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: GzSpace.s2,
          end: GzSpace.s2,
          child: GzIconButton(
            icon: GzIcons.heart,
            iconActive: GzIcons.heartFill,
            active: favourite,
            label: favourite ? context.gzL10n.commonA11yFavouriteRemove : context.gzL10n.commonA11yFavouriteAdd,
            onPressed: onFavourite,
          ),
        ),
      ],
    );
  }
}

/// HowStrip (web CL-SERV-03): three glyph disks on one hairline thread with a one-word label each, then the info glyph.
class ServHowStrip extends StatelessWidget {
  const ServHowStrip({required this.steps, required this.title, super.key});

  /// (icon, label, title, body) per step.
  final List<(IconData, String, String, String)> steps;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget disk(IconData i, {bool sm = false, GzIconSize size = GzIconSize.md}) => Container(
      width: sm ? GzSpace.s8 : GzSize.touchMin,
      height: sm ? GzSpace.s8 : GzSize.touchMin,
      decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
      child: Center(child: GzIcon(i, size: size, color: c.textStrong)),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(top: GzSpace.s6, start: GzSpace.s2, end: GzSpace.s2),
                      child: Container(height: GzStroke.hair, color: c.borderStrong),
                    ),
                  ),
                Column(
                  children: [
                    disk(steps[i].$1),
                    const SizedBox(height: GzSpace.s1),
                    GzText(steps[i].$2, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        GzInfoButton(
          title: title,
          label: title,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(height: GzSpace.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  disk(steps[i].$1, sm: true, size: GzIconSize.sm),
                  const SizedBox(width: GzSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(steps[i].$3, role: GzTextRole.label, color: c.textStrong),
                        const SizedBox(height: GzSpace.s1),
                        GzText(steps[i].$4, role: GzTextRole.bodyS, color: c.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
