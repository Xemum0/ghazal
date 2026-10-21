import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show GateReason, GateResume, SessionGate, requestsRepositoryProvider, supportRepositoryProvider, vouchersRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'action_result.dart';
import 'booking_draft.dart';
import 'payment.dart';

/// The writes of the voucher and the request (R01, R05, R07, R08, R10a, R13a) and the credit-voucher ask. Every action returns an
/// [ActionResult] (never throws an `ApiProblem`), shows up in `state.busy` while it runs (`voucher-checkout`, `send-request`,
/// `confirm:<id>`, `cancel:<id>`, `credit:<id>` ...), keeps one idempotency key per intent so a retry replays, refetches the lists on
/// success (`clientDataRevisionProvider`) and on a 409 conflict. A guest is stopped by the gate (`ActionGated`).
///
/// R09 (the 24 h confirm window lapsed: the voucher is forfeited) is a server job: the app only [refresh]es.
final NotifierProvider<VoucherActions, ActionsState> voucherActionsProvider = NotifierProvider<VoucherActions, ActionsState>(VoucherActions.new);

class VoucherActions extends Notifier<ActionsState> {
  final IntentKeys _keys = IntentKeys();

  @override
  ActionsState build() => const ActionsState();

  void _begin(String key) => state = state.copyWith(busy: {...state.busy, key}, clearProblem: true);

  void _end(String key, {ApiProblem? problem}) =>
      state = ActionsState(busy: {...state.busy}..remove(key), lastProblem: problem ?? state.lastProblem);

  /// Runs [call] as the action [key]; [intent] is the idempotency intent (null: no key needed).
  Future<ActionResult<T>> _run<T>(String key, Future<T> Function(String? idempotencyKey) call, {String? intent, void Function(T value)? onSuccess}) async {
    _begin(key);
    try {
      final value = await call(intent == null ? null : _keys.keyFor(intent));
      if (intent != null) _keys.done(intent);
      onSuccess?.call(value);
      ref.read(clientDataRevisionProvider.notifier).bump();
      _end(key);
      return ActionSuccess(value);
    } on ApiProblem catch (p) {
      // A definite refusal ends the intent; a transient failure keeps the key so the retry is the same intent.
      if (intent != null && !p.isTransient) _keys.done(intent);
      if (p.status == 409) ref.read(clientDataRevisionProvider.notifier).bump();
      _end(key, problem: p);
      return ActionFailure(p);
    }
  }

  /// Creates the unpaid voucher bound to the draft's target and quote (CA-VCH-04) and prepares the payment (`paymentProvider`). The draft
  /// keeps the voucher id and the quote id. A guest gets the gate (`GateReason.voucher`) and `ActionGated`. [input] defaults to the draft's.
  Future<ActionResult<VoucherCheckout>> checkout({GateResume? resume, VoucherCheckoutInput? input}) {
    if (!ref.requireSignIn(GateReason.voucher, resume: resume)) return Future.value(const ActionGated());
    final body = input ?? ref.read(bookingDraftProvider).toCheckoutInput();
    return _run<VoucherCheckout>(
      'voucher-checkout',
      (key) => ref.read(vouchersRepositoryProvider).startVoucherCheckout(body: body, idempotencyKey: key),
      intent: 'checkout:${body.targetId}:${body.packageId}:${body.eventDate}:${body.guests}',
      onSuccess: (c) {
        ref.read(bookingDraftProvider.notifier).patch((d) => d.copyWith(voucherId: c.voucher.id, quoteId: c.quote.quoteId));
        ref.read(paymentProvider.notifier).prepare(voucherId: c.voucher.id, amount: c.amount, methods: c.methods);
      },
    );
  }

  /// R01: sends the draft as a request with [voucherId] (default: the draft's voucher) and moves the draft to `sent` with the request id.
  /// A guest gets the gate (`GateReason.sendRequest`). Refusals carry the stable codes (`OPEN_REQUEST_LIMIT`, `SLOT_UNAVAILABLE`,
  /// `QUOTE_CHANGED` ...). Throws `StateError` when the draft is incomplete.
  Future<ActionResult<Booking>> sendRequest({String? voucherId, GateResume? resume}) {
    if (!ref.requireSignIn(GateReason.sendRequest, resume: resume)) return Future.value(const ActionGated());
    final draft = ref.read(bookingDraftProvider);
    final body = draft.toCreateRequestInput(voucherId: voucherId);
    return _run<Booking>(
      'send-request',
      (key) => ref.read(requestsRepositoryProvider).createRequest(body: body, idempotencyKey: key),
      intent: 'send:${body.voucherId}',
      onSuccess: (b) => ref.read(bookingDraftProvider.notifier).patch((d) => d.copyWith(voucherId: body.voucherId, requestId: b.id, step: BookingStep.sent)),
    );
  }

