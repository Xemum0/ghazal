import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Booking, BookingFor;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_c_kit.dart';

/// GuestCard: the client card of the hotel booking detail (ADR 0008 D8, ADR 0033): the monogram, the name (in its own script), the
/// verified-phone and first-booking markers, then a ruled list (who the booking is for, the person to contact, their number) and the
/// icon row Call / Chat / Voucher. The number is an LTR isolate and shows only when the client shared it (ADR 0003, OQ-B-19);
/// otherwise Call is disabled and says why, and Chat is always there.
class GzGuestCard extends StatelessWidget {
  const GzGuestCard({required this.booking, this.onCall, this.onChat, this.onVoucher, this.voucher = true, super.key});

  /// Only the client fields of the booking are read: `clientName`, `contact`, `verifiedPhone`, `firstBooking`.
  final Booking booking;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onVoucher;

  /// Hide the Voucher action (a request that has no voucher attached; kept for the visit card).
  final bool voucher;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final contact = booking.contact;
    final bookingFor = switch (contact.bookingFor) {
      BookingFor.bride => l.uiHotelGuestBride,
      BookingFor.groom => l.uiHotelGuestGroom,
      BookingFor.family => l.uiHotelGuestFamily,
      BookingFor.planner => l.uiHotelGuestPlanner,
      BookingFor.unknown => '',
    };
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(GzSpace.s4),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GzAvatar(name: booking.clientName, size: GzAvatarSize.md, voice: GzAvatarVoice.sans),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzUserBlock(booking.clientName, role: GzTextRole.title, color: c.textStrong, maxLines: 2),
                      const SizedBox(height: GzSpace.s1),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: GzSpace.s3,
                        children: [
                          if (booking.verifiedPhone)
                            _Mark(
                              icon: GzIcon(GzIcons.verified, size: GzIconSize.xs, color: c.iconSuccess),
                              label: l.uiHotelGuestVerified,
                            ),
                          if (booking.firstBooking)
                            _Mark(
                              icon: const GzThreadBead(tone: GzBeadTone.ink),
                              label: l.uiHotelGuestFirst,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s4),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: Column(
                children: [
                  _Item(
                    label: l.uiHotelGuestBookingFor,
                    value: GzText(bookingFor, role: GzTextRole.bodyS, color: c.textStrong, textAlign: TextAlign.end),
                  ),
                  _Item(
                    label: l.uiHotelGuestContact,
                    value: GzUserTextEnd(contact.name, role: GzTextRole.bodyS, color: c.textStrong),
                  ),
                  _Item(
                    label: l.uiHotelGuestPhone,
                    value: contact.shared
                        ? Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: GzNum(f.plain(f.phone(contact.phone)), role: GzTextRole.bodyS, color: c.textStrong),
                          )
                        : GzText(l.uiHotelGuestNotShared, role: GzTextRole.bodyS, color: c.textSecondary, textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s4),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Action(
                      icon: GzIcons.phone,
                      label: l.uiHotelGuestCall,
                      hint: contact.shared ? null : l.uiHotelGuestCallWhy,
                      onPressed: contact.shared ? (onCall ?? () {}) : null,
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: _Action(icon: GzIcons.chat, label: l.uiHotelGuestChat, onPressed: onChat ?? () {}),
                  ),
                  if (voucher) ...[
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: _Action(icon: GzIcons.ticket, label: l.uiHotelGuestVoucher, onPressed: onVoucher ?? () {}),
                    ),
                  ],
                ],
              ),
            ),
            if (!contact.shared) ...[
              const SizedBox(height: GzSpace.s4),
              GzText(l.uiHotelGuestCallWhy, role: GzTextRole.caption, color: c.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      icon,
      const SizedBox(width: GzSpace.s1),
      GzText(label, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
    ],
  );
}

class _Item extends StatelessWidget {
  const _Item({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: gzRuleBelow(c),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          GzText(label, role: GzTextRole.caption, color: c.textSecondary),
          const SizedBox(width: GzSpace.s4),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onPressed, this.hint});

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: hint == null ? label : '$label. $hint',
      borderRadius: GzRadius.smAll,
      minHeight: GzSize.rowMin,
      builder: (context, st) {
        final fg = st.enabled ? c.textStrong : c.textDisabled;
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.rowMin),
          decoration: BoxDecoration(
            color: st.pressed ? c.surfaceQuiet : null,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GzIcon(icon, size: GzIconSize.md, color: fg),
              const SizedBox(height: GzSpace.s1),
              GzText(label, role: GzTextRole.caption, color: fg),
            ],
          ),
        );
      },
    );
  }
}
