// HL-ACCS-02 Verify with email (web `HL-ACCS-02.tsx`): one reusable code screen for a new device, a password reset, the step-up before a
// high-risk action and the email of a new application (mode `application`, PA-ACC-07: the right code opens the session of the new account and the
// landing rule shows the application under review). Six boxes LTR in both languages, the sixth digit submits, resend after 60 s.
// Requirements: HA-AUTH-01, HA-SET-03, HA-SET-01, PA-ACC-07.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerPasswordForgotInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart' show applicationChallengeProvider;
import '../../../l10n/l10n.dart';
import '../application/access_flow.dart';
import 'widgets/access_parts.dart';
import 'widgets/access_support.dart';
import 'widgets/code_panel.dart';

class HlAccs02Screen extends ConsumerStatefulWidget {
  const HlAccs02Screen({super.key});

  @override
  ConsumerState<HlAccs02Screen> createState() => _HlAccs02ScreenState();
}

class _HlAccs02ScreenState extends ConsumerState<HlAccs02Screen> {
  late final CodeMode _mode;
  CodeView _view = CodeView.normal;
  String _code = '';
  int _seconds = kResendSeconds;
  int _failed = 0;
  bool _tooMany = false;
  bool _seeded = false;
  Timer? _tick;
  Timer? _later;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _mode = parseCodeMode(GzNavigatorScope.of(context).params['mode']);
    final challenge = _mode == CodeMode.application ? ref.read(applicationChallengeProvider)?.challenge : ref.read(sessionProvider.notifier).challenge;
    _seconds = challenge?.resendAfterSeconds ?? kResendSeconds;
    _startTick();
    if (_mode == CodeMode.reset) unawaited(_sendResetCode());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _later?.cancel();
    super.dispose();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds <= 0 || !mounted) return;
      setState(() => _seconds--);
    });
  }

  /// A password reset asks the server for a code first (the sign-in challenge was opened by the sign-in itself).
  Future<void> _sendResetCode() async {
    final email = ref.read(accessFlowProvider).email;
    try {
      final challenge = await ref.read(authRepositoryProvider).partnerForgotPassword(body: PartnerPasswordForgotInput(email: email));
      if (!mounted) return;
      ref.read(accessFlowProvider.notifier).startReset(email, challenge);
      setState(() => _seconds = challenge.resendAfterSeconds);
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() => _view = p.code == ApiProblemCode.offline || p.code == ApiProblemCode.timeout ? CodeView.offline : CodeView.deliveryFailed);
    }
  }

  void _change(String next) {
    setState(() {
      _code = next;
      if (_view == CodeView.error || _view == CodeView.expired || _view == CodeView.cooldown) _view = CodeView.normal;
    });
  }

  Future<void> _verify([String? value]) async {
    final code = value ?? _code;
    if (code.length < kOtpLength || _view == CodeView.loading) return;
    final nav = GzNavigatorScope.of(context);
    if (_mode == CodeMode.reset) {
      ref.read(accessFlowProvider.notifier).setResetCode(code);
      nav.replace('HL-ACCS-03', params: const {'mode': 'reset'});
      return;
    }
    setState(() => _view = CodeView.loading);
    try {
      if (_mode == CodeMode.stepUp) {
        // The contract has no partner step-up challenge yet (requests.md): the confirmation closes the screen.
        setState(() => _view = CodeView.success);
        _later = Timer(const Duration(milliseconds: 1100), _done);
        return;
      }
      final container = ProviderScope.containerOf(context);
      if (_mode == CodeMode.application) {
        await ref.read(applicationChallengeProvider.notifier).verify(code);
      } else {
        await ref.read(sessionProvider.notifier).partnerVerifyCode(code);
      }
      // The session opened: the app leaves the access screens by itself, so the landing is decided now (the success beat is the lands-on-Today).
      await landAfterSignIn(container, nav);
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() {
        switch (p.code) {
          case ApiProblemCode.otpInvalid:
            _failed++;
            _tooMany = _failed >= kMaxAttempts;
            _view = _tooMany ? CodeView.expired : CodeView.error;
          case ApiProblemCode.otpLocked:
            _tooMany = true;
            _view = CodeView.expired;
          case ApiProblemCode.otpExpired:
            _tooMany = false;
            _view = CodeView.expired;
          case ApiProblemCode.offline || ApiProblemCode.timeout:
            _view = CodeView.offline;
          default:
            _view = CodeView.deliveryFailed;
        }
        if (_view == CodeView.expired) _seconds = 0;
      });
    }
  }

  void _done() {
    if (!mounted) return;
    final nav = GzNavigatorScope.of(context);
    if (_mode == CodeMode.stepUp) {
      nav.pop();
      nav.toast(GzToastSpec(message: context.l10n.hotelAccessStepupDone, tone: GzToastTone.success));
      return;
    }
    landAfterSignIn(ProviderScope.containerOf(context), nav);
  }

  /// A fresh code. A sign-in has no resend endpoint (requests.md): the person goes back to sign in again, which sends one.
  Future<void> _resend() async {
    if (_mode == CodeMode.reset) {
      setState(() {
        _code = '';
        _failed = 0;
        _tooMany = false;
        _view = CodeView.cooldown;
      });
      await _sendResetCode();
      return;
    }
    final nav = GzNavigatorScope.of(context);
    if (_mode == CodeMode.application) {
      // the account exists but its address is not verified: signing in with it sends a fresh code (the new device)
      ref.read(accessFlowProvider.notifier).setEmail(ref.read(applicationChallengeProvider)?.email ?? '');
      nav.reset('HL-ACCS-01');
      return;
    }
    if (nav.canGoBack) {
      nav.pop();
    } else {
      nav.replace('HL-ACCS-01');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final applying = _mode == CodeMode.application;
    final email = applying ? (ref.watch(applicationChallengeProvider)?.email ?? ref.watch(accessFlowProvider).email) : ref.watch(accessFlowProvider).email;
    final demo = ref.read(accessDemoPrefillProvider);
    final shown = email.isNotEmpty ? email : (ref.read(sessionProvider.notifier).challenge?.destinationHint ?? (demo ? kDemoEmail : ''));
    final masked = maskEmail(shown);
    final support = accessSupportAction(context, ref);
    final art = switch (_view) {
      CodeView.expired => GzIllustrationName.hourglass,
      CodeView.deliveryFailed => GzIllustrationName.warning,
      CodeView.offline => GzIllustrationName.wifiOff,
      _ => switch (_mode) {
        CodeMode.reset => GzIllustrationName.key,
        CodeMode.stepUp => GzIllustrationName.shield,
        CodeMode.signIn || CodeMode.application => GzIllustrationName.envelope,
      },
    };
    final title = switch (_mode) {
      CodeMode.stepUp => l.hotelAccessStepupTitle,
      CodeMode.application => l.hotelAccessVerifyApplicationTitle,
      _ => l.hotelAccessVerifyTitle,
    };
    final done = _view == CodeView.success;
    final GzActionBarAction action = switch (_view) {
      CodeView.loading => GzActionBarAction(label: l.hotelAccessVerifySubmit, loading: true),
      CodeView.success => GzActionBarAction(label: l.commonActionContinue, onPressed: _done),
      CodeView.expired || CodeView.deliveryFailed => GzActionBarAction(label: l.hotelAccessVerifyResend, onPressed: _resend),
      _ => GzActionBarAction(label: l.hotelAccessVerifySubmit, disabled: _view == CodeView.offline || _code.length < kOtpLength, onPressed: _verify),
    };

    return GzScreen(
      top: const GzTopBar(),
      bottom: GzActionBar(action: action),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!done) ...[
              if (_view == CodeView.offline) ...[
                AccessStateNote(tone: AccessNoteTone.offline, text: l.commonStateOffline),
                const SizedBox(height: GzSpace.s5),
              ],
              AccessHead(art: art, title: title),
              const SizedBox(height: GzSpace.s5),
              if (_mode == CodeMode.stepUp) ...[
                _ActionLine(text: l.hotelAccessStepupActionBilling, icon: GzIcons.receipt),
                const SizedBox(height: GzSpace.s5),
              ],
              AccessNumberRow(masked: masked),
              const SizedBox(height: GzSpace.s5),
            ],
            CodePanel(
              view: _view,
              code: _code,
              seconds: _seconds,
              failed: _failed,
              tooMany: _tooMany,
              application: applying,
              onChanged: _change,
              onComplete: _verify,
              onResend: _resend,
              onSupport: support,
            ),
          ],
        ),
      ),
    );
  }
}

/// Step-up: the action being confirmed, as one ruled line (a glyph and two words).
class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: GzSize.thumbSm,
            height: GzSize.thumbSm,
            decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: GzIcon(icon, size: GzIconSize.sm, color: c.iconPrimary),
          ),
          const SizedBox(width: GzSpace.s3),
          GzText(text, role: GzTextRole.title, color: c.textStrong),
        ],
      ),
    );
  }
}
