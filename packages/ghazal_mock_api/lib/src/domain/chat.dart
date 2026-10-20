/// Conversations and messages (REST-complete chat: ordered by a per-conversation `seq`), the unread counters of both sides, and the scripted
/// replies that make a demo feel alive (the venue, support, the planner or the vendor answer a few seconds after the client writes).
library;

import '../core/app.dart';
import '../db/mock_db.dart';
import '../engine/engine.dart';

List<Json> messagesOf(MockApp app, String conversationId) {
  final out = [for (final m in app.db.raw('Message')) if (m['conversationId'] == conversationId) m];
  return stableSorted(out, (a, b) => a.integer('seq') - b.integer('seq'));
}

int lastSeq(MockApp app, String conversationId) {
  var max = 0;
  for (final m in app.db.raw('Message')) {
    if (m['conversationId'] == conversationId && m.integer('seq') > max) max = m.integer('seq');
  }
  return max;
}

/// Appends a message, advances `lastMessageAt` and the unread counters. [from]: client, venue, planner, vendor, support or system.
Json appendMessage(
  MockApp app,
  String conversationId, {
  required String from,
  String? senderName,
  Json? text,
  String kind = 'text',
  String origin = 'en',
  Json? card,
  Json? voice,
  Json? document,
  Json? image,
  String? clientMsgId,
  bool draft = false,
  String status = 'sent',
}) {
  final conv = app.db.require('Conversation', conversationId);
  final id = 'msg-m${app.db.next('message').toString().padLeft(4, '0')}';
  final msg = <String, dynamic>{
    'id': id,
    'conversationId': conversationId,
    'seq': lastSeq(app, conversationId) + 1,
    'clientMsgId': ?clientMsgId,
    'from': from,
    'senderName': senderName,
    'at': app.now,
    'kind': kind,
    'text': text,
    'origin': origin,
    'voice': ?voice,
    'document': ?document,
    'image': ?image,
    'card': ?card,
    'status': status,
    'draft': draft,
  };
  app.db.put('Message', msg);
  if (!draft) {
    conv['lastMessageAt'] = app.now;
    final unread = conv.obj('unread');
    if (from == 'client') {
      unread['hotel'] = unread.integer('hotel') + 1;
      conv['awaitingReplySince'] ??= app.now;
    } else {
      unread['client'] = unread.integer('client') + 1;
      if (from != 'system') conv['awaitingReplySince'] = null;
    }
    conv['unread'] = unread;
    app.db.put('Conversation', conv);
  }
  return msg;
}

const _venueReplies = [
  {'en': 'Thank you for your message. We are checking and will come back to you shortly.', 'ar': 'شكرًا لتواصلكم. نراجع الأمر وسنرد عليكم قريبًا.'},
  {'en': 'Welcome! Yes, we can help with that. Could you tell us your preferred date and number of guests?', 'ar': 'أهلًا بكم! نعم، يسعدنا مساعدتكم. هل تخبروننا بالتاريخ المفضل وعدد الضيوف؟'},
];
const _supportReplies = [
  {'en': 'Thanks for writing to Ghazal support. We are looking into this and will reply here within a few hours.', 'ar': 'شكرًا لتواصلكم مع دعم غزل. نراجع طلبكم وسنرد هنا خلال ساعات.'},
];
const _visitReplies = [
  {'en': 'Noted, thank you. We will be ready for you at the main entrance.', 'ar': 'تم، شكرًا لكم. سنكون بانتظاركم عند المدخل الرئيسي.'},
];
const _planner = [
  {'en': 'Lovely, I will prepare a few ideas and share them before our call.', 'ar': 'رائع، سأجهّز بعض الأفكار وأشاركها معكم قبل مكالمتنا.'},
];
const _vendor = [
  {'en': 'Thank you for your interest. We will send the details and availability shortly.', 'ar': 'شكرًا لاهتمامكم. سنرسل التفاصيل والتوفر قريبًا.'},
];

/// Schedules the scripted answer to a client message: one reply per kind of conversation (the visit group gets the hotel representative and, on
/// the first message, Ghazal support too).
void scheduleReplies(MockApp app, String conversationId) {
  app.scheduler.after(app.config.botDelay, () => _reply(app, conversationId));
}

