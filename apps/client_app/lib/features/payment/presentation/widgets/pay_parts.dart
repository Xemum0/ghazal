import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/pay_flow.dart';

/// The bound choice as one plate without a card (web `VenuePlate`): the venue
/// or provider (photograph or monogram, name), then the hall and the package,
/// the date and the guests as facts. The plate IS the binding.
class PayVenuePlate extends StatelessWidget {
  const PayVenuePlate({required this.quote, super.key});

  final PayQuote quote;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final name = quote.name.of(lang);
    final hall = quote.hallName?.of(lang);
    final cover = quote.cover;
    return Semantics(
      container: true,
      label: l.clientPaymentLabelVoucherFor,
      child: Column(
        key: const ValueKey<String>('pay.plate'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (cover != null)
                SizedBox(width: GzSize.thumbLg, height: GzSize.thumbLg, child: GzPhoto(src: gzImageRefSrc(cover), alt: cover.alt.of(lang), borderRadius: GzRadius.mdAll))
              else
                GzAvatar(name: name, size: GzAvatarSize.lg),
              const SizedBox(width: GzSpace.s4),
              Expanded(child: GzText(name, role: GzTextRole.d1, color: c.textStrong)),
            ],
          ),
          const SizedBox(height: GzSpace.s4),
          GzFactRow(
            children: [
              if (hall != null && hall.isNotEmpty) GzFactChip(icon: GzIcons.hall, label: l.clientPaymentLabelHall, value: hall, small: true),
              GzFactChip(icon: GzIcons.calendar, label: l.clientPaymentLabelDate, value: f.date(quote.eventDate.toString(), DateStyle.compact), small: true),
              if ((quote.guests ?? 0) > 0) GzFactChip(icon: GzIcons.usersThree, label: l.clientPaymentLabelGuests, value: f.integer(quote.guests!), small: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// The mm:ss countdown of the checkout's last 60 seconds (web `PayTimer`).
class PayTimer extends StatelessWidget {
  const PayTimer({required this.ms, super.key});

  final int ms;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final total = (ms / 1000).ceil().clamp(0, 60);
    final value = '${f.integer(total ~/ 60)}:${total % 60 < 10 ? '0' : ''}${f.integer(total % 60)}';
    return Semantics(
      label: context.l10n.clientPaymentTimerSr(value),
      excludeSemantics: true,
      child: GzFactChip(icon: GzIcons.timer, label: context.l10n.clientPaymentTimerSr(value), value: value, tone: GzFactTone.accent),
    );
  }
}

/// The typeset wordmark under a method glyph: Latin, left to right, never
/// translated (web `WORD`). The accessible name is the full method name.
String payMethodWord(GatewayMethod method) => switch (method) {
  GatewayMethod.knet => 'KNET',
  GatewayMethod.applePay => 'Pay',
  GatewayMethod.googlePay => 'Pay',
  GatewayMethod.card => 'VISA · MC',
  GatewayMethod.unknown => 'VISA · MC',
};

/// One gateway method as a radio tile (web `MethodTile`): the glyph and the
/// wordmark name it, the accessible name is the full method name. Selected =
/// ink border and the gold bead (gold is the choice, never a fill). After a
/// failed KNET attempt the first tile carries one quiet word, "Suggested".
/// Three tiles sit side by side in platform order.
class PayMethodTile extends StatelessWidget {
  const PayMethodTile({required this.method, required this.selected, this.suggested = false, this.disabled = false, required this.onSelect, super.key});

  final GatewayMethod method;
  final bool selected;
  final bool suggested;
  final bool disabled;
  final VoidCallback onSelect;

  String _name(BuildContext context) {
    final l = context.l10n;
    return switch (method) {
      GatewayMethod.knet => l.clientPaymentMethodKnet,
      GatewayMethod.applePay => l.clientPaymentMethodApplePay,
      GatewayMethod.googlePay => l.clientPaymentMethodGooglePay,
      GatewayMethod.card => l.clientPaymentMethodCard,
      GatewayMethod.unknown => l.clientPaymentMethodCard,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      key: ValueKey<String>('pay.method.${method.value}'),
      onPressed: disabled ? null : onSelect,
      semanticLabel: _name(context),
      borderRadius: GzRadius.mdAll,
      expand: true,
      minHeight: GzSize.rowQueue,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s5),
        decoration: BoxDecoration(
          color: disabled ? c.surfaceCanvas : c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: selected ? c.borderFocus : (disabled ? c.borderHairline : c.borderStrong), width: selected ? GzStroke.icon : GzStroke.hair),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 0,
              end: 0,
              child: ExcludeSemantics(child: GzBead(hollow: !selected)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(payMethodIcon(method), size: GzIconSize.md, color: disabled ? c.iconDisabled : c.iconPrimary, mirror: false),
                          const SizedBox(height: GzSpace.s1),
                          GzText(payMethodWord(method), role: GzTextRole.figLabel, color: disabled ? c.textDisabled : c.textStrong, softWrap: false),
                        ],
                      ),
                    ),
                  ),
                  if (suggested) ...[const SizedBox(height: GzSpace.s1), GzText(context.l10n.clientPaymentMethodSuggested, role: GzTextRole.caption, color: c.textStrong, softWrap: false)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The payment as facts (web `PayFacts`): the exact amount, the method and the
/// voucher it pays for.
class PayFacts extends StatelessWidget {
  const PayFacts({required this.quote, required this.method, super.key});

  final PayQuote quote;
  final GatewayMethod method;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = quote.name.of(context.gz.locale.languageCode);
    return Column(
      key: const ValueKey<String>('pay.facts'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzFactRow(
          label: l.clientPaymentLabelAmount,
          children: [
            GzFactChip(icon: GzIcons.coins, label: l.clientPaymentLabelAmount, valueWidget: GzPrice(fils: quote.feeFils, mode: GzMoneyMode.exact, size: GzPriceSize.strong), tone: GzFactTone.accent),
            GzFactChip(
              icon: payMethodIcon(method),
              label: l.clientPaymentLabelMethod,
              value: switch (method) {
                GatewayMethod.knet => l.clientPaymentMethodKnet,
                GatewayMethod.applePay => l.clientPaymentMethodApplePay,
                GatewayMethod.googlePay => l.clientPaymentMethodGooglePay,
                _ => l.clientPaymentMethodCardShort,
              },
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
        GzFactRow(
          label: l.clientPaymentLabelVoucherFor,
          children: [GzFactChip(icon: GzIcons.ticket, label: l.clientPaymentLabelVoucherFor, value: name, tone: GzFactTone.muted)],
        ),
      ],
    );
  }
}

/// The centred stage of an outcome (web `.pm-out` in `.pm-stage`): the panel
/// grows to fill the body between the bars and centres its content, with a
/// little more air below than above. Used with a `fixed` screen body (the
/// stage IS the scroller: it scrolls only when the content does not fit).
class PayStage extends StatelessWidget {
  const PayStage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s6, bottom: GzSpace.s16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [child]),
        ),
      ),
    ),
  );
}

/// One outcome panel (web `Outcome`): a drawing, a title of two words, the
/// facts, and the recovery text behind an info glyph.
/// The facts are centred like the title (the web centres the whole panel).
class PayOutcome extends StatelessWidget {
  const PayOutcome({required this.illustration, required this.title, this.meta, this.infoTitle, this.infoBody, this.busy = false, this.danger = false, this.size = GzIllustrationSize.hero, super.key});

  final GzIllustrationName illustration;
  final String title;
  final Widget? meta;
  final String? infoTitle;
  final String? infoBody;
  final bool busy;
  final bool danger;
  final GzIllustrationSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: title,
      child: Column(
        key: const ValueKey<String>('pay.outcome'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: ExcludeSemantics(child: GzIllustration(illustration, size: size, tone: danger ? GzIllustrationTone.danger : GzIllustrationTone.standard))),
          const SizedBox(height: GzSpace.s4),
          GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true, textAlign: TextAlign.center),
          if (busy) ...[const SizedBox(height: GzSpace.s4), const Center(child: GzActivity())],
          if (meta != null || (infoTitle != null && infoBody != null)) ...[
            const SizedBox(height: GzSpace.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ?meta,
                if (infoTitle != null && infoBody != null) ...[const SizedBox(width: GzSpace.s2), GzInfoButton(title: infoTitle!, paragraphs: [infoBody!], bleed: true)],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
