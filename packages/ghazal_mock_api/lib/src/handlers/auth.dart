/// auth: client sign-in by WhatsApp code (any 6 digits or 123456; 000000 is locked, 111111 expired), password, social, partner sign-in by
/// email and password with a code on a new device, staff invitations, step-up. The mock sends nothing; codes and emails land in the outbox.
library;

import 'dart:convert';

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../engine/engine.dart';
import 'common.dart';

const _standardPassword = 'Ghazal#2026';

Json newChallenge(MockApp app, {required String purpose, required String channel, required String destination, String? userId, String? phone}) {
  final id = 'chal-${app.db.next('challenge').toString().padLeft(4, '0')}';
  // rate limit: more than five codes to one destination inside one story minute
  final recent = app.db.raw('OtpChallenge').where((c) => c['destination'] == destination && instantMs(app.now) - instantMs(c.str('createdAt')) < 60000).length;
  if (recent >= 5) throw ApiError('RATE_LIMITED', retryAfterSeconds: 60);
  final hint = channel == 'email' ? destination.replaceFirstMapped(RegExp(r'^(.).*@'), (m) => '${m[1]}•••@') : '${destination.substring(0, destination.length > 4 ? destination.length - 4 : 0)}${'•' * 0}${destination.length > 4 ? '••${destination.substring(destination.length - 2)}' : destination}';
  app.db.put('OtpChallenge', {'id': id, 'purpose': purpose, 'channel': channel, 'destination': destination, 'userId': userId, 'phone': phone, 'createdAt': app.now, 'expiresAt': app.clock.after(const Duration(minutes: 5)), 'used': false});
  if (channel == 'email') {
    app.outbox.add({'at': app.now, 'to': destination, 'kind': 'code', 'purpose': purpose, 'code': app.seed.extra.obj('credentials').str('otpCode'), 'challengeId': id});
  }
  return {'challengeId': id, 'channel': channel, 'destinationHint': hint, 'expiresInSeconds': 300, 'resendAfterSeconds': 60, 'codeLength': 6};
}

/// Checks a code against an open challenge; returns the challenge.
Json checkOtp(MockApp app, String challengeId, String code) {
  final c = app.db.get('OtpChallenge', challengeId) ?? (throw ApiError('OTP_INVALID'));
  final cred = app.seed.extra.obj('credentials');
  if (code == cred.str('lockedOtp')) throw ApiError('OTP_LOCKED', retryAfterSeconds: 900);
  if (c['used'] == true || code == cred.str('expiredOtp') || instantMs(app.now) > instantMs(c.str('expiresAt'))) throw ApiError('OTP_EXPIRED');
  if (!RegExp(r'^\d{6}$').hasMatch(code)) throw ApiError('OTP_INVALID');
  return c;
}

void consumeChallenge(MockApp app, Json c) => app.db.put('OtpChallenge', {...c, 'used': true});

Json _newUser(MockApp app, {required String name, String? phone, String? email, String locale = 'ar', bool phoneVerified = false}) {
  final id = 'user-n${app.db.next('user').toString().padLeft(3, '0')}';
  final u = <String, dynamic>{
    'id': id,
    'role': 'client',
    'name': name,
    'nameLatin': null,
    'monogram': name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
    'phone': phone ?? '',
    'email': email,
    'locale': locale,
    'digitStyle': 'western',
    'createdAt': app.now,
    '_phoneVerified': phoneVerified,
  };
  app.db.put('User', u);
  return u;
}

Json? _byPhone(MockApp app, String phone) => app.db.firstWhere('User', (u) => u['phone'] == phone && u['role'] == 'client');

/// Resolves the partner user of an email: the persona emails, then staff accepted by invitation.
Json? _partnerByEmail(MockApp app, String email) {
  final e = email.toLowerCase();
  for (final p in app.seed.extra.list('personas')) {
    if ((p['email'] as String?)?.toLowerCase() == e && p['userId'] != null) return app.db.get('User', p.str('userId'));
  }
  return app.db.firstWhere('User', (u) => (u['_email'] as String?)?.toLowerCase() == e);
}

Json _partnerPassword(MockApp app, Json user) => {'password': user['_password'] ?? app.seed.extra.obj('credentials').str('partnerPassword')};

