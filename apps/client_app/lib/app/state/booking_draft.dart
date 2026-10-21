import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'search_brief.dart';

enum BookingStep { package, details, review, sent }

/// The personal block of the request form (CL-BOOK details). The phone is the client's own number in E.164.
@immutable
final class DraftPersonal {
  const DraftPersonal({this.name = '', this.phone = '', this.email = '', this.bookingFor = BookingFor.bride, this.shareContact = true});

  final String name;
  final String phone;
  final String email;
  final BookingFor bookingFor;

  /// Share the contact with the venue when it approves.
  final bool shareContact;

  DraftPersonal copyWith({String? name, String? phone, String? email, BookingFor? bookingFor, bool? shareContact}) => DraftPersonal(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        bookingFor: bookingFor ?? this.bookingFor,
        shareContact: shareContact ?? this.shareContact,
      );

  @override
  bool operator ==(Object other) =>
      other is DraftPersonal && other.name == name && other.phone == phone && other.email == email && other.bookingFor == bookingFor && other.shareContact == shareContact;

  @override
  int get hashCode => Object.hash(name, phone, email, bookingFor, shareContact);
}

/// The request the client is putting together (web `BookingDraft`, ADR 0033): local until Review, the server never stores a draft. A venue
/// request has a hall, session, package, date, audience and guests; a service request has a listing, package, date and a quantity
/// (carried in [guests]).
@immutable
final class BookingDraft {
  const BookingDraft({
    this.targetType = BookingTargetType.venue,
    this.venueId,
    this.providerId,
    this.listingId,
    this.hallId,
    this.sessionId,
    this.packageId,
    this.extras = const <String>[],
    this.eventDate,
    this.audience,
    this.guests,
    this.personal = const DraftPersonal(),
    this.requests = '',
    this.voucherId,
    this.quoteId,
    this.requestId,
    this.step = BookingStep.package,
  });

  static const BookingDraft empty = BookingDraft();

  final BookingTargetType targetType;
  final String? venueId;
  final String? providerId;
  final String? listingId;
  final String? hallId;
  final String? sessionId;
  final String? packageId;
  final List<String> extras;
  final LocalDate? eventDate;
  final Audience? audience;

  /// Guests (venue) or quantity (service provider).
  final int? guests;
  final DraftPersonal personal;
  final String requests;

  /// The voucher bound to this quote once the checkout created it (paid later).
  final String? voucherId;

  /// The server quote of the checkout (it must still match when the request is sent).
  final String? quoteId;

  /// The request that was created (step `sent`).
  final String? requestId;
  final BookingStep step;

  bool get isProvider => targetType == BookingTargetType.provider;

  /// The fields a send still needs, by name (empty = ready).
  List<String> get missing => <String>[
        if (isProvider) ...[
          if (providerId == null) 'providerId',
          if (listingId == null) 'listingId',
        ] else ...[
          if (venueId == null) 'venueId',
          if (hallId == null) 'hallId',
          if (sessionId == null) 'sessionId',
          if (audience == null) 'audience',
        ],
        if (packageId == null) 'packageId',
        if (eventDate == null) 'eventDate',
        if (guests == null) 'guests',
      ];

  bool get isComplete => missing.isEmpty;

  /// The `VoucherCheckoutInput` of this draft (the target is the venue or the provider).
  VoucherCheckoutInput toCheckoutInput() {
    _require();
    return VoucherCheckoutInput(
      targetType: isProvider ? VoucherTargetType.provider : VoucherTargetType.venue,
      targetId: (isProvider ? providerId : venueId)!,
      hallId: isProvider ? null : hallId,
      packageId: packageId!,
      eventDate: eventDate!,
      guests: guests,
      quoteId: quoteId,
    );
  }

  /// The body of R01 for [voucherId] (default: the draft's own). Throws `StateError` when the draft is incomplete: [missing] says what.
  CreateRequestInput toCreateRequestInput({String? voucherId}) {
    _require();
    final voucher = voucherId ?? this.voucherId;
    if (voucher == null) throw StateError('the draft has no voucher');
    return CreateRequestInput(
      targetType: targetType,
      venueId: isProvider ? null : venueId,
      providerId: isProvider ? providerId : null,
      eventDate: eventDate!,
      sections: isProvider
          ? null
          : [RequestSectionInput(hallId: hallId!, sessionId: sessionId!, audience: audience!, guests: guests!, packageId: packageId!)],
      service: isProvider ? RequestServiceInput(listingId: listingId!, packageId: packageId!, quantity: guests!) : null,
      extras: extras.isEmpty ? null : [for (final id in extras) QuoteExtraInput(extraId: id, qty: 1)],
      voucherId: voucher,
      quoteId: quoteId,
      contact: ContactInput(name: personal.name, phone: personal.phone, bookingFor: personal.bookingFor, shared: personal.shareContact),
      specialRequests: requests.trim().isEmpty ? null : requests.trim(),
    );
  }

  void _require() {
    if (!isComplete) throw StateError('the booking draft is incomplete: ${missing.join(', ')}');
  }

