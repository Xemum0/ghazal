/// The mock's control surface (not part of the product API, documented in docs/architecture/mock-api.md): reset, move the story clock, switch
/// persona, force a scenario, settle a payment, moderate a listing, decide a refund request, jump to a story point, read the outbox and the
/// event log. The same operations exist over HTTP under `/__mock/*` (see `control_http.dart`).
library;

import 'core/app.dart';
import 'core/problem.dart';
import 'db/mock_db.dart';
import 'domain/chat.dart';
import 'domain/jobs.dart';
import 'domain/notify.dart';
import 'domain/vouchers.dart';
import 'engine/engine.dart';
import 'handlers/partner_listings.dart' show transitionListing;
import 'handlers/support.dart' show decideRefundRequest;

/// The hero story of the prototype: Reem asks Aurelia Gulf Hotel for Danah Ballroom on 14 Jan 2027, 350 guests, KD 15,400 at the voucher price.
const storyPoints = ['pending', 'approved', 'confirmed', 'redeemed', 'completed', 'declined', 'expired', 'lapsed', 'cancelled', 'counter_offer'];

class MockControl {
  MockControl(this._app);
  final MockApp _app;

  /// Story reset: seeds again, clock back at 2026-11-12T16:00+03:00 (or the configured start), no sessions, no pending work. The persona,
  /// scenario and latency stay as they are.
  Future<void> reset() async => _app.reset();

  DateTime get now => DateTime.fromMillisecondsSinceEpoch(_app.clock.millis, isUtc: true);

  /// The story instant as Kuwait time.
  String get nowText => _app.now;

  /// Sets the story clock and runs the system jobs that fall due (R06, R09, R12, validity, checkout lapse).
  void setClock(DateTime at) {
    _app.clock.set(at);
    sweep(_app);
  }

  /// Moves the story clock forward (the whole "wait 24 hours" of a demo is `advance(Duration(hours: 24))`).
  void advance(Duration d) {
    _app.clock.advance(d);
    sweep(_app);
  }

  /// Requests without a token act as this persona: `guest` (anonymous), `new_client`, `reem`, `hotel_admin`, `hotel_manager`, `hotel_non_major`,
  /// `provider`. Returns the tokens of the persona's session (to seed a `TokenStore`), or null for the guest.
  Json? setPersona(String persona) {
    if (persona != 'guest' && _app.personaOf(persona) == null) throw ArgumentError('unknown persona $persona');
    _app.config.persona = persona;
    return persona == 'guest' ? null : _app.personaTokens(persona);
  }

  String get persona => _app.config.persona;

  /// Tokens of a persona without making it the default.
  Json sessionFor(String persona) => _app.personaTokens(persona);

  /// `none`, `slow`, `error`, `offline`, `empty` or `expired`: sticky until changed (the `X-Mock-Scenario` header applies to one call).
  void setScenario(String scenario) {
    if (scenario != Scenario.none && !Scenario.all.contains(scenario)) throw ArgumentError('unknown scenario $scenario');
    _app.config.scenario = scenario;
  }

  String get scenario => _app.config.scenario;

  /// Sticky latency added to every call (the `X-Mock-Latency` header applies to one call).
  void setLatency(Duration d) => _app.config.latency = d;

  /// The payment gateway answers `502 PAYMENT_GATEWAY_ERROR` to new payment sessions while true.
  void setGatewayDown(bool down) => _app.flags['gatewayDown'] = down;

  /// Settles a payment session: `succeeded` activates the voucher, `failed` and `cancelled` leave it unpaid.
  Json settlePayment(String paymentId, {String outcome = 'succeeded'}) => wire(domainSettle(_app, paymentId, outcome));

