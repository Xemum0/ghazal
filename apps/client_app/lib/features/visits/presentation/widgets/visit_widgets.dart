export 'visit_slot_picker.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show ThreadMember, ThreadRole, VisitRow, VisitStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/visits_view.dart';

/// The venue a visit is about: a 56 photograph (a monogram when there is
/// none), the name in the display face, then a hall caption or facts.
class VenueLineTile extends ConsumerWidget {
  const VenueLineTile({required this.venueId, this.caption, this.facts, super.key});

  final String venueId;
  final String? caption;
  final Widget? facts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venue = ref.watch(venueOfProvider(venueId)).value;
    final lang = context.gz.locale.languageCode;
    final name = venue?.name.of(lang) ?? '';
    final cover = venue?.cover;
    return Semantics(
      container: true,
      label: name,
      child: ExcludeSemantics(
        child: Row(
          children: [
            if (cover != null)
              SizedBox(
                width: GzSize.thumbMd,
                height: GzSize.thumbMd,
                child: ClipRRect(
                  borderRadius: GzRadius.smAll,
                  child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl), alt: cover.alt.of(lang)),
                ),
              )
            else
              GzAvatar(name: name.isEmpty ? ' ' : name, size: GzAvatarSize.md),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(textDirection: TextDirection.ltr, child: const SizedBox.shrink()),
                  GzText(
                    name,
                    role: GzTextRole.d1,
                    color: context.gz.colors.textStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    header: true,
                  ),
                  if (caption != null)
                    GzText(caption!, role: GzTextRole.caption, color: context.gz.colors.textSecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (facts != null) ...[const SizedBox(height: GzSpace.s1), facts!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three facts of one visit as icon + value, no labels: the day, the
/// arrival window and how many people come.
class VisitFactsRow extends StatelessWidget {
  const VisitFactsRow({
    required this.slotStart,
    required this.slotEnd,
    this.visitors,
    this.compact = false,
    this.tone = GzFactTone.normal,
    this.startOnly = false,
    super.key,
  });

  final DateTime slotStart;
  final DateTime slotEnd;
  final int? visitors;
  final bool compact;
  final GzFactTone tone;
  final bool startOnly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    // Compact drops the weekday (`14 Nov`); the full line keeps it.
    final day = compact
        ? '${f.integer(f.civil(slotStart.toIso8601String()).day)} ${f.monthName(f.civil(slotStart.toIso8601String()).month, short: true)}'
        : f.date(slotStart.toIso8601String(), DateStyle.full);
    // The window as one figure and one quiet unit (`5:00–5:30 م`), split from the shared formatter's own join.
    (String, String) partsOf(DateTime at) {
      final s = f.time(at.toIso8601String());
      final i = s.lastIndexOf(' ');
      return i < 0 ? (s, '') : (s.substring(0, i), s.substring(i + 1));
    }

    final a = partsOf(slotStart);
    final b = partsOf(slotEnd);
    final String? mer = startOnly ? (a.$2.isEmpty ? null : a.$2) : (a.$2 == b.$2 ? (b.$2.isEmpty ? null : b.$2) : (b.$2.isEmpty ? null : b.$2));
    // The window as runs of figures (`5:00`, `–`, `5:30`), like the web's digit islands, so each figure is its own word.
    final Widget windowValue = startOnly
        ? _fig(context, a.$1, small: compact, tone: tone)
        : _rangeValue(context, a.$1, b.$1, small: compact, tone: tone, across: a.$2 == b.$2 ? null : a.$2);
    return GzFactRow(
      label: l.clientVisitsSummary,
      children: [
        GzFactChip(icon: GzIcons.calendar, label: l.clientVisitsFactDay, value: day, tone: tone),
        GzFactChip(icon: GzIcons.clock, label: l.clientVisitsFactWindow, valueWidget: windowValue, unit: mer, tone: tone),
        if (visitors != null) GzFactChip(icon: GzIcons.usersThree, label: l.clientVisitsFactVisitors, value: f.integer(visitors!), tone: tone),
      ],
    );
  }
}

/// One figure run in the voice of a fact chip value.
Widget _fig(BuildContext context, String s, {required bool small, required GzFactTone tone}) {
  final c = context.gz.colors;
  return GzText(
    s,
    role: small ? GzTextRole.figCaption : GzTextRole.figBodyS,
    color: tone == GzFactTone.muted ? c.textSecondary : c.textStrong,
    figures: true,
    softWrap: false,
  );
}

/// The window figure as three runs (`5:00`, `–`, `5:30`); `across` carries the first meridiem when the window crosses noon.
Widget _rangeValue(BuildContext context, String hm1, String hm2, {required bool small, required GzFactTone tone, String? across}) {
  final spoken = across == null ? '$hm1–$hm2' : '$hm1 $across–$hm2';
  return Semantics(
    container: true,
    label: spoken,
    child: ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fig(context, hm1, small: small, tone: tone),
            if (across != null) ...[_fig(context, ' $across', small: small, tone: tone)],
            _fig(context, '–', small: small, tone: tone),
            _fig(context, hm2, small: small, tone: tone),
          ],
        ),
      ),
    ),
  );
}