  /// Changes some fields. The `clear*` flags drop a field (`clearVoucher` drops the voucher, quote and request ids: use it when the
  /// package, date, guests or hall change after a checkout, so a stale quote is never sent).
  BookingDraft copyWith({
    BookingTargetType? targetType,
    String? venueId,
    String? providerId,
    String? listingId,
    String? hallId,
    String? sessionId,
    String? packageId,
    List<String>? extras,
    LocalDate? eventDate,
    Audience? audience,
    int? guests,
    DraftPersonal? personal,
    String? requests,
    String? voucherId,
    String? quoteId,
    String? requestId,
    BookingStep? step,
    bool clearVoucher = false,
    bool clearSession = false,
    bool clearPackage = false,
  }) =>
      BookingDraft(
        targetType: targetType ?? this.targetType,
        venueId: venueId ?? this.venueId,
        providerId: providerId ?? this.providerId,
        listingId: listingId ?? this.listingId,
        hallId: hallId ?? this.hallId,
        sessionId: clearSession ? null : (sessionId ?? this.sessionId),
        packageId: clearPackage ? null : (packageId ?? this.packageId),
        extras: extras ?? this.extras,
        eventDate: eventDate ?? this.eventDate,
        audience: audience ?? this.audience,
        guests: guests ?? this.guests,
        personal: personal ?? this.personal,
        requests: requests ?? this.requests,
        voucherId: clearVoucher ? null : (voucherId ?? this.voucherId),
        quoteId: clearVoucher ? null : (quoteId ?? this.quoteId),
        requestId: clearVoucher ? null : (requestId ?? this.requestId),
        step: step ?? this.step,
      );

  @override
  bool operator ==(Object other) =>
      other is BookingDraft &&
      other.targetType == targetType &&
      other.venueId == venueId &&
      other.providerId == providerId &&
      other.listingId == listingId &&
      other.hallId == hallId &&
      other.sessionId == sessionId &&
      other.packageId == packageId &&
      listEquals(other.extras, extras) &&
      other.eventDate == eventDate &&
      other.audience == audience &&
      other.guests == guests &&
      other.personal == personal &&
      other.requests == requests &&
      other.voucherId == voucherId &&
      other.quoteId == quoteId &&
      other.requestId == requestId &&
      other.step == step;

  @override
  int get hashCode => Object.hash(targetType, venueId, providerId, listingId, hallId, sessionId, packageId, Object.hashAll(extras), eventDate, audience, guests,
      Object.hash(personal, requests, voucherId, quoteId, requestId, step));
}

/// The booking draft: UI memory of the request flow, not persisted. It is cleared when the client signs out (not when a guest signs in:
/// a guest who hit the gate keeps the draft and resumes it).
final NotifierProvider<BookingDraftNotifier, BookingDraft> bookingDraftProvider = NotifierProvider<BookingDraftNotifier, BookingDraft>(BookingDraftNotifier.new);

class BookingDraftNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() {
    ref.listen(sessionProvider, (prev, next) {
      if ((prev?.isSignedIn ?? false) && !next.isSignedIn) state = BookingDraft.empty;
    });
    return BookingDraft.empty;
  }

  /// Starts a fresh draft for a venue (or, with [providerId], a service provider) seeded from the Brief (date, audience, guests) and the
  /// signed-in client (name, phone). [patch] fields win over the seed (a package chosen on the venue page).
  void start({
    String? venueId,
    String? providerId,
    String? listingId,
    String? hallId,
    String? sessionId,
    String? packageId,
    LocalDate? eventDate,
    Audience? audience,
    int? guests,
    List<String> extras = const <String>[],
  }) {
    final brief = ref.read(searchBriefProvider);
    final session = ref.read(sessionProvider);
    final user = session is ClientSession ? session.user : null;
    state = BookingDraft(
      targetType: providerId != null ? BookingTargetType.provider : BookingTargetType.venue,
      venueId: venueId,
      providerId: providerId,
      listingId: listingId,
      hallId: hallId,
      sessionId: sessionId,
      packageId: packageId,
      extras: List<String>.unmodifiable(extras),
      eventDate: eventDate ?? brief.date,
      audience: audience ?? brief.audience,
      guests: guests ?? brief.guests,
      personal: DraftPersonal(name: user?.name ?? '', phone: user?.phone ?? '', email: user?.email ?? ''),
    );
  }

  /// Replaces the draft wholesale (a flow that built it elsewhere) or edits it: `patch((d) => d.copyWith(hallId: 'V01-danah'))`.
  void patch(BookingDraft Function(BookingDraft current) change) => state = change(state);

  void toggleExtra(String extraId) => state = state.copyWith(
        extras: state.extras.contains(extraId) ? [for (final e in state.extras) if (e != extraId) e] : [...state.extras, extraId],
      );

  void setStep(BookingStep step) => state = state.copyWith(step: step);

  void setPersonal(DraftPersonal Function(DraftPersonal current) change) => state = state.copyWith(personal: change(state.personal));

  void reset() => state = BookingDraft.empty;
}