  Future<({int version, BookingStatus status})> _current(String requestId, int? version, BookingStatus? status) async {
    if (version != null && status != null) return (version: version, status: status);
    final b = (await ref.read(requestsRepositoryProvider).getRequest(requestId: requestId)).booking;
    return (version: version ?? b.version, status: status ?? b.status);
  }

  /// R07 (pending: withdraw, the voucher is released and reusable), R10a (approved: cancel, released) or R13a (confirmed: cancel, the
  /// voucher is consumed, no refund). The right call is chosen from the request's status; pass [version] and [status] from the detail you
  /// show to save a read. A stale version answers `BOOKING_STATE_CONFLICT` (the lists refetch).
  Future<ActionResult<Booking>> cancelRequest(String requestId, {CancelReason? reason, int? version, BookingStatus? status}) async {
    final key = 'cancel:$requestId';
    _begin(key);
    final ({int version, BookingStatus status}) cur;
    try {
      cur = await _current(requestId, version, status);
    } on ApiProblem catch (p) {
      _end(key, problem: p);
      return ActionFailure(p);
    }
    _end(key);
    return _run<Booking>(
      key,
      (k) {
        final repo = ref.read(requestsRepositoryProvider);
        return cur.status == BookingStatus.pending
            ? repo.withdrawRequest(requestId: requestId, ifMatch: versionTag(cur.version), idempotencyKey: k)
            : repo.cancelRequest(requestId: requestId, body: CancelRequestInput(reason: reason), ifMatch: versionTag(cur.version), idempotencyKey: k);
      },
      intent: key,
    );
  }

  /// R08: the client confirms inside the 24 h window (`CONFIRM_WINDOW_ENDED` after it: the voucher is forfeited, the screen refetches).
  Future<ActionResult<Booking>> confirm(String requestId, {int? version}) async {
    final key = 'confirm:$requestId';
    _begin(key);
    final int v;
    try {
      v = version ?? (await _current(requestId, null, null)).version;
    } on ApiProblem catch (p) {
      _end(key, problem: p);
      return ActionFailure(p);
    }
    _end(key);
    return _run<Booking>(key, (k) => ref.read(requestsRepositoryProvider).confirmRequest(requestId: requestId, ifMatch: versionTag(v), idempotencyKey: k), intent: key);
  }

  /// R05: the client accepts one date ([optionIndex]) of the venue's counter-offer; the 24 h confirm window starts.
  Future<ActionResult<Booking>> acceptProposal(String requestId, String proposalId, int optionIndex, {int? version}) async {
    final key = 'proposal:$requestId';
    final int v;
    try {
      v = version ?? (await _current(requestId, null, null)).version;
    } on ApiProblem catch (p) {
      return ActionFailure(p);
    }
    return _run<Booking>(
      key,
      (k) => ref.read(requestsRepositoryProvider).acceptProposal(
            requestId: requestId,
            proposalId: proposalId,
            body: ProposalAnswerInput(optionIndex: optionIndex),
            ifMatch: versionTag(v),
            idempotencyKey: k,
          ),
      intent: '$key:accept:$optionIndex',
    );
  }

  /// The client declines the counter-offer: the request is cancelled and the voucher released (no penalty).
  Future<ActionResult<Booking>> declineProposal(String requestId, String proposalId, {int? version}) async {
    final key = 'proposal:$requestId';
    final int v;
    try {
      v = version ?? (await _current(requestId, null, null)).version;
    } on ApiProblem catch (p) {
      return ActionFailure(p);
    }
    return _run<Booking>(
      key,
      (k) => ref.read(requestsRepositoryProvider).declineProposal(requestId: requestId, proposalId: proposalId, ifMatch: versionTag(v), idempotencyKey: k),
      intent: '$key:decline',
    );
  }

  /// Asks support for a credit voucher after a venue-fault release (ADR 0035 D5): records the request, no money goes back, support decides
  /// in the chat. Read `getSupportConversation` afterwards to open it. `409` when one is already open.
  Future<ActionResult<RefundRequest>> askSupportCredit(String voucherId, {String? note}) => _run<RefundRequest>(
        'credit:$voucherId',
        (key) => ref.read(supportRepositoryProvider).createRefundRequest(body: CreateRefundRequestInput(voucherId: voucherId, note: note), idempotencyKey: key),
        intent: 'credit:$voucherId',
      );

  /// The server may have moved on (the clock passed `confirmBy`, the venue answered): refetch the lists.
  void refresh() => ref.read(clientDataRevisionProvider.notifier).bump();
}