Map<String, Handler> authHandlers(MockApp app) => {
      'requestOtp': (r) {
        final phone = r.b.str('phone').replaceAll(' ', '');
        final user = _byPhone(app, phone);
        return newChallenge(app, purpose: r.b.str('purpose'), channel: 'whatsapp', destination: phone, userId: user?.str('id'), phone: phone);
      },
      'verifyOtp': (r) {
        final c = checkOtp(app, r.b.str('challengeId'), r.b.str('code'));
        consumeChallenge(app, c);
        final phone = c.strOrNull('phone') ?? '';
        var user = c.strOrNull('userId') != null ? app.db.get('User', c.str('userId')) : _byPhone(app, phone);
        var isNew = false;
        if (user == null) {
          user = _newUser(app, name: '', phone: phone, phoneVerified: true);
          user['name'] = 'Guest ${phone.length > 4 ? phone.substring(phone.length - 4) : phone}';
          user['monogram'] = 'G';
          isNew = true;
        } else if (user['_pendingRegistration'] == true) {
          isNew = true;
        }
        user['_phoneVerified'] = true;
        user.remove('_pendingRegistration');
        app.db.put('User', user);
        return authSession(app, user.str('id'), isNew: isNew, deviceId: r.b.strOrNull('deviceId'));
      },
      'registerAccount': (r) {
        final phone = r.b.str('phone').replaceAll(' ', '');
        var user = _byPhone(app, phone);
        if (user == null) {
          user = _newUser(app, name: r.b.str('name'), phone: phone, locale: r.b.str('locale'));
          user['_pendingRegistration'] = true;
          if (r.b['password'] != null) user['_password'] = r.b['password'];
          app.db.put('User', user);
        }
        return newChallenge(app, purpose: 'verify_phone', channel: 'whatsapp', destination: phone, userId: user.str('id'), phone: phone);
      },
      'passwordLogin': (r) {
        final user = _byPhone(app, r.b.str('phone').replaceAll(' ', ''));
        if (user == null || r.b.str('password') != (user['_password'] ?? _standardPassword)) throw ApiError('CREDENTIALS_INVALID');
        return authSession(app, user.str('id'), deviceId: r.b.strOrNull('deviceId'));
      },
      'requestPasswordReset': (r) {
        final phone = r.b.str('phone').replaceAll(' ', '');
        return newChallenge(app, purpose: 'reset_password', channel: 'whatsapp', destination: phone, userId: _byPhone(app, phone)?.str('id'), phone: phone);
      },
      'resetPassword': (r) {
        final c = checkOtp(app, r.b.str('challengeId'), r.b.str('code'));
        consumeChallenge(app, c);
        final uid = c.strOrNull('userId');
        if (uid != null) {
          final u = app.db.get('User', uid);
          if (u != null) app.db.put('User', {...u, '_password': r.b.str('newPassword')});
        }
        return null;
      },
      'signInWithApple': (r) => _social(app, r, 'apple'),
      'signInWithGoogle': (r) => _social(app, r, 'google'),
      'refreshSession': (r) {
        final t = app.refreshSession(r.b.str('refreshToken'));
        final s = app.db.get('Session', t['sessionId'] as String)!;
        return {'accessToken': t['accessToken'], 'refreshToken': t['refreshToken'], 'tokenType': 'Bearer', 'expiresInSeconds': 600, 'isNewUser': false, 'user': meOf(app, s.str('userId'))};
      },
      'signOut': (r) {
        app.revokeSession(r.identity!.sessionId);
        return null;
      },
      'stepUp': (r) {
        final user = app.requireUser(r.userId);
        if (r.b.str('method') == 'password') {
          if (r.b.strOrNull('password') != (user['_password'] ?? (user['role'] == 'client' ? _standardPassword : app.seed.extra.obj('credentials').str('partnerPassword')))) throw ApiError('CREDENTIALS_INVALID');
        } else {
          final c = checkOtp(app, r.b.strOrNull('challengeId') ?? '', r.b.strOrNull('code') ?? '');
          consumeChallenge(app, c);
        }
        return {'token': 'gzm_su_${app.db.next('stepup')}', 'expiresInSeconds': 300};
      },
      'partnerLogin': (r) {
        final email = r.b.str('email');
        final user = _partnerByEmail(app, email);
        if (user == null || r.b.str('password') != _partnerPassword(app, user)['password']) throw ApiError('CREDENTIALS_INVALID');
        final device = r.b.strOrNull('deviceId');
        final known = (user['_devices'] as List?)?.cast<String>() ?? const <String>[];
        if (device != null && known.contains(device)) {
          return {'status': 'signed_in', 'session': authSession(app, user.str('id'), deviceId: device), 'challenge': null};
        }
        return {'status': 'code_required', 'session': null, 'challenge': newChallenge(app, purpose: 'login', channel: 'email', destination: email, userId: user.str('id'))};
      },
      'partnerVerifyCode': (r) {
        final c = checkOtp(app, r.b.str('challengeId'), r.b.str('code'));
        consumeChallenge(app, c);
        final user = app.requireUser(c.str('userId'));
        final device = r.b.strOrNull('deviceId');
        if (device != null) {
          user['_devices'] = [...((user['_devices'] as List?) ?? const []), device];
          app.db.put('User', user);
        }
        return authSession(app, user.str('id'), deviceId: device);
      },
      'partnerForgotPassword': (r) {
        final email = r.b.str('email');
        final user = _partnerByEmail(app, email);
        return newChallenge(app, purpose: 'reset_password', channel: 'email', destination: email, userId: user?.str('id'));
      },
      'partnerResetPassword': (r) {
        final c = checkOtp(app, r.b.str('challengeId'), r.b.str('code'));
        consumeChallenge(app, c);
        final uid = c.strOrNull('userId');
        final u = uid == null ? null : app.db.get('User', uid);
        if (u != null) app.db.put('User', {...u, '_password': r.b.str('newPassword')});
        return null;
      },
      'getStaffInvitationPreview': (r) {
        final inv = _invitationByToken(app, r.p('token'));
        return {
          'email': inv['email'],
          'role': inv['role'],
          'accountName': app.targetName(venueId: inv.str('venueId')),
          'invitedBy': inv['invitedBy'],
          'expiresAt': inv['expiresAt'],
        };
      },
      'acceptStaffInvitation': (r) {
        final inv = _invitationByToken(app, r.b.str('token'));
        final staffId = inv.strOrNull('staffId');
        final staff = staffId == null ? null : app.db.get('StaffMember', staffId);
        var user = staff == null ? null : app.db.get('User', staff.str('userId'));
        user ??= {'id': 'user-s${app.db.next('user')}', 'role': 'hotel_staff', 'name': (inv.str('email')).split('@').first, 'nameLatin': (inv.str('email')).split('@').first, 'monogram': inv.str('email')[0].toUpperCase(), 'phone': '', 'email': inv.str('email'), 'locale': 'en', 'digitStyle': 'western', 'createdAt': app.now};
        user
          ..['email'] = inv.str('email')
          ..['_email'] = inv.str('email')
          ..['_password'] = r.b.str('password')
          ..['_phoneVerified'] = true;
        app.db.put('User', user);
        if (staff != null) {
          staff
            ..['status'] = 'active'
            ..['userId'] = user['id']
            ..['lastSeenAt'] = app.now
            ..['inviteExpiresAt'] = null;
          app.db.put('StaffMember', staff);
        } else {
          app.db.put('StaffMember', {'id': 'staff-${user['id']}', 'userId': user['id'], 'venueId': inv['venueId'], 'name': user['name'], 'nameLatin': user['nameLatin'], 'monogram': user['monogram'], 'email': inv['email'], 'role': inv['role'], 'roleLabel': _roleLabel(inv.str('role')), 'roleSummary': _roleLabel(inv.str('role')), 'phone': '', 'status': 'active', 'uiLang': 'en', 'lastSeenAt': app.now, 'invitedAt': inv['sentAt'], 'inviteExpiresAt': null, 'invitedBy': inv['invitedBy'], 'isYou': false});
        }
        inv['status'] = 'accepted';
        app.db.put('StaffInvitation', inv);
        return authSession(app, user.str('id'), deviceId: r.b.strOrNull('deviceId'));
      },
    };