  /// Moderation of a listing in `pending_review` (the Super Admin web in the real service): approve (the listing goes live) or reject with codes
  /// (`content_not_compliant`, `wrong_category`, `missing_details`, `unclear_pricing`, `other`) and a note.
  Json moderateListing(String listingId, {required bool approve, List<String> codes = const [], String? note}) {
    final l = _app.db.get('Listing', listingId) ?? (throw ApiError.notFound('listing'));
    if (l['status'] != 'pending_review' && l['status'] != 'approved') throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
    const moderator = 'Yousef Al-Kandari';
    if (approve) {
      if (l['status'] == 'pending_review') transitionListing(_app, l, 'approved', 'moderator', actorName: moderator);
      final plan = _app.seed.rows('AdPlan').cast<Json?>().firstWhere((p) => p!['cycle'] == l['planCycle'], orElse: () => null);
      l['decidedAt'] = _app.now;
      l['startsOn'] = _app.today();
      l['endsOn'] = addDays(_app.today(), plan?.integer('periodDays') ?? 30);
      transitionListing(_app, l, 'active', 'system');
      for (final uid in _app.notifyTargets(providerId: l.strOrNull('providerId'))) {
        notify(_app, userId: uid, kind: 'listing_approved', audience: 'hotel', vars: {'title': l.obj('title')}, params: {'listing': listingId}, listingId: listingId);
      }
    } else {
      final c = codes.isEmpty ? ['other'] : codes;
      l['decidedAt'] = _app.now;
      l['rejection'] = {'codes': c, 'note': {'en': note ?? 'Please review the listing details.', 'ar': note ?? 'يرجى مراجعة تفاصيل الإعلان.'}};
      transitionListing(_app, l, 'rejected', 'moderator', actorName: moderator, codes: c, note: note);
      for (final uid in _app.notifyTargets(providerId: l.strOrNull('providerId'))) {
        notify(_app, userId: uid, kind: 'listing_rejected', audience: 'hotel', vars: {'title': l.obj('title')}, params: {'listing': listingId, 'codes': c}, listingId: listingId);
      }
    }
    _app.db.put('Listing', l);
    return wire(l);
  }

  /// Test hook: marks a listing's fee as paid (the hosted payment cannot run while plan rates are undecided), so the refund-record flow can be exercised.
  Json markListingPaid(String listingId, {int amountFils = 0}) {
    final l = _app.db.get('Listing', listingId) ?? (throw ApiError.notFound('listing'));
    l['billing'] = {'status': 'paid', 'amountFils': amountFils, 'paidAt': _app.now};
    _app.db.put('Listing', l);
    return wire(l);
  }

  /// Decides a plan's rate (fils) or clears it (null): while a rate is null the pay step stays disabled (`PLAN_RATES_NOT_ANNOUNCED`, "Rates announced
  /// soon"). Test hook only: the owner has not decided any rate (OQ-V-07).
  void setPlanRate(String cycle, int? fils) {
    final rates = <String, int?>{...((_app.flags['planRates'] as Map?)?.cast<String, int?>() ?? const {})};
    rates[cycle] = fils;
    _app.flags['planRates'] = rates;
  }

  /// Decides a credit voucher (refund) request: grant creates the credit voucher, decline carries a reason.
  Json decideRefund(String requestId, {required bool grant, String? reason}) => wire(decideRefundRequest(_app, requestId, grant: grant, reason: reason));

