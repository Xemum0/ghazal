/// Site visits (voucher-model section 11.1): 30-minute arrival slots from the partner's weekly rules, the group chat of client, hotel
/// representative and Ghazal support, and the visit status machine (requested, confirmed, reschedule_proposed, arrived, completed, declined,
/// cancelled, missed).
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../engine/engine.dart';
import 'chat.dart';
import 'format.dart';
import 'notify.dart';
import 'views.dart';

Json requireVisit(MockApp app, String id) => app.db.get('VisitAppointment', id) ?? (throw ApiError.notFound('visit'));

ApiError visitConflict(Json v) => ApiError('VISIT_STATE_CONFLICT', currentStatus: v.str('status'));

/// The venue member who answers visits: reception first, then a manager, then the account owner, then support.
String representativeFor(MockApp app, String venueId) {
  for (final role in ['reception', 'manager', 'admin']) {
    for (final s in app.db.raw('StaffMember')) {
      if (s['venueId'] == venueId && s['role'] == role && s['status'] == 'active') return s.str('userId');
    }
  }
  final targets = app.notifyTargets(venueId: venueId);
  return targets.isNotEmpty ? targets.first : 'user-support';
}

Json _member(MockApp app, String userId, String role, {Json? organisation}) {
  final u = app.db.peek('User', userId);
  return {
    'userId': userId,
    'role': role,
    'name': u?['name'] ?? userId,
    'nameLatin': u?['nameLatin'] ?? u?['name'] ?? userId,
    'monogram': u?['monogram'] ?? '?',
    'chip': {
      'client': {'en': 'Client', 'ar': 'العميل'},
      'hotel_representative': {'en': 'Hotel representative', 'ar': 'ممثل الفندق'},
      'support': {'en': 'Ghazal support', 'ar': 'دعم غزل'},
    }[role],
    'organisation': organisation,
  };
}

Json _slotLT(String slotStart) => {
  'en': '${dateText(kuwaitDateOf(slotStart), 'en')} · ${timeText(kuwaitTimeOf(slotStart), 'en')}',
  'ar': '${dateText(kuwaitDateOf(slotStart), 'ar')} · ${timeText(kuwaitTimeOf(slotStart), 'ar')}',
};

Json _historyEntry(MockApp app, String status, String actor, String? actorName) => {'at': app.now, 'status': status, 'actor': actor, 'actorName': ?actorName};

String _statusWord(String status, String lang) => const {
  'requested': ['requested', 'بانتظار الرد'],
  'confirmed': ['confirmed', 'مؤكدة'],
  'reschedule_proposed': ['new time proposed', 'موعد جديد مقترح'],
  'arrived': ['arrived', 'تم الوصول'],
  'completed': ['completed', 'اكتملت'],
  'declined': ['declined', 'مرفوضة'],
  'cancelled': ['cancelled', 'ملغاة'],
  'missed': ['missed', 'فائتة'],
}[status]![lang == 'ar' ? 1 : 0];

void _syncConversation(MockApp app, Json visit) {
  final conv = app.db.get('Conversation', visit.str('conversationId'));
  if (conv == null) return;
  final slot = visit.str('slotStart');
  final venue = app.targetName(venueId: visit.str('venueId'));
  conv['subtitle'] = {
    'en': '${dateText(kuwaitDateOf(slot), 'en')} · ${timeText(kuwaitTimeOf(slot), 'en')} · ${_statusWord(visit.str('status'), 'en')}',
    'ar': '${dateText(kuwaitDateOf(slot), 'ar')} · ${timeText(kuwaitTimeOf(slot), 'ar')} · ${_statusWord(visit.str('status'), 'ar')}',
  };
  conv['title'] = {'en': 'Site visit · ${venue['en']}', 'ar': 'زيارة · ${venue['ar']}'};
  final cfg = app.platformConfig;
  conv['readOnlyFrom'] = addHours(visit.str('slotEnd'), cfg.integer('visitChatReadonlyHours'));
  conv['archiveOn'] = addDays(kuwaitDateOf(visit.str('slotEnd')), cfg.integer('visitChatArchiveDays'));
  app.db.put('Conversation', conv);
}

