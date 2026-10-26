import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, chatRepositoryProvider, visitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart'
    show
        SendMessageInput,
        SendMessageInputKind,
        ThreadMember,
        VisitAppointment,
        VisitProposalAnswer,
        VisitStatus,
        VisitThread,
        WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import 'widgets/visit_composer.dart';
import 'widgets/visit_thread_parts.dart';
import '../application/visits_view.dart';
import 'widgets/visit_widgets.dart';

/// CL-VIST-03 Visit chat. Covers CA-VIS-03, CA-VIS-05, CA-VIS-06, CA-CHAT-06,
/// CA-CHAT-07, CA-CHAT-08, CA-CHAT-11.
///
/// The dedicated three-way group chat of one visit: the client, a hotel
/// representative and a Ghazal support representative. A pinned card carries
/// the slot, status and arrival actions; messages show the sender's role chip.
/// Read-only after closing: the composer is replaced by a lock and a link.
/// States: requested, confirmed, reschedule-proposed, day-of, arrived,
/// completed-read-only, declined, cancelled, missed, sending, failed,
/// offline-queued, loading, error.
class ClVist03Screen extends ConsumerStatefulWidget {
  const ClVist03Screen({super.key});

  @override
  ConsumerState<ClVist03Screen> createState() => _ClVist03ScreenState();
}

class _ClVist03ScreenState extends ConsumerState<ClVist03Screen> {
  GzNavigator get _nav => context.gzNav;

  String get _visitId => (_nav.params['visitId'] as String?) ?? 'visit-aurelia-reem';

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(visitThreadProvider(_visitId));
    return GzAsyncView<VisitThread>(
      value: thread,
      loading: const VisitChatSkeleton(),
      onRetry: () => ref.invalidate(visitThreadProvider(_visitId)),
      data: (t) => _ChatBody(key: ValueKey<String>('visits.chat.${t.visit.id}'), thread: t),
    );
  }
}

class _ChatBody extends ConsumerStatefulWidget {
  const _ChatBody({required this.thread, super.key});

  final VisitThread thread;

  @override
  ConsumerState<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends ConsumerState<_ChatBody> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // The web thread opens at the newest message (body.scrollTop = scrollHeight).
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(2));
  }

  void _toEnd(int again) {
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(_scroll.position.maxScrollExtent);
    if (again > 0) WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(again - 1));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GzNavigator get _nav => context.gzNav;

  VisitAppointment get _visit => widget.thread.visit;

  Future<void> _sendText(String text) async {
    final convId = widget.thread.thread.id;
    final repo = ref.read(chatRepositoryProvider);
    final notSent = context.l10n.clientVisitsNotSent;
    final nav = _nav;
    try {
      await repo.sendMessage(
        conversationId: convId,
        body: SendMessageInput(
          clientMsgId: 'c${DateTime.now().microsecondsSinceEpoch}',
          kind: SendMessageInputKind.text,
          text: text,
          origin: WireLang.en,
        ),
      );
      ref.read(clientDataRevisionProvider.notifier).bump();
      ref.invalidate(visitThreadProvider(_visit.id));
    } on Object {
      nav.toast(GzToastSpec(message: notSent));
    }
  }

  Future<void> _confirmProposed() async {
    try {
      await ref.read(visitsRepositoryProvider).answerVisitProposal(visitId: _visit.id, body: const VisitProposalAnswer(accept: true));
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (mounted) _nav.toast(GzToastSpec(message: context.l10n.clientVisitsConfirmedToast, tone: GzToastTone.success));
    } on Object {
      if (mounted) _nav.toast(GzToastSpec(message: context.l10n.clientVisitsNothingChanged, tone: GzToastTone.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final visit = _visit;
    final members = widget.thread.thread.members ?? const <ThreadMember>[];
    final closed = visitChatClosed(visit, ref.watch(clockProvider)());
    final meId = widget.thread.thread.clientId;
    final lang = context.gz.locale.languageCode;
    final venueName = widget.thread.target.name.of(lang);
    final top = GzTopBar(title: venueName);
    final bottom = closed
        ? _ClosedBar(venueId: visit.venueId)
        : VisitComposer(
            onSend: _sendText,
            onAttach: () {},
            onVoice: (s) {},
            onTooShort: () => _nav.toast(GzToastSpec(message: l.clientVisitsRecordTooShort)),
          );
    return GzScreen.slivers(
      controller: _scroll,
      top: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          _PinnedCard(
            thread: widget.thread,
            meId: meId,
            members: members,
            onMembers: () => _openMembers(members, meId, venueName),
            onAnother: () => _nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{'venueId': visit.venueId})),
            onChange: () => _nav.openSheet('CL-VIST-05', options: GzSheetOptions(params: <String, Object?>{'visitId': visit.id})),
            onConfirmProposed: _confirmProposed,
            onWay: () => _sendText(l.clientVisitsTapOnTheWay),
            onArrived: () => _sendText(l.clientVisitsTapArrived),
          ),
        ],
      ),
      bottom: bottom,
      slivers: [VisitThreadSlivers(thread: widget.thread, meId: meId)],
    );
  }

  void _openMembers(List<ThreadMember> members, String? meId, String venueName) {
    final l = context.l10n;
    final nav = _nav;
    final visit = _visit;
    _nav.openSheetBuilder(
      (_) => Column(
        key: const ValueKey<String>('visits.members'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GzText(l.clientVisitsMembersTitle, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true),
              ),
              const SizedBox(width: GzSpace.s3),
              GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: () => nav.closeSheet()),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          GzParticipantStrip(members: members, meId: meId),
          const SizedBox(height: GzSpace.s3),
          GzIconListRow(
            flush: true,
            icon: GzIcons.hall,
            title: venueName,
            chevron: true,
            onPressed: () {
              nav.closeSheet();
              nav.push('CL-VENU-01', params: <String, Object?>{'venueId': visit.venueId});
            },
          ),
          GzIconListRow(
            flush: true,
            last: true,
            icon: GzIcons.warning,
            title: l.clientMessagesInfoReport,
            chevron: true,
            onPressed: () {
              nav.closeSheet();
              nav.openSheet('CL-MSGS-03', options: GzSheetOptions(params: <String, Object?>{'conversationId': widget.thread.thread.id}));
            },
          ),
          const SizedBox(height: GzSpace.s2),
          GzText(l.clientVisitsInfoRecord(venueName), role: GzTextRole.caption, color: context.gz.colors.textSecondary),
        ],
      ),
    );
  }
}

