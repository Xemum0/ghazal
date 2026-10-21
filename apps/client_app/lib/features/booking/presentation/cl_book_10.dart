import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' hide BookingSection;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'package:client_app/app/state/state.dart';

import '../application/booking_actions.dart';
import '../application/booking_alternatives.dart';
import '../application/booking_flow_providers.dart' show bookingConfigProvider, keepStale;
import '../application/booking_request.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_layout.dart';

/// CL-BOOK-10 Confirmation window ended. Covers CA-STAT-12, CA-VCH-11, CA-BOOK-16.
///
/// The calm outcome when the 24 hour confirm window lapses (or the venue withdrew its approval, or the date was taken), as a drawing, two
/// words and two facts. The sentences (the outcome, and what happens to the voucher: a client lapse forfeits it, it does not come back; a
/// venue-side end releases it and the client may ask support for a credit voucher) are behind two info glyphs. Never blaming, never a dead
/// end: a new request, free dates, a message to the venue, the venue itself, or similar halls free on the date.
/// params: bookingId, reason (lapsed | revoked | date_taken).
class ClBook10Screen extends ConsumerWidget {
  const ClBook10Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final async = ref.watch(bookingRequestProvider((id: nav.params['bookingId'] as String?, preferApproved: false)));
    final facts = keepStale(async).value;
    final b = facts?.booking;
    return GzScreen(
      top: GzTopBar(back: GzTopBarBack.close, backLabel: context.gzL10n.commonActionClose, onBack: nav.pop, rule: false),
      bottom: facts == null
          ? null
          : GzActionBar(
              secondary: GzActionBarAction(
                label: l10n.clientBookingEndedFreeDates,
                onPressed: () => nav.openSheet(
                  'CL-VENU-03',
                  options: GzSheetOptions(
                    params: <String, Object?>{
                      'source': 'booking',
                      'venueId': facts.venueId,
                      'hallId': facts.section?.hallId,
                      'date': b!.eventDate.toString(),
                      'guests': facts.section?.guests,
                    },
                  ),
                ),
              ),
              action: GzActionBarAction(
                label: l10n.clientBookingEndedNew,
                disabled: facts.venueId == null,
                onPressed: () =>
                    nav.push('CL-BOOK-01', params: <String, Object?>{'venueId': facts.venueId, 'voucherId': facts.voucher?.id, 'fresh': true}),
              ),
            ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s8),
        child: BookingAsync<RequestFacts>(
          value: async,
          offlineText: l10n.clientBookingEndedOffline,
          onRetry: () => ref.invalidate(bookingRequestProvider),
          loading: const StepSection(gap: GzSpace.s5, children: [GzSkeleton(blockSize: 140), GzSkeleton(blockSize: 100)]),
          data: (facts) => _Ended(facts: facts),
        ),
      ),
    );
  }
}

class _Ended extends ConsumerWidget {
  const _Ended({required this.facts});

  final RequestFacts facts;

