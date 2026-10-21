// CL-ONBD-03 Who is planning? (CA-ONB-07, CA-ONB-09). Port of CL-ONBD-03.tsx.
// A two-word question with its drawing, four role chips (a glyph and one word each, none preselected), a name and an optional partner name
// (no first/last split, ADR 0012) and a live monogram. Every answer is optional: Skip and Continue both go to the date, only Continue
// writes the answers.
import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show WeddingRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/onboarding_profile.dart';
import 'widgets/obd_chip.dart';
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
  late WeddingRole? _role;
  late String _name;
  late String _partner;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(weddingDraftProvider);
    _name = saved.brideName ?? '';
    _role = (saved.brideName ?? '').isEmpty ? null : saved.role;
    _partner = saved.partnerName ?? '';
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
    final partnerLabel = switch (_role) {
      WeddingRole.bride => l10n.clientOnboardingAboutPartnerGroom,
      WeddingRole.groom => l10n.clientOnboardingAboutPartnerBride,
      WeddingRole.family || WeddingRole.planner => l10n.clientOnboardingAboutPartnerCouple,
      _ => l10n.clientOnboardingAboutPartnerDefault,
    };
    Widget chip(WeddingRole r) => Expanded(
          child: ObdChip(label: _roleLabel(l10n, r), iconStart: _roleIcon[r], selected: _role == r, onPressed: () => setState(() => _role = r)),
        );
    return GzScreen(
      top: ObdStepBar(step: 1, total: 4, onSkip: _next),
      bottom: GzActionBar(action: GzActionBarAction(label: l10n.commonActionContinue, onPressed: _confirm)),
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
                  Row(children: [chip(_roles[0]), const SizedBox(width: GzSpace.s2), chip(_roles[1])]),
                  const SizedBox(height: GzSpace.s2),
                  Row(children: [chip(_roles[2]), const SizedBox(width: GzSpace.s2), chip(_roles[3])]),
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
                    onValueChange: (v) => setState(() => _name = v),
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s4),
            GzTextField(label: partnerLabel, value: _partner, onValueChange: (v) => setState(() => _partner = v), textInputAction: TextInputAction.done),
          ],
        ),
      ),
    );
  }
}
