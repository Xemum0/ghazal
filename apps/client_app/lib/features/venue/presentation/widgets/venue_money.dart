import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/venue_model.dart';
import '../venue_glyphs.dart';

/// A small amount in the figures voice (a per-guest rate): currency and figure in one LTR island, the currency first in both languages.
/// [struck] strikes the figure only (web `StruckMoney`: the standard price beside a voucher price; the currency stays clean); [quiet]
/// takes the secondary ink for both parts (the struck standard price and the sibling day rate).
class QuietMoney extends StatelessWidget {
  const QuietMoney({required this.fils, this.role = GzTextRole.figBodyS, this.struck = false, this.quiet = false, super.key});

  final int fils;
  final GzTextRole role;
  final bool struck;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final ink = quiet || struck ? c.textSecondary : c.textPrimary;
    final parts = context.gzFormat.moneyParts(fils, const MoneyOptions(mode: MoneyMode.browse));
    // The web island (`gz-money`): the currency in the label voice, a 4 gap, the figure in the role; only the figure is struck.
    final currency = gz.text(GzTextRole.label).copyWith(color: c.textSecondary, decoration: TextDecoration.none);
    final amount = gz
        .text(role)
        .copyWith(color: ink, decoration: struck ? TextDecoration.lineThrough : TextDecoration.none, decorationColor: ink, decorationThickness: 1);
    return Semantics(
      label: GzBidi.strip(parts.text),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            GzChromeBaseline(
              style: currency,
              child: Text(gz.isAr ? parts.currency : parts.currency.toUpperCase(), style: currency, softWrap: false),
            ),
            const SizedBox(width: GzSpace.s1),
            GzChromeBaseline(
              style: amount,
              child: Text(parts.integer + parts.fraction, style: amount, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// A caption-size amount inside running text (the sibling day rate: web `<Figures text={money}/>` in a `gz-t-caption` span): the shared
/// formatter text, so the bidi order is the language's own; [struck] draws the line through the whole amount (web `gz-strike`).
class CaptionMoney extends StatelessWidget {
  const CaptionMoney({required this.fils, this.struck = false, super.key});

  final int fils;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final text = f.plain(f.money(fils, const MoneyOptions(mode: MoneyMode.browse)));
    return GzText.rich(
      TextSpan(
        style: struck ? TextStyle(decoration: TextDecoration.lineThrough, decorationColor: c.textSecondary, decorationThickness: 1) : null,
        children: GzFigures.spans(context, text, role: GzTextRole.caption),
      ),
      role: GzTextRole.caption,
      color: c.textSecondary,
      semanticLabel: text,
    );
  }
}

/// The "you save" mark: a down trend glyph and the figure on the success tint (never gold: a price is not a verb).
class SavingPill extends StatelessWidget {
  const SavingPill({required this.fils, super.key});

  final int fils;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final amount = f.plain(f.money(fils, const MoneyOptions(mode: MoneyMode.browse)));
    return Semantics(
      label: context.gzL10n.commonYouSave(amount),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.pillMin),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.statusSuccessBg, borderRadius: GzRadius.xsAll),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.statusSuccessText, mirror: false),
                const SizedBox(width: GzSpace.s1),
                GzText(amount, role: GzTextRole.pill, color: c.statusSuccessText, figures: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// PriceBlock (date strip, the dates sheet and the package sheet): the two prices of one quote as glyphs and figures (ADR 0034). The
/// voucher price is the headline (a ticket for a member, a lock for a guest: both see the number), the standard price sits under it
/// struck, then the saving and the (i). Without a voucher price, or when the saving does not beat the fee, one price and nothing about
/// vouchers (CA-VCH-10).
class PriceBlock extends StatelessWidget {
  const PriceBlock({required this.prices, this.guest = false, this.owned = false, this.size = GzPriceSize.hero, this.onHow, super.key});

  final QuotePrices prices;
  final bool guest;
  final bool owned;
  final GzPriceSize size;
  final VoidCallback? onHow;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final lc = context.gzL10n;
    final f = context.gzFormat;
    final sep = sepOf(f);
    final basis = l.clientVenueTotalFor(guestsText(f, prices.billedGuests));
    if (!prices.eligible) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(GzIcons.coins, size: GzIconSize.md, tone: GzIconTone.secondary, semanticLabel: '${l.clientVenueEstimateLabel}$sep$basis'),
          const SizedBox(width: GzSpace.s3),
          GzPrice(fils: prices.standard, size: size),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(
              guest ? GzIcons.lock : GzIcons.ticket,
              size: GzIconSize.md,
              tone: guest ? GzIconTone.secondary : GzIconTone.success,
              semanticLabel: '${lc.commonVoucherPrice}$sep$basis',
            ),
            const SizedBox(width: GzSpace.s3),
            GzPrice(fils: prices.voucher, size: size),
          ],
        ),
        const SizedBox(height: GzSpace.s1),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s1,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: lc.commonStandardPrice),
                const SizedBox(width: GzSpace.s2),
                QuietMoney(fils: prices.standard, struck: true),
              ],
            ),
            SavingPill(fils: prices.savings),
            if (onHow != null && !owned) GzIconButton(icon: GzIcons.info, iconSize: GzIconSize.sm, label: l.clientVenueHowTitle, onPressed: onHow),
          ],
        ),
      ],
    );
  }
}

/// The summary of the venue bars (web `ActionBar summaryLabel` = a glyph, the word only for the screen reader): the glyph on a caption
/// line over the figure. The kit bar's `summaryLabel` is a string, so the glyph rides in `summaryValue` (kit request filed).
class VenueBarPrice extends StatelessWidget {
  const VenueBarPrice({required this.glyph, required this.label, required this.fils, super.key});

  final IconData glyph;
  final String label;
  final int fils;

  @override
  Widget build(BuildContext context) {
    final st = context.gz.text(GzTextRole.caption);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: (st.fontSize ?? 0) * (st.height ?? 1),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              label: label,
              excludeSemantics: true,
              child: GzIcon(glyph, size: GzIconSize.sm, tone: GzIconTone.secondary),
            ),
          ),
        ),
        GzPrice(fils: fils, size: GzPriceSize.display),
      ],
    );
  }
}
