import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Event names of the taxonomy (ADR 0019 item 1: `object_verb_pastTense`, snake_case). One registry: an unregistered
/// name is a bug. Payment and refund events of ADR 0019 are server-emitted and not listed; the voucher model (ADR 0033)
/// has no client payment funnel beyond the voucher purchase.
abstract final class GzEvents {
  static const appOpened = 'app_opened';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const languageChanged = 'language_changed';
  static const digitStyleChanged = 'digit_style_changed';
  static const notificationOpened = 'notification_opened';
  static const reviewSubmitted = 'review_submitted';
  static const chatStarted = 'chat_started';
  static const plannerConsultationRequested = 'planner_consultation_requested';
  static const searchPerformed = 'search_performed';
  static const filterApplied = 'filter_applied';
  static const filterCleared = 'filter_cleared';
  static const sortChanged = 'sort_changed';
  static const venueCardTapped = 'venue_card_tapped';
  static const venueViewed = 'venue_viewed';
  static const venueViewEnded = 'venue_view_ended';
  static const venueCtaClicked = 'venue_cta_clicked';
  static const galleryOpened = 'gallery_opened';
  static const galleryImagesViewed = 'gallery_images_viewed';
  static const videoPlayed = 'video_played';
  static const shareInitiated = 'share_initiated';
  static const wishlistChanged = 'wishlist_changed';
  static const availabilityDateSelected = 'availability_date_selected';
  static const estimateChanged = 'estimate_changed';
  static const compareChanged = 'compare_changed';
  static const compareViewed = 'compare_viewed';
  static const compareShared = 'compare_shared';
  static const compareBookClicked = 'compare_book_clicked';
  static const authPrompted = 'auth_prompted';
  static const authCompleted = 'auth_completed';
  static const bookingStarted = 'booking_started';
  static const bookingStepViewed = 'booking_step_viewed';
  static const bookingStepCompleted = 'booking_step_completed';
  static const bookingReviewViewed = 'booking_review_viewed';
  static const bookingSubmitted = 'booking_submitted';
  static const bookingAbandoned = 'booking_abandoned';
  static const bookingStatusChanged = 'booking_status_changed';
  // Partner app (ADR 0019 item 6 and 7).
  static const todayViewed = 'today_viewed';
  static const requestViewed = 'request_viewed';
  static const requestAccepted = 'request_accepted';
  static const requestDeclined = 'request_declined';
  static const requestCounterOffered = 'request_counter_offered';
  static const calendarViewed = 'calendar_viewed';
  static const datesBlocked = 'dates_blocked';
  static const offerPublished = 'offer_published';
  static const heroEdited = 'hero_edited';
  static const analyticsViewed = 'analytics_viewed';

  static const List<String> all = [
    appOpened, onboardingStepCompleted, languageChanged, digitStyleChanged, notificationOpened, reviewSubmitted,
    chatStarted, plannerConsultationRequested, searchPerformed, filterApplied, filterCleared, sortChanged,
    venueCardTapped, venueViewed, venueViewEnded, venueCtaClicked, galleryOpened, galleryImagesViewed, videoPlayed,
    shareInitiated, wishlistChanged, availabilityDateSelected, estimateChanged, compareChanged, compareViewed,
    compareShared, compareBookClicked, authPrompted, authCompleted, bookingStarted, bookingStepViewed,
    bookingStepCompleted, bookingReviewViewed, bookingSubmitted, bookingAbandoned, bookingStatusChanged, todayViewed,
    requestViewed, requestAccepted, requestDeclined, requestCounterOffered, calendarViewed, datesBlocked,
    offerPublished, heroEdited, analyticsViewed, //
  ];
}

/// One analytics event: a registered [name] and snake_case [properties]. Never put a name, phone, email, Civil ID,
/// IBAN, card data or free text in [properties] (ADR 0019 item 11); money is `amount_fils`.
class AnalyticsEvent {
  const AnalyticsEvent(this.name, [this.properties = const {}]);

  final String name;
  final Map<String, Object?> properties;

  @override
  String toString() => 'AnalyticsEvent($name, $properties)';
}

/// Thin analytics interface (ADR 0022 H). The first-party sink arrives with the API; until then [NoopAnalytics].
abstract interface class Analytics {
  /// Records one event. Never throws and never awaits the network.
  void track(AnalyticsEvent event);

  /// Sets a property sent with every later event (`lang`, `digit_style`, `is_guest`).
  void setCommonProperty(String key, Object? value);
}

class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void track(AnalyticsEvent event) {}

  @override
  void setCommonProperty(String key, Object? value) {}
}

/// Collects events in memory (tests and the prototype inspector).
class RecordingAnalytics implements Analytics {
  final List<AnalyticsEvent> events = [];
  final Map<String, Object?> common = {};

  @override
  void track(AnalyticsEvent event) {
    if (!GzEvents.all.contains(event.name)) throw ArgumentError('unregistered analytics event: ${event.name}');
    events.add(AnalyticsEvent(event.name, {...common, ...event.properties}));
  }

  @override
  void setCommonProperty(String key, Object? value) => common[key] = value;
}

final Provider<Analytics> analyticsProvider = Provider<Analytics>((ref) => const NoopAnalytics());
