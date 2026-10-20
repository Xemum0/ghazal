/// chat: conversations and messages for both apps (REST-complete: ordered by `seq`, unread counters, drafts, attachments). Realtime delivery
/// is outside the contract; the apps poll `listMessages?afterSeq=`.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/chat.dart';
import '../domain/views.dart';
import '../engine/engine.dart';
import 'common.dart';

const _maxBytes = {
  'venue_photo': 25 * 1024 * 1024,
  'listing_photo': 25 * 1024 * 1024,
  'provider_portfolio': 25 * 1024 * 1024,
  'venue_video': 500 * 1024 * 1024,
  'chat_voice': 5 * 1024 * 1024,
  'chat_document': 20 * 1024 * 1024,
  'chat_image': 15 * 1024 * 1024,
};
const _allowedTypes = {
  'venue_photo': ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
  'listing_photo': ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
  'provider_portfolio': ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
  'chat_image': ['image/jpeg', 'image/png', 'image/webp', 'image/heic'],
  'venue_video': ['video/mp4', 'video/quicktime'],
  'chat_voice': ['audio/aac', 'audio/mp4', 'audio/m4a', 'audio/mpeg'],
  'chat_document': ['application/pdf'],
};

/// Creates an upload session (signed URL stand-in) after the size and type checks of the contract.
Json uploadSession(MockApp app, Json input, {String? defaultPurpose}) {
  final purpose = input.strOrNull('purpose') ?? defaultPurpose ?? 'chat_document';
  final size = input.integer('sizeBytes');
  final max = _maxBytes[purpose] ?? 20 * 1024 * 1024;
  if (!(_allowedTypes[purpose] ?? const <String>[]).contains(input.str('contentType'))) throw ApiError('MEDIA_TYPE_UNSUPPORTED', params: {'contentType': input['contentType']});
  if (size > max) throw ApiError('MEDIA_TOO_LARGE', params: {'maxBytes': max});
  final id = 'upl-${app.db.next('upload').toString().padLeft(5, '0')}';
  final expires = app.clock.after(const Duration(minutes: 15));
  app.db.put('Upload', {'id': id, 'purpose': purpose, 'fileName': input['fileName'], 'contentType': input['contentType'], 'sizeBytes': size, 'completed': false, 'createdAt': app.now});
  return {'id': id, 'uploadUrl': '${app.baseUrl}/__mock/uploads/$id', 'method': 'PUT', 'headers': {'Content-Type': input['contentType']}, 'expiresAt': expires, 'maxBytes': max};
}

/// Whether the caller takes part in the conversation and as which side (`client` or `partner`).
String _side(MockApp app, Req r, Json c) {
  if (r.partner != null) {
    final ctx = r.partner!;
    final ok = (ctx.venueId != null && c['venueId'] == ctx.venueId) || (ctx.providerId != null && c['vendorId'] == ctx.providerId);
    if (!ok) throw ApiError.notFound('conversation');
    return 'partner';
  }
  if (c['clientId'] != r.userId) throw ApiError.notFound('conversation');
  return 'client';
}

Json _conv(MockApp app, Req r) {
  final c = app.db.get('Conversation', r.p('conversationId')) ?? (throw ApiError.notFound('conversation'));
  _side(app, r, c);
  return c;
}

Json _text(String? text, String origin) => origin == 'ar' ? {'en': null, 'ar': text} : {'en': text, 'ar': null};