  /// A scripted reply from Ghazal support in the group chat of a visit.
  Json supportReply(String visitId, {String? text}) {
    final v = _app.db.get('VisitAppointment', visitId) ?? (throw ApiError.notFound('visit'));
    final members = (_app.db.require('Conversation', v.str('conversationId'))['members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final name = members.cast<Map<String, dynamic>?>().firstWhere((m) => m!['role'] == 'support', orElse: () => null)?['nameLatin'] as String? ?? 'Ghazal support';
    return wire(appendMessage(_app, v.str('conversationId'), from: 'support', senderName: name, text: {'en': text ?? 'Ghazal support here: everything is set for your visit.', 'ar': text ?? 'دعم غزل هنا: كل شيء جاهز لزيارتكم.'}));
  }

  /// Runs every pending scheduled task now (payment answers, chat replies, undo windows), in due order. Tests call this instead of waiting.
  Future<void> flush() => _app.scheduler.flush();

  /// Runs the system jobs for the current clock (also done at the start of every request).
  void sweepNow() => sweep(_app);

  /// Jumps the hero story (Reem, Danah Ballroom, 14 Jan 2027) to one of its prepared states: one of [storyPoints].
  void jumpToStory(String point) {
    if (!storyPoints.contains(point)) throw ArgumentError('unknown story point $point');
    final story = _app.seed.extra.obj('story');
    final id = story.str('bookingId');
    final voucherId = story.str('voucherId');
    final seedBooking = _app.seed.rows('Booking').firstWhere((b) => b['id'] == id);
    final seedVoucher = _app.seed.rows('Voucher').firstWhere((v) => v['id'] == voucherId);
    final variant = point == 'pending' ? null : _app.seed.extra.obj('heroVariants').obj(point);
    final booking = deepCopy(variant?.obj('booking') ?? seedBooking);
    final voucher = deepCopy(variant?.obj('voucher') ?? seedVoucher);
    _app.db.put('Booking', booking);
    _app.db.put('Voucher', voucher);
    for (final c in _app.db.raw('CalendarClaim').toList()) {
      if (c['bookingId'] == id) _app.db.remove('CalendarClaim', c.str('id'));
    }
    final claimKind = {'pending': 'requested', 'counter_offer': 'requested', 'approved': 'hold', 'confirmed': 'booking', 'redeemed': 'booking'}[point];
    if (claimKind != null) {
      for (final s in booking.list('sections')) {
        _app.db.put('CalendarClaim', {
          'id': 'claim-${booking['ref']}-${s['position']}',
          'venueId': booking['venueId'],
          'hallId': s['hallId'],
          'date': booking['eventDate'],
          'kind': claimKind,
          'bookingId': id,
          'audience': s['audience'],
          'guests': s['guests'],
          'clientName': booking['clientName'],
          'blockReason': null,
          'blockNote': null,
          'blockedBy': null,
          'holdUntil': claimKind == 'hold' ? booking['confirmBy'] : null,
          'start': s['start'],
          'end': s['end'],
        });
      }
    }
    final extra = variant?.objOrNull('extra');
    if (extra != null) _app.logEvent('story_extra', {'keys': extra.keys.toList()});
    // the client notification that goes with the point
    final notes = _app.seed.extra.obj('client').obj('heroVariantNotifications');
    final key = {'approved': 'approved', 'confirmed': 'confirmed', 'lapsed': 'lapsed', 'declined': 'declined', 'redeemed': 'redeemed'}[point];
    if (key != null && notes[key] is Map) {
      final n = deepCopy((notes[key] as Map).cast<String, dynamic>());
      n['id'] = 'ntf-story-$point';
      n['at'] = _app.now;
      n['read'] = false;
      _app.db.put('Notification', n);
    }
    _app.logEvent('story_point', {'point': point});
  }

  /// The competing request of the web Decision screen (`simulateCompeting`): Dalal asks Aurelia for the same Thursday (14 Jan 2027, Danah Ballroom).
  /// The seed keeps it out of the database (a sixth pending request would not match the story: five wait at the start); this puts it in, with its
  /// voucher and its `requested` claim, so the partner's request counts and Needs-you gain a row and "other requests for this date" reads 2.
  /// Idempotent; returns the booking, or null when it is already there or the seed has none.
  Json? simulateRival() {
    final stash = _app.db.get('Rival', 'rival');
    if (stash == null) return null;
    final booking = stash.obj('booking');
    final voucher = stash.objOrNull('voucher');
    _app.db.put('Booking', booking);
    if (voucher != null) _app.db.put('Voucher', voucher);
    for (final s in booking.list('sections')) {
      _app.db.put('CalendarClaim', {
        'id': 'claim-req-${booking['ref']}-${s['position']}',
        'venueId': booking['venueId'],
        'hallId': s['hallId'],
        'date': booking['eventDate'],
        'kind': 'requested',
        'bookingId': booking['id'],
        'audience': s['audience'],
        'guests': s['guests'],
        'clientName': booking['clientName'],
        'blockReason': null,
        'blockNote': null,
        'blockedBy': null,
        'holdUntil': null,
        'start': s['start'],
        'end': s['end'],
      });
    }
    _app.db.remove('Rival', 'rival');
    _app.logEvent('rival_request', {'bookingId': booking['id']});
    return wire(booking);
  }

  /// The emails the mock "sent" (partner codes, staff invitations, password resets, calendar files), oldest first.
  List<Json> get outbox => List.unmodifiable(_app.outbox);

  /// Everything noteworthy that happened (state changes, notifications, scheduled work, errors), oldest first.
  List<Json> get events => List.unmodifiable(_app.eventLog);

  /// A summary of the current state for the Demo tools sheet.
  Json get state => {
        'now': _app.now,
        'persona': _app.config.persona,
        'scenario': _app.config.scenario,
        'latencyMs': _app.config.latency.inMilliseconds,
        'gatewayDown': _app.flags['gatewayDown'] == true,
        'pendingTasks': _app.scheduler.pending,
        'counts': {for (final c in ['Booking', 'Voucher', 'VisitAppointment', 'Conversation', 'Message', 'Notification', 'Listing']) c: _app.db.count(c)},
      };
}

/// Indirection so `control.dart` does not import `domain/vouchers.dart` twice under different names.
Json domainSettle(MockApp app, String id, String outcome) => settlePayment(app, id, outcome);
