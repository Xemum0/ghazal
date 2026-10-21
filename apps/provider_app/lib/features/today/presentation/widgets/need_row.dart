// NeedRow: one line of the Needs-you queue (web `NeedRow.tsx`; ADR 0008 D4/D5, text diet). A leading disk (the hall's section symbol for a
// request, the type glyph for the rest), the name, the facts as glyph + value, the time left as a timer fact, and for a request the voucher price.
// The 2 dp reply-window bar is the row's own baseline and depletes toward the inline-start. A request row is the toggle that opens the full triage
// card in place; every other item opens its object. No label is printed: the glyph is the type, its name is read.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, DecimalOptions, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show SlaState;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/today_data.dart';
import 'today_bits.dart';

IconData _typeIcon(NeedKind k) => switch (k) {
  NeedKind.request => GzIcons.calendarDots,
  NeedKind.awaiting => GzIcons.hourglass,
  NeedKind.visit => GzIcons.calendarPlus,
  NeedKind.message => GzIcons.chat,
  NeedKind.review => GzIcons.star,
  NeedKind.calendar => GzIcons.calendarCheck,
};

String _kindWord(AppL10n l, NeedKind k) => switch (k) {
  NeedKind.request => l.hotelTodayKindRequest,
  NeedKind.awaiting => l.hotelTodayKindAwaiting,
  NeedKind.visit => l.hotelTodayKindVisit,
  NeedKind.message => l.hotelTodayKindMessage,
  NeedKind.review => l.hotelTodayKindReview,
  NeedKind.calendar => l.hotelTodayKindCalendar,
};

/// Minutes between an instant and the app's clock (never negative).
int _waited(DateTime since, DateTime now) => now.difference(since).inMinutes.clamp(0, 1 << 30);

class NeedRow extends ConsumerWidget {
  const NeedRow({
    required this.entry,
    this.expanded = false,
    this.expandable = true,
    this.onPressed,
    this.onConfirm,
    this.disabled = false,
    this.last = false,
    this.detail = false,
    super.key,
  });

  final NeedItem entry;
  final bool expanded;

  /// A venue request opens as the triage card in place; a service provider's request (and every other item) opens its object.
  final bool expandable;
  final VoidCallback? onPressed;
  final VoidCallback? onConfirm;
  final bool disabled;
  final bool last;

  /// The full queue adds the absolute reply-by clock to a request (a fact, not a sentence).
  final bool detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    final kind = entry.kind;
    final isRequest = kind == NeedKind.request;
    final request = entry.request;
    final booking = request?.booking;
    final sla = entry.sla;
    final tone = leftToneOf(sla?.state);
    final share = sla == null ? 0.0 : (1 - sla.elapsed).clamp(0.0, 1.0);
    final canExpand = expandable && isRequest && request != null;
    final leftTone = kind == NeedKind.awaiting ? (sla?.state == SlaState.expired ? LeftTone.expired : LeftTone.neutral) : tone;
    String say(String spoken) => kind == NeedKind.awaiting ? l.hotelTodayConfirmWindowEnds(spoken) : l.hotelTodayWindowEnds(spoken);

    String name = entry.item.title.of(lang);
    var userName = true;
    IconData disk = _typeIcon(kind);
    final facts = <Widget>[];
    Widget? trailing;
    int? price;

