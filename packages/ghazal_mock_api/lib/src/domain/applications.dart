/// The partner application (round 2, ADR 0038, PA-ACC-07 and PA-ACC-08): the form is validated, the account and the provider profile are created under
/// review, and the staff decision (the Super Admin web in the real service) accepts or rejects. Shared by the `chooseAccountType` handler, the
/// control endpoint and the seeded applicant personas.
library;

import '../core/app.dart';
import '../core/problem.dart';
import '../db/mock_db.dart' show wire;
import '../engine/engine.dart';

/// The application form of PA-ACC-07 / PA-ACC-08 (OQ-R2-03): every field the form needs, as `{path, code}` problems of a 422 VALIDATION_FAILED. The
/// request schema already checked types, formats and the three-category limit; this adds what only the account type knows.
///
/// [at] prefixes the error paths when the form is nested in a bigger body (`/application` for the public `submitPartnerApplication`).
void checkApplicationForm(MockApp app, Json b, String accountType, {String at = ''}) {
  final errs = <Json>[];
  bool blank(Object? v) => v == null || (v is String && v.trim().isEmpty);
  final name = b.objOrNull('name');
  for (final lang in const ['ar', 'en']) {
    if (blank(name?[lang])) errs.add({'path': '$at/name/$lang', 'code': 'required'});
  }
  for (final k in const ['governorateId', 'contactName', 'phone', 'email', 'description']) {
    if (blank(b[k])) errs.add({'path': '$at/$k', 'code': 'required'});
  }
  final gov = b['governorateId'];
  if (gov is String && gov.isNotEmpty && !app.seed.rows('Governorate').any((g) => g['id'] == gov)) {
    errs.add({'path': '$at/governorateId', 'code': 'unknown_governorate'});
  }
  if (accountType == 'service_provider') {
    final cats = (b['categoryIds'] as List?) ?? const [];
    if (cats.isEmpty && blank(b['otherCategoryNote'])) errs.add({'path': '$at/categoryIds', 'code': 'required'});
    for (final e in cats.indexed) {
      if (!app.seed.rows('ServiceCategory').any((c) => c['id'] == e.$2)) errs.add({'path': '$at/categoryIds/${e.$1}', 'code': 'unknown_category'});
    }
  }
  if (errs.isNotEmpty) throw ApiError('VALIDATION_FAILED', errors: errs);
}

/// The fields of an application document from the form body (also used to refresh it on a resubmission).
Json applicationFields(Json b) => {
  'name': b['name'],
  'categoryIds': (b['categoryIds'] as List?) ?? <String>[],
  'otherCategoryNote': (b['otherCategoryNote'] as String?)?.trim().isEmpty ?? true ? null : (b['otherCategoryNote'] as String).trim(),
  'governorateId': b['governorateId'],
  'contactName': (b['contactName'] as String).trim(),
  'phone': b['phone'],
  'email': b['email'],
  'description': (b['description'] as String).trim(),
  'licenceRef': (b['licenceRef'] as String?)?.trim().isEmpty ?? true ? null : (b['licenceRef'] as String).trim(),
};

/// What the applicant's provider profile takes from the form (a venue-type application has no provider yet).
void applyApplicationToProvider(MockApp app, String? providerId, Json a) {
  if (providerId == null) return;
  final provider = app.db.get('ServiceProvider', providerId);
  if (provider == null) return;
  final cats = (a['categoryIds'] as List).cast<String>();
  final areas = app.seed.rows('Area');
  final area = areas.cast<Json?>().firstWhere((x) => x!['governorateId'] == a['governorateId'], orElse: () => null) ?? areas.first;
  provider['name'] = a['name'];
  provider['categoryId'] = cats.isEmpty ? provider['categoryId'] : cats.first;
  provider['alsoCategoryIds'] = cats.length > 1 ? cats.sublist(1) : <String>[];
  provider['areaId'] = area['id'];
  provider['governorateId'] = a['governorateId'];
  provider['about'] = {'en': a['description'], 'ar': a['description']};
  provider['phone'] = a['phone'];
  app.db.put('ServiceProvider', provider);
}

