// CL-AUTH-03 About you: name, sex, terms (CA-AUTH-11, CA-AUTH-13, CA-AUTH-14, CA-ONB-08). Port of CL-AUTH-03.tsx.
// Last step for a brand-new account (a verified number, or an Apple or Google identity) and the step that opens the app: the name is
// required and so is the sex (female or male; stored on the account, not shown to venues, not used to filter: OQ-R2-02), then the Terms of
// Use and Privacy Policy. A two-word title with the live monogram at its end edge, a name, the sex choice, an optional email and a two-word
// consent with the info glyph beside it. Continue calls `completeProfile` and continues to the optional onboarding steps (CL-ONBD-03).
import 'dart:async';

import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show RegisterInput, Sex, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import 'widgets/auth_bits.dart';
import 'widgets/legal.dart';

const Duration _successHold = Duration(milliseconds: 1200);

enum _Phase { form, creating, done }

class ClAuth03Screen extends ConsumerStatefulWidget {
  const ClAuth03Screen({super.key});

  @override
  ConsumerState<ClAuth03Screen> createState() => _ClAuth03State();
}

class _ClAuth03State extends ConsumerState<ClAuth03Screen> {
  String _name = '';
  String _email = '';
  Sex? _sex;
  bool _accepted = false;
  bool _nameError = false;
  bool _sexError = false;
  bool _termsError = false;
  _Phase _phase = _Phase.form;
  Timer? _hold;
  bool _live = false;

  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    final flow = ref.read(authFlowProvider);
    final provider = context.gzNav.params['provider'];
    final session = ref.read(sessionProvider);
    _live = flow.challenge != null || provider != null || session is ClientSession || flow.password.isNotEmpty;
    if (_live) {
      // Live: empty, or what Apple or Google gave (the mock's placeholder name of a number-only account is not a name).
      final given = session is ClientSession && provider != null ? session.user.name : '';
      _name = given.startsWith('Guest') ? '' : given;
    } else {
      // Opened on its own (a harness): the story's name and sex so the monogram preview and the tiles read.
      _name = Localizations.localeOf(context).languageCode == 'ar' ? 'ريم الدوسري' : 'Reem Al-Dosari';
      _sex = Sex.female;
      _accepted = true;
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final missingName = _name.trim().isEmpty;
    final sex = _sex;
    setState(() {
      _nameError = missingName;
      _sexError = sex == null;
      _termsError = !_accepted;
    });
    if (missingName || sex == null || !_accepted || _phase == _Phase.creating) return;
    setState(() => _phase = _Phase.creating);
    final nav = context.gzNav;
    final flow = ref.read(authFlowProvider);
    try {
      if (flow.password.isNotEmpty && ref.read(sessionProvider) is! ClientSession) {
        // A password account: the number is verified after the registration (the API creates the account first, then the code).
        final locale = Localizations.localeOf(context).languageCode;
        await ref.read(authRepositoryProvider).registerAccount(
              body: RegisterInput(
                phone: flow.phone,
                name: _name.trim(),
                password: flow.password,
                sex: sex,
                acceptedTerms: true,
                locale: locale == 'ar' ? WireLang.ar : WireLang.en,
                deviceId: ref.read(deviceIdProvider),
              ),
            );
        await ref.sendCode(flow.phone, AuthPurpose.passwordCreate);
        if (!mounted) return;
        setState(() => _phase = _Phase.form);
        nav.replace('CL-AUTH-02');
        return;
      }
      await ref.completeProfile(name: _name, sex: sex, email: _email);
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
      _hold = Timer(_successHold, () {
        if (mounted) ref.finishSignIn(fresh: true);
      });
    } on ApiProblem catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Phase.form);
      nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, e), tone: GzToastTone.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final busy = _phase == _Phase.creating;
    final initial = authMonogramFor(_name);
    return GzScreen(
      top: GzTopBar(onBack: () => context.gzNav.pop()),
      bottom: _phase == _Phase.done ? null : GzActionBar(action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: _submit, loading: busy)),
      child: _phase == _Phase.done
          ? Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: GzSuccessState(illustration: GzIllustrationName.seal, title: l10n.clientAuthSharedAccountReady, size: GzIllustrationSize.hero),
            )
          : AuthBody(
              spacing: GzSpace.s5, // web `.gza03 { gap: space-5 }`: the form is the page
              children: [
                AuthHead(
                  title: l10n.clientAuthNameTitle,
                  trailing: Semantics(
                    label: l10n.clientAuthNameMonogram,
                    image: true,
                    excludeSemantics: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                      child: SizedBox(
                        width: GzSize.thumbLg,
                        height: GzSize.thumbLg,
                        child: Center(child: initial.isEmpty ? GzIcon(GzIcons.user, size: GzIconSize.md, color: c.iconSecondary) : GzText(initial, role: GzTextRole.d2, color: c.iconSecondary)),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzTextField(
                      label: l10n.clientAuthNameLabel,
                      value: _name,
                      onValueChange: (v) => setState(() {
                        _name = v;
                        if (v.trim().isNotEmpty) _nameError = false;
                      }),
                      placeholder: l10n.clientAuthNamePlaceholder,
                      autofillHints: const [AutofillHints.name],
                      error: _nameError ? l10n.commonLabelRequired : null,
                      disabled: busy,
                    ),
                    const SizedBox(height: GzSpace.s5),
                    GzSexChoice(
                      value: _sex,
                      label: l10n.clientAuthNameSexLabel,
                      femaleLabel: l10n.clientAuthNameSexFemale,
                      maleLabel: l10n.clientAuthNameSexMale,
                      onChanged: (v) => setState(() {
                        _sex = v;
                        _sexError = false;
                      }),
                      error: _sexError ? l10n.commonLabelRequired : null,
                      disabled: busy,
                    ),
                    const SizedBox(height: GzSpace.s5),
                    GzTextField(
                      label: l10n.clientAuthNameEmailLabel,
                      optional: true,
                      dir: GzFieldDir.ltr,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: false,
                      value: _email,
                      onValueChange: (v) => setState(() => _email = v),
                      disabled: busy,
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The checkbox hugs its label so the info glyph sits right beside it (web `.gza03-agree`).
                    Flexible(
                      child: IntrinsicWidth(
                        child: GzCheckbox(
                          label: l10n.clientAuthNameAccept,
                          checked: _accepted,
                          onChanged: (v) => setState(() {
                            _accepted = v;
                            if (v) _termsError = false;
                          }),
                          error: _termsError ? l10n.commonLabelRequired : null,
                          disabled: busy,
                        ),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s1),
                    AuthLegalInfo(title: l10n.clientAuthNameLegalTitle),
                  ],
                ),
              ],
            ),
    );
  }
}
