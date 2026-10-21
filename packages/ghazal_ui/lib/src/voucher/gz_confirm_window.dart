import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../core/core.dart';
import '../foundation.dart';
import 'gz_confirm_left.dart';

/// ConfirmWindow: the 24 hour window the client has to confirm an approved request (owner rule, fixed). Calm by design: the deadline
/// is an absolute sentence, the time left is hours and minutes (never seconds, never a ticking digit), the thread bar only shows how
/// much of the window has passed and never turns red. Under an hour it says minutes; at the end it says the window closed and that
/// the voucher is no longer valid, in a neutral tone.
///
/// States (derived): open, last hour, lapsed (the deadline passed), confirmed ([confirmedAt] set). [now] defaults to the story or
/// device clock of the format scope; [onConfirm] shows the one primary action (omit when the screen has its own bar); [onDark]
/// restyles it for the ink panel of the approval hero.
class GzConfirmWindow extends StatelessWidget {
  const GzConfirmWindow({required this.deadline, this.confirmedAt, this.onConfirm, this.onDark = false, this.now, super.key});

  /// When the window closes (`booking.confirmBy`).
  final DateTime deadline;

  /// When the client confirmed (`booking.confirmedAt`): switches to the done state.
  final DateTime? confirmedAt;
  final VoidCallback? onConfirm;
  final bool onDark;

  /// The instant to measure from; defaults to the format scope's clock.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final c = context.gz.colors;
    final muted = onDark ? c.textOnDarkMuted : c.textSecondary;
    final strong = onDark ? c.textOnDark : c.textStrong;
    final left = gzConfirmLeft(f, l, deadline: deadline, now: now ?? f.now());
    final done = confirmedAt != null;
    final List<Widget> body;
    if (done) {
      body = [
        GzText(l.uiVoucherConfirmDoneTitle, role: GzTextRole.title, color: strong, header: true),
        GzText(l.uiVoucherConfirmDoneAt(f.dateTime(confirmedAt!, DateStyle.short)), role: GzTextRole.bodyS, color: muted, figures: true),
      ];
    } else if (left.ended) {
      body = [
        GzText(l.uiVoucherConfirmLapsedTitle, role: GzTextRole.title, color: strong, header: true),
        GzText(l.uiVoucherConfirmLapsedBody, role: GzTextRole.bodyS, color: muted),
      ];
    } else {
      final share = (left.passed * 1000).round();
      body = [
        GzText(l.uiVoucherConfirmEyebrow, role: GzTextRole.label, color: muted),
        GzText(l.uiVoucherConfirmBy(f.dateTime(deadline, DateStyle.full)), role: GzTextRole.title, color: strong, figures: true, header: true),
        Semantics(
          label: l.uiVoucherConfirmThread,
          value: left.text,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
              child: ClipRRect(
                borderRadius: GzRadius.pillAll,
                child: SizedBox(
                  height: GzStroke.threadMax,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (share > 0) Expanded(flex: share, child: ColoredBox(color: c.markKhayt)),
                      if (share < 1000) Expanded(flex: 1000 - share, child: ColoredBox(color: onDark ? c.markTrackOnDark : c.markTrack)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        GzText.rich(
          TextSpan(
            style: TextStyle(fontWeight: context.gz.text(GzTextRole.title).fontWeight),
            children: GzFigures.spans(context, left.text, role: GzTextRole.bodyS),
          ),
          role: GzTextRole.bodyS,
          color: strong,
          semanticLabel: left.text,
        ),
        GzText(l.uiVoucherConfirmHeld, role: GzTextRole.caption, color: muted),
        if (onConfirm != null)
          Padding(
            padding: const EdgeInsets.only(top: GzSpace.s3),
            child: GzButton(label: l.commonConfirmBooking, fullWidth: true, onPressed: onConfirm),
          ),
      ];
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: done || left.ended ? null : l.uiVoucherConfirmEyebrow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < body.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), body[i]],
        ],
      ),
    );
  }
}
