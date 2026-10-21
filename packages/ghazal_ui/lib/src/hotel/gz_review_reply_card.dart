import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Review;

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_c_kit.dart';

/// The three states of a review in the hotel's reading list.
enum GzReviewReplyState { needsReply, replied, reported }

/// ReviewReplyCard: a review as the hotel reads it (HL-GROW-06, HA-NOTI-04 / 07 / 09, ADR 0008 D11): reply once in the venue's voice
/// and report abuse; the hotel never approves, edits or hides a review (Ghazal moderates). The reviewer's monogram, name (or
/// Anonymous), the rating, the date and the event month; the text exactly as typed, in its own script and direction. Three
/// states: needs a reply (a gold-tinted pill, the staged draft quoted when there is one, Reply and Report), replied (the hotel's
/// reply in a quiet rose note, signed and dated, with no second reply), reported (a neutral pill: under review by Ghazal). No
/// photos with people are ever shown (ADR 0015 D7).
class GzReviewReplyCard extends StatelessWidget {
  const GzReviewReplyCard({required this.review, required this.state, this.onReply, this.onReport, this.last = false, super.key});

  final Review review;
  final GzReviewReplyState state;
  final VoidCallback? onReply;
  final VoidCallback? onReport;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final author = review.anonymous ? l.uiHotelReviewAnonymous : review.author.of(lang);
    final month = f.date(review.eventDate.toString(), DateStyle.monthYear);
    final origin = review.origin.value;
    final reply = review.ownerReply;
    final draft = review.replyDraft;
    final showTags = state != GzReviewReplyState.replied || review.verifiedBooking;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s4),
        decoration: gzRuleBelow(c, last: last),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GzAvatar(
                  name: author,
                  initial: review.anonymous ? null : review.monogram,
                  size: GzAvatarSize.sm,
                  voice: GzAvatarVoice.sans,
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzUserBlock(author, role: GzTextRole.title, color: c.textStrong),
                      GzFigText(
                        '${f.date(review.postedAt, DateStyle.short)} · ${l.uiHotelReviewEvent(month)}',
                        role: GzTextRole.caption,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                GzRating(value: review.rating),
              ],
            ),
            if (showTags) ...[
              const SizedBox(height: GzSpace.s3),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s2,
                children: [
                  if (state == GzReviewReplyState.needsReply) GzStatusPill(status: GzStatus.requested, label: l.uiHotelReviewNeeds),
                  if (state == GzReviewReplyState.reported) GzStatusPill(status: GzStatus.expired, label: l.uiHotelReviewReported),
                  if (review.verifiedBooking)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                        const SizedBox(width: GzSpace.s1),
                        GzText(l.uiHotelReviewVerified, role: GzTextRole.caption, color: c.textSecondary),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: GzSpace.s3),
            GzUserBlock(review.text.of(origin), role: GzTextRole.bodyS, color: c.textPrimary),
            if (state == GzReviewReplyState.replied && reply != null) ...[
              const SizedBox(height: GzSpace.s3),
              _Note(
                color: c.surfaceTint,
                head: Row(
                  children: [
                    GzIcon(GzIcons.reply, size: GzIconSize.xs, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    Expanded(
                      child: GzFigText(
                        '${l.uiHotelReviewYours(reply.by)} · ${f.date(reply.repliedAt, DateStyle.short)}',
                        role: GzTextRole.caption,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                body: reply.text.of(origin),
              ),
            ],
            if (state == GzReviewReplyState.needsReply && draft != null) ...[
              const SizedBox(height: GzSpace.s3),
              _Note(
                color: c.surfaceQuiet,
                head: GzText(l.uiHotelReviewDraft, role: GzTextRole.caption, color: c.textSecondary),
                body: draft.of(origin),
              ),
            ],
            if (state == GzReviewReplyState.needsReply) ...[
              const SizedBox(height: GzSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: GzButton(
                      label: l.uiHotelReviewReply,
                      variant: GzButtonVariant.secondary,
                      iconStart: GzIcons.reply,
                      fullWidth: true,
                      onPressed: onReply ?? () {},
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzButton(label: l.uiHotelReviewReport, variant: GzButtonVariant.tertiary, onPressed: onReport ?? () {}),
                ],
              ),
              const SizedBox(height: GzSpace.s3),
              GzText(l.uiHotelReviewOnce, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.color, required this.head, required this.body});

  final Color color;
  final Widget head;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(GzSpace.s3),
    decoration: BoxDecoration(color: color, borderRadius: GzRadius.smAll),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        head,
        const SizedBox(height: GzSpace.s1),
        GzUserBlock(body, role: GzTextRole.bodyS, color: context.gz.colors.textPrimary),
      ],
    ),
  );
}
