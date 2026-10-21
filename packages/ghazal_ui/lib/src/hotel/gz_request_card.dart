import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, PartnerRequestRow, SlaState;

import '../brand/brand.dart';
import '../client/client_d.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../voucher/voucher_shared.dart';
import 'gz_request_card_parts.dart';
import 'hotel_bits.dart';

/// The lifecycle of a card in the queue: `new` (gold bead), `viewed`, `accepting` (Accept loading, the others held), `accepted`
/// (awaiting the client, the 24 h confirm deadline and the 8 s Undo bar), `declined` (summary and reason).
enum GzRequestCardState { newRequest, viewed, accepting, accepted, declined }

/// RequestCard: the triage card of the partner app (ADR 0008 D5, text diet ADR 0034: glyphs and figures replace captions). A pending
/// request, one decision: ONE gold Accept at thumb height, Reschedule and Decline at equal weight under it (no swipe actions).
/// Top to bottom: the 2 dp reply-window bar (ink under 50%, gold from 50%, danger from 80% or under an hour; it depletes toward the
/// inline-start); status pill, voucher chip, Urgent and the time left; the date and the hall line; the facts strip (package,
/// guests, voucher price); the guest line (monogram, name, markers, chat and call); the special requests; the check line or the
/// conflict note with Compare; the compact Booking Thread; Accept / Reschedule + Decline.
/// States: [state] new, viewed, accepting, accepted (summary + Undo), declined (summary + reason); [held] disables Accept with its
/// reason. The widget fetches nothing: [request] is a `PartnerRequestRow` and [packageName] comes from the venue's packages.
/// Web `RequestCard`.
class GzRequestCard extends StatefulWidget {
  const GzRequestCard({
    required this.request,
    this.packageName,
    this.state = GzRequestCardState.viewed,
    this.canCall,
    this.held = false,
    this.declineReason,
    this.inlineUndo = true,
    this.undoPaused = false,
    this.onOpen,
    this.onAccept,
    this.onReschedule,
    this.onDecline,
    this.onCompare,
    this.onCall,
    this.onChat,
    this.onUndo,
    this.onUndoExpire,
    super.key,
  });

  /// The booking, its halls and voucher, the SLA reading and the count of other requests on the date.
  final PartnerRequestRow request;

  /// Name of the booked package (the booking only carries its id).
  final LocalizedText? packageName;
  final GzRequestCardState state;

  /// Call shows only when the client shared the number (ADR 0003). Default: the booking's own flag.
  final bool? canCall;

  /// The date is on hold for another couple: Accept is disabled and says why.
  final bool held;

  /// Declined: the reason category the hotel gave, already worded.
  final String? declineReason;

  /// Set false where the card sits under its own Undo toast (a screen-level toast region).
  final bool inlineUndo;

  /// Holds the Undo line full (gallery specimens and tests).
  final bool undoPaused;
  final VoidCallback? onOpen;
  final VoidCallback? onAccept;
  final VoidCallback? onReschedule;
  final VoidCallback? onDecline;
  final VoidCallback? onCompare;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onUndo;
  final VoidCallback? onUndoExpire;

  @override
  State<GzRequestCard> createState() => _GzRequestCardState();
}

GzSlaState _tone(SlaState? s) => switch (s) {
  SlaState.gold => GzSlaState.gold,
  SlaState.danger => GzSlaState.danger,
  SlaState.expired => GzSlaState.expired,
  _ => GzSlaState.neutral,
};