  /// The reason the screen is told, else what the request itself says: a client who did not confirm lapsed, a venue that withdrew or a
  /// date that went elsewhere is not the client's lapse.
  String _reason(String? param) {
    if (param != null) return param;
    final b = facts.booking;
    if (b.expiredReason == ExpiredReason.slotTaken) return 'date_taken';
    if (b.status == BookingStatus.cancelled && b.cancelledBy == CancelledBy.venue) return 'revoked';
    return 'lapsed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final b = facts.booking;
    final voucher = facts.voucher;
    final section = facts.section;
    final venueId = facts.venueId;
    final reason = _reason(nav.params['reason'] as String?);
    final name = context.bi(facts.targetName);
    final date = f.date(b.eventDate.toString(), DateStyle.short);
    final forfeited = reason == 'lapsed';
    final reuse = forfeited ? null : voucher?.reuseUntil;
    final hours = f.digits(l10n.commonCountHours(ref.watch(bookingConfigProvider).value?.confirmWindowHours ?? 24));
    final heading = switch (reason) {
      'revoked' => l10n.clientBookingEndedRevokedTitle,
      'date_taken' => l10n.clientBookingEndedTakenTitle,
      _ => l10n.clientBookingEndedTitle,
    };
    final outcome = switch (reason) {
      'revoked' => l10n.clientBookingEndedRevoked(name, date),
      'date_taken' => l10n.clientBookingEndedTaken(date, name),
      _ => l10n.clientBookingEndedLapsed(hours, date),
    };
    final voucherLine = forfeited
        ? l10n.clientBookingEndedVoucherForfeited
        : (reuse != null
              ? l10n.clientBookingEndedVoucherCredit(name, f.date(reuse.toString(), DateStyle.full))
              : l10n.clientBookingEndedVoucherPlain);
    final rail = venueId != null && section != null
        ? ref
                  .watch(
                    bookingAlternativesProvider(
                      AltQuery(venueId: venueId, hallId: null, date: b.eventDate, guests: section.guests, audience: section.audience, dates: false),
                    ),
                  )
                  .value
                  ?.halls ??
              const <AltHall>[]
        : const <AltHall>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepSection(
          label: heading,
          gap: GzSpace.s3,
          bottom: GzSpace.s4,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6),
              child: Align(
                child: GzIllustration(reason == 'lapsed' ? GzIllustrationName.hourglass : GzIllustrationName.calendar, size: GzIllustrationSize.lg),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: GzText(heading, role: GzTextRole.d3, color: c.textStrong, textAlign: TextAlign.center, header: true),
                ),
                const SizedBox(width: GzSpace.s1),
                GzInfoButton(title: heading, paragraphs: [outcome]),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: GzSpace.s4,
              runSpacing: GzSpace.s2,
              children: [
                GzFactChip(
                  icon: GzIcons.calendarX,
                  label: l10n.clientBookingEndedReleased,
                  value: f.date(b.eventDate.toString(), DateStyle.compact),
                  tone: GzFactTone.muted,
                ),
                if (reason == 'lapsed')
                  GzFactChip(icon: GzIcons.clockOff, label: l10n.clientBookingEndedWindow, value: hours, tone: GzFactTone.muted),
              ],
            ),
          ],
        ),
        StepSection(
          tight: true,
          label: l10n.clientBookingEndedVoucherTitle,
          children: [
            Container(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, top: GzSpace.s3, bottom: GzSpace.s3, end: GzSpace.s1),
              decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
              child: BookingGap(
                gap: GzSpace.s3,
                children: [
                  Row(
                    children: [
                      Container(
                        width: GzSize.avatarSm,
                        height: GzSize.avatarSm,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceRaised),
                        child: Center(
                          child: GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary),
                        ),
                      ),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        // the code is an LTR island: it starts at the left in both languages
                        child: voucher == null
                            ? const SizedBox.shrink()
                            : Directionality(
                                textDirection: TextDirection.ltr,
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: GzText(voucher.code, role: GzTextRole.figBody, color: c.textStrong),
                                ),
                              ),
                      ),
                      GzInfoButton(title: l10n.clientBookingEndedVoucherTitle, paragraphs: [voucherLine]),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: GzSpace.s3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: GzSpace.s3,
                            runSpacing: GzSpace.s1,
                            children: [
                              GzStatusPill(status: forfeited ? GzStatus.voucherForfeited : GzStatus.voucherActive),
                              if (reuse != null)
                                GzFactChip(
                                  icon: GzIcons.calendar,
                                  label: l10n.clientBookingEndedUntil,
                                  value: f.date(reuse.toString(), DateStyle.compact),
                                  small: true,
                                  tone: GzFactTone.muted,
                                ),
                            ],
                          ),
                        ),
                        if (!forfeited && voucher != null)
                          EndBleed(
                            by: 8,
                            child: GzButton(
                              label: l10n.clientBookingEndedRefund,
                              variant: GzButtonVariant.tertiary,
                              iconEnd: GzIcons.chevronRight,
                              onPressed: () =>
                                  nav.openSheet('CL-VCHR-05', options: GzSheetOptions(params: <String, Object?>{'voucherId': voucher.id})),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (rail.isNotEmpty)
          StepSection(
            tight: true,
            label: l10n.clientBookingTakenSimilar(date),
            children: [
              GzFactRow(
                children: [
                  GzFactChip(
                    icon: GzIcons.calendarCheck,
                    label: l10n.clientBookingTakenSimilar(''),
                    value: f.date(b.eventDate.toString(), DateStyle.compact),
                    tone: GzFactTone.muted,
                  ),
                ],
              ),
              Column(
                children: [
                  for (var i = 0; i < rail.length; i++)
                    GzListRow(
                      flush: true,
                      last: i == rail.length - 1,
                      chevron: true,
                      autoDir: true,
                      leading: SizedBox(
                        width: GzSize.thumbMd,
                        height: GzSize.thumbMd,
                        child: rail[i].venue.cover == null
                            ? DecoratedBox(
                                decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.smAll),
                              )
                            : GzPhoto(src: gzImageRefSrc(rail[i].venue.cover!), borderRadius: GzRadius.smAll),
                      ),
                      title: context.bi(rail[i].venue.name),
                      trailing: GzPrice(fils: rail[i].fils, size: GzPriceSize.strong),
                      onPressed: () {
                        ref
                            .read(searchBriefProvider.notifier)
                            .update((s) => s.copyWith(date: b.eventDate, guests: section?.guests, audience: section?.audience));
                        leaveBookingFlow(ref, nav, 'discover', thenId: 'CL-VENU-01', thenParams: <String, Object?>{'venueId': rail[i].venue.id});
                      },
                    ),
                ],
              ),
            ],
          ),
        StepSection(
          bottom: 0,
          label: l10n.clientBookingEndedViewVenue,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GzIconButton(
                  icon: GzIcons.chat,
                  label: l10n.commonActionMessage,
                  onPressed: () => nav.push('CL-MSGS-02', params: <String, Object?>{'venueId': venueId}),
                ),
                if (venueId != null)
                  GzButton(
                    label: l10n.clientBookingEndedViewVenue,
                    variant: GzButtonVariant.tertiary,
                    iconStart: GzIcons.venue,
                    onPressed: () => nav.push('CL-VENU-01', params: <String, Object?>{'venueId': venueId}),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
