import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, DecimalOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show RatingSummary, Review, ReviewAudience, WireLang;

import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';

/// The photograph descriptor of a review photo (`asset://...` or a served URL is used as is; a bare file name such as
/// `buffets/buffets-03-x.jpg` becomes the bundled mock image id).
String gzReviewPhotoSrc(String photo) {
  if (photo.contains('://')) return photo;
  final name = photo.split('/').last.replaceFirst(RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false), '');
  return 'asset://ghazal_mock_api/images/$name';
}

TextDirection _autoDirection(String text, TextDirection fallback) {
  for (final r in text.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFDFF) || (r >= 0xFE70 && r <= 0xFEFF)) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x24F)) return TextDirection.ltr;
  }
  return fallback;
}

/// ReviewCard (web `ReviewCard`, CA-REV, ADR 0018 D3): a review as a quiet ruled block, not a card. A monogram (never a face), the first
/// name, the stars and a date, the verified-booking mark, the text exactly as typed (`dir=auto`, in its own language), an optional strip
/// of empty-room photographs and the owner's reply set apart on the quiet surface. Long text collapses to three lines behind "Read more".
class GzReviewCard extends StatefulWidget {
  const GzReviewCard({required this.review, this.venueName, this.photos, this.collapseAt = 180, super.key});

  final Review review;

  /// The venue name for the owner reply ("Reply from Aurelia Gulf Hotel").
  final String? venueName;

  /// Photograph descriptors (see [gzReviewPhotoSrc]) shown as a strip; defaults to `review.photos`.
  final List<String>? photos;

  /// Characters shown before "Read more".
  final int collapseAt;

  @override
  State<GzReviewCard> createState() => _GzReviewCardState();
}

