import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ghazal_api/ghazal_api.dart';

const String _kAccess = 'gz.access_token';
const String _kRefresh = 'gz.refresh_token';
const String _kDevice = 'gz.device_id';

/// Tokens in the platform keychain / keystore (ADR 0028 item 4). Used when `USE_MOCK=false`; the mock and the tests use [MemoryTokenStore].
final class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final access = await _storage.read(key: _kAccess);
    final refresh = await _storage.read(key: _kRefresh);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _kAccess, value: tokens.accessToken);
    await _storage.write(key: _kRefresh, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  /// The install id (`X-Device-Id`): created once and kept in secure storage.
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _kDevice);
    if (existing != null && existing.isNotEmpty) return existing;
    final fresh = newDeviceId();
    await _storage.write(key: _kDevice, value: fresh);
    return fresh;
  }
}

/// A random install id (32 hex characters).
String newDeviceId() {
  final random = Random.secure();
  return List<String>.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
