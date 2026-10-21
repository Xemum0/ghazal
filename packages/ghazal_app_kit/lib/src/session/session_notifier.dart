import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../data/api_providers.dart';
import '../data/client_environment.dart';
import '../data/mock_backend.dart';
import '../nav/go_router_navigator.dart' show GoRouterNavigator;
import '../nav/nav_providers.dart' show gzNavigatorProvider;
import 'gate.dart';
import 'session_types.dart';

/// The one session of the running app. A guest until a sign-in flow (client OTP or password, partner email and code, staff invitation) or
/// the demo tools move it. Sign-out, a revoked session and a failed token refresh all return it to a guest.
final NotifierProvider<SessionNotifier, AppSession> sessionProvider = NotifierProvider<SessionNotifier, AppSession>(SessionNotifier.new);

final GzLogger _log = GzLogger('session');

class SessionNotifier extends Notifier<AppSession> {
  OtpChallenge? _challenge;
  bool _partnerChallenge = false;

  @override
  AppSession build() => const GuestSession();

  /// The open one-time-code challenge (the screen reads the resend timer and the destination hint from it).
  OtpChallenge? get challenge => _challenge;

  /// Replaces the session (tests, the demo tools).
  void setSession(AppSession session) => state = session;

  AuthUser _user(User u) => AuthUser(id: u.id, name: u.name, phone: u.phone, monogram: u.monogram, email: u.email);

  // ---------------------------------------------------------------------------------------------- client: OTP, password, restore

  /// Step 1 of the client sign-in: sends the code to [phone] (any Kuwaiti spelling, normalised to E.164). Returns the challenge.
  Future<OtpChallenge> requestOtp(String phone, {OtpPurpose purpose = OtpPurpose.login}) async {
    final e164 = PhoneKw.toE164(phone) ?? phone;
    final challenge = await ref
        .read(authRepositoryProvider)
        .requestOtp(
          body: OtpRequestInput(phone: e164, purpose: purpose, deviceId: ref.read(deviceIdProvider)),
        );
    _challenge = challenge;
    _partnerChallenge = false;
    return challenge;
  }

  /// Step 2: the code of the open challenge. Opens the session (a first-time number becomes a new client: `isNewUser`) and returns it.
  /// Throws `ApiProblem` (`OTP_INVALID`, `OTP_EXPIRED`, `OTP_LOCKED`); the challenge stays open for a retry.
  Future<ClientSession> verifyOtp(String code) async {
    final challenge = _challenge;
    if (challenge == null || _partnerChallenge) throw StateError('verifyOtp without requestOtp');
    final auth = await ref
        .read(authRepositoryProvider)
        .verifyOtp(
          body: OtpVerifyInput(challengeId: challenge.challengeId, code: code, deviceId: ref.read(deviceIdProvider)),
        );
    _challenge = null;
    return _adoptClient(auth);
  }

