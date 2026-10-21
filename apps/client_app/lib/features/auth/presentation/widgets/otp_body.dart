import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/auth_flow.dart';
import '../../application/otp_controller.dart';
import 'auth_bits.dart';
import 'support.dart';

/// The primary action of the code step, per view (web `OtpModel.action`).
GzActionBarAction otpAction(BuildContext context, WidgetRef ref, OtpController otp, VoidCallback onVerified) {
  final l10n = context.l10n;
  switch (otp.view) {
    case OtpView.loading:
      return GzActionBarAction(label: l10n.clientAuthOtpVerify, loading: true);
    case OtpView.success:
      return GzActionBarAction(label: l10n.commonActionContinue, onPressed: onVerified);
    case OtpView.expiredCode:
      return GzActionBarAction(label: l10n.clientAuthOtpResend, onPressed: otp.resend);
    case OtpView.deliveryFailed:
      return GzActionBarAction(label: l10n.clientAuthOtpSendAgain, onPressed: otp.resend);
    case OtpView.locked:
      return GzActionBarAction(label: l10n.clientAuthSharedSupport, onPressed: () => openAuthSupport(context, ref));
    case OtpView.offline:
      return GzActionBarAction(label: l10n.clientAuthOtpVerify, disabled: true);
    default:
      return GzActionBarAction(
        label: l10n.clientAuthOtpVerify,
        disabled: otp.code.length < AuthConfig.otpLength,
        onPressed: otp.code.length < AuthConfig.otpLength ? null : () => otp.verify(onVerified: onVerified),
      );
  }
}

/// The body of the code step: the six cells, the resend timer or link, Open WhatsApp; locked and delivery-failed bring their own drawing
/// (web `OtpBody`).
class AuthOtpBody extends ConsumerWidget {
  const AuthOtpBody({required this.otp, required this.onVerified, required this.onOpenWhatsapp, required this.onApple, required this.onGoogle, super.key});

  final OtpController otp;
  final VoidCallback onVerified;
  final VoidCallback onOpenWhatsapp;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = otp.view;
    if (view == OtpView.success) {
      return GzSuccessState(illustration: GzIllustrationName.seal, title: l10n.clientAuthOtpSuccessTitle, size: GzIllustrationSize.hero, flush: true);
    }
    if (view == OtpView.locked) {
      return GzEmptyState(
        illustration: GzIllustrationName.shield,
        title: l10n.clientAuthOtpLocked,
        detail: l10n.clientAuthOtpLockedDetail,
        fill: false,
        flush: true,
        size: GzIllustrationSize.lg,
        center: false,
      );
    }
    if (view == OtpView.deliveryFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzEmptyState(
            illustration: GzIllustrationName.chat,
            artTone: GzIllustrationTone.danger,
            title: l10n.clientAuthOtpDeliveryFailed,
            detail: l10n.clientAuthOtpDeliveryFailedDetail,
            fill: false,
            flush: true,
            size: GzIllustrationSize.lg,
            center: false,
          ),
          const SizedBox(height: GzSpace.s4),
          const AuthOrDivider(),
          const SizedBox(height: GzSpace.s4),
          AuthProviderButtons(onApple: onApple, onGoogle: onGoogle),
          const SizedBox(height: GzSpace.s4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(label: l10n.clientAuthSharedSupport, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: () => openAuthSupport(context, ref)),
          ),
        ],
      );
    }
    final error = view == OtpView.wrongCode ? l10n.clientAuthOtpWrong : (view == OtpView.expiredCode ? l10n.clientAuthOtpExpired : null);
    final showResend = view != OtpView.expiredCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view == OtpView.resendCooldown) ...[AuthInlineNote(tone: AuthNoteTone.success, message: l10n.clientAuthOtpResent), const SizedBox(height: GzSpace.s4)],
        GzOtpInput(
          label: l10n.clientAuthOtpLabel,
          value: otp.code,
          onChanged: otp.change,
          onCompleted: (c) => otp.verify(value: c, onVerified: onVerified),
          loading: view == OtpView.loading,
          error: error,
          disabled: view == OtpView.offline,
          autofocus: otp.live,
        ),
        const SizedBox(height: GzSpace.s4),
        if (showResend) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                if (otp.seconds > 0)
                  GzFactChip(icon: GzIcons.timer, value: l10n.clientAuthOtpTimer(ref.watch(gzFormatProvider).integer(otp.seconds)), label: l10n.clientAuthOtpResendIn(otp.seconds))
                else
                  GzButton(label: l10n.clientAuthOtpResend, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: view == OtpView.offline ? null : otp.resend),
                const Spacer(),
                if (view == OtpView.wrongCode) AuthAttemptPips(left: otp.attemptsLeft),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s4),
        ],
        GzButton(label: l10n.commonActionOpenWhatsapp, variant: GzButtonVariant.secondary, iconStart: GzIcons.whatsapp, fullWidth: true, onPressed: view == OtpView.offline ? null : onOpenWhatsapp),
      ],
    );
  }
}