void _card(MockApp app, Json visit, String title, Json titleAr) {
  appendMessage(
    app,
    visit.str('conversationId'),
    from: 'system',
    kind: 'visit_card',
    text: {'en': title, 'ar': titleAr['ar']},
    card: {
      'kind': 'visit',
      'title': {'en': title, 'ar': titleAr['ar']},
      'lines': [
        _slotLT(visit.str('slotStart')),
        app.targetName(venueId: visit.str('venueId')),
        {'en': '${visit['visitors']} visitors', 'ar': '${visit['visitors']} زائرين'},
      ],
      'at': visit['slotStart'],
      'refId': visit['id'],
    },
  );
}

void _saveVisit(MockApp app, Json v, String status, String actor, String? actorName) {
  v['status'] = status;
  (v['history'] as List).add(_historyEntry(app, status, actor, actorName));
  app.db.put('VisitAppointment', v);
  _syncConversation(app, v);
  app.logEvent('visit_$status', {'visitId': v['id']});
}

/// Books a visit: the slot must be one of the venue's free arrival windows. Creates the visit, the three-way group thread and the notifications.
Json bookVisit(MockApp app, Json who, Json input) {
  final venueId = input.str('venueId');
  final venue = app.db.peek('Venue', venueId) ?? (throw ApiError.notFound('venue'));
  final settings = app.db.peek('VenueSettings', venueId);
  final visitsOn = settings?.objOrNull('bookingRules')?['visitsEnabled'] != false;
  if (venue['channel'] == 'external_link' || venue.list('visitSlots').isEmpty || !visitsOn) throw ApiError('VISIT_NOT_ALLOWED');
  if (app.db.peek('User', who.str('id'))?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
  final slotStart = input.str('slotStart');
  _requireFreeSlot(app, venueId, slotStart);
  final seq = app.db.next('visit');
  final id = 'visit-${venue['slug'] ?? venueId.toLowerCase()}-$seq';
  final rep = representativeFor(app, venueId);
  final convId = 'conv-$id';
  final slotEnd = slotEndOf(slotStart);
  final clientName = who.str('name');
  final visit = <String, dynamic>{
    'id': id,
    'venueId': venueId,
    'clientId': who['id'],
    'clientName': clientName,
    'requestedAt': app.now,
    'slotStart': slotStart,
    'slotEnd': slotEnd,
    'visitors': input.integer('visitors'),
    'note': input['note'],
    'status': 'requested',
    'representativeId': rep,
    'conversationId': convId,
    'proposedSlotStart': null,
    'arrivedAt': null,
    'closedAt': null,
    'history': [_historyEntry(app, 'requested', 'client', clientName)],
  };
  app.db.put('VisitAppointment', visit);
  final venueName = venue.obj('name');
  app.db.put('Conversation', {
    'id': convId,
    'kind': 'visit_group',
    'title': {'en': 'Site visit · ${venueName['en']}', 'ar': 'زيارة · ${venueName['ar']}'},
    'subtitle': {'en': '', 'ar': ''},
    'monogram': 'ز',
    'clientId': who['id'],
    'clientName': clientName,
    'venueId': venueId,
    'bookingId': null,
    'plannerId': null,
    'vendorId': null,
    'pinned': false,
    'unread': {'client': 0, 'hotel': 1},
    'handledBy': app.db.peek('User', rep)?['nameLatin'],
    'lastMessageAt': app.now,
    'awaitingReplySince': app.now,
    'usuallyRepliesHours': 2,
    'visitId': id,
    'members': [
      _member(app, who.str('id'), 'client'),
      _member(app, rep, 'hotel_representative', organisation: venueName),
      _member(app, 'user-support-lama', 'support'),
    ],
    'readOnlyFrom': null,
    'archiveOn': null,
  });
  _syncConversation(app, visit);
  appendMessage(
    app,
    convId,
    from: 'system',
    kind: 'system',
    text: {
      'en': 'A group chat opened for your visit on ${dateText(kuwaitDateOf(slotStart), 'en')}: you, ${venueName['en']} and Ghazal support.',
      'ar': 'فُتحت محادثة جماعية لزيارتكم يوم ${dateText(kuwaitDateOf(slotStart), 'ar')}: أنتم و${venueName['ar']} ودعم غزل.',
    },
  );
  if (input['note'] != null && (input['note'] as String).isNotEmpty) {
    appendMessage(app, convId, from: 'client', senderName: clientName, text: {'en': null, 'ar': input['note']}, origin: 'ar');
  }
  notify(
    app,
    userId: who.str('id'),
    kind: 'visit_requested',
    audience: 'client',
    vars: {'venue': venueName, 'slot': _slotLT(slotStart)},
    params: {'venue': venueId, 'visit': id},
    venueId: venueId,
    conversationId: convId,
    visitId: id,
  );
  for (final uid in app.notifyTargets(venueId: venueId)) {
    notify(
      app,
      userId: uid,
      kind: 'visit_request',
      audience: 'hotel',
      vars: {'client': clientName, 'slot': _slotLT(slotStart), 'visitors': input.integer('visitors')},
      params: {'client': clientName, 'visitors': input['visitors']},
      venueId: venueId,
      conversationId: convId,
      visitId: id,
    );
  }
  return app.db.require('VisitAppointment', id);
}

String slotEndOf(String slotStart) => addMinutes(slotStart, 30);

void _requireFreeSlot(MockApp app, String venueId, String slotStart, {String? exceptVisit}) {
  final date = kuwaitDateOf(slotStart);
  final engine = app.engine();
  final slots = engine.visitSlotsFor(venueId, date);
  final slot = slots.cast<Json?>().firstWhere((s) => s!['start'] == slotStart, orElse: () => null);
  if (slot == null) throw ApiError('VISIT_SLOT_TAKEN', params: {'reason': 'not_a_slot'});
  if (slot['available'] != true) {
    // a slot held by the visit being moved counts as free
    final holder = app.db
        .raw('VisitAppointment')
        .any((v) => v['venueId'] == venueId && v['slotStart'] == slotStart && v['id'] != exceptVisit && !['declined', 'cancelled'].contains(v['status']));
    if (holder || instantMs(slotStart) <= instantMs(app.now)) throw ApiError('VISIT_SLOT_TAKEN');
  }
}

/// `VisitThread`: the target, the group conversation, the visit and the messages the caller may read.
Json visitThread(MockApp app, Json visit, {required bool partner}) {
  final conv = app.db.require('Conversation', visit.str('conversationId'));
  return {
    'target': targetSummary(app, venueId: visit.str('venueId')),
    'thread': wire(conv),
    'visit': wire(visit),
    'messages': visibleMessages(app, visit.str('conversationId'), partner: partner),
  };
}

// ---------------------------------------------------------------- partner side

Json confirmVisit(MockApp app, String id, String actorName) {
  final v = requireVisit(app, id);
  if (v['status'] != 'requested') throw visitConflict(v);
  _saveVisit(app, v, 'confirmed', 'hotel_representative', actorName);
  _card(app, v, 'Site visit confirmed', {'ar': 'تم تأكيد زيارة القاعة'});
  notify(
    app,
    userId: v.str('clientId'),
    kind: 'visit_confirmed',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: v.str('venueId')),
      'slot': _slotLT(v.str('slotStart')),
    },
    params: {'visit': id},
    venueId: v.str('venueId'),
    conversationId: v.str('conversationId'),
    visitId: id,
  );
  return v;
}

