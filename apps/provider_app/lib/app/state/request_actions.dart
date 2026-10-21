import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerBookingsRepositoryProvider, partnerRequestsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'action_result.dart';

/// What the partner just did to a request, for the toast and the undo.
enum PartnerActionKind { accept, decline, proposeDates, revoke, cancelConfirmed }

@immutable
final class PartnerAction {
  const PartnerAction({required this.kind, required this.requestId, required this.booking, required this.undoable});

  final PartnerActionKind kind;
  final String requestId;

  /// The request as the server answered the action.
  final Booking booking;

  /// Only an accept can be undone (R03u), and only inside the window.
  final bool undoable;

  @override
  bool operator ==(Object other) => other is PartnerAction && other.kind == kind && other.requestId == requestId && other.booking.version == booking.version && other.undoable == undoable;

  @override
  int get hashCode => Object.hash(kind, requestId, booking.version, undoable);
}

@immutable
final class RequestActionsState {
  const RequestActionsState({this.busy = const <String>{}, this.lastProblem, this.last});

  /// Keys of the actions in flight: `accept:<id>`, `decline:<id>`, `propose:<id>`, `cancel:<id>`, `redeem:<code>`.
  final Set<String> busy;
  final ApiProblem? lastProblem;

  /// The last action; while [PartnerAction.undoable] it is the one the 8-second undo bar offers. Cleared by [RequestActions.commit], by the
  /// timer, by the next action and by an undo.
  final PartnerAction? last;

  bool get isBusy => busy.isNotEmpty;
  bool isBusyWith(String key) => busy.contains(key);
  bool get canUndo => last?.undoable ?? false;

  @override
  bool operator ==(Object other) => other is RequestActionsState && setEquals(other.busy, busy) && other.lastProblem == lastProblem && other.last == last;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(busy), lastProblem, last);
}

/// How long the undo bar stays (ADR 0008 D5: 8 seconds). The server holds the undo for the same time; tests override it.
final Provider<Duration> undoWindowProvider = Provider<Duration>((ref) => const Duration(seconds: 8));

/// The partner's write actions on requests (R03 accept, R03u undo, R04 decline, R05 propose dates, R10b revoke, R13b cancel, R11 redeem).
/// Every action returns an [ActionResult] (never throws an `ApiProblem`), shows in `state.busy`, keeps one idempotency key per intent and
/// refetches the lists afterwards (`partnerDataRevisionProvider`; also after a 409, the request moved under the screen). The server decides
/// who may do what: a `403` arrives as a problem.
final NotifierProvider<RequestActions, RequestActionsState> requestActionsProvider = NotifierProvider<RequestActions, RequestActionsState>(RequestActions.new);

class RequestActions extends Notifier<RequestActionsState> {
  final IntentKeys _keys = IntentKeys();
  Timer? _undoTimer;

  @override
  RequestActionsState build() {
    ref.onDispose(() => _undoTimer?.cancel());
    return const RequestActionsState();
  }

  void _begin(String key) => state = RequestActionsState(busy: {...state.busy, key}, last: state.last);

  void _end(String key, {ApiProblem? problem, PartnerAction? last, bool keepLast = true}) => state = RequestActionsState(
        busy: {...state.busy}..remove(key),
        lastProblem: problem,
        last: last ?? (keepLast ? state.last : null),
      );

  void _bump() => ref.read(partnerDataRevisionProvider.notifier).bump();

  Future<ActionResult<T>> _run<T>(String key, String intent, Future<T> Function(String idempotencyKey) call, {PartnerAction? Function(T value)? record}) async {
    _begin(key);
    try {
      final value = await call(_keys.keyFor(intent));
      _keys.done(intent);
      final action = record?.call(value);
      _undoTimer?.cancel();
      _end(key, last: action, keepLast: false);
      if (action != null && action.undoable) _undoTimer = Timer(ref.read(undoWindowProvider), commit);
      _bump();
      return ActionSuccess(value);
    } on ApiProblem catch (p) {
      if (!p.isTransient) _keys.done(intent);
      if (p.status == 409) _bump();
      _end(key, problem: p);
      return ActionFailure(p);
    }
  }

