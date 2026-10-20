/// What the transport needs to know about the running app. Implemented by the apps (device id from secure storage, language from the locale
/// provider, partner context from the Partner session); [StaticClientEnvironment] serves tests.
abstract interface class GzClientEnvironment {
  /// `ar` or `en`: sent as `Accept-Language` (advisory: search language bias; push and PDFs use the saved locale).
  String get languageCode;

  /// The install id (`X-Device-Id`): guest rate limiting and session binding.
  String get deviceId;

  /// `ios`, `android` or `web` (`X-Platform`): orders payment methods and wallet availability.
  String get platform;

  /// `X-App-Version`; below the minimum the API answers 426 APP_UPDATE_REQUIRED.
  String get appVersion;

  /// The active Partner context (`X-Venue-Id` for a hotel or hall, `X-Provider-Id` for a service provider); null in the Client app.
  PartnerRequestContext? get partnerContext;
}

/// Exactly one of the two ids is normally set.
final class PartnerRequestContext {
  const PartnerRequestContext({this.venueId, this.providerId});

  final String? venueId;
  final String? providerId;
}

final class StaticClientEnvironment implements GzClientEnvironment {
  StaticClientEnvironment({
    this.languageCode = 'en',
    this.deviceId = 'device-test',
    this.platform = 'ios',
    this.appVersion = '1.0.0',
    this.partnerContext,
  });

  @override
  String languageCode;
  @override
  String deviceId;
  @override
  String platform;
  @override
  String appVersion;
  @override
  PartnerRequestContext? partnerContext;
}
