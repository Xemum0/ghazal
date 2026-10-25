/// The request (booking) lifecycle: creation with a voucher (R01) and the transitions R03-R13 with their actors, guards, voucher outcomes,
/// calendar claims and notifications (docs/architecture/booking-state-machine.md). The transition table itself is the engine's; this file
/// applies it to documents. No money moves here: the venue and the client settle off-app (ADR 0033).
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'notify.dart';
import 'vouchers.dart';

// ---------------------------------------------------------------- helpers

Json requireBooking(MockApp app, String idOrRef) {
  final b = app.db.get('Booking', idOrRef) ?? app.db.firstWhere('Booking', (d) => d['ref'] == idOrRef);
  return b ?? (throw ApiError.notFound('request'));
}

/// End of the event plus the completion delay: the moment R12 fires (event day, sessions end by 02:00 next morning, plus 12 h).
String eventEndOf(MockApp app, Json booking) =>
    addHours('${addDays(booking.str('eventDate'), 1)}T02:00:00+03:00', app.platformConfig.integer('completionDelayHours'));

String _sectionStart(Json b) {
  final sections = b.list('sections');
  return atTime(b.str('eventDate'), sections.isNotEmpty ? sections.first.str('start') : '12:00');
}

List<Json> _thread(Json b) {
  final status = b.str('status');
  final events = b.list('events');
  String? eventAt(String to) {
    for (final e in events.reversed) {
      if (e['to'] == to) return e.str('at');
    }
    return null;
  }

  final approvedAt = b.strOrNull('approvedAt');
  final confirmedAt = b.strOrNull('confirmedAt');
  final redeemedAt = b.strOrNull('redeemedAt');
  final wasApproved = approvedAt != null;
  final wasConfirmed = confirmedAt != null;
  final end = {'declined', 'expired', 'cancelled'}.contains(status);
  Json knot(String node, String state, [String? at, Json? extra]) => {'node': node, 'state': state, 'at': at, ...?extra};

  final request = knot('request', 'done', b.str('createdAt'));
  Json approval;
  if (status == 'pending') {
    approval = knot('approval', 'current', b.strOrNull('respondBy'));
  } else if (wasApproved) {
    approval = knot('approval', 'done', approvedAt);
  } else {
    approval = knot('approval', 'closed', b['expiredReason'] == 'venue_no_response' ? b.strOrNull('respondBy') : eventAt(status));
  }
  Json confirmation;
  if (status == 'approved') {
    confirmation = knot('confirmation', 'current', b.strOrNull('confirmBy'));
  } else if (wasConfirmed) {
    confirmation = knot('confirmation', 'done', confirmedAt);
  } else if (wasApproved && end) {
    confirmation = knot('confirmation', 'closed', b['expiredReason'] == 'client_no_confirmation' ? b.strOrNull('confirmBy') : null);
  } else {
    confirmation = knot('confirmation', end ? 'closed' : 'future');
  }
  Json redemption;
  if (redeemedAt != null) {
    redemption = knot('redemption', 'done', redeemedAt, b['redeemedBy'] != null ? {'by': b['redeemedBy']} : null);
  } else if (status == 'confirmed') {
    redemption = knot('redemption', 'current');
  } else if (end) {
    redemption = knot('redemption', 'closed');
  } else if (status == 'completed') {
    redemption = knot('redemption', 'done', b.strOrNull('completedAt'));
  } else {
    redemption = knot('redemption', 'future');
  }
  final day = status == 'completed' ? knot('day', 'done', _sectionStart(b)) : (end ? knot('day', 'closed') : knot('day', 'future', _sectionStart(b)));
  return [request, approval, confirmation, redemption, day, if (status == 'completed') knot('completed', 'done', b.strOrNull('completedAt'))];
}

List<String> _clientActions(Json b) {
  final a = ['message'];
  switch (b['status']) {
    case 'pending':
      a.addAll(['withdraw', 'call']);
      if (b.objOrNull('proposal')?['status'] == 'proposed') a.addAll(['accept_proposal', 'decline_proposal']);
    case 'approved':
      a.addAll(['confirm', 'cancel', 'call']);
    case 'confirmed':
      a.addAll(['cancel', 'call', 'open_voucher']);
    case 'redeemed':
      a.add('open_voucher');
    case 'completed':
      a.addAll(['review', 'report_issue', 'open_voucher']);
  }
  return a;
}

List<String> _partnerActions(Json b) {
  final a = ['message'];
  switch (b['status']) {
    case 'pending':
      a.add('call');
      // while a counter-offer is open the venue waits for the client's answer
      if (b.objOrNull('proposal')?['status'] != 'proposed') a.addAll(['accept', 'decline', 'propose']);
    case 'approved':
      a.addAll(['call', 'revoke']);
    case 'confirmed':
      a.addAll(['call', 'redeem', 'cancel']);
  }
  return a;
}

/// The booking as one of the apps sees it (`role`: client or partner): internal fields stripped, `allowedActions` for that viewer.
Json viewBooking(Json b, {String role = 'client'}) {
  final out = wire(b);
  out['allowedActions'] = role == 'partner' ? _partnerActions(b) : _clientActions(b);
  return out;
}

/// Raises BOOKING_STATE_CONFLICT carrying the current status and version (the "already updated" sheet).
ApiError conflict(Json b) => ApiError('BOOKING_STATE_CONFLICT', currentStatus: b.str('status'), currentVersion: b.integer('version'));

void checkIfMatch(Req r, Json b) {
  final m = r.ifMatch;
  if (m != null && m != 'v${b.integer('version')}') throw conflict(b);
}

void _save(MockApp app, Json b) {
  b['version'] = b.list('events').length + 1;
  b['thread'] = _thread(b);
  app.db.put('Booking', b);
}

Json _event(MockApp app, {String? from, String? to, required String actor, String? actorName, String? note, String kind = 'transition'}) => {
  'at': app.now,
  'kind': kind,
  'from': from,
  'to': to,
  'actor': actor,
  'actorName': ?actorName,
  if (note != null && note.isNotEmpty) 'note': {'en': note, 'ar': note},
};

