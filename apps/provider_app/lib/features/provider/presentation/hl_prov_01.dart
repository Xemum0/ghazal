// HL-PROV-01 Apply to join (web `HL-PROV-01.tsx`): the application form of a service provider or a private hall (PA-ACC-07, PA-ACC-08, ADR 0038).
// Two steps and a result: the account type (a hotel or a hall chain is onboarded by Ghazal), the form (business name in Arabic and English, up to
// three categories plus an open "Other" note, governorate, contact person, phone, email, a short description, an optional licence reference) and
// "Application received": the account stays under review and Ghazal staff accept or reject it (HL-ACCS-04 shows the wait and the decision). A
// rejected application comes back here through "Edit and resubmit" (route param `resubmit`), prefilled, with the staff note on top.
// Signed out (round 2b, route param `signedOut` from HL-ACCS-01 "Apply to join", or no session at all): the form also makes the account. A first
// section "Your account" (email, password with its strength, repeat) comes before the business information; the email is also the contact email.
// Submit calls the public `submitPartnerApplication`, then HL-ACCS-02 (mode `application`) asks for the emailed code and lands on HL-ACCS-04.
// Requirements: PA-ACC-01..03, PA-ACC-07, PA-ACC-08, PA-REV-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GuestSession, GzAsyncView, gzProblemMessage, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/application_form.dart';
import '../application/provider_actions.dart';
import '../application/provider_data.dart';
import 'widgets/application_account.dart';
import 'widgets/application_fields.dart';
import 'widgets/application_steps.dart';

enum _Step { choose, form, received }

class HlProv01Screen extends ConsumerStatefulWidget {
  const HlProv01Screen({super.key});

  @override
  ConsumerState<HlProv01Screen> createState() => _HlProv01State();
}

class _HlProv01State extends ConsumerState<HlProv01Screen> {
  _Step? _step;
  ApplicantKind? _kind;
  ApplicationForm? _edited;
  ApplicantAccount _account = const ApplicantAccount();
  bool _tried = false;
  bool _failed = false;
  bool _offline = false;

  bool _isResubmit(BuildContext context) => GzNavigatorScope.of(context).params['resubmit'] == true;

  /// The form on screen: what the person typed, else the rejected application (Edit and resubmit), else a blank one of the chosen kind.
  ApplicationForm _form(ApplicationSetup? setup, bool resubmit) {
    final edited = _edited;
    if (edited != null) return edited;
    final app = setup?.application;
    if (resubmit && app != null) return ApplicationForm.fromApplication(app);
    return ApplicationForm(kind: _kind ?? ApplicantKind.serviceProvider);
  }

  /// No partner session: the sign-in screen opened the form for a new applicant (or the app was reopened on it signed out).
  bool _isSignedOut(BuildContext context) => GzNavigatorScope.of(context).params['signedOut'] == true || ref.watch(sessionProvider) is GuestSession;

  void _edit(ApplicationForm f) => setState(() {
    _edited = f;
    _failed = false;
    _offline = false;
  });

  void _editAccount(ApplicantAccount a) => setState(() {
    _account = a;
    _failed = false;
    _offline = false;
  });

