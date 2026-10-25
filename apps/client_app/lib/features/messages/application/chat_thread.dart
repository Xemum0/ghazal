import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show chatRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'inbox.dart';

/// What a message the client just wrote is doing: still on its way, queued offline, failed, or being uploaded.
enum LocalState { sending, queued, failed, uploading }

/// A message of the client's that the server has not confirmed yet. It is drawn in the thread until the server's copy replaces it.
@immutable
class LocalMsg {
  const LocalMsg({
    required this.clientMsgId,
    required this.kind,
    required this.at,
    this.text,
    this.seconds,
    this.fileName,
    this.state = LocalState.sending,
    this.progress = 0,
  });

  final String clientMsgId;
  final SendMessageInputKind kind;
  final DateTime at;
  final String? text;
  final int? seconds;
  final String? fileName;
  final LocalState state;
  final double progress;

  LocalMsg copyWith({LocalState? state, double? progress}) => LocalMsg(
    clientMsgId: clientMsgId,
    kind: kind,
    at: at,
    text: text,
    seconds: seconds,
    fileName: fileName,
    state: state ?? this.state,
    progress: progress ?? this.progress,
  );

  /// The message as the bubble draws it (the sender's own, `sent`).
  Message toMessage(String conversationId, WireLang lang) => Message(
    id: 'local-$clientMsgId',
    conversationId: conversationId,
    seq: 1 << 30,
    clientMsgId: clientMsgId,
    from: MessageFrom.client,
    senderName: null,
    at: at,
    kind: switch (kind) {
      SendMessageInputKind.voice => MessageKind.voice,
      SendMessageInputKind.document => MessageKind.document,
      SendMessageInputKind.image => MessageKind.image,
      _ => MessageKind.text,
    },
    text: text == null ? null : LocalizedText(en: lang == WireLang.en ? text : null, ar: lang == WireLang.ar ? text : null),
    origin: lang,
    voice: seconds == null ? null : MessageVoice(seconds: seconds!),
    document: kind == SendMessageInputKind.document ? MessageDocument(name: fileName ?? '', sizeKb: 84, mime: 'application/pdf') : null,
    status: MessageStatus.sent,
    draft: false,
  );
}

@immutable
class ChatState {
  const ChatState({required this.conversation, this.messages = const <Message>[], this.locals = const <LocalMsg>[]});

  final Conversation conversation;
  final List<Message> messages;
  final List<LocalMsg> locals;

  int get lastSeq => messages.isEmpty ? 0 : messages.last.seq;

  ChatState copyWith({Conversation? conversation, List<Message>? messages, List<LocalMsg>? locals}) =>
      ChatState(conversation: conversation ?? this.conversation, messages: messages ?? this.messages, locals: locals ?? this.locals);
}

/// The script of typed text: `ar` when it holds Arabic letters (each message keeps its own language and direction, ADR 0014 D8).
WireLang scriptOf(String text) => RegExp(r'[؀-ۿݐ-ݿ]').hasMatch(text) ? WireLang.ar : WireLang.en;

/// One conversation: its messages, the writes in flight, and the poll for what the other side wrote (the API has no push: the app asks
/// `listMessages?afterSeq=` every few seconds while the thread is open).
final chatThreadProvider = AsyncNotifierProvider.autoDispose.family<ChatThread, ChatState, String>(ChatThread.new);

class ChatThread extends AsyncNotifier<ChatState> {
  ChatThread(this.conversationId);

