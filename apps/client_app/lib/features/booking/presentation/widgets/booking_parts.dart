import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_flow_model.dart';
import '../booking_glyphs.dart';
import 'booking_info.dart';
import 'booking_layout.dart';

/// "The venue replies within 4 hours" as a fact (ADR 0034): a timer glyph and the hours, no sentence. Never urgency, never a ticking clock.
class BookingReplyFact extends ConsumerWidget {
  const BookingReplyFact({required this.slaHours, super.key});

  final int slaHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final fast = slaHours <= 4;
    return GzFactChip(
      icon: GzIcons.timer,
      tone: fast ? GzFactTone.accent : GzFactTone.normal,
      label: fast ? l10n.clientBookingReplyFast : l10n.clientBookingReplyWithin,
      value: f.digits(l10n.commonCountHours(slaHours)),
    );
  }
}

/// The ruled "your date" strip (direction rule 8: a hairline above and below, not a panel): one 64 dp target that opens the calendar.
class BookingDateRow extends ConsumerWidget {
  const BookingDateRow({required this.date, required this.onPressed, super.key});

  final LocalDate date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final label = f.date(date.toString(), DateStyle.full);
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: '${context.l10n.clientBookingDateChange}: ${f.plain(label)}',
      minWidth: 0,
      scale: 1,
      child: BookingRuled(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: Row(
              children: [
                GzIcon(GzIcons.calendar, size: GzIconSize.md, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzText(label, role: GzTextRole.title, color: c.textStrong, figures: true),
                ),
                const SizedBox(width: GzSpace.s3),
                GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Voucher first": the quiet rose panel of a step reached without a voucher (CA-VCH-09, ADR 0033: there is no request without one). A
/// small drawing of the voucher, two words, the price as a figure and the info glyph behind which the sentence lives.
class BookingVoucherNeed extends StatelessWidget {
  const BookingVoucherNeed({required this.feeFils, required this.onGet, super.key});

  final int feeFils;
  final VoidCallback onGet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s1),
        child: Row(
          children: [
            Expanded(
              child: GzPressable(
                onPressed: onGet,
                semanticLabel: l10n.clientBookingNeedVoucherTitle,
                minWidth: 0,
                scale: 1,
                borderRadius: GzRadius.smAll,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
                    child: Row(
                      children: [
                        const GzIllustration(GzIllustrationName.voucher, size: GzIllustrationSize.sm),
                        const SizedBox(width: GzSpace.s3),
                        Expanded(
                          child: GzText(l10n.clientBookingNeedVoucherTitle, role: GzTextRole.d1, color: c.textStrong),
                        ),
                        const SizedBox(width: GzSpace.s3),
                        GzPrice(fils: feeFils, size: GzPriceSize.strong),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: GzSpace.s1),
            BookingInfoButton(
              title: l10n.clientBookingNeedVoucherInfoTitle,
              paragraphs: [l10n.clientBookingNeedVoucherBody, l10n.clientBookingHostingOneVoucher],
              bleed: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// What this request is for (web `RequestPlate`): the hall's own photograph, its name in serif and its facts. [wide] gives the hall the
/// width of the screen (step 1: a 16:10 photograph, the name and the facts under it); the Review keeps the compact plate.
class BookingRequestPlate extends StatelessWidget {
  const BookingRequestPlate({required this.cover, required this.hallName, required this.facts, this.wide = false, super.key});

  final ImageRef? cover;
  final String hallName;
  final List<Widget> facts;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final name = GzText(hallName, role: GzTextRole.d1, color: c.textStrong, maxLines: 2);
    final text = BookingGap(
      gap: GzSpace.s2,
      cross: CrossAxisAlignment.start,
      children: [
        name,
        GzFactRow(children: facts),
      ],
    );
    final photo = cover == null
        ? DecoratedBox(
            decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.mdAll),
          )
        : GzPhoto(src: gzImageRefSrc(cover!), alt: '', borderRadius: GzRadius.mdAll, priority: true);
    if (wide) {
      return BookingGap(
        gap: GzSpace.s3,
        children: [
          AspectRatio(aspectRatio: GzLayout.aspect16x10, child: photo),
          text,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: GzSize.thumbCompactWidth, height: GzSize.thumbCompactHeight, child: photo),
        const SizedBox(width: GzSpace.s4),
        Expanded(child: text),
      ],
    );
  }
}

/// The facts a voucher binds, as locked rows on step 1 (ADR 0033 D3): the date, then the hall as the photograph plate the Review closes
/// with. One ruled block, not a panel. The lock glyph and the voucher chip say why nothing here is editable; one quiet "Change" opens
/// the voucher quote sheet where a change is checked against the saving test.
class BookingVoucherLock extends ConsumerWidget {
  const BookingVoucherLock({required this.flow, required this.onChange, super.key});

  final FlowModel flow;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final voucher = flow.voucher!;
    final sec = flow.section;
    final session = sec.session;
    final hairline = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    return BookingRuled(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
            child: SizedBox(
              height: GzSize.touchMin,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary, semanticLabel: l10n.clientBookingFromVoucher),
                          const SizedBox(width: GzSpace.s2),
                          GzVoucherChip(code: voucher.code, tone: GzVoucherChipTone.ready),
                        ],
                      ),
                    ),
                  ),
                  EndBleed(
                    by: 8,
                    child: GzButton(label: l10n.clientBookingFromVoucherChange, variant: GzButtonVariant.tertiary, onPressed: onChange),
                  ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzIcon(GzIcons.calendar, size: GzIconSize.md, color: c.iconSecondary),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(f.date(flow.date.toString(), DateStyle.full), role: GzTextRole.title, color: c.textStrong, figures: true),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: hairline)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.rowMin),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
                child: BookingRequestPlate(
                  wide: true,
                  cover: sec.hall.cover ?? flow.venue.cover,
                  hallName: context.bi(sec.hall.name),
                  facts: [
                    GzFactChip(icon: audienceGlyph(sec.audience), label: hostingLabel(l10n, sec.audience)),
                    GzFactChip(icon: GzIcons.usersThree, label: l10n.clientBookingGuestsLabel, value: f.integer(sec.guests)),
                    if (session != null) GzFactChip(icon: sessionGlyph(session.start), label: context.bi(session.name)),
                    BookingReplyFact(slaHours: flow.slaHours),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ladies' reception" / "Men's reception" / "Mixed celebration".
String hostingLabel(AppL10n l10n, Audience a) => switch (a) {
  Audience.men => l10n.clientBookingHostingMen,
  Audience.mixed => l10n.clientBookingHostingMixed,
  _ => l10n.clientBookingHostingWomen,
};
