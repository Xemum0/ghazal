// CL-ONBD-03 Who is planning? (CA-ONB-07, CA-ONB-09, CA-ONB-10). Port of CL-ONBD-03.tsx.
// First of the three optional steps after the account is created (ADR 0038): the name comes from the account, and the role is suggested
// from the sex given there (female: bride, male: groom; a chip the person can change, OQ-R2-06). A two-word question with its drawing, four
// role chips (a glyph and one word each), a name and an optional partner name (no first/last split, ADR 0012) and a live monogram. Every
// answer is optional: Skip and Continue both go to the date, only Continue writes the answers. There is no Back.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Sex, WeddingRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_profile.dart';
import 'widgets/step_bar.dart';
import 'widgets/step_head.dart';

const List<WeddingRole> _roles = <WeddingRole>[WeddingRole.bride, WeddingRole.groom, WeddingRole.family, WeddingRole.planner];

/// One glyph per role: the gown, the male sign, a group, a clipboard. Never a face or a figure.
const Map<WeddingRole, IconData> _roleIcon = <WeddingRole, IconData>{
  WeddingRole.bride: GzIcons.dress,
  WeddingRole.groom: GzIcons.groom,
  WeddingRole.family: GzIcons.guests,
  WeddingRole.planner: GzIcons.clipboard,
};

class ClOnbd03Screen extends ConsumerStatefulWidget {
  const ClOnbd03Screen({super.key});

  @override
  ConsumerState<ClOnbd03Screen> createState() => _ClOnbd03State();
}

class _ClOnbd03State extends ConsumerState<ClOnbd03Screen> {
  WeddingRole? _role;
  late String _name;
  late String _partner;
  bool _roleTouched = false;
  bool _nameTouched = false;

  @override
  void initState() {
    super.initState();
    // What the account knows: the name at once (the session), the sex a moment later (the profile read) for the role suggestion.
    final saved = ref.read(obdDraftProvider);
    final session = ref.read(sessionProvider);
    final accountName = session is ClientSession && !session.user.name.startsWith('Guest') ? session.user.name : '';
    _name = saved.brideName ?? accountName;
    _role = (saved.brideName ?? '').isEmpty ? null : saved.role;
    _partner = saved.partnerName ?? '';
  }

  /// The account arrived: fill what the person has not touched.
  void _seedFromAccount(({String name, Sex? sex})? account) {
    if (account == null) return;
    setState(() {
      if (!_nameTouched && _name.isEmpty && !account.name.startsWith('Guest')) _name = account.name;
      if (!_roleTouched && _role == null) _role = obdRoleForSex(account.sex);
    });
  }

  void _next() => context.gzNav.push('CL-ONBD-04');

  void _confirm() {
    ref.commitAbout(role: _role, name: _name, partnerName: _partner);
    _next();
  }

  String _roleLabel(AppL10n l10n, WeddingRole r) => switch (r) {
    WeddingRole.bride => l10n.clientOnboardingAboutRoleBride,
    WeddingRole.groom => l10n.clientOnboardingAboutRoleGroom,
    WeddingRole.family => l10n.clientOnboardingAboutRoleFamily,
    _ => l10n.clientOnboardingAboutRolePlanner,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    ref.listen(obdAccountProvider, (_, next) => _seedFromAccount(next.value));
    final partnerLabel = switch (_role) {
      WeddingRole.bride => l10n.clientOnboardingAboutPartnerGroom,
      WeddingRole.groom => l10n.clientOnboardingAboutPartnerBride,
      WeddingRole.family || WeddingRole.planner => l10n.clientOnboardingAboutPartnerCouple,
      _ => l10n.clientOnboardingAboutPartnerDefault,
    };
    Widget chip(WeddingRole r) => Expanded(
      child: GzChip(
        label: _roleLabel(l10n, r),
        expand: true,
        iconStart: _roleIcon[r],
        selected: _role == r,
        onPressed: () => setState(() {
          _role = r;
          _roleTouched = true;
        }),
      ),
    );
    return GzScreen(
      top: ObdStepBar(step: 1, total: 3, back: false, onSkip: _next),
      bottom: GzActionBar(
        action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: _confirm),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ObdStepHead(title: l10n.clientOnboardingAboutTitle, art: GzIllustrationName.invitation),
            const SizedBox(height: GzSpace.s6),
            // Two equal rows of two: a single choice reads as one block, not a ragged wrap.
            Semantics(
              container: true,
              label: l10n.clientOnboardingAboutRoleLabel,
              child: Column(
                children: [
                  Row(
                    children: [
                      chip(_roles[0]),
                      const SizedBox(width: GzSpace.s2),
                      chip(_roles[1]),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s2),
                  Row(
                    children: [
                      chip(_roles[2]),
                      const SizedBox(width: GzSpace.s2),
                      chip(_roles[3]),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GzAvatar(name: l10n.clientOnboardingAboutMonogram, initial: obdMonogramFor(_name), size: GzAvatarSize.md),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: GzTextField(
                    label: l10n.clientOnboardingAboutNameLabel,
                    value: _name,
                    onValueChange: (v) => setState(() {
                      _name = v;
                      _nameTouched = true;
                    }),
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s4),
            GzTextField(
              label: partnerLabel,
              value: _partner,
              onValueChange: (v) => setState(() => _partner = v),
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }
}