Map<String, Handler> chatHandlers(MockApp app) => {
      'listConversations': (r) {
        final kinds = r.qList('kind');
        final onlyUnread = r.qBool('unread') == true;
        final partner = r.partner;
        final rows = app.db.raw('Conversation').where((c) {
          final mine = partner != null ? (partner.venueId != null ? c['venueId'] == partner.venueId : c['vendorId'] == partner.providerId) : c['clientId'] == r.userId;
          if (!mine) return false;
          if (kinds.isNotEmpty && !kinds.contains(c['kind'])) return false;
          if (onlyUnread && c.obj('unread').integer(partner != null ? 'hotel' : 'client') == 0) return false;
          return true;
        }).toList();
        final sorted = stableSorted(rows, (a, b) => a['pinned'] == b['pinned'] ? b.str('lastMessageAt').compareTo(a.str('lastMessageAt')) : (a['pinned'] == true ? -1 : 1));
        return pageMap(r, sorted, wire);
      },
      'createConversation': (r) {
        if (app.db.peek('User', r.userId)?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
        final b = r.b;
        final kind = b.str('kind');
        final venueId = b.strOrNull('venueId');
        final providerId = b.strOrNull('providerId');
        final plannerId = b.strOrNull('plannerId');
        final existing = app.db.firstWhere('Conversation', (c) => c['clientId'] == r.userId && c['kind'] == kind && c['venueId'] == venueId && c['vendorId'] == providerId && c['plannerId'] == plannerId);
        late final Json conv;
        if (existing != null) {
          conv = existing;
        } else {
          Json title = {'en': 'Ghazal', 'ar': 'غزل'};
          if (venueId != null) title = app.targetName(venueId: venueId);
          if (providerId != null) title = app.targetName(providerId: providerId);
          if (plannerId != null) title = app.db.peek('Planner', plannerId)?.obj('name') ?? app.seed.rows('Planner').cast<Json?>().firstWhere((p) => p!['id'] == plannerId, orElse: () => null)?.obj('name') ?? title;
          final id = 'conv-m${app.db.next('conv').toString().padLeft(4, '0')}';
          app.db.put('Conversation', {
            'id': id,
            'kind': kind,
            'title': title,
            'subtitle': {'en': kind == 'enquiry' ? 'Enquiry' : (kind == 'vendor' ? 'Quote request' : 'Conversation'), 'ar': kind == 'enquiry' ? 'استفسار' : (kind == 'vendor' ? 'طلب عرض سعر' : 'محادثة')},
            'monogram': title.strOrNull('ar')?.isNotEmpty == true ? String.fromCharCode(title.str('ar').runes.first) : '?',
            'clientId': r.userId,
            'clientName': r.identity!.user['name'],
            'venueId': venueId,
            'bookingId': b['bookingId'],
            'plannerId': plannerId,
            'vendorId': providerId,
            'pinned': false,
            'unread': {'client': 0, 'hotel': 0},
            'handledBy': null,
            'lastMessageAt': app.now,
            'awaitingReplySince': null,
            'usuallyRepliesHours': 2,
          });
          conv = app.db.require('Conversation', id);
        }
        final first = b.strOrNull('firstMessage');
        if (first != null && first.isNotEmpty) {
          appendMessage(app, conv.str('id'), from: 'client', senderName: r.identity!.user.str('name'), text: _text(first, 'ar'), origin: 'ar');
          scheduleReplies(app, conv.str('id'));
        }
        return wire(app.db.require('Conversation', conv.str('id')));
      },
      'getConversation': (r) => wire(_conv(app, r)),
      'listMessages': (r) {
        final c = _conv(app, r);
        final partner = r.partner != null;
        var rows = visibleMessages(app, c.str('id'), partner: partner);
        final after = r.qInt('afterSeq');
        if (after != null) rows = rows.where((m) => m.integer('seq') > after).toList();
        return pageMap(r, rows, (m) => m);
      },
      'sendMessage': (r) {
        final c = _conv(app, r);
        final side = _side(app, r, c);
        final ro = c.strOrNull('readOnlyFrom');
        if (ro != null && instantMs(app.now) >= instantMs(ro)) throw ApiError.forbidden('this chat is read-only');
        final b = r.b;
        final cmid = b.str('clientMsgId');
        final prior = app.db.firstWhere('Message', (m) => m['conversationId'] == c['id'] && m['clientMsgId'] == cmid);
        if (prior != null) return wire(prior);
        final kind = b.str('kind');
        final origin = b.strOrNull('origin') ?? r.lang;
        if (kind == 'text' && (b.strOrNull('text') ?? '').trim().isEmpty) throw ApiError.validation('/text', 'required');
        Json? voice, document, image;
        if (kind == 'voice') voice = {'seconds': b.intOrNull('voiceSeconds') ?? 5};
        if (kind == 'document' || kind == 'image') {
          final up = app.db.peek('Upload', b.strOrNull('attachmentId') ?? '') ?? (throw ApiError.validation('/attachmentId', 'unknown_upload'));
          if (kind == 'document') {
            document = {'name': up['fileName'], 'sizeKb': ((up.integer('sizeBytes')) / 1024).ceil(), 'mime': 'application/pdf'};
          } else {
            final venue = c.strOrNull('venueId') != null ? app.db.peek('Venue', c.str('venueId')) : null;
            final file = (venue?.objOrNull('cover') ?? app.seed.rows('Venue').first.obj('cover'))['file'];
            image = {'file': file, 'alt': {'en': up['fileName'], 'ar': up['fileName']}};
          }
        }
        final isClient = side == 'client';
        final from = isClient ? 'client' : (c['kind'] == 'vendor' || r.partner?.providerId != null ? 'vendor' : (c['kind'] == 'support' ? 'support' : 'venue'));
        final msg = appendMessage(app, c.str('id'),
            from: from, senderName: actorName(r), text: kind == 'text' ? _text(b.strOrNull('text'), origin) : null, kind: kind, origin: origin, clientMsgId: cmid, voice: voice, document: document, image: image);
        if (isClient) scheduleReplies(app, c.str('id'));
        // a venue reply clears the "reply drafts" of that conversation
        if (!isClient) {
          for (final m in app.db.raw('Message').where((m) => m['conversationId'] == c['id'] && m['draft'] == true && m['_draftBy'] == r.userId).toList()) {
            app.db.remove('Message', m.str('id'));
          }
        }
        return wire(msg);
      },
      'markConversationRead': (r) {
        final c = _conv(app, r);
        final side = _side(app, r, c);
        final upTo = r.b.integer('upToSeq');
        final unread = c.obj('unread');
        if (side == 'client') {
          unread['client'] = 0;
        } else {
          unread['hotel'] = 0;
        }
        c['unread'] = unread;
        app.db.put('Conversation', c);
        for (final m in app.db.raw('Message').where((m) => m['conversationId'] == c['id'] && m.integer('seq') <= upTo && m['status'] != 'read' && (side == 'client' ? m['from'] != 'client' : m['from'] == 'client')).toList()) {
          app.db.put('Message', {...deepCopy(m), 'status': 'read'});
        }
        return null;
      },
      'setConversationPinned': (r) {
        final c = _conv(app, r);
        c['pinned'] = r.b['pinned'] == true;
        app.db.put('Conversation', c);
        return wire(c);
      },
      'saveReplyDraft': (r) {
        final c = _conv(app, r);
        if (_side(app, r, c) != 'partner') throw ApiError.forbidden('drafts are a partner feature');
        final text = r.b.str('text');
        final existing = app.db.firstWhere('Message', (m) => m['conversationId'] == c['id'] && m['draft'] == true && m['_draftBy'] == r.userId && m['kind'] == 'text');
        if (existing != null) {
          existing['text'] = _text(text, r.lang);
          existing['at'] = app.now;
          app.db.put('Message', existing);
          return wire(existing);
        }
        final m = appendMessage(app, c.str('id'), from: 'venue', senderName: actorName(r), text: _text(text, r.lang), origin: r.lang, draft: true);
        m['_draftBy'] = r.userId;
        app.db.put('Message', m);
        return wire(m);
      },
      'createAttachmentUpload': (r) {
        _conv(app, r);
        return uploadSession(app, r.b);
      },
    };