  final String conversationId;
  Timer? _poll;
  int _n = 0;

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  @override
  Future<ChatState> build() async {
    ref.onDispose(() => _poll?.cancel());
    final conversation = await _repo.getConversation(conversationId: conversationId);
    final page = await _repo.listMessages(conversationId: conversationId, limit: 50);
    final msgs = [...page.items.where((m) => !m.draft)];
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => unawaited(_pull()));
    final s = ChatState(conversation: conversation, messages: msgs);
    unawaited(Future<void>.microtask(markRead));
    return s;
  }

  Future<void> _pull() async {
    final cur = state.value;
    if (cur == null) return;
    try {
      final page = await _repo.listMessages(conversationId: conversationId, afterSeq: cur.lastSeq, limit: 50);
      final now = state.value ?? cur;
      final fresh = page.items.where((m) => !m.draft && !now.messages.any((x) => x.id == m.id)).toList();
      if (fresh.isEmpty) return;
      final ids = {
        for (final m in fresh)
          if (m.clientMsgId != null) m.clientMsgId,
      };
      state = AsyncData(
        now.copyWith(
          messages: [...now.messages, ...fresh],
          locals: [
            for (final l in now.locals)
              if (!ids.contains(l.clientMsgId)) l,
          ],
        ),
      );
      if (fresh.any((m) => m.from != MessageFrom.client)) unawaited(markRead());
    } on Object {
      // the next tick tries again
    }
  }

  /// Tells the server the thread is read up to the last message, then refreshes the inbox counts.
  Future<void> markRead() async {
    final cur = state.value;
    if (cur == null ||
        cur.conversation.unread.client == 0 && cur.messages.every((m) => m.from == MessageFrom.client || m.status == MessageStatus.read)) {
      return;
    }
    try {
      await _repo.markConversationRead(
        conversationId: conversationId,
        body: ReadMarkerInput(upToSeq: cur.lastSeq),
      );
      ref.read(inboxRevisionProvider.notifier).bump();
    } on Object {
      // read state is best effort
    }
  }

  String _id() => 'c${ref.read(clockProvider)().microsecondsSinceEpoch}-${_n++}';

  void _putLocal(LocalMsg m) {
    final cur = state.value;
    if (cur == null) return;
    final rest = [
      for (final l in cur.locals)
        if (l.clientMsgId != m.clientMsgId) l,
    ];
    // keep order: a retried message stays where it was
    final i = cur.locals.indexWhere((l) => l.clientMsgId == m.clientMsgId);
    final next = i < 0 ? [...rest, m] : [...cur.locals.sublist(0, i), m, ...cur.locals.sublist(i + 1)];
    state = AsyncData(cur.copyWith(locals: next));
  }

  /// Sends a text message. Returns the problem when the API refused (the message stays as `failed`, or `queued` offline).
  Future<void> sendText(String text) =>
      _send(LocalMsg(clientMsgId: _id(), kind: SendMessageInputKind.text, at: ref.read(clockProvider)(), text: text));

  Future<void> sendVoice(int seconds) =>
      _send(LocalMsg(clientMsgId: _id(), kind: SendMessageInputKind.voice, at: ref.read(clockProvider)(), seconds: seconds));

  /// A document or a photo: an upload session first, then the message that points at it.
  Future<void> sendAttachment({required bool image, required String fileName}) => _send(
    LocalMsg(
      clientMsgId: _id(),
      kind: image ? SendMessageInputKind.image : SendMessageInputKind.document,
      at: ref.read(clockProvider)(),
      fileName: fileName,
      state: LocalState.uploading,
    ),
  );

  Future<void> retry(String clientMsgId) async {
    final l = state.value?.locals.where((x) => x.clientMsgId == clientMsgId).firstOrNull;
    if (l == null) return;
    final media = l.kind == SendMessageInputKind.image || l.kind == SendMessageInputKind.document;
    await _send(l.copyWith(state: media ? LocalState.uploading : LocalState.sending));
  }

  void discard(String clientMsgId) {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(
        locals: [
          for (final l in cur.locals)
            if (l.clientMsgId != clientMsgId) l,
        ],
      ),
    );
  }

  Future<void> _send(LocalMsg m) async {
    _putLocal(m);
    try {
      String? attachment;
      final file = m.fileName;
      if (m.kind == SendMessageInputKind.image || m.kind == SendMessageInputKind.document) {
        final image = m.kind == SendMessageInputKind.image;
        final session = await _repo.createAttachmentUpload(
          conversationId: conversationId,
          body: UploadSessionInput(
            fileName: file ?? (image ? 'photo.jpg' : 'document.pdf'),
            contentType: image ? 'image/jpeg' : 'application/pdf',
            sizeBytes: 86016,
            purpose: image ? UploadPurpose.chatImage : UploadPurpose.chatDocument,
          ),
        );
        attachment = session.id;
        _putLocal(m.copyWith(state: LocalState.sending, progress: 1));
      }
      final msg = await _repo.sendMessage(
        conversationId: conversationId,
        body: SendMessageInput(
          clientMsgId: m.clientMsgId,
          kind: m.kind,
          text: m.text,
          origin: m.text == null ? null : scriptOf(m.text!),
          attachmentId: attachment,
          voiceSeconds: m.seconds,
        ),
      );
      final cur = state.value;
      if (cur == null) return;
      final has = cur.messages.any((x) => x.id == msg.id);
      state = AsyncData(
        cur.copyWith(
          messages: has ? cur.messages : [...cur.messages, msg],
          locals: [
            for (final l in cur.locals)
              if (l.clientMsgId != m.clientMsgId) l,
          ],
        ),
      );
      ref.read(inboxRevisionProvider.notifier).bump();
    } on ApiProblem catch (p) {
      _putLocal(m.copyWith(state: p.isOffline ? LocalState.queued : LocalState.failed));
    }
  }
}
