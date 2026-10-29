import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart' show ConversationKind, Message, MessageKind;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/chat_thread.dart';
import '../application/messages_format.dart' show messageText;
import '../application/thread_resolve.dart';
import '../application/thread_ui.dart';
import 'widgets/msg_sheet_head.dart';
import 'widgets/msg_info_parts.dart';

/// CL-MSGS-03 Conversation details (sheet over the conversation).
/// Covers CA-CHAT-11.
///
/// Who you are talking to, the linked booking, shared media and the safety
/// actions: report a message and block a conversation. Support threads and
/// visit group chats cannot be blocked.
/// States: default, report-select, block-confirm, reported, blocked, error,
/// offline.
class ClMsgs03Screen extends ConsumerStatefulWidget {
  const ClMsgs03Screen({super.key});

  @override
  ConsumerState<ClMsgs03Screen> createState() => _ClMsgs03ScreenState();
}

enum _Step { main, pick, reason, reported, blocked }

class _ClMsgs03ScreenState extends ConsumerState<ClMsgs03Screen> {
  _Step _step = _Step.main;
  String? _picked;
  String? _reason;
  String _note = '';

  GzNavigator get _nav => context.gzNav;

  @override
  Widget build(BuildContext context) {
    final p = ThreadParams.from(_nav.params);
    final resolved = ref.watch(resolveThreadProvider(p));
    return GzAsyncView<ResolvedThread>(
      value: resolved,
      loading: const _InfoSkeleton(),
      onRetry: () => ref.invalidate(resolveThreadProvider(p)),
      data: (r) {
        if (r.conversationId == null) {
          return Column(
            key: const ValueKey<String>('thread.info.empty'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [MsgSheetHead(title: context.l10n.clientMessagesInfoTitle, onClose: () => _nav.closeSheet())],
          );
        }
        return _InfoBody(
          conversationId: r.conversationId!,
          venueId: r.venueId,
          step: _step,
          picked: _picked,
          reason: _reason,
          note: _note,
          onStep: (s) => setState(() => _step = s),
          onPicked: (v) => setState(() => _picked = v),
          onReason: (v) => setState(() => _reason = v),
          onNote: (v) => setState(() => _note = v),
        );
      },
    );
  }
}

class _InfoBody extends ConsumerWidget {
  // Opened as a sheet over the thread: closing it returns to 'CL-MSGS-02'.
  const _InfoBody({
    required this.conversationId,
    required this.venueId,
    required this.step,
    required this.picked,
    required this.reason,
    required this.note,
    required this.onStep,
    required this.onPicked,
    required this.onReason,
    required this.onNote,
  });

  final String conversationId;
  final String? venueId;
  final _Step step;
  final String? picked;
  final String? reason;
  final String note;
  final ValueChanged<_Step> onStep;
  final ValueChanged<String?> onPicked;
  final ValueChanged<String?> onReason;
  final ValueChanged<String> onNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    final thread = ref.watch(chatThreadProvider(conversationId));
    final conv = thread.value?.conversation;
    if (conv == null) {
      return Column(
        key: const ValueKey<String>('thread.info.loading'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MsgSheetHead(title: l.clientMessagesInfoTitle, onClose: () => nav.closeSheet()),
          const _InfoSkeleton(),
        ],
      );
    }
    final resolvedVenueId = conv.venueId ?? venueId;
    final venue = resolvedVenueId == null ? null : ref.watch(threadVenueProvider(resolvedVenueId)).value;
    final phone = venue?.phone;
    final isSupport = conv.kind == ConversationKind.support;
    final isVisit = conv.kind == ConversationKind.visitGroup;
    final locked = isSupport || isVisit;
    final blocked = ref.watch(blockedConversationsProvider).contains(conversationId);
    final muted = ref.watch(mutedConversationsProvider).contains(conversationId);
    final lang = context.gz.locale.languageCode;
    final name = conv.title.of(lang);
    final theirs = thread.value?.messages.where((m) => m.from.value != 'client' && m.kind != MessageKind.system).toList() ?? const <Message>[];
    final photos = thread.value?.messages.where((m) => m.kind == MessageKind.image && m.image != null).toList() ?? const <Message>[];
    final docs = thread.value?.messages.where((m) => m.kind == MessageKind.document && m.document != null).toList() ?? const <Message>[];

    if (step == _Step.pick) return _pickStep(context, ref, theirs, conv.id);
    if (step == _Step.reason) return _reasonStep(context, ref);
    if (step == _Step.reported || step == _Step.blocked) return _doneStep(context, ref, blocked: step == _Step.blocked);

