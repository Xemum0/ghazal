// The pieces of the booking rules screen (web `RulesParts.tsx`): the fixed booking-mode panel and the "What couples see" timeline.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// Booking mode is always "Request to book" (ADR 0033): shown as a fact, never as a switch.
class BookingModeCard extends StatelessWidget {
  const BookingModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
      child: Row(
        children: [
          GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary),
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: GzText(context.l10n.hotelVenueModeRequest, role: GzTextRole.title, color: c.textStrong),
          ),
        ],
      ),
    );
  }
}

/// Request, reply, confirm, pay the venue directly: the four steps a couple lives through, with this venue's reply window.
class CouplesTimeline extends StatelessWidget {
  const CouplesTimeline({required this.replyHours, required this.confirmHours, this.payText, super.key});

  final String replyHours;
  final String confirmHours;
  final String? payText;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final rows = <(String, String?)>[
      (l.hotelVenueTlRequest, null),
      (l.hotelVenueTlReply(replyHours), null),
      (l.hotelVenueTlConfirm(confirmHours), null),
      (l.hotelVenueTlPay, payText),
    ];
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: c.borderStrong, width: GzStroke.hair),
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: GzSize.timelineRail,
                      child: Column(
                        children: [
                          const SizedBox(height: GzSpace.s2),
                          Transform.rotate(
                            angle: 0.785398,
                            child: Container(width: GzSize.knotBead, height: GzSize.knotBead, color: c.markKhayt),
                          ),
                          const SizedBox(height: GzSpace.s2),
                          Expanded(
                            child: i == rows.length - 1 ? const SizedBox(width: GzStroke.hair) : Container(width: GzStroke.hair, color: c.borderStrong),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(bottom: i == rows.length - 1 ? 0 : GzSpace.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GzText(rows[i].$1, role: GzTextRole.title, color: c.textStrong, figures: true),
                            if (rows[i].$2 != null) ...[
                              const SizedBox(height: GzSpace.s1),
                              GzText(rows[i].$2!, role: GzTextRole.bodyS, color: c.textSecondary, figures: true),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
