// TriageCard (web `TriageCard.tsx`, ADR 0034): the decision-ready request card of the Pending segment. It speaks in glyphs and figures: the
// reply-window bar (2 dp, depletes toward the inline-start), the time left as `[timer] 20 h`, the voucher chip, the date as the headline with the
// hall under it, the facts of the event with the voucher price (standard struck) at the end of the same row, the guest (monogram, name, two
// marks, chat and call), the special request as authored text, then ONE gold Accept, Decline and a calendar glyph for another date.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'bk_bits.dart';

enum TriageLock { offline, readOnly }

class TriageCard extends StatelessWidget {
  const TriageCard({
    required this.request,
    this.fresh = false,
    this.lock,
    this.held = false,
    this.onOpen,
    this.onAccept,
    this.onPropose,
    this.onDecline,
    this.onCompare,
    this.onCall,
    this.onChat,
    super.key,
  });

  final PartnerRequestRow request;
  final bool fresh;
  final TriageLock? lock;
  final bool held;
  final VoidCallback? onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onPropose;
  final VoidCallback? onDecline;
  final VoidCallback? onCompare;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.l10n;
    final lang = gz.locale.languageCode;
    final b = request.booking;
    final sla = request.sla;
    final section = b.sections.isEmpty ? null : b.sections.first;
    final hall = section == null ? '' : request.halls.where((h) => h.id == section.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '';
    final urgent = f.daysUntil(b.eventDate.toString()) <= 14;
    final readOnly = lock == TriageLock.readOnly;
    final offline = lock == TriageLock.offline;
    final date = dayLine(f, b.eventDate, year: true);
    final left = sla == null ? null : durationOf(context, sla.minutesLeft, lead: true);
    final voucher = request.voucher;
    final totals = b.totals;
    final canCall = b.contact.shared && !readOnly;
    final blocked = offline || held;
    final tone = switch (sla?.state) {
      SlaState.gold => c.statusSlaWarn,
      SlaState.danger => c.statusSlaAlert,
      SlaState.expired => c.borderStrong,
      _ => c.statusSlaOk,
    };
    final leftColor = switch (sla?.state) {
      SlaState.gold => c.textGoldInk,
      SlaState.danger || SlaState.expired => c.textDanger,
      _ => c.textSecondary,
    };
    final remaining = sla == null ? 0.0 : gzRemainingShare(sla.elapsed);

    final open = GzPressable(
      onPressed: onOpen ?? () {},
      semanticLabel: l.hotelBookingsOpenRequest(date),
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.pillMin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (left != null)
                  Semantics(
                    label: l.hotelBookingsTimeLeft(left.spoken),
                    excludeSemantics: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(GzIcons.timer, size: GzIconSize.xs, color: leftColor),
                        const SizedBox(width: GzSpace.s1),
                        GzText(left.visual, role: GzTextRole.figBodyS, color: leftColor, figures: true, softWrap: false),
                      ],
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: GzSpace.s3),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: GzSpace.s2,
                    runSpacing: GzSpace.s2,
                    children: [
                      if (fresh)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const GzThreadBead(),
                            const SizedBox(width: GzSpace.s1),
                            GzText(context.gzL10n.commonLabelNew, role: GzTextRole.pill, color: c.textStrong),
                          ],
                        ),
                      if (urgent) const GzStatusPill(status: GzStatus.urgent),
                      if (voucher != null) GzVoucherChip(code: voucher.code),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          GzText(date, role: GzTextRole.uiXl, color: c.textStrong, figures: true),
          const SizedBox(height: GzSpace.s1),
          GzText(hall, role: GzTextRole.title, color: c.textStrong),
          const SizedBox(height: GzSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: BookingFacts(booking: b)),
              const SizedBox(width: GzSpace.s3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: context.gzL10n.commonVoucherPrice,
                    child: GzPrice(fils: totals.voucherTotal.fils, mode: GzMoneyMode.browse, size: GzPriceSize.strong),
                  ),
                  if (totals.standardTotal.fils > totals.voucherTotal.fils) ...[
                    const SizedBox(height: GzSpace.s1),
                    BkStruckMoney(fils: totals.standardTotal.fils, label: context.gzL10n.commonStandardPrice),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final guest = Container(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: GzAvatar(name: b.clientName, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: IntrinsicWidth(
                    child: GzUserText(b.clientName, role: GzTextRole.title, color: c.textStrong, maxLines: 2),
                  ),
                ),
                if (b.verifiedPhone) ...[
                  const SizedBox(width: GzSpace.s2),
                  Semantics(
                    label: l.hotelBookingsVerified,
                    excludeSemantics: true,
                    child: GzIcon(GzIcons.verified, size: GzIconSize.xs, tone: GzIconTone.success),
                  ),
                ],
                if (b.firstBooking) ...[
                  const SizedBox(width: GzSpace.s2),
                  Semantics(
                    label: l.hotelBookingsFirstBooking,
                    excludeSemantics: true,
                    child: GzIcon(GzIcons.sparkle, size: GzIconSize.xs, tone: GzIconTone.accent),
                  ),
                ],
              ],
            ),
          ),
          if (!readOnly) ...[
            const SizedBox(width: GzSpace.s3),
            GzIconButton(
              icon: GzIcons.chat,
              label: l.hotelBookingsMessageName(b.clientName),
              variant: GzIconButtonVariant.outline,
              onPressed: onChat ?? () {},
            ),
            if (canCall) ...[
              const SizedBox(width: GzSpace.s1),
              GzIconButton(
                icon: GzIcons.phone,
                label: l.hotelBookingsCallName(b.clientName),
                variant: GzIconButtonVariant.outline,
                onPressed: onCall ?? () {},
              ),
            ],
          ],
        ],
      ),
    );

    final notes = b.specialRequests;
    final children = <Widget>[
      open,
      guest,
      if (notes != null && notes.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(GzSpace.s3),
          decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.smAll),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: GzSpace.s1),
                child: Semantics(
                  label: l.hotelBookingsSpecialRequests,
                  excludeSemantics: true,
                  child: GzIcon(GzIcons.notes, size: GzIconSize.sm, tone: GzIconTone.accent),
                ),
              ),
              const SizedBox(width: GzSpace.s2),
              Expanded(
                child: GzUserText(notes, role: GzTextRole.bodyS, color: c.textPrimary, maxLines: 2),
              ),
            ],
          ),
        ),
      if (held)
        Semantics(
          liveRegion: true,
          container: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSpace.s6),
            child: Row(
              children: [
                GzIcon(GzIcons.lock, size: GzIconSize.xs, tone: GzIconTone.accent),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(l.hotelBookingsHeldLine, role: GzTextRole.caption, color: c.textSecondary),
                ),
              ],
            ),
          ),
        )
      else if (request.otherRequestsSameDate > 0)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GzFactChip(
                icon: GzIcons.compare,
                label: l.hotelBookingsOthersSameDate(request.otherRequestsSameDate),
                value: '+${f.integer(request.otherRequestsSameDate)}',
                tone: GzFactTone.accent,
              ),
              GzButton(label: l.hotelBookingsCompare, variant: GzButtonVariant.tertiary, onPressed: onCompare ?? () {}),
            ],
          ),
        ),
      if (!readOnly)
        SizedBox(
          height: GzSize.controlCta,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GzButton(
                  label: context.gzL10n.commonActionAccept,
                  size: GzButtonSize.cta,
                  fullWidth: true,
                  spill: true,
                  iconStart: offline ? GzIcons.offline : GzIcons.check,
                  onPressed: blocked ? null : (onAccept ?? () {}),
                ),
              ),
              const SizedBox(width: GzSpace.s2),
              BkTextButton(label: context.gzL10n.commonActionDecline, onPressed: offline ? null : (onDecline ?? () {})),
              const SizedBox(width: GzSpace.s2),
              BkSquareButton(icon: GzIcons.calendarDots, label: l.hotelBookingsProposeDate, onPressed: offline ? null : (onPropose ?? () {})),
            ],
          ),
        ),
    ];

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: b.clientName,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  height: GzStroke.thread,
                  color: c.markTrack,
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: remaining,
                    heightFactor: 1,
                    child: GzDrawOnce(
                      child: ColoredBox(color: tone, child: const SizedBox.expand()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(GzSpace.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A secondary button that is only a glyph at the CTA height (the web `Button` with an sr-only label): a 52 dp square, [label] is its name.
class BkSquareButton extends StatelessWidget {
  const BkSquareButton({required this.icon, required this.label, this.onPressed, super.key});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      scale: GzMotion.scalePress,
      minHeight: GzSize.controlCta,
      builder: (context, st) {
        final disabled = !st.enabled;
        final fg = disabled ? c.actionSecondaryLabelDisabled : c.actionSecondaryLabel;
        return Container(
          width: GzSize.controlCta,
          height: GzSize.controlCta,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: st.pressed ? c.actionSecondaryBgPressed : null,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: disabled ? c.actionSecondaryBorderDisabled : c.actionSecondaryBorder, width: GzStroke.hair),
          ),
          child: GzIcon(icon, size: GzIconSize.sm, color: fg),
        );
      },
    );
  }
}