Json declineVisit(MockApp app, String id, String actorName, String? reason) {
  final v = requireVisit(app, id);
  if (v['status'] != 'requested' && v['status'] != 'reschedule_proposed') throw visitConflict(v);
  v['closedAt'] = app.now;
  _saveVisit(app, v, 'declined', 'hotel_representative', actorName);
  _card(app, v, 'Site visit declined', {'ar': 'تم رفض طلب الزيارة'});
  notify(
    app,
    userId: v.str('clientId'),
    kind: 'visit_message',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: v.str('venueId')),
      'slot': _slotLT(v.str('slotStart')),
    },
    params: {'visit': id},
    venueId: v.str('venueId'),
    conversationId: v.str('conversationId'),
    visitId: id,
  );
  return v;
}

Json proposeVisitSlot(MockApp app, String id, String actorName, String slotStart) {
  final v = requireVisit(app, id);
  if (v['status'] != 'requested' && v['status'] != 'confirmed') throw visitConflict(v);
  _requireFreeSlot(app, v.str('venueId'), slotStart, exceptVisit: id);
  v['proposedSlotStart'] = slotStart;
  _saveVisit(app, v, 'reschedule_proposed', 'hotel_representative', actorName);
  appendMessage(
    app,
    v.str('conversationId'),
    from: 'venue',
    senderName: actorName,
    text: {'en': 'Could we move your visit to ${_slotLT(slotStart)['en']}?', 'ar': 'هل يناسبكم نقل زيارتكم إلى ${_slotLT(slotStart)['ar']}؟'},
  );
  notify(
    app,
    userId: v.str('clientId'),
    kind: 'visit_message',
    audience: 'client',
    vars: {
      'venue': app.targetName(venueId: v.str('venueId')),
      'slot': _slotLT(slotStart),
    },
    params: {'visit': id},
    venueId: v.str('venueId'),
    conversationId: v.str('conversationId'),
    visitId: id,
  );
  return v;
}

