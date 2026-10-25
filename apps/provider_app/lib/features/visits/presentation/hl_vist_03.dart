// HL-VIST-03 Visit chat (web `HL-VIST-03.tsx`): the dedicated group chat of one visit as the hotel representative reads it: exactly three roles
// (the client, the hotel representative, a Ghazal support representative), member-only (ADR 0033 D9). The header shows the three role chips (a tap
// opens the member sheet); the visit card is pinned under it with the action for the state; every message carries its sender role. The chat
// closes read-only 24 hours after the slot, or at once on decline or cancel. Requirements: HA-VIS-03, HA-VIS-06, HA-MSG-02, HA-MSG-03, HA-AUTH-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, chatRepositoryProvider, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart'
    show MessageFrom, SendMessageInput, SendMessageInputKind, StaffMember, ThreadMember, ThreadRole, VisitStatus, VisitThread, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/visits_data.dart';
import 'widgets/chat_composer.dart';
import 'widgets/visit_actions.dart';
import 'widgets/visit_chat_bits.dart';

class HlVist03Screen extends ConsumerStatefulWidget {
  const HlVist03Screen({super.key});

  @override
  ConsumerState<HlVist03Screen> createState() => _HlVist03ScreenState();
}

class _HlVist03ScreenState extends ConsumerState<HlVist03Screen> {
  final ScrollController _scroll = ScrollController();
  String? _playing;
  int _shown = -1;
  int _seq = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String conversationId, {String? text, int? seconds}) async {
    final nav = GzNavigatorScope.of(context);
    final gzL = context.gzL10n;
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: conversationId,
            body: SendMessageInput(
              clientMsgId: 'vc-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
              kind: seconds != null ? SendMessageInputKind.voice : SendMessageInputKind.text,
              text: text,
              origin: text == null ? null : (RegExp(r'[؀-ۿ]').hasMatch(text) ? WireLang.ar : WireLang.en),
              voiceSeconds: seconds,
            ),
          );
      if (mounted) ref.read(partnerDataRevisionProvider.notifier).bump();
    } on ApiProblem catch (p) {
      nav.toast(GzToastSpec(message: gzProblemMessage(gzL, p), tone: GzToastTone.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final id = (nav.params['visitId'] as String?) ?? kHeroRequestedVisit;
    final role = ref.watch(visitRoleProvider);
    final now = ref.watch(clockProvider)();
    final value = ref.watch(partnerVisitThreadProvider(id));
    final data = value.value;
    final act = VisitUi(context, ref);
    final see = canSeeVisits(role);
    final members = data?.thread.members ?? const <ThreadMember>[];
    final visit = data?.visit;
    final repId = visit == null ? '' : (ref.watch(representativeOverrideProvider)[visit.id] ?? visit.representativeId);
    final staff = ref.watch(visitStaffProvider).value ?? const <StaffMember>[];
    final rep = staff.where((s) => s.userId == repId).firstOrNull;
    final repName = rep == null ? '' : (lang == 'ar' ? rep.name : rep.nameLatin);
    final me = ref.watch(partnerContextProvider)?.userId;
    final closed = visit != null && visitChatClosed(visit, now);
    // Admin and Manager read every chat; Reception (and anyone else with the visit permission) only the ones they are assigned to.
    final assigned = role.name == 'reception' ? repId == me : true;
    final canWrite = see && !closed && (isVisitLead(role) || assigned);
    final canAct = see && (isVisitLead(role) || assigned);

    final top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTopBar(
          title: l.hotelVisitsChatTitle,
          actions: [
            GzTopBarAction(
              icon: GzIcons.usersThree,
              label: l.hotelVisitsMembersTitle,
              onPressed: members.isEmpty ? null : () => act.members(members, meId: me),
            ),
          ],
        ),
        if (visit != null && members.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(top: GzSpace.s2, bottom: GzSpace.s3),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzParticipantStrip(
                  members: members,
                  meId: me,
                  onOpen: () => act.members(members, meId: me),
                ),
                const SizedBox(height: GzSpace.s3),
                VisitPinned(
                  visit: visit,
                  canAct: canAct,
                  canArrive: canMarkArrived(visit, now, f.isoDay),
                  onOpen: () => act.open(visit),
                  onConfirm: () => act.confirm(visit),
                  onPropose: () => act.propose(visit),
                  onArrived: () => act.arrival(visit),
                ),
              ],
            ),
          ),
      ],
    );

    Widget? bottom;
    if (data != null && see) {
      if (closed) {
        bottom = VisitReadOnlyBar(
          text: visit.status == VisitStatus.declined
              ? l.hotelVisitsChatClosedDeclined
              : (visit.status == VisitStatus.cancelled ? l.hotelVisitsChatClosedCancelled : l.hotelVisitsChatClosedAfter),
        );
      } else if (!canWrite) {
        bottom = VisitReadOnlyBar(text: l.hotelVisitsChatReadOnlyRole);
      } else {
        final convId = data.thread.id;
        bottom = ThreadComposer(
          quick: [
            QuickReply(id: 'confirm', label: l.hotelVisitsQrConfirm, text: l.hotelVisitsQrConfirmText),
            QuickReply(id: 'entrance', label: l.hotelVisitsQrEntrance, text: l.hotelVisitsQrEntranceText),
            QuickReply(id: 'parking', label: l.hotelVisitsQrParking, text: l.hotelVisitsQrParkingText),
          ],
          onSend: (t) => _send(convId, text: t),
          onAttach: act.attach,
          onVoice: (s) => _send(convId, seconds: s),
          onTooShort: () => nav.toast(GzToastSpec(message: l.hotelVisitsRecordHold)),
        );
      }
    }

    final rows = data == null ? const <ChatRow>[] : chatRowsOf(context, data.visit, data.messages, data.thread.id, repName, now);
    if (data != null && rows.length != _shown) {
      _shown = rows.length;
      void toEnd() {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        toEnd();
        WidgetsBinding.instance.addPostFrameCallback((_) => toEnd());
      });
    }

    return GzScreen(
      top: top,
      bottom: bottom,
      controller: _scroll,
      child: !see
          ? GzErrorState(kind: GzErrorKind.noAccess, title: l.hotelVisitsNoAccessTitle, body: l.hotelVisitsNoAccessBody)
          : GzAsyncView<VisitThread>(
              value: value,
              loading: const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzSkeleton(blockSize: 72),
                    SizedBox(height: GzSpace.s3),
                    GzSkeleton(blockSize: 96),
                    SizedBox(height: GzSpace.s3),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 216, blockSize: 72),
                    ),
                    SizedBox(height: GzSpace.s3),
                    GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 160, blockSize: 48),
                  ],
                ),
              ),
              onRetry: () => ref.invalidate(partnerVisitThreadProvider(id)),
              data: (_) {
                final children = <Widget>[];
                String day = '';
                MessageFrom? lastFrom;
                for (var i = 0; i < rows.length; i++) {
                  final m = rows[i].message;
                  final d = f.isoDay(m.at);
                  final head = d != day;
                  day = d;
                  if (head) children.add(GzChatDateDivider(date: m.at.toIso8601String()));
                  final role0 = switch (m.from) {
                    MessageFrom.client => ThreadRole.client,
                    MessageFrom.venue => ThreadRole.hotelRepresentative,
                    MessageFrom.support => ThreadRole.support,
                    _ => null,
                  };
                  final member = role0 == null ? null : memberOf(members, role0);
                  final showSender = member != null && (head || lastFrom != m.from);
                  lastFrom = (m.kind.value == 'system' || m.kind.value == 'visit_card') ? null : m.from;
                  final next = i + 1 < rows.length ? rows[i + 1].message : null;
                  final lastOfRun = next == null || next.from != m.from || next.kind.value == 'system' || f.isoDay(next.at) != d;
                  children.add(
                    GzChatBubble(
                      message: m,
                      side: GzChatSide.hotel,
                      group: m.kind.value == 'system',
                      groupIcon: rows[i].icon,
                      sender: showSender
                          ? GzChatSender(name: lang == 'ar' ? member.name : member.nameLatin, role: member.role, you: member.userId == me)
                          : null,
                      showMeta: lastOfRun,
                      playing: _playing == m.id,
                      onPlay: () => setState(() => _playing = _playing == m.id ? null : m.id),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]],
                      const SizedBox(height: GzSpace.s3),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
