import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The platform biometric prompt (Face ID, Touch ID, fingerprint). The `local_auth` plugin is not in the build yet (requests.md), so the
/// default accepts after a short pause like the prototype's scan; the integrator replaces it with the plugin call. Biometrics unlock a
/// stored session, they never replace the first sign-in.
abstract class BiometricAuthenticator {
  const BiometricAuthenticator();

  /// Which method the wording follows: `face`, `touch` or `fingerprint`; null when the device has none enrolled.
  String? get method;

  /// Opens the system prompt: true on a match.
  Future<bool> authenticate();
}

class PlaceholderBiometric extends BiometricAuthenticator {
  const PlaceholderBiometric();

  @override
  String? get method => 'face';

  @override
  Future<bool> authenticate() => Future<bool>.delayed(const Duration(milliseconds: 900), () => true);
}

final Provider<BiometricAuthenticator> biometricProvider = Provider<BiometricAuthenticator>((ref) => const PlaceholderBiometric());