/// Applies a table transition: guards the source status, appends the event, saves. Returns the stored booking.
Json _go(MockApp app, Json b, String id, {required String actorName, String? note, required void Function(Json b) mutate}) {
  final t = transitionById(id)!;
  if (b['status'] != t.from) throw conflict(b);
  mutate(b);
  b['status'] = t.to;
  b.list('events'); // normalise
  (b['events'] as List).add(_event(app, from: t.from, to: t.to, actor: t.actor, actorName: actorName, note: note));
  _save(app, b);
  app.logEvent('request_${t.id}', {'bookingId': b['id'], 'from': t.from, 'to': t.to});
  return b;
}

// ---------------------------------------------------------------- calendar claims

void _dropClaims(MockApp app, String bookingId) {
  for (final c in app.db.raw('CalendarClaim').toList()) {
    if (c['bookingId'] == bookingId) app.db.remove('CalendarClaim', c.str('id'));
  }
}

void _setClaims(MockApp app, Json b, String kind, {String? holdUntil}) {
  _dropClaims(app, b.str('id'));
  final venueId = b.strOrNull('venueId');
  if (venueId == null) return;
  for (final s in b.list('sections')) {
    app.db.put('CalendarClaim', {
      'id': 'claim-${b['ref']}-${s['position']}',
      'venueId': venueId,
      'hallId': s['hallId'],
      'date': b['eventDate'],
      'kind': kind,
      'bookingId': b['id'],
      'audience': s['audience'],
      'guests': s['guests'],
      'clientName': b['clientName'],
      'blockReason': null,
      'blockNote': null,
      'blockedBy': null,
      'holdUntil': kind == 'hold' ? holdUntil : null,
      'start': s['start'],
      'end': s['end'],
    });
  }
}

