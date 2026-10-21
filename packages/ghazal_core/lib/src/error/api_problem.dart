import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The stable error codes of docs/architecture/api-conventions.md section 5. The API sends no user-facing prose;
/// clients map the code plus params to a localised string through [ApiProblem.messageKey].
enum ApiProblemCode {
  validationFailed('VALIDATION_FAILED'),
  authRequired('AUTH_REQUIRED'),
  tokenExpired('TOKEN_EXPIRED'),
  sessionRevoked('SESSION_REVOKED'),
  phoneVerificationRequired('PHONE_VERIFICATION_REQUIRED'),
  forbidden('FORBIDDEN'),
  stepUpRequired('STEP_UP_REQUIRED'),
  notFound('NOT_FOUND'),
  otpInvalid('OTP_INVALID'),
  otpExpired('OTP_EXPIRED'),
  otpLocked('OTP_LOCKED'),
  rateLimited('RATE_LIMITED'),
  idempotencyKeyReused('IDEMPOTENCY_KEY_REUSED'),
  idempotencyInProgress('IDEMPOTENCY_IN_PROGRESS'),
  bookingStateConflict('BOOKING_STATE_CONFLICT'),
  bookingNotPayableYet('BOOKING_NOT_PAYABLE_YET'),
  slotUnavailable('SLOT_UNAVAILABLE'),
  openUnpaidLimit('OPEN_UNPAID_LIMIT'),
  quoteExpired('QUOTE_EXPIRED'),
  quoteChanged('QUOTE_CHANGED'),
  leadTimeTooShort('LEAD_TIME_TOO_SHORT'),
  guestsOutOfRange('GUESTS_OUT_OF_RANGE'),
  audienceNotAllowed('AUDIENCE_NOT_ALLOWED'),
  instantNotEligible('INSTANT_NOT_ELIGIBLE'),
  channelNotBookable('CHANNEL_NOT_BOOKABLE'),
  venueKycRequired('VENUE_KYC_REQUIRED'),
  couponInvalid('COUPON_INVALID'),
  couponNotApplicable('COUPON_NOT_APPLICABLE'),
  paymentWindowClosed('PAYMENT_WINDOW_CLOSED'),
  paymentGatewayError('PAYMENT_GATEWAY_ERROR'),
  accountDeletionBlocked('ACCOUNT_DELETION_BLOCKED'),
  appUpdateRequired('APP_UPDATE_REQUIRED'),

  // The voucher-model contract codes (`x-error-codes` of packages/contracts/openapi/base.yaml, ADR 0033 / 0035). The pre-voucher codes above
  // stay so older fixtures still parse; the apps show them with the generic message.
  openRequestLimit('OPEN_REQUEST_LIMIT'),
  voucherNotOffered('VOUCHER_NOT_OFFERED'),
  voucherNotUsable('VOUCHER_NOT_USABLE'),
  voucherTargetMismatch('VOUCHER_TARGET_MISMATCH'),
  voucherCheckoutExpired('VOUCHER_CHECKOUT_EXPIRED'),
  voucherUnknown('VOUCHER_UNKNOWN'),
  voucherOtherPartner('VOUCHER_OTHER_PARTNER'),
  voucherNotConfirmed('VOUCHER_NOT_CONFIRMED'),
  voucherAlreadyUsed('VOUCHER_ALREADY_USED'),
  creditNotEligible('CREDIT_NOT_ELIGIBLE'),
  refundRequestExists('REFUND_REQUEST_EXISTS'),
  confirmWindowEnded('CONFIRM_WINDOW_ENDED'),
  undoWindowEnded('UNDO_WINDOW_ENDED'),
  planRatesNotAnnounced('PLAN_RATES_NOT_ANNOUNCED'),
  listingNotEditable('LISTING_NOT_EDITABLE'),
  listingStateConflict('LISTING_STATE_CONFLICT'),
  mediaTooLarge('MEDIA_TOO_LARGE'),
  mediaTypeUnsupported('MEDIA_TYPE_UNSUPPORTED'),
  reviewAlreadyReplied('REVIEW_ALREADY_REPLIED'),
  reviewNotAllowed('REVIEW_NOT_ALLOWED'),
  visitSlotTaken('VISIT_SLOT_TAKEN'),
  visitNotAllowed('VISIT_NOT_ALLOWED'),
  visitStateConflict('VISIT_STATE_CONFLICT'),
  staffLastAdmin('STAFF_LAST_ADMIN'),
  invitationExpired('INVITATION_EXPIRED'),
  emailAlreadyInvited('EMAIL_ALREADY_INVITED'),
  credentialsInvalid('CREDENTIALS_INVALID'),
  venueContextRequired('VENUE_CONTEXT_REQUIRED'),
  preconditionFailed('PRECONDITION_FAILED'),

