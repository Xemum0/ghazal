// "Your account" of HL-PROV-01 signed out (web `HL-PROV-01.tsx`, round 2b, PA-ACC-07): the applicant's email (it is also the contact email, so the
// business section does not ask for it again), a password with its strength thread and rules, and the password again. Account errors sit under
// their field: email already registered, password too weak, the two passwords differ.
import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/widgets/password_widgets.dart';
import '../../../../l10n/l10n.dart';

/// What the person typed in the account section (never stored with the application) and what the server said about it.
@immutable
final class ApplicantAccount {
  const ApplicantAccount({this.password = '', this.repeat = '', this.takenEmail});

  final String password;
  final String repeat;

  /// The email the server answered `EMAIL_ALREADY_REGISTERED` for (lower case); the error shows while the field still holds it.
  final String? takenEmail;

  ApplicantAccount copyWith({String? password, String? repeat, String? takenEmail, bool clearTaken = false}) =>
      ApplicantAccount(password: password ?? this.password, repeat: repeat ?? this.repeat, takenEmail: clearTaken ? null : (takenEmail ?? this.takenEmail));

  PasswordCheck get check => password.isEmpty ? PasswordCheck.empty : checkPassword(password, '');
  bool get weak => !check.ok;
  bool get differ => repeat != password;
  bool emailTaken(String email) => takenEmail != null && takenEmail == email.trim().toLowerCase();

  /// The account part stops a submit: weak or mistyped password, or an email the server already knows.
  bool bad(String email) => weak || differ || emailTaken(email);
}

class ApplicationAccountSection extends StatelessWidget {
  const ApplicationAccountSection({
    required this.email,
    required this.emailError,
    required this.account,
    required this.tried,
    required this.onEmail,
    required this.onAccount,
    this.disabled = false,
    super.key,
  });

  final String email;

  /// The message under the email field (invalid after a try, or already registered), null when it is fine.
  final String? emailError;
  final ApplicantAccount account;
  final bool tried;
  final ValueChanged<String> onEmail;
  final ValueChanged<ApplicantAccount> onAccount;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    const gap = SizedBox(height: GzSpace.s5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzText(l.hotelProviderFormAccountTitle, role: GzTextRole.title, color: c.textStrong, header: true),
        gap,
        GzTextField(
          label: l.hotelProviderFormEmail,
          dir: GzFieldDir.ltr,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const ['username'],
          autocorrect: false,
          enableSuggestions: false,
          disabled: disabled,
          startAdornment: GzIcon(GzIcons.mail, size: GzIconSize.sm, color: c.iconSecondary),
          value: email,
          onValueChange: onEmail,
          error: emailError,
        ),
        gap,
        PartnerPasswordField(
          label: l.hotelAccessSetupPasswordLabel,
          showLabel: true,
          newPassword: true,
          disabled: disabled,
          value: account.password,
          error: tried && account.weak ? l.hotelProviderAccountPasswordWeak : null,
          onChanged: (v) => onAccount(account.copyWith(password: v)),
        ),
        gap,
        PasswordRules(check: account.check),
        gap,
        PartnerPasswordField(
          label: l.hotelProviderAccountRepeat,
          showLabel: true,
          newPassword: true,
          disabled: disabled,
          value: account.repeat,
          error: account.differ && (account.repeat.isNotEmpty || tried) ? l.hotelAccessSetupMismatch : null,
          onChanged: (v) => onAccount(account.copyWith(repeat: v)),
        ),
      ],
    );
  }
}
