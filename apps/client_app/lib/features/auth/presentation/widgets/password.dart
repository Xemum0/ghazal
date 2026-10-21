import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/auth_flow.dart';

/// The password input: the kit text field (LTR, 56) with a 44 reveal control at its end. Never shown in analytics or logs.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({required this.label, required this.value, required this.onChanged, this.error, this.disabled = false, this.creating = false, super.key});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool disabled;
  final bool creating;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    return GzTextField(
      label: widget.label,
      value: widget.value,
      onValueChange: widget.onChanged,
      error: widget.error,
      disabled: widget.disabled,
      dir: GzFieldDir.ltr,
      obscureText: !_shown,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [widget.creating ? AutofillHints.newPassword : AutofillHints.password],
      endAdornment: GzPressable(
        semanticLabel: _shown ? l10n.clientAuthPwdHide : l10n.clientAuthPwdShow,
        selected: _shown,
        onPressed: widget.disabled ? null : () => setState(() => _shown = !_shown),
        borderRadius: GzRadius.smAll,
        child: SizedBox(width: GzSize.touchMin, height: GzSize.touchMin, child: Center(child: GzIcon(_shown ? GzIcons.eyeOff : GzIcons.eye, size: GzIconSize.sm, color: widget.disabled ? c.iconDisabled : c.iconSecondary))),
      ),
    );
  }
}

/// The live strength and rules (create and reset), without a sentence: a three-segment gold thread that fills as the password improves
/// and two rule chips, `8+` (length) and `Aa1` (a letter and a number), each with a check or a dash.
class PasswordCheck {
  PasswordCheck(String value, String nationalPhone)
      : length = value.length >= AuthConfig.passwordMin,
        mix = RegExp('[A-Za-z؀-ۿ]').hasMatch(value) && RegExp(r'\d').hasMatch(value),
        notPhone = value.isNotEmpty && (nationalPhone.isEmpty || !value.contains(nationalPhone)),
        isEmpty = value.isEmpty;

  final bool length;
  final bool mix;
  final bool notPhone;
  final bool isEmpty;

  int get score => isEmpty ? 0 : <bool>[length, mix, notPhone].where((b) => b).length;
  bool get strong => length && mix && notPhone;

  /// True when the one rule that has a name of its own is the one being broken.
  bool get containsPhone => !isEmpty && !notPhone;
}

class AuthPasswordRules extends StatelessWidget {
  const AuthPasswordRules({required this.check, required this.format, super.key});

  final PasswordCheck check;
  final GzFormat format;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.l10n;
    final level = check.score <= 1 ? l10n.clientAuthPwdStrengthWeak : (check.score == 2 ? l10n.clientAuthPwdStrengthFair : l10n.clientAuthPwdStrengthStrong);
    final rules = <(bool, String, String)>[
      (check.length, '${format.integer(AuthConfig.passwordMin)}+', l10n.clientAuthPwdRuleLength(AuthConfig.passwordMin)),
      (check.mix, 'Aa1', l10n.clientAuthPwdRuleMix),
    ];
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.clientAuthPwdStrength(level),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: GzSpace.s1),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(borderRadius: GzRadius.pillAll, color: check.score >= i ? c.markKhayt : c.markTrack),
                      child: const SizedBox(height: GzStroke.threadMax),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          Row(
            children: [
              for (var i = 0; i < rules.length; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s5),
                Semantics(
                  label: '${rules[i].$3}, ${rules[i].$1 ? l10n.clientAuthPwdRuleMet : l10n.clientAuthPwdRuleOpen}',
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      GzIcon(rules[i].$1 ? GzIcons.checkCircle : GzIcons.minus, size: GzIconSize.xs, color: rules[i].$1 ? c.iconSuccess : c.iconDisabled),
                      const SizedBox(width: GzSpace.s2),
                      GzNum(rules[i].$2, role: GzTextRole.figBodyS, color: rules[i].$1 ? c.textPrimary : c.textSecondary),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
