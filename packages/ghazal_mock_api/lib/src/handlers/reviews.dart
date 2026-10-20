/// reviews: venue reviews for clients (list, write after a completed request). Partner-side replies are in `partner_reviews.dart`.
library;

import '../core/app.dart';
import '../core/paging.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../domain/notify.dart';
import '../domain/views.dart';
import '../engine/engine.dart';

/// A review as a client sees it (no reply draft, no internal fields).
Json publicReview(Json r) => {...wire(r), 'replyDraft': null};

Map<String, Handler> reviewsHandlers(MockApp app) => {
      'listVenueReviews': (r) {
        final id = r.p('venueId');
        app.db.peek('Venue', id) ?? (throw ApiError.notFound('venue'));
        var rows = app.db.raw('Review').where((x) => x['venueId'] == id && x['_hidden'] != true).toList();
        if (r.q('audience') != null) rows = rows.where((x) => x['audience'] == r.q('audience')).toList();
        if (r.q('hallId') != null) rows = rows.where((x) => x['hallId'] == r.q('hallId')).toList();
        final sort = r.q('sort') ?? 'newest';
        final sorted = stableSorted(rows, (a, b) {
          switch (sort) {
            case 'highest':
              return cmpNum((b['rating'] as num) - (a['rating'] as num));
            case 'lowest':
              return cmpNum((a['rating'] as num) - (b['rating'] as num));
            default:
              return b.str('postedAt').compareTo(a.str('postedAt'));
          }
        });
        return pageMap(r, sorted, publicReview);
      },
      'createReview': (r) {
        final b = app.db.get('Booking', r.p('requestId'));
        if (b == null || b['clientId'] != r.userId) throw ApiError.notFound('request');
        if (b['status'] != 'completed' || b['venueId'] == null || app.db.raw('Review').any((x) => x['_bookingId'] == b['id'])) throw ApiError('REVIEW_NOT_ALLOWED');
        final venueId = b.str('venueId');
        final body = r.b;
        final origin = body.strOrNull('origin') ?? r.lang;
        final anonymous = body['anonymous'] == true;
        final user = r.identity!.user;
        final text = origin == 'ar' ? {'en': null, 'ar': body['text']} : {'en': body['text'], 'ar': null};
        final section = b.list('sections').first;
        final seq = app.db.next('review');
        final review = <String, dynamic>{
          'id': 'rv-$venueId-m$seq',
          'venueId': venueId,
          'author': anonymous ? {'en': 'Guest', 'ar': 'ضيفة'} : {'en': user['nameLatin'] ?? user['name'], 'ar': user['name']},
          'monogram': anonymous ? 'ض' : user['monogram'],
          'anonymous': anonymous,
          'rating': body['rating'],
          'categories': body['categories'],
          'text': text,
          'origin': origin,
          'audience': section['audience'] == 'men' ? 'men' : 'women',
          'hallId': section['hallId'],
          'eventDate': b['eventDate'],
          'postedAt': app.now,
          'ownerReply': null,
          'supportRequest': null,
          'replyDraft': null,
          'verifiedBooking': true,
          'photos': <String>[],
          '_bookingId': b['id'],
        };
        app.db.put('Review', review);
        // the venue's rating summary follows the new review
        final venue = app.db.get('Venue', venueId)!;
        final rating = venue.obj('rating');
        final n = rating.integer('count');
        double mix(num? old, num add) => ((((old ?? add) * n) + add) / (n + 1) * 10).round() / 10;
        final cats = rating.objOrNull('categories');
        final nc = body.obj('categories');
        venue['rating'] = {
          'average': mix(rating['average'] as num?, body['rating'] as num),
          'count': n + 1,
          'categories': cats == null ? nc : {for (final k in ['venue', 'food', 'service', 'value']) k: mix(cats[k] as num, nc[k] as num)},
        };
        app.db.put('Venue', venue);
        for (final uid in app.notifyTargets(venueId: venueId)) {
          notify(app, userId: uid, kind: 'review_received', audience: 'hotel', params: {'reviewer': review['author'], 'rating': review['rating']}, bookingId: b.str('id'), venueId: venueId);
        }
        app.logEvent('review_created', {'reviewId': review['id']});
        return publicReview(review);
      },
    };
