import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, chatRepositoryProvider, visitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Message, MessageFrom, MessageKind, SendMessageInput, SendMessageInputKind, ThreadMember, ThreadRole, VisitAppointment, VisitProposalAnswer, VisitStatus, VisitThread, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import 'widgets/visit_composer.dart';
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
      loading: const _VisitChatSkeleton(),
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
        body: SendMessageInput(clientMsgId: 'c${DateTime.now().microsecondsSinceEpoch}', kind: SendMessageInputKind.text, text: text, origin: WireLang.en),
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
          _PinnedCard(thread: widget.thread, meId: meId, members: members, onMembers: () => _openMembers(members, meId, venueName), onAnother: () => _nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{'venueId': visit.venueId})), onChange: () => _nav.openSheet('CL-VIST-05', options: GzSheetOptions(params: <String, Object?>{'visitId': visit.id})), onConfirmProposed: _confirmProposed, onWay: () => _sendText(l.clientVisitsTapOnTheWay), onArrived: () => _sendText(l.clientVisitsTapArrived)),
        ],
      ),
      bottom: bottom,
      slivers: [_ThreadSlivers(thread: widget.thread, meId: meId)],
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
              Expanded(child: GzText(l.clientVisitsMembersTitle, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true)),
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
  const _PinnedCard({required this.thread, required this.meId, required this.members, required this.onMembers, required this.onChange, required this.onAnother, required this.onConfirmProposed, required this.onWay, required this.onArrived});

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
    final changeable = visit.status == VisitStatus.requested || visit.status == VisitStatus.confirmed || visit.status == VisitStatus.rescheduleProposed;
    final dayOf = changeable && f.isoDay(visit.slotStart) == f.isoDay(ref.watch(clockProvider)());
    return Container(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
      decoration: BoxDecoration(color: c.surfaceCanvas, border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: _card(context, ref, l, c, visit, members, changeable, dayOf),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, AppL10n l, GzColors c, VisitAppointment visit, List<ThreadMember> members, bool changeable, bool dayOf) {
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
                Expanded(
                  child: Semantics(
                    container: true,
                    label: l.clientVisitsPinLabel,
                    child: Row(
                      children: [
                        GzStatusPill(status: statusOfVisitLocal(visit.status)),
                        const SizedBox(width: GzSpace.s3),
                        Expanded(child: MemberDiscs(members: members, meId: meId, onOpen: onMembers)),
                      ],
                    ),
                  ),
                ),
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
                      GzFactChip(icon: GzIcons.calendarDots, label: l.clientVisitsConfirmTime, value: context.gzFormat.date(visit.proposedSlotStart!.toIso8601String(), DateStyle.dayMonth), tone: GzFactTone.accent, small: true),
                      GzFactChip(icon: GzIcons.clock, label: l.clientVisitsConfirmTime, value: context.gzFormat.time(visit.proposedSlotStart!), tone: GzFactTone.accent, small: true),
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
                Expanded(child: GzButton(label: l.clientVisitsOnTheWay, variant: GzButtonVariant.secondary, iconStart: GzIcons.navigate, onPressed: onWay)),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzButton(label: l.clientVisitsArrived, iconStart: GzIcons.pin, onPressed: onArrived)),
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
      decoration: BoxDecoration(color: c.surfaceCanvas, border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s2),
            Expanded(child: GzText(l.clientVisitsClosed, role: GzTextRole.bodyS, color: c.textSecondary)),
            GzButton(label: l.clientVisitsMessageVenue, variant: GzButtonVariant.secondary, iconStart: GzIcons.chat, onPressed: () => context.gzNav.push('CL-MSGS-02', params: <String, Object?>{'venueId': venueId})),
          ],
        ),
      ),
    );
  }
}

class _ThreadSlivers extends StatelessWidget {
  const _ThreadSlivers({required this.thread, required this.meId});

  final VisitThread thread;
  final String? meId;

  /// A system line says what happened in a few words (the seeded and the store's lines are full sentences).
  String _shortLine(BuildContext context, Message m) {
    final l = context.l10n;
    if (m.kind == MessageKind.visitCard) return l.clientVisitsSysConfirmed;
    final en = (m.text?.en ?? '').toLowerCase();
    if (en.contains('group chat opened')) return l.clientVisitsSysOpened;
    if (en.contains('could not offer')) return l.clientVisitsSysDeclined;
    if (en.contains('cancelled')) return l.clientVisitsSysCancelled;
    if (en.contains('arrival confirmed')) return l.clientVisitsSysArrived;
    if (en.contains('visit is complete')) return l.clientVisitsSysCompleted;
    if (en.contains('missed')) return l.clientVisitsSysMissed;
    if (en.contains('read-only')) return l.clientVisitsSysClosed;
    if (en.contains('hotel confirmed your visit')) return l.clientVisitsSysConfirmed;
    return m.text?.of(context.gz.locale.languageCode) ?? '';
  }

