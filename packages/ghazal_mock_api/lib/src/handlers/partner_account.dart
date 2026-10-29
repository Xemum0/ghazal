/// partner-account: the partner session (memberships, context), account type, staff and invitations, notification preferences.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../db/mock_db.dart';
import '../domain/applications.dart';
import '../domain/notify.dart';
import '../engine/engine.dart';
import 'auth.dart' show newChallenge, partnerByEmail;
import 'common.dart';
import 'partner_common.dart';

Json _roleLabel(String role) => {
  'en': role[0].toUpperCase() + role.substring(1),
  'ar': const {'admin': 'المالك', 'manager': 'مدير', 'reception': 'الاستقبال', 'accountant': 'المحاسبة', 'marketing': 'التسويق'}[role] ?? role,
};
Json _roleSummary(String role) => {
  'admin': {'en': 'Admin: everything, including staff and billing', 'ar': 'المالك: كل الصلاحيات بما فيها الموظفون والفواتير'},
  'manager': {'en': 'Manager: requests, calendar, listing and prices', 'ar': 'مدير: الطلبات والتقويم والإعلان والأسعار'},
  'reception': {'en': 'Reception: redeem vouchers, visits and calendar', 'ar': 'الاستقبال: استخدام الكوبونات والزيارات والتقويم'},
  'accountant': {'en': 'Accountant: reports and billing', 'ar': 'المحاسبة: التقارير والفواتير'},
  'marketing': {'en': 'Marketing: listing, voucher prices and reviews', 'ar': 'التسويق: الإعلان وأسعار الكوبون والتقييمات'},
}[role]!;

int _pending(MockApp app, Membership m) =>
    m.pendingRequests ??
    app.db.raw('Booking').where((b) => b['status'] == 'pending' && (m.venueId != null ? b['venueId'] == m.venueId : b['providerId'] == m.providerId)).length;

Json _membership(MockApp app, Membership m) => {
  'accountId': m.accountId,
  'accountType': m.accountType,
  'accountName': m.accountName,
  'venueId': m.venueId,
  'providerId': m.providerId,
  'role': m.role,
  'permissions': rolePermissions[m.role] ?? const <String>[],
  'pendingRequests': _pending(app, m),
  'feeExempt': m.feeExempt,
  'status': m.status,
  'application': _applicationView(app, m.accountId),
};

/// The application of an account in its wire shape (null when the account was assigned by Ghazal).
Json? _applicationView(MockApp app, String accountId) {
  final a = applicationOfAccount(app, accountId);
  return a == null ? null : wire(a);
}

Json _partnerMe(MockApp app, Req r) {
  final ms = app.membershipsOf(r.userId);
  final session = app.db.peek('Session', r.identity!.sessionId);
  var ctx = session?.objOrNull('context');
  ctx ??= ms.length == 1 ? {'accountId': ms.first.accountId, 'venueId': ms.first.venueId, 'providerId': ms.first.providerId} : null;
  return {
    'user': publicUser(app.requireUser(r.userId)),
    'memberships': [for (final m in ms) _membership(app, m)],
    'active': ctx,
  };
}

Json _staffView(MockApp app, Json s, String viewer) => {
  ...wire(s),
  'isYou': s['userId'] == viewer,
  'invitedByName': invitedByName(app, s.strOrNull('invitedBy')),
};

int _activeAdmins(MockApp app, String venueId) =>
    app.db.raw('StaffMember').where((s) => s['venueId'] == venueId && s['role'] == 'admin' && s['status'] == 'active').length;

Json _staff(MockApp app, Req r) {
  final s = app.db.get('StaffMember', r.p('staffId'));
  if (s == null || s['venueId'] != r.ctx.venueId) throw ApiError.notFound('staff member');
  return s;
}