/// The status of a site visit as the shared status vocabulary.
GzStatus statusOfVisitLocal(VisitStatus s) => switch (s) {
  VisitStatus.requested => GzStatus.visitRequested,
  VisitStatus.confirmed => GzStatus.visitConfirmed,
  VisitStatus.rescheduleProposed => GzStatus.visitReschedule,
  VisitStatus.arrived => GzStatus.visitArrived,
  VisitStatus.completed => GzStatus.visitCompleted,
  VisitStatus.declined => GzStatus.visitDeclined,
  VisitStatus.cancelled => GzStatus.visitCancelled,
  _ => GzStatus.visitMissed,
};

/// One of the client's visits (CL-VIST-04): a 56 photograph (a monogram when
/// there is none), the venue name, the status pill and the day and arrival
/// time as icon + value. One 44+ target into the chat.
class VisitRowTile extends StatelessWidget {
  const VisitRowTile({required this.row, required this.onOpen, super.key});

  final VisitRow row;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final v = row.visit;
    final name = row.target.name.of(lang);
    final when = '${f.date(v.slotStart.toIso8601String(), DateStyle.dayMonth)} · ${f.time(v.slotStart)}';
    final cover = row.target.cover;
    return Column(
      key: ValueKey<String>('visits.row.${v.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPressable(
          onPressed: onOpen,
          semanticLabel: '$name, $when',
          scale: 1,
          minHeight: 0,
          minWidth: 0,
          borderRadius: GzRadius.smAll,
          builder: (context, st) => Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
            child: Row(
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(
                    width: GzSize.thumbCompactWidth,
                    height: GzSize.thumbCompactHeight,
                    child: ClipRRect(
                      borderRadius: GzRadius.mdAll,
                      child: cover != null
                          ? GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl), alt: cover.alt.of(lang))
                          : Center(child: GzAvatar(name: name, initial: context.gz.isAr ? row.target.monogram : null, size: GzAvatarSize.lg)),
                    ),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzText(name, role: GzTextRole.d1, color: context.gz.colors.textStrong, textAlign: TextAlign.start),
                      const SizedBox(height: GzSpace.s2),
                      GzStatusPill(status: statusOfVisitLocal(v.status)),
                      const SizedBox(height: GzSpace.s2),
                      VisitFactsRow(slotStart: v.slotStart, slotEnd: v.slotEnd, compact: true, startOnly: true),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
              ],
            ),
          ),
        ),
        Container(height: GzStroke.hair, color: context.gz.colors.borderHairline),
      ],
    );
  }
}

/// The three members of a visit chat as monogram discs in fixed order.
class MemberDiscs extends StatelessWidget {
  const MemberDiscs({required this.members, this.meId, this.onOpen, super.key});

  final List<ThreadMember> members;
  final String? meId;
  final VoidCallback? onOpen;

  static int _order(ThreadRole r) => switch (r) {
    ThreadRole.client => 0,
    ThreadRole.hotelRepresentative => 1,
    _ => 2,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final sorted = [...members]..sort((a, b) => _order(a.role).compareTo(_order(b.role)));
    final discs = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < sorted.length; i++) ...[
          if (i > 0) const SizedBox(width: GzSpace.s1),
          _MemberDisc(member: sorted[i], lang: lang),
        ],
      ],
    );
    if (onOpen == null) {
      return Semantics(
        container: true,
        label: l.clientVisitsMembersOpen,
        child: ExcludeSemantics(child: discs),
      );
    }
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: l.clientVisitsMembersOpen,
      scale: 1,
      minHeight: GzSize.touchMin,
      minWidth: 0,
      borderRadius: GzRadius.pillAll,
      child: discs,
    );
  }
}

/// One monogram disc of the web `gzvt-md__d`: a 2 dp pad and a 1 dp ring (the client's is visible), tinted by role.
class _MemberDisc extends StatelessWidget {
  const _MemberDisc({required this.member, required this.lang});

  final ThreadMember member;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final name = lang == 'ar' ? member.name : member.nameLatin;
    final (Color bg, Color ring) = switch (member.role) {
      ThreadRole.client => (c.surfaceRaised, c.borderStrong),
      ThreadRole.hotelRepresentative => (c.statusNeutralBg, c.scrimClear),
      _ => (c.surfaceTint, c.scrimClear),
    };
    final fg = member.role == ThreadRole.hotelRepresentative ? c.statusNeutralText : c.textStrong;
    final style = gz.text(GzTextRole.d1).copyWith(color: fg, wordSpacing: 0, decoration: TextDecoration.none);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(GzStroke.thread),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: GzStroke.hair)),
        child: Container(
          width: GzSize.disk,
          height: GzSize.disk,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          child: Text((lang == 'ar' ? member.monogram : null) ?? gzMonogramOf(name), style: style, textAlign: TextAlign.center, softWrap: false),
        ),
      ),
    );
  }
}
