import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
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

/// What the auth screens share that the session and the gate do not carry: the number being verified, where the code is going, the
/// password a new account is being created with, the code of a reset, and the gate request the sheet was opened for.
///
/// The sheet leaves the stack (and so dismisses the gate) as soon as the code step opens; [pending] keeps what the guest was doing so the
/// sign-in can still resume it.
class AuthFlowState {
  const AuthFlowState({
    this.phone = '',
    this.purpose = AuthPurpose.login,
    this.challenge,
    this.resetCode = '',
    this.password = '',
    this.pending,
    this.bioOffered = false,
    this.bioEnabled = false,
  });

  /// National digits of the number the person typed.
  final String phone;
  final AuthPurpose purpose;
  final OtpChallenge? challenge;
  final String resetCode;
  final String password;
  final GateRequest? pending;
  final bool bioOffered;
  final bool bioEnabled;

  AuthFlowState copyWith({
    String? phone,
    AuthPurpose? purpose,
    OtpChallenge? challenge,
    String? resetCode,
    String? password,
    GateRequest? pending,
    bool? bioOffered,
    bool? bioEnabled,
    bool clearChallenge = false,
    bool clearPending = false,
  }) =>
      AuthFlowState(
        phone: phone ?? this.phone,
        purpose: purpose ?? this.purpose,
        challenge: clearChallenge ? null : (challenge ?? this.challenge),
        resetCode: resetCode ?? this.resetCode,
        password: password ?? this.password,
        pending: clearPending ? null : (pending ?? this.pending),
        bioOffered: bioOffered ?? this.bioOffered,
        bioEnabled: bioEnabled ?? this.bioEnabled,
      );
}

final NotifierProvider<AuthFlowNotifier, AuthFlowState> authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlowState>(AuthFlowNotifier.new);

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  void update(AuthFlowState Function(AuthFlowState s) change) => state = change(state);

  /// A fresh run (the sheet opened for a gate request, or a plain sign-in): keeps what the biometric offer remembers.
  void begin({GateRequest? pending}) =>
      state = AuthFlowState(pending: pending ?? state.pending, bioOffered: state.bioOffered, bioEnabled: state.bioEnabled);

  void reset() => state = AuthFlowState(bioOffered: state.bioOffered, bioEnabled: state.bioEnabled);
}
