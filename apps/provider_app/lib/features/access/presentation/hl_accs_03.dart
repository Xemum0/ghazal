// HL-ACCS-03 Set your password (web `HL-ACCS-03.tsx`): the landing of the emailed invitation and of a password reset. A new staff member sees who
// invited them and in which role (read-only card), picks a password and a language. Requirements: HA-AUTH-01, HA-AUTH-02, HA-SET-05, PA-ACC-06.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show PasswordResetInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/access_flow.dart';
import '../application/invitation_providers.dart';
import 'widgets/access_parts.dart';
import 'widgets/access_support.dart';
import 'widgets/invite_card.dart';
import 'widgets/password_rules.dart';

enum _View { form, loading, error, success, expired, offline }

class HlAccs03Screen extends ConsumerStatefulWidget {
  const HlAccs03Screen({super.key});

  @override
  ConsumerState<HlAccs03Screen> createState() => _HlAccs03ScreenState();
}

class _HlAccs03ScreenState extends ConsumerState<HlAccs03Screen> {
  late final bool _reset;
  late final String _token;
  late String _password;
  late String _confirm;
  _View _view = _View.form;
  bool _touched = false;
  bool _seeded = false;
  Timer? _later;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final params = GzNavigatorScope.of(context).params;
    _reset = params['mode'] == 'reset';
    _token = (params['token'] as String?) ?? kHeroInvitationToken;
    final demo = ref.read(accessDemoPrefillProvider);
    _password = demo ? kDemoPassword : '';
    _confirm = _password;
  }

  @override
  void dispose() {
    _later?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    if (_view == _View.loading || _view == _View.offline) return;
    final nav = GzNavigatorScope.of(context);
    setState(() => _view = _View.loading);
    try {
      if (_reset) {
        final flow = ref.read(accessFlowProvider);
        final challenge = flow.resetChallenge;
        if (challenge == null) throw const ApiProblem.offline();
        await ref
            .read(authRepositoryProvider)
            .partnerResetPassword(
              body: PasswordResetInput(challengeId: challenge.challengeId, code: flow.resetCode, newPassword: _password),
            );
        ref.read(accessFlowProvider.notifier).endReset();
      } else {
        final container = ProviderScope.containerOf(context);
        await ref.read(sessionProvider.notifier).acceptInvitation(token: _token, password: _password);
        // The session opened: the app leaves the access screens by itself, so the landing is decided now.
        await landAfterSignIn(container, nav);
        return;
      }
      if (!mounted) return;
      setState(() => _view = _View.success);
      _later = Timer(const Duration(milliseconds: 1100), () => _proceed(nav));
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() {
        _view = switch (p.code) {
          ApiProblemCode.invitationExpired => _View.expired,
          ApiProblemCode.offline || ApiProblemCode.timeout => _View.offline,
          _ => _View.error,
        };
      });
    }
  }

  void _proceed(GzNavigator nav) {
    if (!mounted) return;
    if (_reset) {
      nav.reset('HL-ACCS-01', params: const {'notice': 'password-changed'});
      return;
    }
    landAfterSignIn(ProviderScope.containerOf(context), nav);
  }

  void _back() {
    final nav = GzNavigatorScope.of(context);
    if (nav.canGoBack) {
      nav.pop();
    } else {
      nav.replace('HL-ACCS-01');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final preview = _reset ? null : ref.watch(invitationPreviewProvider(_token));
    final expired =
        _view == _View.expired ||
        (preview != null &&
            preview.hasError &&
            preview.error is ApiProblem &&
            (preview.error as ApiProblem).code == ApiProblemCode.invitationExpired);
    final local = (preview?.value?.email ?? ref.read(accessFlowProvider).email).split('@').first;
    final check = checkPassword(_password, local);
    final matches = _password == _confirm;
    final valid = check.ok && matches;
    final busy = _view == _View.loading;
    final offline = _view == _View.offline;

    final GzActionBarAction action;
    if (_view == _View.success) {
      action = GzActionBarAction(label: l.commonActionContinue, onPressed: () => _proceed(nav));
    } else if (expired) {
      action = GzActionBarAction(label: l.hotelAccessAdminAction, onPressed: accessContactAdminAction(context));
    } else {
      action = GzActionBarAction(
        label: l.commonActionSave,
        onPressed: _save,
        loading: busy,
        disabled: offline || !valid || (!_reset && preview != null && !preview.hasValue),
      );
    }

    final Widget body;
    if (_view == _View.success) {
      body = GzSuccessState(title: l.hotelAccessSetupSuccessTitle, size: GzIllustrationSize.hero, flush: true);
    } else if (expired) {
      body = GzEmptyState(
        illustration: GzIllustrationName.hourglass,
        title: l.hotelAccessSetupExpiredTitle,
        detail: l.hotelAccessSetupExpiredDetail,
        detailTitle: l.hotelAccessSetupExpiredTitle,
        size: GzIllustrationSize.hero,
        flush: true,
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline) ...[AccessStateNote(tone: AccessNoteTone.offline, text: l.commonStateOffline), const SizedBox(height: GzSpace.s6)],
          AccessHead(
            art: _reset ? GzIllustrationName.key : null,
            title: l.hotelAccessSetupTitle,
            end: _reset ? null : AccessLangChip(disabled: busy),
          ),
          const SizedBox(height: GzSpace.s6),
          if (!_reset) ...[
            if (preview != null && preview.hasValue) InviteCard(preview: preview.requireValue),
            if (preview != null && preview.isLoading) const GzSkeleton(variant: GzSkeletonVariant.block),
            const SizedBox(height: GzSpace.s6),
          ],
          if (_view == _View.error) ...[
            AccessStateNote(
              tone: AccessNoteTone.danger,
              text: l.hotelAccessSetupError,
              detail: l.hotelAccessSetupErrorDetail,
              detailTitle: l.hotelAccessSetupError,
            ),
            const SizedBox(height: GzSpace.s6),
          ],
          AccessPasswordField(
            label: l.hotelAccessSetupPasswordLabel,
            newPassword: true,
            value: _password,
            disabled: busy,
            onChanged: (v) => setState(() {
              _password = v;
              _touched = true;
              if (_view == _View.error) _view = _View.form;
            }),
          ),
          const SizedBox(height: GzSpace.s5),
          PasswordRules(check: _touched || _password.isNotEmpty ? check : PasswordCheck.empty),
          const SizedBox(height: GzSpace.s5),
          AccessPasswordField(
            label: l.hotelAccessSetupConfirmLabel,
            showLabel: true,
            newPassword: true,
            value: _confirm,
            disabled: busy,
            error: _touched && _confirm.isNotEmpty && !matches ? l.hotelAccessSetupMismatch : null,
            onChanged: (v) => setState(() => _confirm = v),
          ),
        ],
      );
    }

    return GzScreen(
      top: GzTopBar(onBack: _back),
      bottom: GzActionBar(action: action),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: body,
      ),
    );
  }
}
