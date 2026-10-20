/// The pair of tokens of one session (ADR 0028): a 10-minute access JWT and a rotating, device-bound refresh token.
final class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  bool operator ==(Object other) => other is AuthTokens && other.accessToken == accessToken && other.refreshToken == refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);
}

/// Where the session lives. The apps back it with `flutter_secure_storage` (refresh token and device id only, ADR 0028 item 4);
/// [MemoryTokenStore] serves tests and the mock.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

final class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._tokens]);

  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
