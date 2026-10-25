/// Every operation of the contract by `operationId`, assembled from the handler files of the 23 tags.
library;

import '../core/app.dart';
import '../core/request.dart';
import 'auth.dart';
import 'chat.dart';
import 'home.dart';
import 'notifications.dart';
import 'partner_account.dart';
import 'partner_bookings.dart';
import 'partner_calendar.dart';
import 'partner_growth.dart';
import 'partner_listings.dart';
import 'partner_requests.dart';
import 'partner_reviews.dart';
import 'partner_venue.dart';
import 'partner_visits.dart';
import 'planners.dart';
import 'profile.dart';
import 'requests.dart';
import 'reviews.dart';
import 'services.dart';
import 'support.dart';
import 'venues.dart';
import 'visits.dart';
import 'vouchers.dart';
import 'wedding.dart';

/// Tag name to the handlers of that tag (for the coverage report: operations hit per tag).
Map<String, Map<String, Handler>> handlersByTag(MockApp app) => {
  'auth': authHandlers(app),
  'home': homeHandlers(app),
  'venues': venuesHandlers(app),
  'vouchers': vouchersHandlers(app),
  'requests': requestsHandlers(app),
  'visits': visitsHandlers(app),
  'chat': chatHandlers(app),
  'notifications': notificationsHandlers(app),
  'reviews': reviewsHandlers(app),
  'wedding': weddingHandlers(app),
  'services': servicesHandlers(app),
  'planners': plannersHandlers(app),
  'profile': profileHandlers(app),
  'support': supportHandlers(app),
  'partner-account': partnerAccountHandlers(app),
  'partner-requests': partnerRequestsHandlers(app),
  'partner-bookings': partnerBookingsHandlers(app),
  'partner-calendar': partnerCalendarHandlers(app),
  'partner-venue': partnerVenueHandlers(app),
  'partner-visits': partnerVisitsHandlers(app),
  'partner-growth': partnerGrowthHandlers(app),
  'partner-listings': partnerListingsHandlers(app),
  'partner-reviews': partnerReviewsHandlers(app),
};

Map<String, Handler> allHandlers(MockApp app) => {for (final m in handlersByTag(app).values) ...m};