  /// Client-side conditions that are not API codes.
  offline('OFFLINE'),
  timeout('TIMEOUT'),
  unknown('UNKNOWN');

  const ApiProblemCode(this.wire);

  /// The `code` string on the wire.
  final String wire;

  static ApiProblemCode parse(String? wire) =>
      ApiProblemCode.values.firstWhere((c) => c.wire == wire, orElse: () => ApiProblemCode.unknown);

  /// camelCase key suffix: `SLOT_UNAVAILABLE` becomes `slotUnavailable`.
  String get messageKey => 'apiError${name[0].toUpperCase()}${name.substring(1)}';
}

/// One field error of a `VALIDATION_FAILED` problem.
class ApiFieldError extends Equatable {
  const ApiFieldError({required this.path, required this.code, this.params = const {}});

  final String path;
  final ApiProblemCode code;
  final Map<String, Object?> params;

  @override
  List<Object?> get props => [path, code, params];
}

/// An RFC 9457 `application/problem+json` body (api-conventions section 5). `title` and `detail` are for developers
/// and logs only; never show them. A screen shows the string behind [messageKey] with [params].
class ApiProblem extends Equatable implements Exception {
  const ApiProblem({
    required this.status,
    required this.code,
    this.title,
    this.detail,
    this.type,
    this.requestId,
    this.params = const {},
    this.errors = const [],
    this.alternatives = const [],
    this.retryAfterSeconds,
  });

  final int status;
  final ApiProblemCode code;
  final String? title;
  final String? detail;
  final String? type;
  final String? requestId;
  final Map<String, Object?> params;
  final List<ApiFieldError> errors;
  final List<Map<String, Object?>> alternatives;

  /// From the `Retry-After` header (429, 409 in progress).
  final int? retryAfterSeconds;

  /// A client-side problem: no connectivity.
  const ApiProblem.offline() : this(status: 0, code: ApiProblemCode.offline);

  const ApiProblem.timeout() : this(status: 0, code: ApiProblemCode.timeout);

  /// Parses a response. [body] may be a decoded map, a JSON string or null (a non-problem 5xx body becomes `UNKNOWN`).
  factory ApiProblem.fromResponse({required int status, Object? body, Map<String, String>? headers}) {
    Object? decoded = body;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        decoded = null;
      }
    }
    final retry = int.tryParse(headers?['retry-after'] ?? headers?['Retry-After'] ?? '');
    if (decoded is! Map<Object?, Object?>) {
      return ApiProblem(status: status, code: ApiProblemCode.unknown, retryAfterSeconds: retry);
    }
    final map = decoded.cast<String, Object?>();
    return ApiProblem(
      status: (map['status'] as num?)?.toInt() ?? status,
      code: ApiProblemCode.parse(map['code'] as String?),
      title: map['title'] as String?,
      detail: map['detail'] as String?,
      type: map['type'] as String?,
      requestId: map['requestId'] as String?,
      params: (map['params'] as Map<String, Object?>?) ?? const {},
      errors: [
        for (final e in (map['errors'] as List<Object?>? ?? const []).whereType<Map<String, Object?>>())
          ApiFieldError(
            path: e['path'] as String? ?? '',
            code: ApiProblemCode.parse(e['code'] as String?),
            params: (e['params'] as Map<String, Object?>?) ?? const {},
          ),
      ],
      alternatives: [for (final a in (map['alternatives'] as List<Object?>? ?? const []).whereType<Map<String, Object?>>()) a],
      retryAfterSeconds: retry,
    );
  }

  /// ARB key of the user-safe message (`apiErrorSlotUnavailable`); the `params` fill its placeholders.
  String get messageKey => code.messageKey;

  bool get isOffline => code == ApiProblemCode.offline;

  /// 5xx and network conditions the global retry policy may retry (idempotent GETs only).
  bool get isTransient => status == 0 || status >= 500;

  /// The session is gone: sign out and clear caches.
  bool get requiresSignOut => code == ApiProblemCode.sessionRevoked;

  /// A single-flight refresh then one replay.
  bool get requiresRefresh => code == ApiProblemCode.tokenExpired;

  @override
  List<Object?> get props => [status, code, requestId, params, errors, retryAfterSeconds];

  @override
  String toString() => 'ApiProblem(${code.wire} $status${requestId == null ? '' : ' $requestId'})';
}
