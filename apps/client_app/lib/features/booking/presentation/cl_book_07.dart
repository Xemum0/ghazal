import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' hide BookingSection;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_alternatives.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_layout.dart';

/// CL-BOOK-07 That date is no longer available (sheet). Covers CA-BOOK-16, CA-VDET-22, CA-VCH-11.
///
/// Recovery in drawings, glyphs and figures: a calendar drawing, the outcome in two words (date taken, session taken, window ended), the
/// date as a fact and the voucher as a ticket with a check; then the nearest free dates of the same hall (a date and its voucher price),
/// similar halls free on the same date, a new date from the calendar, or back to the results. Calm, blameless, never a dead end.
/// params: reason (date_taken | session_taken | confirm_window_ended), venueId, date, from (the screen that opened it).
class ClBook07Screen extends ConsumerWidget {
  const ClBook07Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowAsync = ref.watch(bookingFlowProvider);
    return BookingAsync<FlowModel>(
      value: flowAsync,
      onRetry: () => ref.invalidate(bookingFlowProvider),
      loading: const _TakenSkeleton(),
      data: (flow) => _Taken(flow: flow),
    );
  }
}

class _TakenSkeleton extends StatelessWidget {
  const _TakenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const BookingGap(
      gap: GzSpace.s5,
      children: [GzSkeleton(inlineSize: 200, blockSize: 56), GzSkeleton(blockSize: 24), GzSkeleton(blockSize: 24), GzSkeleton(blockSize: 24)],
    );
  }
}

class _Taken extends ConsumerWidget {
  const _Taken({required this.flow});

  final FlowModel flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final p = nav.params;
    final reason = (p['reason'] as String?) ?? 'date_taken';
    final venueId = (p['venueId'] as String?) ?? flow.venue.id;
    final date = p['date'] is String ? LocalDate.parse(p['date']! as String) : flow.date;
    final from = p['from'] as String?;
    final sec = flow.section;
    final hallId = venueId == flow.venue.id ? sec.hall.id : null;
    final session = sec.session;
    final alt = ref.watch(
      bookingAlternativesProvider(AltQuery(venueId: venueId, hallId: hallId, date: date, guests: flow.guests, audience: flow.audience)),
    );
    final title = switch (reason) {
      'confirm_window_ended' => l10n.clientBookingTakenExpiredTitle,
      'session_taken' => l10n.clientBookingTakenSessionTitle,
      _ => l10n.clientBookingTakenTitle,
    };
    final none = alt.hasValue && alt.requireValue.dates.isEmpty && alt.requireValue.halls.isEmpty;
    final art = none ? GzIllustrationName.noResult : (reason == 'confirm_window_ended' ? GzIllustrationName.hourglass : GzIllustrationName.calendar);

    String dayLabel(LocalDate d) {
      final civil = f.civil(d.toString());
      final year = d.year == date.year ? '' : ' ${f.integer(civil.year)}';
      return '${f.weekdayName(civil.weekday, NameStyle.short)} ${f.integer(civil.day)} ${f.monthName(civil.month, short: true)}$year';
    }

    Widget price(int fils) => GzPrice(fils: fils, size: GzPriceSize.strong);

