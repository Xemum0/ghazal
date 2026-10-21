import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Conversation, Message, MessageKind, WireLang;

import '../core/core.dart';
import '../foundation.dart';
import 'gz_chat_bubble.dart' show GzChatSide, gzChatOwn;
import 'gz_chat_parts.dart' show gzAutoDir;

/// ConversationRow (CA-MSG): the Messages list row, a monogram, the title, one line of preview, the time and the gold unread count. An
/// unread preview is strong; a pinned thread without unread shows the pin. [last] is the last message of any kind for the preview.
class GzConversationRow extends StatelessWidget {
  const GzConversationRow({required this.conversation, this.last, this.side = GzChatSide.client, this.onOpen, super.key});

  final Conversation conversation;
  final Message? last;
  final GzChatSide side;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final conv = conversation;
    final unread = side == GzChatSide.client ? conv.unread.client : conv.unread.hotel;
    final msg = last;
    final title = conv.title.of(lang);
    final String preview;
    if (msg == null) {
      preview = conv.subtitle.of(lang);
    } else if (msg.kind == MessageKind.voice) {
      final s = msg.voice?.seconds ?? 0;
      preview = '${l.uiClientChatVoice} ${f.integer(s ~/ 60)}:${(s % 60).toString().padLeft(2, '0')}';
    } else if (msg.kind == MessageKind.image) {
      preview = l.uiClientChatPhoto;
    } else if (msg.kind == MessageKind.document) {
      preview = msg.document?.name ?? '';
    } else if (msg.card != null) {
      preview = msg.card!.title.of(lang);
    } else {
      preview = msg.text?.of(msg.origin == WireLang.ar ? 'ar' : 'en') ?? '';
    }
    final mine = msg != null && gzChatOwn(msg, side);
    final strong = gz.text(GzTextRole.title).fontWeight;
    final body = gz.text(GzTextRole.body).fontWeight;
    final previewColor = unread > 0 ? c.textStrong : c.textSecondary;
    final subtitle = Row(
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        if (mine) ...[
          GzText.rich(TextSpan(text: l.uiClientChatYou.trimRight(), style: TextStyle(fontWeight: body)), role: GzTextRole.caption, color: c.textSecondary, softWrap: false),
          const SizedBox(width: GzSpace.s1),
        ],
        Expanded(
          child: Directionality(
            textDirection: gzAutoDir(preview),
            child: GzText.rich(
              TextSpan(style: unread > 0 ? TextStyle(fontWeight: strong) : null, children: GzFigures.spans(context, preview, role: GzTextRole.caption)),
              role: GzTextRole.caption,
              color: previewColor,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
    final time = f.ago(conv.lastMessageAt);
    // One button for assistive technology: who, what was last said, when, and how many are unread (the badge alone would be lost
    // behind the row's own name).
    final spoken = [title, f.plain(preview), time, if (unread > 0) l.uiClientChatUnread(unread), if (unread == 0 && conv.pinned) l.uiClientChatPinned].join(', ');
    GzListRow row([GzPreviewState? state]) => GzListRow(
          title: title,
          autoDir: true,
          subtitleWidget: subtitle,
          previewState: state,
          leading: GzAvatar(name: title, initial: gz.isAr ? conv.monogram : null, size: GzAvatarSize.md),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GzText(time, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              if (unread > 0 || conv.pinned) const SizedBox(height: GzSpace.s1),
              if (unread > 0) GzCountBadge(count: unread) else if (conv.pinned) GzIcon(GzIcons.bookmark, size: GzIconSize.xs, color: c.iconSecondary),
            ],
          ),
        );
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: spoken,
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: 0,
      minWidth: 0,
      builder: (context, st) => row(st.pressed ? GzPreviewState.pressed : null),
    );
  }
}
