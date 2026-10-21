// CL-AUTH-03 Create account: name and terms (CA-AUTH-11, CA-ONB-08). Port of CL-AUTH-03.tsx.
// Last step for a brand-new account (a verified number, or an Apple or Google identity): confirm the name and agree to the Terms of Use and
// Privacy Policy. A two-word title with the live monogram at its end edge, two fields, what the device carries over as a row of facts, and
// a two-word consent with the info glyph beside it (Terms and Privacy open as two rows). Continue creates the account, attaches what the
// guest chose on the device (Brief, hearts, Compare set, ADR 0007 D10) and returns to the interrupted intent.
import 'dart:async';

import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, DateStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show RegisterInput, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/auth_actions.dart';
import '../application/auth_flow.dart';
import '../application/auth_resume.dart';
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
  bool _accepted = false;
  bool _nameError = false;
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
    final draftName = ref.read(weddingDraftProvider).brideName;
    final fromSession = session is ClientSession && session.user.name.isNotEmpty && !session.user.name.startsWith('Guest') ? session.user.name : '';
    if (_live) {
      // Live: what onboarding left, or what Apple or Google gave.
      _name = draftName ?? fromSession;
    } else {
      // Opened on its own (a harness): the story's name so the monogram preview reads.
      _name = Localizations.localeOf(context).languageCode == 'ar' ? 'ريم الدوسري' : 'Reem Al-Dosari';
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final missingName = _name.trim().isEmpty;
    setState(() {
      _nameError = missingName;
      _termsError = !_accepted;
    });
    if (missingName || !_accepted || _phase == _Phase.creating) return;
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
      await ref.confirmName(name: _name, email: _email);
      if (!mounted) return;
      unawaited(ref.read(weddingProfileProvider.future).then((_) {}, onError: (Object _) {}));
      setState(() => _phase = _Phase.done);
      _hold = Timer(_successHold, () {
        if (mounted) ref.finishSignIn();
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
    final f = ref.watch(gzFormatProvider);
    final brief = ref.watch(searchBriefProvider);
    final hearts = ref.watch(favouritesProvider).value?.venue.length ?? 0;
    final busy = _phase == _Phase.creating;
    final initial = authMonogramFor(_name);
    // What the device carries over: the Brief's date and guests and the hearts (the Compare set travels too, silently). Opened on its own
    // the screen shows the shared story.
    final date = _live ? brief.date : AuthStory.date;
    final guests = _live ? brief.guests : AuthStory.guests;
    final carried = date != null || guests != null || (_live && hearts > 0);

    return GzScreen(
      top: GzTopBar(onBack: () => context.gzNav.pop()),
      bottom: _phase == _Phase.done ? null : GzActionBar(action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: _submit, loading: busy)),
      child: _phase == _Phase.done
          ? Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: GzSuccessState(illustration: GzIllustrationName.seal, title: l10n.clientAuthSharedAccountReady, size: GzIllustrationSize.hero),
            )
          : AuthBody(
              children: [
                AuthHead(
                  title: l10n.clientAuthNameTitle,
                  art: GzIllustrationName.invitation,
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
                    if (carried) ...[
                      const SizedBox(height: GzSpace.s5),
                      Semantics(
                        container: true,
                        label: l10n.clientAuthNameKept,
                        child: Row(
                          children: [
                            GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSuccess),
                            const SizedBox(width: GzSpace.s3),
                            Expanded(
                              child: Wrap(
                                spacing: GzSpace.s3,
                                runSpacing: GzSpace.s2,
                                children: [
                                  if (date != null) GzFactChip(icon: GzIcons.calendar, value: f.date(date.toString(), DateStyle.dayMonth), label: l10n.clientAuthSharedDate),
                                  if (guests != null) GzFactChip(icon: GzIcons.usersThree, value: f.integer(guests), label: l10n.clientAuthSharedGuests),
                                  if (_live && hearts > 0) GzFactChip(icon: GzIcons.heart, value: f.integer(hearts), label: l10n.clientAuthReasonSave),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
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
                    const SizedBox(width: GzSpace.s1),
                    AuthLegalInfo(title: l10n.clientAuthNameLegalTitle),
                  ],
                ),
              ],
            ),
    );
  }
}
