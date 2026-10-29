// CL-AUTH-01 Sign in (CA-AUTH-03, 04, 05, 09, 10, 12, 13). Port of CL-AUTH-01.tsx.
// A full screen since ADR 0038: there is no guest mode, so this is what the Client app shows right after the introduction and the only door
// in (no "continue as guest", no gate sheet, no context line, nothing to resume). Phone first (compound field, fixed +965 chip), one gold
// action ("Send code" with the WhatsApp mark), Apple and Google as equals in one row, the password path as a tertiary link. There is no SMS
// fallback. The legal consent and the "partners use the Partner app" line live behind the info glyph at the foot.
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
import 'widgets/support.dart';

enum _Status { idle, loading, invalid, notWhatsapp, offline }

class ClAuth01Screen extends ConsumerStatefulWidget {
  const ClAuth01Screen({super.key});

  @override
  ConsumerState<ClAuth01Screen> createState() => _ClAuth01State();
}

class _ClAuth01State extends ConsumerState<ClAuth01Screen> {
  String _phone = '';
  _Status _status = _Status.idle;

  Future<void> _submit() async {
    if (_status == _Status.loading || _status == _Status.offline) return;
    final f = ref.read(gzFormatProvider);
    if (!f.isValidPhone(_phone)) {
      setState(() => _status = _Status.invalid);
      return;
    }
    setState(() => _status = _Status.loading);
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
    setState(() => _status = _Status.idle);
    nav.push('CL-AUTH-02');
  }

  Future<void> _provider({required bool apple}) async {
    final nav = context.gzNav;
    setState(() => _status = _Status.loading);
    try {
      final session = await ref.socialSignIn(apple: apple);
      if (!mounted) return;
      setState(() => _status = _Status.idle);
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

  void _toPassword() => context.gzNav.push('CL-AUTH-04', params: const <String, Object?>{'mode': 'signin'});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final busy = _status == _Status.loading;
    final offline = _status == _Status.offline;
    final error = _status == _Status.invalid ? l10n.clientAuthGateErrorDigits(AuthConfig.phoneDigits) : null;

    return GzScreen(
      top: GzTopBar(onBack: () => context.gzNav.pop()),
      child: AuthBody(
        spacing: GzSpace.s5,
        children: [
          AuthHead(title: l10n.clientAuthSharedSignIn, art: GzIllustrationName.key),
          if (offline) AuthInlineNote(tone: AuthNoteTone.offline, message: l10n.commonStateOffline),
          if (_status == _Status.notWhatsapp)
            AuthInlineNote(
              tone: AuthNoteTone.danger,
              message: l10n.clientAuthGateErrorNotOnWhatsapp,
              detail: l10n.clientAuthGateNotOnWhatsappDetail,
              actionLabel: l10n.clientAuthSharedSupport,
              onAction: () => openAuthSupport(context, ref),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzPhoneField(
                valueAlign: GzPhoneValueAlign.chip,
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
              const SizedBox(height: GzSpace.s5),
              GzButton(label: l10n.clientAuthSharedSendCode, iconStart: GzIcons.whatsapp, fullWidth: true, loading: busy, onPressed: offline ? null : _submit),
            ],
          ),
          const AuthOrDivider(),
          AuthProviderButtons(onApple: busy || offline ? null : () => _provider(apple: true), onGoogle: busy || offline ? null : () => _provider(apple: false)),
          Row(
            children: [
              GzButton(label: l10n.clientAuthSharedUsePassword, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: busy ? null : _toPassword),
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
      ),
    );
  }
}