/// Another booking, hold or block already occupies one of the request's halls on its date.
bool _slotTaken(MockApp app, Json b, {String? date, List<Json>? sections}) {
  final d = date ?? b.str('eventDate');
  for (final s in sections ?? b.list('sections')) {
    for (final c in app.db.raw('CalendarClaim')) {
      if (c['hallId'] == s['hallId'] && c['date'] == d && c['bookingId'] != b['id'] && {'booking', 'block', 'hold'}.contains(c['kind'])) return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------- creation (R01)

List<Json> _alternatives(MockApp app, String hallId, String venueId, String date) {
  final out = <Json>[];
  final engine = app.engine();
  var month = monthOf(date);
  for (var i = 0; i < 3 && out.length < 3; i++) {
    for (final d in engine.availabilityFor(venueId, hallId, month)) {
      if (d.str('date').compareTo(date) > 0 && isRequestable(d)) out.add({'eventDate': d['date'], 'hallId': hallId});
      if (out.length == 3) break;
    }
    month = addMonths(month, 1);
  }
  return out;
}

String _nextRef(MockApp app, List<Object> seed) {
  final n = app.db.next('booking');
  String ref;
  var tries = 0;
  do {
    ref = 'GZ-${app.now.substring(2, 4)}${app.now.substring(5, 7)}-${crockford4([...seed, n, tries])}';
    tries++;
  } while (app.db.raw('Booking').any((b) => b['ref'] == ref) && tries < 50);
  return ref;
}

/// Validates the sections of a venue request or quote against the contract's guards (channel, audience, guests, session, lead time, availability
/// and a price rule for the date) and returns the booking sections plus the shape the quote engine takes. Errors: CHANNEL_NOT_BOOKABLE,
/// LEAD_TIME_TOO_SHORT, AUDIENCE_NOT_ALLOWED, GUESTS_OUT_OF_RANGE, SLOT_UNAVAILABLE (with alternatives).
({List<Json> sections, List<Json> quoteSections}) buildSections(
  MockApp app,
  String venueId,
  String eventDate,
  List<Json> input, {
  required bool sessionRequired,
}) {
  final venue = app.db.peek('Venue', venueId) ?? (throw ApiError.notFound('venue'));
  if (venue['channel'] == 'external_link') throw ApiError('CHANNEL_NOT_BOOKABLE');
  if (input.isEmpty) throw ApiError.validation('/sections', 'required');
  if (diffDays(app.today(), eventDate) < minLeadDays) throw ApiError('LEAD_TIME_TOO_SHORT', params: {'minDays': minLeadDays});
  final engine = app.engine();
  final sections = <Json>[];
  final quoteSections = <Json>[];
  var pos = 0;
  for (final s in input) {
    pos++;
    final at = '/sections/${pos - 1}';
    final hall =
        venue.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == s['hallId'], orElse: () => null) ??
        (throw ApiError.validation('$at/hallId', 'unknown_hall'));
    final pkg = app.db.peek('Package', s.str('packageId'));
    if (pkg == null || pkg['venueId'] != venueId || !pkg.strings('hallIds').contains(hall['id'])) throw ApiError.validation('$at/packageId', 'unknown_package');
    final sec = hall.list('sections').cast<Json?>().firstWhere((x) => x!['audience'] == s['audience'], orElse: () => null);
    if (sec == null || !pkg.strings('audiences').contains(s['audience'])) throw ApiError('AUDIENCE_NOT_ALLOWED', params: {'audience': s['audience']});
    final lo = effectiveMinGuests(pkg, sec.integer('minGuests'));
    final hi = pkg.integer('maxGuests') < sec.integer('maxGuests') ? pkg.integer('maxGuests') : sec.integer('maxGuests');
    final guests = s.integer('guests');
    if (guests < 1 || guests > hi) throw ApiError('GUESTS_OUT_OF_RANGE', params: {'min': lo, 'max': hi});
    final day = engine
        .availabilityFor(venueId, hall.str('id'), monthOf(eventDate))
        .cast<Json?>()
        .firstWhere((d) => d!['date'] == eventDate, orElse: () => null);
    final daySessions = day?.list('sessions') ?? const <Json>[];
    Json? session;
    if (s['sessionId'] != null) {
      session =
          hall.list('sessions').cast<Json?>().firstWhere((x) => x!['id'] == s['sessionId'], orElse: () => null) ??
          (throw ApiError.validation('$at/sessionId', 'unknown_session'));
    } else {
      if (sessionRequired) throw ApiError.validation('$at/sessionId', 'required');
      for (final cand in hall.list('sessions')) {
        final st = daySessions.cast<Json?>().firstWhere((x) => x!['sessionId'] == cand['id'], orElse: () => null)?['state'];
        if (st == 'available' || st == 'held') {
          session = cand;
          break;
        }
      }
      session ??= hall.list('sessions').first;
    }
    final sess = daySessions.cast<Json?>().firstWhere((x) => x!['sessionId'] == session!['id'], orElse: () => null);
    if (day == null || !isRequestable(day) || (sess != null && sess['state'] != 'available' && sess['state'] != 'held')) {
      throw ApiError(
        'SLOT_UNAVAILABLE',
        params: {'hallId': hall['id'], 'eventDate': eventDate},
        alternatives: _alternatives(app, hall.str('id'), venueId, eventDate),
      );
    }
    if (resolveRule(app.db.raw('PriceRule'), pkg.str('id'), eventDate) == null) {
      throw ApiError('SLOT_UNAVAILABLE', params: {'reason': 'package_not_sold'}, alternatives: _alternatives(app, hall.str('id'), venueId, eventDate));
    }
    final bg = billableGuests(guests, lo, pkg.integer('complimentaryBps'));
    sections.add({
      'position': pos,
      'hallId': hall['id'],
      'sessionId': session['id'],
      'audience': s['audience'],
      'guests': guests,
      'billableGuests': bg.billable,
      'packageId': pkg['id'],
      'start': session['start'],
      'end': session['end'],
    });
    quoteSections.add({'hallId': hall['id'], 'audience': s['audience'], 'guests': guests, 'packageId': pkg['id']});
  }
  return (sections: sections, quoteSections: quoteSections);
}

/// The extras of a quote or a request: each one a live extra of the venue, with a quantity between 1 and its `maxQty` (a per-guest extra takes the
/// billable guests, so its quantity is only checked to be at least 1). Errors: 422 `unknown_extra`, `out_of_range` (with `params.max`).
void checkExtras(MockApp app, String venueId, List<Json> extras) {
  for (final e in extras.indexed) {
    final x = app.db.peek('Extra', e.$2.str('extraId'));
    if (x == null || x['venueId'] != venueId || !x.flag('active')) throw ApiError.validation('/extras/${e.$1}/extraId', 'unknown_extra');
    final qty = e.$2.integer('qty');
    if (qty < 1 || (x['pricingUnit'] != 'per_guest' && qty > x.integer('maxQty'))) {
      throw ApiError.validation('/extras/${e.$1}/qty', 'out_of_range', params: {'max': x.integer('maxQty')});
    }
  }
}

/// R01: sends a request with an active voucher. Returns the stored booking (client view is built by the caller).
Json createRequest(MockApp app, Identity who, Json input) {
  final cfg = app.platformConfig;
  final user = who.user;
  if (app.db.peek('User', who.userId)?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
  final voucher = app.db.get('Voucher', input.str('voucherId'));
  if (voucher == null || voucher['clientId'] != who.userId) throw ApiError('VOUCHER_NOT_USABLE', detail: 'unknown voucher');
  final seen = asSeen(app, voucher);
  if (seen['status'] != 'active') throw ApiError('VOUCHER_NOT_USABLE', params: {'status': seen['status']});
  final open = app.db.raw('Booking').where((b) => b['clientId'] == who.userId && openStatuses.contains(b['status'])).length;
  if (open >= cfg.integer('maxOpenRequests')) throw ApiError('OPEN_REQUEST_LIMIT', params: {'max': cfg['maxOpenRequests']});

  final isProvider = input['targetType'] == 'provider';
  final eventDate = input.str('eventDate');
  final today = app.today();
  if (diffDays(today, eventDate) < minLeadDays && !isProvider) throw ApiError('LEAD_TIME_TOO_SHORT', params: {'minDays': minLeadDays});
  final engine = app.engine();
  final targetId = isProvider ? input.strOrNull('providerId') : input.strOrNull('venueId');
  if (targetId == null) throw ApiError.validation(isProvider ? '/providerId' : '/venueId', 'required');
  if (voucher['kind'] == 'bound' &&
      voucher['_creditOrigin'] != true &&
      (voucher['venueOrProviderId'] != targetId || voucher['targetType'] != (isProvider ? 'provider' : 'venue'))) {
    throw ApiError('VOUCHER_TARGET_MISMATCH', params: {'voucherTarget': voucher['venueOrProviderId']});
  }

  late final Json quote;
  var sections = <Json>[];
  Json? service;
  String? hallIdForVoucher;
  String packageIdForVoucher;
  int? guestsForVoucher;
  if (isProvider) {
    final s = input.objOrNull('service') ?? (throw ApiError.validation('/service', 'required'));
    final provider = app.db.peek('ServiceProvider', targetId) ?? (throw ApiError.notFound('provider'));
    final listing = app.db.raw('Listing').cast<Json?>().firstWhere((l) => l!['providerId'] == targetId && l['status'] == 'active', orElse: () => null);
    if (listing == null) throw ApiError('CHANNEL_NOT_BOOKABLE', detail: 'the provider has no live listing');
    if (!provider.list('packages').any((p) => p['id'] == s['packageId'])) throw ApiError.validation('/service/packageId', 'unknown_package');
    final qty = s.integer('quantity');
    quote = engine.quoteForProvider(providerId: targetId, packageId: s.str('packageId'), qty: qty);
    service = {'providerId': targetId, 'listingId': s['listingId'] ?? listing['id'], 'packageId': s['packageId'], 'quantity': qty, 'venueId': s['venueId']};
    packageIdForVoucher = s.str('packageId');
  } else {
    checkExtras(app, targetId, input.list('extras'));
    final built = buildSections(app, targetId, eventDate, input.list('sections'), sessionRequired: true);
    sections = built.sections;
    final quoteSections = built.quoteSections;
    quote = engine.quoteFor(venueId: targetId, eventDate: eventDate, sections: quoteSections, extras: input.list('extras'));
    hallIdForVoucher = sections.first.str('hallId');
    packageIdForVoucher = sections.first.str('packageId');
    guestsForVoucher = sections.first.integer('guests');
  }
  // the snapshot the client saw (quoteId) and the voucher's own quote must still hold
  final qid = input.strOrNull('quoteId');
  if (qid != null) {
    final snap = app.db.peek('Quote', qid);
    if (snap == null) throw ApiError('QUOTE_EXPIRED');
    if (instantMs(app.now) > instantMs(snap.str('expiresAt'))) throw ApiError('QUOTE_EXPIRED');
    final t = quote.obj('totals');
    if (snap['voucherTotal'] != filsOf(t.obj('voucherTotal')) || snap['standardTotal'] != filsOf(t.obj('standardTotal'))) throw ApiError('QUOTE_CHANGED');
  }
  if (quote['voucherEligible'] != true) throw ApiError('QUOTE_CHANGED', detail: 'the voucher saving no longer beats the voucher fee');
  if (voucher['kind'] == 'bound' && voucher['_creditOrigin'] != true) {
    final qf = voucher.obj('quoteFils');
    final t = quote.obj('totals');
    if (input.list('extras').isEmpty &&
        (voucher['eventDate'] != eventDate || qf['standard'] != filsOf(t.obj('standardTotal')) || qf['voucher'] != filsOf(t.obj('voucherTotal')))) {
      throw ApiError('QUOTE_CHANGED', params: {'voucherEventDate': voucher['eventDate']});
    }
  }

  final lead = diffDays(today, eventDate);
  final defaultSla = isProvider
      ? cfg.integer('defaultReplyHours')
      : (app.db.peek('Venue', targetId)!.obj('policies').intOrNull('responseSlaHours') ?? cfg.integer('defaultReplyHours'));
  final slaHours = !isProvider && lead <= cfg.integer('urgentLeadDays') ? cfg.integer('urgentReplyHours') : defaultSla;
  final ref = _nextRef(app, [who.userId, targetId, eventDate]);
  final id = 'bk-$ref';
  final contact = input.obj('contact');
  final priorCount = app.db.raw('Booking').where((b) => b['clientId'] == who.userId).length;
  final booking = <String, dynamic>{
    'id': id,
    'ref': ref,
    'targetType': isProvider ? 'provider' : 'venue',
    'venueId': isProvider ? null : targetId,
    'providerId': isProvider ? targetId : null,
    'clientId': who.userId,
    'clientName': user['name'],
    'weddingId': app.db.peek('WeddingProfile', who.userId)?['id'],
    'status': 'pending',
    'createdAt': app.now,
    'eventDate': eventDate,
    'sections': sections,
    'service': service,
    'lines': quote['lines'],
    'totals': quote['totals'],
    'voucherId': voucher['id'],
    'respondBy': addHours(app.now, slaHours),
    'approvedAt': null,
    'confirmBy': null,
    'confirmedAt': null,
    'redeemedAt': null,
    'redeemedBy': null,
    'completedAt': null,
    'slaHours': slaHours,
    'contact': {'name': contact['name'], 'phone': contact['phone'], 'shared': contact['shared'], 'bookingFor': contact['bookingFor']},
    'specialRequests': input['specialRequests'],
    'firstBooking': priorCount == 0,
    'verifiedPhone': true,
    'thread': <Json>[],
    'events': [_event(app, to: 'pending', actor: 'client', actorName: user.strOrNull('name'))],
    'cancelledBy': null,
    'reasonCode': null,
    'rejectReason': null,
    'expiredReason': null,
    'proposal': null,
    'overlays': <String, dynamic>{},
    'approvedDiscount': null,
    'version': 2,
    'allowedActions': <String>[],
  };
  bindVoucher(
    app,
    voucher,
    bookingId: id,
    targetType: isProvider ? 'provider' : 'venue',
    targetId: targetId,
    hallId: hallIdForVoucher,
    packageId: packageIdForVoucher,
    eventDate: eventDate,
    guests: guestsForVoucher,
    quote: quote,
  );
  _save(app, booking);
  if (!isProvider) _setClaims(app, booking, 'requested');
  _ensureVenueConversation(app, booking);

  final name = app.targetName(venueId: booking['venueId'] as String?, providerId: booking['providerId'] as String?);
  notify(
    app,
    userId: who.userId,
    kind: 'request_sent',
    audience: 'client',
    vars: {'venue': name, 'date': dateLT(eventDate), 'replyBy': instantLT(booking.str('respondBy'))},
    params: {'venue': targetId, 'eventDate': eventDate, 'replyBy': booking['respondBy']},
    bookingId: id,
    venueId: booking['venueId'] as String?,
    voucherId: voucher.str('id'),
  );
  for (final uid in app.notifyTargets(venueId: booking['venueId'] as String?, providerId: booking['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'new_request',
      audience: 'hotel',
      vars: {'client': user.str('name'), 'date': dateLT(eventDate), 'guests': (guestsForVoucher ?? service?['quantity'] ?? 1) as Object},
      params: {'client': user['name'], 'eventDate': eventDate},
      bookingId: id,
      venueId: booking['venueId'] as String?,
      voucherId: voucher.str('id'),
    );
  }
  app.logEvent('request_R01', {'bookingId': id, 'ref': ref});
  return app.db.require('Booking', id);
}

void _ensureVenueConversation(MockApp app, Json b) {
  final venueId = b.strOrNull('venueId');
  final providerId = b.strOrNull('providerId');
  final existing = app.db.firstWhere(
    'Conversation',
    (c) => c['clientId'] == b['clientId'] && (venueId != null ? c['venueId'] == venueId && c['kind'] == 'venue' : c['vendorId'] == providerId),
  );
  if (existing != null) {
    if (existing['bookingId'] != b['id']) {
      existing['bookingId'] = b['id'];
      app.db.put('Conversation', existing);
    }
    return;
  }
  final name = app.targetName(venueId: venueId, providerId: providerId);
  final convId = 'conv-${b['ref']}';
  app.db.put('Conversation', {
    'id': convId,
    'kind': venueId != null ? 'venue' : 'vendor',
    'title': name,
    'subtitle': {'en': 'Request · ${dateText(b.str('eventDate'), 'en')}', 'ar': 'طلب · ${dateText(b.str('eventDate'), 'ar')}'},
    'monogram': name.strOrNull('ar')?.runes.isNotEmpty == true ? String.fromCharCode(name.str('ar').runes.first) : '?',
    'clientId': b['clientId'],
    'clientName': b['clientName'],
    'venueId': venueId,
    'bookingId': b['id'],
    'plannerId': null,
    'vendorId': providerId,
    'pinned': false,
    'unread': {'client': 0, 'hotel': 0},
    'handledBy': null,
    'lastMessageAt': app.now,
    'awaitingReplySince': null,
    'usuallyRepliesHours': 2,
  });
}

// ---------------------------------------------------------------- venue-side transitions

/// R03: approve. [lowerVoucherTotal] (fils) may only be lower than the voucher total (ADR 0033 D3).
Json approveRequest(MockApp app, String id, {required String actorName, int? lowerVoucherTotal}) {
  final b = requireBooking(app, id);
  if (b['status'] != 'pending') throw conflict(b);
  if (b.objOrNull('proposal')?['status'] == 'proposed') throw conflict(b);
  if (_slotTaken(app, b)) {
    final s = b.list('sections').first;
    throw ApiError(
      'SLOT_UNAVAILABLE',
      params: {'eventDate': b['eventDate']},
      alternatives: _alternatives(app, s.str('hallId'), b.str('venueId'), b.str('eventDate')),
    );
  }
  Json? discount;
  if (lowerVoucherTotal != null) {
    final total = filsOf(b.obj('totals').obj('voucherTotal'));
    if (lowerVoucherTotal < 0 || lowerVoucherTotal > total) throw ApiError.validation('/lowerVoucherTotal', 'cannot_exceed_voucher_total');
    if (lowerVoucherTotal < total) discount = fils(total - lowerVoucherTotal);
  }
  _go(
    app,
    b,
    'R03',
    actorName: actorName,
    mutate: (b) {
      b['_respondBy'] = b['respondBy'];
      b['respondBy'] = null;
      b['approvedAt'] = app.now;
      b['confirmBy'] = confirmByFor(app.now, confirmWindowHours: app.platformConfig.integer('confirmWindowHours'));
      b['undoUntil'] = _plusSeconds(app.now, app.platformConfig.integer('approvalUndoSeconds'));
      b['_undoClosed'] = false;
      if (discount != null) {
        b['approvedDiscount'] = discount;
        _applyDiscount(b, discount);
      }
    },
  );
  _setClaims(app, b, 'hold', holdUntil: b.str('confirmBy'));
  app.scheduler.after(Duration(seconds: app.platformConfig.integer('approvalUndoSeconds')), () => closeUndoWindowIfDue(app, b.str('id'), force: true));
  return app.db.require('Booking', b.str('id'));
}

String _plusSeconds(String instant, int seconds) => toKuwaitInstant(instantMs(instant) + seconds * 1000);

void _applyDiscount(Json b, Json discount) {
  final totals = b.obj('totals');
  final sub = filsOf(totals.obj('voucherSubtotal'));
  final d = filsOf(discount) > sub ? sub : filsOf(discount);
  totals['venueDiscount'] = fils(d);
  // the voucher total falls by the discount (service charge follows the discounted subtotal, like the engine)
  final bps = filsOf(totals.obj('voucherServiceCharge')) == 0 ? 0 : jsRound(filsOf(totals.obj('voucherServiceCharge')) * 10000 / (sub == 0 ? 1 : sub));
  final sc = bps > 0 ? shareMoney(fils(sub - d), bps) : zero();
  totals['voucherServiceCharge'] = sc;
  totals['voucherTotal'] = addMoney([fils(sub - d), sc]);
  final savings = filsOf(totals.obj('standardTotal')) - filsOf(totals.obj('voucherTotal'));
  totals['savings'] = fils(savings > 0 ? savings : 0);
  totals['netSavings'] = (savings > 0 ? savings : 0) - filsOf(totals.obj('voucherFee'));
  final lines = b.list('lines');
  lines.removeWhere((l) => l['kind'] == 'venue_discount');
  if (d > 0) {
    lines.add({
      'kind': 'venue_discount',
      'section': null,
      'name': {'en': 'Venue discount', 'ar': 'خصم من القاعة'},
      'qty': 1,
      'unit': null,
      'amount': negMoney(fils(d)),
      'standardUnit': null,
      'standardAmount': zero(),
    });
  }
  b['lines'] = lines;
}

/// The 8 s undo window of an approval: when it closes the client hears about the approval (ADR 0008: "sent only when the window closes").
void closeUndoWindowIfDue(MockApp app, String id, {bool force = false}) {
  final b = app.db.get('Booking', id);
  if (b == null || b['status'] != 'approved' || b['_undoClosed'] == true) return;
  final until = b.strOrNull('undoUntil');
  if (!force && (until == null || instantMs(app.now) < instantMs(until))) return;
  b['_undoClosed'] = true;
  b.remove('undoUntil');
  app.db.put('Booking', b);
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'request_approved',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
      'confirmBy': instantLT(b.str('confirmBy')),
    },
    params: {'confirmBy': b['confirmBy']},
    bookingId: id,
    venueId: b['venueId'] as String?,
    voucherId: b.str('voucherId'),
  );
  // a reminder one hour before the window ends is raised by the sweep when the clock passes it
}

/// R03u: undo an approval inside the 8 s window.
Json undoApprove(MockApp app, String id, {required String actorName}) {
  final b = requireBooking(app, id);
  if (b['status'] != 'approved') throw conflict(b);
  final until = b.strOrNull('undoUntil');
  if (b['_undoClosed'] == true || until == null || instantMs(app.now) > instantMs(until)) throw ApiError('UNDO_WINDOW_ENDED');
  _go(
    app,
    b,
    'R03u',
    actorName: actorName,
    mutate: (b) {
      b['respondBy'] = b['_respondBy'];
      b.remove('_respondBy');
      b['approvedAt'] = null;
      b['confirmBy'] = null;
      b.remove('undoUntil');
      b['approvedDiscount'] = null;
    },
  );
  _setClaims(app, b, 'requested');
  return app.db.require('Booking', id);
}

/// R04: decline.
Json declineRequest(MockApp app, String id, {required String actorName, required String reason, String? note}) {
  final b = requireBooking(app, id);
  _go(
    app,
    b,
    'R04',
    actorName: actorName,
    note: note,
    mutate: (b) {
      b['rejectReason'] = reason;
      b['respondBy'] = b['respondBy'];
    },
  );
  _dropClaims(app, id);
  final v = releaseVoucher(app, b.str('voucherId'), 'declined');
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'request_declined',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b['venueId'] as String?,
    voucherId: v.str('id'),
  );
  return app.db.require('Booking', id);
}

/// Counter-offer: the venue proposes 1-3 other dates at the same voucher price (valid 48 h).
Json proposeDates(MockApp app, String id, List<Json> options, {required String actorName}) {
  final b = requireBooking(app, id);
  if (b['status'] != 'pending' || b.objOrNull('proposal')?['status'] == 'proposed') throw conflict(b);
  final engine = app.engine();
  final venueId = b.str('venueId');
  final out = <Json>[];
  final current = filsOf(b.obj('totals').obj('voucherTotal'));
  for (final o in options) {
    final hall =
        app.db.peek('Venue', venueId)!.list('halls').cast<Json?>().firstWhere((h) => h!['id'] == o['hallId'], orElse: () => null) ??
        (throw ApiError.validation('/options/hallId', 'unknown_hall'));
    final date = o.str('eventDate');
    final day = engine.availabilityFor(venueId, hall.str('id'), monthOf(date)).cast<Json?>().firstWhere((d) => d!['date'] == date, orElse: () => null);
    if (day == null || !isRequestable(day)) {
      throw ApiError('SLOT_UNAVAILABLE', params: {'eventDate': date}, alternatives: _alternatives(app, hall.str('id'), venueId, date));
    }
    final sec = b.list('sections').first;
    Json? q;
    try {
      q = engine.quoteFor(
        venueId: venueId,
        eventDate: date,
        sections: [
          {'hallId': hall['id'], 'audience': sec['audience'], 'guests': sec['guests'], 'packageId': sec['packageId']},
        ],
      );
    } on StateError {
      q = null;
    }
    final quoted = q != null ? filsOf(q.obj('totals').obj('voucherTotal')) : current;
    out.add({'eventDate': date, 'hallId': hall['id'], 'sessionId': o['sessionId'], 'quotedTotal': fils(quoted), 'delta': fils(quoted - current)});
  }
  b['proposal'] = {
    'id': 'prop-${b['ref']}',
    'kind': 'counter_offer',
    'status': 'proposed',
    'proposedAt': app.now,
    'expiresAt': addHours(app.now, app.platformConfig.integer('counterOfferValidityHours')),
    'originalPriceHeld': true,
    'options': out,
  };
  (b['events'] as List).add(_event(app, kind: 'note', actor: 'venue', actorName: actorName, note: 'Proposed ${out.length} other date(s)'));
  _save(app, b);
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'message',
    audience: 'client',
    vars: {'sender': app.targetName(venueId: venueId)},
    params: {'proposal': b['proposal']['id']},
    bookingId: id,
    venueId: venueId,
  );
  return app.db.require('Booking', id);
}

