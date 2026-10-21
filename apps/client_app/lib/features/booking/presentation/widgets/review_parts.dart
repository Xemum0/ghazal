import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'booking_info.dart';

/// The voucher that goes with the request (web `VoucherAttach`): a ticket, its code and its validity as a date fact; one tap changes it.
class BookingVoucherAttach extends ConsumerWidget {
  const BookingVoucherAttach({required this.voucher, required this.onChange, super.key});

  final Voucher voucher;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final until = voucher.validUntil;
    return GzPressable(
      onPressed: onChange,
      semanticLabel: '${l10n.clientBookingVoucherChange}: ${voucher.code}',
      minWidth: 0,
      scale: 1,
      borderRadius: GzRadius.mdAll,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            Container(
              width: GzSize.avatarSm,
              height: GzSize.avatarSm,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
              child: Center(
                child: GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: GzText(voucher.code, role: GzTextRole.figTitle, color: c.textStrong),
                  ),
                  if (until != null) ...[
                    const SizedBox(height: GzSpace.s1),
                    GzFactChip(
                      icon: GzIcons.calendar,
                      label: l10n.clientBookingVoucherValid,
                      value: f.date(until, DateStyle.compact),
                      small: true,
                      tone: GzFactTone.muted,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
          ],
        ),
      ),
    );
  }
}

/// What happens next as four glyph knots (send, reply, confirm, at the venue) with the reply time and the confirm window as facts: the
/// one place the future of the flow is told (web `NextThread`).
class BookingNextThread extends StatelessWidget {
  const BookingNextThread({required this.replyBy, required this.confirmHoursLabel, super.key});

  final String replyBy;
  final String confirmHoursLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GzIconProgress(
      steps: [
        GzIconProgressStep(id: 'send', icon: GzIcons.send, label: l10n.clientBookingNextSend, state: GzKnotState.now),
        GzIconProgressStep(id: 'reply', icon: GzIcons.verified, label: l10n.clientBookingNextReply, state: GzKnotState.open),
        GzIconProgressStep(id: 'confirm', icon: GzIcons.calendarCheck, label: l10n.clientBookingNextConfirm, state: GzKnotState.open),
        GzIconProgressStep(id: 'venue', icon: GzIcons.qrCode, label: l10n.clientBookingNextVenue, state: GzKnotState.open),
      ],
      label: l10n.clientBookingNextTitle,
      labels: GzProgressLabels.all,
      draw: GzDraw.off,
      note: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GzSpace.s4,
        runSpacing: GzSpace.s1,
        children: [
          GzFactChip(icon: GzIcons.timer, label: l10n.clientBookingNextReplyNote, value: replyBy, small: true, tone: GzFactTone.muted),
          GzFactChip(
            icon: GzIcons.hourglass,
            label: l10n.clientBookingNextConfirmNote,
            value: confirmHoursLabel,
            small: true,
            tone: GzFactTone.muted,
          ),
        ],
      ),
    );
  }
}

/// The consent row: the checkbox and its info glyph on one line; the sheet carries the sentence and a button that opens the terms.
class BookingConsentRow extends StatelessWidget {
  const BookingConsentRow({required this.checked, required this.onChanged, required this.bodies, required this.onRead, super.key});

  final bool checked;
  final ValueChanged<bool> onChanged;
  final List<String> bodies;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzCheckbox(label: l10n.clientBookingConsent, checked: checked, onChanged: onChanged),
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        BookingInfoButton(
          title: l10n.clientBookingConsentTitle,
          label: l10n.clientBookingConsentRead,
          paragraphs: bodies,
          extra: (sheet) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(
              label: l10n.clientBookingConsentRead,
              variant: GzButtonVariant.tertiary,
              iconEnd: GzIcons.chevronRight,
              onPressed: () {
                Navigator.of(sheet).pop();
                onRead();
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The client's own words as the last row of the Review: a glyph disk, the text in body type (clamped to three lines, never longer) and a
/// chevron that opens the step to edit it.
class BookingNoteRow extends StatelessWidget {
  const BookingNoteRow({required this.text, required this.onPressed, super.key});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: text,
      minWidth: 0,
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: Row(
            children: [
              Container(
                width: GzSize.avatarSm,
                height: GzSize.avatarSm,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                child: Center(
                  child: GzIcon(GzIcons.notes, size: GzIconSize.md, color: c.iconPrimary),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: GzText(text, role: GzTextRole.body, color: c.textPrimary, maxLines: 3),
              ),
              const SizedBox(width: GzSpace.s3),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
