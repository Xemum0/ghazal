// The WhatsApp code body of the Profile flow: deletion asks for a fresh code (CL-PROF-06) and a new phone number is verified the same
// way (CL-PROF-03). Text diet (ADR 0034): the number is a value beside the WhatsApp mark, a wrong code is two words, a timer is a figure,
// locked and not-delivered are a drawing and three words. Port of the web `_components/reauth.tsx`.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/profile_code.dart';
import 'profile_parts.dart';

/// The primary action of the code step, per view (the sheet footer or the screen's action bar).
GzActionBarAction codeAction(BuildContext context, ProfileCodeController code, VoidCallback onVerified) {
  final l = context.l10n;
  switch (code.view) {
    case CodeView.loading:
      return GzActionBarAction(label: l.clientAuthOtpVerify, loading: true);
    case CodeView.success:
      return GzActionBarAction(label: l.commonActionContinue, onPressed: onVerified);
    case CodeView.expiredCode:
      return GzActionBarAction(label: l.clientAuthOtpResend, onPressed: code.resend);
    case CodeView.deliveryFailed:
      return GzActionBarAction(label: l.clientAuthOtpSendAgain, onPressed: code.resend);
    case CodeView.locked:
      return GzActionBarAction(label: l.clientAuthSharedSupport, onPressed: () => context.gzNav.push('CL-MSGS-02', params: const <String, Object?>{'support': true}));
    case CodeView.offline:
      return GzActionBarAction(label: l.clientAuthOtpVerify, disabled: true);
    default:
      final ready = code.code.length >= kCodeLength;
      return GzActionBarAction(label: l.clientAuthOtpVerify, disabled: !ready, onPressed: ready ? () => code.verify(onVerified: onVerified) : null);
  }
}

class ProfileCodeBody extends StatelessWidget {
  const ProfileCodeBody({required this.code, required this.phoneText, required this.onVerified, this.sheet = false, super.key});

  final ProfileCodeController code;

  /// The formatted number the code went to.
  final String phoneText;
  final VoidCallback onVerified;
  final bool sheet;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final view = code.view;
    if (view == CodeView.success) {
      return GzSuccessState(illustration: GzIllustrationName.seal, title: l.clientAuthOtpSuccessTitle, size: sheet ? GzIllustrationSize.lg : GzIllustrationSize.hero, fill: !sheet, flush: true);
    }
    if (view == CodeView.locked) {
      return GzEmptyState(
        illustration: GzIllustrationName.shield,
        title: l.clientAuthOtpLocked,
        detail: l.clientAuthOtpLockedDetail,
        action: GzStateAction(label: l.clientAuthSharedSupport, variant: GzButtonVariant.tertiary, onPressed: () => context.gzNav.push('CL-MSGS-02', params: const <String, Object?>{'support': true})),
        fill: false,
        flush: true,
        size: GzIllustrationSize.lg,
        center: false,
      );
    }
    if (view == CodeView.deliveryFailed) {
      return GzEmptyState(
        illustration: GzIllustrationName.chat,
        artTone: GzIllustrationTone.danger,
        title: l.clientAuthOtpDeliveryFailed,
        detail: l.clientAuthOtpDeliveryFailedDetail,
        action: GzStateAction(label: l.clientAuthOtpSendAgain, variant: GzButtonVariant.secondary, onPressed: code.resend),
        secondary: GzStateAction(label: l.clientAuthSharedSupport, onPressed: () => context.gzNav.push('CL-MSGS-02', params: const <String, Object?>{'support': true})),
        fill: false,
        flush: true,
        size: GzIllustrationSize.lg,
        center: false,
      );
    }
    final error = view == CodeView.wrongCode ? l.clientAuthOtpWrong : (view == CodeView.expiredCode ? l.clientAuthOtpExpired : null);
    final frozen = view == CodeView.offline;
    final showResend = view != CodeView.expiredCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const ProfDisk(icon: GzIcons.whatsapp),
            const SizedBox(width: GzSpace.s4),
            Flexible(child: GzNum(phoneText, role: GzTextRole.figTitle, color: c.textStrong)),
          ],
        ),
        const SizedBox(height: GzSpace.s5),
        GzOtpInput(
          label: l.clientAuthOtpLabel,
          value: code.code,
          onChanged: code.change,
          onCompleted: (v) => code.verify(value: v, onVerified: onVerified),
          loading: view == CodeView.loading,
          error: error,
          disabled: frozen,
          autofocus: code.live,
        ),
        const SizedBox(height: GzSpace.s5),
        if (showResend)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: code.seconds > 0
                  ? GzFactChip(icon: GzIcons.timer, value: l.clientAuthOtpTimer(code.seconds.toString()), label: l.clientAuthOtpResendIn(code.seconds))
                  : GzButton(label: l.clientAuthOtpResend, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: frozen ? null : code.resend),
            ),
          )
        else
          GzButton(label: l.clientAuthOtpResend, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: code.resend),
      ],
    );
  }
}
