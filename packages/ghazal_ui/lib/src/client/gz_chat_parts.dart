import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Message, MessageKind;
import 'package:intl/intl.dart' show Bidi;

import '../core/gz_format_scope.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_service_tile.dart' show gzImageSrc;

/// The colours of one bubble body: own = ink with canvas text, received = ink-50, draft = a dashed outline on the canvas.
class GzBubbleInk {
  const GzBubbleInk({required this.fg, required this.muted, required this.iconTile, required this.iconTileFg, required this.disc, required this.discFg, required this.bar, required this.barPlayed});

  factory GzBubbleInk.of(GzColors c, {required bool own, required bool draft}) {
    if (draft) {
      return GzBubbleInk(
        fg: c.textPrimary,
        muted: c.textSecondary,
        iconTile: own ? c.surfaceQuiet : c.surfaceRaised,
        iconTileFg: c.iconPrimary,
        disc: c.surfaceDarkRaised,
        discFg: c.iconOnDark,
        bar: c.textSecondary,
        barPlayed: c.textStrong,
      );
    }
    return own
        ? GzBubbleInk(fg: c.textOnDark, muted: c.textOnDarkMuted, iconTile: c.surfaceDark, iconTileFg: c.textOnDark, disc: c.surfaceCanvas, discFg: c.iconPrimary, bar: c.textOnDarkMuted, barPlayed: c.textOnDark)
        : GzBubbleInk(fg: c.textStrong, muted: c.textSecondary, iconTile: c.surfaceRaised, iconTileFg: c.textStrong, disc: c.surfaceDarkRaised, discFg: c.iconOnDark, bar: c.textSecondary, barPlayed: c.textStrong);
  }

  final Color fg;
  final Color muted;
  final Color iconTile;
  final Color iconTileFg;
  final Color disc;
  final Color discFg;
  final Color bar;
  final Color barPlayed;
}

/// 28 deterministic bar heights (dp from the 4-pt scale) so every voice message has its own, stable waveform. The same arithmetic as
/// the web `waveform` (JavaScript doubles: the multiply loses low bits above 2^53, so it is done in doubles here too).
List<double> gzWaveform(String seed, [int bars = 28]) {
  const steps = [4.0, 8.0, 12.0, 16.0, 20.0, 24.0];
  const mod = 4294967296.0;
  var h = 0.0;
  for (final ch in seed.runes) {
    h = (h * 31 + ch) % mod;
  }
  return List.generate(bars, (i) {
    h = (h * 1103515245 + 12345 + i) % mod;
    final envelope = math.sin(i / (bars - 1) * math.pi);
    final hi = (h.toInt() >> 8) % 4;
    final idx = (envelope * 2 + hi + 0.5).floor().clamp(0, steps.length - 1);
    return steps[idx];
  });
}

/// A 1 dp dashed rounded outline (the draft bubble). Dash and gap of 3 dp, like the browser's `dashed` at 1 px.
class GzDashedBorder extends CustomPainter {
  const GzDashedBorder({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.hair;
    final rrect = radius.toRRect(Offset.zero & size).deflate(GzStroke.hair / 2);
    final path = Path()..addRRect(rrect);
    for (final PathMetric m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 3, m.length)), paint);
        d += 6;
      }
    }
  }

  @override
  bool shouldRepaint(GzDashedBorder old) => old.color != color || old.radius != radius;
}

TextDirection gzAutoDir(String text) => Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

/// The photo of an image message: 240 wide, 4:3, one button.
class GzChatImageBody extends StatelessWidget {
  const GzChatImageBody({required this.message, this.onOpen, super.key});

  final Message message;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final img = message.image;
    if (img == null) return const SizedBox.shrink();
    final alt = img.alt.of(gz.locale.languageCode);
    return Semantics(
      button: true,
      label: '${context.gzL10n.uiClientChatOpenPhoto}: $alt',
      excludeSemantics: true,
      onTap: onOpen,
      child: GzPressable(
        onPressed: onOpen,
        scale: 1,
        minHeight: 0,
        minWidth: 0,
        child: SizedBox(width: GzSize.chatMedia, height: GzSize.chatMedia / GzLayout.aspect4x3, child: GzPhoto(src: gzImageSrc(img.file), alt: alt)),
      ),
    );
  }
}

/// A document: file icon tile, the file name as an LTR isolate, "PDF · 38 KB", a download glyph.
class GzChatDocumentBody extends StatelessWidget {
  const GzChatDocumentBody({required this.message, required this.ink, super.key});

  final Message message;
  final GzBubbleInk ink;

  @override
  Widget build(BuildContext context) {
    final doc = message.document;
    if (doc == null) return const SizedBox.shrink();
    final l = context.gzL10n;
    final f = context.gzFormat;
    Widget tile(Widget child, {Color? fill}) => DecoratedBox(
          decoration: BoxDecoration(color: fill, borderRadius: GzRadius.smAll),
          child: SizedBox(width: GzSize.thumbSm, height: GzSize.thumbSm, child: Center(child: child)),
        );
    return Semantics(
      container: true,
      label: l.uiClientChatDownload(doc.name),
      excludeSemantics: true,
      child: SizedBox(
        width: GzSize.chatMedia,
        child: Row(
          children: [
            tile(GzIcon(GzIcons.document, size: GzIconSize.md, color: ink.iconTileFg), fill: ink.iconTile),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GzText(doc.name, role: GzTextRole.bodyS, color: ink.fg, maxLines: 1, textAlign: TextAlign.start),
                  ),
                  GzText('${l.uiClientChatPdf} · ${l.uiClientChatKb(f.integer(doc.sizeKb))}', role: GzTextRole.caption, color: ink.muted, figures: true),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            tile(GzIcon(GzIcons.download, size: GzIconSize.sm, color: ink.fg)),
          ],
        ),
      ),
    );
  }
}

