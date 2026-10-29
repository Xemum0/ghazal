import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show OtpChallenge;

/// Config values the screens read (ADR 0028 item 2, ADR 0012 D4): never typed into a message.
abstract final class AuthConfig {
  static const int otpLength = 6;
  static const int phoneDigits = 8;
  static const int resendSeconds = 60;
  static const int maxAttempts = 5;
  static const int passwordMin = 8;
  static const int lockMinutes = 15;

  /// The demo persona (Reem, `+96550000012`): what a screen opened on its own shows.
  static const String storyNational = '50000012';

  /// Ghazal Support (fixture phone 0001), display only.
  static const String supportPhone = '+96550000001';

  /// What the bundled mock accepts: any six digits, with these three exceptions (docs/architecture/mock-api.md).
  static const String mockWrong = '000000';
}

/// Why the code is being asked: sign-in, the code of a password reset (only collected here, the reset call verifies it) or a new password
/// account (the number is verified at the end of the registration).
enum AuthPurpose { login, passwordReset, passwordCreate }

/// What the auth screens share that the session does not carry: the number being verified, where the code is going, the password a new
/// account is being created with and the code of a reset. There is no guest mode (ADR 0038), so nothing waits on the other side of the
/// sign-in: a returning account lands on Home, a new one continues to About you and the optional steps.
class AuthFlowState {
  const AuthFlowState({
    this.phone = '',
    this.purpose = AuthPurpose.login,
    this.challenge,
    this.resetCode = '',
    this.password = '',
    this.bioOffered = false,
    this.bioEnabled = false,
  });

  /// National digits of the number the person typed.
  final String phone;
  final AuthPurpose purpose;
  final OtpChallenge? challenge;
  final String resetCode;
  final String password;
  final bool bioOffered;
  final bool bioEnabled;

  AuthFlowState copyWith({
    String? phone,
    AuthPurpose? purpose,
    OtpChallenge? challenge,
    String? resetCode,
    String? password,
    bool? bioOffered,
    bool? bioEnabled,
    bool clearChallenge = false,
  }) =>
      AuthFlowState(
        phone: phone ?? this.phone,
        purpose: purpose ?? this.purpose,
        challenge: clearChallenge ? null : (challenge ?? this.challenge),
        resetCode: resetCode ?? this.resetCode,
        password: password ?? this.password,
        bioOffered: bioOffered ?? this.bioOffered,
        bioEnabled: bioEnabled ?? this.bioEnabled,
      );
}

final NotifierProvider<AuthFlowNotifier, AuthFlowState> authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlowState>(AuthFlowNotifier.new);

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  void update(AuthFlowState Function(AuthFlowState s) change) => state = change(state);

  void reset() => state = AuthFlowState(bioOffered: state.bioOffered, bioEnabled: state.bioEnabled);
}
