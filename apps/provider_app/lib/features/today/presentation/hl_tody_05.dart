// HL-TODY-05 Conversation (web `HL-TODY-05.tsx`): a real-time conversation with a couple (or Ghazal Support) that always shows the booking it belongs
// to, so staff can answer and decide in one place. Text, photos, documents and voice notes; quick replies; a pinned booking context bar with Accept
// and Decline while the request is pending. The tab bar is hidden while the composer is open (ADR 0008 D2).
// Voucher model (ADR 0033): the quick replies are Availability, Voucher price, Visit invitation and Address; the chat never chases money.
// Requirements: HA-MSG-02..05, HA-BOOK-03, HA-BOOK-04, HA-BOOK-07.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, chatRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, MoneyMode, MoneyOptions, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/request_ui.dart';
import '../application/today_data.dart';
import 'widgets/thread_composer.dart';
import 'widgets/thread_context_bar.dart';

enum _LocalState { sending, failed }

/// A message typed in this run that the server has not confirmed yet (it shows a clock, or a warning with Retry).
class _Local {
  _Local({required this.id, required this.text, required this.seconds}) : state = _LocalState.sending;

  final String id;
  final String? text;
  final int? seconds;
  _LocalState state;
}

class HlTody05Screen extends ConsumerStatefulWidget {
  const HlTody05Screen({super.key});

  @override
  ConsumerState<HlTody05Screen> createState() => _HlTody05ScreenState();
}

