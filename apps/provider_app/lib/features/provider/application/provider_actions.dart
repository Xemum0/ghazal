// The writes of the Provider and listings flow, over `partnerListingsRepositoryProvider`. Every one answers an `ActionResult` (never throws
// an `ApiProblem`) and bumps `partnerDataRevisionProvider` so the lists refetch. Listings carry an ETag the GET does not hand to the app, so the
// version is counted here (the server starts at 1 and adds one per write): requests.md.
import 'dart:convert' show jsonEncode;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerAccountRepositoryProvider, partnerListingsRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';
import 'application_form.dart';
import 'listing_draft.dart';

final NotifierProvider<ListingActions, ActionsState> listingActionsProvider = NotifierProvider<ListingActions, ActionsState>(ListingActions.new);

class ListingActions extends Notifier<ActionsState> {
  final IntentKeys _keys = IntentKeys();
  final Map<String, int> _versions = <String, int>{};

  @override
  ActionsState build() => const ActionsState();

  PartnerListingsRepository get _repo => ref.read(partnerListingsRepositoryProvider);

  Future<ActionResult<T>> _run<T>(String key, Future<T> Function() call, {String? intent, bool bump = true}) async {
    state = ActionsState(busy: {...state.busy, key});
    try {
      final value = await call();
      if (intent != null) _keys.done(intent);
      state = ActionsState(busy: {...state.busy}..remove(key));
      if (bump) ref.read(partnerDataRevisionProvider.notifier).bump();
      return ActionSuccess(value);
    } on ApiProblem catch (p) {
      if (intent != null && !p.isTransient) _keys.done(intent);
      state = ActionsState(busy: {...state.busy}..remove(key), lastProblem: p);
      return ActionFailure(p);
    }
  }

  /// Saves the editor: new and changed packages first (the listing points at them by id), then the listing itself (created when
  /// [listingId] is null). A package taken out of the draft only leaves the listing.
  Future<ActionResult<Listing>> saveDraft(ListingDraft d, {String? listingId}) {
    final intent = 'save:${listingId ?? 'new'}';
    return _run<Listing>('save', () async {
      final ids = <String>[];
      for (final p in d.packages) {
        final input = ProviderPackageInput(
          name: LocalizedText(en: p.nameEn, ar: p.nameAr),
          price: MoneyAmount(p.standardFils ?? 0),
          voucherPrice: p.voucherFils == null ? null : MoneyAmount(p.voucherFils!),
          unit: p.structure == PriceStructure.perPerson ? const LocalizedText(en: 'per guest', ar: 'للشخص') : const LocalizedText(en: 'per event', ar: 'للحفل الواحد'),
          priceStructure: p.structure,
          includes: p.includes,
        );
        if (p.isNew) {
          ids.add((await _repo.createProviderPackage(body: input, idempotencyKey: _keys.keyFor('pkg:${p.id}'))).id);
          _keys.done('pkg:${p.id}');
        } else {
          await _repo.updateProviderPackage(packageId: p.id, body: input);
          ids.add(p.id);
        }
      }
      final body = ListingInput(
        categoryId: d.categoryId,
        title: LocalizedText(en: d.titleEn, ar: d.titleAr),
        description: LocalizedText(en: d.descEn, ar: d.descAr),
        packageIds: ids,
      );
      if (listingId == null) return _repo.createListing(body: body, idempotencyKey: _keys.keyFor(intent));
      final v = _versions[listingId] ?? 1;
      final out = await _repo.updateListing(listingId: listingId, body: body, ifMatch: versionTag(v));
      _versions[listingId] = v + 1;
      return out;
    }, intent: intent);
  }

  /// Chooses the plan of a listing (nothing is charged; contract partners have none).
  Future<ActionResult<Listing>> choosePlan(String listingId, AdPlanCycle cycle) =>
      _run<Listing>('plan', () => _repo.chooseListingPlan(listingId: listingId, body: ChoosePlanInput(cycle: cycle)), bump: false);

  /// Sends the listing to review (never published on payment: only a moderator decision publishes).
  Future<ActionResult<Listing>> submit(String listingId) {
    final intent = 'submit:$listingId';
    return _run<Listing>('submit', () => _repo.submitListing(listingId: listingId, idempotencyKey: _keys.keyFor(intent)), intent: intent);
  }

