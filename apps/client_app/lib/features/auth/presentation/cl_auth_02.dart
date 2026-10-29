// CL-AUTH-02 WhatsApp code (CA-AUTH-05, CA-AUTH-06). Port of CL-AUTH-02.tsx.
// A chat drawing, a two-word title, the number as a figure with one word to change it, six boxes in LTR order in both languages, a timer
// figure (Resend at zero) and Open WhatsApp. No sentence anywhere: wrong, expired, locked and delivery-failed are a glyph and two or three
// words, the recovery text is behind an info glyph. Five attempts then a lock; no SMS fallback. Success draws the seal and continues: a
// new account goes to "About you" (name, sex, terms), an existing one straight to Home (no interrupted intent since ADR 0038), a password
// flow back to the password screen.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import '../application/otp_controller.dart';
import 'widgets/auth_bits.dart';
import 'widgets/otp_body.dart';

class ClAuth02Screen extends ConsumerStatefulWidget {
  const ClAuth02Screen({super.key});

  @override
  ConsumerState<ClAuth02Screen> createState() => _ClAuth02State();
}

class _ClAuth02State extends ConsumerState<ClAuth02Screen> {
  late final OtpController _otp = OtpController(ref)..addListener(_rebuild);

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _otp
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  /// The code was accepted and the seal has shown: where the flow goes on.
  void _verified() {
    if (!mounted) return;
    final flow = ref.read(authFlowProvider);
    final nav = context.gzNav;
    switch (flow.purpose) {
      case AuthPurpose.passwordReset:
        nav.pop();
      case AuthPurpose.passwordCreate:
        // The account was registered with its name and sex on "About you": only the optional steps are left.
        ref.finishSignIn(fresh: true);
      case AuthPurpose.login:
        final session = ref.read(sessionProvider);
        if (session is ClientSession && session.isNewUser) {
          nav.replace('CL-AUTH-03');
        } else {
          ref.finishSignIn();
        }
    }
  }

  /// The sign-in (or the password screen) is the screen below this one.
  void _changeNumber() => context.gzNav.pop();

  Future<void> _provider({required bool apple}) async {
    final nav = context.gzNav;
    try {
      final session = await ref.socialSignIn(apple: apple);
      if (!mounted) return;
      if (session.isNewUser) {
        nav.replace('CL-AUTH-03', params: <String, Object?>{'provider': apple ? 'apple' : 'google'});
      } else {
        ref.finishSignIn();
      }
    } on ApiProblem {
      // The failure state stays where it is: the buttons can be tried again.
    }
  }

  void _openWhatsapp() => context.gzNav.toast(GzToastSpec(message: context.l10n.clientAuthOtpOpening, icon: GzIcons.whatsapp));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final flow = ref.watch(authFlowProvider);
    final national = flow.phone.isEmpty ? AuthConfig.storyNational : flow.phone;
    final phone = '+965$national';
    final view = _otp.view;
    final settled = view == OtpView.success;
    // Locked and delivery-failed bring their own drawing (shield, chat): the head then keeps only its title.
    final stateful = view == OtpView.locked || view == OtpView.deliveryFailed;

    return GzScreen.slivers(
      top: GzTopBar(onBack: () => context.gzNav.pop()),
      bottom: GzActionBar(action: otpAction(context, ref, _otp, _verified)),
      slivers: [
        if (view == OtpView.offline) SliverToBoxAdapter(child: GzBanner(message: l10n.commonStateOffline, tone: GzBannerTone.offline)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!settled) ...[
                  AuthHead(title: l10n.clientAuthOtpTitle, art: stateful ? null : GzIllustrationName.chat),
                  const SizedBox(height: GzSpace.s5),
                  AuthNumberRow(phone: phone, format: f, onChange: _changeNumber),
                  const SizedBox(height: GzSpace.s5),
                ],
                AuthOtpBody(otp: _otp, onVerified: _verified, onOpenWhatsapp: _openWhatsapp, onApple: () => _provider(apple: true), onGoogle: () => _provider(apple: false)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
