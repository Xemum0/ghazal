// ReviewItem (web `ReviewItem.tsx`): a review as the venue reads it, in the diet form of the shared review card: a monogram (never a face), the
// reviewer's name with the verified glyph, the stars, facts as glyph and figure (the date, the reception), the text exactly as typed in its own script
// clamped to three lines. Three states: needs a reply (the staged draft quoted, Reply and Report), replied (the venue's reply in a rose block), reported.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'grow_bits.dart';

enum ReviewItemState { needsReply, replied, reported }

class ReviewItem extends StatelessWidget {
  const ReviewItem({required this.review, required this.state, this.onReply, this.onReport, this.last = false, super.key});

  final Review review;
  final ReviewItemState state;
  final VoidCallback? onReply;
  final VoidCallback? onReport;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final author = review.anonymous ? l.hotelGrowRwAnonymous : review.author.of(lang);
    final own = review.origin.value;
    final men = review.audience == ReviewAudience.men;
    Widget quote(IconData icon, String label, String text, int lines, Color bg) => Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsetsDirectional.all(GzSpace.s3),
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
              child: GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: ReviewParagraph(text, color: c.textPrimary, maxLines: lines),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GzAvatar(name: author, initial: review.anonymous ? null : review.monogram, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GzUserText(author, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                          ),
                          if (review.verifiedBooking) ...[
                            const SizedBox(width: GzSpace.s1),
                            Semantics(
                              label: l.hotelGrowRwVerified,
                              child: GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: GzSpace.s1),
                      GzFactRow(
                        label: l.hotelGrowFactsLabel,
                        children: [
                          GzFactChip(
                            icon: GzIcons.calendar,
                            valueWidget: GzText(dm(f, f.isoDay(review.postedAt)), role: GzTextRole.figCaption, color: c.textSecondary, figures: true),
                            label: l.hotelGrowRwPosted,
                            small: true,
                            tone: GzFactTone.muted,
                          ),
                          GzFactChip(
                            icon: men ? GzIcons.sectionMen : GzIcons.sectionWomen,
                            label: men ? l.hotelGrowFactMen : l.hotelGrowFactLadies,
                            small: true,
                            tone: GzFactTone.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                GzRating(value: review.rating),
              ],
            ),
            const SizedBox(height: GzSpace.s3),
            ReviewParagraph(review.text.of(own), color: c.textPrimary, maxLines: 3),
            if (state == ReviewItemState.replied && review.ownerReply != null) ...[
              const SizedBox(height: GzSpace.s3),
              quote(GzIcons.reply, l.hotelGrowRwYourReply, review.ownerReply!.text.of(own), 3, c.surfaceTintSoft),
            ],
            if (state == ReviewItemState.needsReply && review.replyDraft != null) ...[
              const SizedBox(height: GzSpace.s3),
              quote(GzIcons.edit, l.hotelGrowRwDraft, review.replyDraft!.of(own), 2, c.surfaceQuiet),
            ],
            if (state == ReviewItemState.needsReply) ...[
              const SizedBox(height: GzSpace.s3),
              Row(
                children: [
                  GzButton(label: l.hotelGrowRwReply, variant: GzButtonVariant.secondary, iconStart: GzIcons.reply, onPressed: onReply),
                  const SizedBox(width: GzSpace.s2),
                  GzButton(label: l.hotelGrowRwReport, variant: GzButtonVariant.tertiary, onPressed: onReport),
                ],
              ),
            ],
            if (state == ReviewItemState.reported) ...[
              const SizedBox(height: GzSpace.s3),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzTag(label: l.hotelGrowRwReported, icon: GzIcons.flag),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A guest's words (`dir="auto"` on the web): the paragraph runs in its own direction and sits on that side, so an Arabic review in the
/// English UI is flush right. Own voice by script, like [GzUserText].
class ReviewParagraph extends StatelessWidget {
  const ReviewParagraph(this.text, {required this.color, this.maxLines, super.key});

  final String text;
  final Color color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final style = GzType.style(Locale(gzScriptOf(text)), GzTextRole.bodyS).copyWith(color: color, decoration: TextDecoration.none);
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        style: style,
        textDirection: gzFirstStrongOr(text, Directionality.of(context)),
        textAlign: TextAlign.start,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }
}