  /// Opens the gateway session of the plan fee (409 `PLAN_RATES_NOT_ANNOUNCED` while the rates are undecided).
  Future<ActionResult<PaymentSession>> openPayment(String listingId, GatewayMethod method) {
    final intent = 'pay:$listingId';
    return _run<PaymentSession>('pay', () => _repo.createListingPaymentSession(listingId: listingId, body: PaymentSessionInput(method: method), idempotencyKey: _keys.keyFor(intent)), intent: intent, bump: false);
  }

  /// Renews an ended or expiring listing (a new payment, never an auto-debit).
  Future<ActionResult<Listing>> renew(String listingId) {
    final intent = 'renew:$listingId';
    return _run<Listing>('renew', () => _repo.renewListing(listingId: listingId, idempotencyKey: _keys.keyFor(intent)), intent: intent);
  }

  /// Asks support for a fee refund: recorded by the platform, paid outside the gateway.
  Future<ActionResult<Listing>> requestRefund(String listingId, {String? note}) {
    final intent = 'refund:$listingId';
    return _run<Listing>('refund', () => _repo.requestListingFeeRefund(listingId: listingId, body: FeeRefundInput(note: note), idempotencyKey: _keys.keyFor(intent)), intent: intent);
  }

  /// Adds a photo: the signed upload session, then the completed upload attached as the cover.
  Future<ActionResult<Listing>> addPhoto(String listingId) => _run<Listing>('photo', () async {
        final up = await _repo.createListingUpload(
          listingId: listingId,
          body: const UploadSessionInput(fileName: 'listing-photo.jpg', contentType: 'image/jpeg', sizeBytes: 480000, purpose: UploadPurpose.listingPhoto),
        );
        return _repo.attachListingMedia(listingId: listingId, body: AttachListingMediaInput(uploadId: up.id, role: ListingMediaRole.cover));
      });

  /// The application of a service provider or a private hall (`POST /partner/account-type`, PA-ACC-07): creates the account under review with a
  /// pending application. The session then follows the new account (the server made it the active one), so the status screen and every
  /// later call carry it.
  Future<ActionResult<PartnerApplication>> apply(ApplicationForm form) {
    const intent = 'application';
    return _run<PartnerApplication>('application', () async {
      final me = await ref.read(partnerAccountRepositoryProvider).chooseAccountType(body: form.toChooseInput(), idempotencyKey: _keys.keyFor(intent));
      final created = me.memberships.where((m) => m.application != null && m.application!.status == ApplicationStatus.pending).lastOrNull ??
          me.memberships.lastWhere((m) => m.application != null);
      await ref.read(sessionProvider.notifier).switchPartnerContext(created.accountId, venueId: created.venueId, providerId: created.providerId);
      return created.application!;
    }, intent: intent);
  }

  /// The PUBLIC application (`POST /partner/applications`, round 2b, OQ-R2-11): no session. The server makes the unverified account and the pending
  /// application and answers the emailed-code challenge; the app opens it for HL-ACCS-02 (`applicationChallengeProvider`). The Idempotency-Key
  /// is kept for a retry of the same send (one account, one email); a refusal that is not transient drops it.
  Future<ActionResult<OtpChallenge>> applyPublic(ApplicationForm form, String password, WireLang locale) {
    final body = form.toSubmitInput(password: password, locale: locale);
    final intent = 'application:public:${jsonEncode(body.toJson()).hashCode}'; // another body is another intent (the key is not reused for it)
    return _run<OtpChallenge>('application', () async {
      final challenge = await ref.read(partnerAccountRepositoryProvider).submitPartnerApplication(body: body, idempotencyKey: _keys.keyFor(intent));
      ref.read(applicationChallengeProvider.notifier).open(form.email.trim(), challenge);
      return challenge;
    }, intent: intent, bump: false);
  }

  /// Edit and resubmit a rejected application (`PUT /partner/application`): it goes back to `pending` with the reason cleared; 409
  /// `APPLICATION_NOT_EDITABLE` when it is not rejected any more.
  Future<ActionResult<PartnerApplication>> resubmit(ApplicationForm form) =>
      _run<PartnerApplication>('application', () => ref.read(partnerAccountRepositoryProvider).resubmitPartnerApplication(body: form.toResubmitInput()));
}
