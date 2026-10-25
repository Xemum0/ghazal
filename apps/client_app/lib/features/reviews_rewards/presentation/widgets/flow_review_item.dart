import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Review, ReviewAudience, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// One review in the list (flow-local twin of the web `ReviewItem`, which the
/// screen builds itself instead of the shared card): a monogram, the name
/// with a verified glyph, then facts as glyph + figure (stars, the
/// reception's symbol, the month), the text exactly as typed cut to two
/// lines, the photographs (empty rooms) and the venue's reply as a glyph
/// block. No "Verified booking" line, no "Reply from" header: both are
/// accessible names. The one control is the overflow that opens the report
/// sheet; a reported review says so with one word.
class FlowReviewItem extends StatefulWidget {
  const FlowReviewItem({required this.review, required this.venueName, this.reported = false, this.onMore, this.moreKey, super.key});

  final Review review;
  final String venueName;
  final bool reported;
  final VoidCallback? onMore;
  final ValueKey<String>? moreKey;

  @override
  State<FlowReviewItem> createState() => _FlowReviewItemState();
}

/// The text up to [limit] characters, cut at the last space so no word is split, closed with an ellipsis (web `cutAt`).
String _cutAt(String text, int limit) {
  if (text.length <= limit) return text;
  final head = text.substring(0, limit);
  final space = head.lastIndexOf(' ');
  final cut = space > limit * 0.6 ? head.substring(0, space) : head;
  return '${cut.replaceFirst(RegExp(r'[\s,.;:،؛]+$'), '')}…';
}

class _FlowReviewItemState extends State<FlowReviewItem> {
  bool _open = false;
  bool _replyOpen = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final r = widget.review;
    final origin = r.origin == WireLang.ar ? 'ar' : 'en';
    final name = r.anonymous ? l.clientReviewsRewardsGuest : r.author.of(lang);
    final audienceIcon = r.audience == ReviewAudience.men ? GzIcons.sectionMen : GzIcons.sectionWomen;
    final audienceWord = r.audience == ReviewAudience.men ? context.gzL10n.uiClientReviewMen : context.gzL10n.uiClientReviewLadies;
    final text = r.text.of(origin);
    final shots = r.photos.take(3).toList();
    final reply = r.ownerReply?.text.of(lang);
    return Semantics(
      container: true,
      child: Container(
        key: ValueKey<String>('reviews.item.${r.id}'),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzAvatar(name: name, initial: r.anonymous || lang != 'ar' ? null : r.monogram, size: GzAvatarSize.sm),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: GzText(
                                        name,
                                        role: GzTextRole.title,
                                        color: c.textStrong,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                    if (r.verifiedBooking) ...[
                                      const SizedBox(width: GzSpace.s1),
                                      Semantics(
                                        label: l.clientReviewsRewardsListVerified,
                                        child: ExcludeSemantics(
                                          child: GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: GzSpace.s2),
                              if (widget.reported)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess),
                                    const SizedBox(width: GzSpace.s1),
                                    GzText(l.clientReviewsRewardsListReported, role: GzTextRole.caption, color: c.textSuccess),
                                  ],
                                )
                              else
                                GzIconButton(
                                  key: widget.moreKey,
                                  icon: GzIcons.more,
                                  label: l.clientReviewsRewardsListMore,
                                  onPressed: widget.onMore,
                                ),
                            ],
                          ),
                        ),
                        Semantics(
                          container: true,
                          label: l.clientReviewsRewardsRating,
                          child: Wrap(
                            spacing: GzSpace.s3,
                            runSpacing: GzSpace.s2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              GzFactChip(
                                icon: GzIcons.starFill,
                                label: l.clientReviewsRewardsRating,
                                value: f.number(r.rating, const DecimalOptions(minFraction: 1, maxFraction: 1)),
                                tone: GzFactTone.accent,
                              ),
                              GzFactChip(icon: audienceIcon, label: audienceWord),
                              GzFactChip(
                                icon: GzIcons.calendar,
                                label: l.clientReviewsRewardsListEvent,
                                value: f.date(r.eventDate.toString(), DateStyle.monthYear),
                                tone: GzFactTone.muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              _Clamp(text: text, origin: origin, open: _open, onToggle: () => setState(() => _open = !_open)),
              if (shots.isNotEmpty) ...[
                const SizedBox(height: GzSpace.s3),
                Semantics(
                  container: true,
                  label: context.gzL10n.uiClientReviewPhotos,
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: GzSpace.s2),
                        Expanded(
                          child: i < shots.length
                              ? AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                    borderRadius: GzRadius.smAll,
                                    child: GzPhoto(src: gzReviewPhotoSrc(shots[i]), alt: ''),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (reply != null) ...[
                const SizedBox(height: GzSpace.s3),
                Container(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s1, top: GzSpace.s3, bottom: GzSpace.s3),
                  decoration: BoxDecoration(
                    color: c.surfaceQuiet,
                    borderRadius: GzRadius.smAll,
                    border: BorderDirectional(
                      start: BorderSide(color: c.borderStrong, width: GzStroke.thread),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                        child: GzIcon(
                          GzIcons.reply,
                          size: GzIconSize.sm,
                          color: c.iconSecondary,
                          semanticLabel: l.clientReviewsRewardsListReplyFrom(widget.venueName),
                        ),
                      ),
                      const SizedBox(width: GzSpace.s2),
                      Expanded(
                        child: _Clamp(text: reply, origin: lang, open: _replyOpen, onToggle: () => setState(() => _replyOpen = !_replyOpen)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Authored text cut to two lines with the chevron at inline-end (web `ClampText`): the paragraph and the 44 button side by side.
class _Clamp extends StatelessWidget {
  const _Clamp({required this.text, required this.origin, required this.open, required this.onToggle});

  final String text;
  final String origin;
  final bool open;
  final VoidCallback onToggle;

  static const int _limit = 104;

  @override
  Widget build(BuildContext context) {
    final long = text.length > _limit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Paragraph(text: long && !open ? _cutAt(text, _limit) : text, origin: origin),
        ),
        if (long) ...[
          const SizedBox(width: GzSpace.s1),
          GzIconButton(
            icon: open ? GzIcons.chevronUp : GzIcons.chevronDown,
            iconSize: GzIconSize.sm,
            label: open ? context.gzL10n.commonActionShowLess : context.l10n.clientReviewsRewardsShowMore,
            expanded: open,
            onPressed: onToggle,
          ),
        ],
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text, required this.origin});

  final String text;
  final String origin;

  @override
  Widget build(BuildContext context) {
    TextDirection dir = TextDirection.ltr;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]').hasMatch(ch)) {
        dir = TextDirection.rtl;
        break;
      }
      if (RegExp(r'[A-Za-z]').hasMatch(ch)) break;
    }
    final style = GzType.style(Locale(origin), GzTextRole.bodyS).copyWith(color: context.gz.colors.textPrimary, decoration: TextDecoration.none);
    return SizedBox(
      width: double.infinity,
      child: Directionality(
        textDirection: dir,
        child: Text(text, style: style, textAlign: TextAlign.start),
      ),
    );
  }
}
