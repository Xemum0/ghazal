// Reads and writes of the venue flow (HL-VENU-01..06), over the partner-venue repository. Lists refetch after a write by watching
// `partnerDataRevisionProvider`. Writes never throw an `ApiProblem`: they answer an `ActionResult`, the screen shows the message.
// Settings documents (policies, booking rules, a hall, a package) carry an ETag; the contract's GET does not return it to the app, so the
// version is counted here (the server starts at 1 and adds one per write): see requests.md [P-H3].
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart'
    show homeRepositoryProvider, partnerRequestsRepositoryProvider, partnerVenueRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';
import 'venue_pricing.dart';

/// The hero constants of the web screens (`venue/_components/venue.ts`): the hero hall and package of the Aurelia Gulf Hotel.
const String kHeroHallId = 'V01-danah';

/// The story booking behind every "what couples see" sample (web `sample()`): Reem's request, 350 guests, its standard and voucher totals.
const String kSampleBookingId = 'bk-GZ-2611-0147';

final FutureProvider<Booking> sampleBookingProvider = FutureProvider.autoDispose<Booking>((ref) async {
  return (await ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: kSampleBookingId)).booking;
});

/// The voucher-model numbers (fee, validity, confirm window) of the platform configuration.
final FutureProvider<PlatformConfig> venueConfigProvider = FutureProvider.autoDispose<PlatformConfig>(
  (ref) async => (await ref.read(homeRepositoryProvider).getAppConfig()).config,
);

/// The body that writes a hall again unchanged (a screen edits one part of it and sends the rest as it was).
HallInput hallInputOf(
  Hall h, {
  GuestRange? capacity,
  HallSetting? setting,
  bool? exclusiveDay,
  List<HallSection>? sections,
  List<SessionInput>? sessions,
  LocalizedText? name,
}) => HallInput(
  name: name ?? h.name,
  setting: setting ?? h.setting,
  capacity: capacity ?? h.capacity,
  exclusiveDay: exclusiveDay ?? h.exclusiveDay,
  sessions: sessions ?? [for (final s in h.sessions) sessionInputOf(s)],
  sections: sections ?? h.sections,
  seasonMonths: h.seasonMonths,
  description: h.description,
);

SessionInput sessionInputOf(Session s) => SessionInput(
  id: s.id,
  name: s.name,
  start: s.start,
  end: s.end,
  bufferBeforeMin: s.bufferBeforeMin,
  bufferAfterMin: s.bufferAfterMin,
  weekdays: s.weekdays,
);

/// The facility catalogue (id, group, label) every facility row is named from.
final FutureProvider<Map<String, LocalizedText>> venueAmenityLabelsProvider = FutureProvider.autoDispose<Map<String, LocalizedText>>((ref) async {
  final t = await ref.read(venuesRepositoryProvider).getFilterTaxonomy();
  return {for (final a in t.amenities) a.id: a.label};
});

/// The governorate and area names of the venue's address.
final FutureProvider<({LocalizedText governorate, LocalizedText area})?> venueRegionProvider =
    FutureProvider.autoDispose<({LocalizedText governorate, LocalizedText area})?>((ref) async {
      final v = (await ref.watch(partnerVenueProvider.future)).venue;
      final r = await ref.read(venuesRepositoryProvider).listAreas();
      final g = r.governorates.where((x) => x.id == v.governorateId).firstOrNull;
      final a = r.areas.where((x) => x.id == v.areaId).firstOrNull;
      if (g == null || a == null) return null;
      return (governorate: g.name, area: a.name);
    });

/// The venue's own profile with the completeness of its listing.
final FutureProvider<PartnerVenue> partnerVenueProvider = FutureProvider.autoDispose<PartnerVenue>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getPartnerVenue();
});

/// Photos and videos with the upload limits.
final FutureProvider<MediaLibrary> venueMediaProvider = FutureProvider.autoDispose<MediaLibrary>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).listVenueMedia();
});

/// Packages with their price rules, and the extras.
final FutureProvider<PackageCatalog> venueCatalogProvider = FutureProvider.autoDispose<PackageCatalog>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).listPartnerPackages();
});

/// Halls with sessions, sections and policy facts.
final FutureProvider<HallList> venueHallsProvider = FutureProvider.autoDispose<HallList>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).listPartnerHalls();
});

final FutureProvider<VenuePolicies> venuePoliciesProvider = FutureProvider.autoDispose<VenuePolicies>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getVenuePolicies();
});

final FutureProvider<BookingRules> venueRulesProvider = FutureProvider.autoDispose<BookingRules>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getBookingRules();
});

final FutureProvider<BusinessHours> venueHoursProvider = FutureProvider.autoDispose<BusinessHours>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getBusinessHours();
});

/// The package with this id, from the catalog (null while loading or when it does not exist).
PackageEditor? packageOf(PackageCatalog catalog, String? id) {
  for (final p in catalog.packages) {
    if (p.package.id == id) return p;
  }
  return null;
}