  Future<void> _send(ApplicationSetup setup, bool resubmit, bool signedOut) async {
    setState(() {
      _tried = true;
      _failed = false;
    });
    final form = _form(setup, resubmit);
    if (!form.isComplete || (signedOut && _account.bad(form.email))) return;
    final actions = ref.read(listingActionsProvider.notifier);
    final nav = GzNavigatorScope.of(context);
    final g = context.gzL10n;
    final lang = context.gz.locale.languageCode == 'ar' ? WireLang.ar : WireLang.en;
    final ActionResult<Object?> r = signedOut
        ? await actions.applyPublic(form, _account.password, lang)
        : (resubmit ? await actions.resubmit(form) : await actions.apply(form));
    if (!mounted) return;
    switch (r) {
      case ActionSuccess():
        if (signedOut) {
          // the unverified account exists and the code is on its way: the form stays here, under the code screen, for Back
          setState(() => _edited = form);
          nav.push('HL-ACCS-02', params: const {'mode': 'application'});
          return;
        }
        setState(() {
          _edited = form;
          _step = _Step.received;
        });
      case ActionFailure(:final problem):
        if (problem.code == ApiProblemCode.emailAlreadyRegistered) {
          // an account with this email exists (a rejected applicant included: sign in, then Edit and resubmit): said under the email field
          setState(() => _account = _account.copyWith(takenEmail: form.email.trim().toLowerCase()));
          return;
        }
        final offline = problem.code == ApiProblemCode.offline || problem.code == ApiProblemCode.timeout;
        setState(() {
          _offline = offline;
          _failed = !offline;
        });
        // an application that was decided meanwhile is not editable any more: say so, the status screen shows the decision
        if (problem.code == ApiProblemCode.applicationNotEditable) nav.toast(GzToastSpec(message: gzProblemMessage(g, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final resubmit = _isResubmit(context);
    final signedOut = _isSignedOut(context) && !resubmit;
    final step = _step ?? (resubmit ? _Step.form : _Step.choose);
    final setupAsync = ref.watch(applicationSetupProvider);
    final setup = setupAsync.value;
    final busy = ref.watch(listingActionsProvider).isBusy;
    final form = _form(setup, resubmit);

    final Widget top;
    final GzActionBar bottom;
    final Widget body;
    switch (step) {
      case _Step.choose:
        top = const GzTopBar();
        bottom = GzActionBar(
          action: GzActionBarAction(
            label: l.hotelProviderContinue,
            iconEnd: GzIcons.chevronRight,
            disabled: _kind == null,
            reason: _kind == null ? l.hotelProviderChooseReason : null,
            onPressed: () => setState(() {
              _edited = (_edited ?? const ApplicationForm()).copyWith(kind: _kind);
              _step = _Step.form;
            }),
          ),
        );
        body = ApplyChoose(kind: _kind, onPick: (k) => setState(() => _kind = k));
      case _Step.received:
        top = GzTopBar(title: l.hotelProviderSubmittedBar, back: GzTopBarBack.hide);
        bottom = GzActionBar(
          action: GzActionBarAction(
            label: l.hotelProviderSubmittedStatus,
            iconEnd: GzIcons.chevronRight,
            onPressed: () => nav.reset('HL-ACCS-04', params: {'variant': 'application-review', 'account': form.isHall ? 'hotel' : 'provider'}),
          ),
        );
        body = ApplyReceived(name: form.nameFor(lang), hall: form.isHall);
      case _Step.form:
        final title = resubmit ? l.hotelProviderFormBarEdit : (form.isHall ? l.hotelProviderTypeHallTitle : l.hotelProviderTypeProviderTitle);
        final bar = GzTopBar(title: title, onBack: resubmit ? null : () => setState(() => _step = _Step.choose));
        top = _offline
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [bar, GzBanner(message: l.hotelProviderOfflineStrip(context.gzFormat.time(DateTime.now())), tone: GzBannerTone.offline)],
              )
            : bar;
        bottom = GzActionBar(
          action: GzActionBarAction(
            label: l.hotelProviderSubmit,
            iconEnd: GzIcons.check,
            loading: busy,
            disabled: _offline || setup == null,
            reason: _offline ? l.hotelProviderNeedsConnection : null,
            onPressed: setup == null ? null : () => _send(setup, resubmit, signedOut),
          ),
        );
        body = GzAsyncView<ApplicationSetup>(
          value: setupAsync,
          loading: const _FormSkeleton(),
          onRetry: () => ref.invalidate(applicationSetupProvider),
          data: (s) {
            final f = _form(s, resubmit);
            final missing = f.missing;
            return ApplicationFields(
              form: f,
              setup: s,
              tried: _tried,
              failed: _failed,
              onChanged: _edit,
              onRetry: () => _send(s, resubmit, signedOut),
              resubmitNote: resubmit ? s.application?.rejectionReason?.of(lang) : null,
              accountBad: signedOut && _account.bad(f.email),
              account: signedOut
                  ? ApplicationAccountSection(
                      email: f.email,
                      emailError: _tried && missing.email
                          ? l.hotelProviderFormEmailError
                          : (_tried && _account.emailTaken(f.email) ? l.hotelProviderAccountEmailUsed : null),
                      account: _account,
                      tried: _tried,
                      disabled: busy,
                      onEmail: (v) => _edit(f.copyWith(email: v)),
                      onAccount: _editAccount,
                    )
                  : null,
            );
          },
        );
    }
    return GzScreen(top: top, bottom: bottom, child: body);
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 56),
        SizedBox(height: GzSpace.s3),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 56),
        SizedBox(height: GzSpace.s5),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96),
        SizedBox(height: GzSpace.s5),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 56),
      ],
    ),
  );
}
