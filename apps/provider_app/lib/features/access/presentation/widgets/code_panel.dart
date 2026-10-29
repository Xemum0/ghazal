// The code step of HL-ACCS-02 as a body (web `CodePanel.tsx` `CodeBody`): the six cells, the countdown figure (Resend at zero), the attempts
// pips, and the views of the inventory states. No sentence anywhere: wrong and expired are two words on the cells, the delivery failure is a
// title with its recovery text behind an info glyph. No SMS fallback: a failed delivery offers Resend, Support and nothing else.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/access_flow.dart';
import 'access_parts.dart';

enum CodeView { normal, loading, error, expired, cooldown, deliveryFailed, offline, success }

class CodePanel extends StatelessWidget {
  const CodePanel({
    required this.view,
    required this.code,
    required this.seconds,
    required this.failed,
    required this.tooMany,
    required this.onChanged,
    required this.onComplete,
    required this.onResend,
    required this.onSupport,
    this.application = false,
    this.autofocus = false,
    super.key,
  });

  final CodeView view;
  final String code;
  final int seconds;
  final int failed;
  final bool tooMany;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onComplete;
  final VoidCallback onResend;
  final VoidCallback onSupport;
  final bool autofocus;

  /// The email of a new application: the success title says the email is verified, no trust fact (nothing was trusted yet).
  final bool application;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    if (view == CodeView.success) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzSuccessState(title: application ? l.hotelAccessVerifyApplicationDone : l.hotelAccessVerifySuccessTitle, fill: false, size: GzIllustrationSize.hero, flush: true),
            if (!application) ...[
              const SizedBox(height: GzSpace.s1),
              GzFactChip(
                icon: GzIcons.shieldCheck,
                label: l.hotelAccessVerifyTrustDays(kTrustDays),
                value: l.hotelAccessVerifyTrustFact(f.integer(kTrustDays)),
              ),
            ],
          ],
        ),
      );
    }
    final String? error = switch (view) {
      CodeView.error => l.hotelAccessVerifyWrong,
      CodeView.expired => tooMany ? l.hotelAccessVerifyTooMany : l.hotelAccessVerifyExpired,
      _ => null,
    };
    final delivery = view == CodeView.deliveryFailed;
    final showTimer =
        view == CodeView.normal || view == CodeView.loading || view == CodeView.error || view == CodeView.cooldown || view == CodeView.offline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view == CodeView.cooldown) ...[
          AccessStateNote(tone: AccessNoteTone.success, text: l.hotelAccessVerifyResent),
          const SizedBox(height: GzSpace.s4),
        ],
        if (delivery) ...[
          AccessStateNote(
            tone: AccessNoteTone.danger,
            text: l.hotelAccessVerifyFailed,
            detail: l.hotelAccessVerifyFailedDetail,
            detailTitle: l.hotelAccessVerifyFailed,
          ),
          const SizedBox(height: GzSpace.s4),
        ],
        GzOtpInput(
          length: kOtpLength,
          value: code,
          onChanged: onChanged,
          onCompleted: onComplete,
          loading: view == CodeView.loading,
          error: error,
          disabled: delivery || view == CodeView.offline,
          autofocus: autofocus,
        ),
        if (showTimer) ...[
          const SizedBox(height: GzSpace.s4),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (seconds > 0)
                  GzFactChip(icon: GzIcons.timer, label: l.hotelAccessVerifyResendIn(seconds), value: l.hotelAccessVerifyTimer(f.integer(seconds)))
                else
                  Transform.translate(
                    offset: Offset(context.gz.isRtl ? 8 : -8, 0),
                    child: GzButton(
                      label: l.hotelAccessVerifyResend,
                      variant: GzButtonVariant.tertiary,
                      onPressed: view == CodeView.offline ? null : onResend,
                    ),
                  ),
                if (view == CodeView.error) AccessAttemptPips(left: (kMaxAttempts - failed).clamp(0, kMaxAttempts), total: kMaxAttempts),
              ],
            ),
          ),
        ],
        if (delivery) ...[
          const SizedBox(height: GzSpace.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Transform.translate(
              offset: Offset(context.gz.isRtl ? 8 : -8, 0),
              child: GzButton(label: l.hotelAccessSupportShort, variant: GzButtonVariant.tertiary, iconStart: GzIcons.headset, onPressed: onSupport),
            ),
          ),
        ],
      ],
    );
  }
}
