import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sheet_queue.dart';

/// The Face ID offer that follows a sign-in, as a request to the sheet queue. The auth feature owns the sheet; the app root installs it
/// here (`ClientApp`), so the onboarding feature can ask for it at the end of the optional steps without importing the auth feature. Null
/// without an app root, with the offer off (tests) or without a device that has biometrics enrolled.
final Provider<QueuedSheet?> biometricOfferProvider = Provider<QueuedSheet?>((ref) => null);

extension BiometricOfferAsk on WidgetRef {
  /// Asks the sheet queue for the offer: it opens once per run of the app, a beat after a calm moment begins (never over a sheet or the
  /// checkout).
  void askBiometricOffer() {
    final offer = read(biometricOfferProvider);
    if (offer != null) read(sheetQueueProvider.notifier).enqueue(offer);
  }
}
