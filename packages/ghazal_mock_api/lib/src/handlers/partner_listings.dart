/// partner-listings: provider listings and their review states (draft, payment_pending, pending_review, approved, rejected, active, expired,
/// paused), plans and billing (rates are undecided: nothing can be paid), media, and the provider's own packages.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/notify.dart';
import '../domain/vouchers.dart' show newListingPaymentSession;
import '../engine/engine.dart';
import 'chat.dart' show uploadSession;
import 'partner_common.dart';

Json _decision(MockApp app, Json listing, String? from, String to, String actor, {String? actorName, List<String>? codes, String? note}) => {
      'id': 'rev-m${app.db.next('decision').toString().padLeft(4, '0')}',
      'listingId': listing['id'],
      'at': app.now,
      'from': from,
      'to': to,
      'actor': actor,
      'actorName': ?actorName,
      'codes': ?codes,
      if (note != null) 'note': {'en': note, 'ar': note},
    };

/// Moves a listing to [to], recording the decision in its history.
Json transitionListing(MockApp app, Json l, String to, String actor, {String? actorName, List<String>? codes, String? note}) {
  final from = l.str('status');
  l['status'] = to;
  (l['history'] as List).add(_decision(app, l, from, to, actor, actorName: actorName, codes: codes, note: note));
  return l;
}

Json _own(MockApp app, Req r) {
  final l = app.db.get('Listing', r.p('listingId'));
  if (l == null || l['partnerAccountId'] != r.ctx.accountId) throw ApiError.notFound('listing');
  return l;
}

Json _listingView(Json l) => wire(l);

Json _provider(MockApp app, Req r) => app.db.get('ServiceProvider', requireProviderId(r)) ?? (throw ApiError.notFound('provider'));

Json _packageFrom(Json input, String id) => {
      'id': id,
      'name': input['name'],
      'price': input['price'],
      'voucherPrice': input['voucherPrice'],
      'unit': input['unit'],
      'priceStructure': input['priceStructure'],
      'minQuantity': input['minQuantity'],
      'includes': input['includes'] ?? <Json>[],
    };

void _refreshFrom(Json provider) {
  final pk = provider.list('packages');
  if (pk.isEmpty) return;
  final cheapest = pk.reduce((a, b) => filsOf(a.obj('price')) <= filsOf(b.obj('price')) ? a : b);
  provider['from'] = cheapest['price'];
  provider['fromVoucher'] = cheapest['voucherPrice'];
}

void _checkPackage(Json input) {
  final v = input.objOrNull('voucherPrice');
  if (v != null && filsOf(v) > filsOf(input.obj('price'))) throw ApiError.validation('/voucherPrice', 'voucher_price_above_standard');
}

