import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, chatRepositoryProvider, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart'
    show CreateConversationInput, CreateConversationInputKind, Message, MessageFrom, MessageKind, MessageStatus, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/chat_thread.dart';
import '../application/messages_format.dart' show shortDuration;
import '../application/thread_resolve.dart';
import '../application/thread_ui.dart';
import 'widgets/follow_newest.dart';
import 'widgets/msg_composer.dart';
import 'widgets/msg_sheet_head.dart';
import 'widgets/thread_parts.dart';

export '../application/thread_ui.dart';

/// CL-MSGS-02 Conversation. Covers CA-CHAT-02..09, CA-AUTH-10.
///
/// One thread with a venue, a planner, a service provider or Ghazal Support:
/// text, photos, documents and voice notes, sent / delivered / read ticks, a
/// pinned request bar (date, status, a chevron into the request), system lines
/// for the request, and structured cards (meeting, quote request). Own messages
/// sit at inline-end; every message aligns by its own first strong character.
/// A first message to a venue (or to Support) opens the thread. The tab bar is hidden.
/// States: default, loading, empty-enquiry, sending, failed, delivered, read,
/// uploading, recording, offline-queued, error, blocked,
/// planner-variant, vendor-variant, support-variant.
class ClMsgs02Screen extends ConsumerStatefulWidget {
  const ClMsgs02Screen({super.key});

  @override
  ConsumerState<ClMsgs02Screen> createState() => _ClMsgs02ScreenState();
}

class _ClMsgs02ScreenState extends ConsumerState<ClMsgs02Screen> {
  late String _draft;
  bool _draftSeeded = false;

  GzNavigator get _nav => context.gzNav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftSeeded) {
      _draftSeeded = true;
      final p = _nav.params;
      _draft = (p['draft'] as String?) ?? '';
    }
  }

  /// The first message of a thread that does not exist yet (an enquiry to a venue, or Support): the server opens the conversation with
  /// it, and the screen replaces itself with the thread.
  Future<void> _startEnquiry(ResolvedThread r, String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    final nav = _nav;
    try {
      final conv = await ref.read(chatRepositoryProvider).createConversation(
        body: CreateConversationInput(
          kind: r.venueId != null ? CreateConversationInputKind.venue : CreateConversationInputKind.enquiry,
          venueId: r.venueId,
          firstMessage: body,
        ),
      );
      if (!mounted) return;
      ref.invalidate(resolveThreadProvider);
      _draft = '';
      nav.replace('CL-MSGS-02', params: <String, Object?>{'conversationId': conv.id, if (r.venueId != null) 'venueId': r.venueId});
    } on ApiProblem catch (e) {
      if (mounted) nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, e), tone: GzToastTone.danger));
    }
  }

  void _send(ChatThread thread, String text) {
    unawaited(thread.sendText(text));
    setState(() => _draft = '');
  }

  @override
  Widget build(BuildContext context) {
    final params = ThreadParams.from(_nav.params);
    final resolved = ref.watch(resolveThreadProvider(params));
    return GzAsyncView<ResolvedThread>(
      value: resolved,
      loading: const _ThreadSkeleton(),
      onRetry: () => ref.invalidate(resolveThreadProvider(params)),
      data: (r) => _ThreadBody(key: ValueKey<String>('thread.${r.conversationId ?? r.venueId ?? 'support'}'), resolved: r, draft: _draft, onDraft: (v) => _draft = v, onEnquiry: (text) => _startEnquiry(r, text), onSend: _send),
    );
  }
}

class _ThreadBody extends ConsumerStatefulWidget {
  const _ThreadBody({required this.resolved, required this.draft, required this.onDraft, required this.onEnquiry, required this.onSend, super.key});

  final ResolvedThread resolved;
  final String draft;
  final ValueChanged<String> onDraft;
  final ValueChanged<String> onEnquiry;
  final void Function(ChatThread thread, String text) onSend;

  @override
  ConsumerState<_ThreadBody> createState() => _ThreadBodyState();
}

