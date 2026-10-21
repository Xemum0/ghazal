import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_core/ghazal_core.dart';

import '../session/session_notifier.dart';
import '../session/session_types.dart';
import 'secure_token_store.dart';

/// Where tokens live: memory in mock mode and tests (the default), the keychain in a real build (the bootstrap overrides it).
final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>((ref) => MemoryTokenStore());

/// The install id (`X-Device-Id`). The bootstrap overrides it with the one kept in secure storage.
final Provider<String> deviceIdProvider = Provider<String>((ref) => newDeviceId());

const String _appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

/// A [GzClientEnvironment] that reads the language from the locale provider and the partner context from the session every time a request is
/// made, so a language switch or a context switch reaches the next call with no rebuild of the client.
final class DynamicClientEnvironment implements GzClientEnvironment {
  DynamicClientEnvironment({
    required this.language,
    required this.device,
    required this.partner,
    this.platformOverride,
    this.appVersion = _appVersion,
  });

  final String Function() language;
  final String Function() device;
  final PartnerRequestContext? Function() partner;
  final String? platformOverride;

  @override
  final String appVersion;

  @override
  String get languageCode => language();

  @override
  String get deviceId => device();

  @override
  String get platform =>
      platformOverride ??
      (kIsWeb
          ? 'web'
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => 'android',
              TargetPlatform.iOS => 'ios',
              _ => 'web',
            });

  @override
  PartnerRequestContext? get partnerContext => partner();
}

/// The environment of the running app (locale and partner context from providers).
final Provider<GzClientEnvironment> clientEnvironmentProvider = Provider<GzClientEnvironment>((ref) {
  return DynamicClientEnvironment(
    language: () => ref.read(localeProvider).languageCode,
    device: () => ref.read(deviceIdProvider),
    partner: () {
      final session = ref.read(sessionProvider);
      if (session is! PartnerSession) return null;
      if (session.venueId == null && session.providerId == null) return null;
      return PartnerRequestContext(venueId: session.venueId, providerId: session.providerId);
    },
  );
});