/// Creates the account (`under_review`), the provider profile of a service provider and the `pending` application of [userId] from the form [form]
/// (validated first: a bad form is 422 VALIDATION_FAILED, its paths prefixed by [at]). Nothing about the session is touched here.
({Json application, String accountId, String? providerId}) submitApplication(
  MockApp app, {
  required String userId,
  required String accountType,
  required Json form,
  String at = '',
}) {
  checkApplicationForm(app, form, accountType, at: at);
  final fields = applicationFields(form);
  final seq = app.db.next('account');
  final accountId = 'partner-m$seq';
  String? providerId;
  if (accountType == 'service_provider') {
    providerId = 'vendor-m$seq';
    final cat = app.seed.rows('ServiceCategory').first;
    final area = app.seed.rows('Area').first;
    final name = form.obj('name');
    final first = name.strOrNull('ar') ?? name.strOrNull('en') ?? '?';
    app.db.put('ServiceProvider', {
      'id': providerId,
      'categoryId': cat['id'],
      'alsoCategoryIds': <String>[],
      'name': form['name'],
      'monogram': first.isEmpty ? '?' : String.fromCharCode(first.runes.first),
      'areaId': area['id'],
      'governorateId': area['governorateId'],
      'about': {'en': '', 'ar': ''},
      'rating': null,
      'from': fils(0),
      'fromVoucher': null,
      'fromUnit': {'en': 'per service', 'ar': 'للخدمة'},
      'packages': <Json>[],
      'portfolio': <Json>[],
      'tags': <Json>[],
      'femaleTeamForLadies': false,
      'usuallyRepliesHours': 24,
      'verified': false,
      'phone': app.requireUser(userId)['phone'] ?? '',
    });
    applyApplicationToProvider(app, providerId, fields);
  }
  final application = {
    'id': 'app-m${app.db.next('application').toString().padLeft(3, '0')}',
    'accountId': accountId,
    'accountType': accountType,
    ...fields,
    'status': 'pending',
    'rejectionReason': null,
    'submittedAt': app.now,
    'decidedAt': null,
    '_userId': userId,
  };
  app.db.put('PartnerApplication', application);
  app.db.put('PartnerAccount', {
    'id': accountId,
    'type': accountType,
    'name': form['name'],
    'venueIds': <String>[],
    'providerId': providerId,
    'ownerUserId': userId,
    'feeExempt': false,
    'status': 'under_review',
    'createdAt': app.now,
  });
  return (application: application, accountId: accountId, providerId: providerId);
}

/// Staff decision on an application (the Super Admin web in the real service; the mock's `POST /__mock/applications/{id}/decide`): accept makes the
/// account `active` so it can create listings; reject keeps it `under_review` and records the reason the applicant sees with "Edit and resubmit".
Json decideApplication(MockApp app, String applicationId, {required bool accept, String? reason, String? reasonAr}) {
  final a = app.db.get('PartnerApplication', applicationId) ?? (throw ApiError.notFound('application'));
  if (a['status'] != 'pending') {
    throw ApiError('APPLICATION_NOT_EDITABLE', detail: 'only a pending application can be decided', currentStatus: a.str('status'));
  }
  a['status'] = accept ? 'accepted' : 'rejected';
  a['decidedAt'] = app.now;
  a['rejectionReason'] = accept
      ? null
      : {
          'en': reason ?? 'Please review the business details and send the application again.',
          'ar': reasonAr ?? reason ?? 'يرجى مراجعة بيانات النشاط وإعادة إرسال الطلب.',
        };
  app.db.put('PartnerApplication', a);
  final account = app.db.get('PartnerAccount', a.str('accountId'));
  if (account != null && accept) {
    account['status'] = 'active';
    app.db.put('PartnerAccount', account);
  }
  app.logEvent(accept ? 'partner_application_accepted' : 'partner_application_rejected', {
    'applicationId': applicationId,
    'accountId': a['accountId'],
  });
  return wire(a);
}

/// Round 2: the seeded applicant personas of `extra.json` (`provider_applicant`: an application `pending`; `provider_rejected`: an application
/// `rejected` with a reason). Each is a partner user with one `under_review` service-provider account, so the Partner app's "under review" and
/// "rejected, edit and resubmit" states can be shown without driving the form. Called by `MockApp.reset` once the story clock is set.
void seedApplicantPersonas(MockApp app) {
  for (final p in app.seed.extra.list('personas')) {
    final state = p['applicant'] as String?;
    if (state == null) continue;
    final nameAr = p.str('nameAr');
    app.db.put('User', {
      'id': p.str('userId'),
      'role': 'provider_staff',
      'name': nameAr,
      'nameLatin': p['name'],
      'monogram': String.fromCharCode(nameAr.runes.first),
      'phone': p['phone'],
      'email': p['email'],
      'locale': 'ar',
      'digitStyle': 'western',
      'createdAt': app.now,
      '_phoneVerified': true,
    });
    final created = submitApplication(app, userId: p.str('userId'), accountType: 'service_provider', form: p.obj('application'));
    if (state == 'rejected') {
      final reason = p.obj('rejection');
      decideApplication(app, created.application.str('id'), accept: false, reason: reason.str('en'), reasonAr: reason.str('ar'));
    }
  }
}
