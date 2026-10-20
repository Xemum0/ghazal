/// Where the apps talk to. Switching to the real backend changes only these two values (plan section 1, criterion 6).
final class GzApiConfig {
  const GzApiConfig({required this.baseUrl, required this.useMock});

  /// Read from `--dart-define=API_BASE_URL=...` and `--dart-define=USE_MOCK=false`; the default is the in-process mock.
  factory GzApiConfig.fromEnvironment() => const GzApiConfig(
        baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: 'http://mock.ghazal.local/v1'),
        useMock: bool.fromEnvironment('USE_MOCK', defaultValue: true),
      );

  final String baseUrl;
  final bool useMock;
}
