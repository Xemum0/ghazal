// CL-AUTH-04 Password (CA-AUTH-01, 02, 07). Port of CL-AUTH-04.tsx.
// The tertiary path, as modes of one screen: sign in, create an account, forgot password (request, sent, reset). The only identifier is the
// Kuwait mobile number behind the fixed +965 chip; recovery goes through the WhatsApp code, never an email link here. Each mode is one
// drawing, a title of two or three words and its fields; the single gold action lives in the action bar.
//
// Create account follows the API (POST /auth/register creates the account with name, terms and password first, then verifies the phone):
// this screen collects the number and the password, the name and terms step registers, the code step verifies (open-questions.md).
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, PhoneKw, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show PasswordResetInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import 'widgets/auth_bits.dart';
import 'widgets/password.dart';

enum _Mode { signin, create, forgot, sent, reset }

enum _View { idle, loading, invalid, locked, offline, updated }

const int _missesToLock = 3;

class ClAuth04Screen extends ConsumerStatefulWidget {
  const ClAuth04Screen({super.key});

  @override
  ConsumerState<ClAuth04Screen> createState() => _ClAuth04State();
}

class _ClAuth04State extends ConsumerState<ClAuth04Screen> {
  late _Mode _mode;
  _View _view = _View.idle;
  late String _phone;
  String _password = '';
  int _misses = 0;
  bool _phoneError = false;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final param = context.gzNav.params['mode'];
    _mode = switch (param) {
      'create' => _Mode.create,
      'forgot' => _Mode.forgot,
      _ => _Mode.signin,
    };
    _phone = ref.read(authFlowProvider).phone;
  }

  void _toMode(_Mode next) => setState(() {
        _mode = next;
        _view = _View.idle;
        _phoneError = false;
        if (next != _Mode.reset && next != _Mode.create) _password = '';
      });

  void _backToGate() {
    final flow = ref.read(authFlowProvider);
    final nav = context.gzNav..pop();
    nav.openSheet('CL-AUTH-01', options: GzSheetOptions(params: <String, Object?>{'reason': flow.pending?.reason.wire ?? 'none'}));
  }

  void _onBack() {
    if (_mode == _Mode.signin) return _backToGate();
    if (_mode == _Mode.sent) return _toMode(_Mode.forgot);
    _toMode(_Mode.signin);
  }

  bool get _validPhone => ref.read(gzFormatProvider).isValidPhone(_phone);

  void _toast(String message) => context.gzNav.toast(GzToastSpec(message: message, tone: GzToastTone.danger));

  Future<void> _signIn() async {
    if (!_validPhone) return setState(() => _phoneError = true);
    setState(() => _view = _View.loading);
    ref.rememberGate();
    ref.read(gateProvider.notifier).dismiss();
    try {
      await ref.read(sessionProvider.notifier).passwordLogin(_phone, _password);
      if (!mounted) return;
      ref.finishSignIn();
    } on ApiProblem catch (e) {
      if (!mounted) return;
      if (e.isOffline) return setState(() => _view = _View.offline);
      if (e.code == ApiProblemCode.rateLimited) return setState(() => _view = _View.locked);
      final n = _misses + 1;
      setState(() {
        _misses = n;
        _view = n >= _missesToLock ? _View.locked : _View.invalid;
      });
    }
  }

  void _createAccount() {
    if (!_validPhone) return setState(() => _phoneError = true);
    ref.rememberGate();
    ref.read(authFlowProvider.notifier).update((s) => s.copyWith(phone: PhoneKw.normalizeInput(_phone), password: _password, purpose: AuthPurpose.passwordCreate));
    context.gzNav.push('CL-AUTH-03');
  }

  Future<void> _requestCode() async {
    if (!_validPhone) return setState(() => _phoneError = true);
    setState(() => _view = _View.loading);
    try {
      await ref.sendCode(_phone, AuthPurpose.passwordReset);
      if (!mounted) return;
      ref.read(authFlowProvider.notifier).update((s) => s.copyWith(resetCode: ''));
      _toMode(_Mode.sent);
    } on ApiProblem catch (e) {
      if (!mounted) return;
      setState(() => _view = e.isOffline ? _View.offline : _View.idle);
      if (!e.isOffline) _toast(gzProblemMessage(context.gzL10n, e));
    }
  }

  Future<void> _savePassword() async {
    final flow = ref.read(authFlowProvider);
    final challenge = flow.challenge;
    if (challenge == null) return _toMode(_Mode.forgot);
    setState(() => _view = _View.loading);
    try {
      await ref.read(authRepositoryProvider).resetPassword(body: PasswordResetInput(challengeId: challenge.challengeId, code: flow.resetCode, newPassword: _password));
      if (!mounted) return;
      setState(() => _view = _View.updated);
    } on ApiProblem catch (e) {
      if (!mounted) return;
      if (e.isOffline) return setState(() => _view = _View.offline);
      // A wrong or expired code is only found out here (the reset call verifies it): back to the code step.
      setState(() => _view = _View.idle);
      _toast(gzProblemMessage(context.gzL10n, e));
      _toMode(_Mode.sent);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFlowState>(authFlowProvider, (prev, next) {
      // Back from the code step with the code collected: the reset continues with the new password.
      if (_mode == _Mode.sent && next.resetCode.isNotEmpty && next.resetCode != prev?.resetCode) _toMode(_Mode.reset);
    });
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final check = PasswordCheck(_password, PhoneKw.normalizeInput(_phone));
    final busy = _view == _View.loading;
    final offline = _view == _View.offline;
    final locked = _view == _View.locked;
    final shownPhone = '+965${_phone.isEmpty ? AuthConfig.storyNational : _phone}';

    final GzActionBarAction action;
    if (_view == _View.updated) {
      action = GzActionBarAction(label: l10n.clientAuthSharedSignIn, onPressed: () => setState(() {
            _mode = _Mode.signin;
            _view = _View.idle;
            _password = '';
          }));
    } else {
      action = switch (_mode) {
        _Mode.create => GzActionBarAction(label: l10n.commonActionContinue, onPressed: _createAccount, disabled: !check.strong || _phone.isEmpty),
        _Mode.forgot => GzActionBarAction(label: l10n.clientAuthSharedSendCode, onPressed: _requestCode, loading: busy, iconEnd: GzIcons.whatsapp),
        _Mode.sent => GzActionBarAction(label: l10n.clientAuthPwdEnterCode, onPressed: () => context.gzNav.push('CL-AUTH-02')),
        _Mode.reset => GzActionBarAction(label: l10n.commonActionSave, onPressed: _savePassword, loading: busy, disabled: !check.strong),
        _Mode.signin => GzActionBarAction(label: l10n.clientAuthSharedSignIn, onPressed: _signIn, loading: busy, disabled: offline || locked),
      };
    }

    Widget phoneField() => GzPhoneField(
          valueAlign: GzPhoneValueAlign.chip,
          label: l10n.clientAuthSharedPhone,
          value: _phone,
          onChange: (n, _) => setState(() {
            _phone = n;
            _phoneError = false;
          }),
          error: _phoneError ? l10n.clientAuthGateErrorDigits(AuthConfig.phoneDigits) : null,
          validateOnBlur: false,
          disabled: busy,
        );

    (String, GzIllustrationName)? head;
    final Widget content;
    if (_view == _View.updated) {
      content = GzSuccessState(illustration: GzIllustrationName.seal, title: l10n.clientAuthPwdUpdatedTitle, size: GzIllustrationSize.hero, flush: true);
    } else if (_mode == _Mode.signin) {
      head = (l10n.clientAuthSharedSignIn, GzIllustrationName.key);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked) ...[
            AuthInlineNote(
              tone: AuthNoteTone.danger,
              icon: GzIcons.lock,
              message: l10n.clientAuthPwdLocked,
              facts: GzFactChip(icon: GzIcons.timer, value: f.duration(AuthConfig.lockMinutes * 60000.0), label: l10n.clientAuthPwdLocked),
            ),
            const SizedBox(height: GzSpace.section),
            GzButton(label: l10n.clientAuthSharedUseCode, variant: GzButtonVariant.secondary, iconStart: GzIcons.whatsapp, fullWidth: true, onPressed: _backToGate),
          ] else ...[
            phoneField(),
            const SizedBox(height: GzSpace.s5),
            AuthPasswordField(
              label: l10n.clientAuthPwdPassword,
              value: _password,
              onChanged: (v) => setState(() {
                _password = v;
                if (_view == _View.invalid) _view = _View.idle;
              }),
              error: _view == _View.invalid ? l10n.clientAuthPwdInvalid : null,
              disabled: busy,
            ),
            const SizedBox(height: GzSpace.s1),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Semantics(
                label: l10n.clientAuthPwdForgotLabel,
                excludeSemantics: true,
                button: true,
                onTap: busy ? null : () => _toMode(_Mode.forgot),
                child: GzButton(label: l10n.clientAuthPwdForgot, variant: GzButtonVariant.tertiary, onPressed: busy ? null : () => _toMode(_Mode.forgot)),
              ),
            ),
          ],
          const SizedBox(height: GzSpace.section),
          Row(
            children: [
              GzButton(label: l10n.clientAuthSharedCreateAccount, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: busy ? null : () => _toMode(_Mode.create)),
              const Spacer(),
              if (!locked) GzButton(label: l10n.clientAuthSharedUseCode, variant: GzButtonVariant.tertiary, iconStart: GzIcons.whatsapp, onPressed: busy ? null : _backToGate),
            ],
          ),
        ],
      );
    } else if (_mode == _Mode.create) {
      head = (l10n.clientAuthSharedCreateAccount, GzIllustrationName.doorway);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          phoneField(),
          const SizedBox(height: GzSpace.s5),
          AuthPasswordField(
            label: l10n.clientAuthPwdPassword,
            value: _password,
            onChanged: (v) => setState(() => _password = v),
            error: check.containsPhone ? l10n.clientAuthPwdRulePhone : null,
            creating: true,
          ),
          const SizedBox(height: GzSpace.s5),
          AuthPasswordRules(check: check, format: f),
          const SizedBox(height: GzSpace.section),
          Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l10n.clientAuthSharedSignIn, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: () => _toMode(_Mode.signin))),
        ],
      );
    } else if (_mode == _Mode.forgot) {
      head = (l10n.clientAuthPwdForgotTitle, GzIllustrationName.envelope);
      content = phoneField();
    } else if (_mode == _Mode.sent) {
      head = (l10n.clientAuthOtpResent, GzIllustrationName.chat);
      content = AuthNumberRow(phone: shownPhone, format: f, onChange: () => _toMode(_Mode.forgot));
    } else {
      head = (l10n.clientAuthPwdResetTitle, GzIllustrationName.shield);
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthPasswordField(
            label: l10n.clientAuthPwdPassword,
            value: _password,
            onChanged: (v) => setState(() => _password = v),
            error: check.containsPhone ? l10n.clientAuthPwdRulePhone : null,
            creating: true,
            disabled: busy,
          ),
          const SizedBox(height: GzSpace.s5),
          AuthPasswordRules(check: check, format: f),
        ],
      );
    }

    return GzScreen(
      top: GzTopBar(onBack: _onBack),
      bottom: GzActionBar(action: action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) GzBanner(message: l10n.commonStateOffline, tone: GzBannerTone.offline),
          AuthBody(children: [if (head != null) AuthHead(title: head.$1, art: head.$2), content]),
        ],
      ),
    );
  }
}