/// A voice message: play disc in a 44 target, an LTR waveform (a recording is not text), the duration as a figure.
class GzChatVoiceBody extends StatelessWidget {
  const GzChatVoiceBody({required this.message, required this.ink, this.playing = false, this.progress = 0, this.onPlay, super.key});

  final Message message;
  final GzBubbleInk ink;
  final bool playing;
  final double progress;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final f = context.gzFormat;
    final secs = message.voice?.seconds ?? 0;
    final bars = gzWaveform(message.id);
    final done = (bars.length * progress.clamp(0.0, 1.0)).round();
    final time = '${f.integer(secs ~/ 60)}:${(secs % 60).toString().padLeft(2, '0')}';
    return SizedBox(
      width: GzSize.chatMedia,
      child: Row(
        children: [
          Semantics(
            button: true,
            toggled: playing,
            label: playing ? l.uiClientChatPause : l.uiClientChatPlay,
            excludeSemantics: true,
            onTap: onPlay,
            child: GzPressable(
              onPressed: onPlay,
              borderRadius: GzRadius.pillAll,
              child: SizedBox.square(
                dimension: GzSize.touchMin,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: ink.disc, shape: BoxShape.circle),
                    child: SizedBox.square(dimension: GzSize.disk, child: Center(child: GzIcon(playing ? GzIcons.pause : GzIcons.play, size: GzIconSize.sm, color: ink.discFg))),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Semantics(
              image: true,
              label: l.uiClientChatVoice,
              excludeSemantics: true,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SizedBox(
                  height: 24,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < bars.length; i++) ...[
                        if (i > 0) const SizedBox(width: GzStroke.thread),
                        Expanded(child: Center(child: DecoratedBox(decoration: BoxDecoration(color: i < done ? ink.barPlayed : ink.bar, borderRadius: GzRadius.pillAll), child: SizedBox(height: bars[i], width: double.infinity)))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzNum(time, role: GzTextRole.figCaption, color: ink.fg),
        ],
      ),
    );
  }
}

/// The three structured cards (meeting, quote request, booking / visit): glyph and title, then the lines and the time.
class GzChatCardBody extends StatelessWidget {
  const GzChatCardBody({required this.message, required this.ink, super.key});

  final Message message;
  final GzBubbleInk ink;

  @override
  Widget build(BuildContext context) {
    final card = message.card;
    if (card == null) return const SizedBox.shrink();
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final icon = switch (message.kind) {
      MessageKind.meetingCard => GzIcons.calendar,
      MessageKind.quoteRequestCard => GzIcons.clipboard,
      MessageKind.visitCard => GzIcons.calendarCheck,
      _ => GzIcons.receipt,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s2),
            Flexible(child: GzText(card.title.of(lang), role: GzTextRole.title, color: ink.fg)),
          ],
        ),
        for (final line in card.lines) ...[
          const SizedBox(height: GzSpace.s1),
          GzText(line.of(lang), role: GzTextRole.bodyS, color: ink.fg, figures: true),
        ],
        if (card.at != null) ...[
          const SizedBox(height: GzSpace.s1),
          GzText(f.dateTime(card.at!), role: GzTextRole.bodyS, color: ink.fg, figures: true),
        ],
      ],
    );
  }
}

/// A run with line-height 0 (the web `.gz-num` as a flex item): it contributes no height and its glyphs are centred on the line, so a
/// row of this and a 16 dp glyph is as tall as the glyph and a row of it alone is 0 high.
class GzZeroHeight extends SingleChildRenderObjectWidget {
  const GzZeroHeight({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderZeroHeight();
}

class _RenderZeroHeight extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    c.layout(BoxConstraints(maxWidth: constraints.maxWidth), parentUsesSize: true);
    size = constraints.constrain(Size(c.size.width, 0));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c != null) context.paintChild(c, offset + Offset(0, -c.size.height / 2));
  }

  @override
  double computeMinIntrinsicWidth(double height) => child?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) => child?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.constrain(Size(child?.getDryLayout(BoxConstraints(maxWidth: constraints.maxWidth)).width ?? 0, 0));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => false;
}

/// The typed text of a message: set in the style of ITS language (the web puts `lang` on the span, so an Arabic message in an English
/// thread keeps the Arabic face and line height), direction by its first strong character.
class GzTypedText extends StatelessWidget {
  const GzTypedText({required this.text, required this.lang, required this.color, super.key});

  final String text;
  final String lang;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = GzType.style(Locale(lang), GzTextRole.bodyS).copyWith(color: color, decoration: TextDecoration.none);
    return Directionality(
      textDirection: gzAutoDir(text),
      child: Text(text, style: style, textAlign: TextAlign.start),
    );
  }
}
