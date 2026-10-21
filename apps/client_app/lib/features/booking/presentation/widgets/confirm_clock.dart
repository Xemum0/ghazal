import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The 24 hour confirm window of CL-BOOK-08 as ONE layout for every moment of the window (the shared `GzConfirmWindow` draws the elapsed
/// share, this draws what is left). A timer glyph and the absolute deadline, a 4 dp bar whose gold fill is the share of the 24 hours still
/// remaining, and the time left as an hourglass and a figure; in the final hour the same line becomes a calm mm:ss. Never red, never animated.
class BookingConfirmClock extends ConsumerWidget {
  const BookingConfirmClock({required this.deadline, required this.seconds, required this.final_, super.key});

  final DateTime deadline;

  /// Seconds left (the screen ticks).
  final int seconds;

  /// Show mm:ss instead of the hours left.
  final bool final_;

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final remaining = (seconds / (gzConfirmWindowHours * 3600)).clamp(0.0, 1.0);
    final clock = '${_two(seconds ~/ 60)}:${_two(seconds % 60)}';
    final left = gzConfirmLeft(
      f,
      context.gzL10n,
      deadline: deadline,
      now: deadline.subtract(Duration(seconds: seconds)),
    );
    final hours = (seconds / 3600).ceil().clamp(1, 1000);
    return Semantics(
      container: true,
      label: l10n.clientBookingConfirmWindowLabel,
      child: Container(
        padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GzIcon(GzIcons.timer, size: GzIconSize.md, color: c.iconAccent, semanticLabel: l10n.clientBookingConfirmByLabel),
                const SizedBox(width: GzSpace.s2),
                Expanded(
                  child: GzText(f.dateTime(deadline), role: GzTextRole.title, color: c.textStrong, figures: true),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s2),
            Semantics(
              label: l10n.clientBookingConfirmWindowLabel,
              value: left.text,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
                child: ClipRRect(
                  borderRadius: GzRadius.pillAll,
                  child: SizedBox(
                    height: GzStroke.threadMax,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: (remaining * 1000).round(),
                          child: ColoredBox(color: c.markKhayt),
                        ),
                        Expanded(
                          flex: 1000 - (remaining * 1000).round(),
                          child: ColoredBox(color: c.markTrack),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s2),
            if (final_)
              Semantics(
                label: l10n.clientBookingConfirmLeft(clock),
                child: Row(
                  children: [
                    GzIcon(GzIcons.hourglass, size: GzIconSize.sm, color: c.iconSecondary),
                    const SizedBox(width: GzSpace.s2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: GzText(clock, role: GzTextRole.figBody, color: c.textGoldInk),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzFactChip(icon: GzIcons.hourglass, label: left.text, value: f.digits(l10n.commonCountHours(hours))),
              ),
          ],
        ),
      ),
    );
  }
}