  /// The glyph of a system line: what happened, read from the seeded English line (the web `systemIcon`).
  IconData _systemIcon(Message m) {
    final key = '${m.id} ${m.text?.en ?? ''}'.toLowerCase();
    if (RegExp('cancel|declin|could not offer').hasMatch(key)) return GzIcons.close;
    if (RegExp('closed|read-only').hasMatch(key)) return GzIcons.lock;
    if (RegExp('arriv').hasMatch(key)) return GzIcons.pin;
    if (RegExp('complete|visit is done').hasMatch(key)) return GzIcons.checkDouble;
    if (RegExp('propos|asked').hasMatch(key)) return GzIcons.calendarDots;
    if (RegExp('missed').hasMatch(key)) return GzIcons.userMinus;
    if (RegExp('confirm').hasMatch(key) || m.kind == MessageKind.visitCard) return GzIcons.calendarCheck;
    return GzIcons.usersThree;
  }

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final messages = thread.messages.where((m) => !m.draft).toList();
    if (messages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
          child: GzEmptyState(fill: false, illustration: GzIllustrationName.emptyMessages, title: context.l10n.clientVisitsSysOpened),
        ),
      );
    }
    String? lastKey;
    return SliverPadding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s4),
      sliver: SliverList.builder(
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final d = f.isoDay(m.at);
          final newDay = i == 0 || f.isoDay(messages[i - 1].at) != d;
          final sys = m.kind == MessageKind.system || m.kind == MessageKind.visitCard;
          final key = sys ? 'system' : m.from.value;
          final runStart = newDay || key != lastKey || lastKey == 'system';
          lastKey = key;
          final next = i + 1 < messages.length ? messages[i + 1] : null;
          final nextKey = next == null ? null : (next.kind == MessageKind.system || next.kind == MessageKind.visitCard) ? 'system' : next.from.value;
          final runEnd = nextKey != key || (next != null && f.isoDay(next.at) != d);
          final own = !sys && m.from == MessageFrom.client;
          ThreadMember? member;
          if (!sys && !own) {
            final role = m.from == MessageFrom.venue ? ThreadRole.hotelRepresentative : ThreadRole.support;
            member = thread.thread.members?.where((x) => x.role == role).firstOrNull;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay) ...[const SizedBox(height: GzSpace.s4), GzChatDateDivider(date: d), if (sys) const SizedBox(height: GzSpace.s3)],
              if (sys) ...[
                const SizedBox(height: GzSpace.s3),
                _SystemLine(text: _shortLine(context, m), icon: _systemIcon(m)),
                const SizedBox(height: GzSpace.s3),
              ] else ...[
                SizedBox(height: runStart ? GzSpace.s4 : GzSpace.s1),
                if (member != null) _SenderLine(member: member, lang: lang),
                GzChatBubble(message: m, side: GzChatSide.client, showMeta: runEnd),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              Flexible(child: GzText(text, role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SenderLine extends StatelessWidget {
  const _SenderLine({required this.member, required this.lang});

  final ThreadMember member;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final short = member.role == ThreadRole.hotelRepresentative ? l.clientVisitsRoleHotel : l.clientVisitsRoleSupport;
    final full = member.role == ThreadRole.hotelRepresentative ? context.gzL10n.commonRoleHotelRep : context.gzL10n.commonRoleSupport;
    final name = lang == 'ar' ? member.name : member.nameLatin;
    final (Color bg, Color? border, Color fg) = member.role == ThreadRole.hotelRepresentative
        ? (c.statusNeutralBg, null, c.statusNeutralText)
        : (c.surfaceTint, null, c.textStrong);
    return Semantics(
      container: true,
      label: '$name, $full',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s1),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(color: bg, borderRadius: GzRadius.xsAll, border: Border.all(color: border ?? c.scrimClear, width: GzStroke.hair)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.pillMin),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + GzStroke.hair, vertical: GzSpace.s1 + GzStroke.hair),
                  child: GzText(short, role: GzTextRole.pill, color: fg, softWrap: false, overflow: TextOverflow.visible),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

class _VisitChatSkeleton extends StatelessWidget {
  const _VisitChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          GzSkeleton(blockSize: 112),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(inlineSize: 248, blockSize: 72),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(inlineSize: 216, blockSize: 72),
        ],
      ),
    );
  }
}
