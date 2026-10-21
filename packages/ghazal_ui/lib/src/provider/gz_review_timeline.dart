import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show DecisionActor, Listing, ListingRejectionCode, ListingStatus, ReviewDecision;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';

/// ReviewTimeline (HL-PROV review status): the audit trail of one listing, oldest first, as the Booking Thread's vertical rail: a
/// tied knot per decision with its absolute time and who made it, then the knot that is still ahead. The rule it exists to state: a
/// listing goes live only after a person at Ghazal has approved it, never because it was paid for. A rejection lists its reasons in
/// plain words and the moderator's note, and (with [planKeptUntil]) says how long the plan is kept for a resubmission.
class GzReviewTimeline extends StatelessWidget {
  const GzReviewTimeline({required this.listing, this.planKeptUntil, super.key});

  final Listing listing;

  /// Until when the plan is kept after a rejection (the web `planKeptUntil`; the generated model does not carry it yet).
  final DateTime? planKeptUntil;

  static String _status(GzL10n l, ListingStatus s) => switch (s) {
    ListingStatus.draft || ListingStatus.unknown => l.uiProviderTimelineDraft,
    ListingStatus.paymentPending => l.uiProviderTimelinePaymentPending,
    ListingStatus.pendingReview => l.uiProviderTimelinePendingReview,
    ListingStatus.approved => l.uiProviderTimelineApproved,
    ListingStatus.rejected => l.uiProviderTimelineRejected,
    ListingStatus.active => l.uiProviderTimelineActive,
    ListingStatus.expired => l.uiProviderTimelineExpired,
    ListingStatus.paused => l.uiProviderTimelinePaused,
  };

  static String _reason(GzL10n l, ListingRejectionCode c) => switch (c) {
    ListingRejectionCode.contentNotCompliant => l.uiProviderTimelineReasonContentNotCompliant,
    ListingRejectionCode.wrongCategory => l.uiProviderTimelineReasonWrongCategory,
    ListingRejectionCode.missingDetails => l.uiProviderTimelineReasonMissingDetails,
    ListingRejectionCode.unclearPricing => l.uiProviderTimelineReasonUnclearPricing,
    ListingRejectionCode.other || ListingRejectionCode.unknown => l.uiProviderTimelineReasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final past = <_Row>[
      for (final d in listing.history)
        _Row(
          key: d.id,
          state: d.to == ListingStatus.rejected ? GzKnotState.ended : GzKnotState.tied,
          title: _status(l, d.to),
          at: d.at,
          who: _who(l, d),
          note: d.note?.of(lang),
          reasons: d.codes ?? const [],
        ),
    ];
    final ahead = <_Row>[];
    switch (listing.status) {
      case ListingStatus.pendingReview:
        ahead.add(_Row(key: 'n-review', state: GzKnotState.now, title: l.uiProviderTimelineNextReview, note: l.uiProviderTimelineNextReviewNote, future: true));
        ahead.add(_Row(key: 'n-live', state: GzKnotState.open, title: l.uiProviderTimelineNextLive, note: l.uiProviderTimelineNextLiveNote, future: true));
      case ListingStatus.paymentPending || ListingStatus.draft:
        ahead.add(_Row(key: 'n-review', state: GzKnotState.open, title: l.uiProviderTimelineNextReview, note: l.uiProviderTimelineNextReviewNote, future: true));
      case ListingStatus.approved:
        ahead.add(_Row(key: 'n-live', state: GzKnotState.now, title: l.uiProviderTimelineNextLive, note: l.uiProviderTimelineNextLiveNote, future: true));
      default:
        break;
    }
    final rows = [...past, ...ahead];
    return Semantics(
      container: true,
      label: l.uiProviderTimelineLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++)
            _Item(
              row: rows[i],
              last: i == rows.length - 1,
              done: i < past.length - 1,
              keptUntil: rows[i].state == GzKnotState.ended ? planKeptUntil : null,
            ),
        ],
      ),
    );
  }

  static String _who(GzL10n l, ReviewDecision d) => switch (d.actor) {
    DecisionActor.provider => l.uiProviderTimelineYou,
    DecisionActor.system => l.uiProviderTimelineSystem,
    _ => d.actorName != null ? l.uiProviderTimelineModeratorBy(d.actorName!) : l.uiProviderTimelineModerator,
  };
}

class _Row {
  const _Row({required this.key, required this.state, required this.title, this.at, this.who, this.note, this.reasons = const [], this.future = false});

  final String key;
  final GzKnotState state;
  final String title;
  final DateTime? at;
  final String? who;
  final String? note;
  final List<ListingRejectionCode> reasons;
  final bool future;
}

/// One knot with its rail segment and its text column.
class _Item extends StatelessWidget {
  const _Item({required this.row, required this.last, required this.done, required this.keptUntil});

  final _Row row;
  final bool last;
  final bool done;
  final DateTime? keptUntil;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final r = row;
    final faint = r.future && r.state == GzKnotState.open;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: GzSize.iconLg,
            child: Column(
              children: [
                GzThreadKnot(state: r.state, endedIcon: GzIcons.close, endedTone: GzKnotEndedTone.danger),
                if (!last) ...[
                  const SizedBox(height: GzSpace.s1),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: GzSpace.s4),
                      child: SizedBox(width: GzStroke.thread, child: ColoredBox(color: done ? c.markKhayt : c.markTrack)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: GzSpace.s1, bottom: last ? 0 : GzSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzText(r.title, role: GzTextRole.title, color: faint ? c.textSecondary : c.textStrong),
                  if (r.at != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzText(f.dateTime(r.at!, DateStyle.short) + (r.who != null ? ' · ${r.who}' : ''), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                  ],
                  if (r.reasons.isNotEmpty) ...[
                    const SizedBox(height: GzSpace.s1),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < r.reasons.length; i++) ...[
                          if (i > 0) const SizedBox(height: GzSpace.s1),
                          _Reason(text: GzReviewTimeline._reason(l, r.reasons[i])),
                        ],
                      ],
                    ),
                  ],
                  if (r.note != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzText(r.note!, role: GzTextRole.caption, color: c.textSecondary),
                  ],
                  if (keptUntil != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzText(l.uiProviderTimelineKeptUntil(f.date(keptUntil!, DateStyle.short)), role: GzTextRole.caption, color: c.textSecondary, figures: true),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rejection reason: body-s in the danger ink, indented by the 16 dp list gutter (the web list shows no marker: `list-style: none`
/// is inherited from the timeline).
class _Reason extends StatelessWidget {
  const _Reason({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.s4),
    child: GzText(text, role: GzTextRole.bodyS, color: context.gz.colors.textDanger),
  );
}