void _reply(MockApp app, String conversationId) {
  final conv = app.db.get('Conversation', conversationId);
  if (conv == null) return;
  final n = app.db.raw('Message').where((m) => m['conversationId'] == conversationId && m['from'] != 'client' && m['from'] != 'system').length;
  Json pick(List<Map<String, String>> pool) => {...pool[n % pool.length]};
  switch (conv['kind']) {
    case 'venue':
    case 'enquiry':
      final name = conv.strOrNull('handledBy') ?? _staffName(app, conv.strOrNull('venueId')) ?? 'Reception';
      appendMessage(app, conversationId, from: 'venue', senderName: name, text: pick(_venueReplies), origin: 'en');
    case 'visit_group':
      final members = (conv['members'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
      String nameOf(String role) => members.cast<Map<String, dynamic>?>().firstWhere((m) => m!['role'] == role, orElse: () => null)?['nameLatin'] as String? ?? '';
      appendMessage(app, conversationId, from: 'venue', senderName: nameOf('hotel_representative'), text: pick(_visitReplies), origin: 'en');
      if (n == 0) {
        appendMessage(app, conversationId, from: 'support', senderName: nameOf('support'), text: {'en': 'Ghazal support is here in the chat if anything changes.', 'ar': 'دعم غزل هنا في المحادثة إذا تغيّر أي شيء.'}, origin: 'en');
      }
    case 'support':
      appendMessage(app, conversationId, from: 'support', senderName: 'Lama Al-Khalidi', text: pick(_supportReplies), origin: 'en');
    case 'planner':
      appendMessage(app, conversationId, from: 'planner', senderName: app.db.peek('Planner', conv.strOrNull('plannerId') ?? '')?.obj('name').strOrNull('en') ?? 'Planner', text: pick(_planner), origin: 'en');
    case 'vendor':
      for (final q in app.db.raw('VendorQuoteRequest').where((q) => q['conversationId'] == conversationId).toList()) {
        app.db.put('VendorQuoteRequest', {...deepCopy(q), 'status': 'replied'});
      }
      appendMessage(app, conversationId, from: 'vendor', senderName: app.targetName(providerId: conv.strOrNull('vendorId')).strOrNull('en'), text: pick(_vendor), origin: 'en');
  }
  app.logEvent('chat_reply', {'conversationId': conversationId});
}

String? _staffName(MockApp app, String? venueId) {
  if (venueId == null) return null;
  for (final s in app.db.raw('StaffMember')) {
    if (s['venueId'] == venueId && s['role'] == 'manager') return s.strOrNull('nameLatin');
  }
  return null;
}

/// The conversation as the caller sees it: unread counts stay, the draft of a reply is not part of it.
Json viewConversation(Json c) => wire(c);

/// The messages one side may read: the hotel sees its drafts, the client never does.
List<Json> visibleMessages(MockApp app, String conversationId, {required bool partner}) =>
    [for (final m in messagesOf(app, conversationId)) if (partner || m['draft'] != true) wire(m)];

/// The support conversation of a client (created on first use), or of a partner context when [venueId] is given.
Json ensureSupportConversation(MockApp app, {String? clientId, String? venueId}) {
  final existing = app.db.firstWhere('Conversation', (c) => c['kind'] == 'support' && (venueId != null ? c['venueId'] == venueId : c['clientId'] == clientId && c['venueId'] == null));
  if (existing != null) return existing;
  final id = venueId != null ? 'conv-support-$venueId' : 'conv-support-$clientId';
  final client = clientId == null ? null : app.db.peek('User', clientId);
  final doc = <String, dynamic>{
    'id': id,
    'kind': 'support',
    'title': {'en': 'Ghazal Support', 'ar': 'دعم غزل'},
    'subtitle': {'en': venueId != null ? 'Help for your account' : 'Help with your booking', 'ar': venueId != null ? 'مساعدة بخصوص حسابكم' : 'مساعدة بخصوص حجزكم'},
    'monogram': 'غ',
    'clientId': venueId != null ? null : clientId,
    'clientName': venueId != null ? '' : (client?['name'] ?? ''),
    'venueId': venueId,
    'bookingId': null,
    'plannerId': null,
    'vendorId': null,
    'pinned': false,
    'unread': {'client': 0, 'hotel': 0},
    'handledBy': null,
    'lastMessageAt': app.now,
    'awaitingReplySince': null,
    'usuallyRepliesHours': null,
  };
  app.db.put('Conversation', doc);
  appendMessage(app, id, from: 'support', senderName: 'Lama Al-Khalidi', text: {'en': 'Hello! You are chatting with Ghazal support. How can we help?', 'ar': 'أهلًا! أنتم تتحدثون مع دعم غزل. كيف نساعدكم؟'}, origin: 'ar');
  return app.db.require('Conversation', id);
}