Json markVisit(MockApp app, String id, String actorName, {required bool arrived}) {
  final v = requireVisit(app, id);
  if (v['status'] != 'confirmed') throw visitConflict(v);
  if (arrived) v['arrivedAt'] = app.now;
  v['closedAt'] = arrived ? null : app.now;
  _saveVisit(app, v, arrived ? 'arrived' : 'missed', 'hotel_representative', actorName);
  return v;
}

// ---------------------------------------------------------------- client side

Json cancelVisit(MockApp app, String id, String? reason) {
  final v = requireVisit(app, id);
  if (!['requested', 'confirmed', 'reschedule_proposed'].contains(v['status'])) throw visitConflict(v);
  v['closedAt'] = app.now;
  _saveVisit(app, v, 'cancelled', 'client', v.str('clientName'));
  _card(app, v, 'Site visit cancelled', {'ar': 'تم إلغاء الزيارة'});
  for (final uid in app.notifyTargets(venueId: v.str('venueId'))) {
    notify(
      app,
      userId: uid,
      kind: 'visit_request',
      audience: 'hotel',
      vars: {'client': v.str('clientName'), 'slot': _slotLT(v.str('slotStart')), 'visitors': v['visitors'] as Object},
      params: {'cancelled': true},
      venueId: v.str('venueId'),
      conversationId: v.str('conversationId'),
      visitId: id,
    );
  }
  return v;
}

Json rescheduleVisit(MockApp app, String id, String slotStart) {
  final v = requireVisit(app, id);
  if (!['requested', 'confirmed', 'reschedule_proposed'].contains(v['status'])) throw visitConflict(v);
  _requireFreeSlot(app, v.str('venueId'), slotStart, exceptVisit: id);
  v['slotStart'] = slotStart;
  v['slotEnd'] = slotEndOf(slotStart);
  v['proposedSlotStart'] = null;
  _saveVisit(app, v, 'requested', 'client', v.str('clientName'));
  return v;
}

Json answerVisitProposal(MockApp app, String id, bool accept) {
  final v = requireVisit(app, id);
  final proposed = v.strOrNull('proposedSlotStart');
  if (v['status'] != 'reschedule_proposed' || proposed == null) throw visitConflict(v);
  if (accept) {
    _requireFreeSlot(app, v.str('venueId'), proposed, exceptVisit: id);
    v['slotStart'] = proposed;
    v['slotEnd'] = slotEndOf(proposed);
    v['proposedSlotStart'] = null;
    _saveVisit(app, v, 'confirmed', 'client', v.str('clientName'));
    _card(app, v, 'Site visit confirmed', {'ar': 'تم تأكيد زيارة القاعة'});
  } else {
    v['proposedSlotStart'] = null;
    v['closedAt'] = app.now;
    _saveVisit(app, v, 'cancelled', 'client', v.str('clientName'));
  }
  return v;
}

/// Sweep: an arrived visit completes when its slot ends.
void progressVisits(MockApp app) {
  for (final v in app.db.raw('VisitAppointment').toList()) {
    if (v['status'] == 'arrived' && instantMs(app.now) >= instantMs(v.str('slotEnd'))) {
      final c = deepCopy(v);
      c['closedAt'] = app.now;
      _saveVisit(app, c, 'completed', 'system', null);
    }
  }
}