void expireProposal(MockApp app, String id) {
  final b = app.db.get('Booking', id);
  if (b == null) return;
  final p = b.objOrNull('proposal');
  if (p == null || p['status'] != 'proposed') return;
  p['status'] = 'expired';
  b['proposal'] = p;
  (b['events'] as List).add(_event(app, kind: 'note', actor: 'system', note: 'The counter-offer expired'));
  _save(app, b);
}

/// R10b: the venue revokes an approval (Admin or Manager, reason required, reliability strike).
Json revokeApproval(MockApp app, String id, {required String actorName, required String reason, String? note}) {
  final b = requireBooking(app, id);
  _go(
    app,
    b,
    'R10b',
    actorName: actorName,
    note: note,
    mutate: (b) {
      b['cancelledBy'] = 'venue';
      b['reasonCode'] = reason;
      (b['overlays'] as Map)['reliabilityStrike'] = true;
    },
  );
  _dropClaims(app, id);
  _strike(app, b.str('venueId'));
  final v = releaseVoucher(app, b.str('voucherId'), 'approval_revoked');
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'booking_cancelled',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b.str('venueId')),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b.str('venueId'),
    voucherId: v.str('id'),
  );
  return app.db.require('Booking', id);
}

/// R13b: the venue cancels a confirmed request.
Json cancelConfirmedByVenue(MockApp app, String id, {required String actorName, required String reason, String? note}) {
  final b = requireBooking(app, id);
  _go(
    app,
    b,
    'R13b',
    actorName: actorName,
    note: note,
    mutate: (b) {
      b['cancelledBy'] = 'venue';
      b['reasonCode'] = reason;
      (b['overlays'] as Map)['reliabilityStrike'] = true;
    },
  );
  _dropClaims(app, id);
  _strike(app, b.str('venueId'));
  final v = releaseVoucher(app, b.str('voucherId'), 'venue_cancelled');
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'booking_cancelled',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b.str('venueId')),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b.str('venueId'),
    voucherId: v.str('id'),
  );
  return app.db.require('Booking', id);
}

