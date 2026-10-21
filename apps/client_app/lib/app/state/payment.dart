import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show vouchersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show GatewayMethod, MoneyAmount, PaymentSessionInput, PaymentSessionStatus, PaymentState;

import 'action_result.dart';

/// Where the voucher payment stands (ADR 0027 gateway boundary). `verifying` is "we are asking the gateway": the answer of a redirect is
/// never trusted, the status is read from the server until the webhook has decided.
enum PaymentOutcome { idle, processing, success, failed, cancelled, verifying }

extension PaymentOutcomeX on PaymentOutcome {
  bool get isFinal => this == PaymentOutcome.success || this == PaymentOutcome.failed || this == PaymentOutcome.cancelled;
}

PaymentOutcome paymentOutcomeOf(PaymentSessionStatus s) => switch (s) {
      PaymentSessionStatus.created || PaymentSessionStatus.processing => PaymentOutcome.processing,
      PaymentSessionStatus.verifying => PaymentOutcome.verifying,
      PaymentSessionStatus.succeeded => PaymentOutcome.success,
      PaymentSessionStatus.failed => PaymentOutcome.failed,
      PaymentSessionStatus.cancelled => PaymentOutcome.cancelled,
      PaymentSessionStatus.unknown => PaymentOutcome.processing,
    };

@immutable
final class PaymentFlowState {
  const PaymentFlowState({
    this.outcome = PaymentOutcome.idle,
    this.voucherId,
    this.amount,
    this.method,
    this.methods = const <GatewayMethod>[],
    this.paymentId,
    this.redirectUrl,
    this.failureCode,
    this.problem,
  });

  static const PaymentFlowState idle = PaymentFlowState();

  final PaymentOutcome outcome;

  /// The unpaid voucher being paid for (always a voucher: listing fees are not payable yet, rates are not announced).
  final String? voucherId;

  /// The KD 2 voucher price as the server gave it.
  final MoneyAmount? amount;
  final GatewayMethod? method;

  /// The methods the checkout offered.
  final List<GatewayMethod> methods;
  final String? paymentId;

  /// The hosted gateway page to open (external browser or in-app web view).
  final String? redirectUrl;
  final String? failureCode;

  /// The refusal when the session could not be opened (gateway down, checkout expired).
  final ApiProblem? problem;

  PaymentFlowState copyWith({
    PaymentOutcome? outcome,
    GatewayMethod? method,
    String? paymentId,
    String? redirectUrl,
    String? failureCode,
    ApiProblem? problem,
    bool clearProblem = false,
  }) =>
      PaymentFlowState(
        outcome: outcome ?? this.outcome,
        voucherId: voucherId,
        amount: amount,
        method: method ?? this.method,
        methods: methods,
        paymentId: paymentId ?? this.paymentId,
        redirectUrl: redirectUrl ?? this.redirectUrl,
        failureCode: failureCode ?? this.failureCode,
        problem: clearProblem ? null : (problem ?? this.problem),
      );

  @override
  bool operator ==(Object other) =>
      other is PaymentFlowState &&
      other.outcome == outcome &&
      other.voucherId == voucherId &&
      other.amount == amount &&
      other.method == method &&
      listEquals(other.methods, methods) &&
      other.paymentId == paymentId &&
      other.redirectUrl == redirectUrl &&
      other.failureCode == failureCode &&
      other.problem == problem;

  @override
  int get hashCode => Object.hash(outcome, voucherId, amount, method, Object.hashAll(methods), paymentId, redirectUrl, failureCode, problem);
}

/// The payment outcome machine of the voucher: idle, processing (session open, the person is on the gateway), verifying (asking the
/// server), then success, failed or cancelled. `voucherActionsProvider.checkout` prepares it; the payment screens drive `begin`,
/// `verify` and `reset`.
final NotifierProvider<PaymentNotifier, PaymentFlowState> paymentProvider = NotifierProvider<PaymentNotifier, PaymentFlowState>(PaymentNotifier.new);

