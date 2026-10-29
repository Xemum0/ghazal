// What the password screens share (HL-ACCS-01, HL-ACCS-03, HL-PROV-01 signed out): the password input (LTR, a lock at the start, a 44 reveal
// control at the end) and the strength and rules without a sentence (a three-segment gold thread that fills as the password improves, one
// word for the level, never colour alone, and two rule chips, `10+` (length) and `Aa1` (a letter and a number), each with a check or a dash).
// Lives in lib/app because two features use it (no cross-feature imports).
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../l10n/l10n.dart';

/// The shortest password the screens ask for (the same figure as the web `PASSWORD_MIN`; the server's own floor is 8).
const int kPasswordMin = 10;

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

/// Password input: LTR, a lock at the start, a 44 reveal control at the end. The label is the accessible name unless [showLabel].
class PartnerPasswordField extends StatefulWidget {
  const PartnerPasswordField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.showLabel = false,
    this.newPassword = false,
    this.error,
    this.disabled = false,
    this.onSubmitted,
    this.textInputAction,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool showLabel;
  final bool newPassword;
  final String? error;
  final bool disabled;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<PartnerPasswordField> createState() => _PartnerPasswordFieldState();
}

class _PartnerPasswordFieldState extends State<PartnerPasswordField> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    return Semantics(
      label: widget.showLabel ? null : widget.label,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: widget.showLabel ? 0 : GzSpace.s2),
        child: GzTextField(
          label: widget.showLabel ? widget.label : null,
          value: widget.value,
          onValueChange: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: widget.textInputAction,
          dir: GzFieldDir.ltr,
          obscureText: !_shown,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: [widget.newPassword ? 'newPassword' : 'password'],
          disabled: widget.disabled,
          error: widget.error,
          startAdornment: GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary),
          // the reveal control: a 44 target with the secondary ink (the web `hxa-eye`), not the plain icon button's primary ink
          endAdornment: GzPressable(
            semanticLabel: _shown ? l.hotelAccessPasswordHide : l.hotelAccessPasswordShow,
            onPressed: widget.disabled ? null : () => setState(() => _shown = !_shown),
            borderRadius: GzRadius.smAll,
            pressedColor: c.surfaceQuiet,
            child: Center(child: GzIcon(_shown ? GzIcons.eyeOff : GzIcons.eye, size: GzIconSize.sm, color: widget.disabled ? c.iconDisabled : c.iconSecondary)),
          ),
        ),
      ),
    );
  }
}