void _strike(MockApp app, String? venueId) {
  if (venueId == null) return;
  final s = app.db.get('VenueSettings', venueId);
  if (s == null) return;
  s['reliabilityStrikes'] = (s.intOrNull('reliabilityStrikes') ?? 0) + 1;
  app.db.put('VenueSettings', s);
}

/// R11: redeem by code (the partner checks the voucher against the request).
Json redeemBooking(MockApp app, String id, {required String actorName}) {
  final b = requireBooking(app, id);
  _go(
    app,
    b,
    'R11',
    actorName: actorName,
    note: 'Voucher redeemed',
    mutate: (b) {
      b['redeemedAt'] = app.now;
      b['redeemedBy'] = actorName;
    },
  );
  useVoucher(app, b.str('voucherId'), 'redeemed', by: actorName);
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'voucher_redeemed',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'code': app.db.peek('Voucher', b.str('voucherId'))!.str('code'),
    },
    params: {'staff': actorName},
    bookingId: id,
    venueId: b['venueId'] as String?,
    voucherId: b.str('voucherId'),
  );
  for (final uid in app.notifyTargets(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'voucher_redeemed_by_you',
      audience: 'hotel',
      vars: {'client': b.str('clientName'), 'date': dateLT(b.str('eventDate')), 'staff': actorName},
      params: {'client': b['clientName'], 'staff': actorName},
      bookingId: id,
      venueId: b['venueId'] as String?,
      voucherId: b.str('voucherId'),
    );
  }
  return app.db.require('Booking', id);
}