  Future<({int version, BookingStatus status})> _current(String requestId, int? version, BookingStatus? status) async {
    if (version != null && status != null) return (version: version, status: status);
    final b = (await ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: requestId)).booking;
    return (version: version ?? b.version, status: status ?? b.status);
  }

  /// Runs [call] with the version of the request: [version] when the screen has it, otherwise read first.
  Future<ActionResult<Booking>> _versioned(
    String key,
    String requestId,
    int? version,
    Future<Booking> Function(String ifMatch, String idempotencyKey) call,
    PartnerActionKind kind, {
    String? intent,
  }) async {
    final int v;
    if (version != null) {
      v = version;
    } else {
      _begin(key);
      try {
        v = (await _current(requestId, null, null)).version;
      } on ApiProblem catch (p) {
        _end(key, problem: p);
        return ActionFailure(p);
      }
      _end(key);
    }
    return _run<Booking>(key, intent ?? key, (k) => call(versionTag(v), k), record: (b) => PartnerAction(kind: kind, requestId: requestId, booking: b, undoable: kind == PartnerActionKind.accept));
  }

  /// R03: approves at the voucher price (or lower: [lowerVoucherTotal], never higher). Starts the fixed 24 h confirm window and the undo
  /// bar (`state.last`, 8 s). `SLOT_UNAVAILABLE` when the date was taken meanwhile.
  Future<ActionResult<Booking>> accept(String requestId, {MoneyAmount? lowerVoucherTotal, int? version}) => _versioned(
        'accept:$requestId',
        requestId,
        version,
        (ifMatch, k) => ref
            .read(partnerRequestsRepositoryProvider)
            .acceptRequest(requestId: requestId, body: AcceptRequestInput(lowerVoucherTotal: lowerVoucherTotal), ifMatch: ifMatch, idempotencyKey: k),
        PartnerActionKind.accept,
      );

  /// R03u: takes the accept back inside the undo window (the request returns to pending; the client was never told). Fails with a problem
  /// once the window passed.
  Future<ActionResult<Booking>> undo() async {
    final last = state.last;
    if (last == null || !last.undoable) throw StateError('nothing to undo');
    final key = 'undo:${last.requestId}';
    _undoTimer?.cancel();
    final result = await _run<Booking>(key, key, (k) => ref.read(partnerRequestsRepositoryProvider).undoAcceptRequest(requestId: last.requestId, idempotencyKey: k));
    // The result of an undo is not itself undoable: the bar is gone either way.
    if (state.last == last) state = RequestActionsState(busy: state.busy, lastProblem: state.lastProblem);
    return result;
  }

  /// The undo window ended (the toast closed): the action stands.
  void commit() {
    _undoTimer?.cancel();
    if (state.last != null) state = RequestActionsState(busy: state.busy, lastProblem: state.lastProblem);
  }

  /// R04: declines with a reason (`note` is required and shown to the client for `other`). The voucher is released. Not undoable.
  Future<ActionResult<Booking>> decline(String requestId, RejectReason reason, {String? note, int? version}) => _versioned(
        'decline:$requestId',
        requestId,
        version,
        (ifMatch, k) => ref
            .read(partnerRequestsRepositoryProvider)
            .declineRequest(requestId: requestId, body: DeclineRequestInput(reason: reason, note: note), ifMatch: ifMatch, idempotencyKey: k),
        PartnerActionKind.decline,
      );

  /// R05: the counter-offer, one to three dates in the same hall and session; the voucher price is held and the client has 48 hours.
  Future<ActionResult<Booking>> proposeDates(String requestId, List<ProposedDateInput> options, {int? version}) => _versioned(
        'propose:$requestId',
        requestId,
        version,
        (ifMatch, k) => ref
            .read(partnerRequestsRepositoryProvider)
            .proposeDates(requestId: requestId, body: ProposeDatesInput(options: options), ifMatch: ifMatch, idempotencyKey: k),
        PartnerActionKind.proposeDates,
        intent: 'propose:$requestId:${options.map((o) => '${o.eventDate}${o.hallId}${o.sessionId}').join(',')}',
      );

  /// "Propose another date" with one date in the request's first hall and session (what the prototype's `rescheduleRequest` did).
  Future<ActionResult<Booking>> rescheduleTo(String requestId, LocalDate date) async {
    try {
      final b = (await ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: requestId)).booking;
      final s = b.sections.isEmpty ? null : b.sections.first;
      if (s == null) throw StateError('request $requestId has no hall section to move');
      return await proposeDates(requestId, [ProposedDateInput(eventDate: date, hallId: s.hallId, sessionId: s.sessionId)], version: b.version);
    } on ApiProblem catch (p) {
      return ActionFailure(p);
    }
  }

  /// R10b (an approved request: revoke, the voucher is released and refundable) or R13b (a confirmed one: cancel, released and refundable,
  /// a reliability strike). The call is chosen from the status ([status], or read first). [reason] defaults to `approvalRevoked` /
  /// `hallUnavailable`.
  Future<ActionResult<Booking>> cancelByPartner(String requestId, {CancelReason? reason, String? note, int? version, BookingStatus? status}) async {
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
    final approved = cur.status == BookingStatus.approved;
    final body = PartnerCancelInput(reason: reason ?? (approved ? CancelReason.approvalRevoked : CancelReason.hallUnavailable), note: note);
    return _versioned(
      key,
      requestId,
      cur.version,
      (ifMatch, k) => approved
          ? ref.read(partnerRequestsRepositoryProvider).revokeApproval(requestId: requestId, body: body, ifMatch: ifMatch, idempotencyKey: k)
          : ref.read(partnerRequestsRepositoryProvider).cancelConfirmedRequest(requestId: requestId, body: body, ifMatch: ifMatch, idempotencyKey: k),
      approved ? PartnerActionKind.revoke : PartnerActionKind.cancelConfirmed,
    );
  }

  static String _code(String code) => code.trim().toUpperCase();

  /// R11 step one: reads what the code would redeem (`ok: false` with a reason: `unknownCode`, `otherPartner`, `notConfirmed`,
  /// `alreadyUsed`). Nothing changes on the server.
  Future<ActionResult<RedeemCheck>> checkVoucher(String code) async {
    try {
      return ActionSuccess(await ref.read(partnerBookingsRepositoryProvider).checkVoucherCode(code: _code(code)));
    } on ApiProblem catch (p) {
      return ActionFailure(p);
    }
  }

  /// R11 step two: the one confirmation ("Redeem"): the voucher becomes used and the request redeemed. Run [checkVoucher] first and show it.
  Future<ActionResult<VoucherAndRequest>> redeem(String code) => _run<VoucherAndRequest>(
        'redeem:${_code(code)}',
        'redeem:${_code(code)}',
        (k) => ref.read(partnerBookingsRepositoryProvider).redeemVoucher(code: _code(code), idempotencyKey: k),
      );
}
