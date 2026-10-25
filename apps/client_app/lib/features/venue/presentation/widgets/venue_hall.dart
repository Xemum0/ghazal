import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../venue_glyphs.dart';

/// The text up to [limit] characters, cut at the last space so no word is split, closed with an ellipsis.
String cutAt(String text, int limit) {
  if (text.length <= limit) return text;
  final head = text.substring(0, limit);
  final space = head.lastIndexOf(' ');
  final cut = space > limit * 0.6 ? head.substring(0, space) : head;
  return '${cut.replaceFirst(RegExp(r'[\s,.;:،؛]+$'), '')}…';
}

/// Clamp (ADR 0034): authored text (a hall description, a review, the venue's own terms) is exempt from the word budget but never
/// runs long on the page: two or three lines, then the chevron.
class VenueClamp extends StatefulWidget {
  const VenueClamp({required this.text, this.limit = 96, this.lang, super.key});

  final String text;
  final int limit;

  /// Language of the text when it is not the interface language (a review as typed).
  final String? lang;

  @override
  State<VenueClamp> createState() => _VenueClampState();
}

class _VenueClampState extends State<VenueClamp> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final long = widget.text.length > widget.limit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Directionality(
            textDirection: widget.lang == null ? Directionality.of(context) : (widget.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr),
            child: GzText(long && !_open ? cutAt(widget.text, widget.limit) : widget.text, role: GzTextRole.bodyS, color: c.textPrimary, textAlign: TextAlign.start),
          ),
        ),
        if (long) ...[
          const SizedBox(width: GzSpace.s1),
          GzIconButton(
            icon: _open ? GzIcons.chevronUp : GzIcons.chevronDown,
            iconSize: GzIconSize.sm,
            label: _open ? l.clientVenueLess : l.clientVenueMore,
            expanded: _open,
            onPressed: () => setState(() => _open = !_open),
          ),
        ],
      ],
    );
  }
}

/// ThreadPreview (CL-VENU-01, direction rule 8): the Booking Thread shown before anything has happened. Five glyph knots (voucher,
/// request, approval, confirmation inside 24 hours, at the venue); the first is where the visitor stands, the rest are open (a knot
/// ties only on a real event). One word under the active knot, the venue's reply time as a fact and the money rule behind an (i). A quiet
/// rose panel, the one place on the page that tints.
class VenueThreadPreview extends StatelessWidget {
  const VenueThreadPreview({required this.note, this.replyHours, this.onViewVoucher, super.key});

  final String note;
  final double? replyHours;

  /// The client already holds a ready voucher: the request knot is where they stand.
  final VoidCallback? onViewVoucher;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final owned = onViewVoucher != null;
    GzKnotState state(int i) => owned ? (i == 0 ? GzKnotState.tied : (i == 1 ? GzKnotState.now : GzKnotState.open)) : (i == 0 ? GzKnotState.now : GzKnotState.open);
    final steps = <GzIconProgressStep>[
      GzIconProgressStep(id: 'voucher', icon: GzIcons.ticket, label: l.clientVenueThreadVoucher, state: state(0)),
      GzIconProgressStep(id: 'request', icon: GzIcons.send, label: l.clientVenueThreadRequest, state: state(1)),
      GzIconProgressStep(id: 'approval', icon: GzIcons.verified, label: l.clientVenueThreadApproval, state: state(2)),
      GzIconProgressStep(id: 'confirmation', icon: GzIcons.calendarCheck, label: l.clientVenueThreadConfirm, state: state(3)),
      GzIconProgressStep(id: 'redemption', icon: GzIcons.qrCode, label: l.clientVenueThreadAtVenue, state: state(4)),
    ];
    return Semantics(
      container: true,
      label: l.clientVenueThreadTitle,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.panelPad, end: GzSpace.panelPad, top: GzSpace.panelPad, bottom: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzIconProgress(steps: steps, label: l.clientVenueThreadLabel),
              const SizedBox(height: GzSpace.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: owned
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const GzStatusPill(status: GzStatus.voucherActive),
                                const SizedBox(width: GzSpace.s3),
                                Flexible(
                                  child: GzButton(label: l.clientVenueOwnedView, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.chevronRight, onPressed: onViewVoucher),
                                ),
                              ],
                            )
                          : (replyHours != null
                                ? Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: GzFactChip(
                                      icon: GzIcons.chat,
                                      valueWidget: GzText(context.gzDuration((replyHours! * 3600000).round()), role: GzTextRole.figBodyS, figures: true),
                                      label: l.clientVenueResponseUsually(replyHours!.round()),
                                    ),
                                  )
                                : const SizedBox.shrink()),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    GzInfoButton(title: context.gzL10n.commonVoucher, label: l.clientVenueHowTitle, paragraphs: [note]),
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