class _GzReviewCardState extends State<GzReviewCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final r = widget.review;
    final origin = r.origin == WireLang.ar ? 'ar' : 'en';
    final text = r.text.of(origin);
    final long = text.length > widget.collapseAt;
    final shots = widget.photos ?? r.photos;
    final name = r.anonymous ? l.uiClientReviewAnonymous : r.author.of(lang);
    final audience = r.audience == ReviewAudience.men ? l.uiClientReviewMen : l.uiClientReviewLadies;
    final originStyle = GzType.style(Locale(origin), GzTextRole.bodyS).copyWith(color: c.textPrimary, decoration: TextDecoration.none);

    Widget paragraph(String s, {int? maxLines}) => SizedBox(
      width: double.infinity,
      child: Directionality(
        textDirection: _autoDirection(s, gz.textDirection),
        child: Text(s, style: originStyle, maxLines: maxLines, overflow: maxLines != null ? TextOverflow.ellipsis : null, textAlign: TextAlign.start),
      ),
    );

    final reply = r.ownerReply;
    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GzAvatar(name: name, initial: r.anonymous || lang != 'ar' ? null : r.monogram, size: GzAvatarSize.sm),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(name, role: GzTextRole.title, color: c.textPrimary, maxLines: 1),
                        GzText(
                          '$audience · ${f.date(r.eventDate.toString(), DateStyle.compact)}',
                          role: GzTextRole.caption,
                          color: c.textSecondary,
                          figures: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzRating(value: r.rating),
                ],
              ),
              if (r.verifiedBooking) ...[
                const SizedBox(height: GzSpace.s3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                    const SizedBox(width: GzSpace.s1),
                    GzText(l.uiClientReviewVerified, role: GzTextRole.caption, color: c.textSuccess),
                  ],
                ),
              ],
              const SizedBox(height: GzSpace.s3),
              paragraph(text, maxLines: long && !_open ? 3 : null),
              if (long) ...[
                const SizedBox(height: GzSpace.s3),
                GzButton(
                  label: _open ? l.uiClientReviewLess : l.uiClientReviewMore,
                  variant: GzButtonVariant.tertiary,
                  onPressed: () => setState(() => _open = !_open),
                ),
              ],
              if (shots.isNotEmpty) ...[
                const SizedBox(height: GzSpace.s3),
                Semantics(
                  container: true,
                  label: l.uiClientReviewPhotos,
                  child: Row(
                    children: [
                      for (var i = 0; i < shots.length && i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: GzSpace.s2),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: GzLayout.aspect4x3,
                            child: ClipRRect(
                              borderRadius: GzRadius.smAll,
                              child: ColoredBox(
                                color: c.surfacePlaceholder,
                                child: GzPhoto(src: gzReviewPhotoSrc(shots[i])),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (reply != null) ...[
                const SizedBox(height: GzSpace.s3),
                SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: GzRadius.smAll,
                    child: ColoredBox(
                      color: c.surfaceQuiet,
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: GzStroke.thread,
                              child: ColoredBox(color: c.borderStrong),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.all(GzSpace.s3),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GzText(
                                      '${l.uiClientReviewReply(widget.venueName ?? '')} · ${f.date(reply.repliedAt, DateStyle.compact)}',
                                      role: GzTextRole.caption,
                                      color: c.textSecondary,
                                      figures: true,
                                    ),
                                    const SizedBox(height: GzSpace.s1),
                                    paragraph(reply.text.of(lang)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

/// RatingSummary (web `RatingSummary`): the average in the figures voice (never the serif), the star row, the review count and the four
/// category scores as 2 dp gold bars (length = quantity). A venue with no reviews reads "New", never 0.0.
class GzRatingSummary extends StatelessWidget {
  const GzRatingSummary({required this.rating, super.key});

  final RatingSummary rating;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final average = rating.average;
    if (average == null || rating.count == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzText(l.commonLabelNew, role: GzTextRole.d2, color: c.textPrimary),
          const SizedBox(height: GzSpace.s2),
          GzText(l.uiClientReviewNone, role: GzTextRole.bodyS, color: c.textSecondary),
        ],
      );
    }
    const one = DecimalOptions(minFraction: 1, maxFraction: 1);
    final cats = rating.categories;
    final rows = cats == null
        ? const <(String, double)>[]
        : [
            (l.uiClientReviewCatVenue, cats.venue),
            (l.uiClientReviewCatFood, cats.food),
            (l.uiClientReviewCatService, cats.service),
            (l.uiClientReviewCatValue, cats.value),
          ];
    return Semantics(
      container: true,
      label: l.commonA11yRating((average * 10).round() / 10, 5),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gzFigText(context, f.number(average, one), role: GzTextRole.fig3xl, color: c.textStrong),
              const SizedBox(height: GzSpace.s1),
              GzRating(value: average, variant: GzRatingVariant.stars, showValue: false),
              const SizedBox(height: GzSpace.s1),
              GzText(l.commonCountReviews(rating.count), role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(width: GzSpace.s6),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: GzSpace.s2),
                    _CategoryBar(label: rows[i].$1, value: rows[i].$2),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final shown = f.number(value, const DecimalOptions(minFraction: 1, maxFraction: 1));
    final fill = (value * 100).round();
    final rest = ((5 - value) * 100).round();
    return Row(
      children: [
        SizedBox(
          width: GzSpace.s12,
          child: GzText(label, role: GzTextRole.caption, color: c.textSecondary),
        ),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: Semantics(
            image: true,
            label: l.uiClientReviewScore(label, shown),
            excludeSemantics: true,
            child: SizedBox(
              height: GzStroke.thread,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fill > 0)
                    Expanded(
                      flex: fill,
                      child: ColoredBox(color: c.markKhayt),
                    ),
                  if (rest > 0)
                    Expanded(
                      flex: rest,
                      child: ColoredBox(color: c.markTrack),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        SizedBox(
          width: GzSpace.s6,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: gzFigText(context, shown, role: GzTextRole.figCaption, color: c.textStrong),
          ),
        ),
      ],
    );
  }
}