class _HlTody05ScreenState extends ConsumerState<HlTody05Screen> {
  final List<_Local> _local = <_Local>[];
  final ScrollController _scroll = ScrollController();
  String? _playing;
  String? _id;
  int _seq = 0;
  bool _markedRead = false;
  int _shownCount = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_id != null) return;
    final params = GzNavigatorScope.of(context).params;
    _id = (params['conversationId'] as String?) ?? (params['support'] == true ? kSupportConversationId : null);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({required String id, String? text, int? seconds, required String clientId}) async {
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            conversationId: id,
            body: SendMessageInput(
              clientMsgId: clientId,
              kind: seconds != null ? SendMessageInputKind.voice : SendMessageInputKind.text,
              text: text,
              origin: text == null ? null : (RegExp(r'[؀-ۿ]').hasMatch(text) ? WireLang.ar : WireLang.en),
              voiceSeconds: seconds,
            ),
          );
      if (!mounted) return;
      ref.read(partnerDataRevisionProvider.notifier).bump();
      setState(() => _local.removeWhere((m) => m.id == clientId));
    } on ApiProblem {
      if (!mounted) return;
      setState(() => _local.where((m) => m.id == clientId).forEach((m) => m.state = _LocalState.failed));
    }
  }

  void _submit(String conversationId, {String? text, int? seconds}) {
    final clientId = 'cm-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    setState(() => _local.add(_Local(id: clientId, text: text, seconds: seconds)));
    _send(id: conversationId, text: text, seconds: seconds, clientId: clientId);
  }

  void _retry(String conversationId, _Local m) {
    setState(() => m.state = _LocalState.sending);
    _send(id: conversationId, text: m.text, seconds: m.seconds, clientId: m.id);
  }

  void _openAttach() {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final c = context.gz.colors;
    nav.openSheetBuilder(
      (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (icon, label) in [(GzIcons.camera, l.hotelTodayAttachCamera), (GzIcons.image, l.hotelTodayAttachPhoto), (GzIcons.document, l.hotelTodayAttachDocument)])
            GzPressable(
              onPressed: () {
                nav.closeSheet();
                // The device picker is a platform plugin the app does not carry yet (requests.md): the row says so instead of failing silently.
                nav.toast(GzToastSpec(message: context.gzL10n.commonStateTitleNetwork));
              },
              semanticLabel: label,
              borderRadius: GzRadius.smAll,
              minHeight: GzSize.controlLg,
              scale: 1,
              child: Container(
                constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                child: Row(
                  children: [
                    Container(
                      width: GzSize.touchMin,
                      height: GzSize.touchMin,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
                      child: GzIcon(icon, size: GzIconSize.md, color: c.iconPrimary),
                    ),
                    const SizedBox(width: GzSpace.s4),
                    GzText(label, role: GzTextRole.body, color: c.textStrong),
                  ],
                ),
              ),
            ),
        ],
      ),
      options: GzSheetOptions(title: l.hotelTodayAttachTitle),
    );
  }

  void _openMenu() {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    nav.openSheetBuilder(
      (sheetContext) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
        child: GzButton(
          label: l.hotelTodayReport,
          variant: GzButtonVariant.secondary,
          fullWidth: true,
          iconStart: GzIcons.warning,
          onPressed: () {
            nav.closeSheet();
            nav.toast(GzToastSpec(message: l.hotelTodayReportSent, tone: GzToastTone.success));
          },
        ),
      ),
      options: GzSheetOptions(title: l.hotelTodayConversationMenu),
    );
  }

  List<QuickReply> _quick(Booking booking, PartnerRequestDetail detail) {
    final l = context.l10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final names = booking.venueId == null ? null : ref.watch(venueNamesProvider(booking.venueId!)).value;
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    return [
      QuickReply(id: 'availability', label: l.hotelTodayQrAvailability, text: l.hotelTodayQrAvailabilityText(f.date(booking.eventDate.toString()))),
      QuickReply(
        id: 'price',
        label: l.hotelTodayQrPrice,
        text: l.hotelTodayQrPriceText(f.guests(guests), f.money(booking.totals.voucherTotal.fils, const MoneyOptions(mode: MoneyMode.exact)), f.money(booking.totals.standardTotal.fils, const MoneyOptions(mode: MoneyMode.exact))),
      ),
      QuickReply(id: 'visit', label: l.hotelTodayQrVisit, text: l.hotelTodayQrVisitText),
      QuickReply(id: 'address', label: l.hotelTodayQrAddress, text: l.hotelTodayQrAddressText(names?.venue.of(lang) ?? '', names?.area?.of(lang) ?? '')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    // A screen opened with only a booking finds its conversation in the inbox; without anything it shows the hero conversation.
    final params = nav.params;
    var id = _id;
    if (id == null) {
      final bookingId = params['bookingId'] as String?;
      final entries = ref.watch(inboxProvider).value;
      if (bookingId != null && entries != null) id = entries.where((e) => e.conversation.bookingId == bookingId).firstOrNull?.conversation.id;
      id ??= bookingId == null ? kHeroConversationId : null;
    }
    final value = id == null ? const AsyncValue<ThreadData>.loading() : ref.watch(threadProvider(id));
    final readOnly = params['readOnly'] == true;
    final data = value.value;
    final conv = data?.conversation;
    final support = conv?.kind == ConversationKind.support;
    final name = conv == null ? '' : (support ? conv.title.of(lang) : conv.clientName);
    final bookingId = conv?.bookingId;
    final detail = (!support && bookingId != null) ? ref.watch(requestDetailProvider(bookingId)).value : null;

    if (data != null && !_markedRead && id != null && data.conversation.unread.hotel > 0 && data.messages.isNotEmpty) {
      _markedRead = true;
      final last = data.messages.where((m) => !m.draft).lastOrNull;
      if (last != null) {
        final cid = id;
        Future.microtask(() async {
          await ref.read(chatRepositoryProvider).markConversationRead(conversationId: cid, body: ReadMarkerInput(upToSeq: last.seq));
          if (mounted) ref.read(partnerDataRevisionProvider.notifier).bump();
        });
      }
    }

    final count = (data?.messages.length ?? 0) + _local.length;
    if (data != null && count != _shownCount) {
      _shownCount = count;
      void toEnd() {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        toEnd();
        WidgetsBinding.instance.addPostFrameCallback((_) => toEnd());
      });
    }

    final canCall = detail?.booking.contact.shared == true && !support;
    final request = detail == null ? null : RequestUi(context, ref);
    final top = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTopBar(
          title: name,
          actions: [
            if (canCall) GzTopBarAction(icon: GzIcons.phone, label: l.hotelTodayCallClient(name), onPressed: () => nav.openSheet('HL-BOOK-04', options: GzSheetOptions(params: {'bookingId': bookingId}))),
            GzTopBarAction(icon: GzIcons.moreVertical, label: l.hotelTodayConversationMenu, onPressed: _openMenu),
          ],
        ),
        if (detail != null)
          ThreadContextBar(
            request: detail,
            now: now,
            readOnly: readOnly,
            onOpen: () => nav.push('HL-BOOK-03', params: {'bookingId': detail.booking.id}),
            onAccept: () => request!.acceptDetail(detail),
            onDecline: () => request!.declineDetail(detail),
          ),
      ],
    );

    final quick = detail == null ? const <QuickReply>[] : _quick(detail.booking, detail);
    final Widget? bottom = readOnly
        ? Container(
            padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s4 + MediaQuery.paddingOf(context).bottom),
            color: c.surfaceQuiet,
            child: Row(children: [GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary), const SizedBox(width: GzSpace.s3), GzText(l.hotelTodayReadOnly, role: GzTextRole.bodyS)]),
          )
        : (data == null
            ? null
            : ThreadComposer(
                quick: quick,
                onSend: (text) => _submit(id!, text: text),
                onAttach: _openAttach,
                onVoice: (s) => _submit(id!, seconds: s),
                onTooShort: () => nav.toast(GzToastSpec(message: l.hotelTodayRecordHold)),
              ));

    Message localMessage(_Local m) => Message(
          id: m.id,
          conversationId: id ?? '',
          seq: 1 << 30,
          from: MessageFrom.venue,
          senderName: null,
          at: now,
          kind: m.seconds != null ? MessageKind.voice : MessageKind.text,
          text: m.text == null ? null : LocalizedText.same(m.text!),
          origin: RegExp(r'[؀-ۿ]').hasMatch(m.text ?? '') ? WireLang.ar : WireLang.en,
          voice: m.seconds == null ? null : MessageVoice(seconds: m.seconds!),
          status: MessageStatus.sent,
          draft: false,
        );

    return GzScreen(
      top: top,
      bottom: bottom,
      controller: _scroll,
      child: GzAsyncView<ThreadData>(
        value: value,
        isEmpty: (d) => d.messages.isEmpty && _local.isEmpty,
        loading: const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 248, blockSize: 72),
              SizedBox(height: GzSpace.s3),
              Align(alignment: AlignmentDirectional.centerEnd, child: GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 216, blockSize: 72)),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 160, blockSize: 48),
            ],
          ),
        ),
        empty: GzEmptyState(illustration: GzIllustrationName.emptyMessages, title: l.hotelTodayThreadEmptyTitle),
        onRetry: () {
          if (id != null) ref.invalidate(threadProvider(id));
        },
        data: (d) {
          String day = '';
          var prevDraft = false;
          final children = <Widget>[];
          final all = [for (final m in d.messages) (message: m, local: null as _Local?), for (final m in _local) (message: localMessage(m), local: m as _Local?)];
          for (final row in all) {
            final m = row.message;
            final dd = f.isoDay(m.at);
            if (dd != day) {
              children.add(GzChatDateDivider(date: m.at.toIso8601String()));
              day = dd;
            }
            final firstDraft = m.draft && !prevDraft;
            prevDraft = m.draft;
            if (firstDraft) {
              children.add(
                Row(
                  children: [
                    GzIcon(GzIcons.edit, size: GzIconSize.xs, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    GzText(l.hotelTodayDraftTag, role: GzTextRole.caption, color: c.textSecondary),
                  ],
                ),
              );
            }
            final local = row.local;
            children.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzChatBubble(
                    message: m,
                    side: GzChatSide.hotel,
                    showMeta: !m.draft && local == null,
                    playing: _playing == m.id,
                    onPlay: () => setState(() => _playing = _playing == m.id ? null : m.id),
                  ),
                  if (local != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(local.state == _LocalState.failed ? GzIcons.warningCircle : GzIcons.clock, size: GzIconSize.xs, color: local.state == _LocalState.failed ? c.iconDanger : c.iconSecondary),
                          if (local.state == _LocalState.failed) GzButton(label: context.gzL10n.commonActionRetry, variant: GzButtonVariant.tertiary, onPressed: () => _retry(id!, local)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // The web list ends with a zero-height anchor the flex gap still counts.
              children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]], const SizedBox(height: GzSpace.s3)],
            ),
          );
        },
      ),
    );
  }
}
