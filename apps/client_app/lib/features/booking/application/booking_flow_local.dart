import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show BookingFor;

/// The optional occasion of step 1 (web `OccasionKey`, flagged OQ-B-11).
enum BookingOccasion { wedding, milka, henna, engagement, other }

/// What the request flow keeps besides the shared [BookingDraft] (web `useFlowStore`): occasion, extra quantities, who the booking is for,
/// the phone verified in this run, the two consents, the steps on screen and the planner card state. Not persisted; cleared when the flow ends.
@immutable
final class BookingFlowLocal {
  const BookingFlowLocal({
    this.occasion,
    this.extraQty = const <String, int>{},
    this.forOther = false,
    this.otherName = '',
    this.relation = BookingFor.bride,
    this.verifiedPhone,
    this.consent = false,
    this.confirmConsent = false,
    this.entered = const <int>{},
    this.plannerDismissed = false,
    this.notifPrompted = false,
  });

  final BookingOccasion? occasion;
  final Map<String, int> extraQty;
  final bool forOther;
  final String otherName;
  final BookingFor relation;

  /// E.164 of a number verified in this run (the signed-in number is verified by the sign-in itself).
  final String? verifiedPhone;

  /// Consent on the Review (venue, voucher and platform terms) and on Confirm your booking.
  final bool consent;
  final bool confirmConsent;

  /// Steps (1 to 5) whose screen is on the stack: an Edit link pops back to them, otherwise it replaces.
  final Set<int> entered;
  final bool plannerDismissed;
  final bool notifPrompted;

  BookingFlowLocal copyWith({
    BookingOccasion? occasion,
    bool clearOccasion = false,
    Map<String, int>? extraQty,
    bool? forOther,
    String? otherName,
    BookingFor? relation,
    String? verifiedPhone,
    bool? consent,
    bool? confirmConsent,
    Set<int>? entered,
    bool? plannerDismissed,
    bool? notifPrompted,
  }) => BookingFlowLocal(
    occasion: clearOccasion ? null : (occasion ?? this.occasion),
    extraQty: extraQty ?? this.extraQty,
    forOther: forOther ?? this.forOther,
    otherName: otherName ?? this.otherName,
    relation: relation ?? this.relation,
    verifiedPhone: verifiedPhone ?? this.verifiedPhone,
    consent: consent ?? this.consent,
    confirmConsent: confirmConsent ?? this.confirmConsent,
    entered: entered ?? this.entered,
    plannerDismissed: plannerDismissed ?? this.plannerDismissed,
    notifPrompted: notifPrompted ?? this.notifPrompted,
  );
}

final NotifierProvider<BookingFlowLocalNotifier, BookingFlowLocal> bookingFlowLocalProvider =
    NotifierProvider<BookingFlowLocalNotifier, BookingFlowLocal>(BookingFlowLocalNotifier.new);

class BookingFlowLocalNotifier extends Notifier<BookingFlowLocal> {
  @override
  BookingFlowLocal build() => const BookingFlowLocal();

  void update(BookingFlowLocal Function(BookingFlowLocal current) change) => state = change(state);

  void reset() => state = const BookingFlowLocal();

  void markEntered(int step, {required bool on}) {
    if (!ref.mounted) return;
    final next = {...state.entered};
    on ? next.add(step) : next.remove(step);
    state = state.copyWith(entered: next);
  }
}