  /// Phone and password sign-in (CL-AUTH-04).
  Future<ClientSession> passwordLogin(String phone, String password) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .passwordLogin(
          body: PasswordLoginInput(phone: PhoneKw.toE164(phone) ?? phone, password: password, deviceId: ref.read(deviceIdProvider)),
        );
    return _adoptClient(auth);
  }

  Future<ClientSession> _adoptClient(AuthSession auth) async {
    await ref.read(tokenStoreProvider).write(AuthTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken));
    final session = ClientSession(user: _user(auth.user.user), isNewUser: auth.isNewUser, phoneVerified: auth.user.phoneVerified);
    state = session;
    completeGate();
    return session;
  }

  /// A sign-in finished: closes the gate sheet and the sign-in screens above the place the guest came from, then continues at the gate
  /// request's [GateResume] (a route name with its params), unless that screen is already the one showing. A landing the flow named
  /// (`signInLandingProvider`) wins: it replaces the stack (the router does the same when it sees the session change first).
  /// Does nothing without an open gate request or a landing.
  ///
  /// The navigator is read here, inside the callback, and the router follows the session through `ref.container` (see `buildGzRouter`),
  /// so the session provider is not part of the navigator's dependency chain.
  void completeGate() {
    final landing = ref.read(signInLandingProvider.notifier).take();
    if (ref.read(gateProvider) == null && landing == null) return;
    final resume = ref.read(gateProvider.notifier).takeResume();
    final nav = ref.read(gzNavigatorProvider);
    if (landing != null) {
      nav.reset(landing.routeName, params: landing.params);
      return;
    }
    closeAuthScreens();
    if (resume != null && nav.currentId != resume.routeName) nav.push(resume.routeName, params: resume.params);
  }

  /// Closes the gate sheet and the sign-in screens (`CL-AUTH-*`) at the top of the stack, without a gate request to resume. The router
  /// adapter does it in one step (`GoRouterNavigator.popWhile`); any other navigator pops one by one.
  void closeAuthScreens() {
    final nav = ref.read(gzNavigatorProvider);
    bool isAuth(String id) => id.startsWith('CL-AUTH-');
    if (nav is GoRouterNavigator) {
      nav.popWhile(isAuth);
      return;
    }
    var guard = 0;
    while (isAuth(nav.currentId) && nav.canGoBack && guard++ < 8) {
      if (nav.currentId == kGateSheetId) {
        nav.closeSheet();
      } else {
        nav.pop();
      }
    }
  }

  /// Opens the session kept in the token store (app start). A client, partner or no session; a refresh that fails leaves a guest.
  Future<AppSession> restore() async {
    final tokens = await ref.read(tokenStoreProvider).read();
    if (tokens == null) return state;
    try {
      final me = await ref.read(profileRepositoryProvider).getMe();
      final role = me.user.role;
      if (role == UserRole.hotelStaff || role == UserRole.providerStaff) {
        return state = await _partnerSessionFromServer(me.user);
      }
      return state = ClientSession(user: _user(me.user), phoneVerified: me.phoneVerified);
    } on ApiProblem catch (e) {
      _log.warning('restore failed: ${e.code.wire}');
      if (e.status == 401 || e.requiresSignOut) await _forget();
      return state;
    }
  }

  // ---------------------------------------------------------------------------------------------- partner: email, code, invitation

  /// Partner sign-in (HL-ACCS-01). A known device opens the session; a new device answers `codeRequired` and a code is emailed: continue
  /// with [partnerVerifyCode]. Returns the server answer.
  Future<PartnerLoginResult> partnerLogin(String email, String password) async {
    final result = await ref
        .read(authRepositoryProvider)
        .partnerLogin(
          body: PartnerLoginInput(email: email.trim(), password: password, deviceId: ref.read(deviceIdProvider)),
        );
    final session = result.session;
    if (result.status == PartnerLoginStatus.signedIn && session != null) {
      await _adoptPartner(session);
    } else {
      _challenge = result.challenge;
      _partnerChallenge = true;
    }
    return result;
  }

  /// The emailed code of a new device (HL-ACCS-02).
  Future<PartnerSession> partnerVerifyCode(String code) async {
    final challenge = _challenge;
    if (challenge == null || !_partnerChallenge) throw StateError('partnerVerifyCode without partnerLogin');
    final auth = await ref
        .read(authRepositoryProvider)
        .partnerVerifyCode(
          body: OtpVerifyInput(challengeId: challenge.challengeId, code: code, deviceId: ref.read(deviceIdProvider)),
        );
    _challenge = null;
    return _adoptPartner(auth);
  }

  /// Who invited you, before choosing a password (HL-ACCS-03). Throws `INVITATION_EXPIRED`.
  Future<InvitationPreview> invitationPreview(String token) => ref.read(authRepositoryProvider).getStaffInvitationPreview(token: token);

  /// Accepts the emailed invitation: sets the password and signs in (HL-ACCS-03).
  Future<PartnerSession> acceptInvitation({required String token, required String password, bool acceptedTerms = true}) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .acceptStaffInvitation(
          body: AcceptInvitationInput(token: token, password: password, acceptedTerms: acceptedTerms, deviceId: ref.read(deviceIdProvider)),
        );
    return _adoptPartner(auth);
  }

  Future<PartnerSession> _adoptPartner(AuthSession auth) async {
    await ref.read(tokenStoreProvider).write(AuthTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken));
    final session = await _partnerSessionFromServer(auth.user.user);
    state = session;
    return session;
  }

  Future<PartnerSession> _partnerSessionFromServer(User user, {PartnerMe? known}) async {
    final me = known ?? await ref.read(partnerAccountRepositoryProvider).getPartnerMe();
    final active = me.active;
    final memberships = me.memberships;
    if (memberships.isEmpty) {
      return PartnerSession(user: _user(user), accountType: PartnerAccountType.unknown, role: StaffRole.unknown);
    }
    final m = memberships.firstWhere((m) => active != null && m.accountId == active.accountId, orElse: () => memberships.first);
    return PartnerSession(
      user: _user(me.user),
      accountType: m.accountType,
      role: m.role,
      accountId: m.accountId,
      venueId: m.venueId,
      providerId: m.providerId,
      accountName: m.accountName,
      feeExempt: m.feeExempt,
      permissions: m.permissions,
    );
  }

  /// Chooses another account of the same staff member (a person who works for two venues): the next calls carry its id.
  Future<PartnerSession> switchPartnerContext(String accountId, {String? venueId, String? providerId}) async {
    if (state is! PartnerSession) throw StateError('switchPartnerContext without a partner session');
    final me = await ref
        .read(partnerAccountRepositoryProvider)
        .switchPartnerContext(
          body: SwitchContextInput(accountId: accountId, venueId: venueId, providerId: providerId),
        );
    final session = await _partnerSessionFromServer(me.user, known: me);
    state = session;
    return session;
  }

  // ---------------------------------------------------------------------------------------------- end of session

  /// Sign-out: tells the server (best effort), forgets the tokens, back to a guest.
  Future<void> signOut() async {
    final tokens = await ref.read(tokenStoreProvider).read();
    try {
      if (tokens != null) await ref.read(authRepositoryProvider).signOut(body: LogoutInput(refreshToken: tokens.refreshToken));
    } on ApiProblem catch (e) {
      _log.warning('sign-out call failed: ${e.code.wire}');
    }
    await _forget();
  }

  /// The client stack gave up on the session (the refresh token was rejected or reused): no server call, just forget.
  void endedByServer() {
    if (!state.isSignedIn) return;
    _log.info('session ended by the server');
    _forget();
  }

  Future<void> _forget() async {
    _challenge = null;
    await ref.read(tokenStoreProvider).clear();
    state = const GuestSession();
    ref.read(gateProvider.notifier).dismiss();
  }

  // ---------------------------------------------------------------------------------------------- mock personas (demo tools, shot harness)

  /// Mock only: becomes [persona] (`guest`, `new_client`, `reem`, `hotel_admin`, `hotel_manager`, `hotel_non_major`, `provider`) with real
  /// tokens of that persona's session. Returns the new session. Does nothing but return the current one when no in-process mock runs.
  Future<AppSession> loadPersona(String persona) async {
    final mock = ref.read(mockBackendProvider);
    if (mock == null) return state;
    final store = ref.read(tokenStoreProvider);
    if (persona == 'guest') {
      await store.clear();
      mock.control.setPersona('guest');
      _challenge = null;
      return state = const GuestSession();
    }
    final tokens = mock.control.sessionFor(persona);
    await store.write(AuthTokens(accessToken: tokens['accessToken']! as String, refreshToken: tokens['refreshToken']! as String));
    mock.control.setPersona('guest');
    final restored = await restore();
    return restored;
  }
}