Json _roleLabel(String role) => {'en': role[0].toUpperCase() + role.substring(1), 'ar': const {'admin': 'المالك', 'manager': 'مدير', 'reception': 'الاستقبال', 'accountant': 'المحاسبة', 'marketing': 'التسويق'}[role] ?? role};

Json _invitationByToken(MockApp app, String token) {
  final inv = app.db.get('StaffInvitation', token) ?? app.db.firstWhere('StaffInvitation', (i) => i['_token'] == token) ?? (throw ApiError.notFound('invitation'));
  final exp = inv.strOrNull('expiresAt');
  if (inv['status'] == 'accepted' || (exp != null && instantMs(app.now) > instantMs(exp))) throw ApiError('INVITATION_EXPIRED');
  return inv;
}

Json _social(MockApp app, Req r, String provider) {
  final token = r.b.str('identityToken');
  Json claims = {};
  final parts = token.split('.');
  if (parts.length == 3) {
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      claims = (jsonDecode(payload) as Map).cast<String, dynamic>();
    } catch (_) {}
  }
  final sub = (claims['sub'] as String?) ?? 'tok${hash32([token])}';
  final id = 'user-$provider-$sub';
  var user = app.db.get('User', id);
  var isNew = false;
  if (user == null) {
    final name = r.b.strOrNull('name') ?? (claims['name'] as String?) ?? 'Guest';
    user = {
      'id': id,
      'role': 'client',
      'name': name,
      'nameLatin': null,
      'monogram': name.isEmpty ? '?' : String.fromCharCode(name.runes.first),
      'phone': '',
      'email': claims['email'],
      'locale': 'ar',
      'digitStyle': 'western',
      'createdAt': app.now,
      '_phoneVerified': false,
    };
    app.db.put('User', user);
    isNew = true;
  }
  return authSession(app, id, isNew: isNew, deviceId: r.b.strOrNull('deviceId'));
}