class PaymentNotifier extends Notifier<PaymentFlowState> {
  int _generation = 0;
  final IntentKeys _keys = IntentKeys();

  @override
  PaymentFlowState build() {
    ref.onDispose(() => _generation++);
    return PaymentFlowState.idle;
  }

  /// Called by the checkout: an unpaid voucher is waiting for its payment.
  void prepare({required String voucherId, required MoneyAmount amount, List<GatewayMethod> methods = const <GatewayMethod>[]}) {
    _generation++;
    state = PaymentFlowState(voucherId: voucherId, amount: amount, methods: methods);
  }

  /// Opens a hosted gateway session for the prepared voucher with [method] (R: `createPaymentSession`). On success the outcome is
  /// `processing` and `redirectUrl` is the page to open; a refusal (`PAYMENT_GATEWAY_ERROR`, `VOUCHER_CHECKOUT_EXPIRED`) leaves `idle` with
  /// `problem`. [returnUrl] is the deep link the gateway returns to.
  Future<ActionResult<PaymentFlowState>> begin(GatewayMethod method, {String? returnUrl}) async {
    final voucherId = state.voucherId;
    if (voucherId == null) throw StateError('payment.begin without a prepared voucher');
    final intent = 'pay:$voucherId:${method.value}';
    final gen = ++_generation;
    state = state.copyWith(outcome: PaymentOutcome.processing, method: method, clearProblem: true);
    try {
      final session = await ref
          .read(vouchersRepositoryProvider)
          .createPaymentSession(voucherId: voucherId, body: PaymentSessionInput(method: method, returnUrl: returnUrl), idempotencyKey: _keys.keyFor(intent));
      _keys.done(intent);
      if (gen != _generation) return ActionSuccess(state);
      state = state.copyWith(outcome: paymentOutcomeOf(session.status), paymentId: session.id, redirectUrl: session.redirectUrl);
      return ActionSuccess(state);
    } on ApiProblem catch (p) {
      if (p.status >= 400 && p.status < 500) _keys.done(intent);
      if (gen == _generation) state = state.copyWith(outcome: PaymentOutcome.idle, problem: p);
      return ActionFailure(p);
    }
  }

  /// One status read (`getPaymentState`). Success is decided here, never by the redirect: only a `succeeded` answer makes the voucher
  /// paid. Refreshes the lists on success.
  Future<PaymentOutcome> refresh() async {
    final id = state.paymentId;
    if (id == null) return state.outcome;
    final gen = _generation;
    try {
      final PaymentState s = await ref.read(vouchersRepositoryProvider).getPaymentState(paymentId: id);
      if (gen != _generation) return state.outcome;
      final next = paymentOutcomeOf(s.status);
      state = state.copyWith(outcome: next, failureCode: s.failureCode);
      if (next == PaymentOutcome.success) ref.read(clientDataRevisionProvider.notifier).bump();
      return next;
    } on ApiProblem catch (p) {
      if (gen == _generation) state = state.copyWith(problem: p);
      return state.outcome;
    }
  }

  /// The person came back from the gateway (or the app resumed): `verifying`, then read the status every [interval] until it is final or
  /// [maxAttempts] reads passed (the outcome then stays `verifying`: "this is taking longer than usual", the screen offers a manual check).
  Future<PaymentOutcome> verify({Duration interval = const Duration(seconds: 2), int maxAttempts = 15}) async {
    if (state.paymentId == null) return state.outcome;
    final gen = _generation;
    if (!state.outcome.isFinal) state = state.copyWith(outcome: PaymentOutcome.verifying, clearProblem: true);
    for (var i = 0; i < maxAttempts; i++) {
      final o = await refresh();
      if (gen != _generation) return state.outcome;
      if (o.isFinal) return o;
      await Future<void>.delayed(interval);
      if (gen != _generation) return state.outcome;
    }
    return state.outcome;
  }

  /// Back to nothing in flight (the sheet closed, the voucher abandoned, a new checkout starts). Stops a running [verify].
  void reset() {
    _generation++;
    state = PaymentFlowState.idle;
  }
}
