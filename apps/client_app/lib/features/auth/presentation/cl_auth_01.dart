// CL-AUTH-01 Sign in (sheet; CA-AUTH-03, 04, 05, 09, 10, 12, CA-VCH-04). Port of CL-AUTH-01.tsx.
// The single identity entry (no separate Sign up and Login, the identity decides) and the reusable guest-gate sheet: the strip under the
// title is the whole context line, so the draft is never lost and nothing needs a sentence. Phone first (compound field, fixed +965 chip),
// one gold action ("Send code" with the WhatsApp mark), Apple and Google as equals in one row, the password path as a tertiary link. There is
// no SMS fallback. The legal consent and the "partners use the Partner app" line live behind the info glyph at the foot of the sheet.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import 'widgets/auth_bits.dart';
import 'widgets/legal.dart';
import 'widgets/resume_strip.dart';
import 'widgets/support.dart';

enum _Status { idle, loading, invalid, notWhatsapp, offline }

/// The reason the gate was opened for: the open gate request first, then the sheet's own params (`none` is the plain sign-in:
/// onboarding's "I already have an account", an empty Bookings tab: no context line, nothing waiting). A sheet opened with neither shows
/// the shared story (a request to the first venue), so a harness has something to draw.
GateReason? authGateReason(GateRequest? open, Object? param) {
  if (open != null) return open.reason;
  if (param == 'none') return null;
  if (param == null) return GateReason.sendRequest;
  return GateReason.parse(param);
}

class ClAuth01Screen extends ConsumerStatefulWidget {
  const ClAuth01Screen({super.key});

  @override
  ConsumerState<ClAuth01Screen> createState() => _ClAuth01State();
}

class _ClAuth01State extends ConsumerState<ClAuth01Screen> {
  String _phone = '';
  _Status _status = _Status.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.rememberGate();
    });
  }

  Future<void> _submit() async {
    if (_status == _Status.loading || _status == _Status.offline) return;
    final f = ref.read(gzFormatProvider);
    if (!f.isValidPhone(_phone)) {
      setState(() => _status = _Status.invalid);
      return;
    }
    setState(() => _status = _Status.loading);
    ref.rememberGate();
    final nav = context.gzNav;
    try {
      await ref.sendCode(_phone, AuthPurpose.login);
    } on ApiProblem catch (e) {
      if (!mounted) return;
      if (e.isOffline) {
        setState(() => _status = _Status.offline);
      } else if (e.code == ApiProblemCode.rateLimited) {
        setState(() => _status = _Status.idle);
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, e), tone: GzToastTone.danger));
      } else {
        setState(() => _status = _Status.notWhatsapp);
      }
      return;
    }
    if (!mounted) return;
    nav
      ..closeSheet()
      ..push('CL-AUTH-02');
  }

  Future<void> _provider({required bool apple}) async {
    ref.rememberGate();
    final nav = context.gzNav;
    setState(() => _status = _Status.loading);
    try {
      final session = await ref.socialSignIn(apple: apple);
      if (!mounted) return;
      nav.closeSheet();
      if (session.isNewUser) {
        nav.push('CL-AUTH-03', params: <String, Object?>{'provider': apple ? 'apple' : 'google'});
      } else {
        ref.finishSignIn();
      }
    } on ApiProblem catch (e) {
      if (!mounted) return;
      setState(() => _status = e.isOffline ? _Status.offline : _Status.idle);
    }
  }

  void _toPassword() {
    ref.rememberGate();
    context.gzNav
      ..closeSheet()
      ..push('CL-AUTH-04', params: const <String, Object?>{'mode': 'signin'});
  }

  void _notNow() {
    ref.read(favouritesProvider.notifier).clearSignupNudge();
    context.gzNav.closeSheet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final reason = authGateReason(ref.watch(gateProvider), nav.params['reason']);
    final busy = _status == _Status.loading;
    final offline = _status == _Status.offline;
    final nudge = reason == GateReason.save;
    final error = _status == _Status.invalid ? l10n.clientAuthGateErrorDigits(AuthConfig.phoneDigits) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthSheetHead(title: l10n.clientAuthSharedSignIn, onClose: () => nav.closeSheet()),
        const SizedBox(height: GzSpace.s4),
        AuthResumeStrip(reason: reason, compact: true),
        if (reason != null) const SizedBox(height: GzSpace.s4),
        if (offline) ...[AuthInlineNote(tone: AuthNoteTone.offline, message: l10n.commonStateOffline), const SizedBox(height: GzSpace.s4)],
        if (_status == _Status.notWhatsapp) ...[
          AuthInlineNote(
            tone: AuthNoteTone.danger,
            message: l10n.clientAuthGateErrorNotOnWhatsapp,
            detail: l10n.clientAuthGateNotOnWhatsappDetail,
            actionLabel: l10n.clientAuthSharedSupport,
            onAction: () => openAuthSupport(context, ref),
          ),
          const SizedBox(height: GzSpace.s4),
        ],
        GzPhoneField(
          label: l10n.clientAuthSharedPhone,
          value: _phone,
          onChange: (national, _) => setState(() {
            _phone = national;
            if (_status == _Status.invalid || _status == _Status.notWhatsapp) _status = _Status.idle;
          }),
          error: error,
          disabled: busy,
          validateOnBlur: false,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l10n.clientAuthSharedSendCode, iconStart: GzIcons.whatsapp, fullWidth: true, loading: busy, onPressed: offline ? null : _submit),
        const SizedBox(height: GzSpace.s4),
        const AuthOrDivider(),
        const SizedBox(height: GzSpace.s4),
        AuthProviderButtons(onApple: busy || offline ? null : () => _provider(apple: true), onGoogle: busy || offline ? null : () => _provider(apple: false)),
        const SizedBox(height: GzSpace.s4),
        Row(
          children: [
            GzButton(label: l10n.clientAuthSharedUsePassword, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: busy ? null : _toPassword),
            if (nudge) ...[const SizedBox(width: GzSpace.s6), GzButton(label: l10n.clientAuthSharedNotNow, variant: GzButtonVariant.tertiary, onPressed: _notNow)],
            const Spacer(),
            AuthEndShift(
              child: AuthLegalInfo(
                title: l10n.clientAuthSharedInfoTitle,
                rows: false,
                body: (sheet) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzText(l10n.clientAuthSharedPartnerNote, role: GzTextRole.body, color: c.textPrimary),
                    const SizedBox(height: GzSpace.s4),
                    AuthSmallPrint(sheetContext: sheet, parentContext: context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