    void pickDate(LocalDate picked) {
      if (flow.voucher != null && !flow.demo) {
        // A voucher is bound to its quote: the move to another date is checked by the voucher quote sheet (the saving test).
        nav.closeSheet();
        nav.openSheet(
          'CL-VCHR-04',
          options: GzSheetOptions(
            params: <String, Object?>{...bookingVoucherParams(flow, from ?? 'CL-BOOK-07'), 'voucherId': flow.voucher!.id, 'date': picked.toString()},
          ),
        );
        return;
      }
      patchBookingDraft(ref, (d) => d.copyWith(venueId: venueId, eventDate: picked, clearVoucher: true));
      nav.closeSheet();
      if (from == 'CL-BOOK-05') {
        goBookingStep(ref, nav, from: 5, to: 1);
      } else if (from != 'CL-BOOK-01') {
        nav.push('CL-BOOK-01', params: <String, Object?>{'venueId': venueId, 'date': picked.toString()});
      }
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s5 + 1),
      child: BookingGap(
        gap: GzSpace.s5,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: GzIllustration(art, size: GzIllustrationSize.md)),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Center(
                    child: BookingGap(
                      gap: GzSpace.s2,
                      cross: CrossAxisAlignment.start,
                      children: [
                        GzText(title, role: GzTextRole.d1, color: c.textStrong),
                        GzFactRow(
                          children: [
                            GzFactChip(
                              icon: reason == 'confirm_window_ended' ? GzIcons.calendar : GzIcons.calendarX,
                              label: l10n.clientBookingSentDate,
                              value: f.date(date.toString(), DateStyle.compact),
                              tone: GzFactTone.muted,
                            ),
                            if (reason == 'session_taken' && session != null)
                              GzFactChip(icon: sessionGlyph(session.start), label: context.bi(session.name), tone: GzFactTone.muted),
                            GzFactChip(
                              icon: GzIcons.usersThree,
                              label: l10n.clientBookingGuestsLabel,
                              value: f.integer(flow.guests),
                              tone: GzFactTone.muted,
                            ),
                            // The web wraps this chip in an inline span, so its row is the body line (28; Arabic 32) tall, the chip at the top.
                            SizedBox(
                              height: context.gz.isAr ? 32 : 28,
                              child: Align(
                                alignment: AlignmentDirectional.topStart,
                                child: GzFactChip(
                                  icon: GzIcons.ticket,
                                  label: l10n.clientBookingTakenVoucherValid,
                                  valueWidget: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess),
                                  tone: GzFactTone.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: EndBleed(
                    child: GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: nav.closeSheet),
                  ),
                ),
              ],
            ),
          ),
          BookingAsync<Alternatives>(
            value: alt,
            offlineBanner: false,
            loading: Semantics(
              label: l10n.clientBookingTakenLoading,
              child: const BookingGap(
                gap: GzSpace.s3,
                children: [
                  GzSkeleton(inlineSize: 160, blockSize: 24),
                  GzSkeleton(inlineSize: 96, blockSize: 20),
                  GzSkeleton(inlineSize: 160, blockSize: 24),
                ],
              ),
            ),
            data: (a) {
              if (a.dates.isEmpty && a.halls.isEmpty) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: GzText(l10n.clientBookingTakenNone, role: GzTextRole.title, color: c.textStrong, textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: GzSpace.s2),
                    GzInfoButton(
                      title: l10n.clientBookingTakenNone,
                      paragraphs: [l10n.clientBookingTakenNoneInfo(f.date(date.toString(), DateStyle.short))],
                    ),
                  ],
                );
              }
              return BookingGap(
                gap: GzSpace.s5,
                children: [
                  if (a.dates.isNotEmpty)
                    Semantics(
                      container: true,
                      label: l10n.clientBookingTakenNearest,
                      child: Column(
                        children: [
                          for (var i = 0; i < a.dates.length; i++)
                            GzIconListRow(
                              flush: true,
                              last: i == a.dates.length - 1,
                              icon: GzIcons.calendarCheck,
                              title: dayLabel(a.dates[i].date),
                              trailing: price(a.dates[i].fils),
                              chevron: true,
                              onPressed: () => pickDate(a.dates[i].date),
                            ),
                        ],
                      ),
                    ),
                  if (a.halls.isNotEmpty)
                    BookingGap(
                      gap: GzSpace.s2,
                      cross: CrossAxisAlignment.start,
                      children: [
                        GzFactRow(
                          children: [
                            GzFactChip(
                              icon: GzIcons.calendarCheck,
                              label: l10n.clientBookingTakenSimilar(''),
                              value: f.date(date.toString(), DateStyle.compact),
                              tone: GzFactTone.muted,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            for (var i = 0; i < a.halls.length; i++)
                              GzListRow(
                                flush: true,
                                last: i == a.halls.length - 1,
                                chevron: true,
                                autoDir: true,
                                leading: SizedBox(
                                  width: GzSize.thumbMd,
                                  height: GzSize.thumbMd,
                                  child: a.halls[i].venue.cover == null
                                      ? DecoratedBox(
                                          decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.smAll),
                                        )
                                      : GzPhoto(src: gzImageRefSrc(a.halls[i].venue.cover!), borderRadius: GzRadius.smAll),
                                ),
                                title: context.bi(a.halls[i].venue.name),
                                trailing: price(a.halls[i].fils),
                                onPressed: () {
                                  ref
                                      .read(searchBriefProvider.notifier)
                                      .update((b) => b.copyWith(date: date, guests: flow.guests, audience: flow.audience));
                                  nav.closeSheet();
                                  leaveBookingFlow(
                                    ref,
                                    nav,
                                    'discover',
                                    thenId: 'CL-VENU-01',
                                    thenParams: <String, Object?>{'venueId': a.halls[i].venue.id},
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          BookingGap(
            gap: GzSpace.s2,
            children: [
              GzButton(
                label: l10n.clientBookingTakenAnother,
                variant: GzButtonVariant.secondary,
                iconStart: GzIcons.calendar,
                fullWidth: true,
                onPressed: () {
                  nav.closeSheet();
                  nav.openSheet(
                    'CL-VENU-03',
                    options: GzSheetOptions(
                      params: <String, Object?>{
                        'source': 'booking',
                        'venueId': venueId,
                        'hallId': hallId,
                        'date': date.toString(),
                        'guests': flow.guests,
                      },
                    ),
                  );
                },
              ),
              Align(
                child: GzButton(
                  label: l10n.clientBookingTakenResults,
                  variant: GzButtonVariant.tertiary,
                  onPressed: () {
                    nav.closeSheet();
                    leaveBookingFlow(ref, nav, 'discover', thenId: 'CL-DISC-03');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
