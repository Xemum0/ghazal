import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, PhoneKw;
import 'package:ghazal_domain/ghazal_domain.dart' show Me, OtpChallenge, OtpPurpose, OtpRequestInput, PhoneChangeInput, PhoneVerifyInput, StepUpInput, StepUpMethod;

/// What the code is for: a new phone number (CL-PROF-03) or the fresh code that deletion asks for (CL-PROF-06, ADR 0028 item 7).
enum CodePurpose { phoneChange, stepUp }

/// The views of the code body (the inventory states `phone-change-otp` and `otp-reauth`).
enum CodeView { idle, loading, wrongCode, expiredCode, resent, locked, deliveryFailed, offline, success }

const int kCodeLength = 6;
const int kCodeMaxAttempts = 5;
const int kCodeResendSeconds = 60;

/// Frozen countdown of a code screen opened on its own (no code was sent): mid-wait, like the web frame.
const int kCodeStoryCountdown = 38;

/// A WhatsApp code step as a controller: sends nothing by itself, verifies through the repositories, counts the resend wait down and keeps
/// the attempts. The same rules as the sign-in code (five attempts, 60 s resend, expired and locked).
class ProfileCodeController extends ChangeNotifier {
  ProfileCodeController(this._ref, {required this.purpose, required this.phone});

  final WidgetRef _ref;
  final CodePurpose purpose;

  /// The number the code goes to (E.164 or national digits).
  String phone;

  CodeView _view = CodeView.idle;
  String _code = '';
  int _seconds = kCodeStoryCountdown;
  int _failed = 0;
  bool _live = false;
  OtpChallenge? _challenge;
  Timer? _timer;
  Timer? _hold;
  bool _disposed = false;

  CodeView get view => _view;
  String get code => _code;
  int get seconds => _seconds;
  int get attemptsLeft => (kCodeMaxAttempts - _failed).clamp(0, kCodeMaxAttempts);

  /// A code was really requested (the countdown runs and the code is checked).
  bool get live => _live;

  void _set(CodeView v) {
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
    if (_view == CodeView.wrongCode || _view == CodeView.expiredCode || _view == CodeView.resent) _view = CodeView.idle;
    notifyListeners();
  }

  /// Asks for the code. Returns false when it could not be sent (the view says why).
  Future<bool> send() async {
    final e164 = PhoneKw.toE164(phone) ?? phone;
    try {
      _challenge = purpose == CodePurpose.phoneChange
          ? await _ref.read(profileRepositoryProvider).requestPhoneChange(body: PhoneChangeInput(phone: e164))
          : await _ref.read(authRepositoryProvider).requestOtp(body: OtpRequestInput(phone: e164, purpose: OtpPurpose.login, deviceId: _ref.read(deviceIdProvider)));
      _live = true;
      _seconds = _challenge?.resendAfterSeconds ?? kCodeResendSeconds;
      _startTimer();
      _set(CodeView.idle);
      return true;
    } on ApiProblem catch (e) {
      _set(e.isOffline ? CodeView.offline : CodeView.deliveryFailed);
      return false;
    }
  }

  Future<void> resend() async {
    _code = '';
    _failed = 0;
    if (await send()) _set(CodeView.resent);
  }

  /// Checks [value] (the six digits). On success the seal shows for a moment, then [onVerified] runs.
  Future<void> verify({required VoidCallback onVerified, String? value}) async {
    final v = value ?? _code;
    if (v.length < kCodeLength || _view == CodeView.loading) return;
    _set(CodeView.loading);
    try {
      final challengeId = _challenge?.challengeId ?? '';
      if (purpose == CodePurpose.phoneChange) {
        final Me me = await _ref.read(profileRepositoryProvider).confirmPhoneChange(body: PhoneVerifyInput(challengeId: challengeId, code: v));
        if (_disposed) return;
        final session = _ref.read(sessionProvider);
        if (session is ClientSession) {
          final u = session.user;
          _ref.read(sessionProvider.notifier).setSession(
            ClientSession(user: AuthUser(id: u.id, name: u.name, phone: me.user.phone, monogram: u.monogram, email: u.email), phoneVerified: true),
          );
        }
      } else {
        await _ref.read(authRepositoryProvider).stepUp(body: StepUpInput(method: StepUpMethod.otp, challengeId: challengeId, code: v));
        if (_disposed) return;
      }
      _set(CodeView.success);
      _hold = Timer(const Duration(milliseconds: 1100), onVerified);
    } on ApiProblem catch (e) {
      if (_disposed) return;
      switch (e.code) {
        case ApiProblemCode.otpInvalid:
          _failed++;
          _set(_failed >= kCodeMaxAttempts ? CodeView.locked : CodeView.wrongCode);
        case ApiProblemCode.otpExpired:
          _seconds = 0;
          _set(CodeView.expiredCode);
        case ApiProblemCode.otpLocked:
          _set(CodeView.locked);
        default:
          _set(e.isOffline ? CodeView.offline : CodeView.wrongCode);
      }
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
