/// RFC 9457 problem+json errors with the stable codes of the contract (`x-error-codes` of base.yaml): the mock sends a code, never prose.
library;

import '../engine/json.dart';

/// The HTTP status of every stable error code (the contract table, plus [internalError] for the fault-injection scenario).
const errorStatus = <String, int>{
  'VALIDATION_FAILED': 422,
  'AUTH_REQUIRED': 401,
  'TOKEN_EXPIRED': 401,
  'SESSION_REVOKED': 401,
  'PHONE_VERIFICATION_REQUIRED': 403,
  'FORBIDDEN': 403,
  'STEP_UP_REQUIRED': 403,
  'NOT_FOUND': 404,
  'VENUE_CONTEXT_REQUIRED': 400,
  'OTP_INVALID': 400,
  'OTP_EXPIRED': 410,
  'OTP_LOCKED': 423,
  'CREDENTIALS_INVALID': 401,
  'RATE_LIMITED': 429,
  'IDEMPOTENCY_KEY_REUSED': 422,
  'IDEMPOTENCY_IN_PROGRESS': 409,
  'PRECONDITION_FAILED': 412,
  'BOOKING_STATE_CONFLICT': 409,
  'SLOT_UNAVAILABLE': 409,
  'OPEN_REQUEST_LIMIT': 409,
  'QUOTE_EXPIRED': 410,
  'QUOTE_CHANGED': 409,
  'LEAD_TIME_TOO_SHORT': 422,
  'GUESTS_OUT_OF_RANGE': 422,
  'AUDIENCE_NOT_ALLOWED': 422,
  'CHANNEL_NOT_BOOKABLE': 409,
  'VOUCHER_NOT_OFFERED': 409,
  'VOUCHER_NOT_USABLE': 409,
  'VOUCHER_TARGET_MISMATCH': 409,
  'VOUCHER_CHECKOUT_EXPIRED': 409,
  'VOUCHER_UNKNOWN': 404,
  'VOUCHER_OTHER_PARTNER': 409,
  'VOUCHER_NOT_CONFIRMED': 409,
  'VOUCHER_ALREADY_USED': 409,
  'CREDIT_NOT_ELIGIBLE': 409,
  'REFUND_REQUEST_EXISTS': 409,
  'CONFIRM_WINDOW_ENDED': 409,
  'UNDO_WINDOW_ENDED': 409,
  'PAYMENT_GATEWAY_ERROR': 502,
  'PLAN_RATES_NOT_ANNOUNCED': 409,
  'LISTING_NOT_EDITABLE': 409,
  'LISTING_STATE_CONFLICT': 409,
  'MEDIA_TOO_LARGE': 422,
  'MEDIA_TYPE_UNSUPPORTED': 422,
  'REVIEW_ALREADY_REPLIED': 409,
  'REVIEW_NOT_ALLOWED': 409,
  'VISIT_SLOT_TAKEN': 409,
  'VISIT_NOT_ALLOWED': 409,
  'VISIT_STATE_CONFLICT': 409,
  'STAFF_LAST_ADMIN': 409,
  'INVITATION_EXPIRED': 410,
  'EMAIL_ALREADY_INVITED': 409,
  'ACCOUNT_DELETION_BLOCKED': 409,
  'APP_UPDATE_REQUIRED': 426,
};

/// Fault injection only (`X-Mock-Scenario: error`): a 500 outside the contract table.
const internalError = 'INTERNAL_ERROR';

class ApiError implements Exception {
  ApiError(this.code, {this.detail, this.params, this.errors, this.alternatives, this.currentStatus, this.currentVersion, this.retryAfterSeconds, int? status})
      : status = status ?? errorStatus[code] ?? 500;

  final String code;
  final int status;
  final String? detail;
  final Json? params;
  final List<Json>? errors;
  final List<Json>? alternatives;
  final String? currentStatus;
  final int? currentVersion;
  final int? retryAfterSeconds;

  static ApiError notFound([String what = 'resource']) => ApiError('NOT_FOUND', detail: '$what not found');
  static ApiError forbidden([String? detail]) => ApiError('FORBIDDEN', detail: detail);
  static ApiError validation(String path, String code, {Json? params}) =>
      ApiError('VALIDATION_FAILED', errors: [
        {'path': path, 'code': code, 'params': ?params}
      ]);

  String get title => code.split('_').map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}').join(' ');

  /// The problem+json body.
  Json toJson({String? requestId}) => {
        'type': 'https://api.ghazal.example/problems/${code.toLowerCase().replaceAll('_', '-')}',
        'title': title,
        'status': status,
        'code': code,
        'detail': ?detail,
        'requestId': ?requestId,
        'params': ?params,
        'errors': ?errors,
        'alternatives': ?alternatives,
        'currentStatus': ?currentStatus,
        'currentVersion': ?currentVersion,
        'retryAfterSeconds': ?retryAfterSeconds,
      };

  @override
  String toString() => 'ApiError($status $code${detail != null ? ': $detail' : ''})';
}