class _GzRequestCardState extends State<GzRequestCard> {
  bool _undone = false;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final req = widget.request;
    final booking = req.booking;
    final state = widget.state;
    final section = booking.sections.isEmpty ? null : booking.sections.first;
    final hallName = section == null ? '' : req.halls.where((h) => h.id == section.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '';
    final resolved = state == GzRequestCardState.accepted || state == GzRequestCardState.declined;
    final call = widget.canCall ?? booking.contact.shared;
    final eventDay = booking.eventDate.toString();
    final urgent = f.daysUntil(eventDay) <= 14;
    final date = f.date(eventDay, DateStyle.short);
    final sla = req.sla;
    final tone = _tone(sla?.state);
    final left = sla == null ? null : gzTimeLeft(f, l, sla.minutesLeft);
    final name = booking.clientName;
    final voucher = req.voucher;

    String range = '';
    if (section != null) {
      final start = section.start.toString();
      final end = section.end.toString();
      range = gzTimeRangeText(f, eventDay, start, end);
    }
    final total = f.moneyParts(booking.totals.voucherTotal.fils);
    final pkgName = widget.packageName?.of(lang);

    final pills = Wrap(
      spacing: GzSpace.s2,
      runSpacing: GzSpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (state == GzRequestCardState.newRequest)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GzThreadBead(),
              const SizedBox(width: GzSpace.s1),
              GzText(context.gzL10n.commonLabelNew, role: GzTextRole.pill, color: c.textStrong),
            ],
          ),
        GzStatusPill(
          status: state == GzRequestCardState.accepted
              ? GzStatus.approved
              : (state == GzRequestCardState.declined ? GzStatus.declined : GzStatus.pending),
          audience: GzStatusAudience.hotel,
        ),
        if (voucher != null && !resolved) GzVoucherChip(code: voucher.code),
        if (urgent && !resolved) const GzStatusPill(status: GzStatus.urgent),
      ],
    );
    final leftColor = switch (tone) {
      GzSlaState.gold => c.textGoldInk,
      GzSlaState.danger => c.textDanger,
      _ => c.textSecondary,
    };
    final leftWidget = left == null
        ? null
        : Semantics(
            label: l.uiHotelTimeLeft(left.spoken),
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.timer, size: GzIconSize.xs, color: leftColor),
                const SizedBox(width: GzSpace.s1),
                GzText(left.visual, role: GzTextRole.caption, color: leftColor, figures: true, softWrap: false),
              ],
            ),
          );

    final head = GzPressable(
      onPressed: widget.onOpen ?? () {},
      semanticLabel: l.uiHotelCardOpen(date),
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: GzSize.touchMin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s2,
            children: [pills, if (!resolved && leftWidget != null) leftWidget],
          ),
          const SizedBox(height: GzSpace.s2),
          gzRcPinLine(context, GzTextRole.uiXl, GzText(date, role: GzTextRole.uiXl, color: resolved ? c.textPrimary : c.textStrong, figures: true)),
          const SizedBox(height: GzSpace.s2),
          Text(
            hallName,
            style: gz
                .text(GzTextRole.bodyS)
                .copyWith(color: c.textStrong, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
          ),
          if (section != null) ...[
            const SizedBox(height: GzSpace.s2),
            Wrap(
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s1,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                gzRcChip(context, GzFactChip(icon: GzIcons.clock, label: l.uiHotelCardHours, value: range)),
                gzRcChip(context, GzFactChip(icon: gzRcAudienceIcon(section.audience), label: gzRcAudienceWord(l, section.audience))),
              ],
            ),
          ],
        ],
      ),
    );

    final facts = Semantics(
      container: true,
      label: l.uiHotelCardPackage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Wrap(
          spacing: GzSpace.s4,
          runSpacing: GzSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (pkgName != null) gzRcChip(context, GzFactChip(icon: GzIcons.package, label: l.uiHotelCardPackage, value: pkgName)),
            gzRcChip(context, GzFactChip(icon: GzIcons.usersThree, label: l.uiSharedGuests, value: f.integer(section?.guests ?? 0))),
            gzRcChip(context, 
              GzFactChip(
                icon: GzIcons.ticket,
                label: l.uiHotelCardVoucherPrice,
                value: '${total.currency}\u00a0${total.integer}${total.fraction}',
              ),
            ),
          ],
        ),
      ),
    );

    final guest = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: GzAvatar(name: name, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
        ),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2),
              if (!resolved && (booking.verifiedPhone || booking.firstBooking))
                Wrap(
                  spacing: GzSpace.s3,
                  children: [
                    if (booking.verifiedPhone)
                      Semantics(
                        label: l.uiHotelCardVerified,
                        excludeSemantics: true,
                        child: GzIcon(GzIcons.verified, size: GzIconSize.xs, tone: GzIconTone.success),
                      ),
                    if (booking.firstBooking)
                      Semantics(
                        label: l.uiHotelCardFirstBooking,
                        excludeSemantics: true,
                        child: GzIcon(GzIcons.userPlus, size: GzIconSize.xs, tone: GzIconTone.secondary),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (!resolved) ...[
          const SizedBox(width: GzSpace.s3),
          GzIconButton(
            icon: GzIcons.chat,
            label: l.uiHotelCardChat(name),
            variant: GzIconButtonVariant.outline,
            onPressed: widget.onChat ?? () {},
          ),
          if (call) ...[
            const SizedBox(width: GzSpace.s1),
            GzIconButton(
              icon: GzIcons.phone,
              label: l.uiHotelCardCall(name),
              variant: GzIconButtonVariant.outline,
              onPressed: widget.onCall ?? () {},
            ),
          ],
        ],
      ],
    );

    final notes = booking.specialRequests;
    final children = <Widget>[
      head,
      if (!resolved) facts,
      guest,
      if (notes != null && notes.isNotEmpty && !resolved)
        Container(
          padding: const EdgeInsets.all(GzSpace.s3),
          decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.smAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: l.uiHotelCardSpecialRequests,
                excludeSemantics: true,
                child: GzIcon(GzIcons.notes, size: GzIconSize.xs, tone: GzIconTone.secondary),
              ),
              const SizedBox(height: GzSpace.s1),
              GzRcNote(notes),
            ],
          ),
        ),
      if (!resolved && widget.held)
        Semantics(
          liveRegion: true,
          label: l.uiHotelCardHeld,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSpace.s6),
            child: Row(
              children: [
                GzIcon(GzIcons.hourglass, size: GzIconSize.xs, tone: GzIconTone.accent),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(l.uiHotelCardHeld, role: GzTextRole.caption, color: c.textSecondary),
                ),
              ],
            ),
          ),
        )
      else if (!resolved && req.otherRequestsSameDate > 0)
        Semantics(
          container: true,
          liveRegion: true,
          label: '+${f.integer(req.otherRequestsSameDate)} ${l.uiHotelCardOthers(req.otherRequestsSameDate)}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: GzIcon(GzIcons.calendarDots, size: GzIconSize.xs, tone: GzIconTone.accent),
                ),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: ExcludeSemantics(
                    child: GzText(
                      '+${f.integer(req.otherRequestsSameDate)}',
                      role: GzTextRole.caption,
                      color: c.textPrimary,
                      figures: true,
                    ),
                  ),
                ),
                const SizedBox(width: GzSpace.s2),
                GzIconButton(
                  icon: GzIcons.compare,
                  label: l.uiHotelCardCompare,
                  variant: GzIconButtonVariant.outline,
                  onPressed: widget.onCompare ?? () {},
                ),
              ],
            ),
          ),
        ),
      if (!resolved) GzBookingThread(booking: booking, variant: GzBookingThreadVariant.compact),
      if (state == GzRequestCardState.accepted) ...[
        GzRcSummary(
          children: [
            GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, tone: GzIconTone.success),
            GzIcon(GzIcons.timer, size: GzIconSize.xs, tone: GzIconTone.secondary),
            Expanded(
              child: Semantics(
                label: '${l.uiHotelCardConfirmBy} ${GzBidi.strip(f.dateTime(booking.confirmBy ?? f.now().add(const Duration(hours: 24))))}',
                excludeSemantics: true,
                child: GzText(
                  f.dateTime(booking.confirmBy ?? f.now().add(const Duration(hours: 24))),
                  role: GzTextRole.bodyS,
                  color: c.textPrimary,
                  figures: true,
                ),
              ),
            ),
          ],
        ),
        if (widget.inlineUndo && !_undone)
          GzUndoBar(
            message: l.uiHotelCardUndoMessage,
            paused: widget.undoPaused,
            onUndo: () {
              setState(() => _undone = true);
              widget.onUndo?.call();
            },
            onExpire: widget.onUndoExpire,
          ),
      ],
      if (state == GzRequestCardState.declined)
        GzRcSummary(
          children: [
            GzIcon(GzIcons.close, size: GzIconSize.sm, tone: GzIconTone.danger),
            if (widget.declineReason != null)
              Expanded(
                child: GzText(widget.declineReason!, role: GzTextRole.bodyS, color: c.textPrimary),
              ),
          ],
        ),
      if (!resolved)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GzButton(
              label: l.commonActionAccept,
              size: GzButtonSize.cta,
              fullWidth: true,
              iconStart: GzIcons.check,
              loading: state == GzRequestCardState.accepting,
              reason: widget.held ? l.uiHotelCardHeldReason : null,
              onPressed: widget.held ? null : (widget.onAccept ?? () {}),
            ),
            const SizedBox(height: GzSpace.s3),
            Row(
              children: [
                Expanded(
                  child: GzButton(
                    label: l.commonActionReschedule,
                    variant: GzButtonVariant.secondary,
                    size: GzButtonSize.md,
                    onPressed: state == GzRequestCardState.accepting ? null : (widget.onReschedule ?? () {}),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(
                    label: l.commonActionDecline,
                    variant: GzButtonVariant.secondary,
                    size: GzButtonSize.md,
                    onPressed: state == GzRequestCardState.accepting ? null : (widget.onDecline ?? () {}),
                  ),
                ),
              ],
            ),
          ],
        ),
    ];

    final remaining = sla == null ? 0.0 : gzRemainingShare(sla.elapsed);
    final barColor = switch (tone) {
      GzSlaState.neutral => c.statusSlaOk,
      GzSlaState.gold => c.statusSlaWarn,
      GzSlaState.danger => c.statusSlaAlert,
      GzSlaState.expired => c.borderStrong,
    };
    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: name,
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
              if (!resolved)
                ExcludeSemantics(
                  child: Container(
                    height: GzStroke.thread,
                    color: c.markTrack,
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: remaining,
                      heightFactor: 1,
                      child: GzDrawOnce(
                        child: ColoredBox(color: barColor, child: const SizedBox.expand()),
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
