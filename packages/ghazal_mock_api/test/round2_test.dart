// Owner round 2 (ADR 0038, docs/engineering/round2-change-brief.md) in the mock: sex on the client account, governorates as the client's region, the
// partner application with its review states, and no extras on the venue side. Each test names the rule it pins in docs/architecture/mock-api.md.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show Json;

import 'harness.dart';

Future<Response<Object?>> raw(Actor a, String method, String path, {Object? data, Map<String, Object?>? headers, Map<String, Object?>? query}) =>
    a.dio.request<Object?>(
      path,
      data: data,
      queryParameters: query,
      options: Options(method: method, headers: headers, validateStatus: (_) => true),
    );

Json body(Response<Object?> r) => (r.data as Map).cast<String, dynamic>();

List<Json> errorsOf(Response<Object?> r) => ((body(r)['errors'] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();

bool hasError(Response<Object?> r, String path, String code) => errorsOf(r).any((e) => e['path'] == path && e['code'] == code);

void main() {
  late World w;
  setUp(() async => w = await World.create());

  group('sex on the client account (CA-AUTH-14)', () {
    Future<String> firstCode(Actor a, String phone) async {
      final c = await a.repos.auth.requestOtp(
        body: OtpRequestInput(phone: phone, purpose: OtpPurpose.login),
      );
      return c.challengeId;
    }

    /// Signs in with the first code of [phone] and keeps the tokens on the actor (the repositories do not store them themselves).
    Future<AuthSession> signIn(Actor a, String phone) async {
      final s = await a.repos.auth.verifyOtp(
        body: OtpVerifyInput(challengeId: await firstCode(a, phone), code: '123456'),
      );
      await a.tokens.write(AuthTokens(accessToken: s.accessToken, refreshToken: s.refreshToken));
      return s;
    }

    test('the seeded clients carry a sex: Reem and the new-client persona are female, the couples include men', () async {
      expect((await w.actor('reem').repos.profile.getMe()).user.sex, Sex.female);
      expect((await w.actor('new_client').repos.profile.getMe()).user.sex, Sex.female);
      final hind = await w.actor('hotel_manager', venueId: 'V01').repos.profile.getMe();
      expect(hind.user.sex, isNull, reason: 'staff accounts have none');
    });

    test('a first code makes a new, incomplete account: isNewUser stays true and there is no sex until "About you" is completed', () async {
      final a = w.actor('guest');
      const phone = '+96550004001';
      final first = await signIn(a, phone);
      expect(first.isNewUser, isTrue);
      expect(first.user.user.sex, isNull);

      // the person quits before finishing: the next sign-in is still a new account
      final again = await signIn(a, phone);
      expect(again.isNewUser, isTrue, reason: 'About you is not done yet');

      final me = await a.repos.profile.completeProfile(
        body: const CompleteProfileInput(name: 'Maha Al-Sabah', sex: Sex.female, acceptedTerms: true),
      );
      expect(me.user.sex, Sex.female);
      expect(me.user.name, 'Maha Al-Sabah');

      final later = await signIn(a, phone);
      expect(later.isNewUser, isFalse);
      expect(later.user.user.sex, Sex.female);
    });

    test(
      'completeProfile without a sex is the usual 422 VALIDATION_FAILED with {path: /sex, code: required}; so is a sex outside the enum',
      () async {
        final a = w.actor('guest');
        await signIn(a, '+96550004002');
        final missing = await raw(a, 'POST', '/me/complete', data: {'name': 'Maha', 'acceptedTerms': true});
        expect((missing.statusCode, body(missing)['code']), (422, 'VALIDATION_FAILED'));
        expect(hasError(missing, '/sex', 'required'), isTrue, reason: '${errorsOf(missing)}');
        final wrong = await raw(a, 'POST', '/me/complete', data: {'name': 'Maha', 'sex': 'other', 'acceptedTerms': true});
        expect(hasError(wrong, '/sex', 'invalid_enum'), isTrue, reason: '${errorsOf(wrong)}');
        final noTerms = await raw(a, 'POST', '/me/complete', data: {'name': 'Maha', 'sex': 'male', 'acceptedTerms': false});
        expect(noTerms.statusCode, 422);
        final blank = await raw(a, 'POST', '/me/complete', data: {'name': '', 'sex': 'male', 'acceptedTerms': true});
        expect(hasError(blank, '/name', 'too_short'), isTrue, reason: 'name is required too');
      },
    );

    test('registerAccount requires the sex; with it the account is complete and carries it after the phone is verified', () async {
      final a = w.actor('guest');
      final missing = await raw(
        a,
        'POST',
        '/auth/register',
        data: {'phone': '+96550004003', 'name': 'Omar', 'password': 'Passw0rd!x', 'acceptedTerms': true, 'locale': 'en'},
      );
      expect((missing.statusCode, body(missing)['code']), (422, 'VALIDATION_FAILED'));
      expect(hasError(missing, '/sex', 'required'), isTrue);
      final challenge = await a.repos.auth.registerAccount(
        body: const RegisterInput(
          phone: '+96550004004',
          name: 'Omar Al-Failakawi',
          sex: Sex.male,
          password: 'Passw0rd!x',
          acceptedTerms: true,
          locale: WireLang.en,
        ),
      );
      final session = await a.repos.auth.verifyOtp(
        body: OtpVerifyInput(challengeId: challenge.challengeId, code: '123456'),
      );
      expect(session.user.user.sex, Sex.male);
      expect(session.user.user.name, 'Omar Al-Failakawi');
      expect(session.isNewUser, isTrue, reason: 'the first session of a registered account is new (the onboarding follows)');
    });

    test('sex is readable and editable in Profile (updateMe) and cannot be emptied', () async {
      final reem = w.actor('reem');
      final changed = await reem.repos.profile.updateMe(body: const UpdateMeInput(sex: Sex.male));
      expect(changed.user.sex, Sex.male);
      expect((await reem.repos.profile.getMe()).user.sex, Sex.male);
      final nulled = await raw(reem, 'PATCH', '/me', data: {'sex': null});
      expect(nulled.statusCode, 422);
      final wrong = await raw(reem, 'PATCH', '/me', data: {'sex': 'x'});
      expect(hasError(wrong, '/sex', 'invalid_enum'), isTrue);
    });

    test('a social sign-in starts an incomplete account too: completeProfile finishes it', () async {
      final a = w.actor('guest');
      final s = await a.repos.auth.signInWithGoogle(body: const SocialSignInInput(identityToken: 'plain-token'));
      expect(s.isNewUser, isTrue);
      expect(s.user.user.sex, isNull);
      final authed = w.actor('guest');
      await authed.tokens.write(AuthTokens(accessToken: s.accessToken, refreshToken: s.refreshToken));
      final me = await authed.repos.profile.completeProfile(
        body: const CompleteProfileInput(name: 'Layla', sex: Sex.female, acceptedTerms: true),
      );
      expect(me.user.sex, Sex.female);
      final next = await a.repos.auth.signInWithGoogle(body: const SocialSignInInput(identityToken: 'plain-token'));
      expect(next.isNewUser, isFalse);
    });
  });

  group('governorates are the client\'s region (CA-FLT-08, CA-ONB-10)', () {
    Future<List<Json>> rows(Actor a, Map<String, Object?> query) async {
      final r = await raw(a, 'GET', '/venues', query: {'limit': 50, ...query});
      expect(r.statusCode, 200, reason: '${r.data}');
      return ((body(r)['items'] as List)).map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    Set<String> governoratesOf(List<Json> items) => {for (final i in items) ((i['venue'] as Map)['governorateId'] as String)};

    test('GET /areas lists the six official governorates of Kuwait in Arabic and English: the configured list', () async {
      final areas = await w.actor('guest').repos.venues.listAreas();
      expect(areas.governorates.map((g) => g.id), ['capital', 'hawalli', 'farwaniya', 'ahmadi', 'jahra', 'mubarak-al-kabeer']);
      for (final g in areas.governorates) {
        expect(g.name.en, isNotEmpty);
        expect(g.name.ar, matches(RegExp(r'[؀-ۿ]')));
      }
      expect(areas.areas.every((a) => areas.governorates.any((g) => g.id == a.governorateId)), isTrue, reason: 'areas stay as addresses');
    });

    test('governorateIds: none or empty = all, one narrows, several = any of them, an unknown id matches nothing', () async {
      final a = w.actor('reem');
      final all = await rows(a, {});
      expect(governoratesOf(all).length, greaterThan(2));
      final hawalli = await rows(a, {
        'governorateIds': ['hawalli'],
      });
      expect(governoratesOf(hawalli), {'hawalli'});
      final two = await rows(a, {
        'governorateIds': ['hawalli', 'capital'],
      });
      expect(governoratesOf(two), {'hawalli', 'capital'});
      expect(two.length, greaterThan(hawalli.length));
      expect(
        await rows(a, {
          'governorateIds': ['no-such-governorate'],
        }),
        isEmpty,
      );
      final count = body(
        await raw(
          a,
          'GET',
          '/venues/count',
          query: {
            'governorateIds': ['hawalli', 'capital'],
          },
        ),
      )['count'];
      expect(count, two.length, reason: 'the live count follows the governorates');
    });

    test('briefGovernorateIds narrows by default; an explicit governorateIds, allAreas (the All governorates chip) or a shelf lifts it', () async {
      final a = w.actor('reem');
      final followBrief = await rows(a, {
        'briefGovernorateIds': ['farwaniya', 'jahra'],
      });
      expect(governoratesOf(followBrief), isNotEmpty);
      expect(governoratesOf(followBrief).difference({'farwaniya', 'jahra'}), isEmpty);
      expect(
        governoratesOf(
          await rows(a, {
            'briefGovernorateIds': ['farwaniya'],
            'governorateIds': ['hawalli'],
          }),
        ),
        {'hawalli'},
      );
      expect(
        governoratesOf(
          await rows(a, {
            'briefGovernorateIds': ['farwaniya'],
            'allAreas': true,
          }),
        ).length,
        greaterThan(2),
      );
      final shelf = await rows(a, {
        'briefGovernorateIds': ['farwaniya'],
        'shelf': 'recommended',
        'date': '2027-01-14',
        'guests': 350,
        'audience': 'women',
      });
      expect(governoratesOf(shelf).difference({'farwaniya'}), isNotEmpty, reason: 'a shelf ignores the Brief region');
    });

    test('the older areas keep working: an explicit area narrows, and areas apply only to a Brief without governorates', () async {
      final a = w.actor('reem');
      final salmiya = await rows(a, {
        'areaIds': ['salmiya'],
      });
      expect(salmiya, isNotEmpty);
      expect(salmiya.every((i) => (i['venue'] as Map)['areaId'] == 'salmiya'), isTrue);
      final briefAreas = await rows(a, {
        'briefAreaIds': ['salmiya'],
      });
      expect(briefAreas.every((i) => (i['venue'] as Map)['areaId'] == 'salmiya'), isTrue);
      // governorates win over the older Brief areas: Salmiya is in Hawalli, the Brief says Capital, the list is Capital
      final both = await rows(a, {
        'briefAreaIds': ['salmiya'],
        'briefGovernorateIds': ['capital'],
      });
      expect(governoratesOf(both), {'capital'});
    });

    test('Home follows the Brief governorates: the free count and the free shelf only hold halls of those governorates', () async {
      final a = w.actor('reem');
      final everywhere = await a.repos.home.getHome(date: LocalDate.parse('2027-01-14'), guests: 350, audience: Audience.women);
      final far = await a.repos.home.getHome(
        date: LocalDate.parse('2027-01-14'),
        guests: 350,
        audience: Audience.women,
        governorateIds: ['farwaniya', 'jahra'],
      );
      expect(far.freeCount, lessThan(everywhere.freeCount ?? 1 << 20));
      final free = far.shelves.where((s) => s.id == ShelfId.free).expand((s) => s.items).toList();
      expect(free, isNotEmpty);
      for (final item in free) {
        expect(['farwaniya', 'jahra'], contains(item.row.venue.governorateId));
      }
    });

    test('the wedding profile keeps governorateIds (empty = all governorates); Reem\'s Brief is Hawalli and Capital, and Home reads it', () async {
      final reem = w.actor('reem');
      final profile = await reem.repos.wedding.getWeddingProfile();
      expect(profile.governorateIds, ['hawalli', 'capital']);
      final nora = w.actor('new_client');
      final put = await nora.repos.wedding.putWeddingProfile(
        body: const WeddingProfileInput(role: WeddingRole.bride, brideName: 'Nora', governorateIds: ['ahmadi', 'jahra']),
      );
      expect(put.governorateIds, ['ahmadi', 'jahra']);
      final patched = await nora.repos.wedding.updateWeddingProfile(body: const WeddingProfileInput(governorateIds: []));
      expect(patched.governorateIds, isEmpty, reason: 'an empty list is every governorate');
      // Home with no Brief field: Reem's profile is the Brief, so the free shelf stays inside Hawalli and Capital
      final home = await reem.repos.home.getHome();
      final free = home.shelves.where((s) => s.id == ShelfId.free).expand((s) => s.items).toList();
      expect(free, isNotEmpty);
      for (final item in free) {
        expect(['hawalli', 'capital'], contains(item.row.venue.governorateId));
      }
    });

    test('the Services list narrows by governorate too (CL-SERV-02)', () async {
      final a = w.actor('reem');
      final all = await a.repos.services.listServiceProviders(limit: 50);
      final one = all.items.first.governorateId;
      final narrowed = await a.repos.services.listServiceProviders(governorateIds: [one], limit: 50);
      expect(narrowed.items, isNotEmpty);
      expect(narrowed.items.every((p) => p.governorateId == one), isTrue);
    });
  });

  group('partner application (PA-ACC-07, PA-ACC-08)', () {
    Json form({String type = 'service_provider', List<String> categories = const ['henna'], String? note, String? licence = 'KW-77120'}) => {
      'accountType': type,
      'name': {'en': 'Henna Studio', 'ar': 'استوديو حناء'},
      'categoryIds': categories,
      'otherCategoryNote': note,
      'governorateId': 'hawalli',
      'contactName': 'Aisha Al-Rashidi',
      'phone': '+96550009123',
      'email': 'hello@henna-studio.example',
      'description': 'Bridal and guest henna, home visits across Hawalli.',
      'licenceRef': licence,
    };

    Future<Response<Object?>> apply(Actor a, Json b) =>
        raw(a, 'POST', '/partner/account-type', data: b, headers: {'Idempotency-Key': 'k-${b.hashCode}-${DateTime.now().microsecondsSinceEpoch}'});

    test('an application starts pending: the account is under review and the applicant sees it in the session and in the account', () async {
      final p = w.actor('hotel_non_major');
      final r = await apply(p, form());
      expect(r.statusCode, 201, reason: '${r.data}');
      final me = PartnerMe.fromJson(body(r));
      final m = me.memberships.firstWhere((x) => x.application != null);
      expect(m.status, PartnerAccountStatus.underReview);
      expect(m.application!.status, ApplicationStatus.pending);
      expect(m.application!.submittedAt, isNotNull);
      expect(m.application!.decidedAt, isNull);
      expect(m.application!.rejectionReason, isNull);
      expect(m.application!.categoryIds, [ServiceCategoryId.henna]);
      expect(m.application!.otherCategoryNote, isNull);
      expect(m.application!.governorateId, 'hawalli');
      expect(m.application!.licenceRef, 'KW-77120');

      final mine = await p.repos.partnerAccount.getPartnerApplication();
      expect(mine.id, m.application!.id);
      final account = await w.actor('hotel_non_major', providerId: m.providerId).repos.partnerAccount.getPartnerAccount();
      expect(account.application?.status, ApplicationStatus.pending);
      expect(account.status, PartnerAccountStatus.underReview);
    });

    test(
      'the form is validated: every business field, a category or the Other note for a provider, at most three categories, a known governorate',
      () async {
        final p = w.actor('hotel_non_major');
        final empty = await apply(p, {
          'accountType': 'service_provider',
          'name': {'en': 'X', 'ar': ''},
        });
        expect((empty.statusCode, body(empty)['code']), (422, 'VALIDATION_FAILED'));
        for (final path in ['/name/ar', '/governorateId', '/contactName', '/phone', '/email', '/description', '/categoryIds']) {
          expect(hasError(empty, path, 'required'), isTrue, reason: '$path in ${errorsOf(empty)}');
        }
        final onlyNote = await apply(p, form(categories: const [], note: 'Live falcon show for the entrance'));
        expect(onlyNote.statusCode, 201, reason: 'the open Other note is enough (PA-ACC-08)');
        final application = PartnerMe.fromJson(body(onlyNote)).memberships.firstWhere((x) => x.application != null).application!;
        expect(application.otherCategoryNote, 'Live falcon show for the entrance');
        expect(application.categoryIds, isEmpty);
        final four = await apply(p, form(categories: const ['henna', 'dj', 'mc', 'cake']));
        expect(four.statusCode, 422);
        expect(hasError(four, '/categoryIds', 'too_many'), isTrue, reason: '${errorsOf(four)}');
        final badGov = await apply(p, {...form(), 'governorateId': 'atlantis'});
        expect(hasError(badGov, '/governorateId', 'unknown_governorate'), isTrue);
        final badCat = await apply(p, form(categories: const ['made_up']));
        expect(badCat.statusCode, 422);
        final hall = await apply(p, form(type: 'venue', categories: const []));
        expect(hall.statusCode, 201, reason: 'a private hall has no category');
      },
    );

    test(
      'only an accepted account can create listings: pending and rejected answer 403 APPLICATION_NOT_ACCEPTED; accept lets the listing through',
      () async {
        final p = w.actor('hotel_non_major');
        final m = PartnerMe.fromJson(body(await apply(p, form()))).memberships.firstWhere((x) => x.application != null);
        final owner = w.actor('hotel_non_major', providerId: m.providerId);
        const listing = ListingInput(
          title: LocalizedText(en: 'Henna Studio', ar: 'استوديو حناء'),
        );

        Future<Response<Object?>> create() => raw(
          owner,
          'POST',
          '/partner/listings',
          data: listing.toJson(),
          headers: {'Idempotency-Key': 'l-${DateTime.now().microsecondsSinceEpoch}'},
        );
        final pending = await create();
        expect((pending.statusCode, body(pending)['code']), (403, 'APPLICATION_NOT_ACCEPTED'));
        expect((body(pending)['params'] as Map)['applicationStatus'], 'pending');

        w.control.decidePartnerApplication(m.application!.id, accept: false, reason: 'Please add your licence number.');
        final rejected = await owner.repos.partnerAccount.getPartnerApplication();
        expect(rejected.status, ApplicationStatus.rejected);
        expect(rejected.rejectionReason?.en, 'Please add your licence number.');
        expect(rejected.rejectionReason?.ar, isNotEmpty);
        expect(rejected.decidedAt, isNotNull);
        expect((await owner.repos.partnerAccount.getPartnerAccount()).application?.status, ApplicationStatus.rejected);
        expect((await create()).statusCode, 403, reason: 'a rejected application is not an accepted one');
      },
    );

    test('edit and resubmit: only a rejected application, and it goes back to pending with the reason cleared', () async {
      final p = w.actor('hotel_non_major');
      final m = PartnerMe.fromJson(body(await apply(p, form()))).memberships.firstWhere((x) => x.application != null);
      final owner = w.actor('hotel_non_major', providerId: m.providerId);
      final edit = form(licence: 'KW-77121')..remove('accountType');

      final early = await raw(owner, 'PUT', '/partner/application', data: edit);
      expect((early.statusCode, body(early)['code']), (409, 'APPLICATION_NOT_EDITABLE'));
      expect(body(early)['currentStatus'], 'pending');

      w.control.decidePartnerApplication(m.application!.id, accept: false, reason: 'Add the licence number.');
      final bad = await raw(owner, 'PUT', '/partner/application', data: {...edit, 'contactName': ''});
      expect(bad.statusCode, 422, reason: 'the form is validated again');
      final resubmitted = await owner.repos.partnerAccount.resubmitPartnerApplication(
        body: PartnerApplicationInput(
          name: const LocalizedText(en: 'Henna Studio', ar: 'استوديو حناء'),
          categoryIds: const [ServiceCategoryId.henna],
          governorateId: 'hawalli',
          contactName: 'Aisha Al-Rashidi',
          phone: '+96550009123',
          email: 'hello@henna-studio.example',
          description: 'Bridal and guest henna, home visits across Hawalli.',
          licenceRef: 'KW-77121',
        ),
      );
      expect(resubmitted.status, ApplicationStatus.pending);
      expect(resubmitted.rejectionReason, isNull);
      expect(resubmitted.decidedAt, isNull);
      expect(resubmitted.licenceRef, 'KW-77121');
      expect(resubmitted.id, m.application!.id, reason: 'the same application, not a new one');

      final accepted = w.control.decidePartnerApplication(m.application!.id, accept: true);
      expect(accepted['status'], 'accepted');
      final created = await owner.repos.partnerListings.createListing(
        body: const ListingInput(
          title: LocalizedText(en: 'Henna Studio', ar: 'استوديو حناء'),
        ),
      );
      expect(created.status, ListingStatus.draft);
      final account = await owner.repos.partnerAccount.getPartnerAccount();
      expect((account.status, account.application?.status), (PartnerAccountStatus.active, ApplicationStatus.accepted));
      final late = await raw(owner, 'PUT', '/partner/application', data: edit);
      expect((late.statusCode, body(late)['code']), (409, 'APPLICATION_NOT_EDITABLE'), reason: 'an accepted application is final');
    });

    test('the staff decision is also a control endpoint: POST /__mock/applications/<id>/decide {action, reason}; only a pending application can be decided', () async {
      final p = w.actor('hotel_non_major');
      final m = PartnerMe.fromJson(body(await apply(p, form()))).memberships.firstWhere((x) => x.application != null);
      final id = m.application!.id;
      Future<Response<Object?>> decide(Object data) => raw(p, 'POST', 'http://mock.ghazal.local/__mock/applications/$id/decide', data: data);
      expect((await decide({'action': 'later'})).statusCode, 400);
      final rejected = await decide({'action': 'reject', 'reason': 'We do not list this service yet.'});
      expect(rejected.statusCode, 200);
      expect(body(rejected)['status'], 'rejected');
      expect((body(rejected)['rejectionReason'] as Map)['en'], 'We do not list this service yet.');
      final again = await decide({'action': 'accept'});
      expect((again.statusCode, body(again)['code']), (409, 'APPLICATION_NOT_EDITABLE'));
      final unknown = await raw(p, 'POST', 'http://mock.ghazal.local/__mock/applications/app-none/decide', data: {'action': 'accept'});
      expect(unknown.statusCode, 404);
    });

    test('existing partners stay accepted: no application, active accounts, listings can be created, and there is no application to read', () async {
      final zahra = w.actor('provider', providerId: 'vendor-flowers-zahra');
      final me = await zahra.repos.partnerAccount.getPartnerMe();
      expect(me.memberships.every((m) => m.application == null && m.status == PartnerAccountStatus.active), isTrue);
      final created = await zahra.repos.partnerListings.createListing(
        body: const ListingInput(
          title: LocalizedText(en: 'Zahra Spring', ar: 'زهرة الربيع'),
        ),
      );
      expect(created.status, ListingStatus.draft);
      final none = await raw(zahra, 'GET', '/partner/application');
      expect((none.statusCode, body(none)['code']), (404, 'NOT_FOUND'));
      final hind = w.actor('hotel_manager', venueId: 'V01');
      expect((await hind.repos.partnerAccount.getPartnerAccount()).application, isNull);
    });
  });

  group('seeded applicants', () {
    test('provider_applicant has a pending application and provider_rejected a rejected one with a reason in both languages', () async {
      final pending = (await w.actor('provider_applicant').repos.partnerAccount.getPartnerMe()).memberships.single;
      expect(pending.status, PartnerAccountStatus.underReview);
      expect(pending.application?.status, ApplicationStatus.pending);
      expect(pending.application?.categoryIds, [ServiceCategoryId.photography]);
      final rejected = (await w.actor('provider_rejected').repos.partnerAccount.getPartnerMe()).memberships.single;
      expect(rejected.status, PartnerAccountStatus.underReview);
      expect(rejected.application?.status, ApplicationStatus.rejected);
      expect(rejected.application?.rejectionReason?.en, isNotEmpty);
      expect(rejected.application?.rejectionReason?.ar, matches(RegExp(r'[\u0600-\u06FF]')));
      expect(rejected.application?.otherCategoryNote, isNotNull);
    });

    test('they sign in with their email like any partner, and a reset brings the same two back', () async {
      final a = w.actor('guest');
      final login = await a.repos.auth.partnerLogin(
        body: const PartnerLoginInput(email: 'rawan@rawan-lens.example', password: 'Ghazal#2026', deviceId: 'dev-rawan'),
      );
      expect(login.status, PartnerLoginStatus.codeRequired);
      await w.control.reset();
      final again = (await w.actor('provider_rejected').repos.partnerAccount.getPartnerApplication());
      expect(again.status, ApplicationStatus.rejected);
    });

    test('their listing call is refused until staff accept, then goes through', () async {
      final pending = w.actor('provider_applicant');
      final me = (await pending.repos.partnerAccount.getPartnerMe()).memberships.single;
      final owner = w.actor('provider_applicant', providerId: me.providerId);
      const listing = ListingInput(
        title: LocalizedText(en: 'Rawan Lens', ar: 'روان لينز'),
      );
      await expectLater(owner.repos.partnerListings.createListing(body: listing), throwsA(isA<ApiProblem>().having((e) => e.status, 'status', 403)));
      w.control.decidePartnerApplication(me.application!.id, accept: true);
      expect((await owner.repos.partnerListings.createListing(body: listing)).status, ListingStatus.draft);
    });
  });

  group('services are independent of venues (CA-SVC-19)', () {
    test('the venue detail and the partner package catalogue carry no extras, while the endpoints stay valid', () async {
      final detail = await w.actor('reem').repos.venues.getVenue(venueId: 'V01');
      expect(detail.extras, isEmpty);
      expect(detail.packages, isNotEmpty);
      final hind = w.actor('hotel_manager', venueId: 'V01');
      final catalogue = await hind.repos.partnerVenue.listPartnerPackages();
      expect(catalogue.extras, isEmpty);
      expect(catalogue.packages, isNotEmpty);
      // the deprecated calls still answer (additive contract): the extra is stored but no read lists it
      final extra = await hind.repos.partnerVenue.createExtra(
        body: const ExtraInput(
          category: ExtraCategory.lighting,
          name: LocalizedText(en: 'Extra lights', ar: 'إضاءة إضافية'),
          pricingUnit: PricingUnit.flat,
          price: MoneyAmount(150000),
          maxQty: 4,
        ),
      );
      expect(extra.id, isNotEmpty);
      expect((await hind.repos.partnerVenue.listPartnerPackages()).extras, isEmpty);
      expect((await w.actor('reem').repos.venues.getVenue(venueId: 'V01')).extras, isEmpty);
    });
  });

  group('configuration', () {
    test('the Client app note for service providers points to the Partner app store page kept in configuration (CA-SVC-20, OQ-R2-04)', () async {
      final config = await w.actor('guest').repos.home.getAppConfig();
      expect(config.partnerAppUrl, startsWith('https://'));
    });
  });
}
