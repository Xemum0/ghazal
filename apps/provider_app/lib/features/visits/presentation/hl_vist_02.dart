// HL-VIST-02 Visit (web `HL-VIST-02.tsx`): one site visit as the hotel representative sees it: who, when, how many, what they asked, the assigned
// representative, the three chat members and the visit's own timeline. The pinned bar changes with the status. Visits are free and carry no
// money. The client shows a first name and a monogram; the phone is never shown. Requirements: HA-VIS-02, HA-VIS-03, HA-VIS-04, HA-VIS-06.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffMember, ThreadMember, VisitStatus, VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/visits_data.dart';
import 'widgets/visit_actions.dart';
import 'widgets/visit_detail_bits.dart';
import 'widgets/visit_sheets.dart';
import 'widgets/visits_bits.dart';

class HlVist02Screen extends ConsumerWidget {
  const HlVist02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final id = (GzNavigatorScope.of(context).params['visitId'] as String?) ?? kHeroRequestedVisit;
    final role = ref.watch(visitRoleProvider);
    final thread = ref.watch(partnerVisitThreadProvider(id));
    final f = context.gzFormat;
    final data = thread.value;
    final now = ref.watch(clockProvider)();
    final act = VisitUi(context, ref);
    final canReply = canSeeVisits(role);
    Widget? bar;
    if (data != null && canReply) bar = VisitBar(visit: data.visit, lead: isVisitLead(role), now: now, act: act, isoDay: f.isoDay);
    final title = data == null ? null : l.hotelVisitsDetailTitle(f.dateTime(data.visit.slotStart, DateStyle.short));
    return GzScreen(
      top: GzTopBar(title: title),
      bottom: bar,
      child: !canReply
          ? GzErrorState(kind: GzErrorKind.noAccess, title: l.hotelVisitsNoAccessTitle, body: l.hotelVisitsNoAccessBody)
          : GzAsyncView<VisitThread>(
              value: thread,
              loading: const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s2),
                child: Column(
                  children: [
                    GzSkeleton(blockSize: 112),
                    SizedBox(height: GzSpace.s4),
                    GzSkeleton(blockSize: 72),
                    SizedBox(height: GzSpace.s4),
                    GzSkeleton(blockSize: 160),
                  ],
                ),
              ),
              onRetry: () => ref.invalidate(partnerVisitThreadProvider(id)),
              data: (t) => _Body(thread: t, now: now),
            ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.thread, required this.now});

  final VisitThread thread;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final role = ref.watch(visitRoleProvider);
    final v = thread.visit;
    final act = VisitUi(context, ref);
    final name = firstName(v.clientName);
    final repId = ref.watch(representativeOverrideProvider)[v.id] ?? v.representativeId;
    final staff = ref.watch(visitStaffProvider).value ?? const <StaffMember>[];
    final rep = staff.where((s) => s.userId == repId).firstOrNull;
    final repName = rep == null ? '' : (lang == 'ar' ? rep.name : rep.nameLatin);
    final lead = isVisitLead(role);
    final today = f.isoDay(v.slotStart) == f.isoDay(now);
    final proposed = v.proposedSlotStart;
    final declined = ref.watch(declineReasonProvider)[v.id];
    final members = thread.thread.members ?? const <ThreadMember>[];

    (IconData, String) note() => switch (v.status) {
      VisitStatus.requested => (GzIcons.clock, l.hotelVisitsNoteRequested),
      VisitStatus.rescheduleProposed => (
        GzIcons.calendarDots,
        l.hotelVisitsNoteReschedule(proposed == null ? '' : f.dateTime(proposed, DateStyle.short)),
      ),
      VisitStatus.confirmed =>
        today ? (GzIcons.pin, l.hotelVisitsNoteDayOf(f.time(v.slotStart))) : (GzIcons.calendarCheck, l.hotelVisitsNoteConfirmed),
      VisitStatus.arrived => (GzIcons.checkCircle, l.hotelVisitsNoteArrived(f.time(v.arrivedAt ?? v.slotStart))),
      VisitStatus.completed => (GzIcons.checkDouble, l.hotelVisitsNoteCompleted),
      VisitStatus.declined => (
        GzIcons.calendarX,
        declined == null ? l.hotelVisitsNoteDeclined : l.hotelVisitsNoteDeclinedReason(declineWord(l, declined)),
      ),
      VisitStatus.cancelled => (GzIcons.close, l.hotelVisitsNoteCancelled),
      _ => (GzIcons.userMinus, l.hotelVisitsNoteMissed),
    };
    final n = note();
    final chatOpen = v.status == VisitStatus.confirmed || v.status == VisitStatus.rescheduleProposed || v.status == VisitStatus.arrived;
    const gap = SizedBox(height: GzSpace.s6);
    Widget pad(Widget w) => Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: w,
    );

    return Padding(
      padding: const EdgeInsets.only(top: GzSpace.s2, bottom: GzSpace.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pad(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzStatusPill(status: visitPill(v.status), audience: GzStatusAudience.hotel),
                const SizedBox(height: GzSpace.s3),
                GzText(f.date(v.slotStart, DateStyle.full), role: GzTextRole.uiXl, color: c.textStrong, figures: true, header: true),
                const SizedBox(height: GzSpace.s2),
                Wrap(
                  spacing: GzSpace.s5,
                  runSpacing: GzSpace.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...(context.gz.isAr
                        ? <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GzIcon(GzIcons.guests, size: GzIconSize.sm, color: c.iconSecondary),
                                const SizedBox(width: GzSpace.s2),
                                GzText(l.hotelVisitsVisitors(v.visitors), role: GzTextRole.body, color: c.textPrimary),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GzIcon(GzIcons.clock, size: GzIconSize.sm, color: c.iconSecondary),
                                const SizedBox(width: GzSpace.s2),
                                GzText(f.timeRange(v.slotStart, v.slotEnd), role: GzTextRole.figBody, color: c.textPrimary, figures: true),
                              ],
                            ),
                          ]
                        : <Widget>[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GzIcon(GzIcons.clock, size: GzIconSize.sm, color: c.iconSecondary),
                                const SizedBox(width: GzSpace.s2),
                                GzText(f.timeRange(v.slotStart, v.slotEnd), role: GzTextRole.figBody, color: c.textPrimary, figures: true),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GzIcon(GzIcons.guests, size: GzIconSize.sm, color: c.iconSecondary),
                                const SizedBox(width: GzSpace.s2),
                                GzText(l.hotelVisitsVisitors(v.visitors), role: GzTextRole.body, color: c.textPrimary),
                              ],
                            ),
                          ]),
                  ],
                ),
              ],
            ),
          ),
          gap,
          pad(VisitNotice(icon: n.$1, text: n.$2, rose: v.status == VisitStatus.requested || v.status == VisitStatus.missed)),
          gap,
          VisitSection(
            title: l.hotelVisitsSecClient,
            child: Row(
              children: [
                GzAvatar(name: name, initial: lang == 'ar' ? name.substring(0, 1) : null, size: GzAvatarSize.md, voice: GzAvatarVoice.sans),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: GzUserText(name, role: GzTextRole.uiTitle, color: c.textStrong, maxLines: 1),
                ),
              ],
            ),
          ),
          gap,
          VisitSection(
            title: l.hotelVisitsSecVisit,
            child: Column(
              children: [
                _FactRow(
                  label: l.hotelVisitsFactRequested,
                  value: f.dateTime(v.requestedAt, DateStyle.short),
                  last: !(v.status == VisitStatus.rescheduleProposed && proposed != null),
                ),
                if (v.status == VisitStatus.rescheduleProposed && proposed != null)
                  _FactRow(label: l.hotelVisitsFactProposed, value: f.dateTime(proposed, DateStyle.short), last: true),
              ],
            ),
          ),
          if (v.note != null && v.note!.isNotEmpty) ...[
            gap,
            VisitSection(
              title: l.hotelVisitsSecNote,
              child: Container(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.s4),
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: c.borderStrong, width: GzStroke.hair),
                  ),
                ),
                child: GzUserText(v.note!, role: GzTextRole.body, color: c.textPrimary),
              ),
            ),
          ],
          gap,
          VisitSection(
            title: l.hotelVisitsSecRep,
            child: GzListRow(
              flush: true,
              last: true,
              title: repName,
              subtitle: rep?.roleLabel.of(lang),
              leading: rep == null
                  ? null
                  : GzAvatar(name: repName, initial: lang == 'ar' ? rep.monogram : null, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
              chevron: lead,
              onPressed: lead ? () => act.assign(v, repId) : null,
              autoDir: true,
            ),
          ),
          if (members.isNotEmpty) ...[
            gap,
            VisitSection(
              title: l.hotelVisitsSecChat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzParticipantStrip(members: members, onOpen: () => act.members(members)),
                  if (!(canSeeVisits(role) && chatOpen)) ...[
                    const SizedBox(height: GzSpace.s3),
                    GzButton(
                      label: l.hotelVisitsOpenChat,
                      variant: GzButtonVariant.secondary,
                      size: GzButtonSize.md,
                      fullWidth: true,
                      spill: true,
                      iconStart: GzIcons.chat,
                      onPressed: () => act.chat(v),
                    ),
                  ],
                ],
              ),
            ),
          ],
          gap,
          VisitSection(
            title: l.hotelVisitsSecTimeline,
            child: VisitTimeline(visit: v, repName: repName),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.label, required this.value, required this.last});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: GzText(label, role: GzTextRole.bodyS, color: c.textSecondary),
          ),
          GzText(value, role: GzTextRole.body, color: c.textStrong, figures: true),
        ],
      ),
    );
  }
}
