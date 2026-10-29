// Round 2b (OQ-R2-11, docs/engineering/round2-change-brief.md): the partner application is PUBLIC. `submitPartnerApplication` (POST /partner/applications, no
// session) creates the applicant's account, the pending application and an email verification challenge; `partnerVerifyCode` answers it. Each test names
// the rule it pins in docs/architecture/mock-api.md ("Round 2b").
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show Json;

import 'harness.dart';

Future<Response<Object?>> raw(Actor a, String method, String path, {Object? data, Map<String, Object?>? headers}) => a.dio.request<Object?>(
  path,
  data: data,
  options: Options(method: method, headers: headers, validateStatus: (_) => true),
);

Json body(Response<Object?> r) => (r.data as Map).cast<String, dynamic>();

List<Json> errorsOf(Response<Object?> r) => ((body(r)['errors'] as List?) ?? const []).map((e) => (e as Map).cast<String, dynamic>()).toList();

bool hasError(Response<Object?> r, String path, String code) => errorsOf(r).any((e) => e['path'] == path && e['code'] == code);

void main() {
  late World w;
  setUp(() async => w = await World.create());

  const email = 'Aisha@Henna-Studio.example';
  const password = 'Henna#2026!';

  Json application({List<String> categories = const ['henna'], String? note, String contactEmail = 'hello@henna-studio.example'}) => {
    'name': {'en': 'Henna Studio', 'ar': 'استوديو حناء'},
    'categoryIds': categories,
    'otherCategoryNote': note,
    'governorateId': 'hawalli',
    'contactName': 'Aisha Al-Rashidi',
    'phone': '+96550009123',
    'email': contactEmail,
    'description': 'Bridal and guest henna, home visits across Hawalli.',
    'licenceRef': 'KW-77120',
  };

  Json submission({String type = 'service_provider', String accountEmail = email, String pass = password, Json? app}) => {
    'account': {'email': accountEmail, 'password': pass, 'locale': 'ar'},
    'accountType': type,
    'application': app ?? application(categories: type == 'venue' ? const [] : const ['henna']),
  };

  Future<Response<Object?>> submit(Actor a, Json b, {String? key}) =>
      raw(a, 'POST', '/partner/applications', data: b, headers: {'Idempotency-Key': key ?? 'k-${DateTime.now().microsecondsSinceEpoch}'});

  /// The verification code the mock "emailed" for [to] (the outbox entry of the application).
  String codeFor(String to) => w.control.outbox.lastWhere((m) => m['kind'] == 'partner_application_verify' && m['to'] == to)['code'] as String;

  Future<AuthSession> verify(Actor guest, String challengeId, String code, {String? deviceId}) => guest.repos.auth.partnerVerifyCode(
    body: OtpVerifyInput(challengeId: challengeId, code: code, deviceId: deviceId),
  );

  Actor signedIn(AuthSession s, {String? providerId}) => w.actorWithTokens(
    AuthTokens(accessToken: s.accessToken, refreshToken: s.refreshToken),
    providerId: providerId,
  );

  group('the public application (OQ-R2-11)', () {
    test('lifecycle: submit with no session, the code lands in the outbox, verify opens a session with the application pending, staff accept, a listing is allowed', () async {
      final guest = w.actor('guest');
      final r = await submit(guest, submission());
      expect(r.statusCode, 202, reason: '${r.data}');
      final challenge = OtpChallenge.fromJson(body(r));
      expect(challenge.channel, OtpChannel.email);
      expect(challenge.codeLength, 6);
      expect(challenge.destinationHint, isNot(contains('henna-studio')), reason: 'the hint is masked');

      final mail = w.control.outbox.lastWhere((m) => m['kind'] == 'partner_application_verify');
      expect((mail['to'], mail['challengeId'], mail['code']), (email, challenge.challengeId, '123456'));

      // No session yet: the signed-in endpoints refuse the guest.
      expect((await raw(guest, 'GET', '/partner/application')).statusCode, 401);

      final session = await verify(guest, challenge.challengeId, codeFor(email), deviceId: 'dev-aisha');
      expect(session.user.user.email, email);
      expect(session.user.emailVerified, isTrue);
      expect(session.isNewUser, isFalse);

      final applicant = signedIn(session);
      final me = await applicant.repos.partnerAccount.getPartnerMe();
      final m = me.memberships.single;
      expect((m.accountType, m.status), (PartnerAccountType.serviceProvider, PartnerAccountStatus.underReview));
      expect(m.venueId, isNull, reason: 'no venue membership');
      expect(m.providerId, isNotNull);
      expect(m.application?.status, ApplicationStatus.pending);
      expect(m.application?.email, 'hello@henna-studio.example', reason: 'the contact email is its own field');
      expect(m.application?.categoryIds, [ServiceCategoryId.henna]);
      expect(me.active?.accountId, m.accountId, reason: 'the single account is the active context');

      final mine = await applicant.repos.partnerAccount.getPartnerApplication();
      expect((mine.id, mine.status, mine.accountId), (m.application!.id, ApplicationStatus.pending, m.accountId));

      // Pending: listings are refused (APPLICATION_NOT_ACCEPTED); accept lets them through.
      final owner = signedIn(session, providerId: m.providerId);
      const listing = ListingInput(
        title: LocalizedText(en: 'Henna Studio', ar: 'استوديو حناء'),
      );
      Future<Response<Object?>> create() =>
          raw(owner, 'POST', '/partner/listings', data: listing.toJson(), headers: {'Idempotency-Key': 'l-${DateTime.now().microsecondsSinceEpoch}'});
      final early = await create();
      expect((early.statusCode, body(early)['code']), (403, 'APPLICATION_NOT_ACCEPTED'));
      expect((body(early)['params'] as Map)['applicationStatus'], 'pending');

      w.control.decidePartnerApplication(mine.id, accept: true);
      expect((await create()).statusCode, 201);
      final account = await owner.repos.partnerAccount.getPartnerAccount();
      expect((account.status, account.application?.status), (PartnerAccountStatus.active, ApplicationStatus.accepted));
    });

    test('a private hall applies too: no category needed, no venue and no provider until staff set the hall up', () async {
      final guest = w.actor('guest');
      final r = await submit(guest, submission(type: 'venue', accountEmail: 'owner@palms-hall.example'));
      expect(r.statusCode, 202, reason: '${r.data}');
      final session = await verify(guest, OtpChallenge.fromJson(body(r)).challengeId, '123456');
      final m = (await signedIn(session).repos.partnerAccount.getPartnerMe()).memberships.single;
      expect((m.accountType, m.status, m.venueId, m.providerId), (PartnerAccountType.venue, PartnerAccountStatus.underReview, null, null));
      expect(m.application?.accountType, PartnerAccountType.venue);
      expect(m.application?.categoryIds, isEmpty);
    });

    test('the email is the sign-in name: the chosen password signs in (the standard one does not), a new device asks for a code, the verified device does not', () async {
      final guest = w.actor('guest');
      final c = OtpChallenge.fromJson(body(await submit(guest, submission())));
      await verify(guest, c.challengeId, '123456', deviceId: 'dev-aisha');

      final same = await guest.repos.auth.partnerLogin(
        body: const PartnerLoginInput(email: 'aisha@henna-studio.example', password: password, deviceId: 'dev-aisha'),
      );
      expect(same.status, PartnerLoginStatus.signedIn, reason: 'the device that verified is known; the email is case-insensitive');
      expect(same.session?.user.user.email, email);
      final other = await guest.repos.auth.partnerLogin(
        body: const PartnerLoginInput(email: email, password: password, deviceId: 'dev-other'),
      );
      expect(other.status, PartnerLoginStatus.codeRequired);
      final bad = await raw(guest, 'POST', '/auth/partner/login', data: {'email': email, 'password': 'Ghazal#2026', 'deviceId': 'dev-aisha'});
      expect((bad.statusCode, body(bad)['code']), (401, 'CREDENTIALS_INVALID'));
    });

    test(
      'an applicant who never entered the code signs in with the password and verifies the new device: the application is waiting, pending',
      () async {
        final guest = w.actor('guest');
        await submit(guest, submission());
        final login = await guest.repos.auth.partnerLogin(
          body: const PartnerLoginInput(email: email, password: password, deviceId: 'dev-late'),
        );
        expect(login.status, PartnerLoginStatus.codeRequired);
        final session = await verify(guest, login.challenge!.challengeId, '123456', deviceId: 'dev-late');
        final application = await signedIn(session).repos.partnerAccount.getPartnerApplication();
        expect(application.status, ApplicationStatus.pending);
      },
    );

    test('the code is checked like partner sign-in: 222222 is wrong with the attempts left, 111111 expired, 000000 locked', () async {
      final guest = w.actor('guest');
      final c = OtpChallenge.fromJson(body(await submit(guest, submission())));
      Future<Response<Object?>> check(String code) => raw(guest, 'POST', '/auth/partner/verify', data: {'challengeId': c.challengeId, 'code': code});
      final wrong = await check('222222');
      expect((wrong.statusCode, body(wrong)['code']), (400, 'OTP_INVALID'));
      expect((body(wrong)['params'] as Map)['remainingAttempts'], 4);
      expect((await check('111111')).statusCode, 410);
      expect((await check('000000')).statusCode, 423);
    });

    test('rejected: the applicant sees the reason after signing in, edits and resubmits, staff accept, the account is active', () async {
      final guest = w.actor('guest');
      final c = OtpChallenge.fromJson(body(await submit(guest, submission())));
      final session = await verify(guest, c.challengeId, '123456', deviceId: 'dev-aisha');
      final applicant = signedIn(session);
      final id = (await applicant.repos.partnerAccount.getPartnerApplication()).id;

      w.control.decidePartnerApplication(id, accept: false, reason: 'Please add your licence number.');
      final seen = await applicant.repos.partnerAccount.getPartnerApplication();
      expect((seen.status, seen.rejectionReason?.en), (ApplicationStatus.rejected, 'Please add your licence number.'));
      expect(seen.rejectionReason?.ar, isNotEmpty);

      // A second public submit with the same email is refused: sign in and use the signed-in resubmit.
      final again = await submit(guest, submission());
      expect((again.statusCode, body(again)['code']), (409, 'EMAIL_ALREADY_REGISTERED'));

      final resubmitted = await applicant.repos.partnerAccount.resubmitPartnerApplication(
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
      expect((resubmitted.id, resubmitted.status), (id, ApplicationStatus.pending));
      expect(resubmitted.rejectionReason, isNull);
      expect(w.control.decidePartnerApplication(id, accept: true)['status'], 'accepted');
      expect((await applicant.repos.partnerAccount.getPartnerApplication()).status, ApplicationStatus.accepted);
    });

    test('a second submit with the same email is 409 EMAIL_ALREADY_REGISTERED: its own, any case, any seeded partner, a rejected applicant, a colleague on a team', () async {
      final guest = w.actor('guest');
      expect((await submit(guest, submission())).statusCode, 202);
      for (final dup in [email, 'aisha@henna-studio.example', '  AISHA@HENNA-STUDIO.EXAMPLE ']) {
        final r = await submit(guest, submission(accountEmail: dup.trim()));
        expect((r.statusCode, body(r)['code']), (409, 'EMAIL_ALREADY_REGISTERED'), reason: dup);
        expect(r.headers.value('content-type'), contains('application/problem+json'));
        expect(body(r)['status'], 409);
      }
      // The seeded partners and applicants (rejected Bader, pending Rawan) are registered too.
      for (final seeded in ['bader@bader-decor.example', 'rawan@rawan-lens.example']) {
        final r = await submit(guest, submission(accountEmail: seeded));
        expect((r.statusCode, body(r)['code']), (409, 'EMAIL_ALREADY_REGISTERED'), reason: seeded);
      }
      final manager = w.actor('hotel_admin', venueId: 'V01');
      await manager.repos.partnerAccount.inviteStaff(
        body: const InviteStaffInput(email: 'new.reception@aurelia-gulf.example', role: StaffRole.reception),
      );
      // A colleague a hotel invited is on that team already (the email is unique across partner accounts and teams).
      final invited = await submit(guest, submission(accountEmail: 'new.reception@aurelia-gulf.example'));
      expect((invited.statusCode, body(invited)['code']), (409, 'EMAIL_ALREADY_REGISTERED'));
    });

    test('422 VALIDATION_FAILED names every failing field under /account and /application, and nothing is created', () async {
      final guest = w.actor('guest');
      final empty = await submit(guest, {
        'account': {'email': 'not-an-email', 'password': 'short', 'locale': 'ar'},
        'accountType': 'service_provider',
        'application': {
          'name': {'en': 'X', 'ar': ''},
          'phone': '+96550009123',
          'email': 'hello@henna-studio.example',
        },
      });
      expect((empty.statusCode, body(empty)['code']), (422, 'VALIDATION_FAILED'));
      expect(errorsOf(empty).any((e) => e['path'] == '/account/email'), isTrue, reason: '${errorsOf(empty)}');
      expect(errorsOf(empty).any((e) => e['path'] == '/account/password'), isTrue, reason: '${errorsOf(empty)}');
      for (final path in ['/application/governorateId', '/application/contactName', '/application/description']) {
        expect(errorsOf(empty).any((e) => e['path'] == path), isTrue, reason: '$path in ${errorsOf(empty)}');
      }

      // Every required field present but blank: the form rules of the account type answer (the same checks as the signed-in form).
      final blank = await submit(
        guest,
        submission(
          app: {
            ...application(categories: const []),
            'name': {'en': 'Henna Studio', 'ar': ''},
          },
        ),
      );
      expect((blank.statusCode, body(blank)['code']), (422, 'VALIDATION_FAILED'));
      expect(hasError(blank, '/application/name/ar', 'required'), isTrue, reason: '${errorsOf(blank)}');
      expect(
        hasError(blank, '/application/categoryIds', 'required'),
        isTrue,
        reason: 'a provider needs a category or the Other note: ${errorsOf(blank)}',
      );

      final missingAccount = await submit(guest, {'accountType': 'venue', 'application': application(categories: const [])});
      expect(missingAccount.statusCode, 422);
      expect(errorsOf(missingAccount).any((e) => e['path'] == '/account'), isTrue, reason: '${errorsOf(missingAccount)}');

      final four = await submit(guest, submission(app: application(categories: const ['henna', 'dj', 'mc', 'cake'])));
      expect(four.statusCode, 422);
      expect(hasError(four, '/application/categoryIds', 'too_many'), isTrue, reason: '${errorsOf(four)}');
      final badGov = await submit(guest, submission(app: {...application(), 'governorateId': 'atlantis'}));
      expect(hasError(badGov, '/application/governorateId', 'unknown_governorate'), isTrue, reason: '${errorsOf(badGov)}');
      final badCat = await submit(guest, submission(app: application(categories: const ['made_up'])));
      expect(badCat.statusCode, 422);
      final badType = await submit(guest, submission(type: 'hotel'));
      expect(badType.statusCode, 422);
      expect(errorsOf(badType).any((e) => e['path'] == '/accountType'), isTrue, reason: '${errorsOf(badType)}');
      final onlyNote = await submit(
        guest,
        submission(
          accountEmail: 'note@falcons.example',
          app: application(categories: const [], note: 'Live falcon show'),
        ),
      );
      expect(onlyNote.statusCode, 202, reason: 'the open Other note is enough (PA-ACC-08)');

      // None of the refused calls created the user: the email is still free.
      expect((await submit(guest, submission())).statusCode, 202);
    });

    test('rate limit: more than five codes to one email inside a minute is 429 RATE_LIMITED and creates nothing', () async {
      final guest = w.actor('guest');
      for (var i = 0; i < 5; i++) {
        await guest.repos.auth.partnerForgotPassword(body: const PartnerPasswordForgotInput(email: email));
      }
      final r = await submit(guest, submission());
      expect((r.statusCode, body(r)['code']), (429, 'RATE_LIMITED'));
      expect(r.headers.value('retry-after'), '60');
      final login = await raw(guest, 'POST', '/auth/partner/login', data: {'email': email, 'password': password});
      expect(login.statusCode, 401, reason: 'no user was created by the refused call');
      w.control.advance(const Duration(minutes: 2));
      expect((await submit(guest, submission())).statusCode, 202, reason: 'the minute passed');
    });

    test(
      'idempotency: the same key and body replays the first answer (one account), another body under the key is 422, a new key is the 409',
      () async {
        final guest = w.actor('guest');
        final first = await submit(guest, submission(), key: 'apply-1');
        final replay = await submit(guest, submission(), key: 'apply-1');
        expect((first.statusCode, replay.statusCode), (202, 202));
        expect(replay.headers.value('idempotent-replayed'), 'true');
        expect(body(replay)['challengeId'], body(first)['challengeId']);
        expect(w.control.outbox.where((m) => m['kind'] == 'partner_application_verify').length, 1, reason: 'one email, not two');
        final reused = await submit(guest, submission(accountEmail: 'other@henna-studio.example'), key: 'apply-1');
        expect((reused.statusCode, body(reused)['code']), (422, 'IDEMPOTENCY_KEY_REUSED'));
        final fresh = await submit(guest, submission(), key: 'apply-2');
        expect((fresh.statusCode, body(fresh)['code']), (409, 'EMAIL_ALREADY_REGISTERED'));
      },
    );

    test('a client or a leftover token does not matter: the operation is public (no AUTH_REQUIRED, no partner header)', () async {
      final r = await submit(w.actor('reem'), submission());
      expect(r.statusCode, 202, reason: '${r.data}');
    });

    test('a reset brings the world back: the applicant is gone and the email is free again', () async {
      final guest = w.actor('guest');
      expect((await submit(guest, submission())).statusCode, 202);
      await w.control.reset();
      expect((await submit(guest, submission())).statusCode, 202);
    });
  });
}
