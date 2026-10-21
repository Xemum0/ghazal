// Strength and the rules without a sentence (HL-ACCS-03): a three-segment gold thread that fills as the password improves, one word for the
// level (never colour alone) and two rule chips, `10+` (length) and `Aa1` (a letter and a number), each with a check or a dash.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/access_flow.dart';

class PasswordCheck {
  const PasswordCheck({required this.length, required this.mix, required this.score});

  static const PasswordCheck empty = PasswordCheck(length: false, mix: false, score: 0);

  final bool length;
  final bool mix;
  final int score;

  bool get ok => length && mix;
}

PasswordCheck checkPassword(String value, String local) {
  final length = value.length >= kPasswordMin;
  final mix = RegExp(r'[A-Za-z؀-ۿ]').hasMatch(value) && RegExp(r'\d').hasMatch(value);
  final notEmail = value.isNotEmpty && (local.isEmpty || !value.toLowerCase().contains(local.toLowerCase()));
  final score = value.isEmpty ? 0 : [length, mix, notEmail].where((x) => x).length;
  return PasswordCheck(length: length, mix: mix, score: score);
}

class PasswordRules extends StatelessWidget {
  const PasswordRules({required this.check, super.key});

  final PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final word = check.score <= 1
        ? l.hotelAccessSetupStrengthWeak
        : (check.score == 2 ? l.hotelAccessSetupStrengthFair : l.hotelAccessSetupStrengthStrong);
    final rules = <({bool met, String chip, String name})>[
      (met: check.length, chip: '${f.integer(kPasswordMin)}+', name: l.hotelAccessSetupRuleLength(kPasswordMin)),
      (met: check.mix, chip: 'Aa1', name: l.hotelAccessSetupRuleMix),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.iconMd),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 1; i <= 3; i++) ...[
                        if (i > 1) const SizedBox(width: GzSpace.s1),
                        Expanded(
                          child: Container(
                            height: GzStroke.threadMax,
                            decoration: BoxDecoration(color: check.score >= i ? c.markKhayt : c.markTrack, borderRadius: GzRadius.pillAll),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin),
                child: Semantics(
                  liveRegion: true,
                  label: l.hotelAccessSetupStrength(word),
                  child: GzText(
                    check.score == 0 ? '' : word,
                    role: GzTextRole.caption,
                    color: c.textPrimary,
                    textAlign: TextAlign.end,
                    excludeSemantics: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s3),
        Row(
          children: [
            for (final r in rules) ...[
              Semantics(
                container: true,
                label: '${r.name}, ${r.met ? l.hotelAccessSetupRuleMet : l.hotelAccessSetupRuleOpen}',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzIcon(r.met ? GzIcons.checkCircle : GzIcons.minus, size: GzIconSize.xs, color: r.met ? c.iconSuccess : c.iconDisabled),
                      const SizedBox(width: GzSpace.s2),
                      GzLtr(
                        child: GzText(r.chip, role: GzTextRole.figBodyS, color: r.met ? c.textPrimary : c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (r != rules.last) const SizedBox(width: GzSpace.s5),
            ],
          ],
        ),
      ],
    );
  }
}
