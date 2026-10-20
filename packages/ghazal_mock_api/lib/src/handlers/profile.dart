/// profile: the account (me), devices, phone change and account deletion.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../core/request.dart';
import '../engine/engine.dart';
import 'auth.dart' show checkOtp, newChallenge, consumeChallenge;
import 'common.dart';

Map<String, Handler> profileHandlers(MockApp app) => {
      'getMe': (r) => meOf(app, r.userId),
      'updateMe': (r) {
        final u = app.requireUser(r.userId);
        for (final k in ['name', 'email', 'locale', 'digitStyle']) {
          if (r.b.containsKey(k)) u[k] = r.b[k];
        }
        if (r.b['name'] != null) u['monogram'] = String.fromCharCode((r.b['name'] as String).runes.first);
        if (r.b.containsKey('marketingOptIn')) u['_marketingOptIn'] = r.b['marketingOptIn'];
        app.db.put('User', u);
        if (r.b.containsKey('marketingOptIn')) {
          final p = app.db.get('NotificationPreferences', r.userId) ?? {'userId': r.userId, 'marketing': false, 'quietHours': {'start': '22:00', 'end': '09:00'}, 'maxMarketingPerWeek': 2};
          p['marketing'] = r.b['marketingOptIn'];
          app.db.put('NotificationPreferences', p, id: r.userId);
        }
        return meOf(app, r.userId);
      },
      'deleteAccount': (r) {
        final blocking = app.db.raw('Booking').any((b) => b['clientId'] == r.userId && b['status'] == 'confirmed' && b.str('eventDate').compareTo(app.today()) >= 0);
        if (blocking) throw ApiError('ACCOUNT_DELETION_BLOCKED');
        final u = app.requireUser(r.userId);
        u['_deletionRequestedAt'] = app.now;
        app.db.put('User', u);
        return {'status': 'scheduled', 'effectiveAt': '${addDays(app.today(), 30)}T00:00:00+03:00'};
      },
      'registerDevice': (r) {
        app.db.put('Device', {'id': '${r.userId}|${r.p('deviceId')}', 'userId': r.userId, 'deviceId': r.p('deviceId'), ...r.b});
        return null;
      },
      'requestPhoneChange': (r) => newChallenge(app, purpose: 'change_phone', channel: 'whatsapp', destination: r.b.str('phone'), userId: r.userId, phone: r.b.str('phone')),
      'confirmPhoneChange': (r) {
        final c = checkOtp(app, r.b.str('challengeId'), r.b.str('code'));
        if (c['userId'] != r.userId) throw ApiError('OTP_INVALID');
        consumeChallenge(app, c);
        final u = app.requireUser(r.userId);
        u['phone'] = c['phone'];
        u['_phoneVerified'] = true;
        app.db.put('User', u);
        return meOf(app, r.userId);
      },
    };
