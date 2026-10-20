/// services: additional services (categories, providers with a live listing, provider quotes, quote requests that open a chat with the vendor).
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/chat.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

bool _hasActiveListing(MockApp app, String providerId) => app.db.raw('Listing').any((l) => l['providerId'] == providerId && l['status'] == 'active');

Map<String, Handler> servicesHandlers(MockApp app) => {
      'listServiceCategories': (r) {
        final cats = app.seed.rows('ServiceCategory');
        final sorted = stableSorted(cats, (a, b) => a.integer('order') - b.integer('order'));
        return {'groups': app.seed.rows('ServiceGroup'), 'primary': sorted.where((c) => c['primary'] == true).toList(), 'secondary': sorted.where((c) => c['primary'] != true).toList()};
      },
      'listServiceProviders': (r) {
        final cat = r.q('categoryId');
        final areas = r.qList('areaIds');
        final govs = r.qList('governorateIds');
        final q = normalizeSearch(r.q('q') ?? '');
        var rows = app.db.raw('ServiceProvider').where((p) {
          if (!_hasActiveListing(app, p.str('id'))) return false;
          if (cat != null && p['categoryId'] != cat && !p.strings('alsoCategoryIds').contains(cat)) return false;
          if (areas.isNotEmpty && !areas.contains(p['areaId'])) return false;
          if (govs.isNotEmpty && !govs.contains(p['governorateId'])) return false;
          if (r.qBool('femaleTeamOnly') == true && p['femaleTeamForLadies'] != true) return false;
          if (q.isNotEmpty) {
            final hay = [p.obj('name')['en'], p.obj('name')['ar'], ...p.list('tags').expand((t) => [t['en'], t['ar']])].map((x) => normalizeSearch((x ?? '').toString()));
            if (!hay.any((t) => t.contains(q))) return false;
          }
          return true;
        }).toList();
        final sort = r.q('sort') ?? 'recommended';
        double score(Json p) => ((p.objOrNull('rating')?['average'] as num?)?.toDouble() ?? 3.8) * 10 + ((p.objOrNull('rating')?['count'] as num?)?.toDouble() ?? 0).clamp(0, 200) / 40;
        rows = stableSorted(rows, (a, b) {
          switch (sort) {
            case 'rating':
              return cmpNum(((b.objOrNull('rating')?['average'] as num?) ?? 0) - ((a.objOrNull('rating')?['average'] as num?) ?? 0));
            case 'price':
              return filsOf(a.obj('from')) - filsOf(b.obj('from'));
            case 'newest':
              return b.str('id').compareTo(a.str('id'));
            default:
              return cmpNum(score(b) - score(a));
          }
        });
        return pageMap(r, rows, wire);
      },
      'getServiceProvider': (r) {
        final p = app.db.get('ServiceProvider', r.p('providerId'));
        if (p == null || (!_hasActiveListing(app, p.str('id')) && r.identity?.isPartner != true)) throw ApiError.notFound('provider');
        return wire(p);
      },
      'quoteProvider': (r) {
        final id = r.p('providerId');
        final p = app.db.peek('ServiceProvider', id) ?? (throw ApiError.notFound('provider'));
        if (!p.list('packages').any((x) => x['id'] == r.q('packageId'))) throw ApiError.validation('/packageId', 'unknown_package');
        final q = app.engine().quoteForProvider(providerId: id, packageId: r.q('packageId')!, qty: r.qInt('qty')!);
        return wireQuote(q, targetType: 'provider', targetId: id);
      },
      'createQuoteRequest': (r) {
        if (app.db.peek('User', r.userId)?['_phoneVerified'] == false) throw ApiError('PHONE_VERIFICATION_REQUIRED');
        final b = r.b;
        final provider = app.db.peek('ServiceProvider', b.str('providerId')) ?? (throw ApiError.notFound('provider'));
        final pkg = provider.list('packages').cast<Json?>().firstWhere((p) => p!['id'] == b['packageId'], orElse: () => null) ?? (throw ApiError.validation('/packageId', 'unknown_package'));
        var conv = app.db.firstWhere('Conversation', (c) => c['clientId'] == r.userId && c['vendorId'] == provider['id']);
        if (conv == null) {
          final id = 'conv-m${app.db.next('conv').toString().padLeft(4, '0')}';
          app.db.put('Conversation', {
            'id': id,
            'kind': 'vendor',
            'title': provider['name'],
            'subtitle': {'en': 'Quote request', 'ar': 'طلب عرض سعر'},
            'monogram': provider['monogram'],
            'clientId': r.userId,
            'clientName': r.identity!.user['name'],
            'venueId': null,
            'bookingId': null,
            'plannerId': null,
            'vendorId': provider['id'],
            'pinned': false,
            'unread': {'client': 0, 'hotel': 0},
            'handledBy': null,
            'lastMessageAt': app.now,
            'awaitingReplySince': null,
            'usuallyRepliesHours': provider['usuallyRepliesHours'],
          });
          conv = app.db.require('Conversation', id);
        }
        final id = 'vqr-m${app.db.next('quoteRequest').toString().padLeft(3, '0')}';
        final req = {
          'id': id,
          'clientId': r.userId,
          'vendorId': provider['id'],
          'vendorPackageId': pkg['id'],
          'eventDate': b['eventDate'],
          'venueId': b['venueId'],
          'guests': b['guests'],
          'note': b['note'] ?? '',
          'requestedAt': app.now,
          'status': 'sent',
          'conversationId': conv.str('id'),
        };
        app.db.put('VendorQuoteRequest', req);
        appendMessage(app, conv.str('id'), from: 'client', senderName: r.identity!.user.str('name'), kind: 'quote_request_card', text: {'en': 'Quote request', 'ar': 'طلب عرض سعر'}, card: {
          'kind': 'quote_request',
          'title': {'en': 'Quote request', 'ar': 'طلب عرض سعر'},
          'lines': [pkg['name']],
          'refId': id,
        });
        scheduleReplies(app, conv.str('id'));
        return req;
      },
      'listQuoteRequests': (r) {
        final rows = app.db.raw('VendorQuoteRequest').where((q) => q['clientId'] == r.userId).toList();
        return pageMap(r, stableSorted(rows, (a, b) => b.str('requestedAt').compareTo(a.str('requestedAt'))), wire);
      },
    };
