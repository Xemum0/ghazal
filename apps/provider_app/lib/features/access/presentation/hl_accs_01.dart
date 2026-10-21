// HL-ACCS-01 Sign in (web `HL-ACCS-01.tsx`): email and password, no sign-up, one empty-hall photograph, the wordmark, a language chip.
// Requirements: HA-AUTH-01, HA-SET-05, PA-ACC-01, PA-ACC-02, PA-ACC-06.
import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerLoginStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/access_flow.dart';
import 'widgets/access_parts.dart';
import 'widgets/invite_sheet.dart';

const String _kPhoto = 'asset://ghazal_mock_api/images/ballrooms-14-skylight-vault-long-tables';

enum _Status { idle, loading, error, locked, offline }

class HlAccs01Screen extends ConsumerStatefulWidget {
  const HlAccs01Screen({super.key});

  @override
  ConsumerState<HlAccs01Screen> createState() => _HlAccs01ScreenState();
}

class _HlAccs01ScreenState extends ConsumerState<HlAccs01Screen> {
  late String _email;
  late String _password;
  _Status _status = _Status.idle;
  int _failed = 0;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final demo = ref.read(accessDemoPrefillProvider);
    final typed = ref.read(accessFlowProvider).email;
    _email = typed.isNotEmpty ? typed : (demo ? kDemoEmail : '');
    _password = demo ? kDemoPassword : '';
  }

  bool get _ready => isValidEmail(_email) && _password.isNotEmpty;

  Future<void> _submit() async {
    if (_status == _Status.loading || _status == _Status.locked || !_ready) {
      return;
    }
    setState(() => _status = _Status.loading);
    final nav = GzNavigatorScope.of(context);
    final flow = ref.read(accessFlowProvider.notifier);
    final container = ProviderScope.containerOf(context);
    try {
      final result = await ref.read(sessionProvider.notifier).partnerLogin(_email, _password);
      if (!mounted) return;
      flow.setEmail(_email.trim());
      if (result.status == PartnerLoginStatus.signedIn) {
        setState(() => _status = _Status.idle);
        await landAfterSignIn(container, nav);
      } else {
        setState(() => _status = _Status.idle);
        nav.push('HL-ACCS-02', params: const {'mode': 'sign-in'});
      }
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() {
        if (p.code == ApiProblemCode.offline || p.code == ApiProblemCode.timeout) {
          _status = _Status.offline;
        } else if (p.code == ApiProblemCode.rateLimited || p.code == ApiProblemCode.otpLocked) {
          _status = _Status.locked;
        } else {
          _failed++;
          _status = _failed >= kMaxAttempts ? _Status.locked : _Status.error;
        }
      });
    }
  }

  void _edit() {
    if (_status == _Status.error || _status == _Status.offline) setState(() => _status = _Status.idle);
  }

  void _forgot() {
    ref.read(accessFlowProvider.notifier).setEmail(isValidEmail(_email) ? _email.trim() : '');
    GzNavigatorScope.of(context).push('HL-ACCS-02', params: const {'mode': 'reset'});
  }

  void _invite() {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (sheetContext) => InviteSheetContent(
        onClose: () => nav.closeSheet(),
        onOpenInvitation: () {
          nav.closeSheet();
          nav.push('HL-ACCS-03', params: const {'mode': 'invite'});
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelAccessInviteTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final busy = _status == _Status.loading;
    final locked = _status == _Status.locked;
    final offline = _status == _Status.offline;
    final until = f.time(ref.read(clockProvider)().add(const Duration(minutes: kLockMinutes)));
    final safeTop = MediaQuery.paddingOf(context).top;

    return GzScreen(
      bottom: GzActionBar(
        action: GzActionBarAction(label: l.hotelAccessSigninSubmit, onPressed: _submit, loading: busy, disabled: offline || locked || !_ready),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: safeTop, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.controlLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GzWordmark(size: GzWordmarkSize.lg, script: context.gz.isAr ? GzWordmarkScript.arabic : GzWordmarkScript.latin),
                  AccessLangChip(disabled: busy),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            ClipRRect(
              borderRadius: GzRadius.mdAll,
              child: SizedBox(
                height: 184,
                child: GzPhoto(src: _kPhoto, alt: l.hotelAccessPhotoAlt, priority: true),
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            if (_status == _Status.idle && GzNavigatorScope.of(context).params['notice'] == 'password-changed') ...[
              AccessStateNote(tone: AccessNoteTone.success, icon: GzIcons.lock, text: context.gzL10n.commonStateSaved),
              const SizedBox(height: GzSpace.s4),
            ],
            if (offline) ...[
              AccessStateNote(tone: AccessNoteTone.offline, text: context.gzL10n.commonStateOffline),
              const SizedBox(height: GzSpace.s4),
            ],
            if (_status == _Status.error) ...[
              AccessStateNote(
                tone: AccessNoteTone.danger,
                text: l.hotelAccessSigninInvalid,
                detail: l.hotelAccessSigninInvalidDetail,
                detailTitle: l.hotelAccessSigninInvalidTitle,
              ),
              const SizedBox(height: GzSpace.s4),
            ],
            if (locked) ...[
              AccessStateNote(
                tone: AccessNoteTone.danger,
                icon: GzIcons.lock,
                text: l.hotelAccessSigninPaused,
                facts: GzFactChip(icon: GzIcons.clock, label: l.hotelAccessSigninPausedUntil(until), value: until),
                detail: l.hotelAccessSigninPausedDetail(until),
                detailTitle: l.hotelAccessSigninPaused,
              ),
              const SizedBox(height: GzSpace.s4),
            ],
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
              child: GzTextField(
                value: _email,
                dir: GzFieldDir.ltr,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const ['username'],
                autocorrect: false,
                enableSuggestions: false,
                disabled: busy || locked,
                startAdornment: GzIcon(GzIcons.mail, size: GzIconSize.sm, color: c.iconSecondary),
                onValueChange: (v) {
                  _email = v;
                  _edit();
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            AccessPasswordField(
              label: l.hotelAccessSigninPasswordLabel,
              value: _password,
              disabled: busy || locked,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submit(),
              onChanged: (v) {
                _password = v;
                _edit();
                setState(() {});
              },
            ),
            const SizedBox(height: GzSpace.s4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Transform.translate(
                offset: Offset(context.gz.isRtl ? -8 : 8, 0),
                child: GzButton(label: l.hotelAccessSigninForgot, variant: GzButtonVariant.tertiary, onPressed: busy || offline ? null : _forgot),
              ),
            ),
            const SizedBox(height: GzSpace.s5),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: GzIconListRow(icon: GzIcons.mail, title: l.hotelAccessSigninInvite, flush: true, onPressed: busy ? null : _invite),
            ),
          ],
        ),
      ),
    );
  }
}
