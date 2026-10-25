import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show
        ClientSession,
        GateReason,
        GateResume,
        GzAsyncView,
        WidgetSessionGate,
        requestsRepositoryProvider,
        reviewsRepositoryProvider,
        sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, BookingDetail, BookingStatus, CreateReviewInput, RatingCategories, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/reviews_view.dart';
import 'widgets/composer_parts.dart';

/// CL-RVRW-02 Write a review. Covers CA-REV-01..04, CA-STAT-07, CA-TOOL-19,
/// CA-AUTH-10.
///
/// Rate a completed booking: overall stars, four category scores, a comment,
/// and optional photos that follow the no-people rule. Only a Completed
/// booking opens it; a guest is asked to sign in at Send with the draft kept.
/// States: default, ineligible, uploading, photo-rejected-people, submitting,
/// success, media-under-review, error, offline-draft, already-reviewed.
class ClRvrw02Screen extends ConsumerStatefulWidget {
  const ClRvrw02Screen({super.key});

  @override
  ConsumerState<ClRvrw02Screen> createState() => _ClRvrw02ScreenState();
}

class _ClRvrw02ScreenState extends ConsumerState<ClRvrw02Screen> {
  double _rating = 0;
  final Map<String, double> _cats = <String, double>{'venue': 0, 'food': 0, 'service': 0, 'value': 0};
  String _text = '';
  bool _anonymous = false;
  final List<String> _photos = <String>[];
  bool _busy = false;
  bool _failed = false;
  bool _done = false;

  GzNavigator get _nav => context.gzNav;

  @override
  Widget build(BuildContext context) {
    final params = _nav.params;
    final bookingId = params['bookingId'] as String?;
    final venueId = (params['venueId'] as String?) ?? '';
    if (bookingId == null) return _locked(context, venueId);
    final booking = ref.watch(_bookingProvider(bookingId));
    return GzAsyncView<BookingDetail?>(
      value: booking,
      loading: _composerSkeleton(context),
      onRetry: () => ref.invalidate(_bookingProvider(bookingId)),
      data: (b) {
        if (b == null || b.booking.status != BookingStatus.completed) return _locked(context, venueId);
        return _composer(context, b);
      },
    );
  }