// ---------------------------------------------------------------- client-side transitions

/// R05: the client accepts one date of the counter-offer; the 24 h confirm window starts.
Json acceptProposal(MockApp app, String id, int optionIndex) {
  final b = requireBooking(app, id);
  final p = b.objOrNull('proposal');
  if (b['status'] != 'pending' || p == null || p['status'] != 'proposed') throw conflict(b);
  if (instantMs(app.now) >= instantMs(p.str('expiresAt'))) {
    expireProposal(app, id);
    throw conflict(app.db.require('Booking', id));
  }
  final options = p.list('options');
  if (optionIndex < 0 || optionIndex >= options.length) throw ApiError.validation('/optionIndex', 'out_of_range');
  final o = options[optionIndex];
  final venue = app.db.peek('Venue', b.str('venueId'))!;
  final hall = venue.list('halls').firstWhere((h) => h['id'] == o['hallId']);
  final session = hall.list('sessions').cast<Json?>().firstWhere((s) => s!['id'] == o['sessionId'], orElse: () => null) ?? hall.list('sessions').first;
  final sections = b.list('sections');
  sections[0]
    ..['hallId'] = o['hallId']
    ..['sessionId'] = session['id']
    ..['start'] = session['start']
    ..['end'] = session['end'];
  if (_slotTaken(app, b, date: o.str('eventDate'), sections: sections)) {
    throw ApiError(
      'SLOT_UNAVAILABLE',
      params: {'eventDate': o['eventDate']},
      alternatives: _alternatives(app, o.str('hallId'), b.str('venueId'), o.str('eventDate')),
    );
  }
  _go(
    app,
    b,
    'R05',
    actorName: b.str('clientName'),
    mutate: (b) {
      p['status'] = 'accepted';
      b['proposal'] = p;
      b['sections'] = sections;
      b['eventDate'] = o['eventDate'];
      b['respondBy'] = null;
      b['approvedAt'] = app.now;
      b['confirmBy'] = confirmByFor(app.now, confirmWindowHours: app.platformConfig.integer('confirmWindowHours'));
    },
  );
  final v = app.db.require('Voucher', b.str('voucherId'));
  v['eventDate'] = o['eventDate'];
  v['hallId'] = o['hallId'];
  app.db.put('Voucher', v);
  _setClaims(app, b, 'hold', holdUntil: b.str('confirmBy'));
  for (final uid in app.notifyTargets(venueId: b.str('venueId'))) {
    notify(
      app,
      userId: uid,
      kind: 'client_confirmed',
      audience: 'hotel',
      vars: {'client': b.str('clientName'), 'date': dateLT(o.str('eventDate'))},
      params: {'client': b['clientName']},
      bookingId: id,
      venueId: b.str('venueId'),
    );
  }
  return app.db.require('Booking', id);
}

