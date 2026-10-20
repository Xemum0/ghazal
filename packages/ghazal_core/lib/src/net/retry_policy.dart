import 'dart:async';
import 'dart:math' as math;

/// Global retry policy (ADR 0022 C): only idempotent GETs, only on network errors and 5xx, at most 3 retries with
/// exponential backoff and jitter. POST, PATCH, DELETE, OTP, booking creation and payments never auto-retry (a
/// user-initiated retry reuses the same Idempotency-Key).
class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 4),
  });

  /// A policy that never retries (tests, non-idempotent calls).
  static const RetryPolicy none = RetryPolicy(maxRetries: 0);

  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;

  static const Set<String> idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  /// Whether a failed attempt may be repeated. [attempt] is the number of retries already made (0 for the first
  /// failure). [status] is null for a network error (no response).
  bool shouldRetry({required String method, int? status, required int attempt}) {
    if (!idempotentMethods.contains(method.toUpperCase())) return false;
    if (attempt >= maxRetries) return false;
    return status == null || status == 0 || status >= 500;
  }

  /// Delay before retry number [attempt] + 1: 300 ms, 600 ms, 1.2 s, capped, plus up to 25% jitter ([random] is
  /// injectable for tests).
  Duration delayFor(int attempt, {double Function()? random}) {
    final raw = baseDelay.inMilliseconds * math.pow(2, attempt);
    final capped = math.min(raw, maxDelay.inMilliseconds.toDouble());
    final jitter = capped * 0.25 * (random ?? math.Random().nextDouble)();
    return Duration(milliseconds: (capped + jitter).round());
  }

  /// Runs [action] under the policy. [isTransient] decides from the thrown error whether it was a network or 5xx
  /// failure; [sleep] is injectable so tests do not wait.
  Future<T> run<T>(
    Future<T> Function() action, {
    required String method,
    required int? Function(Object error) statusOf,
    Future<void> Function(Duration)? sleep,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await action();
      } catch (error) {
        if (!shouldRetry(method: method, status: statusOf(error), attempt: attempt)) rethrow;
        await (sleep ?? Future<void>.delayed)(delayFor(attempt));
        attempt++;
      }
    }
  }
}