/// HallSection (CL-VENU-01): the hall switcher (only when more than one hall fits the Brief), the hall's facts as glyphs and figures, its
/// description clamped, and the session switcher (only when more than one session is free that day; an exclusive-day ballroom has none,
/// ADR 0002 D5). Hall names are the one serif inside a control (direction 3, segmented).
class VenueHallSection extends StatelessWidget {
  const VenueHallSection({
    required this.halls,
    required this.hall,
    required this.onHall,
    required this.day,
    required this.date,
    required this.sessionId,
    required this.onSession,
    super.key,
  });

  final List<Hall> halls;
  final Hall hall;
  final ValueChanged<String> onHall;
  final AvailabilityDay? day;
  final LocalDate? date;
  final String? sessionId;
  final ValueChanged<String> onSession;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final free = !hall.exclusiveDay && day != null
        ? hall.sessions.where((s) => day!.sessions.any((x) => x.sessionId == s.id && (x.state == DayState.available || x.state == DayState.held))).toList()
        : const <Session>[];
    final session = free.where((s) => s.id == sessionId).firstOrNull ?? free.firstOrNull;
    String rangeOf(Session s) {
      final d = date ?? LocalDate(2026, 11, 13);
      final end = s.end.compareTo(s.start) <= 0 ? d.addDays(1) : d;
      return f.plain(f.timeRange('${d}T${s.start}', '${end}T${s.end}'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSectionHeader(title: halls.length > 1 ? l.clientVenueHallsTitle : context.bi(hall.name)),
        const SizedBox(height: GzSpace.s4),
        if (halls.length > 1) ...[
          GzSegmentedControl<String>(
            label: l.clientVenueHallSwitchLabel,
            face: GzSegmentedFace.hall,
            value: hall.id,
            onChanged: onHall,
            options: [for (final h in halls) GzSegmentedOption<String>(value: h.id, label: context.bi(h.name))],
          ),
          const SizedBox(height: GzSpace.s4),
        ],
        GzFactRow(
          label: l.clientVenueHallFacts,
          children: [
            GzFactChip(
              icon: GzIcons.usersThree,
              label: l.clientVenueHallCapacity,
              valueWidget: GzNum('${f.integer(hall.capacity.min)}–${f.integer(hall.capacity.max)}', role: GzTextRole.figBodyS),
            ),
            GzFactChip(icon: settingGlyph(hall.setting), label: settingName(l, hall.setting)),
            if (hall.exclusiveDay) GzFactChip(icon: GzIcons.calendarCheck, label: l.clientVenueHallExclusive, value: l.clientVenueHallExclusiveShort),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        VenueClamp(text: context.bi(hall.description)),
        if (free.length > 1) ...[
          const SizedBox(height: GzSpace.s4),
          GzIconSegmented<String>(
            label: l.clientVenueSessionSwitchLabel,
            value: session?.id,
            onChanged: onSession,
            options: [for (final s in free) GzIconSegmentedOption<String>(value: s.id, icon: sessionGlyph(s.start), label: context.bi(s.name))],
          ),
          if (session != null) ...[
            const SizedBox(height: GzSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzFactChip(icon: GzIcons.clock, label: context.bi(session.name), valueWidget: GzText(rangeOf(session), role: GzTextRole.figBodyS, color: c.textPrimary, figures: true)),
            ),
          ],
        ],
      ],
    );
  }
}
