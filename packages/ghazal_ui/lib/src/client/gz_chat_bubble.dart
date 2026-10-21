import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Message, MessageFrom, MessageKind, MessageStatus, ThreadRole, WireLang;

import '../core/gz_format_scope.dart';
import '../foundation.dart';
import '../visits/gz_role_badge.dart';
import 'gz_chat_parts.dart';

/// Whose phone this is: messages from this side sit at inline-end.
enum GzChatSide { client, hotel }

/// Group chat (visit_group, ADR 0033 D9): who wrote a run of bubbles, shown above the first bubble as name then role badge.
class GzChatSender {
  const GzChatSender({required this.name, required this.role, this.you = false});

  final String name;
  final ThreadRole role;
  final bool you;
}

bool gzChatOwn(Message m, GzChatSide side) => side == GzChatSide.client ? m.from == MessageFrom.client : m.from == MessageFrom.venue;

/// ChatBubble (CA-MSG, ADR 0013 D2 dialect rule, ADR 0014 D8). Text is shown as typed, in its own language and direction (auto);
/// image, document, voice (a waveform you can read at a glance) and the structured cards (meeting, quote request, booking); system
/// lines are a centred caption. Own messages sit at inline-end in ink with canvas text, received ones at inline-start on ink-50; the
/// tail corner is the 4 radius, and the opposite side keeps a 48 reserve. No gold: a chat is not a verb. The time stays an LTR figure.
/// [sender] adds the group-chat name line; [group] gives a system line its quiet glyph (`true` = info, or pass an icon).
class GzChatBubble extends StatelessWidget {
  const GzChatBubble({
    required this.message,
    this.side = GzChatSide.client,
    this.playing = false,
    this.progress = 0,
    this.onPlay,
    this.onOpen,
    this.showMeta = true,
    this.sender,
    this.group = false,
    this.groupIcon,
    super.key,
  });

  final Message message;
  final GzChatSide side;

  /// Voice: the playing state and the share played (0 to 1).
  final bool playing;
  final double progress;
  final VoidCallback? onPlay;
  final VoidCallback? onOpen;

  /// Show the time and the delivery state under the bubble (the last of a run).
  final bool showMeta;
  final GzChatSender? sender;

  /// Group chat: a system line follows the viewer's language and carries a glyph ([groupIcon] or info).
  final bool group;
  final IconData? groupIcon;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final m = message;
    final lang = gz.locale.languageCode;
    final own = gzChatOwn(m, side);

    if (m.kind == MessageKind.system) {
      final text = m.text == null ? '' : m.text!.of(group ? lang : (m.origin == WireLang.ar ? 'ar' : 'en'));
      return Align(
        alignment: Alignment.center,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group) ...[GzIcon(groupIcon ?? GzIcons.info, size: GzIconSize.xs, color: c.iconSecondary), const SizedBox(width: GzSpace.s2)],
                Flexible(child: GzText(text, role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.center, figures: group)),
              ],
            ),
          ),
        ),
      );
    }

    final ink = GzBubbleInk.of(c, own: own, draft: m.draft);
    final status = m.status == MessageStatus.read ? l.uiClientChatRead : (m.status == MessageStatus.delivered ? l.uiClientChatDelivered : l.uiClientChatSent);
    final meta = showMeta
        ? Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s1, end: GzSpace.s1, top: GzSpace.s1),
            child: Semantics(
              container: true,
              label: '${f.time(m.at)}${own ? ', $status' : ''}',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The web `Fig` is an inline run with line-height 0: the time adds no height of its own, the delivery glyph (16) sets the row.
                  GzZeroHeight(
                    child: Text(
                      GzBidi.isolateLtr(f.time(m.at)),
                      style: GzFigures.inlineStyle(gz.locale, GzTextRole.caption).copyWith(
                        fontWeight: gz.text(GzTextRole.caption).fontWeight,
                        color: c.textSecondary,
                        decoration: TextDecoration.none,
                        height: gz.text(GzTextRole.figCaption).height,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  if (own) ...[
                    const SizedBox(width: GzSpace.s1),
                    GzIcon(m.status == MessageStatus.read ? GzIcons.checkDouble : GzIcons.check, size: GzIconSize.xs, color: m.status == MessageStatus.read ? c.iconAccent : c.iconSecondary),
                  ],
                  if (m.draft) ...[
                    const SizedBox(width: GzSpace.s1),
                    DecoratedBox(
                      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: GzSpace.s1), child: GzText(l.uiClientChatDraft, role: GzTextRole.caption, color: c.textSecondary)),
                    ),
                  ],
                ],
              ),
            ),
          )
        : null;

    final bare = m.kind == MessageKind.image;
    final Widget body = switch (m.kind) {
      MessageKind.image => GzChatImageBody(message: m, onOpen: onOpen),
      MessageKind.document => GzChatDocumentBody(message: m, ink: ink),
      MessageKind.voice => GzChatVoiceBody(message: m, ink: ink, playing: playing, progress: progress, onPlay: onPlay),
      MessageKind.meetingCard || MessageKind.quoteRequestCard || MessageKind.bookingCard || MessageKind.visitCard => GzChatCardBody(message: m, ink: ink),
      _ => GzTypedText(text: m.text?.of(m.origin == WireLang.ar ? 'ar' : 'en') ?? '', lang: m.origin == WireLang.ar ? 'ar' : 'en', color: ink.fg),
    };

    final rtl = Directionality.of(context) == TextDirection.rtl;
    // border-end-end (own) / border-end-start (received): the tail sits at the bottom corner on the side the bubble hugs.
    final tailLeft = own ? rtl : !rtl;
    const big = Radius.circular(GzRadius.md);
    const tail = Radius.circular(GzRadius.xs);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: tailLeft ? tail : big,
      bottomRight: tailLeft ? big : tail,
    );
    final Widget box;
    if (bare) {
      box = ClipRRect(borderRadius: radius, child: body);
    } else if (m.draft) {
      box = CustomPaint(
        foregroundPainter: GzDashedBorder(color: c.borderStrong, radius: radius),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: GzSpace.s3 + GzStroke.hair, horizontal: GzSpace.s4 + GzStroke.hair), child: body),
      );
    } else {
      box = DecoratedBox(
        decoration: BoxDecoration(color: own ? c.surfaceDarkRaised : c.surfaceQuiet, borderRadius: radius),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: GzSpace.s3, horizontal: GzSpace.s4), child: body),
      );
    }

    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: own ? GzSpace.s12 : 0, end: own ? 0 : GzSpace.s12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (sender != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GzSpace.s1),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: GzSpace.s2,
                    children: [
                      Directionality(
                        textDirection: gzAutoDir(sender!.name),
                        child: GzText(sender!.name, role: GzTextRole.caption, color: c.textStrong),
                      ),
                      GzRoleBadge(role: sender!.role, you: sender!.you),
                    ],
                  ),
                ),
                const SizedBox(height: GzSpace.s1),
              ],
              box,
              if (meta != null) ...[const SizedBox(height: GzSpace.s1), meta],
            ],
          ),
        ),
      ),
    );
  }
}
