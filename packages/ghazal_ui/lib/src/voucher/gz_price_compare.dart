import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show PriceStructure;

import '../client/client_bits.dart' show GzBaselineWrap;
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_sheet.dart';

/// A flex row that starts with a glyph has no text baseline of its own: CSS takes the glyph's bottom edge. This reports that
/// baseline (a centred icon of [iconSize]) so [GzBaselineWrap] lines it up like the browser.
class GzIconBaseline extends SingleChildRenderObjectWidget {
  const GzIconBaseline({required this.iconSize, required super.child, super.key});

  final double iconSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderIconBaseline(iconSize);

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) => (renderObject as _RenderIconBaseline).iconSize = iconSize;
}

class _RenderIconBaseline extends RenderProxyBox {
  _RenderIconBaseline(this._iconSize);

  double _iconSize;

  set iconSize(double v) {
    if (v == _iconSize) return;
    _iconSize = v;
    markNeedsLayout();
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => (size.height + _iconSize) / 2;
}

/// The price size of the voucher headline.
enum GzPriceCompareSize { strong, total, display }

enum GzPriceCompareVariant { stack, inline }

/// Deprecated, no effect (ADR 0038: there is no guest mode, every client is signed in). Kept so call sites compile; remove it there.
enum GzPriceCompareAudience { member, guest }

/// PriceCompare (ADR 0033 D4, voucher-model section 6): the two prices of one quote on the same basis. The voucher price is the
/// headline in the figures voice; the standard price sits under it, quiet and struck through; then the saving and the basis. Glyphs
/// and numbers, no label words (ADR 0034): ticket = voucher price, tag = standard, trend-down = saving, then per guest or package
/// and the guest count; every glyph carries its word as the accessible name.
///
/// [variant] `stack` (package sheet, request summary) or `inline` (one line for a card or row). A [voucher] of null (or not lower than
/// [standard]) renders the standard price alone: no strike, no voucher. Every client is signed in (ADR 0038), so there is no locked
/// "after you sign up" form; [audience] and [onRegister] are deprecated no-ops kept for the call sites that still pass them.
class GzPriceCompare extends StatelessWidget {
  const GzPriceCompare({
    required this.standard,
    required this.voucher,
    required this.structure,
    this.guests,
    this.fee = 2000,
    this.showNet = true,
    this.variant = GzPriceCompareVariant.stack,
    this.audience = GzPriceCompareAudience.member,
    this.onRegister,
    this.size = GzPriceCompareSize.total,
    super.key,
  });

  /// Integer fils, standard column.
  final int standard;

  /// Integer fils, voucher column; null = no voucher price on this quote.
  final int? voucher;
  final PriceStructure structure;

  /// The guest count the quote is for (shown as the guests glyph and a figure).
  final int? guests;

  /// The voucher fee in fils (default KD 2.000): the net saving sentence behind the info glyph names it.
  final int fee;
  final bool showNet;
  final GzPriceCompareVariant variant;

  /// Deprecated, no effect (ADR 0038).
  final GzPriceCompareAudience audience;

  /// Deprecated, no effect (ADR 0038).
  final VoidCallback? onRegister;
  final GzPriceCompareSize size;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final has = voucher != null && voucher! < standard;
    final savings = has ? standard - voucher! : 0;
    final perPerson = structure == PriceStructure.perPerson;
    final basisLabel = perPerson ? l.commonUnitPerGuest : l.uiVoucherPricePackage;
    Widget basis({bool baseline = false}) {
      final row = GzFactRow(
        label: basisLabel,
        children: [
          GzFactChip(icon: perPerson ? GzIcons.perGuest : GzIcons.package, label: basisLabel, small: true, tone: GzFactTone.muted),
          if (guests != null && guests! > 0)
            GzFactChip(icon: GzIcons.usersThree, label: l.uiSharedGuests, value: f.integer(guests!), small: true, tone: GzFactTone.muted),
        ],
      );
      return baseline ? GzIconBaseline(iconSize: GzIconSize.xs.dp, child: row) : row;
    }

    final priceSize = switch (size) {
      GzPriceCompareSize.strong => GzPriceSize.strong,
      GzPriceCompareSize.total => GzPriceSize.total,
      GzPriceCompareSize.display => GzPriceSize.display,
    };

    if (!has) {
      return GzBaselineWrap(
        spacing: GzSpace.s2,
        children: [GzPrice(fils: standard, size: size == GzPriceCompareSize.display ? GzPriceSize.display : GzPriceSize.total), basis(baseline: true)],
      );
    }

    final saving = f.money(savings, const MoneyOptions(mode: MoneyMode.browse));
    final savingChip = Semantics(
      label: l.commonYouSave(saving),
      excludeSemantics: true,
      // The chip's first flex item is the trend glyph: its web baseline is the glyph's bottom edge.
      child: GzGlyphBaseline(
        glyphSize: GzSize.iconXs,
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
                GzMoney(fils: savings, inline: true, amountRole: GzTextRole.figLabel, amountColor: c.statusSuccessText),
              ],
            ),
          ),
        ),
        ),
      ),
    );

    if (variant == GzPriceCompareVariant.inline) {
      return GzBaselineWrap(
        spacing: GzSpace.s2,
        runSpacing: GzSpace.s1,
        children: [
          GzPrice(fils: voucher!, size: GzPriceSize.strong),
          Semantics(
            label: l.commonStandardPrice,
            // The web wraps the figure in a block span (`.gz-pcmp__strike`): its line box holds the page strut around the inline figure.
            child: GzInlineStrut(role: GzTextRole.body, child: GzStruckMoney(fils: standard, role: GzTextRole.figCaption)),
          ),
          savingChip,
          basis(baseline: true),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: l.commonVoucherPrice,
              excludeSemantics: true,
              child: GzIcon(GzIcons.ticket, size: GzIconSize.sm, color: c.iconSuccess),
            ),
            GzPrice(fils: voucher!, size: priceSize),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: l.commonStandardPrice,
              excludeSemantics: true,
              child: GzIconBaseline(iconSize: GzIconSize.xs.dp, child: GzIcon(GzIcons.offer, size: GzIconSize.xs, color: c.iconSecondary)),
            ),
            GzInlineStrut(role: GzTextRole.body, child: GzStruckMoney(fils: standard)),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Row(
          children: [
            Semantics(
              label: l.commonYouSave(saving),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.iconSuccess, mirror: false),
                  const SizedBox(width: GzSpace.s2),
                  GzMoney(
                    fils: savings,
                    inline: true,
                    amountRole: GzTextRole.figBodyS,
                    amountColor: c.textSuccess,
                  ),
                ],
              ),
            ),
            if (showNet && savings > fee) ...[
              const SizedBox(width: GzSpace.s2),
              GzIconButton(
                icon: GzIcons.info,
                iconSize: GzIconSize.sm,
                label: l.uiVoucherPriceNetTitle,
                onPressed: () => _showNet(context, savings),
              ),
            ],
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        Align(alignment: AlignmentDirectional.centerStart, child: basis()),
      ],
    );
  }

  void _showNet(BuildContext context, int savings) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    const browse = MoneyOptions(mode: MoneyMode.browse);
    showGzSheet<void>(
      context,
      title: l.uiVoucherPriceNetTitle,
      footer: Builder(
        builder: (sheet) => GzButton(label: l.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.of(sheet).pop()),
      ),
      builder: (sheet) => GzText(l.uiVoucherPriceNet(f.money(savings - fee, browse), f.money(fee, browse))),
    );
  }
}