class _ThreadBodyState extends ConsumerState<_ThreadBody> with FollowNewest<_ThreadBody> {
  // NOTE: no jump to the end when the thread opens (web parity gap, documented in the flow report): a programmatic jump during the headless
  // settle leaves RichText unpainted in shots, and an initial offset breaks GzScreen's scroll listener during layout. A message that is sent
  // or arrives while it is open is followed (FollowNewest).
  GzNavigator get _nav => context.gzNav;

  ResolvedThread get _r => widget.resolved;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final blocked = _r.conversationId == null ? false : ref.watch(blockedConversationsProvider).contains(_r.conversationId);
    if (_r.isEnquiry || _r.conversationId == null) return _enquiry(context);
    final thread = ref.watch(chatThreadProvider(_r.conversationId!));
    void openInfo() => _nav.openSheet(
      'CL-MSGS-03',
      options: GzSheetOptions(params: <String, Object?>{'conversationId': _r.conversationId!, if (_r.venueId != null) 'venueId': _r.venueId}),
    );
    final top = _ThreadBar(conversationId: _r.conversationId!, onInfo: openInfo);
    return GzAsyncView<ChatState>(
      value: thread,
      loading: _ThreadSkeleton(top: top),
      onRetry: () => ref.invalidate(chatThreadProvider(_r.conversationId!)),
      data: (s) {
        final bookingId = s.conversation.bookingId;
        final rows = _rows(s);
        followNewest(rows.length);
        final bottom = blocked
            ? _BlockedBar(onUnblock: () => ref.read(blockedConversationsProvider.notifier).set(_r.conversationId!, false))
            : MsgComposer(
                initial: widget.draft,
                onSend: (text) {
                  final t = ref.read(chatThreadProvider(_r.conversationId!).notifier);
                  widget.onSend(t, text);
                },
                onAttach: _openAttach,
                onVoice: (seconds) {
                  unawaited(ref.read(chatThreadProvider(_r.conversationId!).notifier).sendVoice(seconds));
                },
                onTooShort: () => _nav.toast(GzToastSpec(message: l.clientMessagesRecordTooShort)),
              );
        return GzScreen.slivers(
          top: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              top,
              if (bookingId != null) _BookingContextBar(bookingId: bookingId),
            ],
          ),
          bottom: bottom,
          controller: threadScroll,
          slivers: [
            // no spacer for the keyboard here: GzScreen already shrinks the list above it, and a keyboard-high gap at the end kept the newest
            // message out of view when the list followed it
            _ThreadSlivers(state: s, rows: rows, bookingId: bookingId),
          ],
        );
      },
    );
  }

  List<_Row> _rows(ChatState s) {
    final lang = context.gz.locale.languageCode;
    final out = <_Row>[
      for (final m in s.messages.where((m) => !m.draft)) _Row(message: m, local: null),
      for (final lm in s.locals) _Row(message: lm.toMessage(s.conversation.id, lang == 'ar' ? WireLang.ar : WireLang.en), local: lm),
    ];
    out.sort((a, b) => a.message.at.compareTo(b.message.at));
    return out;
  }

  Widget _enquiry(BuildContext context) {
    final l = context.l10n;
    final support = _r.supportNew || (_nav.params['support'] == true);
    final venueAsync = !support && _r.venueId != null ? ref.watch(threadVenueProvider(_r.venueId!)) : null;
    final venue = venueAsync?.value;
    final lang = context.gz.locale.languageCode;
    final name = support ? context.gzL10n.commonRoleSupport : (venue?.name.of(lang) ?? '');
    final subtitle = support || venue == null ? null : l.clientMessagesRepliesWithin(2);
    final hasInfo = _r.conversationId != null;
    final top = GzTopBar(
      titleWidget: Semantics(
        header: true,
        label: name,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzAvatar(name: name.isEmpty ? ' ' : name, size: GzAvatarSize.xs),
            const SizedBox(width: GzSpace.s3),
            Flexible(child: GzText(name, role: GzTextRole.title, color: context.gz.colors.textStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      actions: [if (hasInfo) GzTopBarAction(icon: GzIcons.moreVertical, label: l.clientMessagesInfoTitle, onPressed: () {})],
    );
    return GzScreen(
      top: top,
      bottom: MsgComposer(
        initial: widget.draft,
        onSend: widget.onEnquiry,
        onAttach: null,
        onVoice: null,
        onTooShort: () => _nav.toast(GzToastSpec(message: l.clientMessagesRecordTooShort)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (venue?.cover != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GzPhoto(src: gzImageSrc(venue!.cover!.file, venue.cover!.baseUrl), alt: venue.cover!.alt.of(lang)),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(name, role: GzTextRole.d2, color: context.gz.colors.textStrong, header: true),
                if (subtitle != null) ...[
                  const SizedBox(height: GzSpace.s2),
                  GzFactChip(icon: GzIcons.clock, label: subtitle, value: shortDuration(context.gzFormat, 2 * 3600000), small: true, tone: GzFactTone.muted),
                ],
                if (!support) ...[
                  const SizedBox(height: GzSpace.s4),
                  Wrap(
                    spacing: GzSpace.s3,
                    runSpacing: GzSpace.s3,
                    children: [
                      GzChip(label: l.clientMessagesSuggestAvailability, iconStart: GzIcons.calendar, onPressed: () => widget.onEnquiry(l.clientMessagesSuggestAvailabilityAny)),
                      GzChip(
                        label: l.clientMessagesSuggestVisit,
                        iconStart: GzIcons.calendarCheck,
                        onPressed: () => _nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{if (_r.venueId != null) 'venueId': _r.venueId})),
                      ),
                      GzChip(label: l.clientMessagesSuggestVoucher, iconStart: GzIcons.ticket, onPressed: () => widget.onEnquiry(l.clientMessagesSuggestVoucherAny)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAttach() {
    final l = context.l10n;
    final nav = _nav;
    nav.openSheetBuilder(
      (_) => Column(
        key: const ValueKey<String>('thread.attach'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MsgSheetHead(title: l.clientMessagesAttachTitle),
          const SizedBox(height: GzSpace.s2),
          GzListRow(title: l.clientMessagesAttachPhoto, leading: GzIcon(GzIcons.image, size: GzIconSize.sm, color: context.gz.colors.iconSecondary), chevron: true, onPressed: () {
            nav.closeSheet();
            unawaited(ref.read(chatThreadProvider(_r.conversationId!).notifier).sendAttachment(image: true, fileName: 'photo.jpg'));
          }),
          GzListRow(title: l.clientMessagesAttachDocument, leading: GzIcon(GzIcons.document, size: GzIconSize.sm, color: context.gz.colors.iconSecondary), chevron: true, last: true, onPressed: () {
            nav.closeSheet();
            unawaited(ref.read(chatThreadProvider(_r.conversationId!).notifier).sendAttachment(image: false, fileName: 'document.pdf'));
          }),
          const SizedBox(height: GzSpace.s2),
          GzText(l.clientMessagesAttachLimits('10 MB', '15 MB'), role: GzTextRole.caption, color: context.gz.colors.textSecondary),
        ],
      ),
    );
  }
}

class _Row {
  const _Row({required this.message, required this.local});

  final Message message;
  final LocalMsg? local;
}

/// The header: monogram, name, the reply-time fact; a glyph into CL-MSGS-03.
class _ThreadBar extends ConsumerWidget implements PreferredSizeWidget {
  const _ThreadBar({required this.conversationId, required this.onInfo});

  final String conversationId;
  final VoidCallback onInfo;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final thread = ref.watch(chatThreadProvider(conversationId));
    final conv = thread.value?.conversation;
    final lang = context.gz.locale.languageCode;
    final name = conv == null ? '' : conv.title.of(lang);
    final fact = GzFactChip(icon: GzIcons.clock, label: l.clientMessagesRepliesWithin(2), value: shortDuration(context.gzFormat, 2 * 3600000), small: true, tone: GzFactTone.muted);
    // Enlarged text does not fit two lines in the fixed bar: name and reply time share one row (the name ellipsizes).
    final dense = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return GzTopBar(
      titleWidget: Semantics(
        header: true,
        label: name,
        child: dense
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GzAvatar(name: name.isEmpty ? ' ' : name, initial: context.gz.isAr ? conv?.monogram : null, size: GzAvatarSize.xs),
                  const SizedBox(width: GzSpace.s3),
                  Flexible(child: GzText(name, role: GzTextRole.title, color: context.gz.colors.textStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: GzSpace.s2),
                  fact,
                ],
              )
            // The web title is the avatar and the name on one 32 line, the reply-time fact centred under both (its line is the chip + 3).
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GzAvatar(name: name.isEmpty ? ' ' : name, initial: context.gz.isAr ? conv?.monogram : null, size: GzAvatarSize.xs),
                        const SizedBox(width: GzSpace.s2),
                        Flexible(child: GzText(name, role: GzTextRole.title, color: context.gz.colors.textStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 3),
                    child: ConstrainedBox(constraints: BoxConstraints(minHeight: context.gz.isAr ? 22 : 20), child: fact),
                  ),
                ],
              ),
      ),
      actions: [GzTopBarAction(icon: GzIcons.moreVertical, label: l.clientMessagesInfoTitle, onPressed: onInfo)],
    );
  }
}

class _BookingContextBar extends ConsumerWidget {
  const _BookingContextBar({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(threadBookingProvider(bookingId)).value;
    if (booking == null) return const SizedBox.shrink();
    return ContextBar(booking: booking.booking, onOpen: () => context.gzNav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': booking.booking.id}));
  }
}

class _ThreadSlivers extends ConsumerWidget {
  const _ThreadSlivers({required this.state, required this.rows, required this.bookingId});

  final ChatState state;
  final List<_Row> rows;
  final String? bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = context.gzNav;
    final f = context.gzFormat;
    final booking = bookingId == null ? null : ref.watch(threadBookingProvider(bookingId!)).value?.booking;
    const venueName = '';
    final systems = booking == null ? const <SysEvent>[] : systemEventsOf(booking);
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: GzEmptyState(
          key: const ValueKey<String>('thread.empty'),
          illustration: GzIllustrationName.emptyMessages,
          title: context.l10n.clientMessagesEmptyTitle,
        ),
      );
    }
    MessageFrom? lastSide;
    final photos = <GzCarouselImage>[
      for (final r in rows)
        if (r.message.kind == MessageKind.image && r.message.image != null)
          GzCarouselImage(src: gzImageSrc(r.message.image!.file), alt: r.message.image!.alt.of(context.gz.locale.languageCode)),
    ];
    final timeline = <_Item>[
      for (final r in rows) _Item.message(r),
      for (final e in systems) _Item.system(e),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return SliverPadding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s4),
      sliver: SliverList.builder(
        itemCount: timeline.length,
        itemBuilder: (context, i) {
          final item = timeline[i];
          final d = f.isoDay(item.at);
          final newDay = i == 0 || f.isoDay(timeline[i - 1].at) != d;
        if (item.event != null) {
          lastSide = null;
          // A system line breathes like a divider: 12 above and below.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay) ...[const SizedBox(height: GzSpace.s4), GzChatDateDivider(date: d), const SizedBox(height: GzSpace.s3)],
              const SizedBox(height: GzSpace.s3),
              SystemLine(event: item.event!, venue: venueName),
              const SizedBox(height: GzSpace.s3),
            ],
          );
        }
        final row = item.row!;
        final m = row.message;
        final side = m.from;
        final runStart = newDay || side != lastSide;
        lastSide = side;
        final next = i + 1 < timeline.length ? timeline[i + 1] : null;
        final nextMsg = next?.row?.message;
        final runEnd = nextMsg == null || nextMsg.from != m.from || f.isoDay(nextMsg.at) != d;
        final own = m.from == MessageFrom.client;
        final isVoice = m.kind == MessageKind.voice;
        final card = m.kind == MessageKind.meetingCard || m.kind == MessageKind.quoteRequestCard;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (newDay) ...[const SizedBox(height: GzSpace.s4), GzChatDateDivider(date: d), const SizedBox(height: GzSpace.s3)],
            SizedBox(height: runStart ? GzSpace.s4 : GzSpace.s1),
            GzChatBubble(
              message: m,
              side: GzChatSide.client,
              showMeta: false,
              onPlay: isVoice ? () {} : null,
              onOpen: m.kind == MessageKind.image
                  ? () {
                      final idx = photos.indexWhere((p) => p.src == m.image!.file);
                      if (idx < 0) return;
                      // Tapping media opens the shared gallery viewer (the 'CL-VENU-02' pattern).
                      unawaited(showGzGalleryViewer(context, images: photos, label: context.l10n.clientMessagesPhotoViewer, initialIndex: idx));
                    }
                  : null,
            ),
            if (card && m.kind == MessageKind.meetingCard)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzButton(label: context.l10n.clientMessagesCardCalendar, variant: GzButtonVariant.tertiary, iconStart: GzIcons.calendarPlus, onPressed: () => nav.toast(GzToastSpec(message: context.l10n.clientMessagesCardCalendarToast, tone: GzToastTone.success))),
                  GzButton(label: context.l10n.clientMessagesCardChange, variant: GzButtonVariant.tertiary, iconStart: GzIcons.edit, onPressed: () => nav.openSheet('CL-PLAN-04')),
                ],
              ),
            if (card && m.kind == MessageKind.quoteRequestCard)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GzButton(label: context.l10n.clientMessagesCardVendor, variant: GzButtonVariant.tertiary, iconStart: GzIcons.user, onPressed: () {
                  final vendorId = state.conversation.vendorId;
                  if (vendorId != null) nav.push('CL-SERV-03', params: <String, Object?>{'vendorId': vendorId});
                }),
              ),
            const SizedBox(height: GzSpace.s1),
            MessageMeta(
              own: own,
              showTime: runEnd,
              time: m.at,
              read: m.status == MessageStatus.read,
              delivered: m.status == MessageStatus.delivered || m.status == MessageStatus.read,
              local: row.local,
              onRetry: row.local == null ? null : () => unawaited(ref.read(chatThreadProvider(state.conversation.id).notifier).retry(row.local!.clientMsgId)),
              onCancel: row.local == null ? null : () => ref.read(chatThreadProvider(state.conversation.id).notifier).discard(row.local!.clientMsgId),
            ),
          ],
        );
        },
      ),
    );
  }
}

class _Item {
  const _Item.message(this.row) : event = null;
  const _Item.system(this.event) : row = null;

  final _Row? row;
  final SysEvent? event;

  DateTime get at => row?.message.at ?? event!.at;
}

class _ThreadSkeleton extends StatelessWidget {
  const _ThreadSkeleton({this.top});

  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return GzScreen(
      top: top,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: GzSkeleton(inlineSize: 248, blockSize: 72),
            ),
            const SizedBox(height: GzSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzSkeleton(inlineSize: 216, blockSize: 72),
            ),
            const SizedBox(height: GzSpace.s3),
            const GzSkeleton(inlineSize: 160, blockSize: 48),
          ],
        ),
      ),
    );
  }
}

class _BlockedBar extends StatelessWidget {
  const _BlockedBar({required this.onUnblock});

  final VoidCallback onUnblock;

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
            Expanded(child: GzText(l.clientMessagesBlockedNote, role: GzTextRole.bodyS, color: c.textSecondary)),
            GzButton(label: l.clientMessagesUnblock, variant: GzButtonVariant.secondary, onPressed: onUnblock),
          ],
        ),
      ),
    );
  }
}