Json declineProposal(MockApp app, String id) {
  final b = requireBooking(app, id);
  final p = b.objOrNull('proposal');
  if (b['status'] != 'pending' || p == null || p['status'] != 'proposed') throw conflict(b);
  p['status'] = 'declined';
  b['proposal'] = p;
  (b['events'] as List).add(_event(app, kind: 'note', actor: 'client', actorName: b.str('clientName'), note: 'Declined the counter-offer'));
  _save(app, b);
  return app.db.require('Booking', id);
}

/// R07: withdraw a pending request (free; the voucher returns, not credit-eligible).
Json withdrawRequest(MockApp app, String id) {
  final b = requireBooking(app, id);
  _go(
    app,
    b,
    'R07',
    actorName: b.str('clientName'),
    mutate: (b) {
      b['cancelledBy'] = 'client';
      b['reasonCode'] = 'withdrawn';
      b['respondBy'] = null;
    },
  );
  _dropClaims(app, id);
  final v = releaseVoucher(app, b.str('voucherId'), 'withdrawn');
  for (final uid in app.notifyTargets(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'booking_cancelled',
      audience: 'hotel',
      vars: {
        'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
        'date': dateLT(b.str('eventDate')),
      },
      params: {'client': b['clientName'], 'eventDate': b['eventDate']},
      bookingId: id,
      venueId: b['venueId'] as String?,
      voucherId: v.str('id'),
    );
  }
  return app.db.require('Booking', id);
}