  // Reviews open after the event: without a completed booking the screen says when ('CL-BKNG-02' is the way back for an upcoming booking).
  Widget _locked(BuildContext context, String venueId) {
    final l = context.l10n;
    final elig = venueId.isEmpty ? null : ref.watch(reviewEligibilityProvider(venueId)).value;
    final date = elig == null ? '' : context.gzFormat.date(elig.booking.eventDate.toString(), DateStyle.dayMonth);
    return GzScreen(
      top: GzTopBar(title: l.clientReviewsRewardsWriteTitle),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s8),
        child: GzEmptyState(
          key: const ValueKey<String>('review.locked'),
          illustration: GzIllustrationName.hourglass,
          title: l.clientReviewsRewardsOpens(date),
          action: GzStateAction(label: l.clientReviewsRewardsWriteLockedAction, variant: GzButtonVariant.primary, onPressed: () => _nav.pop()),
        ),
      ),
    );
  }

  Widget _composer(BuildContext context, BookingDetail b) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final venue = ref.watch(reviewVenueProvider(b.booking.venueId ?? '')).value;
    final venueName = venue?.name.of(lang) ?? '';
    final rated = _rating > 0;
    final blocker = !_busy && !rated ? l.clientReviewsRewardsWriteSubmitReason : null;
    final word = rated ? _starWord(context, _rating) : ' ';
    final hasDraft = rated || _text.isNotEmpty || _photos.isNotEmpty || _anonymous;
    final gallery = venue?.gallery.map((g) => gzImageSrc(g.file, g.baseUrl)).toList() ?? const <String>[];
    if (_done) return _sent(context, b);
    final audience = b.booking.sections.isEmpty ? null : b.booking.sections.first.audience;
    return GzScreen(
      top: GzTopBar(title: l.clientReviewsRewardsWriteTitle),
      bottom: GzActionBar(
        action: GzActionBarAction(
          label: _failed ? context.gzL10n.commonActionRetry : context.gzL10n.commonActionSend,
          disabled: !rated || _busy,
          reason: blocker,
          onPressed: () => _submit(b.booking.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_failed) ...[
              GzBanner(
                message: l.clientReviewsRewardsWriteError,
                tone: GzBannerTone.danger,
                actionLabel: context.gzL10n.commonActionRetry,
                onAction: () => _submit(b.booking.id),
              ),
              const SizedBox(height: GzSpace.s3),
            ],
            // The plate: which stay this is about (thumb 64, the name in the display face, the audience and the date as facts).
            Row(
              children: [
                if (venue?.cover != null) ...[
                  SizedBox(
                    width: GzSize.thumbLg,
                    height: GzSize.thumbLg,
                    child: ClipRRect(
                      borderRadius: GzRadius.mdAll,
                      child: GzPhoto(src: gzImageSrc(venue!.cover!.file, venue.cover!.baseUrl), alt: ''),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GzText(venueName, role: GzTextRole.d1, color: c.textStrong, header: true, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: GzSpace.s2),
                      Wrap(
                        spacing: GzSpace.s4,
                        runSpacing: GzSpace.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (audience != null) GzFactChip(icon: _audienceGlyph(audience), label: _audienceWord(l, audience)),
                          GzFactChip(
                            icon: GzIcons.calendar,
                            label: l.clientReviewsRewardsListEvent,
                            value: context.gzFormat.date(b.booking.eventDate.toString(), DateStyle.dayMonth),
                            tone: GzFactTone.muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.section),
            // Overall (five large stars, one live word under them, its height reserved) and the four categories in rows of 52.
            Semantics(
              container: true,
              label: l.clientReviewsRewardsWritePrompt(venueName),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ExcludeSemantics(
                    child: ReviewStars(
                      id: 'overall',
                      label: l.clientReviewsRewardsWriteOverall,
                      value: _rating,
                      large: true,
                      disabled: _busy,
                      onChange: (v) => setState(() => _rating = v),
                    ),
                  ),
                  const SizedBox(height: GzSpace.s2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSpace.s8),
                    child: Center(
                      child: GzText(word, role: GzTextRole.d2, color: rated ? c.textStrong : c.textSecondary, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: GzSpace.s4),
                  for (final cat in const ['venue', 'food', 'service', 'value'])
                    ReviewCategoryRow(
                      id: cat,
                      icon: _catIcon(cat),
                      label: _catLabel(context, cat),
                      value: _cats[cat]!,
                      last: cat == 'value',
                      disabled: _busy,
                      onChange: (v) => setState(() => _cats[cat] = v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.section),
            GzTextArea(
              label: l.clientReviewsRewardsWriteTextLabel,
              value: _text,
              onValueChange: (v) => setState(() => _text = v),
              rows: 3,
              maxLength: 600,
              disabled: _busy,
            ),
            const SizedBox(height: GzSpace.section),
            Semantics(
              container: true,
              label: l.clientReviewsRewardsWriteMediaTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                    child: Row(
                      children: [
                        GzText(l.clientReviewsRewardsWriteMediaTitle, role: GzTextRole.title, color: c.textStrong, header: true),
                        const SizedBox(width: GzSpace.s3),
                        GzIcon(GzIcons.user, size: GzIconSize.xs, color: c.iconSecondary),
                        const SizedBox(width: GzSpace.s1),
                        GzIcon(GzIcons.xCircle, size: GzIconSize.xs, color: c.iconDanger),
                        const SizedBox(width: GzSpace.s1),
                        Flexible(
                          child: GzText(l.clientReviewsRewardsWriteMediaNoPeople, role: GzTextRole.caption, color: c.textSecondary),
                        ),
                        const Spacer(),
                        GzInfoButton(
                          title: l.clientReviewsRewardsWriteMediaInfoTitle,
                          paragraphs: [
                            l.clientReviewsRewardsWriteMediaRule,
                            l.clientReviewsRewardsWriteMediaAllowed,
                            l.clientReviewsRewardsWriteMediaChecked,
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GzSpace.s4),
                  ReviewMediaGrid(
                    photos: _photos,
                    canAdd: _photos.length < 5 && gallery.isNotEmpty,
                    busy: _busy,
                    onAdd: () => setState(() {
                      final next = gallery.firstWhere((g) => !_photos.contains(g), orElse: () => gallery.first);
                      if (!_photos.contains(next)) _photos.add(next);
                    }),
                    onRemove: (i) => setState(() => _photos.removeAt(i)),
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: GzSpace.s2),
                    GzText(l.clientReviewsRewardsInReview, role: GzTextRole.caption, color: c.textSecondary),
                  ],
                ],
              ),
            ),
            const SizedBox(height: GzSpace.section),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzToggleRow(
                  title: l.clientReviewsRewardsWriteNameHide,
                  description: _shownName(context, ref),
                  checked: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                  disabled: _busy,
                  divider: false,
                ),
                if (hasDraft) ...[
                  const SizedBox(height: GzSpace.s4),
                  Row(
                    children: [
                      GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess),
                      const SizedBox(width: GzSpace.s1),
                      GzText(context.gzL10n.commonStateSaved, role: GzTextRole.caption, color: c.textSuccess),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sent: one drawing, one line, "Done" (the way back to the reviews when this screen did not come from them).
  Widget _sent(BuildContext context, BookingDetail b) {
    final l = context.l10n;
    final fromList = _nav.params['from'] == 'list';
    return GzScreen(
      top: GzTopBar(title: l.clientReviewsRewardsWriteTitle),
      bottom: GzActionBar(
        action: GzActionBarAction(label: context.gzL10n.commonActionDone, onPressed: () => _nav.pop()),
        secondary: fromList
            ? null
            : GzActionBarAction(
                label: l.clientReviewsRewardsWriteDoneSee,
                onPressed: () => _nav.push('CL-RVRW-01', params: <String, Object?>{'venueId': b.booking.venueId}),
              ),
      ),
      child: GzSuccessState(
        key: const ValueKey<String>('review.done'),
        illustration: GzIllustrationName.successRequest,
        title: l.clientReviewsRewardsWriteDoneTitle,
        body: l.clientReviewsRewardsWriteDoneHelper,
      ),
    );
  }

  IconData _audienceGlyph(Audience a) => switch (a) {
    Audience.men => GzIcons.sectionMen,
    Audience.mixed => GzIcons.sectionMixed,
    _ => GzIcons.sectionWomen,
  };

  String _audienceWord(AppL10n l, Audience a) => switch (a) {
    Audience.men => l.clientReviewsRewardsAudienceMen,
    Audience.mixed => l.clientReviewsRewardsAudienceMixed,
    _ => l.clientReviewsRewardsAudienceWomen,
  };

  Future<void> _submit(String bookingId) async {
    if (_busy) return;
    // A guest meets the sign-in sheet ('CL-AUTH-01', via requireSignIn) at Send with the draft kept.
    if (!ref.read(sessionProvider).isSignedIn) {
      ref.requireSignIn(GateReason.review, resume: GateResume('CL-RVRW-02', <String, Object?>{'bookingId': bookingId}));
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .createReview(
            requestId: bookingId,
            body: CreateReviewInput(
              rating: _rating,
              categories: RatingCategories(venue: _cats['venue']!, food: _cats['food']!, service: _cats['service']!, value: _cats['value']!),
              text: _text.trim(),
              origin: context.gz.locale.languageCode == 'ar' ? WireLang.ar : WireLang.en,
              anonymous: _anonymous,
            ),
          );
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (mounted) {
        _nav.toast(GzToastSpec(message: context.l10n.clientReviewsRewardsWriteDoneTitle, tone: GzToastTone.success));
        setState(() {
          _busy = false;
          _done = true;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  String _shownName(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    if (_anonymous) return l.clientReviewsRewardsGuest;
    final session = ref.watch(sessionProvider);
    final raw = session is ClientSession ? session.user.name : '';
    final parts = raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return l.clientReviewsRewardsGuest;
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts[1][0]}.';
  }

  String _starWord(BuildContext context, double v) {
    final l = context.l10n;
    return switch (v.round().clamp(1, 5)) {
      1 => l.clientReviewsRewardsWriteStar1,
      2 => l.clientReviewsRewardsWriteStar2,
      3 => l.clientReviewsRewardsWriteStar3,
      4 => l.clientReviewsRewardsWriteStar4,
      _ => l.clientReviewsRewardsWriteStar5,
    };
  }

  String _catLabel(BuildContext context, String c) {
    final l = context.l10n;
    return switch (c) {
      'food' => l.clientReviewsRewardsWriteCatFood,
      'service' => l.clientReviewsRewardsWriteCatService,
      'value' => l.clientReviewsRewardsWriteCatValue,
      _ => l.clientReviewsRewardsWriteCatVenue,
    };
  }

  IconData _catIcon(String c) => switch (c) {
    'food' => GzIcons.catering,
    'service' => GzIcons.staff,
    'value' => GzIcons.coins,
    _ => GzIcons.hall,
  };

  Widget _composerSkeleton(BuildContext context) {
    return GzScreen(
      top: GzTopBar(title: context.l10n.clientReviewsRewardsWriteTitle),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            GzSkeleton(blockSize: 64),
            SizedBox(height: GzSpace.s3),
            GzSkeleton(blockSize: 48),
            SizedBox(height: GzSpace.s3),
            GzSkeleton(blockSize: 120),
          ],
        ),
      ),
    );
  }
}

final _bookingProvider = FutureProvider.autoDispose.family<BookingDetail?, String>((ref, id) async {
  try {
    return await ref.watch(requestsRepositoryProvider).getRequest(requestId: id);
  } on Object {
    return null;
  }
});
