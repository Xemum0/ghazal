// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get commonActionAccept => 'Accept';

  @override
  String get commonActionAdd => 'Add';

  @override
  String get commonActionApply => 'Apply';

  @override
  String get commonActionBack => 'Back';

  @override
  String get commonActionCall => 'Call';

  @override
  String get commonActionCancel => 'Cancel';

  @override
  String get commonActionClear => 'Clear';

  @override
  String get commonActionClose => 'Close';

  @override
  String get commonActionConfirm => 'Confirm';

  @override
  String get commonActionContinue => 'Continue';

  @override
  String get commonActionDecline => 'Decline';

  @override
  String get commonActionDone => 'Done';

  @override
  String get commonActionEdit => 'Edit';

  @override
  String get commonActionMessage => 'Message';

  @override
  String get commonActionNext => 'Next';

  @override
  String get commonActionOpenWhatsapp => 'Open WhatsApp';

  @override
  String get commonActionPrevious => 'Previous';

  @override
  String get commonActionRemove => 'Remove';

  @override
  String get commonActionReschedule => 'Reschedule';

  @override
  String get commonActionReset => 'Reset';

  @override
  String get commonActionRetry => 'Try again';

  @override
  String get commonActionSave => 'Save';

  @override
  String get commonActionSearch => 'Search';

  @override
  String get commonActionSeeAll => 'See all';

  @override
  String get commonActionSend => 'Send';

  @override
  String get commonActionShare => 'Share';

  @override
  String get commonActionShowLess => 'Show less';

  @override
  String get commonActionSkip => 'Skip';

  @override
  String get commonActionUndo => 'Undo';

  @override
  String get commonActionWhatsapp => 'WhatsApp';

  @override
  String get commonAvailabilityAvailable => 'Available';

  @override
  String get commonAvailabilityBlocked => 'Blocked';

  @override
  String get commonAvailabilityBooked => 'Booked';

  @override
  String get commonAvailabilityFree => 'Free';

  @override
  String get commonAvailabilityHeld => 'On hold';

  @override
  String get commonAvailabilityPast => 'Past date';

  @override
  String get commonAvailabilityUnavailable => 'Unavailable';

  @override
  String commonAvailabilityLineFree(String date) {
    return '$date · Free';
  }

  @override
  String commonAvailabilityLineBooked(String date) {
    return '$date · Booked';
  }

  @override
  String get commonCalendarAvailability => 'Availability';

  @override
  String get commonCalendarPrices => 'Prices';

  @override
  String get commonCalendarToday => 'Today';

  @override
  String get commonCalendarSelected => 'Selected';

  @override
  String get commonCalendarPeak => 'Peak days';

  @override
  String get commonCalendarPreviousMonth => 'Previous month';

  @override
  String get commonCalendarNextMonth => 'Next month';

  @override
  String commonCalendarOccasionApproximate(String occasion) {
    return '$occasion (approx.)';
  }

  @override
  String get commonStatusRequested => 'Pending';

  @override
  String get commonStatusAwaitingDeposit => 'Approved · deposit due';

  @override
  String get commonStatusConfirmed => 'Confirmed';

  @override
  String get commonStatusRejected => 'Not accepted';

  @override
  String get commonStatusExpired => 'Expired';

  @override
  String get commonStatusCancelled => 'Cancelled';

  @override
  String get commonStatusCompleted => 'Completed';

  @override
  String get commonStatusRefunded => 'Refunded';

  @override
  String get commonStatusNoShow => 'No-show';

  @override
  String get commonStatusHeadlineConfirmed => 'Confirmed booking';

  @override
  String get commonStatusCancelledByYou => 'Cancelled by you';

  @override
  String get commonStatusCancelledByVenue => 'Cancelled by the venue';

  @override
  String get commonStatusHotelMissed => 'Missed';

  @override
  String get commonStatusUrgent => 'Urgent';

  @override
  String commonStatusTimeLeft(String time) {
    return '$time remaining';
  }

  @override
  String get commonFilterAll => 'All';

  @override
  String get commonTierWeekday => 'Weekday';

  @override
  String get commonTierWeekend => 'Weekend';

  @override
  String get commonTierHoliday => 'Holiday';

  @override
  String get commonTierSeason => 'Season';

  @override
  String get commonTierSpecialDate => 'Special date';

  @override
  String get commonUnitPerGuest => 'per guest';

  @override
  String get commonUnitPerNight => 'per night';

  @override
  String get commonUnitPerDay => 'per day';

  @override
  String get commonUnitPerHour => 'per hour';

  @override
  String commonUnitMinGuests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString guests', one: '$countString guest');
    return 'Minimum $_temp0';
  }

  @override
  String commonUnitUpToGuests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString guests', one: '$countString guest');
    return 'Up to $_temp0';
  }

  @override
  String commonCountGuests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString guests', one: '$countString guest', zero: 'No guests');
    return '$_temp0';
  }

  @override
  String commonCountDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString days', one: '$countString day', zero: 'No days');
    return '$_temp0';
  }

  @override
  String commonCountHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString hours', one: '$countString hour', zero: 'No hours');
    return '$_temp0';
  }

  @override
  String commonCountMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString minutes', one: '$countString minute', zero: 'No minutes');
    return '$_temp0';
  }

  @override
  String commonCountHalls(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString halls', one: '$countString hall', zero: 'No halls');
    return '$_temp0';
  }

  @override
  String commonCountPackages(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString packages',
      one: '$countString package',
      zero: 'No packages',
    );
    return '$_temp0';
  }

  @override
  String commonCountMessages(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString messages',
      one: '$countString message',
      zero: 'No messages',
    );
    return '$_temp0';
  }

  @override
  String commonCountBookings(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString bookings',
      one: '$countString booking',
      zero: 'No bookings',
    );
    return '$_temp0';
  }

  @override
  String commonCountSessions(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString sessions',
      one: '$countString session',
      zero: 'No sessions',
    );
    return '$_temp0';
  }

  @override
  String commonCountMonths(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString months', one: '$countString month', zero: 'No months');
    return '$_temp0';
  }

  @override
  String commonCountDates(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString dates', one: '$countString date', zero: 'No dates');
    return '$_temp0';
  }

  @override
  String commonCountRequests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString requests',
      one: '$countString request',
      zero: 'No requests',
    );
    return '$_temp0';
  }

  @override
  String commonCountReviews(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString reviews', one: '$countString review', zero: 'No reviews');
    return '$_temp0';
  }

  @override
  String commonCountPhotos(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString photos', one: '$countString photo', zero: 'No photos');
    return '$_temp0';
  }

  @override
  String commonCountdownDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString days to go', one: '$countString day to go', zero: 'Today');
    return '$_temp0';
  }

  @override
  String commonCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString of $totalString';
  }

  @override
  String get commonStateLoading => 'Loading';

  @override
  String get commonStateTitleGeneric => 'Something went wrong';

  @override
  String get commonStateTitleLoad => 'Couldn’t load';

  @override
  String get commonStateTitleNetwork => 'You’re offline';

  @override
  String get commonStateTitlePayment => 'Payment failed';

  @override
  String get commonStateTitleNoAccess => 'No access';

  @override
  String get commonStateTitleNotFound => 'Not found';

  @override
  String get commonStateTitleEmptySearch => 'No matches';

  @override
  String get commonStateTitleEmpty => 'Nothing here';

  @override
  String get commonStateOffline => 'You’re offline';

  @override
  String get commonStateErrorGeneric => 'Something went wrong on our side. Nothing was changed. Please try again.';

  @override
  String get commonStateErrorLoad => 'We couldn’t load this. Please try again.';

  @override
  String get commonStateErrorNetwork => 'We couldn’t connect. Check your connection and try again.';

  @override
  String get commonStateErrorPayment => 'The payment could not be completed. No amount was charged.';

  @override
  String get commonStateErrorNoAccess => 'You do not have access. Ask your manager.';

  @override
  String get commonStateErrorNotFound => 'This page is no longer available.';

  @override
  String get commonStateSaved => 'Saved';

  @override
  String get commonStateCopied => 'Copied';

  @override
  String get commonStateSent => 'Sent';

  @override
  String get commonNoPaymentNowFull => 'No payment now. Nothing is charged until the hotel approves.';

  @override
  String get commonMoneyDeposit => 'Deposit';

  @override
  String get commonMoneyBalance => 'Remaining balance';

  @override
  String get commonMoneyTotal => 'Total';

  @override
  String get commonMoneyServiceCharge => 'Service charge';

  @override
  String get commonMoneyRentalFee => 'Rental fee';

  @override
  String get commonLabelOptional => 'Optional';

  @override
  String get commonLabelRequired => 'Required';

  @override
  String get commonLabelNotDecided => 'Not decided';

  @override
  String get commonLabelToday => 'Today';

  @override
  String get commonLabelTomorrow => 'Tomorrow';

  @override
  String get commonLabelKuwaitTime => 'Kuwait time';

  @override
  String get commonLabelSponsored => 'Sponsored';

  @override
  String get commonLabelNew => 'New';

  @override
  String get commonLabelOr => 'or';

  @override
  String get commonLabelLanguage => 'Language';

  @override
  String get commonLabelSettings => 'Settings';

  @override
  String get commonLanguageEnglish => 'English';

  @override
  String get commonLanguageArabic => 'Arabic';

  @override
  String get commonFieldRequired => 'This field is required.';

  @override
  String get commonFieldInvalid => 'This value isn’t valid.';

  @override
  String get commonFieldPhoneInvalid => 'This phone number isn’t valid.';

  @override
  String get commonA11yFavouriteAdd => 'Save to favourites';

  @override
  String get commonA11yFavouriteRemove => 'Remove from favourites';

  @override
  String get commonA11yCompareAdd => 'Add to compare';

  @override
  String get commonA11yCompareRemove => 'Remove from compare';

  @override
  String commonA11yPhotoCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Photo $currentString of $totalString';
  }

  @override
  String commonA11yRating(num rating, num max) {
    final intl.NumberFormat ratingNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String ratingString = ratingNumberFormat.format(rating);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return 'Rated $ratingString out of $maxString';
  }

  @override
  String get commonA11ySelected => 'Selected';

  @override
  String get commonStatusPending => 'Pending';

  @override
  String get commonStatusApproved => 'Approved';

  @override
  String get commonStatusRedeemed => 'Redeemed';

  @override
  String get commonStatusDeclined => 'Declined';

  @override
  String get commonStatusHotelPending => 'Pending';

  @override
  String get commonStatusHotelApproved => 'Waiting';

  @override
  String get commonStatusHotelRedeemed => 'Redeemed';

  @override
  String get commonStatusHotelDeclined => 'Declined';

  @override
  String get commonStatusHotelLapsed => 'Lapsed';

  @override
  String get commonStatusDateProposed => 'New date';

  @override
  String get commonVoucherStatusUnpaid => 'Paying';

  @override
  String get commonVoucherStatusActive => 'Ready';

  @override
  String get commonVoucherStatusBound => 'In request';

  @override
  String get commonVoucherStatusUsed => 'Used';

  @override
  String get commonVoucherStatusExpired => 'Expired';

  @override
  String get commonVisitStatusRequested => 'Requested';

  @override
  String get commonVisitStatusConfirmed => 'Confirmed';

  @override
  String get commonVisitStatusReschedule => 'New time';

  @override
  String get commonVisitStatusArrived => 'Arrived';

  @override
  String get commonVisitStatusCompleted => 'Done';

  @override
  String get commonVisitStatusDeclined => 'Unavailable';

  @override
  String get commonVisitStatusCancelled => 'Cancelled';

  @override
  String get commonVisitStatusMissed => 'Missed';

  @override
  String get commonListingStatusDraft => 'Draft';

  @override
  String get commonListingStatusPayment => 'Unpaid';

  @override
  String get commonListingStatusReview => 'In review';

  @override
  String get commonListingStatusApproved => 'Approved';

  @override
  String get commonListingStatusRejected => 'Declined';

  @override
  String get commonListingStatusActive => 'Live';

  @override
  String get commonListingStatusExpired => 'Ended';

  @override
  String get commonListingStatusPaused => 'Paused';

  @override
  String get commonVoucher => 'Voucher';

  @override
  String get commonVoucherPrice => 'Voucher price';

  @override
  String get commonStandardPrice => 'Standard price';

  @override
  String commonYouSave(String amount) {
    return 'You save $amount';
  }

  @override
  String commonSaveAmount(String amount) {
    return 'Save $amount';
  }

  @override
  String get commonConfirmBooking => 'Confirm booking';

  @override
  String get commonRedeemVoucher => 'Redeem voucher';

  @override
  String get commonVoucherCode => 'Voucher code';

  @override
  String commonValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get commonLabelGuestVoucher => 'Voucher price after you sign up';

  @override
  String get commonRoleClient => 'Client';

  @override
  String get commonRoleYou => 'You';

  @override
  String get commonRoleHotelRep => 'Hotel representative';

  @override
  String get commonRoleSupport => 'Ghazal support';

  @override
  String get commonVenueTypePrivateHall => 'Private hall';

  @override
  String get commonVenueTypeGovernmental => 'Governmental facility';

  @override
  String get commonVenueTypeHotel => 'Hotel';

  @override
  String get commonPricingPerPerson => 'Per person';

  @override
  String get commonPricingPackages => 'Packages';

  @override
  String get commonPricingPackage => 'Package';

  @override
  String get commonPricingStructure => 'Pricing';

  @override
  String get commonFilterGovernorate => 'Governorate';

  @override
  String get commonFilterVenueType => 'Venue type';

  @override
  String get commonFilterCapacity => 'Capacity';

  @override
  String get commonPlanWeekly => 'Weekly';

  @override
  String get commonPlanMonthly => 'Monthly';

  @override
  String get commonPlanAnnual => 'Annual';

  @override
  String get commonRatesSoon => 'Rates announced soon';

  @override
  String get commonExempt => 'Exempt';

  @override
  String get commonMajorHotel => 'Major hotel';

  @override
  String get commonA11yInfo => 'More info';

  @override
  String get commonLabelDetails => 'Details';

  @override
  String get commonVoucherStatusForfeited => 'Not valid';

  @override
  String get commonVoucherStatusCredit => 'Credit';

  @override
  String get commonVoucherStatusCreditIssued => 'Credit issued';

  @override
  String get commonVoucherCredit => 'Credit voucher';

  @override
  String get commonVoucherAnyVenue => 'Any hall, hotel or service';

  @override
  String commonVoucherNotValidNote(int hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hoursString hours', one: '$hoursString hour');
    return 'Not confirmed within $_temp0';
  }

  @override
  String commonVoucherConfirmIn24h(int hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(hours, locale: localeName, other: '$hoursString hours', one: '$hoursString hour');
    return 'Confirm at the hotel or service within $_temp0, or the voucher is not valid';
  }

  @override
  String get commonAskSupport => 'Ask support';

  @override
  String get commonCreditRequested => 'Request sent to support';

  @override
  String get commonBillingContract => 'Business contract';

  @override
  String get commonBillingPlan => 'Plan';

  @override
  String get commonBillingContractTerms => 'Terms as contracted';

  @override
  String get commonStaffInvitedByEmail => 'Invited by email';

  @override
  String get commonCalendarByEmail => 'Calendar by email';

  @override
  String get commonReviewAskSupportHide => 'Ask support to hide or delete';

  @override
  String commonVideoLimit(String size) {
    return 'Up to $size MB per video';
  }

  @override
  String get hotelAccessLanguageSwitch => 'Switch language';

  @override
  String get hotelAccessPasswordShow => 'Show password';

  @override
  String get hotelAccessPasswordHide => 'Hide password';

  @override
  String get hotelAccessPhotoAlt =>
      'Light-filled vaulted hall with skylights and arched windows, long banquet tables set with white linen and gold chairs on herringbone parquet';

  @override
  String get hotelAccessSupportTitle => 'Ghazal Support';

  @override
  String get hotelAccessSupportAction => 'Contact support';

  @override
  String get hotelAccessSupportShort => 'Support';

  @override
  String get hotelAccessAdminTitle => 'Account admin';

  @override
  String get hotelAccessAdminAction => 'Contact admin';

  @override
  String get hotelAccessSigninTitle => 'Sign in';

  @override
  String get hotelAccessSigninEmailLabel => 'Email';

  @override
  String get hotelAccessSigninPasswordLabel => 'Password';

  @override
  String get hotelAccessSigninForgot => 'Forgot?';

  @override
  String get hotelAccessSigninForgotLabel => 'Forgot password';

  @override
  String get hotelAccessSigninInvite => 'Invitation';

  @override
  String get hotelAccessSigninSubmit => 'Sign in';

  @override
  String get hotelAccessSigninInvalid => 'Incorrect details';

  @override
  String get hotelAccessSigninInvalidTitle => 'Not signed in';

  @override
  String get hotelAccessSigninInvalidDetail => 'The email or password is not correct. You are not signed in.';

  @override
  String get hotelAccessSigninPaused => 'Attempts paused';

  @override
  String hotelAccessSigninPausedDetail(String time) {
    return 'Attempts are paused. Try again after $time Kuwait time.';
  }

  @override
  String hotelAccessSigninPausedUntil(String time) {
    return 'Paused until $time';
  }

  @override
  String get hotelAccessInviteTitle => 'Invitation only';

  @override
  String get hotelAccessInviteStepLink => 'Email link';

  @override
  String get hotelAccessInviteStepCode => 'Code';

  @override
  String get hotelAccessInviteSteps => 'How an invitation works';

  @override
  String get hotelAccessInviteLink => 'Open link';

  @override
  String hotelAccessInviteFrom(String name) {
    return 'Invited by $name';
  }

  @override
  String get hotelAccessVerifyTitle => 'Enter code';

  @override
  String get hotelAccessVerifyLabel => 'Verification code';

  @override
  String get hotelAccessVerifyStepEmail => 'Email';

  @override
  String hotelAccessVerifySentTo(String email) {
    return 'Code sent by email to $email';
  }

  @override
  String get hotelAccessVerifySubmit => 'Verify';

  @override
  String get hotelAccessVerifyWrong => 'Wrong code';

  @override
  String hotelAccessVerifyAttemptsLeft(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString attempts remaining',
      one: '$countString attempt remaining',
      zero: 'No attempts remaining',
    );
    return '$_temp0';
  }

  @override
  String get hotelAccessVerifyExpired => 'Code expired';

  @override
  String get hotelAccessVerifyTooMany => 'Too many attempts';

  @override
  String get hotelAccessVerifyResent => 'Code sent';

  @override
  String hotelAccessVerifyTimer(String count) {
    return '${count}s';
  }

  @override
  String hotelAccessVerifyResendIn(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString seconds', one: '$countString second');
    return 'Resend code in $_temp0';
  }

  @override
  String get hotelAccessVerifyResend => 'Resend';

  @override
  String get hotelAccessVerifyFailed => 'Not delivered';

  @override
  String get hotelAccessVerifyFailedDetail => 'The code could not be sent by email. Send it again, or contact Support.';

  @override
  String get hotelAccessVerifySuccessTitle => 'Device trusted';

  @override
  String hotelAccessVerifyTrustDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString days', one: '$countString day');
    return 'Trusted for $_temp0';
  }

  @override
  String hotelAccessVerifyTrustFact(String count) {
    return '${count}d';
  }

  @override
  String get hotelAccessVerifySteps => 'Verification steps';

  @override
  String hotelAccessVerifyStepCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $currentString of $totalString';
  }

  @override
  String get hotelAccessAuthTitle => 'Authenticator code';

  @override
  String get hotelAccessStepupTitle => 'Confirm identity';

  @override
  String get hotelAccessStepupActionInvite => 'Invite staff';

  @override
  String get hotelAccessStepupActionRemove => 'Remove staff';

  @override
  String get hotelAccessStepupActionBilling => 'Billing details';

  @override
  String get hotelAccessStepupDone => 'Confirmed';

  @override
  String get hotelAccessSetupTitle => 'New password';

  @override
  String get hotelAccessSetupCardLabel => 'Invitation';

  @override
  String get hotelAccessSetupInvitedEmail => 'Invited email';

  @override
  String hotelAccessSetupValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get hotelAccessSetupRoleInfo => 'What this role can do';

  @override
  String get hotelAccessSetupPasswordLabel => 'Password';

  @override
  String get hotelAccessSetupConfirmLabel => 'Confirm';

  @override
  String get hotelAccessSetupMismatch => 'Doesn’t match';

  @override
  String hotelAccessSetupStrength(String level) {
    return 'Password strength: $level';
  }

  @override
  String get hotelAccessSetupStrengthWeak => 'Weak';

  @override
  String get hotelAccessSetupStrengthFair => 'Fair';

  @override
  String get hotelAccessSetupStrengthStrong => 'Strong';

  @override
  String hotelAccessSetupRuleLength(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString characters', one: '$countString character');
    return 'At least $_temp0';
  }

  @override
  String get hotelAccessSetupRuleMix => 'A letter and a number';

  @override
  String get hotelAccessSetupRuleMet => 'Done';

  @override
  String get hotelAccessSetupRuleOpen => 'Not yet';

  @override
  String get hotelAccessSetupError => 'Not saved';

  @override
  String get hotelAccessSetupErrorDetail => 'We could not save your password. Nothing was changed. Please try again.';

  @override
  String get hotelAccessSetupSuccessTitle => 'Password saved';

  @override
  String get hotelAccessSetupExpiredTitle => 'Invitation expired';

  @override
  String get hotelAccessSetupExpiredDetail => 'Invitations stop working after a few days. Your account admin or Ghazal Support can send a new one.';

  @override
  String get hotelAccessSetupUsedTitle => 'Invitation used';

  @override
  String get hotelAccessSetupUsedDetail => 'Your password is already set. Sign in with your email and password.';

  @override
  String get hotelAccessStatusUnderReviewTitle => 'Under review';

  @override
  String get hotelAccessStatusUnderReviewBody => 'Your account is under review. We will email you when it is active.';

  @override
  String get hotelAccessStatusUnderReviewProviderNote =>
      'Your first listing is reviewed by Ghazal before it goes live. Nothing is published automatically.';

  @override
  String get hotelAccessStatusSuspendedTitle => 'Suspended';

  @override
  String get hotelAccessStatusSuspendedBody => 'This account is suspended. Contact Ghazal Support.';

  @override
  String get hotelAccessStatusDeactivatedTitle => 'Access off';

  @override
  String get hotelAccessStatusDeactivatedBody => 'Your access to this account has been turned off. Contact your account admin.';

  @override
  String get hotelAccessStatusRevokedTitle => 'Session ended';

  @override
  String get hotelAccessStatusRevokedBody => 'An account admin ended this session. Sign in again.';

  @override
  String get hotelAccessStatusNoAccessBody => 'You do not have access. Ask your manager.';

  @override
  String get hotelAccessStatusSignOut => 'Sign out';

  @override
  String get hotelAccessStatusSwitchVenue => 'Switch venue';

  @override
  String get hotelAccessStatusActive => 'Active';

  @override
  String get hotelBookingsTitle => 'Bookings';

  @override
  String get hotelBookingsSearch => 'Search bookings';

  @override
  String get hotelBookingsSearchPlaceholder => 'Name, reference, date';

  @override
  String get hotelBookingsFilterByDate => 'Filter by date';

  @override
  String get hotelBookingsSegments => 'Booking views';

  @override
  String get hotelBookingsSegPending => 'Pending';

  @override
  String get hotelBookingsSegUpcoming => 'Upcoming';

  @override
  String get hotelBookingsSegPast => 'Past';

  @override
  String get hotelBookingsWaitingTitle => 'Awaiting couple';

  @override
  String hotelBookingsOpenRequest(String date) {
    return 'Open request: $date';
  }

  @override
  String hotelBookingsTimeLeft(String time) {
    return '$time remaining';
  }

  @override
  String get hotelBookingsAudienceWomen => 'Ladies';

  @override
  String get hotelBookingsAudienceMen => 'Men';

  @override
  String get hotelBookingsAudienceMixed => 'Mixed';

  @override
  String get hotelBookingsVerified => 'Verified phone';

  @override
  String get hotelBookingsFirstBooking => 'First booking';

  @override
  String hotelBookingsMessageName(String name) {
    return 'Message $name';
  }

  @override
  String hotelBookingsCallName(String name) {
    return 'Call $name';
  }

  @override
  String get hotelBookingsSpecialRequests => 'Special requests';

  @override
  String get hotelBookingsHeldLine => 'Date held';

  @override
  String hotelBookingsOthersSameDate(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$countString other requests for this date',
      one: '+$countString other request for this date',
    );
    return '$_temp0';
  }

  @override
  String get hotelBookingsCompare => 'Compare';

  @override
  String get hotelBookingsViewOnly => 'View only';

  @override
  String get hotelBookingsOfflineShort => 'Offline';

  @override
  String hotelBookingsOfflineBanner(String time) {
    return 'Offline · updated $time';
  }

  @override
  String get hotelBookingsProposeDate => 'Propose another date';

  @override
  String get hotelBookingsEmptyPendingTitle => 'No pending requests';

  @override
  String get hotelBookingsSeeUpcoming => 'View upcoming';

  @override
  String get hotelBookingsNextEvent => 'Next event';

  @override
  String get hotelBookingsEmptyUpcomingTitle => 'No bookings';

  @override
  String get hotelBookingsPastFilter => 'Filter past bookings';

  @override
  String hotelBookingsNoResultsTitle(String query) {
    return 'No match for $query';
  }

  @override
  String get hotelBookingsRecentTitle => 'Recent';

  @override
  String hotelBookingsAcceptedToast(String name) {
    return 'Approved · $name';
  }

  @override
  String get hotelBookingsAwaitingCouple => 'Awaiting the couple';

  @override
  String hotelBookingsConfirmLeft(String time) {
    return '$time to confirm';
  }

  @override
  String get hotelBookingsNotRedeemed => 'Voucher not redeemed';

  @override
  String hotelBookingsRedeemedBy(String name, String date) {
    return 'Redeemed by $name, $date';
  }

  @override
  String get hotelBookingsRedeemedPlain => 'Redeemed';

  @override
  String get hotelBookingsActorVenue => 'Hotel';

  @override
  String get hotelBookingsActorGhazal => 'Ghazal';

  @override
  String get hotelBookingsActorSystem => 'System';

  @override
  String get hotelBookingsActorClient => 'Client';

  @override
  String get hotelBookingsByVenue => 'Cancelled by the hotel';

  @override
  String get hotelBookingsByClient => 'Cancelled by the client';

  @override
  String get hotelBookingsDeclineDate => 'Date unavailable';

  @override
  String get hotelBookingsDeclineCapacity => 'Capacity';

  @override
  String get hotelBookingsDeclinePackage => 'Package';

  @override
  String get hotelBookingsDeclineOther => 'Other';

  @override
  String get hotelBookingsDeclineReason => 'Reason';

  @override
  String hotelBookingsSilence(String time) {
    return 'No reply for $time';
  }

  @override
  String get hotelBookingsFactsLabel => 'Details';

  @override
  String get hotelBookingsFactDate => 'Event date';

  @override
  String get hotelBookingsFactGuests => 'Guests';

  @override
  String get hotelBookingsFactHall => 'Hall';

  @override
  String get hotelBookingsFactTime => 'Time';

  @override
  String get hotelBookingsSessionDay => 'Day session';

  @override
  String get hotelBookingsSessionAfternoon => 'Afternoon session';

  @override
  String get hotelBookingsSessionEvening => 'Evening session';

  @override
  String hotelBookingsBillable(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString guests', one: '$countString guest');
    return 'Billed for $_temp0';
  }

  @override
  String get hotelBookingsFilterTitle => 'Dates';

  @override
  String get hotelBookingsFilterBy => 'Filter by';

  @override
  String get hotelBookingsFilterEvent => 'Event';

  @override
  String get hotelBookingsFilterRequest => 'Request';

  @override
  String hotelBookingsRangeLine(String from, String to) {
    return '$from – $to';
  }

  @override
  String get hotelBookingsRangeApplied => 'Date filter applied';

  @override
  String get hotelBookingsDetailTitle => 'Booking';

  @override
  String hotelBookingsReplyLeft(String time) {
    return '$time to reply';
  }

  @override
  String get hotelBookingsDaysToGo => 'Days to go';

  @override
  String get hotelBookingsEventToday => 'Event today';

  @override
  String get hotelBookingsKnotVoucher => 'Voucher';

  @override
  String get hotelBookingsKnotRequest => 'Request';

  @override
  String get hotelBookingsKnotApproval => 'Approval';

  @override
  String get hotelBookingsKnotConfirmed => 'Confirmed';

  @override
  String get hotelBookingsKnotRedeemed => 'Redeemed';

  @override
  String get hotelBookingsProgressLabel => 'Booking progress';

  @override
  String hotelBookingsStepOf(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String get hotelBookingsIssueReported => 'Client reported an issue';

  @override
  String get hotelBookingsIssueLink => 'Support';

  @override
  String get hotelBookingsCreateWindow => 'Set price';

  @override
  String get hotelBookingsDateFreeAgain => 'Date free';

  @override
  String get hotelBookingsShowMore => 'Show more';

  @override
  String get hotelBookingsShowLess => 'Show less';

  @override
  String get hotelBookingsRowServiceDate => 'Service date';

  @override
  String get hotelBookingsEventTitle => 'Event';

  @override
  String get hotelBookingsRowPackage => 'Package';

  @override
  String get hotelBookingsRowExtras => 'Extras';

  @override
  String get hotelBookingsRowHall => 'Hall';

  @override
  String get hotelBookingsRowDate => 'Date';

  @override
  String get hotelBookingsRowTime => 'Time';

  @override
  String get hotelBookingsRowRedeemedBy => 'Redeemed by';

  @override
  String get hotelBookingsPriceTitle => 'Price';

  @override
  String get hotelBookingsClientSaves => 'Client saves';

  @override
  String get hotelBookingsInfoPriceTitle => 'Voucher price';

  @override
  String get hotelBookingsDirectNote => 'You collect this directly from the client. Ghazal never shows a payment status.';

  @override
  String get hotelBookingsVoucherBound => 'In request';

  @override
  String get hotelBookingsVoucherRedeemed => 'Redeemed';

  @override
  String get hotelBookingsVoucherReturned => 'Returned';

  @override
  String get hotelBookingsVoucherExpired => 'Expired';

  @override
  String get hotelBookingsVoucherNotValid => 'Not valid';

  @override
  String get hotelBookingsProposalTitle => 'New dates';

  @override
  String get hotelBookingsProposalWindow => 'Couple answers by';

  @override
  String get hotelBookingsPriceChanged => 'Price changes';

  @override
  String get hotelBookingsInfoReturned => 'The client’s voucher went back to them. The date is free again.';

  @override
  String get hotelBookingsInfoClientUsed => 'The client cancelled after confirming, so their voucher is used up. The date is free again.';

  @override
  String get hotelBookingsInfoVenue => 'The client’s voucher was returned. They can ask support for credit. A reliability strike was recorded.';

  @override
  String get hotelBookingsMarkCompleted => 'Complete';

  @override
  String get hotelBookingsCancelBooking => 'Cancel booking';

  @override
  String get hotelBookingsCancelInfoTitle => 'Cancellation';

  @override
  String get hotelBookingsCancelNote => 'The client’s voucher goes back to them. They can ask support for credit. A reliability strike is recorded.';

  @override
  String get hotelBookingsRevokeApproval => 'Revoke approval';

  @override
  String get hotelBookingsReplyToReview => 'Reply';

  @override
  String get hotelBookingsCompletedToast => 'Completed';

  @override
  String get hotelBookingsAuditTitle => 'History';

  @override
  String get hotelBookingsAuditRequested => 'Received';

  @override
  String get hotelBookingsAuditApproved => 'Approved';

  @override
  String get hotelBookingsAuditConfirmed => 'Confirmed';

  @override
  String get hotelBookingsAuditRedeemed => 'Redeemed';

  @override
  String get hotelBookingsAuditDeclined => 'Declined';

  @override
  String get hotelBookingsAuditExpired => 'Missed';

  @override
  String get hotelBookingsAuditLapsed => 'Lapsed';

  @override
  String get hotelBookingsAuditRevoked => 'Revoked';

  @override
  String get hotelBookingsAuditCancelled => 'Cancelled';

  @override
  String get hotelBookingsAuditCompleted => 'Completed';

  @override
  String get hotelBookingsAuditProposal => 'New date';

  @override
  String get hotelBookingsAuditUpdated => 'Updated';

  @override
  String get hotelBookingsChatRow => 'Chat';

  @override
  String get hotelBookingsNotShared => 'Number not shared';

  @override
  String get hotelBookingsContactPrivacy => 'This number is shown for this booking only. The client’s voucher code appears only when you redeem it.';

  @override
  String get hotelBookingsContactOffline => 'You’re offline. Calls still work; messages send when you reconnect.';

  @override
  String get hotelBookingsRoleNoContact => 'Your role cannot contact clients. Ask your manager.';

  @override
  String hotelBookingsCallToast(String name) {
    return 'Calling $name';
  }

  @override
  String hotelBookingsWhatsappToast(String name) {
    return 'WhatsApp $name';
  }

  @override
  String get hotelBookingsRedeemMode => 'Entry method';

  @override
  String get hotelBookingsModeScan => 'Scan';

  @override
  String get hotelBookingsModeType => 'Code';

  @override
  String get hotelBookingsTypeCode => 'Type code';

  @override
  String get hotelBookingsScanDemo => 'Simulate';

  @override
  String get hotelBookingsTorchOn => 'Torch on';

  @override
  String get hotelBookingsTorchOff => 'Torch off';

  @override
  String get hotelBookingsCameraDeniedTitle => 'Camera is off';

  @override
  String get hotelBookingsCameraDeniedBody => 'Allow the camera in your phone settings to scan, or type the code instead.';

  @override
  String get hotelBookingsCheckCode => 'Check code';

  @override
  String get hotelBookingsChecking => 'Checking';

  @override
  String get hotelBookingsTryAnother => 'Try another';

  @override
  String get hotelBookingsErrUnknownField => 'Code not found';

  @override
  String get hotelBookingsErrUnknownTitle => 'Code not found';

  @override
  String get hotelBookingsErrUnknownBody => 'Check it and try again.';

  @override
  String get hotelBookingsErrOtherTitle => 'Another venue’s voucher';

  @override
  String get hotelBookingsErrOtherBody => 'It can only be redeemed by the venue it was issued for. No other details are shown.';

  @override
  String get hotelBookingsErrNotConfirmedTitle => 'Not confirmed yet';

  @override
  String get hotelBookingsErrNotConfirmedBody => 'The client has to confirm the booking before the voucher can be redeemed.';

  @override
  String get hotelBookingsErrUsedPlain => 'Already used';

  @override
  String get hotelBookingsErrUsedBody => 'A voucher works once. Contact support if this looks wrong.';

  @override
  String get hotelBookingsErrExpiredTitle => 'Not valid';

  @override
  String get hotelBookingsErrExpiredBody => 'It can no longer be redeemed.';

  @override
  String get hotelBookingsRedeemErrorBody => 'Nothing was changed. Please try again.';

  @override
  String get hotelBookingsRoleHiddenBody => 'Ask an Admin, a Manager or Reception to redeem it.';

  @override
  String get hotelBookingsRedeemFine => 'Redeeming cannot be undone. Support can adjust it if a mistake is made.';

  @override
  String get hotelBookingsRedeemedFine => 'The client pays you directly. Ghazal shows no amount due.';

  @override
  String hotelBookingsRedeemedCached(String time) {
    return 'Offline · saved $time';
  }

  @override
  String get hotelBookingsViewBooking => 'View booking';

  @override
  String get hotelBookingsProtoTag => 'Demo';

  @override
  String get hotelBookingsProtoTitle => 'Prototype shortcuts';

  @override
  String get hotelBookingsProtoReady => 'Ready voucher';

  @override
  String get hotelBookingsProtoNotConfirmed => 'Not confirmed';

  @override
  String get hotelBookingsProtoUsed => 'Already used';

  @override
  String get hotelBookingsProtoOther => 'Other venue';

  @override
  String get hotelBookingsBackToList => 'Bookings';

  @override
  String hotelBookingsDurJoin(String first, String second) {
    return '$first $second';
  }

  @override
  String get hotelCalendarTitle => 'Calendar';

  @override
  String get hotelCalendarViewLabel => 'Calendar view';

  @override
  String get hotelCalendarViewMonth => 'Month';

  @override
  String get hotelCalendarViewWeek => 'Week';

  @override
  String get hotelCalendarViewDay => 'Day';

  @override
  String get hotelCalendarHallsLabel => 'Halls';

  @override
  String get hotelCalendarHallsAll => 'All';

  @override
  String hotelCalendarGridLabel(String month) {
    return 'Calendar, $month';
  }

  @override
  String get hotelCalendarPrevWeek => 'Previous week';

  @override
  String get hotelCalendarNextWeek => 'Next week';

  @override
  String get hotelCalendarPrevDay => 'Previous day';

  @override
  String get hotelCalendarNextDay => 'Next day';

  @override
  String get hotelCalendarWeekLabel => 'Week';

  @override
  String get hotelCalendarActionBlock => 'Block dates';

  @override
  String get hotelCalendarActionSelect => 'Select dates';

  @override
  String get hotelCalendarReadOnly => 'View only';

  @override
  String hotelCalendarOfflineStamp(String time) {
    return 'Offline · $time';
  }

  @override
  String get hotelCalendarOfflineNeed => 'Needs a connection';

  @override
  String get hotelCalendarNudgeTitle => 'Calendar up to date?';

  @override
  String get hotelCalendarNudgeDone => 'Calendar confirmed';

  @override
  String get hotelCalendarEmptyTitle => 'Nothing booked';

  @override
  String hotelCalendarAgendaTitle(String date) {
    return 'Agenda, $date';
  }

  @override
  String get hotelCalendarOpenDay => 'Open day';

  @override
  String get hotelCalendarOpenLabel => 'Open';

  @override
  String get hotelCalendarRequestedLabel => 'Requested';

  @override
  String hotelCalendarBlockedBy(String name) {
    return 'Blocked by $name';
  }

  @override
  String get hotelCalendarBlock => 'Block';

  @override
  String get hotelCalendarOffer => 'Offer';

  @override
  String get hotelCalendarCreateOffer => 'Create offer';

  @override
  String get hotelCalendarOpenThisDate => 'Open date';

  @override
  String get hotelCalendarWhyTitle => 'Can’t block';

  @override
  String get hotelCalendarSoldOutReason => 'A confirmed booking can’t be blocked. Cancel it first.';

  @override
  String get hotelCalendarSoftTitle => 'Open weekends';

  @override
  String hotelCalendarSoftRow(int count, String days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString open weekend dates in the next $days days',
      one: '$countString open weekend date in the next $days days',
      zero: 'No open weekend dates in the next $days days',
    );
    return '$_temp0';
  }

  @override
  String get hotelCalendarLegendSoft => 'Open weekend';

  @override
  String get hotelCalendarHallFact => 'Hall';

  @override
  String get hotelCalendarGuestsFact => 'Guests';

  @override
  String get hotelCalendarCapacityFact => 'Capacity';

  @override
  String get hotelCalendarSessionFact => 'Session';

  @override
  String get hotelCalendarHoldLeft => 'Time remaining';

  @override
  String get hotelCalendarStartsFact => 'Starts in';

  @override
  String get hotelCalendarBlockedByFact => 'Blocked by';

  @override
  String get hotelCalendarAudienceWomen => 'Ladies';

  @override
  String get hotelCalendarAudienceMen => 'Men';

  @override
  String get hotelCalendarAudienceMixed => 'Mixed';

  @override
  String get hotelCalendarKeyTitle => 'Key';

  @override
  String get hotelCalendarRequestNote => 'A request does not hold the date.';

  @override
  String get hotelCalendarTimes => 'Times';

  @override
  String get hotelCalendarSetup => 'Setup';

  @override
  String get hotelCalendarEvent => 'Event';

  @override
  String get hotelCalendarTeardown => 'Teardown';

  @override
  String hotelCalendarTimelineLabel(String hall) {
    return '$hall, timeline';
  }

  @override
  String get hotelCalendarOpenBooking => 'Open booking';

  @override
  String hotelCalendarCall(String name) {
    return 'Call $name';
  }

  @override
  String hotelCalendarMessage(String name) {
    return 'Message $name';
  }

  @override
  String get hotelCalendarHintDrag => 'Press and hold a date, then drag to the last one.';

  @override
  String get hotelCalendarHintTap => 'Or tap the first date, then the last.';

  @override
  String get hotelCalendarRangeNone => 'Choose dates';

  @override
  String get hotelCalendarRangeSummary => 'Dates';

  @override
  String get hotelCalendarRangeBlock => 'Block';

  @override
  String get hotelCalendarRangeOpen => 'Open';

  @override
  String get hotelCalendarRangeOffer => 'Offer';

  @override
  String get hotelCalendarSheetBlockTitle => 'Block dates';

  @override
  String get hotelCalendarSheetOpenTitle => 'Open dates';

  @override
  String get hotelCalendarModeLabel => 'Block or open';

  @override
  String get hotelCalendarModeBlock => 'Block';

  @override
  String get hotelCalendarModeOpen => 'Open';

  @override
  String get hotelCalendarSumEdit => 'Change dates';

  @override
  String get hotelCalendarShortcuts => 'Shortcuts';

  @override
  String get hotelCalendarSession => 'Session';

  @override
  String get hotelCalendarReason => 'Reason';

  @override
  String get hotelCalendarNote => 'Note';

  @override
  String get hotelCalendarReasonOffline => 'Booked offline';

  @override
  String get hotelCalendarReasonMaintenance => 'Maintenance';

  @override
  String get hotelCalendarReasonPrivate => 'Private event';

  @override
  String get hotelCalendarReasonOther => 'Other';

  @override
  String get hotelCalendarVisibilityHint => 'Couples stop seeing blocked dates within seconds.';

  @override
  String get hotelCalendarOpenHint => 'Opened dates go back on sale for couples.';

  @override
  String hotelCalendarPendingWarn(int count, String date) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date has $countString pending requests. They will be marked unavailable.',
      one: '$date has $countString pending request. It will be marked unavailable.',
      zero: 'No pending requests on $date',
    );
    return '$_temp0';
  }

  @override
  String get hotelCalendarConflictBody => 'A date with a confirmed booking can’t be blocked. Cancel the booking first.';

  @override
  String get hotelCalendarConflictTip => 'Or choose only the hall that is free.';

  @override
  String get hotelCalendarConflictCancel => 'Cancel booking';

  @override
  String get hotelCalendarReasonConflict => 'Free dates only';

  @override
  String get hotelCalendarReasonChoose => 'Pick dates first';

  @override
  String get hotelCalendarAlreadyBlocked => 'Already blocked';

  @override
  String hotelCalendarCtaBlock(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Block $countString dates',
      one: 'Block $countString date',
      zero: 'Block',
    );
    return '$_temp0';
  }

  @override
  String hotelCalendarCtaOpen(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Open $countString dates', one: 'Open $countString date', zero: 'Open');
    return '$_temp0';
  }

  @override
  String get hotelCalendarOpenListTitle => 'Blocked dates';

  @override
  String get hotelCalendarOpenEmpty => 'No blocked dates';

  @override
  String get hotelCalendarToastBlocked => 'Hidden from couples';

  @override
  String get hotelCalendarToastOpened => 'Open for booking';

  @override
  String get hotelCalendarPartialTitle => 'Some dates skipped';

  @override
  String get hotelCalendarSaveFailed => 'Couldn’t save';

  @override
  String get hotelCalendarEmailTitle => 'Calendar by email';

  @override
  String get hotelCalendarEmailSwitch => 'Invite me by email';

  @override
  String get hotelCalendarEmailAdd => 'Another address';

  @override
  String get hotelCalendarEmailInvalid => 'Check the address';

  @override
  String get hotelCalendarEmailTest => 'Send a test';

  @override
  String get hotelCalendarEmailTestSent => 'Test sent';

  @override
  String get hotelDecisionsFactsLabel => 'Details';

  @override
  String get hotelDecisionsFactDate => 'Date';

  @override
  String get hotelDecisionsFactGuests => 'Guests';

  @override
  String get hotelDecisionsFactSession => 'Session';

  @override
  String get hotelDecisionsFactLadies => 'Ladies';

  @override
  String get hotelDecisionsFactMen => 'Men';

  @override
  String get hotelDecisionsFactMixed => 'Mixed';

  @override
  String get hotelDecisionsOfflineInfo => 'Decisions are never queued, so nothing is half-sent.';

  @override
  String get hotelDecisionsTermsTitle => 'Terms';

  @override
  String get hotelDecisionsReason => 'Reason';

  @override
  String get hotelDecisionsPickReason => 'Pick a reason';

  @override
  String get hotelDecisionsNote => 'Note';

  @override
  String get hotelDecisionsNoteHelper => 'Client sees this';

  @override
  String get hotelDecisionsNoteRequired => 'Note required';

  @override
  String get hotelDecisionsViewBooking => 'View request';

  @override
  String get hotelDecisionsRefresh => 'Refresh';

  @override
  String get hotelDecisionsAcceptTitle => 'Accept request';

  @override
  String get hotelDecisionsAcceptCta => 'Accept';

  @override
  String hotelDecisionsAcceptConsequence(String date, String name, String duration) {
    return 'This holds <f>$date</f> for <n>$name</n> for <f>$duration</f>.';
  }

  @override
  String get hotelDecisionsAcceptConfirmRule => 'If the client does not confirm, the date is released and their voucher goes back to them.';

  @override
  String get hotelDecisionsAcceptPriceHint => 'Paid to you directly, outside the app, after the client confirms.';

  @override
  String get hotelDecisionsAcceptLowerHint => 'A lower voucher price is optional and never higher than the quote. The client sees the new saving.';

  @override
  String hotelDecisionsAcceptHoldLabel(String duration) {
    return 'Date held for $duration';
  }

  @override
  String get hotelDecisionsAcceptDeadlineLabel => 'Client confirms by';

  @override
  String get hotelDecisionsAcceptOffApp => 'Off-app';

  @override
  String hotelDecisionsAcceptOthersLine(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString other requests for this date',
      one: '$countString other request for this date',
    );
    return '$_temp0';
  }

  @override
  String get hotelDecisionsAcceptCompare => 'Compare';

  @override
  String get hotelDecisionsAcceptCompareThis => 'This';

  @override
  String get hotelDecisionsAcceptCompareOther => 'Other';

  @override
  String get hotelDecisionsAcceptCompareReceived => 'Received';

  @override
  String get hotelDecisionsAcceptLower => 'Lower price';

  @override
  String get hotelDecisionsAcceptLowerLabel => 'Reduce by';

  @override
  String get hotelDecisionsAcceptLowerTooHigh => 'Below the voucher price';

  @override
  String get hotelDecisionsAcceptedTitle => 'Approved';

  @override
  String hotelDecisionsAcceptedBody(String name, String deadline) {
    return 'The date is held for <n>$name</n>, who has until <f>$deadline</f> to confirm.';
  }

  @override
  String get hotelDecisionsAcceptedUndoHint => 'The client is told in a few seconds. Undo until then.';

  @override
  String get hotelDecisionsNotifying => 'Notifying client';

  @override
  String get hotelDecisionsUndoneTitle => 'Back to pending';

  @override
  String get hotelDecisionsUndoneBody => 'The date is released and the client was not told.';

  @override
  String get hotelDecisionsConflictTitle => 'Date on hold';

  @override
  String hotelDecisionsConflictBody(String date) {
    return 'Another client’s approved request holds <f>$date</f> while they confirm. You can still offer a different date.';
  }

  @override
  String get hotelDecisionsAlreadyTitle => 'Already updated';

  @override
  String get hotelDecisionsAlreadyBody => 'Someone on your team or the client changed it a moment ago. This is where it stands now.';

  @override
  String get hotelDecisionsReleasedTitle => 'Request withdrawn';

  @override
  String get hotelDecisionsReleasedBody =>
      'The client’s voucher is no longer attached to your venue, so there is nothing to approve. The request leaves your list.';

  @override
  String get hotelDecisionsDeclineTitle => 'Decline request';

  @override
  String get hotelDecisionsDeclineReasonDate => 'Date';

  @override
  String get hotelDecisionsDeclineReasonCapacity => 'Capacity';

  @override
  String get hotelDecisionsDeclineReasonPackage => 'Package';

  @override
  String get hotelDecisionsDeclineReasonOther => 'Other';

  @override
  String get hotelDecisionsDeclineSuggestTitle => 'Suggest dates';

  @override
  String get hotelDecisionsDeclineSuggestBody => 'The client will see a gentle message and venues that are free on the same date.';

  @override
  String get hotelDecisionsDeclineVoucher => 'Voucher returns';

  @override
  String get hotelDecisionsDeclineVoucherInfo => 'The client’s voucher goes back to them. Declining has no payment consequence.';

  @override
  String get hotelDecisionsDeclineNoUndo => 'A decline cannot be undone.';

  @override
  String get hotelDecisionsDeclineNoUndoShort => 'Can’t undo';

  @override
  String get hotelDecisionsDeclineCtaNext => 'Choose dates';

  @override
  String get hotelDecisionsDeclineCta => 'Decline';

  @override
  String get hotelDecisionsDeclinedTitle => 'Declined';

  @override
  String get hotelDecisionsDeclinedBody => 'The client has been told and their voucher is back with them.';

  @override
  String get hotelDecisionsProposeTitle => 'Propose date';

  @override
  String hotelDecisionsProposeIntro(String window) {
    return 'Pick one to three free dates for the same hall and session. The client has $window to reply.';
  }

  @override
  String hotelDecisionsProposeHold(String amount) {
    return 'Every date keeps the quoted voucher price of $amount. If a date normally costs more, you cover the difference.';
  }

  @override
  String get hotelDecisionsProposeHallLabel => 'Hall';

  @override
  String hotelDecisionsProposeCalendarLabel(String hall) {
    return 'Free dates for $hall';
  }

  @override
  String get hotelDecisionsProposeOriginal => 'Original date';

  @override
  String get hotelDecisionsProposeChosen => 'Your proposal';

  @override
  String hotelDecisionsProposeRemove(String date) {
    return 'Remove $date';
  }

  @override
  String get hotelDecisionsProposeTakenBadge => 'Date taken';

  @override
  String get hotelDecisionsProposeHeldLabel => 'Voucher price held';

  @override
  String get hotelDecisionsProposeLowerLabel => 'Lower by';

  @override
  String get hotelDecisionsProposeReplyLabel => 'Client reply window';

  @override
  String hotelDecisionsProposeCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dates chosen',
      one: '$countString date chosen',
      zero: 'No dates chosen',
    );
    return '$_temp0';
  }

  @override
  String get hotelDecisionsProposeCta => 'Send proposal';

  @override
  String get hotelDecisionsProposePick => 'Pick a date';

  @override
  String get hotelDecisionsProposeEmptyTitle => 'No free dates';

  @override
  String hotelDecisionsProposeEmpty(String days) {
    return 'No free dates in the next $days for this hall.';
  }

  @override
  String get hotelDecisionsProposeEmptyAction => 'Open calendar';

  @override
  String get hotelDecisionsProposeNoHallTitle => 'Agree in chat';

  @override
  String get hotelDecisionsProposeNoHallBody => 'A service request has no hall calendar. Reply to the client in the chat to agree another day.';

  @override
  String get hotelDecisionsProposeSentTitle => 'Proposal sent';

  @override
  String hotelDecisionsProposeSentBody(String duration) {
    return 'The request stays pending with your dates attached. If the client accepts one, a new $duration confirm window starts.';
  }

  @override
  String hotelDecisionsProposeAwaiting(String name, String deadline) {
    return 'Awaiting <n>$name</n> · answer due <f>$deadline</f>';
  }

  @override
  String hotelDecisionsToastProposed(String window) {
    return 'Proposal sent · $window';
  }

  @override
  String get hotelDecisionsCancelTitle => 'Cancel booking';

  @override
  String get hotelDecisionsCancelTitleApproved => 'Withdraw approval';

  @override
  String get hotelDecisionsCancelTalkTitle => 'Chat first';

  @override
  String get hotelDecisionsCancelTalkBody =>
      'A new date is agreed with the client in the chat. If the date moves, the client may need a new request.';

  @override
  String get hotelDecisionsCancelReasonHall => 'Unavailable';

  @override
  String get hotelDecisionsCancelReasonSafety => 'Safety work';

  @override
  String get hotelDecisionsCancelReasonOther => 'Other';

  @override
  String get hotelDecisionsCancelConsequence => 'What happens';

  @override
  String get hotelDecisionsCancelVoucherInfo => 'The client’s voucher goes back to them to use again.';

  @override
  String get hotelDecisionsCancelStrikeInfo => 'A reliability strike is recorded and the date opens again.';

  @override
  String get hotelDecisionsCancelNoMoney => 'No money moves in the app. Anything the client has already paid you is settled between the two of you.';

  @override
  String get hotelDecisionsConsReturned => 'Returned';

  @override
  String get hotelDecisionsConsStrike => 'Strike';

  @override
  String get hotelDecisionsConsReopens => 'Reopens';

  @override
  String get hotelDecisionsCancelCta => 'Cancel booking';

  @override
  String get hotelDecisionsCancelCtaApproved => 'Withdraw approval';

  @override
  String get hotelDecisionsCancelKeep => 'Keep booking';

  @override
  String get hotelDecisionsCancelKeepApproved => 'Keep approval';

  @override
  String get hotelDecisionsCancelDialogTitle => 'Cancel booking?';

  @override
  String get hotelDecisionsCancelDialogTitleApproved => 'Withdraw approval?';

  @override
  String hotelDecisionsCancelDialogBody(String name, String date) {
    return '<n>$name</n> · <f>$date</f>';
  }

  @override
  String get hotelDecisionsCancelledTitle => 'Cancelled';

  @override
  String get hotelDecisionsCancelledTitleApproved => 'Approval withdrawn';

  @override
  String get hotelDecisionsCancelledWindow => 'New offer';

  @override
  String get hotelDecisionsCancelHiddenTitle => 'Managers only';

  @override
  String get hotelDecisionsCancelHiddenBody => 'Only an Admin or Manager can cancel a confirmed booking.';

  @override
  String hotelGrowOfflineStamp(String time) {
    return 'Offline · updated $time';
  }

  @override
  String get hotelGrowErrorBody => 'Nothing was changed. Check your connection and try again.';

  @override
  String get hotelGrowTabsLabel => 'Voucher prices by state';

  @override
  String get hotelGrowTabActive => 'Active';

  @override
  String get hotelGrowTabScheduled => 'Scheduled';

  @override
  String get hotelGrowTabEnded => 'Ended';

  @override
  String get hotelGrowPaused => 'Paused';

  @override
  String get hotelGrowAppliesAll => 'All packages';

  @override
  String hotelGrowSoftInsight(int count, num days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString open weekend dates in the next $daysString days',
      one: '$countString open weekend date in the next $daysString days',
      zero: 'No open weekend dates in the next $daysString days',
    );
    return '$_temp0';
  }

  @override
  String get hotelGrowEmptyTitle => 'No time-boxed windows';

  @override
  String get hotelGrowNoScheduledTitle => 'Nothing scheduled';

  @override
  String get hotelGrowNoEndedTitle => 'No ended windows';

  @override
  String get hotelGrowShowActive => 'Show active prices';

  @override
  String get hotelGrowActionsLabel => 'Voucher price actions';

  @override
  String get hotelGrowStatStarts => 'Starts';

  @override
  String get hotelGrowPreviewWaiting => 'Enter a valid voucher price to see the card as couples will see it.';

  @override
  String get hotelGrowPreviewLabel => 'How couples see it';

  @override
  String get hotelGrowEffectNote => 'Pause and End take effect for couples at once.';

  @override
  String get hotelGrowPause => 'Pause window';

  @override
  String get hotelGrowResume => 'Resume window';

  @override
  String get hotelGrowDuplicate => 'Duplicate';

  @override
  String get hotelGrowEndNow => 'End now';

  @override
  String hotelGrowToastPaused(String title) {
    return '$title is paused. Couples see the standing voucher price.';
  }

  @override
  String hotelGrowToastResumed(String title) {
    return '$title is live again.';
  }

  @override
  String hotelGrowToastEnded(String title) {
    return '$title has ended.';
  }

  @override
  String hotelGrowEndTitle(String title) {
    return 'End $title now?';
  }

  @override
  String get hotelGrowEndBody =>
      'Couples go back to the standing voucher price at once. Requests already sent keep their price. This cannot be undone.';

  @override
  String get hotelGrowEndConfirm => 'End window';

  @override
  String get hotelGrowEndKeep => 'Keep window';

  @override
  String get hotelGrowStepsLabel => 'Voucher price window steps';

  @override
  String get hotelGrowValueTitle => 'Voucher price';

  @override
  String hotelGrowOverError(String max) {
    return 'The voucher price cannot be above the standard price, $max.';
  }

  @override
  String get hotelGrowEmptyValueError => 'Enter the voucher price in dinars, up to three decimals.';

  @override
  String get hotelGrowBestOnly => 'Only the best voucher price applies to a request. Prices do not stack.';

  @override
  String get hotelGrowScopeTitle => 'Applies to';

  @override
  String get hotelGrowPackagesLabel => 'Packages';

  @override
  String get hotelGrowHallsLabel => 'Halls';

  @override
  String get hotelGrowAllHalls => 'All halls';

  @override
  String get hotelGrowTitleTitle => 'Window title';

  @override
  String get hotelGrowTitleEn => 'Title in English';

  @override
  String get hotelGrowTitleAr => 'Title in Arabic';

  @override
  String get hotelGrowTitleComplete => 'Complete';

  @override
  String get hotelGrowCouplesSee => 'Couples see';

  @override
  String get hotelGrowNextReasonTitles => 'Add the title in both languages to continue.';

  @override
  String get hotelGrowNextReasonValue => 'Correct the voucher price to continue.';

  @override
  String get hotelGrowPrefilledTitle => 'For these dates';

  @override
  String get hotelGrowOfflineEdit => 'Offline. You can keep editing; publishing needs a connection.';

  @override
  String get hotelGrowGuardTitle => 'Discard this window?';

  @override
  String get hotelGrowGuardDiscard => 'Discard';

  @override
  String get hotelGrowGuardKeep => 'Keep editing';

  @override
  String get hotelGrowEditorErrorBody => 'Nothing was saved. Check your connection and try again.';

  @override
  String get hotelGrowDatesTitle => 'Event dates';

  @override
  String get hotelGrowShortcuts => 'Shortcuts';

  @override
  String get hotelGrowChooseDates => 'Choose dates myself';

  @override
  String get hotelGrowNoDatesError => 'Choose at least one event date.';

  @override
  String hotelGrowDatesChosen(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dates chosen',
      one: '$countString date chosen',
      zero: 'No dates chosen',
    );
    return '$_temp0';
  }

  @override
  String get hotelGrowClearDates => 'Clear';

  @override
  String get hotelGrowUseOpenDates => 'Use open weekend dates';

  @override
  String get hotelGrowOpenWeekend => 'Open weekend date';

  @override
  String hotelGrowOverlap(String title, String value, String dates) {
    return '$title at $value already covers $dates. The better voucher price applies.';
  }

  @override
  String get hotelGrowRunsTitle => 'When it runs';

  @override
  String get hotelGrowScheduledPill => 'Scheduled';

  @override
  String get hotelGrowStartsLabel => 'Starts on';

  @override
  String get hotelGrowEndsLabel => 'Ends on';

  @override
  String get hotelGrowEndBeforeStart => 'The end date is before the start date.';

  @override
  String get hotelGrowPublish => 'Publish window';

  @override
  String get hotelGrowSchedule => 'Schedule window';

  @override
  String get hotelGrowOfflinePublish => 'Reconnect to publish.';

  @override
  String get hotelGrowReasonDates => 'Choose the event dates first.';

  @override
  String get hotelGrowReasonEnd => 'Set a valid end date first.';

  @override
  String get hotelGrowPublishFailed => 'The window was not published. Nothing changed; try again.';

  @override
  String hotelGrowToastPublished(String title) {
    return '$title is live.';
  }

  @override
  String hotelGrowToastScheduled(String title) {
    return '$title is scheduled.';
  }

  @override
  String get hotelGrowView => 'View';

  @override
  String get hotelGrowAnTitle => 'Analytics';

  @override
  String get hotelGrowAnRangeLabel => 'Period';

  @override
  String get hotelGrowAnRangeMonth => 'This month';

  @override
  String hotelGrowAnRangeDays(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Last $daysString days';
  }

  @override
  String get hotelGrowAnRangeCustom => 'Custom';

  @override
  String hotelGrowAnRangeNote(String date) {
    return 'Data is available from $date.';
  }

  @override
  String get hotelGrowAnKpiViews => 'Views';

  @override
  String get hotelGrowAnKpiClicks => 'Clicks';

  @override
  String get hotelGrowAnKpiConversion => 'Conversion';

  @override
  String get hotelGrowAnVsPrevious => 'vs previous period';

  @override
  String hotelGrowAnChartDesc(String metric, String from, String to) {
    return '$metric, from $from to $to.';
  }

  @override
  String get hotelGrowAnAsTable => 'View as table';

  @override
  String get hotelGrowAnAsChart => 'View as chart';

  @override
  String get hotelGrowAnFunnelTitle => 'From view to voucher';

  @override
  String get hotelGrowAnFunnelDesc => 'Views, clicks, vouchers purchased, requests, confirmed bookings and redeemed vouchers in the period.';

  @override
  String get hotelGrowAnStageConfirmed => 'Confirmed';

  @override
  String get hotelGrowAnValueLabel => 'Count';

  @override
  String get hotelGrowAnTopTitle => 'Top packages';

  @override
  String get hotelGrowAnTopDesc => 'Confirmed bookings per package in the period.';

  @override
  String hotelGrowAnTopOpen(String name) {
    return 'Open $name';
  }

  @override
  String get hotelGrowAnDefsTitle => 'How we count';

  @override
  String hotelGrowAnDefViews(num minutes) {
    final intl.NumberFormat minutesNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'Each person counts once per $minutesString minutes, however many times they open your listing.';
  }

  @override
  String get hotelGrowAnDefClicks => 'Taps on Message, Call, Directions or Share after viewing your listing.';

  @override
  String hotelGrowAnDefConversion(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Confirmed bookings divided by views in the same period, credited to the last view within $daysString days.';
  }

  @override
  String get hotelGrowAnCustomTitle => 'Custom period';

  @override
  String hotelGrowAnCustomOutside(String date) {
    return 'Days before $date have no data.';
  }

  @override
  String get hotelGrowAnEmptyTitle => 'No data yet';

  @override
  String hotelGrowAnInsufBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Trends need at least $daysString days of views. The totals so far are below.';
  }

  @override
  String get hotelGrowAnRoleAnalytics => 'Your role sees listing performance only.';

  @override
  String get hotelGrowRwTitle => 'Reviews';

  @override
  String get hotelGrowRwCatVenue => 'Venue';

  @override
  String get hotelGrowRwCatFood => 'Food';

  @override
  String get hotelGrowRwCatService => 'Service';

  @override
  String get hotelGrowRwCatValue => 'Value';

  @override
  String get hotelGrowRwFilterLabel => 'Show reviews';

  @override
  String get hotelGrowRwFilterAll => 'All';

  @override
  String get hotelGrowRwFilterNeeds => 'Needs reply';

  @override
  String get hotelGrowRwFilterReplied => 'Replied';

  @override
  String get hotelGrowRwFilterReported => 'Reported';

  @override
  String get hotelGrowRwModerated => 'Ghazal moderates reviews. Reply once or report abuse. To hide or delete a review, ask support.';

  @override
  String get hotelGrowRwAskSupport => 'Ask support to hide or delete';

  @override
  String hotelGrowRwReplyTitle(String name) {
    return 'Reply to $name';
  }

  @override
  String get hotelGrowRwReplyHelp => 'Public, signed with the venue name, and sent once.';

  @override
  String get hotelGrowRwReplySend => 'Send reply';

  @override
  String get hotelGrowRwReplySent => 'Your reply is published.';

  @override
  String get hotelGrowRwReportTitle => 'Report this review';

  @override
  String get hotelGrowRwReportBody => 'Choose the reason. Ghazal reviews it and the review stays visible until then.';

  @override
  String get hotelGrowRwReasonAbuse => 'Abusive language';

  @override
  String get hotelGrowRwReasonOff => 'Not about this venue';

  @override
  String get hotelGrowRwReasonPersonal => 'Shares personal data';

  @override
  String get hotelGrowRwReasonOther => 'Other';

  @override
  String get hotelGrowRwReportSend => 'Report review';

  @override
  String get hotelGrowRwReported => 'Reported. Ghazal will review it.';

  @override
  String get hotelGrowRwEmptyTitle => 'No reviews yet';

  @override
  String get hotelGrowRwNoNeedsTitle => 'Every review has a reply';

  @override
  String get hotelGrowRwNoFilterTitle => 'Nothing here';

  @override
  String get hotelGrowRwShowAll => 'Show all reviews';

  @override
  String get hotelGrowRwAnonymous => 'Anonymous';

  @override
  String get hotelGrowRwSummaryLabel => 'Overall rating';

  @override
  String get hotelGrowListTitle => 'Voucher prices';

  @override
  String get hotelGrowNewWindow => 'New voucher price window';

  @override
  String get hotelGrowEditorTitle => 'Voucher price window';

  @override
  String get hotelGrowAlwaysOn => 'Always on';

  @override
  String get hotelGrowStandingTitle => 'Standing voucher prices';

  @override
  String get hotelGrowStandingEditCta => 'Edit package prices';

  @override
  String get hotelGrowStandingExplain =>
      'Every package with a voucher price shows it beside the standard price all the time. A window lowers it for chosen event dates.';

  @override
  String get hotelGrowStandingNote => 'Standing prices change in the package editor, not here.';

  @override
  String get hotelGrowStatRequests => 'Requests';

  @override
  String get hotelGrowStatConfirmed => 'Confirmed';

  @override
  String get hotelGrowStatVouchers => 'Vouchers bought';

  @override
  String get hotelGrowStatEnds => 'Ends';

  @override
  String get hotelGrowUnitPackage => 'per package';

  @override
  String get hotelGrowTitleSuggestion => 'Lower voucher price';

  @override
  String get hotelGrowPriceLabel => 'Voucher price per guest';

  @override
  String get hotelGrowPriceLabelFlat => 'Voucher price per package';

  @override
  String hotelGrowNoEffect(String standing) {
    return 'This is not below the standing voucher price of $standing, so it will not change what couples pay.';
  }

  @override
  String hotelGrowBelowFee(String fee) {
    return 'The saving would not be more than the $fee voucher fee, so couples are not offered a voucher at this price.';
  }

  @override
  String get hotelGrowRequestPrice => 'Request price';

  @override
  String get hotelGrowStandardPrice => 'Standard price';

  @override
  String get hotelGrowYouSave => 'Couples save';

  @override
  String hotelGrowFeeNote(String fee) {
    return 'Couples also pay Ghazal a $fee voucher fee. It is not part of your price and you do not collect it.';
  }

  @override
  String get hotelGrowOpenWeekends => 'Open weekend dates';

  @override
  String get hotelGrowWeekdays => 'Weekdays';

  @override
  String hotelGrowOpenWeekendsBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Open Thursday to Saturday dates in the next $daysString days';
  }

  @override
  String hotelGrowWeekdaysBody(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Open Sunday to Wednesday dates in the next $daysString days';
  }

  @override
  String get hotelGrowUntilEnd => 'Until I end it';

  @override
  String get hotelGrowEndRequired => 'Choose an end date, or turn on Until I end it.';

  @override
  String get hotelGrowAnKpiVouchers => 'Vouchers purchased';

  @override
  String get hotelGrowAnKpiRequests => 'Requests';

  @override
  String get hotelGrowAnKpiRedeemed => 'Vouchers redeemed';

  @override
  String get hotelGrowAnDefVouchers => 'Vouchers bought for your venue in the period, counted at payment, not at use.';

  @override
  String get hotelGrowFactDates => 'Dates';

  @override
  String get hotelGrowStatEnded => 'Ended';

  @override
  String get hotelGrowUnitGuest => 'Per guest';

  @override
  String get hotelGrowFactsLabel => 'Details';

  @override
  String get hotelGrowStandingCount => 'Standing offers';

  @override
  String get hotelGrowFeeTitle => 'Voucher fee';

  @override
  String get hotelGrowExampleLabel => 'Example';

  @override
  String get hotelGrowFactGuests => 'Guests';

  @override
  String get hotelGrowFactDate => 'Date';

  @override
  String get hotelGrowSaving => 'Saving';

  @override
  String get hotelGrowCouplesPay => 'Couples pay';

  @override
  String get hotelGrowOffline => 'Offline';

  @override
  String get hotelGrowRwReply => 'Reply';

  @override
  String get hotelGrowAnRangeFrom => 'From';

  @override
  String get hotelGrowAnRangeTo => 'To';

  @override
  String get hotelGrowEffectTitle => 'Effect';

  @override
  String get hotelGrowFactPackages => 'Packages';

  @override
  String get hotelGrowStandingInfoTitle => 'Standing offers';

  @override
  String get hotelGrowRwVerified => 'Verified';

  @override
  String get hotelGrowRwPosted => 'Posted';

  @override
  String get hotelGrowFactMen => 'Men';

  @override
  String get hotelGrowFactLadies => 'Ladies';

  @override
  String get hotelGrowRwYourReply => 'Your reply';

  @override
  String get hotelGrowRwDraft => 'Draft';

  @override
  String get hotelGrowRwReport => 'Report';

  @override
  String get hotelGrowStepPrice => 'Price';

  @override
  String get hotelGrowStepDates => 'Dates';

  @override
  String get hotelGrowBoundsLabel => 'Price range';

  @override
  String get hotelGrowStandingPrice => 'Standing price';

  @override
  String get hotelGrowNoEffectTitle => 'No change';

  @override
  String get hotelGrowNoEffectShort => 'No change';

  @override
  String get hotelGrowBelowFeeTitle => 'Below fee';

  @override
  String hotelGrowBelowFeeShort(String fee) {
    return 'Under $fee fee';
  }

  @override
  String get hotelGrowPreviewTitle => 'Preview';

  @override
  String get hotelGrowRulesTitle => 'Rules';

  @override
  String get hotelGrowPublishFailedTitle => 'Not published';

  @override
  String get hotelGrowOverlapTitle => 'Overlap';

  @override
  String get hotelGrowLowerPrice => 'Lower price';

  @override
  String get hotelGrowOpenDates => 'Open dates';

  @override
  String get hotelGrowAnApproved => 'Approved';

  @override
  String get hotelGrowAnInsufTitle => 'Not enough data';

  @override
  String hotelGrowAnInsufShort(String days) {
    return '$days days needed';
  }

  @override
  String get hotelGrowRwReviews => 'Reviews';

  @override
  String get hotelGrowRwCategories => 'Categories';

  @override
  String get hotelGrowRwMore => 'More';

  @override
  String get hotelGrowRwRulesTitle => 'Rules';

  @override
  String hotelProviderOfflineStrip(String time) {
    return 'Offline · saved $time';
  }

  @override
  String get hotelProviderNeedsConnection => 'Offline';

  @override
  String get hotelProviderLangArabic => 'Arabic';

  @override
  String get hotelProviderLangEnglish => 'English';

  @override
  String hotelProviderFieldInArabic(String field) {
    return '$field · AR';
  }

  @override
  String hotelProviderFieldInEnglish(String field) {
    return '$field · EN';
  }

  @override
  String get hotelProviderPriceError => 'Amount in dinars';

  @override
  String get hotelProviderListTitle => 'Listings';

  @override
  String get hotelProviderListNew => 'New';

  @override
  String get hotelProviderListRoleReason => 'View only';

  @override
  String hotelProviderListGroupAttention(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Action · $countString';
  }

  @override
  String hotelProviderListGroupRunning(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Live · $countString';
  }

  @override
  String hotelProviderListGroupEnded(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Ended · $countString';
  }

  @override
  String hotelProviderListRejectedBanner(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString not approved';
  }

  @override
  String hotelProviderListExpiryBanner(String date) {
    return 'Ends $date';
  }

  @override
  String get hotelProviderListEmptyTitle => 'No listings yet';

  @override
  String get hotelProviderListErrorTitle => 'Not loaded';

  @override
  String get hotelProviderListErrorBody => 'Nothing changed. Try again.';

  @override
  String get hotelProviderStepFinish => 'Finish';

  @override
  String get hotelProviderStepChoosePlan => 'Plan';

  @override
  String get hotelProviderStepFix => 'Fix';

  @override
  String get hotelProviderStepRenew => 'Renew';

  @override
  String get hotelProviderStepSubmit => 'Submit';

  @override
  String get hotelProviderPlanContractTitle => 'Business contract';

  @override
  String get hotelProviderPlanContractBody => 'Terms as contracted';

  @override
  String get hotelProviderPlanTitle => 'Plan';

  @override
  String get hotelProviderPlanTitleRenew => 'Renew';

  @override
  String get hotelProviderPlanEditListing => 'Edit';

  @override
  String get hotelProviderPlanGroup => 'Plan period';

  @override
  String get hotelProviderPlanInclTitle => 'Included';

  @override
  String get hotelProviderPlanIncl1 => 'Listing';

  @override
  String get hotelProviderPlanIncl2 => 'Requests';

  @override
  String get hotelProviderPlanIncl3 => 'Figures';

  @override
  String get hotelProviderPlanContinue => 'Pay';

  @override
  String get hotelProviderPlanReasonRates => 'Rates soon';

  @override
  String get hotelProviderPlanReasonChoose => 'Pick a plan';

  @override
  String get hotelProviderPlanSubmittedToast => 'Sent';

  @override
  String get hotelProviderPlanSampleNote => 'Sample amounts';

  @override
  String get hotelProviderPlanPreviewSample => 'Sample rates';

  @override
  String hotelProviderPlanRenewLive(String date) {
    return 'Until $date';
  }

  @override
  String hotelProviderPlanRenewExpired(String date) {
    return 'Ended $date';
  }

  @override
  String get hotelProviderPlanErrorTitle => 'Not loaded';

  @override
  String get hotelProviderPlanErrorBody => 'Nothing changed. Try again.';

  @override
  String get hotelProviderPayTitle => 'Pay';

  @override
  String get hotelProviderPayTotal => 'Plan total';

  @override
  String hotelProviderPayAction(String amount) {
    return 'Pay $amount';
  }

  @override
  String get hotelProviderPayWith => 'Pay with';

  @override
  String get hotelProviderChangeMethod => 'Change';

  @override
  String get hotelProviderMethodsTitle => 'Payment method';

  @override
  String get hotelProviderMethodKnet => 'KNET';

  @override
  String get hotelProviderMethodVisa => 'Visa';

  @override
  String get hotelProviderMethodMastercard => 'Mastercard';

  @override
  String get hotelProviderMethodApplePay => 'Apple Pay';

  @override
  String get hotelProviderMethodGooglePay => 'Google Pay';

  @override
  String get hotelProviderSampleBadge => 'Sample';

  @override
  String get hotelProviderRefundNote => 'Fee refunds are handled by support, on request.';

  @override
  String get hotelProviderSumListing => 'Listing';

  @override
  String get hotelProviderSumPlan => 'Plan';

  @override
  String get hotelProviderSumAmount => 'Amount';

  @override
  String get hotelProviderSumPaid => 'Paid';

  @override
  String hotelProviderGatewayTitle(String method) {
    return '$method';
  }

  @override
  String hotelProviderRedirectTitle(String method) {
    return 'To $method';
  }

  @override
  String get hotelProviderRedirectBody => 'Keep the app open.';

  @override
  String get hotelProviderConfirmingTitle => 'Confirming';

  @override
  String get hotelProviderConfirmingBody => 'Please do not pay again.';

  @override
  String get hotelProviderBankMerchant => 'Merchant';

  @override
  String get hotelProviderBankMerchantName => 'Ghazal';

  @override
  String get hotelProviderBankAmount => 'Amount';

  @override
  String get hotelProviderBankCard => 'Card';

  @override
  String get hotelProviderBankExpiry => 'Expiry';

  @override
  String get hotelProviderBankPin => 'PIN';

  @override
  String get hotelProviderBankSubmit => 'Pay';

  @override
  String get hotelProviderProtoLabel => 'Bank answer';

  @override
  String get hotelProviderProtoApproved => 'Approved';

  @override
  String get hotelProviderProtoDeclined => 'Declined';

  @override
  String get hotelProviderLeaveTitle => 'Leave payment?';

  @override
  String get hotelProviderLeaveBody => 'Nothing was charged.';

  @override
  String get hotelProviderLeaveStay => 'Stay';

  @override
  String get hotelProviderLeaveConfirm => 'Leave';

  @override
  String get hotelProviderPaidTitle => 'Paid';

  @override
  String get hotelProviderPaidBody => 'Your listing is in review.';

  @override
  String get hotelProviderRenewedTitle => 'Renewed';

  @override
  String get hotelProviderRenewedBody => 'Your listing stays live.';

  @override
  String hotelProviderRenewedNote(String date) {
    return 'Until $date';
  }

  @override
  String get hotelProviderReceiptLink => 'Receipt';

  @override
  String get hotelProviderViewStatus => 'Status';

  @override
  String get hotelProviderBackToListings => 'Listings';

  @override
  String get hotelProviderFailedTitle => 'Payment failed';

  @override
  String get hotelProviderFailedBody => 'Nothing was charged.';

  @override
  String get hotelProviderRetry => 'Try again';

  @override
  String get hotelProviderSwitchMethod => 'Other method';

  @override
  String get hotelProviderCancelledTitle => 'Cancelled';

  @override
  String get hotelProviderCancelledBody => 'Nothing was charged. Your plan is saved.';

  @override
  String get hotelProviderBackToPay => 'Back';

  @override
  String get hotelProviderBlockedTitle => 'Rates soon';

  @override
  String get hotelProviderBlockedBody => 'Rates are not announced yet, so there is nothing to pay. Your listing and plan choice are kept.';

  @override
  String get hotelProviderBackToPlans => 'Plans';

  @override
  String get hotelProviderOfflinePay => 'Offline';

  @override
  String get hotelProviderPayErrorTitle => 'Payment failed';

  @override
  String get hotelProviderPayErrorBody => 'Nothing was charged. Try again.';

  @override
  String get hotelProviderReceiptTitle => 'Receipt';

  @override
  String get hotelProviderReceiptIssuer => 'Ghazal';

  @override
  String get hotelProviderReceiptNumber => 'No.';

  @override
  String get hotelProviderReceiptDate => 'Date';

  @override
  String get hotelProviderReceiptListing => 'Listing';

  @override
  String get hotelProviderReceiptPlan => 'Plan';

  @override
  String get hotelProviderReceiptVia => 'Via';

  @override
  String get hotelProviderReceiptFoot => 'KWD';

  @override
  String get hotelProviderReceiptSample => 'Sample';

  @override
  String get hotelProviderRequired => 'Required';

  @override
  String get hotelProviderRetryShort => 'Retry';

  @override
  String get hotelProviderEditorTitle => 'Listing';

  @override
  String get hotelProviderEditorTitleNew => 'New listing';

  @override
  String get hotelProviderEditorCategory => 'Category';

  @override
  String get hotelProviderEditorCategoryPlaceholder => 'Choose';

  @override
  String get hotelProviderEditorTexts => 'Texts';

  @override
  String get hotelProviderEditorTitleField => 'Title';

  @override
  String get hotelProviderEditorDescField => 'Description';

  @override
  String get hotelProviderEditorPhotos => 'Photos';

  @override
  String get hotelProviderEditorPackages => 'Packages';

  @override
  String get hotelProviderEditorContact => 'Contact';

  @override
  String get hotelProviderEditorChat => 'Chat';

  @override
  String get hotelProviderEditorPhone => 'Phone';

  @override
  String get hotelProviderEditorContinue => 'Continue';

  @override
  String get hotelProviderEditorSubmitChanges => 'Submit';

  @override
  String get hotelProviderEditorResubmit => 'Resubmit';

  @override
  String get hotelProviderEditorSaveDraft => 'Save draft';

  @override
  String get hotelProviderEditorSaved => 'Saved';

  @override
  String get hotelProviderEditorSavedBanner => 'Saved';

  @override
  String get hotelProviderEditorDraftSaved => 'Draft saved';

  @override
  String get hotelProviderEditorDraftNeedsTitle => 'Add a title';

  @override
  String get hotelProviderEditorFixFields => 'Complete the marked fields';

  @override
  String get hotelProviderEditorValidationNote => 'Complete the marked fields';

  @override
  String get hotelProviderEditorError => 'Not saved';

  @override
  String get hotelProviderEditorLiveNote => 'Live version stays';

  @override
  String hotelProviderEditorRejectedNote(String note) {
    return '$note';
  }

  @override
  String get hotelProviderGuardTitle => 'Discard changes?';

  @override
  String get hotelProviderGuardBody => 'Unsaved edits will be lost.';

  @override
  String get hotelProviderGuardDiscard => 'Discard';

  @override
  String get hotelProviderGuardKeep => 'Keep';

  @override
  String get hotelProviderPhotoAdd => 'Add';

  @override
  String get hotelProviderPhotoRemove => 'Remove photo';

  @override
  String get hotelProviderPhotoCover => 'Cover';

  @override
  String get hotelProviderCatsPrimary => 'Main';

  @override
  String get hotelProviderCatsMore => 'More';

  @override
  String hotelProviderCatsLimit(num count, num max) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$countString/$maxString';
  }

  @override
  String get hotelProviderPkgUnnamed => 'Unnamed';

  @override
  String get hotelProviderPkgAdd => 'Add package';

  @override
  String get hotelProviderPkgNeeded => 'Add a package';

  @override
  String get hotelProviderPkgNoVoucher => 'No voucher';

  @override
  String hotelProviderPkgNoVoucherFull(String fee) {
    return 'No voucher. Saving must exceed $fee.';
  }

  @override
  String hotelProviderPkgSaving(String amount) {
    return 'Saves $amount';
  }

  @override
  String get hotelProviderPkgSheetNew => 'New package';

  @override
  String get hotelProviderPkgSheetEdit => 'Package';

  @override
  String get hotelProviderPkgSave => 'Save';

  @override
  String get hotelProviderPkgDelete => 'Delete';

  @override
  String get hotelProviderPkgName => 'Name';

  @override
  String get hotelProviderPkgPerPackage => 'package';

  @override
  String get hotelProviderPkgVoucherOver => 'At or below standard';

  @override
  String get hotelProviderPkgIncludes => 'Included';

  @override
  String get hotelProviderPkgInclPlaceholder => 'Add item';

  @override
  String hotelProviderPkgRemoveIncl(String name) {
    return 'Remove $name';
  }

  @override
  String get hotelProviderPreviewTitle => 'Preview';

  @override
  String get hotelProviderPreviewNoTitle => 'Title';

  @override
  String get hotelProviderPreviewNoPackage => 'Add a package';

  @override
  String get hotelProviderReviewTitle => 'Review';

  @override
  String get hotelProviderReviewErrorTitle => 'Not loaded';

  @override
  String get hotelProviderReviewErrorBody => 'Nothing changed. Try again.';

  @override
  String get hotelProviderHeadPendingTitle => 'In review';

  @override
  String get hotelProviderHeadApprovedTitle => 'Approved';

  @override
  String get hotelProviderHeadLiveTitle => 'Live';

  @override
  String get hotelProviderHeadRevisionTitle => 'Changes in review';

  @override
  String get hotelProviderHeadRejectedTitle => 'Not approved';

  @override
  String hotelProviderLongWait(num hours) {
    final intl.NumberFormat hoursNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return '$hoursString h in review';
  }

  @override
  String get hotelProviderContactSupport => 'Support';

  @override
  String get hotelProviderReasons => 'Team notes';

  @override
  String get hotelProviderReasonContent => 'Content';

  @override
  String get hotelProviderReasonCategory => 'Category';

  @override
  String get hotelProviderReasonMissing => 'Missing details';

  @override
  String get hotelProviderReasonPricing => 'Pricing';

  @override
  String get hotelProviderReasonOther => 'Other';

  @override
  String get hotelProviderPlanRetained => 'Fee refund: ask support';

  @override
  String get hotelProviderPlanRefunded => 'Refund recorded';

  @override
  String get hotelProviderChoosePlanAgain => 'Plan';

  @override
  String get hotelProviderListingLabel => 'Listing';

  @override
  String get hotelProviderTimeline => 'History';

  @override
  String get hotelProviderFacts => 'Details';

  @override
  String get hotelProviderFactSubmitted => 'Sent';

  @override
  String get hotelProviderFactFees => 'Fees';

  @override
  String get hotelProviderFactNoFees => 'None';

  @override
  String get hotelProviderFactPaid => 'Paid';

  @override
  String get hotelProviderFactRatesSoon => 'Rates soon';

  @override
  String get hotelProviderFactPlanEnds => 'Ends';

  @override
  String hotelProviderDaysLeft(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '$daysString d';
  }

  @override
  String get hotelProviderEditResubmit => 'Edit';

  @override
  String get hotelProviderViewPerformance => 'Performance';

  @override
  String get hotelProviderProtoTitle => 'Moderator';

  @override
  String get hotelProviderProtoApprove => 'Approve';

  @override
  String get hotelProviderProtoReject => 'Reject';

  @override
  String get hotelProviderProtoNote => 'Wrong category, unclear price.';

  @override
  String get hotelProviderPerfTitle => 'Performance';

  @override
  String get hotelProviderPerfEdit => 'Edit';

  @override
  String get hotelProviderPerfErrorTitle => 'Not loaded';

  @override
  String get hotelProviderPerfErrorBody => 'Nothing changed. Try again.';

  @override
  String get hotelProviderPerfEmptyTitle => 'No figures yet';

  @override
  String hotelProviderPerfEnded(String date) {
    return 'Ended $date';
  }

  @override
  String get hotelProviderPerfRangeLabel => 'Period';

  @override
  String get hotelProviderPerfRangeMonth => 'Month';

  @override
  String hotelProviderPerfRange30(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '$daysString d';
  }

  @override
  String hotelProviderPerfRange90(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return '$daysString d';
  }

  @override
  String get hotelProviderPerfRangeCustom => 'Custom';

  @override
  String get hotelProviderPerfViews => 'Views';

  @override
  String get hotelProviderPerfSaves => 'Saves';

  @override
  String get hotelProviderPerfVouchers => 'Vouchers';

  @override
  String get hotelProviderPerfRequests => 'Requests';

  @override
  String get hotelProviderPerfRedeemed => 'Redeemed';

  @override
  String get hotelProviderPerfVsPrevious => 'vs before';

  @override
  String get hotelProviderPerfFunnel => 'Funnel';

  @override
  String get hotelProviderPerfFunnelDesc => 'Views to redeemed';

  @override
  String get hotelProviderPerfCount => 'Count';

  @override
  String hotelProviderPerfStep(String percent) {
    return '$percent';
  }

  @override
  String hotelProviderPerfInsufficient(num days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String daysString = daysNumberFormat.format(days);

    return 'Pick $daysString+ days';
  }

  @override
  String get hotelProviderPerfTop => 'Top packages';

  @override
  String get hotelProviderPerfTopDesc => 'By requests';

  @override
  String get hotelProviderPerfAsTable => 'Table';

  @override
  String get hotelProviderPerfAsChart => 'Chart';

  @override
  String get hotelProviderPerfVenueAnalytics => 'Venue analytics';

  @override
  String get hotelProviderPerfAllListings => 'All listings';

  @override
  String get hotelProviderRangeTitle => 'Period';

  @override
  String get hotelProviderRangeHint => 'Pick dates';

  @override
  String get hotelProviderRangeApply => 'Apply';

  @override
  String get hotelProviderContinue => 'Continue';

  @override
  String get hotelProviderChooseTitle => 'Account type';

  @override
  String get hotelProviderChooseReason => 'Pick one';

  @override
  String get hotelProviderTypeHotelTitle => 'Hotel or hall';

  @override
  String get hotelProviderTypeProviderTitle => 'Provider';

  @override
  String get hotelProviderProfileName => 'Name';

  @override
  String get hotelProviderProfileVenueType => 'Type';

  @override
  String get hotelProviderVenueTypeHall => 'Hall';

  @override
  String get hotelProviderVenueTypeHotel => 'Hotel';

  @override
  String get hotelProviderProfileGovernorate => 'Governorate';

  @override
  String get hotelProviderProfileArea => 'Area';

  @override
  String get hotelProviderProfileChoose => 'Choose';

  @override
  String get hotelProviderProfileCategories => 'Categories';

  @override
  String get hotelProviderCatsChoose => 'Choose';

  @override
  String get hotelProviderCatsEdit => 'Edit';

  @override
  String get hotelProviderProfilePhone => 'Phone';

  @override
  String get hotelProviderPhoneError => 'Invalid number';

  @override
  String get hotelProviderLogoTitle => 'Logo';

  @override
  String get hotelProviderLogoUpload => 'Upload';

  @override
  String get hotelProviderLogoToast => 'In the finished app';

  @override
  String get hotelProviderSubmit => 'Submit';

  @override
  String get hotelProviderSubmitErrorTitle => 'Not submitted';

  @override
  String get hotelProviderSubmitError => 'Nothing was sent. Try again.';

  @override
  String get hotelProviderSubmittedBar => 'Account';

  @override
  String get hotelProviderSubmittedTitle => 'Under review';

  @override
  String get hotelProviderSubmittedFirst => 'First listing';

  @override
  String get hotelProviderSubmittedToday => 'Today';

  @override
  String get hotelProviderSubmittedStatus => 'Status';

  @override
  String get hotelProviderRejectContent => 'Content';

  @override
  String get hotelProviderRejectCategory => 'Category';

  @override
  String get hotelProviderRejectDetails => 'Details';

  @override
  String get hotelProviderRejectPricing => 'Pricing';

  @override
  String get hotelProviderRejectOther => 'Note';

  @override
  String get hotelProviderPlanSampleCta => 'Sample amounts, prototype only. Not a real rate.';

  @override
  String get hotelProviderRefundTitle => 'Refund';

  @override
  String get hotelProviderDetails => 'Details';

  @override
  String get hotelSettingsRoleManager => 'Manager';

  @override
  String get hotelSettingsRoleReception => 'Reception';

  @override
  String get hotelSettingsRoleOwner => 'Admin';

  @override
  String get hotelSettingsStepUpTitle => 'Confirm it’s you';

  @override
  String get hotelSettingsStepUpBodyStaff => 'We send a code to your email.';

  @override
  String get hotelSettingsStepUpSend => 'Send code';

  @override
  String get hotelSettingsMoreTitle => 'More';

  @override
  String get hotelSettingsMoreListing => 'Your listing';

  @override
  String get hotelSettingsMoreCompleteness => 'Language completeness';

  @override
  String get hotelSettingsMoreLangAr => 'Arabic';

  @override
  String get hotelSettingsMoreLangEn => 'English';

  @override
  String get hotelSettingsMorePreview => 'Preview';

  @override
  String get hotelSettingsMorePreviewHeld => 'Preview opens once your listing is approved.';

  @override
  String get hotelSettingsMoreGroupVenue => 'Venue';

  @override
  String get hotelSettingsMoreGroupVisits => 'Visits';

  @override
  String get hotelSettingsMoreGroupGrow => 'Grow';

  @override
  String get hotelSettingsMoreGroupBusiness => 'Business';

  @override
  String get hotelSettingsMoreGroupAccount => 'Account';

  @override
  String get hotelSettingsMoreMedia => 'Photos';

  @override
  String get hotelSettingsMorePackages => 'Packages';

  @override
  String get hotelSettingsMoreHalls => 'Halls';

  @override
  String get hotelSettingsMorePolicies => 'Policies';

  @override
  String get hotelSettingsMoreRules => 'Rules';

  @override
  String get hotelSettingsMoreAvailability => 'Availability';

  @override
  String get hotelSettingsMoreVisitRequests => 'Requests';

  @override
  String get hotelSettingsMoreVisitAvailability => 'Schedule';

  @override
  String get hotelSettingsMoreVoucherPrices => 'Voucher prices';

  @override
  String get hotelSettingsMoreAnalytics => 'Analytics';

  @override
  String get hotelSettingsMoreReviews => 'Reviews';

  @override
  String get hotelSettingsMoreListings => 'Listings';

  @override
  String get hotelSettingsMorePerformance => 'Performance';

  @override
  String get hotelSettingsMoreNotifications => 'Notifications';

  @override
  String get hotelSettingsMoreStaff => 'Staff';

  @override
  String get hotelSettingsMoreHours => 'Business hours';

  @override
  String get hotelSettingsMoreLanguage => 'Language';

  @override
  String get hotelSettingsMoreBiometric => 'Biometric lock';

  @override
  String get hotelSettingsMoreSupport => 'Support';

  @override
  String get hotelSettingsMoreSupportToast => 'Support chat';

  @override
  String get hotelSettingsMoreSwitch => 'Switch venue';

  @override
  String get hotelSettingsMoreLogout => 'Log out';

  @override
  String hotelSettingsMoreVersion(String version) {
    return '$version';
  }

  @override
  String get hotelSettingsMoreTerms => 'Terms';

  @override
  String get hotelSettingsMorePrivacy => 'Privacy';

  @override
  String get hotelSettingsMoreLegalToast => 'Texts managed by Ghazal';

  @override
  String get hotelSettingsMoreAccountType => 'Account type';

  @override
  String get hotelSettingsMoreBilling => 'Billing';

  @override
  String get hotelSettingsMoreBillingAttention => 'Needs attention';

  @override
  String get hotelSettingsLanguageTitle => 'Language';

  @override
  String get hotelSettingsLanguageSaved => 'Language saved';

  @override
  String get hotelSettingsSwitchTitle => 'Switch venue';

  @override
  String get hotelSettingsSwitchCurrent => 'Current venue';

  @override
  String get hotelSettingsLogoutTitle => 'Log out?';

  @override
  String get hotelSettingsBiometricOnTitle => 'Turn on biometric lock?';

  @override
  String get hotelSettingsBiometricOnConfirm => 'Turn on';

  @override
  String get hotelSettingsBiometricOn => 'Lock on';

  @override
  String get hotelSettingsBiometricOff => 'Lock off';

  @override
  String get hotelSettingsPreviewTitle => 'Preview';

  @override
  String get hotelSettingsAcctTitle => 'Account type';

  @override
  String get hotelSettingsAcctVenue => 'Hotel or hall';

  @override
  String get hotelSettingsAcctProvider => 'Service provider';

  @override
  String get hotelSettingsAcctSetup => 'Add account';

  @override
  String get hotelSettingsAcctSwitchedVenue => 'Hotel or hall';

  @override
  String get hotelSettingsAcctSwitchedProvider => 'Service provider';

  @override
  String get hotelSettingsNotifAboutTitle => 'About alerts';

  @override
  String get hotelSettingsNotifAboutLock => 'New request alerts are always on for your role, with a sound of their own.';

  @override
  String get hotelSettingsNotifAboutQuiet => 'Outside business hours the alert is silent and still appears in your list.';

  @override
  String get hotelSettingsNotifAboutChannel =>
      'Alerts arrive as push notifications. Urgent escalations also come by email, and there is no marketing push.';

  @override
  String get hotelSettingsNotifPushOffTitle => 'Notifications off';

  @override
  String get hotelSettingsNotifPushOffBody =>
      'You will not hear about new requests until you turn them on, and the reply clock keeps running. Nothing else here is affected.';

  @override
  String get hotelSettingsNotifPushOffAction => 'Open Settings';

  @override
  String get hotelSettingsNotifPushOffToast => 'Opens phone settings';

  @override
  String get hotelSettingsNotifNewRequest => 'New requests';

  @override
  String get hotelSettingsNotifAlwaysOn => 'Always on';

  @override
  String get hotelSettingsNotifPlaySound => 'Play sound';

  @override
  String get hotelSettingsNotifPlaying => 'Playing';

  @override
  String get hotelSettingsNotifConfirmations => 'Confirmations';

  @override
  String get hotelSettingsNotifCancelled => 'Cancellations';

  @override
  String get hotelSettingsNotifRedemptions => 'Vouchers';

  @override
  String get hotelSettingsNotifVisits => 'Visits';

  @override
  String get hotelSettingsNotifMessages => 'Messages';

  @override
  String get hotelSettingsNotifReviews => 'Reviews';

  @override
  String get hotelSettingsNotifListing => 'Listing';

  @override
  String get hotelSettingsNotifPlan => 'Plan';

  @override
  String get hotelSettingsStaffInvite => 'Invite staff';

  @override
  String get hotelSettingsStaffYou => 'You';

  @override
  String get hotelSettingsStaffSupport => 'Support';

  @override
  String get hotelSettingsStaffEmptyTitle => 'Only you';

  @override
  String get hotelSettingsStaffName => 'Name';

  @override
  String get hotelSettingsStaffNameError => 'Enter a name';

  @override
  String get hotelSettingsStaffRole => 'Role';

  @override
  String get hotelSettingsStaffAccept => 'Reply to requests';

  @override
  String get hotelSettingsStaffSend => 'Send invite';

  @override
  String get hotelSettingsStaffSent => 'Invite sent';

  @override
  String get hotelSettingsStaffSaveRole => 'Save role';

  @override
  String get hotelSettingsStaffSessions => 'End sessions';

  @override
  String get hotelSettingsStaffSessionsDone => 'Signed out';

  @override
  String get hotelSettingsStaffDeactivate => 'Deactivate';

  @override
  String hotelSettingsStaffDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String get hotelSettingsStaffReactivate => 'Reactivate';

  @override
  String hotelSettingsStaffReactivated(String name) {
    return '$name active';
  }

  @override
  String get hotelSettingsStaffRemove => 'Remove';

  @override
  String hotelSettingsStaffRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get hotelSettingsStaffRemoveConfirm => 'Remove';

  @override
  String hotelSettingsStaffRemoved(String name) {
    return '$name removed';
  }

  @override
  String get hotelSettingsStaffResend => 'Resend invite';

  @override
  String get hotelSettingsStaffResent => 'Invite resent';

  @override
  String hotelSettingsStaffOpen(String name) {
    return 'Edit $name';
  }

  @override
  String get hotelSettingsStaffLastSeen => 'Last seen';

  @override
  String get hotelSettingsStaffExpires => 'Invite expires';

  @override
  String get hotelSettingsStaffStateDeactivated => 'Deactivated';

  @override
  String get hotelSettingsStaffAboutTitle => 'About roles';

  @override
  String get hotelSettingsStaffVisitNote => 'Whoever manages visits can read the visit group chats, which also include Ghazal Support.';

  @override
  String get hotelSettingsStaffFoot => 'Admin can’t be assigned from the app. Ghazal support handles ownership transfers.';

  @override
  String get hotelSettingsRoleLineManager => 'Everything, including redeeming vouchers, visits, listings and billing; not staff';

  @override
  String get hotelSettingsRoleLineReception => 'Requests, redeeming vouchers, visits and chat';

  @override
  String get hotelSettingsRoleLineAccountant => 'Billing and receipts; requests to read only';

  @override
  String get hotelSettingsRoleLineMarketing => 'Voucher prices, listings, analytics and photos';

  @override
  String get hotelSettingsHoursAboutTitle => 'About hours';

  @override
  String get hotelSettingsHoursAbout => 'Couples see these as working hours, and they decide when new-request alerts make a sound.';

  @override
  String get hotelSettingsHoursApproxNote => 'Ramadan and the Eids are estimates until announced. Adjust them when they are.';

  @override
  String get hotelSettingsHoursPreview => 'Shown to couples as';

  @override
  String hotelSettingsHoursLine(String days, String from, String to) {
    return '$days $from–$to';
  }

  @override
  String hotelSettingsHoursLineClosed(String days) {
    return '$days closed';
  }

  @override
  String hotelSettingsHoursDaysRange(String first, String last) {
    return '$first–$last';
  }

  @override
  String hotelSettingsHoursDaysPair(String first, String last) {
    return '$first, $last';
  }

  @override
  String get hotelSettingsHoursEveryDay => 'Every day';

  @override
  String get hotelSettingsHoursAllClosed => 'Closed';

  @override
  String get hotelSettingsHoursWeek => 'Weekly hours';

  @override
  String get hotelSettingsHoursTimeFrom => 'Opening';

  @override
  String get hotelSettingsHoursTimeTo => 'Closing';

  @override
  String get hotelSettingsHoursHour => 'Hour';

  @override
  String get hotelSettingsHoursMinute => 'Minutes';

  @override
  String get hotelSettingsHoursAm => 'AM';

  @override
  String get hotelSettingsHoursPm => 'PM';

  @override
  String get hotelSettingsHoursSetTime => 'Set';

  @override
  String get hotelSettingsHoursClosures => 'Closures';

  @override
  String get hotelSettingsHoursClosure => 'Closure';

  @override
  String hotelSettingsHoursClosureRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get hotelSettingsHoursApprox => 'Approx.';

  @override
  String get hotelSettingsHoursSuggested => 'Suggested';

  @override
  String get hotelSettingsHoursAddClosure => 'Add closure';

  @override
  String get hotelSettingsHoursAddTitle => 'Add closure';

  @override
  String get hotelSettingsHoursAddLabel => 'Name';

  @override
  String get hotelSettingsHoursAddConfirm => 'Add';

  @override
  String hotelSettingsHoursRemoveClosure(String label) {
    return 'Remove closure $label';
  }

  @override
  String get hotelSettingsHoursSave => 'Save';

  @override
  String get hotelSettingsHoursGuardTitle => 'Leave without saving?';

  @override
  String get hotelSettingsHoursGuardLeave => 'Leave';

  @override
  String get hotelSettingsHoursGuardStay => 'Stay';

  @override
  String get hotelSettingsHoursViewOnly => 'View only';

  @override
  String get hotelSettingsHoursInvalid => 'Times can’t match';

  @override
  String get hotelSettingsHoursCopy => 'All days';

  @override
  String get hotelSettingsHoursNextDay => 'Next day';

  @override
  String hotelSettingsHoursOpenOn(String day) {
    return 'Open on $day';
  }

  @override
  String get hotelSettingsHoursClosedWord => 'Closed';

  @override
  String get hotelSettingsBillExempt => 'Major hotel · no listing fees';

  @override
  String get hotelSettingsBillExemptBody => 'Your listings are still reviewed before they go live.';

  @override
  String get hotelSettingsBillEnds => 'Plan ends';

  @override
  String get hotelSettingsBillEnded => 'Plan ended';

  @override
  String get hotelSettingsBillDaysLeft => 'Days remaining';

  @override
  String get hotelSettingsBillDaysUnit => 'd';

  @override
  String get hotelSettingsBillHidden => 'Hidden';

  @override
  String get hotelSettingsBillNone => 'No plan';

  @override
  String get hotelSettingsBillNoneBody => 'Choose a weekly, monthly or annual plan to advertise. Nothing goes live until Ghazal has reviewed it.';

  @override
  String get hotelSettingsBillRatesBody => 'You can choose a plan now. Payment opens when rates are announced.';

  @override
  String get hotelSettingsBillStatusLabel => 'Plan status';

  @override
  String get hotelSettingsBillPillActive => 'Active';

  @override
  String get hotelSettingsBillPillExpiring => 'Ending';

  @override
  String get hotelSettingsBillExpiringNote => 'We remind you a week before and again the day before. Renew to keep your listing live.';

  @override
  String get hotelSettingsBillExpiredNote => 'Your listing is hidden. Renew to bring it back; it returns to review before it goes live again.';

  @override
  String get hotelSettingsBillPlanRow => 'Plans';

  @override
  String get hotelSettingsBillRenew => 'Renew';

  @override
  String get hotelSettingsBillChoose => 'Choose plan';

  @override
  String get hotelSettingsBillSeePlans => 'See plans';

  @override
  String get hotelSettingsBillReceipts => 'Receipts';

  @override
  String get hotelSettingsBillDirectNote =>
      'Couples pay you directly for the event. Ghazal holds, takes and pays out no event money, so this is the only place billing appears.';

  @override
  String get hotelSettingsBillViewOnly => 'View only';

  @override
  String get hotelSettingsBillDownload => 'Download PDF';

  @override
  String get hotelSettingsBillDownloaded => 'Receipt saved';

  @override
  String get hotelSettingsBillMethodKnet => 'KNET';

  @override
  String get hotelSettingsBillMethodCard => 'Card';

  @override
  String get hotelSettingsBillMethodApplePay => 'Apple Pay';

  @override
  String get hotelSettingsBillMethodGooglePay => 'Google Pay';

  @override
  String get hotelSettingsStaffEmail => 'Email';

  @override
  String get hotelSettingsStaffEmailError => 'Enter a valid email';

  @override
  String get hotelSettingsBillContractBody => 'Your terms are as contracted with Ghazal. There is no public plan.';

  @override
  String get hotelShellTabBarLabel => 'Main navigation';

  @override
  String get hotelShellTabToday => 'Today';

  @override
  String get hotelShellTabBookings => 'Bookings';

  @override
  String get hotelShellTabCalendar => 'Calendar';

  @override
  String get hotelShellTabMessages => 'Messages';

  @override
  String get hotelShellTabMore => 'More';

  @override
  String hotelShellBadgePending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString requests need your reply',
      one: '$countString request needs your reply',
    );
    return '$_temp0';
  }

  @override
  String hotelShellBadgeOverflow(num max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String maxString = maxNumberFormat.format(max);

    return '$maxString+';
  }

  @override
  String get hotelShellBannerNewRequest => 'New request';

  @override
  String hotelShellGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String hotelShellTodayNeedsReply(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString requests need your reply',
      one: '$countString request needs your reply',
    );
    return '$_temp0';
  }

  @override
  String hotelShellTodayFirstIn(String time) {
    return 'first in $time';
  }

  @override
  String get hotelShellTodayAllClear => 'All clear';

  @override
  String get hotelShellNeedsYouTitle => 'Needs your attention';

  @override
  String get hotelShellOfflineBanner => 'You’re offline. Showing what was last loaded.';

  @override
  String get hotelTodayBell => 'Notifications';

  @override
  String hotelTodayBellUnread(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString unread', one: '$countString unread');
    return 'Notifications, $_temp0';
  }

  @override
  String hotelTodaySwitchVenue(String venue) {
    return 'Switch venue, now $venue';
  }

  @override
  String hotelTodayStatusFirst(String time) {
    return 'First due in $time';
  }

  @override
  String hotelTodayStatusNeeds(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString requests need your reply',
      one: '$countString request needs your reply',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayAllClear => 'All clear';

  @override
  String hotelTodayStatusMarketing(int windows, String views) {
    final intl.NumberFormat windowsNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String windowsString = windowsNumberFormat.format(windows);

    String _temp0 = intl.Intl.pluralLogic(
      windows,
      locale: localeName,
      other: '$windowsString voucher prices running',
      one: '$windowsString voucher price running',
    );
    return '$_temp0 · $views views this week';
  }

  @override
  String get hotelTodayNeedsYouTitle => 'Needs you';

  @override
  String hotelTodaySeeAllCount(String count) {
    return 'See all $count';
  }

  @override
  String hotelTodayWindowEnds(String time) {
    return 'Reply window ends in $time';
  }

  @override
  String hotelTodayWaitingLong(String time) {
    return 'Waiting for a reply for $time';
  }

  @override
  String get hotelTodayBlockDate => 'Block date';

  @override
  String get hotelTodayEventsTitle => 'Events';

  @override
  String get hotelTodayDayView => 'Day view';

  @override
  String get hotelTodayAudienceWomen => 'Ladies’ reception';

  @override
  String get hotelTodayAudienceMen => 'Men’s reception';

  @override
  String get hotelTodayAudienceMixed => 'Mixed reception';

  @override
  String hotelTodayStartsIn(String time) {
    return 'Starts in $time';
  }

  @override
  String get hotelTodayStripLabel => 'Availability over the next seven days';

  @override
  String get hotelTodayCalendar => 'Calendar';

  @override
  String hotelTodaySoftDates(int count, String days) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString open weekend dates in $days days',
      one: '$countString open weekend date in $days days',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayOpenDates => 'Open dates in the next thirty days';

  @override
  String get hotelTodayGlanceTitle => 'Analytics';

  @override
  String get hotelTodayAnalytics => 'Analytics';

  @override
  String get hotelTodayViews7 => 'Views over the last seven days';

  @override
  String get hotelTodayVsPrevious => 'vs the seven days before';

  @override
  String get hotelTodayViewsTrend => 'Views per day, last seven days';

  @override
  String get hotelTodayMessagesTitle => 'Messages';

  @override
  String get hotelTodayUnread => 'Unread';

  @override
  String hotelTodayUnreadCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString unread messages', one: '$countString unread message');
    return '$_temp0';
  }

  @override
  String get hotelTodayYou => 'You';

  @override
  String get hotelTodayPinned => 'Pinned';

  @override
  String get hotelTodayEnquiry => 'Enquiry';

  @override
  String get hotelTodayPreviewVoice => 'Voice message';

  @override
  String get hotelTodayPreviewPhoto => 'Photo';

  @override
  String get hotelTodayPreviewDocument => 'Document';

  @override
  String hotelTodayOfflineStamp(String time) {
    return 'Offline · updated $time';
  }

  @override
  String get hotelTodayOfflineReason => 'Offline. Reconnect to accept.';

  @override
  String get hotelTodaySwitchSister => 'Lumi Marina Hotel';

  @override
  String get hotelTodayAcceptedToast => 'Request approved';

  @override
  String get hotelTodayFirstRunNotifTitle => 'Allow notifications';

  @override
  String get hotelTodayFirstRunNotifBody =>
      'New requests have a limited reply window. With notifications on, you hear about them straight away, even when the app is closed.';

  @override
  String get hotelTodayFirstRunNotifPointTime => 'Urgent alerts';

  @override
  String get hotelTodayFirstRunNotifPointSound => 'Own sound';

  @override
  String get hotelTodayFirstRunNotifAllow => 'Allow';

  @override
  String get hotelTodayFirstRunNotNow => 'Not now';

  @override
  String get hotelTodayFirstRunLockTitle => 'App lock';

  @override
  String get hotelTodayFirstRunLockBody =>
      'Protects requests, vouchers and visits if the phone is lost or shared. You can turn this on later in More.';

  @override
  String get hotelTodayFirstRunLockOn => 'Turn on';

  @override
  String get hotelTodaySwitchTitle => 'Switch venue';

  @override
  String hotelTodaySwitchPending(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString requests waiting', one: '$countString request waiting');
    return '$_temp0';
  }

  @override
  String get hotelTodaySwitchCurrent => 'Current venue';

  @override
  String get hotelTodayRoleManager => 'Manager';

  @override
  String get hotelTodayRoleReception => 'Reception';

  @override
  String hotelTodayDurDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString days', one: '$countString day');
    return '$_temp0';
  }

  @override
  String hotelTodayDurHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString hours', one: '$countString hour');
    return '$_temp0';
  }

  @override
  String hotelTodayDurMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString minutes', one: '$countString minute');
    return '$_temp0';
  }

  @override
  String hotelTodayDurJoin(String first, String second) {
    return '$first $second';
  }

  @override
  String get hotelTodayNeedsTitle => 'Needs you';

  @override
  String get hotelTodayFiltersLabel => 'Filter the queue';

  @override
  String get hotelTodayFilterAll => 'All';

  @override
  String get hotelTodayFilterRequests => 'Requests';

  @override
  String get hotelTodayFilterMessages => 'Messages';

  @override
  String get hotelTodayFilterReviews => 'Reviews';

  @override
  String get hotelTodayFilterCalendar => 'Calendar';

  @override
  String get hotelTodayNotifFilter => 'Show notifications';

  @override
  String get hotelTodayMarkAllRead => 'Mark all as read';

  @override
  String get hotelTodayPrefs => 'Notification preferences';

  @override
  String get hotelTodayNotifEmptyTitle => 'No notifications';

  @override
  String get hotelTodayNotifUnreadEmptyTitle => 'All read';

  @override
  String get hotelTodayNotifShowAll => 'Show all';

  @override
  String get hotelTodayPushDeniedTitle => 'Notifications off';

  @override
  String get hotelTodayOpenSettings => 'Settings';

  @override
  String get hotelTodayPushDeniedToast => 'Turn on in Settings';

  @override
  String get hotelTodayAllRead => 'All read';

  @override
  String get hotelTodayInboxTitle => 'Messages';

  @override
  String get hotelTodayInboxSearch => 'Name or reference';

  @override
  String get hotelTodayInboxSearchLabel => 'Search conversations';

  @override
  String get hotelTodayInboxFilters => 'Filter conversations';

  @override
  String get hotelTodayInboxUnread => 'Unread';

  @override
  String get hotelTodayInboxNeedsReply => 'Needs reply';

  @override
  String get hotelTodayInboxLinked => 'Linked';

  @override
  String get hotelTodayInboxEnquiries => 'Enquiries';

  @override
  String get hotelTodayInboxEmptyTitle => 'No messages';

  @override
  String get hotelTodayInboxNoResultsTitle => 'No match';

  @override
  String get hotelTodayClearSearch => 'Clear';

  @override
  String get hotelTodayInboxSupportOnly => 'Reception handles clients';

  @override
  String get hotelTodayMarkRead => 'Mark read';

  @override
  String get hotelTodayMarkUnread => 'Mark unread';

  @override
  String get hotelTodayConversationMenu => 'Options';

  @override
  String hotelTodayHandledBy(String name) {
    return 'Handled by $name';
  }

  @override
  String hotelTodayCallClient(String name) {
    return 'Call $name';
  }

  @override
  String get hotelTodayReport => 'Report';

  @override
  String get hotelTodayReportSent => 'Report sent';

  @override
  String hotelTodayContextLine(String audience, String date, String guests) {
    return '$audience · $date · $guests';
  }

  @override
  String hotelTodayOpenBooking(String summary) {
    return 'Open request, $summary';
  }

  @override
  String get hotelTodayComposerLabel => 'Message';

  @override
  String get hotelTodayComposerPlaceholder => 'Message';

  @override
  String get hotelTodayAttach => 'Attach';

  @override
  String get hotelTodayAttachTitle => 'Attach';

  @override
  String get hotelTodayAttachCamera => 'Camera';

  @override
  String get hotelTodayAttachPhoto => 'Photos';

  @override
  String get hotelTodayAttachDocument => 'Document';

  @override
  String get hotelTodayRecordHold => 'Hold to record';

  @override
  String get hotelTodayRecording => 'Recording';

  @override
  String get hotelTodaySlideCancel => 'Slide to cancel';

  @override
  String get hotelTodaySlideLock => 'Slide up to lock';

  @override
  String get hotelTodayRecordingLocked => 'Recording locked';

  @override
  String get hotelTodayRecordDelete => 'Delete recording';

  @override
  String get hotelTodayRecordSend => 'Send recording';

  @override
  String get hotelTodayQuickLabel => 'Quick replies';

  @override
  String get hotelTodayQrAvailability => 'Availability';

  @override
  String get hotelTodayQrPrice => 'Price';

  @override
  String get hotelTodayQrVisit => 'Visit';

  @override
  String get hotelTodayQrAddress => 'Address';

  @override
  String hotelTodayQrAvailabilityText(String date) {
    return 'Welcome. $date is available and we would be glad to host you.';
  }

  @override
  String hotelTodayQrPriceText(String guests, String total, String standard) {
    return 'With a Ghazal voucher, the total for $guests is $total instead of $standard. You settle it with us directly after you confirm.';
  }

  @override
  String get hotelTodayQrVisitText =>
      'You are welcome to visit the hall. You can book a visit from our page in the Ghazal app and choose the day that suits you.';

  @override
  String hotelTodayQrAddressText(String venue, String area) {
    return 'You will find us at $venue, $area.';
  }

  @override
  String get hotelTodayMsgSending => 'Sending';

  @override
  String get hotelTodayMsgQueued => 'Waiting for connection';

  @override
  String get hotelTodayMsgFailed => 'Not sent';

  @override
  String get hotelTodayDraftTag => 'Draft';

  @override
  String get hotelTodayThreadEmptyTitle => 'No messages';

  @override
  String get hotelTodayAllPrices => 'All voucher prices';

  @override
  String get hotelTodayAwaitingClient => 'Awaiting client confirmation';

  @override
  String get hotelTodayBillingTitle => 'Billing';

  @override
  String hotelTodayConfirmWindowEnds(String time) {
    return 'Client confirmation window ends in $time';
  }

  @override
  String get hotelTodayFilterListing => 'Listing';

  @override
  String get hotelTodayFilterVisits => 'Visits';

  @override
  String get hotelTodayInboxVisits => 'Visits';

  @override
  String get hotelTodayNewPrice => 'New price';

  @override
  String get hotelTodayNtfListingApproved => 'Listing approved';

  @override
  String get hotelTodayNtfListingRejected => 'Listing not approved';

  @override
  String get hotelTodayNtfListingSubmitted => 'Listing sent for review';

  @override
  String get hotelTodayNtfNewRequest => 'New request';

  @override
  String get hotelTodayNtfRedeemed => 'Voucher redeemed by you';

  @override
  String get hotelTodayPricesTitle => 'Voucher prices';

  @override
  String get hotelTodayRedeem => 'Redeem';

  @override
  String get hotelTodayRequestsMonth => 'Requests this month';

  @override
  String get hotelTodayStatusExempt => 'Major hotel · no listing fees';

  @override
  String get hotelTodayStatusListing => 'A listing needs your attention';

  @override
  String get hotelTodayStatusNoPlan => 'No active listing plan';

  @override
  String hotelTodayStatusPlan(String date) {
    return 'Listing plan ends $date';
  }

  @override
  String hotelTodayStatusVisits(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString visit requests need your reply',
      one: '$countString visit request needs your reply',
    );
    return '$_temp0';
  }

  @override
  String get hotelTodayTilesTitle => 'This month';

  @override
  String get hotelTodayVisitMembers => 'Chat members: client, hotel representative, Ghazal support';

  @override
  String get hotelTodayVoucherMonthTitle => 'Vouchers';

  @override
  String get hotelTodayVouchersRedeemed => 'Vouchers redeemed';

  @override
  String get hotelTodayFirstRunFaceId => 'Face ID';

  @override
  String get hotelTodayFirstRunFingerprint => 'Fingerprint';

  @override
  String get hotelTodayRoleAccountant => 'Accountant';

  @override
  String get hotelTodayRoleMarketing => 'Marketing';

  @override
  String get hotelTodayReadOnly => 'Read only';

  @override
  String get hotelTodayRedeemName => 'Redeem voucher';

  @override
  String get hotelTodayBlockName => 'Block a date';

  @override
  String get hotelTodayNewPriceName => 'New voucher price';

  @override
  String get hotelTodayRedeemedName => 'Vouchers redeemed';

  @override
  String get hotelTodayReviewLabel => 'Listing in review';

  @override
  String get hotelTodayNoPlan => 'No plan';

  @override
  String get hotelTodayFactDate => 'Date';

  @override
  String get hotelTodayFactGuests => 'Guests';

  @override
  String get hotelTodayFactHall => 'Hall';

  @override
  String get hotelTodayFactTime => 'Time';

  @override
  String get hotelTodayFactRating => 'Rating';

  @override
  String get hotelTodayFactVisitors => 'Visitors';

  @override
  String get hotelTodayFactVoucherPrice => 'Voucher price';

  @override
  String get hotelTodayFactReplyBy => 'Reply by';

  @override
  String get hotelTodayFactEnds => 'Ends';

  @override
  String get hotelTodayKindRequest => 'Request';

  @override
  String get hotelTodayKindAwaiting => 'Waiting for client';

  @override
  String get hotelTodayKindVisit => 'Visit request';

  @override
  String get hotelTodayKindMessage => 'Message';

  @override
  String get hotelTodayKindReview => 'Review';

  @override
  String get hotelTodayKindCalendar => 'Calendar check';

  @override
  String get hotelTodayKindListing => 'Listing';

  @override
  String get hotelTodayKindPrice => 'Voucher price ending';

  @override
  String get hotelTodayCalendarCheck => 'Calendar';

  @override
  String hotelTodayListingEndsIn(String time) {
    return 'Plan ends in $time';
  }

  @override
  String hotelTodayWindowEndsIn(String time) {
    return 'Voucher price ends in $time';
  }

  @override
  String get hotelTodayListings => 'Listings';

  @override
  String get hotelTodayNextLabel => 'Next event';

  @override
  String get hotelTodayVouchersBought => 'Vouchers bought';

  @override
  String get hotelTodayVouchersTrend => 'Vouchers bought per day';

  @override
  String get hotelVenueLangBoth => 'AR · EN';

  @override
  String hotelVenueLangArMissing(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'AR $countString';
  }

  @override
  String hotelVenueLangEnMissing(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'EN $countString';
  }

  @override
  String get hotelVenueDashboardTitle => 'Dashboard';

  @override
  String get hotelVenueDashboardCta => 'Dashboard';

  @override
  String get hotelVenueDashboardLead => 'Edited on the dashboard. Existing bookings keep their terms.';

  @override
  String get hotelVenueDashboardItemSeason => 'Seasonal price grids';

  @override
  String get hotelVenueDashboardItemHoliday => 'Holiday and occasion prices';

  @override
  String get hotelVenueDashboardItemSpecial => 'Prices for a single date';

  @override
  String get hotelVenueDashboardItemMenus => 'Menus and menu tiers';

  @override
  String get hotelVenueDashboardItemService => 'Service charge';

  @override
  String get hotelVenueGuardTitle => 'Discard changes?';

  @override
  String get hotelVenueGuardBody => 'You have edits that are not saved. If you leave now, they are lost.';

  @override
  String get hotelVenueGuardDiscard => 'Discard';

  @override
  String get hotelVenueGuardKeep => 'Keep editing';

  @override
  String hotelVenueOfflineStrip(String time) {
    return 'Offline · $time';
  }

  @override
  String get hotelVenueNeedsConnection => 'Needs a connection.';

  @override
  String get hotelVenueRequired => 'Required';

  @override
  String get hotelVenueErrorTitle => 'Couldn’t load';

  @override
  String get hotelVenueErrorBody => 'Nothing changed. Check your connection and try again.';

  @override
  String hotelVenueFieldInArabic(String field) {
    return '$field (AR)';
  }

  @override
  String hotelVenueFieldInEnglish(String field) {
    return '$field (EN)';
  }

  @override
  String get hotelVenuePriceError => 'Invalid amount';

  @override
  String get hotelVenueZoneHall => 'Hall';

  @override
  String get hotelVenueZoneStage => 'Stage and Kosha';

  @override
  String get hotelVenueZoneBridal => 'Bridal suite';

  @override
  String get hotelVenueZoneBuffet => 'Buffet';

  @override
  String get hotelVenueZoneOutdoors => 'Outdoors';

  @override
  String get hotelVenueZoneEntrance => 'Entrance and valet';

  @override
  String get hotelVenueZoneLayouts => 'Layouts';

  @override
  String get hotelVenueZoneStageShort => 'Stage';

  @override
  String get hotelVenueZoneBridalShort => 'Suite';

  @override
  String get hotelVenueZoneEntranceShort => 'Entrance';

  @override
  String get hotelVenueZoneFilter => 'Filter photos by zone';

  @override
  String hotelVenueZoneAll(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'All $countString';
  }

  @override
  String hotelVenueZoneCount(String zone, num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$zone $countString';
  }

  @override
  String get hotelVenueMediaTitle => 'Photos and videos';

  @override
  String get hotelVenueMediaTabs => 'Photos or videos';

  @override
  String hotelVenueMediaTabPhotos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Photos $countString';
  }

  @override
  String hotelVenueMediaTabVideos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Videos $countString';
  }

  @override
  String get hotelVenueMediaEmptyTitle => 'No photos';

  @override
  String get hotelVenueAddPhotosCta => 'Add photos';

  @override
  String get hotelVenueAddVideoCta => 'Add video';

  @override
  String get hotelVenueAddPhotoTitle => 'Add a photo';

  @override
  String get hotelVenueAddVideoTitle => 'Add a video';

  @override
  String get hotelVenuePhotoSheetTitle => 'Photo';

  @override
  String get hotelVenueVideoSheetTitle => 'Video';

  @override
  String hotelVenuePhotoCount(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get hotelVenueReorder => 'Reorder';

  @override
  String get hotelVenueReorderDone => 'Done';

  @override
  String get hotelVenueReorderHint => 'Use the arrows';

  @override
  String get hotelVenueShowAll => 'Show all';

  @override
  String get hotelVenueEmptyRoomOnly => 'Empty rooms only';

  @override
  String hotelVenueAttentionRejected(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString to replace';
  }

  @override
  String get hotelVenueStatusReview => 'Review';

  @override
  String get hotelVenueStatusRejected => 'Replace';

  @override
  String get hotelVenueStatusLive => 'Live';

  @override
  String get hotelVenueReviewNote => 'Only you see it';

  @override
  String hotelVenueUploading(String percent) {
    return 'Uploading · $percent';
  }

  @override
  String get hotelVenueUploadingLabel => 'Upload progress';

  @override
  String get hotelVenueUploadFailed => 'Upload failed';

  @override
  String get hotelVenueUploadQueued => 'Waiting';

  @override
  String get hotelVenueUploadRetry => 'Try again';

  @override
  String get hotelVenueOfflineQueueNote => 'Offline. Uploads wait here.';

  @override
  String hotelVenueVideoOpen(String name) {
    return 'Open $name';
  }

  @override
  String hotelVenueVideoLimits(num size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);

    return 'Up to $sizeString MB';
  }

  @override
  String get hotelVenueVideoTooLarge => 'Too large';

  @override
  String hotelVenueVideoTooLargeBody(num size) {
    final intl.NumberFormat sizeNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String sizeString = sizeNumberFormat.format(size);

    return 'Max $sizeString MB';
  }

  @override
  String get hotelVenueVideoEmptyTitle => 'No videos';

  @override
  String get hotelVenueVideoNote => 'Plays on tap';

  @override
  String get hotelVenueVideoDelete => 'Delete video';

  @override
  String get hotelVenueVideoDeleteTitle => 'Delete this video?';

  @override
  String get hotelVenueVideoDeleteBody => 'It leaves the listing.';

  @override
  String get hotelVenueNewVideoTitle => 'New walkthrough video';

  @override
  String get hotelVenueToastVideoDeleted => 'Video deleted';

  @override
  String get hotelVenueToastVideoAdded => 'Video added';

  @override
  String get hotelVenueCover => 'Cover';

  @override
  String get hotelVenueSetCover => 'Set as cover';

  @override
  String get hotelVenueEditPhoto => 'Edit details';

  @override
  String get hotelVenueDeletePhoto => 'Delete photo';

  @override
  String get hotelVenueDeleteTitle => 'Delete this photo?';

  @override
  String get hotelVenueDeleteBody => 'It leaves the listing.';

  @override
  String get hotelVenueDeleteConfirm => 'Delete';

  @override
  String get hotelVenueDeleteKeep => 'Keep';

  @override
  String get hotelVenueReplace => 'Replace photo';

  @override
  String get hotelVenueReplaceTitle => 'Replace photo';

  @override
  String get hotelVenueReasonPerson => 'A person is visible';

  @override
  String get hotelVenueReplaceShort => 'Replace';

  @override
  String get hotelVenueReasonPersonBody => 'Use an empty room.';

  @override
  String get hotelVenueFieldZone => 'Zone';

  @override
  String get hotelVenueFieldAlt => 'Alt text';

  @override
  String get hotelVenueAltHelper => 'For screen readers';

  @override
  String get hotelVenueAltBothFirst => 'Add both languages';

  @override
  String get hotelVenueUploadZoneFirst => 'Choose a zone';

  @override
  String get hotelVenueToastCover => 'Cover photo updated';

  @override
  String get hotelVenueToastDeleted => 'Photo deleted';

  @override
  String get hotelVenueToastPhotoSaved => 'Photo details saved';

  @override
  String get hotelVenueSourceCamera => 'Camera';

  @override
  String get hotelVenueSourceLibrary => 'Library';

  @override
  String get hotelVenueSourceVideo => 'Choose a video';

  @override
  String get hotelVenueUploadCta => 'Upload photo';

  @override
  String get hotelVenueFaceTitle => 'A person is visible';

  @override
  String get hotelVenueFaceBody => 'Retake or crop the photo.';

  @override
  String get hotelVenueFaceRetake => 'Retake';

  @override
  String get hotelVenueFaceCrop => 'Crop';

  @override
  String get hotelVenueFaceFirst => 'Retake or crop first';

  @override
  String get hotelVenueToastUploadStarted => 'Upload started';

  @override
  String get hotelVenueToastQueued => 'Queued';

  @override
  String get hotelVenueToastPhotoAdded => 'Photo added';

  @override
  String get hotelVenueToastReplaced => 'Photo replaced';

  @override
  String hotelVenueChipReview(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Under review $countString';
  }

  @override
  String get hotelVenueUploadDemoPhoto => 'New photo';

  @override
  String get hotelVenueSave => 'Save changes';

  @override
  String get hotelVenueSavedState => 'Saved';

  @override
  String get hotelVenueFieldName => 'Name';

  @override
  String get hotelVenueFieldDescription => 'Description';

  @override
  String get hotelVenueFieldPrice => 'Price';

  @override
  String get hotelVenueNameRequired => 'Name in both languages';

  @override
  String get hotelVenueReservedName => 'Reserved name';

  @override
  String get hotelVenueAudWomen => 'Ladies';

  @override
  String get hotelVenueAudMen => 'Men';

  @override
  String get hotelVenueAudMixed => 'Mixed';

  @override
  String hotelVenueGuestRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get hotelVenueUnitEvent => 'per event';

  @override
  String get hotelVenueUnitUnit => 'per unit';

  @override
  String get hotelVenueAllDays => 'Every day';

  @override
  String get hotelVenueHidden => 'Hidden';

  @override
  String get hotelVenueOfflineChange => 'Needs a connection to change.';

  @override
  String get hotelVenuePackagesTitle => 'Packages';

  @override
  String get hotelVenuePackagesTabs => 'Packages or extras';

  @override
  String hotelVenueTabPackages(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Packages ($countString)';
  }

  @override
  String hotelVenueTabExtras(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Extras ($countString)';
  }

  @override
  String get hotelVenuePkgNew => 'New package';

  @override
  String get hotelVenueExtraAdd => 'Add extra';

  @override
  String get hotelVenuePkgEmptyTitle => 'No packages';

  @override
  String get hotelVenueExtraEmptyTitle => 'No extras';

  @override
  String hotelVenuePkgActiveLabel(String name) {
    return 'Show $name to couples';
  }

  @override
  String hotelVenueToastPkgHidden(String name) {
    return '$name hidden';
  }

  @override
  String hotelVenueToastPkgShown(String name) {
    return '$name visible';
  }

  @override
  String hotelVenueToastExtraHidden(String name) {
    return '$name hidden';
  }

  @override
  String hotelVenueToastExtraShown(String name) {
    return '$name visible';
  }

  @override
  String hotelVenueArchivedHead(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Archived ($countString)';
  }

  @override
  String get hotelVenueRestore => 'Restore';

  @override
  String hotelVenueToastRestored(String name) {
    return '$name restored';
  }

  @override
  String hotelVenueToastArchived(String name) {
    return '$name archived';
  }

  @override
  String hotelVenueEditPackage(String name) {
    return 'Edit $name';
  }

  @override
  String get hotelVenueExtraEditTitle => 'Edit extra';

  @override
  String get hotelVenueExtraNewTitle => 'New extra';

  @override
  String get hotelVenueFieldUnit => 'Charged';

  @override
  String get hotelVenueFieldShow => 'Show to couples';

  @override
  String hotelVenueExtraRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get hotelVenueToastExtraSaved => 'Saved';

  @override
  String get hotelVenueToastExtraCreated => 'Added';

  @override
  String get hotelVenueNeedPrice => 'Enter a price';

  @override
  String get hotelVenuePkgEditTitle => 'Edit package';

  @override
  String get hotelVenueSecName => 'Name';

  @override
  String get hotelVenueSecAudience => 'Audience';

  @override
  String get hotelVenueSecPricing => 'Pricing';

  @override
  String get hotelVenueSecGuests => 'Guests';

  @override
  String get hotelVenueSecInclusions => 'Included';

  @override
  String get hotelVenueSecPreview => 'Preview';

  @override
  String get hotelVenueSecStatus => 'Status';

  @override
  String get hotelVenueAudienceLabel => 'Audience';

  @override
  String get hotelVenueAudienceNeeded => 'Choose an audience';

  @override
  String get hotelVenueHallsLabel => 'Halls';

  @override
  String get hotelVenueHallsNeeded => 'Choose a hall';

  @override
  String get hotelVenueBasisLabel => 'Pricing basis';

  @override
  String get hotelVenueBasisFlat => 'Flat';

  @override
  String get hotelVenueBasisFlatPlus => 'Flat + guest';

  @override
  String hotelVenueDaysWeekday(String from, String to) {
    return 'Weekday · $from to $to';
  }

  @override
  String hotelVenueDaysWeekend(String from, String to) {
    return 'Weekend · $from to $to';
  }

  @override
  String hotelVenueDaysSwitch(String days) {
    return 'Offer on $days';
  }

  @override
  String get hotelVenueBundleNote => 'Priced from two packages';

  @override
  String get hotelVenueTierNeeded => 'Offer on some days';

  @override
  String get hotelVenueGuestsMin => 'Min guests';

  @override
  String get hotelVenueGuestsMax => 'Max guests';

  @override
  String get hotelVenueMaxBelowMin => 'Max below min';

  @override
  String hotelVenueMaxOverHall(String max) {
    return 'Over hall capacity ($max)';
  }

  @override
  String get hotelVenueInclusionAdd => 'Add';

  @override
  String hotelVenueInclusionRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get hotelVenueInclusionSheetTitle => 'Add';

  @override
  String get hotelVenueInclusionPick => 'Facilities';

  @override
  String get hotelVenueInclusionOwn => 'Your own';

  @override
  String get hotelVenueInclusionOwnLabel => 'Inclusion';

  @override
  String get hotelVenueInclusionBoth => 'Both languages';

  @override
  String get hotelVenueActiveTitle => 'Visible';

  @override
  String get hotelVenueArchive => 'Archive';

  @override
  String get hotelVenueArchiveTitle => 'Archive?';

  @override
  String get hotelVenueArchiveBody => 'Hidden from couples. You can restore it.';

  @override
  String get hotelVenueArchiveConfirm => 'Archive';

  @override
  String get hotelVenuePvDate => 'Date and guests';

  @override
  String get hotelVenuePvGuests => 'Guests only';

  @override
  String get hotelVenuePvNone => 'Neither';

  @override
  String get hotelVenuePvOff => 'Not offered';

  @override
  String get hotelVenuePvNoName => 'Name';

  @override
  String get hotelVenueToastPkgSaved => 'Saved';

  @override
  String get hotelVenueToastPkgCreated => 'Added';

  @override
  String get hotelVenueReasonPrices => 'Enter prices';

  @override
  String get hotelVenueReasonGuests => 'Fix guest numbers';

  @override
  String get hotelVenueExtraActiveOn => 'Couples can add this extra to a request.';

  @override
  String get hotelVenueExtraActiveOff => 'Hidden from couples.';

  @override
  String get hotelVenueSettingIndoor => 'Indoor';

  @override
  String get hotelVenueSettingOutdoor => 'Outdoor';

  @override
  String get hotelVenueSettingMixed => 'Both';

  @override
  String get hotelVenueNone => 'None';

  @override
  String get hotelVenueHallsTitle => 'Halls';

  @override
  String get hotelVenueHallEditTitle => 'Edit hall';

  @override
  String get hotelVenueSecCapacity => 'Capacity';

  @override
  String get hotelVenueSecHallAudience => 'Audience';

  @override
  String get hotelVenueSecSessions => 'Sessions';

  @override
  String get hotelVenueSecFacilities => 'Facilities';

  @override
  String get hotelVenueSecSections => 'By section';

  @override
  String get hotelVenueCapMax => 'Max guests';

  @override
  String hotelVenueCapMin(String audience) {
    return 'Min · $audience';
  }

  @override
  String get hotelVenueMinAboveMax => 'Min above max';

  @override
  String get hotelVenueAudAtLeastOne => 'Choose an audience';

  @override
  String get hotelVenueSettingLabel => 'Setting';

  @override
  String get hotelVenueAudienceAllowed => 'Audiences allowed';

  @override
  String get hotelVenueExclusiveTitle => 'Whole day';

  @override
  String get hotelVenueSessionAdd => 'Add session';

  @override
  String hotelVenueSessionLine(String from, String to) {
    return '$from to $to';
  }

  @override
  String get hotelVenueSessionNeeded => 'Add a session';

  @override
  String get hotelVenueSessionEditTitle => 'Edit session';

  @override
  String get hotelVenueSessionNewTitle => 'New session';

  @override
  String get hotelVenueSessionName => 'Name';

  @override
  String get hotelVenueSessionStart => 'Starts';

  @override
  String get hotelVenueSessionEnd => 'Ends';

  @override
  String get hotelVenueSessionSetup => 'Setup';

  @override
  String get hotelVenueSessionTeardown => 'Teardown';

  @override
  String get hotelVenueSessionDelete => 'Delete';

  @override
  String get hotelVenueSessionAfterMidnight => 'After midnight';

  @override
  String get hotelVenueSessionNameNeeded => 'Name both languages';

  @override
  String get hotelVenuePresetsLabel => 'Start from a preset';

  @override
  String get hotelVenuePresetAfternoon => 'Afternoon';

  @override
  String get hotelVenuePresetEvening => 'Evening';

  @override
  String get hotelVenuePresetFull => 'Full day';

  @override
  String get hotelVenueAmIncluded => 'Included';

  @override
  String get hotelVenueAmExtra => 'Extra cost';

  @override
  String get hotelVenueAmNone => 'Not offered';

  @override
  String hotelVenueAmenityOf(String name, String audience) {
    return '$name · $audience';
  }

  @override
  String hotelVenueAmenityChoose(String name) {
    return 'Choose for $name';
  }

  @override
  String get hotelVenueSectionWomen => 'Ladies';

  @override
  String get hotelVenueSectionMen => 'Men';

  @override
  String get hotelVenueSectionMixed => 'Mixed';

  @override
  String get hotelVenueFactPhoto => 'Photography';

  @override
  String get hotelVenueFactMusic => 'Music';

  @override
  String get hotelVenuePhotoFemale => 'Women only';

  @override
  String get hotelVenuePhotoAllowed => 'Allowed';

  @override
  String get hotelVenuePhotoNone => 'None';

  @override
  String get hotelVenueMusicDj => 'DJ';

  @override
  String get hotelVenueMusicLive => 'Live';

  @override
  String get hotelVenueMusicDuff => 'Duff';

  @override
  String get hotelVenueMusicNone => 'None';

  @override
  String get hotelVenueLinkRules => 'Booking rules';

  @override
  String get hotelVenueToastHallSaved => 'Saved';

  @override
  String get hotelVenuePolTitle => 'Policies';

  @override
  String get hotelVenueSecChildren => 'Boys';

  @override
  String get hotelVenueSecDress => 'Dress code';

  @override
  String get hotelVenueChildrenNoLimit => 'No limit';

  @override
  String get hotelVenueChildrenLimit => 'Limit';

  @override
  String get hotelVenueChildrenAge => 'Max age';

  @override
  String hotelVenueYears(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString years', one: '$countString year');
    return '$_temp0';
  }

  @override
  String get hotelVenueDressLabel => 'Dress code';

  @override
  String get hotelVenueDressNeeded => 'Dress code in both languages';

  @override
  String get hotelVenueToastPolicySaved => 'Saved';

  @override
  String get hotelVenueRulesTitle => 'Booking rules';

  @override
  String get hotelVenueRulesHall => 'Hall';

  @override
  String get hotelVenueSecMode => 'Mode';

  @override
  String get hotelVenueSecResponse => 'Reply';

  @override
  String get hotelVenueModeRequest => 'Request to book';

  @override
  String get hotelVenueRespondLabel => 'Reply within';

  @override
  String get hotelVenueRespondWarn => 'May lower response rate';

  @override
  String get hotelVenueNoticeDays => 'Notice';

  @override
  String get hotelVenueLinkCalendar => 'Calendar';

  @override
  String get hotelVenueToastRulesSaved => 'Saved';

  @override
  String get hotelVenueWindowsRow => 'Voucher windows';

  @override
  String get hotelVenueReasonVoucher => 'Voucher above standard';

  @override
  String get hotelVenueStdFlat => 'Flat';

  @override
  String get hotelVenueStdPerGuest => 'Per guest';

  @override
  String get hotelVenueVchFlat => 'Flat';

  @override
  String get hotelVenueVchPerGuest => 'Per guest';

  @override
  String get hotelVenueVoucherAboveFlat => 'Above standard';

  @override
  String get hotelVenueVoucherAboveGuest => 'Above standard';

  @override
  String hotelVenueVchBelowFee(String fee) {
    return 'Saving under $fee';
  }

  @override
  String hotelVenueVchSaving(String amount) {
    return 'Saves $amount';
  }

  @override
  String hotelVenuePvStandard(String standard) {
    return 'Standard $standard';
  }

  @override
  String get hotelVenueNoVoucherTag => 'No voucher price';

  @override
  String hotelVenueHoursRun(String from, String to) {
    return '$from to $to';
  }

  @override
  String hotelVenueHoursLine(String from, String to) {
    return '$from to $to';
  }

  @override
  String get hotelVenueHoursOpen => 'Opens';

  @override
  String get hotelVenueHoursClose => 'Closes';

  @override
  String get hotelVenueHoursTitle => 'Hours';

  @override
  String get hotelVenueSecHours => 'Hours';

  @override
  String get hotelVenueSecTerms => 'Terms';

  @override
  String get hotelVenueTermsLabel => 'Terms';

  @override
  String get hotelVenueTermsNeeded => 'Terms in both languages';

  @override
  String get hotelVenueVoucherTermsTitle => 'Voucher terms';

  @override
  String get hotelVenueVtFee => 'Fee';

  @override
  String get hotelVenueVtValidity => 'Valid';

  @override
  String get hotelVenueVtConfirm => 'Confirm';

  @override
  String get hotelVenueVtRedeem => 'At venue';

  @override
  String get hotelVenueVtRedeemValue => 'Code';

  @override
  String get hotelVenueSecConfirm => 'Notice';

  @override
  String get hotelVenueConfirmLabel => 'Confirm';

  @override
  String hotelVenueConfirmFixed(String hours) {
    return '$hours';
  }

  @override
  String get hotelVenueNoticeShort => 'Notice shorter than reply window';

  @override
  String get hotelVenueLinkVoucher => 'Voucher prices';

  @override
  String get hotelVenueLinkVisits => 'Visits';

  @override
  String get hotelVenueTlRequest => 'Request';

  @override
  String hotelVenueTlReply(String hours) {
    return 'Reply $hours';
  }

  @override
  String hotelVenueTlConfirm(String hours) {
    return 'Confirm $hours';
  }

  @override
  String get hotelVenueTlPay => 'Pay venue';

  @override
  String hotelVenueTlPayText(String voucher, String standard) {
    return '$voucher · $standard';
  }

  @override
  String get hotelVenueSecProfile => 'Profile';

  @override
  String get hotelVenueTypeLabel => 'Venue type';

  @override
  String get hotelVenueTypePending => 'Pending';

  @override
  String get hotelVenueToastTypeSent => 'Sent';

  @override
  String get hotelVenueSecHalls => 'Halls';

  @override
  String get hotelVenueStd => 'Standard';

  @override
  String get hotelVenueVch => 'Voucher';

  @override
  String get hotelVisitsActorHotel => 'Hotel';

  @override
  String get hotelVisitsActorSupport => 'Ghazal support';

  @override
  String get hotelVisitsActorSystem => 'Ghazal';

  @override
  String get hotelVisitsArrivalTitle => 'Arrival';

  @override
  String get hotelVisitsArrivalError => 'Not saved';

  @override
  String get hotelVisitsDemoJump => 'Demo: jump to the day of the visit';

  @override
  String hotelVisitsArrivedDoneTitle(String name) {
    return '$name arrived';
  }

  @override
  String get hotelVisitsMarkArrived => 'Mark arrived';

  @override
  String get hotelVisitsDidNotArrive => 'No-show';

  @override
  String get hotelVisitsMissedCta => 'No-show';

  @override
  String get hotelVisitsMissedDialogTitle => 'Mark no-show?';

  @override
  String get hotelVisitsMissedDialogBody => 'Ghazal support is informed.';

  @override
  String hotelVisitsMissedDoneTitle(String name) {
    return '$name did not arrive';
  }

  @override
  String hotelVisitsMissedFrom(String time) {
    return 'From $time';
  }

  @override
  String hotelVisitsOnTheWayTitle(String name) {
    return '$name is on the way';
  }

  @override
  String hotelVisitsOnTheWayBody(String time) {
    return '$time';
  }

  @override
  String get hotelVisitsSlotEndedTitle => 'Window ended';

  @override
  String hotelVisitsSlotEndedBody(String name) {
    return '$name';
  }

  @override
  String get hotelVisitsAttachTitle => 'Attach';

  @override
  String get hotelVisitsAttachCamera => 'Camera';

  @override
  String get hotelVisitsAttachPhoto => 'Photos';

  @override
  String get hotelVisitsAttachDocument => 'Document';

  @override
  String get hotelVisitsAvailTitle => 'Visit hours';

  @override
  String get hotelVisitsAvailabilityAction => 'Visit hours';

  @override
  String get hotelVisitsAvailErrorTitle => 'Did not load';

  @override
  String get hotelVisitsAvailHiddenTitle => 'Admin and Manager only';

  @override
  String get hotelVisitsAvailHiddenBody => 'Ask your manager.';

  @override
  String get hotelVisitsMasterTitle => 'Accept visits';

  @override
  String get hotelVisitsOffTitle => 'Visits off';

  @override
  String get hotelVisitsOffBody => 'Hidden from your page';

  @override
  String get hotelVisitsSecDays => 'Days';

  @override
  String get hotelVisitsDayNoVisits => 'Off';

  @override
  String get hotelVisitsDayFrom => 'From';

  @override
  String get hotelVisitsDayTo => 'To';

  @override
  String hotelVisitsDayOpenLabel(String day) {
    return 'Visits on $day';
  }

  @override
  String hotelVisitsDayPick(String what, String time) {
    return '$what at $time';
  }

  @override
  String get hotelVisitsDayErrorOrder => 'End after start';

  @override
  String get hotelVisitsDayErrorBounds => 'Within business hours';

  @override
  String get hotelVisitsSeeBusinessHours => 'Business hours';

  @override
  String get hotelVisitsTimeFrom => 'From';

  @override
  String get hotelVisitsTimeTo => 'To';

  @override
  String get hotelVisitsTimeSet => 'Set';

  @override
  String get hotelVisitsSecSlot => 'Window';

  @override
  String hotelVisitsSlotChip(String minutes) {
    return '$minutes min';
  }

  @override
  String get hotelVisitsSecRepDefault => 'Default rep';

  @override
  String get hotelVisitsRepNone => 'None';

  @override
  String get hotelVisitsSecBlackouts => 'Blackout dates';

  @override
  String get hotelVisitsBlackoutsAdd => 'Add dates';

  @override
  String get hotelVisitsBlackoutTitle => 'Blackout dates';

  @override
  String get hotelVisitsBlackoutNeed => 'Pick a day';

  @override
  String get hotelVisitsBlackoutAdd => 'Add';

  @override
  String hotelVisitsBlackoutRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String hotelVisitsBlackoutRemove(String range) {
    return 'Remove blackout $range';
  }

  @override
  String get hotelVisitsSave => 'Save';

  @override
  String get hotelVisitsSaveClean => 'No changes';

  @override
  String get hotelVisitsSaveInvalid => 'Fix days';

  @override
  String get hotelVisitsSaveOfflineToast => 'Offline';

  @override
  String get hotelVisitsSaved => 'Saved';

  @override
  String get hotelVisitsSavedBanner => 'Saved';

  @override
  String get hotelVisitsGuardTitle => 'Leave unsaved?';

  @override
  String get hotelVisitsGuardBody => 'Changes are lost.';

  @override
  String get hotelVisitsGuardLeave => 'Leave';

  @override
  String get hotelVisitsGuardStay => 'Stay';

  @override
  String get hotelVisitsChatTitle => 'Visit chat';

  @override
  String get hotelVisitsChatErrorTitle => 'Chat did not load';

  @override
  String hotelVisitsChatOfflineBanner(String time) {
    return 'Offline. Last update $time';
  }

  @override
  String get hotelVisitsChatReadOnlyRole => 'Read only';

  @override
  String get hotelVisitsChatClosedAfter => 'Chat closed';

  @override
  String get hotelVisitsChatClosedCancelled => 'Cancelled';

  @override
  String get hotelVisitsChatClosedDeclined => 'Declined';

  @override
  String get hotelVisitsMsgFailed => 'Not sent';

  @override
  String get hotelVisitsMsgQueued => 'Queued';

  @override
  String get hotelVisitsMsgSending => 'Sending';

  @override
  String get hotelVisitsRecordHold => 'Hold to record';

  @override
  String get hotelVisitsQrConfirm => 'Confirm visit';

  @override
  String get hotelVisitsQrConfirmText => 'Visit confirmed. We look forward to welcoming you.';

  @override
  String get hotelVisitsQrEntrance => 'Main entrance';

  @override
  String get hotelVisitsQrEntranceText => 'Please use the main entrance.';

  @override
  String get hotelVisitsQrParking => 'Parking';

  @override
  String get hotelVisitsQrParkingText => 'Parking is at the front.';

  @override
  String hotelVisitsLineConfirmed(String when) {
    return 'Confirmed for $when';
  }

  @override
  String hotelVisitsLineReschedule(String name, String when) {
    return '$name proposed $when';
  }

  @override
  String hotelVisitsLineArrived(String name) {
    return 'Welcome, $name';
  }

  @override
  String get hotelVisitsLineCompleted => 'Visit complete';

  @override
  String get hotelVisitsLineDeclined => 'Visit declined';

  @override
  String get hotelVisitsLineCancelled => 'Visit cancelled';

  @override
  String get hotelVisitsLineMissed => 'Client did not arrive';

  @override
  String get hotelVisitsLineClosed => 'Chat closed';

  @override
  String get hotelVisitsMembersTitle => 'Members';

  @override
  String get hotelVisitsRepTitle => 'Representative';

  @override
  String get hotelVisitsQueueTitle => 'Visits';

  @override
  String get hotelVisitsSegments => 'Visits by status';

  @override
  String get hotelVisitsSegRequested => 'Requested';

  @override
  String get hotelVisitsSegUpcoming => 'Upcoming';

  @override
  String get hotelVisitsSegPast => 'Past';

  @override
  String hotelVisitsRequestedAgo(String ago) {
    return '$ago';
  }

  @override
  String hotelVisitsOpenVisit(String name, String when) {
    return 'Open the visit of $name, $when';
  }

  @override
  String get hotelVisitsEmptyRequestedTitle => 'No requests';

  @override
  String get hotelVisitsEmptyRequestedBody => 'Clients can book a visit from your venue page.';

  @override
  String get hotelVisitsEmptyUpcomingTitle => 'No upcoming visits';

  @override
  String get hotelVisitsEmptyUpcomingBody => 'Confirmed visits appear here with their chat.';

  @override
  String get hotelVisitsEmptyPastTitle => 'No past visits';

  @override
  String get hotelVisitsEmptyPastBody => 'Completed, declined and missed visits are kept here.';

  @override
  String get hotelVisitsSeeUpcoming => 'Upcoming';

  @override
  String get hotelVisitsErrorTitle => 'Did not load';

  @override
  String get hotelVisitsErrorBody => 'Try again';

  @override
  String hotelVisitsOfflineBanner(String time) {
    return 'Offline. Saved $time';
  }

  @override
  String get hotelVisitsOfflineBannerShort => 'Offline';

  @override
  String get hotelVisitsOfflineReason => 'Offline';

  @override
  String get hotelVisitsReadOnlyNote => 'Read only';

  @override
  String get hotelVisitsNoAccessTitle => 'No access';

  @override
  String get hotelVisitsNoAccessBody => 'Ask your manager';

  @override
  String get hotelVisitsConfirm => 'Confirm';

  @override
  String get hotelVisitsPropose => 'Another time';

  @override
  String get hotelVisitsOpenChat => 'Open chat';

  @override
  String get hotelVisitsComplete => 'Complete';

  @override
  String get hotelVisitsCorrectMissed => 'Client arrived';

  @override
  String get hotelVisitsToastConfirmed => 'Confirmed';

  @override
  String get hotelVisitsToastProposed => 'Proposal sent';

  @override
  String get hotelVisitsToastDeclined => 'Declined';

  @override
  String get hotelVisitsToastAssigned => 'Assigned';

  @override
  String get hotelVisitsToastCompleted => 'Completed';

  @override
  String get hotelVisitsProposeTitle => 'Another time';

  @override
  String get hotelVisitsProposeDay => 'Day';

  @override
  String get hotelVisitsProposeTime => 'Time';

  @override
  String get hotelVisitsProposeCta => 'Send';

  @override
  String get hotelVisitsProposeNeed => 'Pick day and time';

  @override
  String get hotelVisitsDeclineTitle => 'Decline';

  @override
  String get hotelVisitsDeclineReason => 'Reason';

  @override
  String get hotelVisitsReasonUnavailable => 'Not available';

  @override
  String get hotelVisitsReasonClosed => 'Venue closed';

  @override
  String get hotelVisitsReasonOther => 'Other';

  @override
  String get hotelVisitsDeclineNote => 'Note';

  @override
  String get hotelVisitsDeclineNoteRequired => 'Add a note';

  @override
  String get hotelVisitsDeclineNeed => 'Pick a reason';

  @override
  String get hotelVisitsDeclineCta => 'Decline';

  @override
  String hotelVisitsDetailTitle(String when) {
    return 'Visit · $when';
  }

  @override
  String get hotelVisitsDetailErrorTitle => 'Did not load';

  @override
  String get hotelVisitsSecClient => 'Client';

  @override
  String get hotelVisitsSecVisit => 'Request';

  @override
  String get hotelVisitsFactRequested => 'Sent';

  @override
  String get hotelVisitsFactProposed => 'Proposed';

  @override
  String get hotelVisitsSecNote => 'Note';

  @override
  String get hotelVisitsSecRep => 'Representative';

  @override
  String get hotelVisitsSecChat => 'Members';

  @override
  String get hotelVisitsSecTimeline => 'Timeline';

  @override
  String hotelVisitsLimitedNote(String name) {
    return '$name only';
  }

  @override
  String get hotelVisitsNoteRequested => 'Awaiting reply';

  @override
  String hotelVisitsNoteReschedule(String when) {
    return 'Proposed $when';
  }

  @override
  String get hotelVisitsNoteConfirmed => 'Confirmed';

  @override
  String hotelVisitsNoteDayOf(String time) {
    return 'Today $time';
  }

  @override
  String hotelVisitsNoteArrived(String time) {
    return 'Arrived $time';
  }

  @override
  String get hotelVisitsNoteCompleted => 'Completed';

  @override
  String get hotelVisitsNoteDeclined => 'Declined';

  @override
  String hotelVisitsNoteDeclinedReason(String reason) {
    return 'Declined: $reason';
  }

  @override
  String get hotelVisitsNoteCancelled => 'Cancelled';

  @override
  String get hotelVisitsNoteMissed => 'No-show';

  @override
  String get hotelVisitsTlRequested => 'Requested';

  @override
  String get hotelVisitsTlConfirmed => 'Confirmed';

  @override
  String get hotelVisitsTlReschedule => 'Another time proposed';

  @override
  String get hotelVisitsTlArrived => 'Arrived';

  @override
  String get hotelVisitsTlCompleted => 'Completed';

  @override
  String get hotelVisitsTlDeclined => 'Declined';

  @override
  String get hotelVisitsTlCancelled => 'Cancelled';

  @override
  String get hotelVisitsTlMissed => 'Did not arrive';

  @override
  String hotelVisitsVisitors(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString visitors',
      one: '$countString visitor',
      zero: 'No visitors',
    );
    return '$_temp0';
  }

  @override
  String get hotelVisitsProposeShort => 'Another time';
}