/// R08: confirm inside the 24 h window.
Json confirmRequest(MockApp app, String id) {
  final b = requireBooking(app, id);
  if (b['status'] == 'approved' && instantMs(app.now) >= instantMs(b.str('confirmBy'))) throw ApiError('CONFIRM_WINDOW_ENDED');
  if (b['status'] == 'approved' && !_holdStillOurs(app, b)) throw ApiError('SLOT_UNAVAILABLE', params: {'eventDate': b['eventDate']});
  _go(
    app,
    b,
    'R08',
    actorName: b.str('clientName'),
    mutate: (b) {
      b['confirmedAt'] = app.now;
      b.remove('undoUntil');
    },
  );
  _setClaims(app, b, 'booking');
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'request_confirmed',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b['venueId'] as String?,
    voucherId: b.str('voucherId'),
  );
  for (final uid in app.notifyTargets(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'client_confirmed',
      audience: 'hotel',
      vars: {'client': b.str('clientName'), 'date': dateLT(b.str('eventDate'))},
      params: {'client': b['clientName'], 'eventDate': b['eventDate']},
      bookingId: id,
      venueId: b['venueId'] as String?,
      voucherId: b.str('voucherId'),
    );
  }
  return app.db.require('Booking', id);
}

bool _holdStillOurs(MockApp app, Json b) {
  if (b['venueId'] == null) return true;
  return b
      .list('sections')
      .every((s) => app.db.raw('CalendarClaim').any((c) => c['bookingId'] == b['id'] && c['hallId'] == s['hallId'] && c['kind'] == 'hold'));
}

/// R10a (approved) and R13a (confirmed): the client cancels. After confirmation the voucher is consumed and no money comes back.
Json cancelByClient(MockApp app, String id, {String? reason}) {
  final b = requireBooking(app, id);
  final status = b.str('status');
  if (status != 'approved' && status != 'confirmed') throw conflict(b);
  final code = reason ?? 'plans_changed';
  _go(
    app,
    b,
    status == 'approved' ? 'R10a' : 'R13a',
    actorName: b.str('clientName'),
    mutate: (b) {
      b['cancelledBy'] = 'client';
      b['reasonCode'] = code;
      b['confirmBy'] = status == 'approved' ? null : b['confirmBy'];
    },
  );
  _dropClaims(app, id);
  if (status == 'approved') {
    releaseVoucher(app, b.str('voucherId'), 'withdrawn');
  } else {
    useVoucher(app, b.str('voucherId'), 'cancelled_after_confirm');
  }
  for (final uid in app.notifyTargets(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'booking_cancelled',
      audience: 'hotel',
      vars: {
        'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
        'date': dateLT(b.str('eventDate')),
      },
      params: {'client': b['clientName'], 'eventDate': b['eventDate']},
      bookingId: id,
      venueId: b['venueId'] as String?,
      voucherId: b.str('voucherId'),
    );
  }
  return app.db.require('Booking', id);
}

// ---------------------------------------------------------------- system transitions

/// R06: the venue did not answer before `respondBy`.
void expirePending(MockApp app, String id) {
  final b = app.db.get('Booking', id);
  if (b == null || b['status'] != 'pending') return;
  _go(
    app,
    b,
    'R06',
    actorName: '',
    mutate: (b) {
      b['expiredReason'] = 'venue_no_response';
    },
  );
  _dropClaims(app, id);
  releaseVoucher(app, b.str('voucherId'), 'venue_no_response');
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'request_expired',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b['venueId'] as String?,
    voucherId: b.str('voucherId'),
  );
}

/// R09: the client did not confirm inside 24 h: the date is released and the voucher is forfeited.
void expireApproval(MockApp app, String id) {
  final b = app.db.get('Booking', id);
  if (b == null || b['status'] != 'approved') return;
  _go(
    app,
    b,
    'R09',
    actorName: '',
    mutate: (b) {
      b['expiredReason'] = 'client_no_confirmation';
      b.remove('undoUntil');
    },
  );
  _dropClaims(app, id);
  forfeitVoucher(app, b.str('voucherId'));
  final venueId = b['venueId'] as String?;
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'voucher_forfeited',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: venueId, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
      'code': app.db.peek('Voucher', b.str('voucherId'))!.str('code'),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: venueId,
    voucherId: b.str('voucherId'),
  );
  for (final uid in app.notifyTargets(venueId: venueId, providerId: b['providerId'] as String?)) {
    notify(
      app,
      userId: uid,
      kind: 'client_lapsed',
      audience: 'hotel',
      vars: {'client': b.str('clientName'), 'date': dateLT(b.str('eventDate'))},
      params: {'client': b['clientName'], 'eventDate': b['eventDate']},
      bookingId: id,
      venueId: venueId,
      voucherId: b.str('voucherId'),
    );
  }
}

/// R12: the event is over (end plus 12 h): confirmed requests complete with the voucher used, redeemed ones just complete.
void completeRequest(MockApp app, String id) {
  final b = app.db.get('Booking', id);
  if (b == null || (b['status'] != 'confirmed' && b['status'] != 'redeemed')) return;
  final wasConfirmed = b['status'] == 'confirmed';
  _go(
    app,
    b,
    wasConfirmed ? 'R12a' : 'R12b',
    actorName: '',
    mutate: (b) {
      b['completedAt'] = app.now;
    },
  );
  if (wasConfirmed) useVoucher(app, b.str('voucherId'), 'completed');
  _dropClaims(app, id);
  notify(
    app,
    userId: b.str('clientId'),
    kind: 'review_prompt',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: b['venueId'] as String?, providerId: b['providerId'] as String?),
      'date': dateLT(b.str('eventDate')),
    },
    params: {'eventDate': b['eventDate']},
    bookingId: id,
    venueId: b['venueId'] as String?,
  );
}
