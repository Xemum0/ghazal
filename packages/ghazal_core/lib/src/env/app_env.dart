import 'package:equatable/equatable.dart';

enum GzEnvironment {
  dev,
  staging,
  prod;

  static GzEnvironment parse(String? raw) => switch (raw?.toLowerCase()) {
        'prod' || 'production' => GzEnvironment.prod,
        'staging' || 'stg' => GzEnvironment.staging,
        _ => GzEnvironment.dev,
      };
}

/// Public build-time configuration (ADR 0022 J). Only `--dart-define` / `--dart-define-from-file` values, never a
/// secret. Switching the mock for the real backend changes `API_BASE_URL` and `USE_MOCK=false` and nothing else.
///
/// Defines: `API_BASE_URL` (or `GZ_API_BASE_URL`), `USE_MOCK` (default true), `ENV` (dev|staging|prod, default dev),
/// `GZ_LOCALE` (ar|en, honoured outside prod only), `MOCK_LATENCY_MS` (default 0, so tests and shots do not wait).
class AppEnv extends Equatable {
  const AppEnv({
    this.apiBaseUrl = 'http://localhost:4710',
    this.useMock = true,
    this.environment = GzEnvironment.dev,
    this.localeOverride,
    this.mockLatencyMs = 0,
  });

  /// Reads the compile-time defines of the running build.
  factory AppEnv.fromEnvironment() {
    const api = String.fromEnvironment('API_BASE_URL');
    const gzApi = String.fromEnvironment('GZ_API_BASE_URL');
    const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
    const env = String.fromEnvironment('ENV');
    const locale = String.fromEnvironment('GZ_LOCALE');
    const latency = int.fromEnvironment('MOCK_LATENCY_MS');
    return AppEnv.fromValues(apiBaseUrl: api.isNotEmpty ? api : gzApi, useMock: useMock, env: env, locale: locale, mockLatencyMs: latency);
  }

  /// The same parsing from plain values (used by tests and by `fromEnvironment`).
  factory AppEnv.fromValues({String? apiBaseUrl, bool useMock = true, String? env, String? locale, int mockLatencyMs = 0}) {
    final e = GzEnvironment.parse(env);
    final l = (locale == 'ar' || locale == 'en') && e != GzEnvironment.prod ? locale : null;
    return AppEnv(
      apiBaseUrl: (apiBaseUrl == null || apiBaseUrl.isEmpty) ? const AppEnv().apiBaseUrl : apiBaseUrl,
      useMock: useMock,
      environment: e,
      localeOverride: l,
      mockLatencyMs: mockLatencyMs < 0 ? 0 : mockLatencyMs,
    );
  }

  final String apiBaseUrl;
  final bool useMock;
  final GzEnvironment environment;

  /// `ar` or `en`, set only outside prod.
  final String? localeOverride;
  final int mockLatencyMs;

  bool get isProd => environment == GzEnvironment.prod;

  @override
  List<Object?> get props => [apiBaseUrl, useMock, environment, localeOverride, mockLatencyMs];
}