/// The body that writes a package again unchanged, apart from what the caller overrides.
PackageInput packageInputOf(PackageEditor e, {bool? active, List<PriceRuleInput>? rules}) {
  final p = e.package;
  return PackageInput(
    hallIds: p.hallIds,
    name: p.name,
    archetype: p.archetype,
    audiences: p.audiences,
    pricingBasis: p.pricingBasis,
    priceStructure: p.priceStructure,
    priceUnit: p.priceUnit,
    minGuests: p.minGuests,
    maxGuests: p.maxGuests,
    guestStep: p.guestStep,
    complimentaryBps: p.complimentaryBps,
    description: p.description,
    inclusions: p.inclusions,
    notes: p.notes,
    components: p.components,
    active: active ?? p.active,
    rules: rules ?? [for (final r in e.rules) ruleInputOf(r)],
  );
}

/// The price rule of a tier of a package (the weekday and weekend rules the phone edits).
PriceRule? ruleOf(PackageEditor pkg, PriceTier tier) {
  for (final r in pkg.rules) {
    if (r.tier == tier) return r;
  }
  return null;
}

/// Writes of the venue flow. One notifier, one busy set (`save:policies`, `media:<id>` ...).
final NotifierProvider<VenueActions, ActionsState> venueActionsProvider = NotifierProvider<VenueActions, ActionsState>(VenueActions.new);

class VenueActions extends Notifier<ActionsState> {
  final IntentKeys _keys = IntentKeys();
  final Map<String, int> _versions = <String, int>{};

  @override
  ActionsState build() => const ActionsState();

  PartnerVenueRepositoryAlias get _repo => ref.read(partnerVenueRepositoryProvider);

  String _tag(String doc) => versionTag(_versions[doc] ?? 1);

  Future<ActionResult<T>> _run<T>(String key, Future<T> Function() call, {String? doc, bool bump = true, String? intent}) async {
    state = ActionsState(busy: {...state.busy, key});
    try {
      final value = await call();
      if (intent != null) _keys.done(intent);
      if (doc != null) _versions[doc] = (_versions[doc] ?? 1) + 1;
      state = ActionsState(busy: {...state.busy}..remove(key));
      if (bump) ref.read(partnerDataRevisionProvider.notifier).bump();
      return ActionSuccess(value);
    } on ApiProblem catch (p) {
      if (intent != null && !p.isTransient) _keys.done(intent);
      state = ActionsState(busy: {...state.busy}..remove(key), lastProblem: p);
      return ActionFailure(p);
    }
  }

  Future<ActionResult<VenuePolicies>> savePolicies(VenuePolicies body) => _run(
    'save:policies',
    () => _repo.putVenuePolicies(body: body, ifMatch: _tag('policies')),
    doc: 'policies',
  );

  Future<ActionResult<BookingRules>> saveRules(BookingRules body) => _run(
    'save:rules',
    () => _repo.putBookingRules(body: body, ifMatch: _tag('rules')),
    doc: 'rules',
  );

  Future<ActionResult<BusinessHours>> saveHours(BusinessHours body) => _run('save:hours', () => _repo.putBusinessHours(body: body));

  Future<ActionResult<Hall>> saveHall(String? hallId, HallInput body) => hallId == null
      ? _run(
          'save:hall',
          () => _repo.createHall(body: body, idempotencyKey: _keys.keyFor('hall:new')),
          intent: 'hall:new',
        )
      : _run(
          'save:hall',
          () => _repo.updateHall(hallId: hallId, body: body, ifMatch: _tag('hall:$hallId')),
          doc: 'hall:$hallId',
        );

  Future<ActionResult<VenueAmenities>> saveAmenities(VenueAmenities body) => _run('save:amenities', () => _repo.setVenueAmenities(body: body));

  Future<ActionResult<PackageEditor>> savePackage(String? packageId, PackageInput body) => packageId == null
      ? _run(
          'save:package',
          () => _repo.createPackage(body: body, idempotencyKey: _keys.keyFor('package:new')),
          intent: 'package:new',
        )
      : _run(
          'save:package',
          () => _repo.updatePackage(packageId: packageId, body: body, ifMatch: _tag('package:$packageId')),
          doc: 'package:$packageId',
        );

  Future<ActionResult<Extra>> saveExtra(String? extraId, ExtraInput body) => extraId == null
      ? _run(
          'save:extra',
          () => _repo.createExtra(body: body, idempotencyKey: _keys.keyFor('extra:new')),
          intent: 'extra:new',
        )
      : _run('save:extra', () => _repo.updateExtra(extraId: extraId, body: body));

  Future<ActionResult<MediaLibrary>> reorder(List<String> ids) => _run('media:order', () => _repo.reorderMedia(body: ReorderMediaInput(ids: ids)));

  Future<ActionResult<MediaItem>> updateMedia(String id, UpdateMediaInput body) =>
      _run('media:$id', () => _repo.updateMediaItem(mediaId: id, body: body));

  Future<ActionResult<void>> deleteMedia(String id) => _run<void>('media:$id', () => _repo.deleteMediaItem(mediaId: id));

  /// A photo or video upload: the signed session, then the completion (the mock stores nothing; the file is processed and moderated).
  Future<ActionResult<MediaItem>> upload(MediaUploadInput input, {LocalizedText? alt}) => _run<MediaItem>('media:upload', () async {
    final session = await _repo.createMediaUploadSession(body: input);
    return _repo.completeMediaUpload(
      uploadId: session.id,
      body: CompleteMediaInput(alt: alt),
      idempotencyKey: _keys.keyFor('upload:${input.fileName}'),
    );
  }, intent: 'upload:${input.fileName}');
}

typedef PartnerVenueRepositoryAlias = PartnerVenueRepository;
