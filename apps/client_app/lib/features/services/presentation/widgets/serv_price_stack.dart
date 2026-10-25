import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The unit a price of a category is quoted in: per-guest prices carry the glyph, the rest one quiet word (web `unitOf`).
String? _unitWord(AppL10n l, String categoryId) => switch (categoryId) {
  'catering' || 'buffet' => null,
  'cake' => l.clientServicesUnitCake,
  'henna' || 'bridal_makeup' => l.clientServicesUnitSession,
  'wedding_dress' => l.clientServicesUnitDress,
  'suit_rental' => l.clientServicesUnitSuit,
  'invitations' => l.clientServicesUnitCard,
  'travel' => l.clientServicesUnitBooking,
  'honeymoon' => l.clientServicesUnitPackage,
  _ => l.clientServicesUnitEvent,
};

/// PriceStack (web CL-SERV-03 package / CL-SERV-02 tile): the voucher price leads behind a ticket (a lock for a guest), the
/// standard price sits beside it struck, and a package also carries the saving.
class ServPriceStack extends StatelessWidget {
  const ServPriceStack({required this.standard, required this.voucher, required this.categoryId, required this.guest, this.package = false, this.inline = false, super.key});

  final int standard;
  final int? voucher;
  final ServiceCategoryId categoryId;
  final bool guest;
  final bool package;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final size = package ? GzPriceSize.strong : GzPriceSize.card;
    final word = _unitWord(l, categoryId.value);
    final Widget unit = word == null
        ? Semantics(label: context.gzL10n.commonUnitPerGuest, child: const GzIcon(GzIcons.perGuest, size: GzIconSize.xs, tone: GzIconTone.secondary))
        : GzText(word, role: GzTextRole.caption, color: c.textSecondary);
    Widget line(List<Widget> kids) => Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: GzSpace.s2, children: kids);
    final v = voucher;
    if (v == null || v >= standard) {
      return line([GzPrice(fils: standard, size: size), unit]);
    }
    final f = context.gzFormat;
    final saving = standard - v;
    final head = line([
      GzIcon(guest ? GzIcons.lock : GzIcons.ticket, size: GzIconSize.xs, tone: guest ? GzIconTone.secondary : GzIconTone.success),
      GzPrice(fils: v, size: size),
      unit,
    ]);
    final sub = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: GzSpace.s3,
      runSpacing: GzSpace.s1,
      children: [
        GzStruckMoney(fils: standard, role: GzTextRole.figCaption),
        if (package)
          Container(
            constraints: const BoxConstraints(minHeight: GzSize.pillMin),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
            decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
            child: Semantics(
              label: context.gzL10n.commonYouSave(f.money(saving)),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.statusSuccessText),
                  const SizedBox(width: GzSpace.s1),
                  GzText(f.money(saving), role: GzTextRole.pill, color: c.statusSuccessText, figures: true),
                ],
              ),
            ),
          ),
      ],
    );
    if (inline) {
      return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: GzSpace.s3, runSpacing: GzSpace.s1, children: [head, sub]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [head, const SizedBox(height: GzSpace.s1), sub]);
  }
}