    // The web details: one column 16 apart; the who header, then ruled sections (the request, the shared media, mute / call / report / block).
    return Column(
      key: const ValueKey<String>('thread.info'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(title: l.clientMessagesInfoTitle, onClose: () => nav.closeSheet()),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            GzAvatar(name: name, initial: context.gz.isAr ? conv.monogram : null, size: GzAvatarSize.lg),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: GzText(name, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true),
            ),
            if (isVisit) GzInfoButton(title: l.clientMessagesInfoMembers, paragraphs: [l.clientMessagesInfoMembersNote]),
          ],
        ),
        if (conv.bookingId != null) ...[const SizedBox(height: GzSpace.s4), _InfoBookingRow(bookingId: conv.bookingId!)],
        if (photos.isNotEmpty || docs.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s4),
          MsgInfoSection(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                child: Row(
                  children: [
                    Expanded(
                      child: GzFactRow(
                        label: l.clientMessagesInfoShared,
                        children: [
                          if (photos.isNotEmpty)
                            GzFactChip(icon: GzIcons.image, label: l.clientMessagesPreviewPhoto, value: context.gzFormat.integer(photos.length)),
                          if (docs.isNotEmpty)
                            GzFactChip(icon: GzIcons.document, label: l.clientMessagesPreviewDocument, value: context.gzFormat.integer(docs.length)),
                        ],
                      ),
                    ),
                    GzInfoButton(title: l.clientMessagesInfoPrivateTitle, paragraphs: [l.clientMessagesInfoPrivate]),
                  ],
                ),
              ),
              if (photos.isNotEmpty)
                SizedBox(
                  height: GzSpace.s20,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: GzSpace.s2),
                    itemBuilder: (context, i) {
                      final m = photos[i];
                      return Semantics(
                        button: true,
                        label: m.image!.alt.of(lang),
                        child: GzPressable(
                          onPressed: () => unawaited(
                            showGzGalleryViewer(
                              context,
                              images: [for (final p in photos) GzCarouselImage(src: gzImageSrc(p.image!.file), alt: p.image!.alt.of(lang))],
                              label: l.clientMessagesPhotoViewer,
                              initialIndex: i,
                            ),
                          ),
                          minHeight: 0,
                          minWidth: 0,
                          borderRadius: GzRadius.smAll,
                          child: SizedBox(
                            width: GzSpace.s20,
                            height: GzSpace.s20,
                            child: ClipRRect(
                              borderRadius: GzRadius.smAll,
                              child: GzPhoto(src: gzImageSrc(m.image!.file), alt: m.image!.alt.of(lang)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              for (final d in docs)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                  child: Row(
                    children: [
                      SizedBox(
                        width: GzSize.thumbSm,
                        height: GzSize.thumbSm,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: context.gz.colors.surfaceQuiet, borderRadius: GzRadius.smAll),
                          child: Center(
                            child: GzIcon(GzIcons.document, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: GzText(
                            d.document!.name,
                            role: GzTextRole.bodyS,
                            color: context.gz.colors.textStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: GzSpace.s4),
        MsgInfoSection(
          gap: 0,
          children: [
            GzIconListRow(
              flush: true,
              icon: GzIcons.bell,
              title: l.clientMessagesInfoMute,
              trailing: GzToggle(
                label: l.clientMessagesInfoMute,
                checked: muted,
                onChanged: (on) {
                  ref.read(mutedConversationsProvider.notifier).set(conversationId, on);
                  nav.toast(GzToastSpec(message: on ? l.clientMessagesInfoMuted : l.clientMessagesInfoUnmuted));
                },
              ),
            ),
            if (phone != null)
              GzIconListRow(
                flush: true,
                icon: GzIcons.phone,
                title: l.clientMessagesInfoCall,
                trailing: GzNum(context.gzFormat.phone(phone), role: GzTextRole.figBodyS),
                chevron: true,
                onPressed: () => nav.toast(GzToastSpec(message: context.gzFormat.phone(phone), icon: GzIcons.phone)),
              ),
            GzIconListRow(flush: true, icon: GzIcons.warning, title: l.clientMessagesInfoReport, chevron: true, onPressed: () => onStep(_Step.pick)),
            if (locked)
              GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.lock,
                title: l.clientMessagesInfoBlock,
                trailing: GzInfoButton(
                  title: l.clientMessagesInfoBlock,
                  paragraphs: [isVisit ? l.clientMessagesInfoVisitNote : l.clientMessagesInfoSupportNote],
                ),
              )
            else if (blocked)
              GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.lock,
                title: l.clientMessagesUnblock,
                onPressed: () {
                  ref.read(blockedConversationsProvider.notifier).set(conversationId, false);
                  nav.toast(GzToastSpec(message: l.clientMessagesUnblockedToast, tone: GzToastTone.success));
                },
              )
            else
              GzIconListRow(
                flush: true,
                last: true,
                tone: GzListRowTone.danger,
                icon: GzIcons.xCircle,
                title: l.clientMessagesInfoBlock,
                chevron: true,
                onPressed: () async {
                  final answer = await nav.openDialog(
                    GzDialogSpec(
                      title: l.clientMessagesBlockTitle,
                      icon: GzIcons.warning,
                      confirmLabel: l.clientMessagesBlockConfirm,
                      cancelLabel: l.clientMessagesBlockKeep,
                    ),
                  );
                  if (answer != GzDialogResult.confirm) return;
                  ref.read(blockedConversationsProvider.notifier).set(conversationId, true);
                  onStep(_Step.blocked);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _pickStep(BuildContext context, WidgetRef ref, List<Message> theirs, String convId) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    return Column(
      key: const ValueKey<String>('thread.info.pick'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(title: l.clientMessagesReportPick, plain: true, onClose: () => onStep(_Step.main)),
        if (theirs.isEmpty)
          GzEmptyState(fill: false, illustration: GzIllustrationName.emptyMessages, title: l.clientMessagesReportNoMessages)
        else
          GzRadioGroup<String>(
            label: l.clientMessagesReportPick,
            value: picked,
            onChanged: onPicked,
            children: [
              for (final m in theirs.reversed.take(6))
                GzRadio<String>(value: m.id, label: messageText(m, lang).isEmpty ? m.id : messageText(m, lang)),
            ],
          ),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          key: const ValueKey<String>('thread.info.pick.continue'),
          label: context.gzL10n.commonActionContinue,
          fullWidth: true,
          onPressed: picked == null ? null : () => onStep(_Step.reason),
        ),
      ],
    );
  }

  Widget _reasonStep(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reasons = <String>[
      l.clientMessagesReasonSpam,
      l.clientMessagesReasonAbusive,
      l.clientMessagesReasonInappropriate,
      l.clientMessagesReasonOther,
    ];
    return Column(
      key: const ValueKey<String>('thread.info.reason'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(title: l.clientMessagesReportReasonTitle, plain: true, onClose: () => onStep(_Step.main)),
        GzRadioGroup<String>(
          label: l.clientMessagesReportReasonTitle,
          value: reason,
          onChanged: onReason,
          children: [for (final r in reasons) GzRadio<String>(value: r, label: r)],
        ),
        const SizedBox(height: GzSpace.s2),
        GzTextArea(label: l.clientMessagesReportNote, optional: true, rows: 3, value: note, onValueChange: onNote),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          key: const ValueKey<String>('thread.info.report.send'),
          label: context.gzL10n.commonActionSend,
          fullWidth: true,
          onPressed: reason == null
              ? null
              : () {
                  onStep(_Step.reported);
                },
        ),
      ],
    );
  }

  Widget _doneStep(BuildContext context, WidgetRef ref, {required bool blocked}) {
    final l = context.l10n;
    final nav = context.gzNav;
    return Column(
      key: ValueKey<String>(blocked ? 'thread.info.blocked' : 'thread.info.reported'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(onClose: () => nav.closeSheet()),
        GzEmptyState(
          fill: false,
          illustration: blocked ? GzIllustrationName.shield : GzIllustrationName.seal,
          title: blocked ? l.clientMessagesBlockedDoneTitle : l.clientMessagesReportDone,
          action: GzStateAction(
            label: context.gzL10n.commonActionDone,
            variant: GzButtonVariant.primary,
            onPressed: () {
              nav.closeSheet();
              if (!blocked) nav.toast(GzToastSpec(message: l.clientMessagesReportDone, tone: GzToastTone.success));
            },
          ),
          secondary: blocked
              ? GzStateAction(
                  label: l.clientMessagesUnblock,
                  onPressed: () {
                    ref.read(blockedConversationsProvider.notifier).set(conversationId, false);
                    nav.toast(GzToastSpec(message: l.clientMessagesUnblockedToast, tone: GzToastTone.success));
                    onStep(_Step.main);
                  },
                )
              : null,
        ),
      ],
    );
  }
}

/// The linked booking row: the request facts with its status into detail.
class _InfoBookingRow extends ConsumerWidget {
  const _InfoBookingRow({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(threadBookingProvider(bookingId)).value;
    if (booking == null) return const SizedBox.shrink();
    return MsgInfoSection(
      children: [
        MsgInfoRequestRow(
          booking: booking.booking,
          onOpen: () {
            context.gzNav.closeSheet();
            context.gzNav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': booking.booking.id});
          },
        ),
      ],
    );
  }
}

class _InfoSkeleton extends StatelessWidget {
  const _InfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          GzSkeleton(blockSize: 56),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(blockSize: 48),
          SizedBox(height: GzSpace.s2),
          GzSkeleton(blockSize: 48),
        ],
      ),
    );
  }
}