/// The application the caller is working on: the one of the context account, else their own latest one.
Json _ownApplication(MockApp app, Req r) {
  final ctxAccount = app.db.peek('Session', r.identity!.sessionId)?.objOrNull('context')?['accountId'];
  final mine = app.db.raw('PartnerApplication').where((a) => a['_userId'] == r.userId).toList();
  final pick =
      mine.cast<Json?>().firstWhere((a) => a!['accountId'] == ctxAccount, orElse: () => null) ?? (mine.isEmpty ? null : mine.last);
  if (pick == null) throw ApiError.notFound('application');
  return deepCopy(pick);
}

/// One partner account per email: an existing partner user (personas, accepted staff, applicants of any status) or a colleague already on a team.
bool _emailTaken(MockApp app, String email) {
  final e = email.trim().toLowerCase();
  return partnerByEmail(app, e) != null || app.db.raw('StaffMember').any((s) => (s['email'] as String?)?.toLowerCase() == e);
}

Map<String, Handler> partnerAccountHandlers(MockApp app) => {
  'getPartnerMe': (r) => _partnerMe(app, r),
  'chooseAccountType': (r) {
    final created = submitApplication(app, userId: r.userId, accountType: r.b.str('accountType'), form: r.b);
    final accountId = created.accountId, providerId = created.providerId, type = r.b.str('accountType');
    final session = app.db.get('Session', r.identity!.sessionId);
    if (session != null) {
      session['context'] = {'accountId': accountId, 'venueId': null, 'providerId': providerId};
      app.db.put('Session', session);
    }
    app.logEvent('partner_account_created', {'accountId': accountId, 'type': type});
    return _partnerMe(app, r);
  },
  // The public application (round 2b, OQ-R2-11): no session. Order matters: the business information (422), then the email (409), then the code
  // (429 creates nothing), then the user, the account and the pending application. The code goes to the outbox as `partner_application_verify`;
  // `partnerVerifyCode` answers it and opens the session (no venue, application `pending`).
  'submitPartnerApplication': (r) {
    final account = r.b.obj('account');
    final accountType = r.b.str('accountType');
    final form = r.b.obj('application');
    final email = account.str('email').trim();
    checkApplicationForm(app, form, accountType, at: '/application');
    if (_emailTaken(app, email)) throw ApiError('EMAIL_ALREADY_REGISTERED');
    final userId = 'user-a${app.db.next('user').toString().padLeft(3, '0')}';
    final challenge = newChallenge(
      app,
      purpose: 'verify_email',
      channel: 'email',
      destination: email,
      userId: userId,
      outboxKind: 'partner_application_verify',
    );
    final contact = form.str('contactName').trim();
    app.db.put('User', {
      'id': userId,
      'role': accountType == 'venue' ? 'hotel_staff' : 'provider_staff',
      'name': contact,
      'nameLatin': null,
      'monogram': contact.isEmpty ? '?' : String.fromCharCode(contact.runes.first).toUpperCase(),
      'phone': form['phone'],
      'email': email,
      'locale': account.str('locale'),
      'digitStyle': 'western',
      'createdAt': app.now,
      '_email': email.toLowerCase(),
      '_password': account.str('password'),
      '_phoneVerified': true,
      '_emailVerified': false,
    });
    final created = submitApplication(app, userId: userId, accountType: accountType, form: form, at: '/application');
    app.logEvent('partner_application_submitted', {'applicationId': created.application['id'], 'accountId': created.accountId, 'type': accountType});
    return challenge;
  },
  'switchPartnerContext': (r) {
    final ms = app.membershipsOf(r.userId);
    final m =
        ms.cast<Membership?>().firstWhere(
          (x) => x!.accountId == r.b['accountId'] && x.venueId == r.b['venueId'] && x.providerId == r.b['providerId'],
          orElse: () => null,
        ) ??
        ms.cast<Membership?>().firstWhere((x) => x!.accountId == r.b['accountId'], orElse: () => null) ??
        (throw ApiError.forbidden('no membership for this account'));
    final session = app.db.get('Session', r.identity!.sessionId)!;
    session['context'] = {'accountId': m.accountId, 'venueId': m.venueId, 'providerId': m.providerId};
    app.db.put('Session', session);
    return _partnerMe(app, r);
  },
  'getPartnerAccount': (r) {
    final account = partnerAccountOf(app, r);
    return {...wire(account), 'application': _applicationView(app, account.str('id'))};
  },
  'getPartnerApplication': (r) => wire(_ownApplication(app, r)),
  'resubmitPartnerApplication': (r) {
    final a = _ownApplication(app, r);
    if (a['status'] != 'rejected') throw ApiError('APPLICATION_NOT_EDITABLE', currentStatus: a.str('status'));
    checkApplicationForm(app, r.b, a.str('accountType'));
    final next = {
      ...a,
      ...applicationFields(r.b),
      'status': 'pending',
      'rejectionReason': null,
      'submittedAt': app.now,
      'decidedAt': null,
    };
    app.db.put('PartnerApplication', next);
    final account = app.db.get('PartnerAccount', a.str('accountId'));
    if (account != null) {
      account['name'] = next['name'];
      app.db.put('PartnerAccount', account);
      applyApplicationToProvider(app, account.strOrNull('providerId'), next);
    }
    app.logEvent('partner_application_resubmitted', {'applicationId': a['id'], 'accountId': a['accountId']});
    return wire(next);
  },
  'listStaff': (r) {
    final venueId = r.ctx.venueId;
    if (venueId == null) return {'staff': <Json>[], 'invitations': <Json>[]};
    final staff = app.db.raw('StaffMember').where((s) => s['venueId'] == venueId).toList();
    final inv = stableSorted(app.db.raw('StaffInvitation').where((i) => i['venueId'] == venueId), (a, b) => b.str('sentAt').compareTo(a.str('sentAt')));
    return {
      'staff': [for (final s in staff) _staffView(app, s, r.userId)],
      'invitations': [for (final i in inv) invitationView(app, i)],
    };
  },
  'inviteStaff': (r) {
    app.requirePermission(r, 'staff:manage');
    final venueId = r.ctx.venueId ?? (throw ApiError.forbidden('staff are managed per venue'));
    final email = r.b.str('email').toLowerCase();
    if (app.db.raw('StaffInvitation').any((i) => i['venueId'] == venueId && (i['email'] as String).toLowerCase() == email && i['status'] == 'invited')) {
      throw ApiError('EMAIL_ALREADY_INVITED');
    }
    final seq = app.db.next('invitation');
    final invId = 'inv-m$seq';
    final staffId = 'staff-m$seq';
    final userId = 'user-inv-m$seq';
    final role = r.b.str('role');
    final local = email.split('@').first;
    app.db.put('User', {
      'id': userId,
      'role': 'hotel_staff',
      'name': local,
      'nameLatin': local,
      'monogram': local[0].toUpperCase(),
      'phone': '',
      'email': null,
      'locale': 'en',
      'digitStyle': 'western',
      'createdAt': app.now,
    });
    final expires = app.clock.after(const Duration(days: 3));
    app.db.put('StaffMember', {
      'id': staffId,
      'userId': userId,
      'venueId': venueId,
      'name': local,
      'nameLatin': local,
      'monogram': local[0].toUpperCase(),
      'email': email,
      'role': role,
      'roleLabel': _roleLabel(role),
      'roleSummary': _roleSummary(role),
      'phone': '',
      'status': 'invited',
      'uiLang': 'en',
      'lastSeenAt': null,
      'invitedAt': app.now,
      'inviteExpiresAt': expires,
      'invitedBy': actorName(r),
      'isYou': false,
    });
    final inv = {
      'id': invId,
      'venueId': venueId,
      'email': email,
      'role': role,
      'status': 'invited',
      'sentAt': app.now,
      'expiresAt': expires,
      'invitedBy': actorName(r),
      'staffId': staffId,
    };
    app.db.put('StaffInvitation', inv);
    app.outbox.add({
      'at': app.now,
      'to': email,
      'kind': 'staff_invitation',
      'role': role,
      'venueId': venueId,
      'token': invId,
      'link': 'ghazal://partner/invitation/$invId',
    });
    for (final uid in app.notifyTargets(venueId: venueId)) {
      notify(app, userId: uid, kind: 'invite', audience: 'hotel', vars: {'email': email, 'role': _roleLabel(role)}, params: {'staff': local}, venueId: venueId);
    }
    return invitationView(app, inv);
  },
  'resendStaffInvitation': (r) {
    app.requirePermission(r, 'staff:manage');
    final inv = app.db.get('StaffInvitation', r.p('invitationId'));
    if (inv == null || inv['venueId'] != r.ctx.venueId) throw ApiError.notFound('invitation');
    if (inv['status'] == 'accepted') throw ApiError('EMAIL_ALREADY_INVITED', detail: 'already accepted');
    inv['sentAt'] = app.now;
    inv['expiresAt'] = app.clock.after(const Duration(days: 3));
    app.db.put('StaffInvitation', inv);
    app.outbox.add({
      'at': app.now,
      'to': inv['email'],
      'kind': 'staff_invitation',
      'role': inv['role'],
      'venueId': inv['venueId'],
      'token': inv['id'],
      'link': 'ghazal://partner/invitation/${inv['id']}',
      'resent': true,
    });
    return invitationView(app, inv);
  },
  'revokeStaffInvitation': (r) {
    app.requirePermission(r, 'staff:manage');
    final inv = app.db.get('StaffInvitation', r.p('invitationId'));
    if (inv == null || inv['venueId'] != r.ctx.venueId) throw ApiError.notFound('invitation');
    app.db.remove('StaffInvitation', inv.str('id'));
    final sid = inv.strOrNull('staffId');
    if (sid != null && app.db.peek('StaffMember', sid)?['status'] == 'invited') app.db.remove('StaffMember', sid);
    return null;
  },
  'changeStaffRole': (r) {
    app.requirePermission(r, 'staff:manage');
    final s = _staff(app, r);
    final role = r.b.str('role');
    if (s['role'] == 'admin' && role != 'admin' && s['status'] == 'active' && _activeAdmins(app, s.str('venueId')) <= 1) throw ApiError('STAFF_LAST_ADMIN');
    s['role'] = role;
    s['roleLabel'] = _roleLabel(role);
    s['roleSummary'] = _roleSummary(role);
    app.db.put('StaffMember', s);
    return _staffView(app, s, r.userId);
  },
  'deactivateStaff': (r) {
    app.requirePermission(r, 'staff:manage');
    final s = _staff(app, r);
    if (s['role'] == 'admin' && s['status'] == 'active' && _activeAdmins(app, s.str('venueId')) <= 1) throw ApiError('STAFF_LAST_ADMIN');
    s['status'] = 'deactivated';
    app.db.put('StaffMember', s);
    return _staffView(app, s, r.userId);
  },
  'reactivateStaff': (r) {
    app.requirePermission(r, 'staff:manage');
    final s = _staff(app, r);
    if (s['status'] == 'deactivated') s['status'] = 'active';
    app.db.put('StaffMember', s);
    return _staffView(app, s, r.userId);
  },
  'getPartnerNotificationPreferences': (r) {
    final venueId = r.ctx.venueId;
    final s = venueId == null ? null : venueSettings(app, venueId);
    return s?.obj('notificationPrefs') ?? {'newRequestAlwaysOn': true, 'messages': true, 'reviews': true, 'vouchers': true, 'visits': true};
  },
  'updatePartnerNotificationPreferences': (r) {
    final prefs = {...r.b, 'newRequestAlwaysOn': true};
    final venueId = r.ctx.venueId;
    if (venueId != null) {
      final s = venueSettings(app, venueId);
      s['notificationPrefs'] = prefs;
      saveSettings(app, s);
    }
    return prefs;
  },
};