/// The pinned visit card under the header: status pill, the day / window /
/// visitors facts, the proposed time and the action of the moment.
class _PinnedCard extends ConsumerWidget {
  const _PinnedCard({
    required this.thread,
    required this.meId,
    required this.members,
    required this.onMembers,
    required this.onChange,
    required this.onAnother,
    required this.onConfirmProposed,
    required this.onWay,
    required this.onArrived,
  });

  final VisitThread thread;
  final String? meId;
  final List<ThreadMember> members;
  final VoidCallback onMembers;
  final VoidCallback onAnother;
  final VoidCallback onChange;
  final VoidCallback onConfirmProposed;
  final VoidCallback onWay;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final visit = thread.visit;
    final changeable =
        visit.status == VisitStatus.requested || visit.status == VisitStatus.confirmed || visit.status == VisitStatus.rescheduleProposed;
    final dayOf = changeable && f.isoDay(visit.slotStart) == f.isoDay(ref.watch(clockProvider)());
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: _card(context, ref, l, c, visit, members, changeable, dayOf),
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    AppL10n l,
    GzColors c,
    VisitAppointment visit,
    List<ThreadMember> members,
    bool changeable,
    bool dayOf,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                // The pill at the start, the member discs and "more" together at the end (web `.gzvt-pin__top`, space-between).
                Semantics(
                  container: true,
                  label: l.clientVisitsPinLabel,
                  child: GzStatusPill(status: statusOfVisitLocal(visit.status)),
                ),
                const Spacer(),
                MemberDiscs(members: members, meId: meId, onOpen: onMembers),
                if (changeable) GzIconButton(icon: GzIcons.more, label: l.clientVisitsChangeOrCancel, onPressed: onChange),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s2),
          VisitFactsRow(slotStart: visit.slotStart, slotEnd: visit.slotEnd, visitors: visit.visitors, compact: true),
          if (visit.status == VisitStatus.rescheduleProposed && visit.proposedSlotStart != null) ...[
            const SizedBox(height: GzSpace.s2),
            Row(
              children: [
                GzIcon(GzIcons.forward, size: GzIconSize.sm, color: c.iconAccent),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzFactRow(
                    label: l.clientVisitsConfirmTime,
                    children: [
                      GzFactChip(
                        icon: GzIcons.calendarDots,
                        label: l.clientVisitsConfirmTime,
                        value: context.gzFormat.date(visit.proposedSlotStart!.toIso8601String(), DateStyle.dayMonth),
                        tone: GzFactTone.accent,
                        small: true,
                      ),
                      GzFactChip(
                        icon: GzIcons.clock,
                        label: l.clientVisitsConfirmTime,
                        value: context.gzFormat.time(visit.proposedSlotStart!),
                        tone: GzFactTone.accent,
                        small: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s2),
            GzButton(label: l.clientVisitsConfirmTime, fullWidth: true, onPressed: onConfirmProposed),
          ],
          if (dayOf) ...[
            const SizedBox(height: GzSpace.s2),
            Row(
              children: [
                Expanded(
                  child: GzButton(label: l.clientVisitsOnTheWay, variant: GzButtonVariant.secondary, iconStart: GzIcons.navigate, onPressed: onWay),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzButton(label: l.clientVisitsArrived, iconStart: GzIcons.pin, onPressed: onArrived),
                ),
              ],
            ),
          ],
          if (!changeable && !dayOf) ...[
            const SizedBox(height: GzSpace.s2),
            GzButton(label: l.clientVisitsChooseAnother, variant: GzButtonVariant.secondary, iconStart: GzIcons.calendarPlus, onPressed: onAnother),
          ],
        ],
      ),
    );
  }
}

class _ClosedBar extends StatelessWidget {
  const _ClosedBar({required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s2),
            Expanded(
              child: GzText(l.clientVisitsClosed, role: GzTextRole.bodyS, color: c.textSecondary),
            ),
            GzButton(
              label: l.clientVisitsMessageVenue,
              variant: GzButtonVariant.secondary,
              iconStart: GzIcons.chat,
              onPressed: () => context.gzNav.push('CL-MSGS-02', params: <String, Object?>{'venueId': venueId}),
            ),
          ],
        ),
      ),
    );
  }
}