    if ((kind == NeedKind.request || kind == NeedKind.awaiting) && booking != null) {
      name = booking.clientName;
      final section = booking.sections.isEmpty ? null : booking.sections.first;
      final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
      if (kind == NeedKind.request && section != null) disk = audienceIcon(section.audience);
      facts.add(TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: dayMonth(f, booking.eventDate.toString()), small: true));
      if (guests > 0) facts.add(GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactGuests, value: f.integer(guests), small: true));
      price = booking.totals.voucherTotal.fils;
      if (sla != null && sla.state != SlaState.expired) {
        trailing = TimeLeft(minutes: sla.minutesLeft, tone: leftTone, say: say);
      } else if (kind == NeedKind.awaiting) {
        trailing = const GzStatusIcon(status: GzStatus.lapsed, audience: GzStatusAudience.hotel);
      }
      final due = entry.item.dueAt;
      if (detail && isRequest && due != null && trailing != null) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            trailing,
            const SizedBox(width: GzSpace.s3),
            TextFact(icon: GzIcons.clock, label: l.hotelTodayFactReplyBy, text: f.time(due), muted: true, small: true),
          ],
        );
      }
    } else if (kind == NeedKind.visit) {
      final id = entry.item.visitId;
      final visit = id == null ? null : ref.watch(visitProvider(id)).value;
      if (visit != null) {
        name = visit.clientName;
        facts.add(TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: f.dateTime(visit.slotStart, DateStyle.short), small: true));
        facts.add(GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactVisitors, value: f.integer(visit.visitors), small: true));
      }
      trailing = TimeLeft(minutes: _waited(entry.item.raisedAt, now), tone: LeftTone.gold, glyph: GzIcons.hourglass, say: l.hotelTodayWaitingLong);
    } else if (kind == NeedKind.message) {
      final id = entry.item.conversationId;
      final conv = id == null ? null : ref.watch(conversationProvider(id)).value;
      if (conv != null) name = conv.clientName;
      final rows = ref.watch(requestRowsProvider).value;
      final b = entry.item.bookingId == null ? null : rows?[entry.item.bookingId]?.booking;
      if (b != null) facts.add(TextFact(icon: GzIcons.calendar, label: l.hotelTodayFactDate, text: dayMonth(f, b.eventDate.toString()), small: true));
      trailing = TimeLeft(minutes: _waited(entry.item.raisedAt, now), tone: LeftTone.gold, glyph: GzIcons.hourglass, say: l.hotelTodayWaitingLong);
    } else if (kind == NeedKind.review) {
      final id = entry.item.reviewId;
      final review = id == null ? null : ref.watch(reviewProvider(id)).value;
      if (review != null) {
        name = review.author.of(lang);
        facts.add(
          GzFactChip(
            icon: GzIcons.star,
            label: l.hotelTodayFactRating,
            value: f.number(review.rating, const DecimalOptions(maxFraction: 1)),
            tone: GzFactTone.accent,
            small: true,
          ),
        );
      } else {
        userName = false;
      }
      trailing = TimeLeft(minutes: _waited(entry.item.raisedAt, now), tone: LeftTone.gold, glyph: GzIcons.hourglass, say: l.hotelTodayWaitingLong);
    } else if (kind == NeedKind.calendar) {
      name = l.hotelTodayCalendarCheck;
      userName = false;
    }

    final priced = price != null;
    final nameW = userName
        ? GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2)
        : GzText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 2);
    final top = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: nameW),
        const SizedBox(width: GzSpace.s3),
        if (priced) GzPrice(fils: price, size: GzPriceSize.strong) else ?trailing,
      ],
    );
    final showBottom = facts.isNotEmpty || (priced && trailing != null);
    final bottom = !showBottom
        ? null
        : Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s1,
            children: [
              if (facts.isNotEmpty) GzFactRow(children: facts),
              if (priced && !detail) ?trailing,
            ],
          );

    final body = Row(
      children: [
        Container(
          width: GzSize.avatarSm,
          height: GzSize.avatarSm,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isRequest ? c.surfaceTint : c.surfaceQuiet),
          child: GzIcon(disk, size: GzIconSize.sm, color: c.iconPrimary),
        ),
        const SizedBox(width: GzSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              top,
              if (bottom != null) ...[const SizedBox(height: GzSpace.s1), bottom],
              if (priced && detail && trailing != null) ...[
                const SizedBox(height: GzSpace.s1),
                Align(alignment: AlignmentDirectional.centerStart, child: trailing),
              ],
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s3),
        if (canExpand)
          GzIcon(expanded ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary)
        else if (kind != NeedKind.calendar)
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
      ],
    );

    final label = [_kindWord(l, kind), name].join('. ');
    final line = Row(
      children: [
        Expanded(
          child: GzPressable(
            onPressed: disabled ? null : onPressed,
            semanticLabel: label,
            borderRadius: GzRadius.smAll,
            minHeight: GzSize.rowQueue,
            scale: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
              child: body,
            ),
          ),
        ),
        if (kind == NeedKind.calendar && onConfirm != null) ...[
          const SizedBox(width: GzSpace.s3),
          GzButton(
            label: context.gzL10n.commonActionConfirm,
            variant: GzButtonVariant.secondary,
            size: GzButtonSize.sm,
            onPressed: disabled ? null : onConfirm,
          ),
        ],
      ],
    );

    final Widget base;
    if (isRequest) {
      final fill = switch (tone) {
        LeftTone.gold => c.statusSlaWarn,
        LeftTone.danger => c.statusSlaAlert,
        LeftTone.expired => c.borderStrong,
        _ => c.statusSlaOk,
      };
      base = SizedBox(
        height: GzStroke.thread,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.markTrack)),
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: share,
                  heightFactor: 1,
                  child: ColoredBox(color: fill),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      base = last
          ? const SizedBox.shrink()
          : SizedBox(
              height: GzStroke.hair,
              child: ColoredBox(color: c.borderHairline, child: const SizedBox.expand()),
            );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [line, base]);
  }
}