Map<String, Handler> partnerListingsHandlers(MockApp app) => {
      'listListings': (r) {
        final rows = app.db.raw('Listing').where((l) => l['partnerAccountId'] == r.ctx.accountId).toList();
        return {'listings': rows.map(_listingView).toList()};
      },
      'createListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final provider = _provider(app, r);
        final account = partnerAccount(app, r);
        final id = 'lst-m${app.db.next('listing').toString().padLeft(3, '0')}';
        final l = <String, dynamic>{
          'id': id,
          'providerId': provider['id'],
          'partnerAccountId': account['id'],
          'categoryId': r.body?['categoryId'] ?? provider['categoryId'],
          'title': r.body?['title'] ?? provider['name'],
          'description': r.body?['description'] ?? provider['about'],
          'cover': provider.list('portfolio').isEmpty ? null : provider.list('portfolio').first,
          'packageIds': r.body?['packageIds'] ?? provider.list('packages').map((p) => p['id']).toList(),
          'status': 'draft',
          'planCycle': null,
          'billing': {'status': account['feeExempt'] == true ? 'exempt' : 'rates_pending', 'amountFils': null, 'paidAt': null},
          'submittedAt': null,
          'decidedAt': null,
          'startsOn': null,
          'endsOn': null,
          'rejection': null,
          'feeRefund': null,
          'sponsored': false,
          'history': <Json>[],
        };
        (l['history'] as List).add(_decision(app, l, null, 'draft', 'provider'));
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'getListing': (r) {
        final l = _own(app, r);
        setEtag(app, r, 'listing:${l['id']}');
        return _listingView(l);
      },
      'updateListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (!{'draft', 'rejected'}.contains(l['status'])) throw ApiError('LISTING_NOT_EDITABLE', currentStatus: l.str('status'));
        final key = 'listing:${l['id']}';
        checkDocMatch(app, r, key);
        for (final k in ['categoryId', 'title', 'description', 'packageIds']) {
          if (r.b.containsKey(k)) l[k] = r.b[k];
        }
        app.db.put('Listing', l);
        bumpDoc(app, r, key);
        return _listingView(l);
      },
      'chooseListingPlan': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (!{'draft', 'rejected', 'payment_pending'}.contains(l['status'])) throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        l['planCycle'] = r.b['cycle'];
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'submitListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (!{'draft', 'rejected'}.contains(l['status'])) throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        final missing = <Json>[];
        if (l['planCycle'] == null) missing.add({'path': '/planCycle', 'code': 'required'});
        if (((l.obj('title')['en'] as String?) ?? (l.obj('title')['ar'] as String?) ?? '').isEmpty) missing.add({'path': '/title', 'code': 'required'});
        if ((l['packageIds'] as List).isEmpty) missing.add({'path': '/packageIds', 'code': 'required'});
        if (missing.isNotEmpty) throw ApiError('VALIDATION_FAILED', errors: missing);
        l['submittedAt'] = app.now;
        l['rejection'] = null;
        final plan = app.adPlans().cast<Json?>().firstWhere((p) => p!['cycle'] == l['planCycle'], orElse: () => null);
        final mustPay = plan != null && plan['ratesFils'] != null && partnerAccount(app, r)['feeExempt'] != true;
        // with undecided rates there is nothing to pay: the listing goes straight to review (the seeds show the same history)
        transitionListing(app, l, mustPay ? 'payment_pending' : 'pending_review', 'provider', note: mustPay ? 'Plan chosen. Pay the listing fee to start the review.' : 'Plan chosen. Payment opens when rates are announced.');
        app.db.put('Listing', l);
        for (final uid in app.notifyTargets(providerId: l.str('providerId'))) {
          notify(app, userId: uid, kind: 'listing_submitted', audience: 'hotel', vars: {'title': l.obj('title')}, params: {'listing': l['id']}, listingId: l.str('id'));
        }
        return _listingView(l);
      },
      'createListingPaymentSession': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (!{'draft', 'payment_pending', 'rejected'}.contains(l['status'])) throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        final plan = app.adPlans().cast<Json?>().firstWhere((p) => p!['cycle'] == l['planCycle'], orElse: () => null);
        if (plan == null || plan['ratesFils'] == null) throw ApiError('PLAN_RATES_NOT_ANNOUNCED');
        if (app.flags['gatewayDown'] == true) throw ApiError('PAYMENT_GATEWAY_ERROR', retryAfterSeconds: 30);
        return wire(newListingPaymentSession(app, listing: l, method: r.b.str('method'), amountFils: plan.integer('ratesFils'), returnUrl: r.b.strOrNull('returnUrl')));
      },
      'pauseListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (l['status'] != 'active') throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        transitionListing(app, l, 'paused', 'provider');
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'resumeListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (l['status'] != 'paused') throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        transitionListing(app, l, 'active', 'provider');
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'renewListing': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (!{'active', 'expired'}.contains(l['status'])) throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        final plan = app.adPlans().cast<Json?>().firstWhere((p) => p!['cycle'] == l['planCycle'], orElse: () => null);
        final days = plan?.integer('periodDays') ?? 30;
        final start = l['status'] == 'active' && l.strOrNull('endsOn') != null ? l.str('endsOn') : app.today();
        l['startsOn'] = l['status'] == 'expired' ? app.today() : l['startsOn'];
        l['endsOn'] = addDays(start, days);
        if (l['status'] == 'expired') transitionListing(app, l, 'active', 'system', note: 'Renewed');
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'requestListingFeeRefund': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        if (l.obj('billing')['status'] != 'paid') throw ApiError('LISTING_STATE_CONFLICT', currentStatus: l.str('status'));
        l['feeRefund'] = {'requestedAt': app.now, 'recordedAt': null, 'recordedBy': null};
        l['billing'] = {...l.obj('billing'), 'status': 'refund_due'};
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'createListingUpload': (r) {
        _own(app, r);
        return uploadSession(app, r.b, defaultPurpose: 'listing_photo');
      },
      'attachListingMedia': (r) {
        app.requirePermission(r, 'listing:manage');
        final l = _own(app, r);
        final up = app.db.get('Upload', r.b.str('uploadId')) ?? (throw ApiError.validation('/uploadId', 'unknown_upload'));
        up['completed'] = true;
        app.db.put('Upload', up);
        final provider = _provider(app, r);
        // the mock stores nothing: it reuses a seeded portfolio photo so the screen has something to draw
        final pool = [for (final p in app.db.raw('ServiceProvider')) ...p.list('portfolio')];
        final base = deepCopy(pool[hash32([up.str('id')]) % pool.length]);
        final alt = r.b['alt'];
        final image = {...base, 'alt': ?alt};
        if (r.b.str('role') == 'cover') {
          l['cover'] = image;
        } else {
          provider['portfolio'] = [...provider.list('portfolio'), image];
          app.db.put('ServiceProvider', provider);
        }
        app.db.put('Listing', l);
        return _listingView(l);
      },
      'getPartnerBilling': (r) {
        final account = partnerAccount(app, r);
        final b = app.seed.extra.list('partnerBilling').cast<Json?>().firstWhere((x) => x!['partnerAccountId'] == account['id'], orElse: () => null);
        final venue = r.ctx.venueId == null ? null : app.db.peek('Venue', r.ctx.venueId!);
        final plans = [for (final p in app.adPlans()) {'plan': p, 'announcedSoon': p['ratesFils'] == null}];
        final payable = plans.every((p) => p['announcedSoon'] != true);
        final mode = b?['mode'] ?? (r.ctx.venueId != null ? 'contract' : 'plan');
        final listing = app.db.raw('Listing').cast<Json?>().firstWhere((l) => l!['partnerAccountId'] == account['id'] && l['planCycle'] != null, orElse: () => null);
        return {
          'mode': mode,
          'feeExempt': account['feeExempt'] == true,
          'majorHotel': venue?['major'] == true,
          'contractSummary': b?['contractSummary'],
          'plan': mode == 'plan' ? {'cycle': listing?['planCycle'], 'endsOn': listing?['endsOn']} : null,
          'plans': plans,
          'payable': payable,
        };
      },
      'getPartnerProvider': (r) => wire(_provider(app, r)),
      'updatePartnerProvider': (r) {
        app.requirePermission(r, 'listing:manage');
        final p = _provider(app, r);
        for (final k in ['about', 'phone', 'areaId', 'tags', 'femaleTeamForLadies']) {
          if (r.b.containsKey(k)) p[k] = r.b[k];
        }
        if (r.b['areaId'] != null) {
          final area = app.seed.rows('Area').cast<Json?>().firstWhere((a) => a!['id'] == r.b['areaId'], orElse: () => null);
          if (area == null) throw ApiError.validation('/areaId', 'unknown_area');
          p['governorateId'] = area['governorateId'];
        }
        app.db.put('ServiceProvider', p);
        return wire(p);
      },
      'listProviderPackages': (r) => {'packages': _provider(app, r)['packages']},
      'createProviderPackage': (r) {
        app.requirePermission(r, 'listing:manage');
        _checkPackage(r.b);
        final p = _provider(app, r);
        final pkg = _packageFrom(r.b, 'vp-${p['id']}-m${app.db.next('providerPackage')}');
        p['packages'] = [...p.list('packages'), pkg];
        _refreshFrom(p);
        app.db.put('ServiceProvider', p);
        return pkg;
      },
      'updateProviderPackage': (r) {
        app.requirePermission(r, 'listing:manage');
        _checkPackage(r.b);
        final p = _provider(app, r);
        final list = p.list('packages');
        final i = list.indexWhere((x) => x['id'] == r.p('packageId'));
        if (i < 0) throw ApiError.notFound('package');
        list[i] = _packageFrom(r.b, r.p('packageId'));
        p['packages'] = list;
        _refreshFrom(p);
        app.db.put('ServiceProvider', p);
        return list[i];
      },
      'deleteProviderPackage': (r) {
        app.requirePermission(r, 'listing:manage');
        final p = _provider(app, r);
        final list = p.list('packages');
        if (!list.any((x) => x['id'] == r.p('packageId'))) throw ApiError.notFound('package');
        p['packages'] = list.where((x) => x['id'] != r.p('packageId')).toList();
        app.db.put('ServiceProvider', p);
        return null;
      },
    };

Json partnerAccount(MockApp app, Req r) => app.db.get('PartnerAccount', r.ctx.accountId) ?? (throw ApiError.notFound('account'));
