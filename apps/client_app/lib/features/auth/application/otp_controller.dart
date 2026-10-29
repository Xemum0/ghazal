import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;

import 'auth_actions.dart';
import 'auth_flow.dart';

/// The views of the code step (the inventory states of CL-AUTH-02).
enum OtpView { idle, loading, wrongCode, expiredCode, resendCooldown, locked, deliveryFailed, offline, success }

/// How long the seal shows before the flow moves on.
const Duration kOtpSuccessHold = Duration(milliseconds: 1100);

/// Frozen countdown of a code screen that was opened on its own (no code was requested): mid-wait, like the prototype's frame.
const int kOtpStoryCountdown = 38;

/// The WhatsApp code step as a controller (the pushed screen CL-AUTH-02; the booking Details step reuses it as a sheet): sends nothing by
/// itself, verifies through the session, counts the resend wait down and keeps the attempts.
class OtpController extends ChangeNotifier {
  OtpController(this._ref) {
    final flow = _ref.read(authFlowProvider);
    _live = flow.challenge != null;
    _seconds = _live ? flow.challenge!.resendAfterSeconds : kOtpStoryCountdown;
    if (_live) _startTimer();
  }

  final WidgetRef _ref;
  late final bool _live;
  OtpView _view = OtpView.idle;
  String _code = '';
  int _seconds = 0;
  int _failed = 0;
  Timer? _timer;
  Timer? _hold;
  bool _disposed = false;

  OtpView get view => _view;
  String get code => _code;
  int get seconds => _seconds;
  int get failed => _failed;
  int get attemptsLeft => (AuthConfig.maxAttempts - _failed).clamp(0, AuthConfig.maxAttempts);

  /// True when a code was really requested (the countdown ticks and codes are verified); false for a screen opened on its own.
  bool get live => _live;

  void _set(OtpView v) {
    _view = v;
    if (!_disposed) notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        _seconds = 0;
        t.cancel();
      } else {
        _seconds--;
      }
      if (!_disposed) notifyListeners();
    });
  }

  void change(String next) {
    _code = next;
    if (_view == OtpView.wrongCode || _view == OtpView.expiredCode || _view == OtpView.resendCooldown) _view = OtpView.idle;
    notifyListeners();
  }

  /// Verifies [value] (the six digits): login and registration open the session, a password reset keeps the code for the reset call.
  Future<void> verify({required VoidCallback onVerified, String? value}) async {
    final v = value ?? _code;
    if (v.length < AuthConfig.otpLength || _view == OtpView.loading) return;
    _set(OtpView.loading);
    final flow = _ref.read(authFlowProvider);
    try {
      if (flow.purpose == AuthPurpose.passwordReset) {
        _ref.read(authFlowProvider.notifier).update((s) => s.copyWith(resetCode: v));
      } else {
        await _ref.read(sessionProvider.notifier).verifyOtp(v);
      }
      if (_disposed) return;
      _set(OtpView.success);
      _hold = Timer(kOtpSuccessHold, onVerified);
    } on ApiProblem catch (e) {
      if (_disposed) return;
      switch (e.code) {
        case ApiProblemCode.otpInvalid:
          _failed++;
          _set(_failed >= AuthConfig.maxAttempts ? OtpView.locked : OtpView.wrongCode);
        case ApiProblemCode.otpExpired:
          _seconds = 0;
          _set(OtpView.expiredCode);
        case ApiProblemCode.otpLocked:
          _set(OtpView.locked);
        default:
          _set(e.isOffline ? OtpView.offline : OtpView.wrongCode);
      }
    }
  }

  /// Sends a new code. A refusal that is not a rate limit is a delivery failure (no SMS fallback, ADR 0028).
  Future<void> resend() async {
    final flow = _ref.read(authFlowProvider);
    _code = '';
    _failed = 0;
    try {
      await _ref.sendCode(flow.phone, flow.purpose);
      if (_disposed) return;
      _seconds = _ref.read(authFlowProvider).challenge?.resendAfterSeconds ?? AuthConfig.resendSeconds;
      _startTimer();
      _set(OtpView.resendCooldown);
    } on ApiProblem catch (e) {
      if (_disposed) return;
      _set(e.isOffline ? OtpView.offline : OtpView.deliveryFailed);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _hold?.cancel();
    super.dispose();
  }
}