/// A secondary button at the CTA height that hugs its word (padding 16, the web `.hbk-tri__decline`).
class BkTextButton extends StatelessWidget {
  const BkTextButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      scale: GzMotion.scalePress,
      minHeight: GzSize.controlCta,
      builder: (context, st) {
        final disabled = !st.enabled;
        return Container(
          height: GzSize.controlCta,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: st.pressed ? c.actionSecondaryBgPressed : null,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: disabled ? c.actionSecondaryBorderDisabled : c.actionSecondaryBorder, width: GzStroke.hair),
          ),
          child: Text(
            label,
            softWrap: false,
            style: gzResetLabelStyle(gz)
                .copyWith(color: disabled ? c.actionSecondaryLabelDisabled : c.actionSecondaryLabel, decoration: TextDecoration.none),
          ),
        );
      },
    );
  }
}

/// The standard price beside a voucher price: the figure is struck, the currency is not (web `StruckMoney` of the Bookings flow).
class BkStruckMoney extends StatelessWidget {
  const BkStruckMoney({required this.fils, required this.label, this.exact = false, super.key});

  final int fils;
  final String label;
  final bool exact;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final parts = context.gzFormat.moneyParts(fils, MoneyOptions(mode: exact ? MoneyMode.exact : MoneyMode.browse));
    final plain = gz.text(GzTextRole.figBodyS).copyWith(color: c.textSecondary, decoration: TextDecoration.none);
    final struck = plain.copyWith(decoration: TextDecoration.lineThrough, decorationColor: c.textSecondary, decorationThickness: 1);
    return Semantics(
      label: '$label ${GzBidi.strip(parts.text)}',
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ConstrainedBox(
          constraints: gz.isAr ? const BoxConstraints.tightFor(height: 26) : const BoxConstraints(minHeight: GzSize.iconMd),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              gzSnappedText(parts.currency, style: plain, softWrap: false),
              if (!gz.isAr) gzSnappedText(' ', style: plain),
              gzSnappedText('${parts.integer}${parts.fraction}', style: struck, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}
