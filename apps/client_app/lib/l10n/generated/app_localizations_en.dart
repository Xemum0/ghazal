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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString guests',
      one: '$countString guest',
    );
    return 'Minimum $_temp0';
  }

  @override
  String commonUnitUpToGuests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString guests',
      one: '$countString guest',
    );
    return 'Up to $_temp0';
  }

  @override
  String commonCountGuests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString guests',
      one: '$countString guest',
      zero: 'No guests',
    );
    return '$_temp0';
  }

  @override
  String commonCountDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days',
      one: '$countString day',
      zero: 'No days',
    );
    return '$_temp0';
  }

  @override
  String commonCountHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours',
      one: '$countString hour',
      zero: 'No hours',
    );
    return '$_temp0';
  }

  @override
  String commonCountMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString minutes',
      one: '$countString minute',
      zero: 'No minutes',
    );
    return '$_temp0';
  }

  @override
  String commonCountHalls(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString halls',
      one: '$countString hall',
      zero: 'No halls',
    );
    return '$_temp0';
  }

  @override
  String commonCountPackages(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString months',
      one: '$countString month',
      zero: 'No months',
    );
    return '$_temp0';
  }

  @override
  String commonCountDates(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString dates',
      one: '$countString date',
      zero: 'No dates',
    );
    return '$_temp0';
  }

  @override
  String commonCountRequests(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString reviews',
      one: '$countString review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String commonCountPhotos(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString photos',
      one: '$countString photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String commonCountdownDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString days to go',
      one: '$countString day to go',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String commonCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
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
  String get commonStateErrorGeneric =>
      'Something went wrong on our side. Nothing was changed. Please try again.';

  @override
  String get commonStateErrorLoad => 'We couldn’t load this. Please try again.';

  @override
  String get commonStateErrorNetwork =>
      'We couldn’t connect. Check your connection and try again.';

  @override
  String get commonStateErrorPayment =>
      'The payment could not be completed. No amount was charged.';

  @override
  String get commonStateErrorNoAccess =>
      'You do not have access. Ask your manager.';

  @override
  String get commonStateErrorNotFound => 'This page is no longer available.';

  @override
  String get commonStateSaved => 'Saved';

  @override
  String get commonStateCopied => 'Copied';

  @override
  String get commonStateSent => 'Sent';

  @override
  String get commonNoPaymentNowFull =>
      'No payment now. Nothing is charged until the hotel approves.';

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
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Photo $currentString of $totalString';
  }

  @override
  String commonA11yRating(num rating, num max) {
    final intl.NumberFormat ratingNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String ratingString = ratingNumberFormat.format(rating);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
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
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hoursString hours',
      one: '$hoursString hour',
    );
    return 'Not confirmed within $_temp0';
  }

  @override
  String commonVoucherConfirmIn24h(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hoursString hours',
      one: '$hoursString hour',
    );
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
  String get clientAuthSharedNotNow => 'Not now';

  @override
  String get clientAuthSharedSupport => 'Support';

  @override
  String get clientAuthSharedApple => 'Apple';

  @override
  String get clientAuthSharedGoogle => 'Google';

  @override
  String get clientAuthSharedUsePassword => 'Password';

  @override
  String get clientAuthSharedUseCode => 'WhatsApp code';

  @override
  String get clientAuthSharedSignIn => 'Sign in';

  @override
  String get clientAuthSharedCreateAccount => 'Create account';

  @override
  String get clientAuthSharedSignedIn => 'Signed in';

  @override
  String get clientAuthSharedAccountReady => 'Account ready';

  @override
  String get clientAuthSharedPhone => 'Mobile';

  @override
  String get clientAuthSharedSendCode => 'Send code';

  @override
  String get clientAuthSharedDate => 'Date';

  @override
  String get clientAuthSharedGuests => 'Guests';

  @override
  String get clientAuthSharedLegalTerms => 'Terms of Use';

  @override
  String get clientAuthSharedLegalPrivacy => 'Privacy Policy';

  @override
  String get clientAuthSharedLegalNote => 'Full text before launch';

  @override
  String get clientAuthSharedTermsSection1 => 'Using Ghazal';

  @override
  String get clientAuthSharedTermsSection2 => 'The voucher';

  @override
  String get clientAuthSharedTermsSection3 => 'Paying the venue';

  @override
  String get clientAuthSharedTermsSection4 => 'Your responsibilities';

  @override
  String get clientAuthSharedPrivacySection1 => 'What we collect';

  @override
  String get clientAuthSharedPrivacySection2 => 'How we use it';

  @override
  String get clientAuthSharedPrivacySection3 => 'Who sees it';

  @override
  String get clientAuthSharedPrivacySection4 => 'Your choices';

  @override
  String get clientAuthSharedInfoTitle => 'Your account';

  @override
  String get clientAuthSharedPartnerNote =>
      'Hotel or service provider? Use the Ghazal Partner app.';

  @override
  String get clientAuthSharedSmallPrint =>
      'Our <terms>Terms of Use</terms> and <privacy>Privacy Policy</privacy> apply. You confirm them when you create an account.';

  @override
  String get clientAuthReasonSendRequest => 'Send request';

  @override
  String get clientAuthReasonVoucher => 'Voucher';

  @override
  String get clientAuthReasonVisit => 'Visit';

  @override
  String get clientAuthReasonChat => 'Message';

  @override
  String get clientAuthReasonReview => 'Review';

  @override
  String get clientAuthReasonPlanner => 'Consultation';

  @override
  String get clientAuthReasonQuote => 'Quote';

  @override
  String get clientAuthReasonSave => 'Shortlist';

  @override
  String clientAuthGateErrorDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString digits',
      one: '$countString digit',
    );
    return 'Needs $_temp0';
  }

  @override
  String get clientAuthGateErrorNotOnWhatsapp => 'Not on WhatsApp';

  @override
  String get clientAuthGateNotOnWhatsappDetail =>
      'We could not send a code to this number on WhatsApp. Continue with Apple or Google, or contact Support.';

  @override
  String get clientAuthOtpTitle => 'WhatsApp code';

  @override
  String get clientAuthOtpSheetTitle => 'Verify number';

  @override
  String get clientAuthOtpLabel => 'Code';

  @override
  String get clientAuthOtpVerify => 'Verify';

  @override
  String get clientAuthOtpWrong => 'Wrong code';

  @override
  String clientAuthOtpAttemptsLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString attempts remaining',
      one: '$countString attempt remaining',
    );
    return '$_temp0';
  }

  @override
  String get clientAuthOtpExpired => 'Code expired';

  @override
  String get clientAuthOtpResent => 'Code sent';

  @override
  String clientAuthOtpResendIn(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Resend code in $countString seconds',
      one: 'Resend code in $countString second',
    );
    return '$_temp0';
  }

  @override
  String clientAuthOtpTimer(String count) {
    return '${count}s';
  }

  @override
  String get clientAuthOtpResend => 'Resend';

  @override
  String get clientAuthOtpChange => 'Change';

  @override
  String get clientAuthOtpChangeNumber => 'Change number';

  @override
  String get clientAuthOtpLocked => 'Too many attempts';

  @override
  String get clientAuthOtpLockedDetail =>
      'Please try again later or contact Support.';

  @override
  String get clientAuthOtpDeliveryFailed => 'Not delivered';

  @override
  String get clientAuthOtpDeliveryFailedDetail =>
      'The code did not reach WhatsApp. Send it again, or continue another way.';

  @override
  String get clientAuthOtpSendAgain => 'Send again';

  @override
  String get clientAuthOtpSuccessTitle => 'Verified';

  @override
  String get clientAuthOtpOpening => 'Opening WhatsApp';

  @override
  String get clientAuthNameTitle => 'Create account';

  @override
  String get clientAuthNameLabel => 'Name';

  @override
  String get clientAuthNamePlaceholder => 'Full name';

  @override
  String get clientAuthNameEmailLabel => 'Email';

  @override
  String get clientAuthNameAccept => 'I agree';

  @override
  String get clientAuthNameLegalTitle => 'Terms and privacy';

  @override
  String get clientAuthNameKept => 'Saved to your account';

  @override
  String get clientAuthNameMonogram => 'Your monogram';

  @override
  String get clientAuthPwdForgotTitle => 'Reset password';

  @override
  String get clientAuthPwdResetTitle => 'New password';

  @override
  String get clientAuthPwdPassword => 'Password';

  @override
  String get clientAuthPwdShow => 'Show password';

  @override
  String get clientAuthPwdHide => 'Hide password';

  @override
  String get clientAuthPwdForgot => 'Forgot?';

  @override
  String get clientAuthPwdForgotLabel => 'Forgot password';

  @override
  String get clientAuthPwdEnterCode => 'Enter code';

  @override
  String get clientAuthPwdVerified => 'Number verified on WhatsApp';

  @override
  String clientAuthPwdStrength(String level) {
    return 'Password strength: $level';
  }

  @override
  String get clientAuthPwdStrengthWeak => 'Weak';

  @override
  String get clientAuthPwdStrengthFair => 'Fair';

  @override
  String get clientAuthPwdStrengthStrong => 'Strong';

  @override
  String clientAuthPwdRuleLength(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString characters',
      one: '$countString character',
    );
    return 'At least $_temp0';
  }

  @override
  String get clientAuthPwdRuleMix => 'A letter and a number';

  @override
  String get clientAuthPwdRulePhone => 'Not your number';

  @override
  String get clientAuthPwdRuleMet => 'Done';

  @override
  String get clientAuthPwdRuleOpen => 'Not yet';

  @override
  String get clientAuthPwdInvalid => 'Details don’t match';

  @override
  String get clientAuthPwdLocked => 'Paused';

  @override
  String get clientAuthPwdUpdatedTitle => 'Password updated';

  @override
  String get clientAuthBioTitle => 'Biometric unlock';

  @override
  String clientAuthBioMethod(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'Face ID',
      'touch': 'Touch ID',
      'other': 'Fingerprint',
    });
    return '$_temp0';
  }

  @override
  String clientAuthBioPromptDetail(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'Face ID',
      'touch': 'Touch ID',
      'other': 'Your fingerprint',
    });
    return '$_temp0 only unlocks the sign-in kept on this phone. It never replaces your first sign-in.';
  }

  @override
  String get clientAuthBioTurnOn => 'Turn on';

  @override
  String get clientAuthBioUnlock => 'Unlock';

  @override
  String get clientAuthBioFailedTitle => 'Not matched';

  @override
  String get clientAuthBioFailedDetail =>
      'You can try again or sign in another way. Your account is not locked.';

  @override
  String get clientAuthBioUnavailableRow => 'Biometric unlock';

  @override
  String get clientAuthBioUnavailableDetail =>
      'Add Face ID or a fingerprint in your phone’s settings to turn this on. Biometrics only unlock the sign-in kept on this phone.';

  @override
  String get clientAuthBioEnabledTitle => 'Turned on';

  @override
  String clientBookingStepOf(String step, String total) {
    return 'Step $step of $total';
  }

  @override
  String get clientBookingStepsLabel => 'Request progress';

  @override
  String get clientBookingLeaveTitle => 'Leave request?';

  @override
  String get clientBookingLeaveBody => 'Draft saved.';

  @override
  String get clientBookingLeaveConfirm => 'Leave';

  @override
  String get clientBookingLeaveKeep => 'Keep editing';

  @override
  String get clientBookingEstimateLabel => 'Est.';

  @override
  String get clientBookingOfflineBanner => 'Offline. Draft saved.';

  @override
  String get clientBookingPriceErrorBanner => 'Price not updated';

  @override
  String get clientBookingPriceTitle => 'Price';

  @override
  String get clientBookingVoucherTotalLabel => 'Voucher price';

  @override
  String get clientBookingVoucherEstimateLabel => 'Voucher price (est.)';

  @override
  String clientBookingYouSaveNet(String amount) {
    return 'You save $amount after the voucher fee';
  }

  @override
  String get clientBookingReplyWithin => 'The venue replies within';

  @override
  String get clientBookingReplyFast => 'The venue is asked to reply within';

  @override
  String get clientBookingEventTitle => 'Your event';

  @override
  String get clientBookingDateChange => 'Change the date';

  @override
  String get clientBookingDateTakenAction => 'Free dates';

  @override
  String clientBookingDateTakenBanner(String date) {
    return '$date unavailable';
  }

  @override
  String get clientBookingDateTakenReason => 'Pick another date';

  @override
  String get clientBookingHostingLabel => 'Reception';

  @override
  String get clientBookingHostingWomen => 'Ladies’ reception';

  @override
  String get clientBookingHostingMen => 'Men’s reception';

  @override
  String get clientBookingHostingMixed => 'Mixed celebration';

  @override
  String get clientBookingHostingWomenShort => 'Ladies’';

  @override
  String get clientBookingHostingMenShort => 'Men’s';

  @override
  String get clientBookingHostingMixedShort => 'Mixed';

  @override
  String get clientBookingHallLabel => 'Hall';

  @override
  String get clientBookingSessionLabel => 'Session';

  @override
  String get clientBookingGuestsLabel => 'Guests';

  @override
  String get clientBookingGuestsPresets => 'Common guest counts';

  @override
  String get clientBookingOccasionLabel => 'Occasion';

  @override
  String get clientBookingOccasionWedding => 'Wedding';

  @override
  String get clientBookingOccasionMilka => 'Milka';

  @override
  String get clientBookingOccasionHenna => 'Henna';

  @override
  String get clientBookingOccasionEngagement => 'Engagement';

  @override
  String get clientBookingOccasionOther => 'Other';

  @override
  String get clientBookingNeedVoucherTitle => 'Voucher first';

  @override
  String get clientBookingNeedVoucherInfoTitle => 'Voucher';

  @override
  String get clientBookingNeedVoucherBody =>
      'A request needs a voucher. It gives you the voucher price and goes to the venue with your request.';

  @override
  String get clientBookingHostingOneVoucher =>
      'One voucher covers one reception. A second reception is its own request with its own voucher.';

  @override
  String clientBookingNeedVoucherAction(String fee) {
    return 'Get voucher $fee';
  }

  @override
  String get clientBookingFromVoucher => 'From your voucher';

  @override
  String get clientBookingFromVoucherChange => 'Change';

  @override
  String get clientBookingFromVoucherChangeAria =>
      'Change what the voucher is bound to';

  @override
  String get clientBookingPackageTitle => 'Package';

  @override
  String get clientBookingPackageSelected => 'Selected';

  @override
  String get clientBookingPackageIncludes => 'Includes';

  @override
  String get clientBookingPackageDetails => 'Details';

  @override
  String get clientBookingPackageFlat => 'Package price';

  @override
  String get clientBookingPackageNoVoucher => 'No voucher';

  @override
  String get clientBookingPackageChangeVoucher =>
      'Opens the voucher for this quote';

  @override
  String get clientBookingPackageNotCoveredToast => 'Not covered by voucher';

  @override
  String get clientBookingPackageNoneTitle => 'No package fits';

  @override
  String clientBookingPackageNoneBody(String guests) {
    return 'No package fits $guests in this hall. Change the guests or choose another hall.';
  }

  @override
  String get clientBookingPackageNoneInfoTitle => 'Packages';

  @override
  String get clientBookingPackageNoneAction => 'Change guests';

  @override
  String get clientBookingPackageMissingReason => 'Choose a package';

  @override
  String get clientBookingPackageBreakdownOpen => 'See the price breakdown';

  @override
  String get clientBookingExtrasTitle => 'Extras';

  @override
  String get clientBookingExtrasInfoTitle => 'Extras';

  @override
  String get clientBookingExtrasIncluded => 'Included';

  @override
  String get clientBookingExtrasNone => 'No extras';

  @override
  String get clientBookingExtrasNoneOffered =>
      'This venue does not sell extras for your booking. You can continue.';

  @override
  String get clientBookingExtrasLead =>
      'Optional and priced separately, at your voucher price where the venue has one.';

  @override
  String get clientBookingExtrasSettledNote =>
      'Extras are settled directly with the venue.';

  @override
  String get clientBookingDetailsTitle => 'Details';

  @override
  String get clientBookingNameLabel => 'Name';

  @override
  String get clientBookingNameError => 'Add a name';

  @override
  String get clientBookingPhoneLabel => 'Phone';

  @override
  String get clientBookingPhoneVerified => 'Verified';

  @override
  String get clientBookingPhoneVerify => 'Verify';

  @override
  String clientBookingPhoneDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString digits',
      one: '$countString digit',
    );
    return 'Needs $_temp0';
  }

  @override
  String get clientBookingEmailLabel => 'Email';

  @override
  String get clientBookingForLabel => 'Booking for';

  @override
  String get clientBookingForSelf => 'Myself';

  @override
  String get clientBookingForOther => 'Someone else';

  @override
  String get clientBookingForNameLabel => 'Their name';

  @override
  String get clientBookingForRelationLabel => 'Relation';

  @override
  String get clientBookingRelationBride => 'Bride';

  @override
  String get clientBookingRelationGroom => 'Groom';

  @override
  String get clientBookingRelationFamily => 'Family';

  @override
  String get clientBookingRelationPlanner => 'Planner';

  @override
  String get clientBookingRequestsLabel => 'Requests';

  @override
  String get clientBookingRequestsSuggestions => 'Common requests';

  @override
  String get clientBookingSuggestPhotographer => 'Female photographer only';

  @override
  String clientBookingSuggestKosha(String time) {
    return 'Kosha team access from $time';
  }

  @override
  String get clientBookingSuggestWheelchair => 'Wheelchair access';

  @override
  String get clientBookingSuggestPhotographerShort => 'Photographer';

  @override
  String get clientBookingSuggestKoshaShort => 'Kosha';

  @override
  String get clientBookingSuggestWheelchairShort => 'Wheelchair';

  @override
  String get clientBookingPrivacyWord => 'Privacy';

  @override
  String clientBookingPrivacy(String venue) {
    return '$venue sees your name and phone for this request only. It sees your voucher code only when you redeem it.';
  }

  @override
  String get clientBookingReviewTitle => 'Review';

  @override
  String get clientBookingReviewExtras => 'Extras';

  @override
  String get clientBookingReviewContact => 'Contact';

  @override
  String get clientBookingReviewPackage => 'Package';

  @override
  String get clientBookingReviewPriceNote =>
      'All-in, and frozen when you send. Nothing more to pay Ghazal: after you confirm, you pay the venue directly.';

  @override
  String get clientBookingNextTitle => 'What happens next';

  @override
  String get clientBookingNextSend => 'Send';

  @override
  String get clientBookingNextReply => 'Reply';

  @override
  String get clientBookingNextConfirm => 'Confirm';

  @override
  String get clientBookingNextVenue => 'Redeem';

  @override
  String get clientBookingNextReplyNote => 'Expected reply by';

  @override
  String get clientBookingNextConfirmNote => 'Time to confirm after approval';

  @override
  String clientBookingNextVenueNote(String venue) {
    return 'You pay $venue directly and show your voucher code.';
  }

  @override
  String get clientBookingConsent => 'I agree';

  @override
  String get clientBookingConsentTitle => 'Terms';

  @override
  String get clientBookingConsentBody =>
      'I agree to the venue terms, the voucher terms and the platform terms.';

  @override
  String get clientBookingConsentRead => 'Read the terms';

  @override
  String get clientBookingSend => 'Send request';

  @override
  String get clientBookingSendFailed => 'Not sent. Try again.';

  @override
  String get clientBookingReasonConsent => 'Agree to send';

  @override
  String get clientBookingReasonLimit => 'Requests full';

  @override
  String get clientBookingReasonVoucher => 'Voucher needed';

  @override
  String get clientBookingReasonPhone => 'Verify phone';

  @override
  String clientBookingLimitBanner(String count, String max) {
    return '$count of $max open';
  }

  @override
  String get clientBookingLimitAction => 'View';

  @override
  String get clientBookingLimitInfoTitle => 'Open requests';

  @override
  String get clientBookingLimitInfo =>
      'Withdraw an open request to send another.';

  @override
  String get clientBookingPhoneBanner => 'Phone not verified';

  @override
  String get clientBookingVoucherUneconomic => 'Saving too low';

  @override
  String get clientBookingVoucherUneconomicInfo =>
      'For this quote the saving is no longer more than the voucher price, so the voucher cannot be used for it.';

  @override
  String get clientBookingVoucherCardTitle => 'Voucher';

  @override
  String get clientBookingVoucherChange => 'Change voucher';

  @override
  String get clientBookingVoucherValid => 'Valid until';

  @override
  String get clientBookingQuoteChanged =>
      'Your total changed since you got the voucher, because of the extras you added. The voucher still applies.';

  @override
  String get clientBookingQuoteChangedShort => 'Total changed';

  @override
  String get clientBookingSentTitle => 'Request sent';

  @override
  String get clientBookingSentInfoTitle => 'Your request';

  @override
  String clientBookingSentBody(String venue, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hours',
      one: '$countString hour',
    );
    return 'The date is not held yet. If $venue approves, we hold it for you for $_temp0 so you can confirm. Your voucher is attached to the request.';
  }

  @override
  String get clientBookingSentWithdraw =>
      'You can withdraw this request. Your voucher comes back and can be used again here.';

  @override
  String get clientBookingSentDate => 'Date';

  @override
  String get clientBookingSentHall => 'Hall';

  @override
  String get clientBookingSentGuests => 'Guests';

  @override
  String get clientBookingSentReference => 'Reference';

  @override
  String get clientBookingSentVoucherPrice => 'Voucher price';

  @override
  String get clientBookingSentHeld => 'Date held';

  @override
  String get clientBookingSentHeldLong => 'Date held by another couple';

  @override
  String get clientBookingSentView => 'View request';

  @override
  String get clientBookingSentDiscover => 'Discover';

  @override
  String get clientBookingSentWedding => 'My Wedding';

  @override
  String get clientBookingSentNotifTitle => 'Booking updates';

  @override
  String get clientBookingSentNotifYes => 'Turn on';

  @override
  String get clientBookingSentNotifNo => 'Not now';

  @override
  String get clientBookingSentNotifToast => 'Updates on';

  @override
  String get clientBookingSentOffline => 'Offline. Summary saved.';

  @override
  String get clientBookingPlannerTitle => 'Wedding planner';

  @override
  String get clientBookingPlannerNo => 'Not now';

  @override
  String get clientBookingTakenTitle => 'Date unavailable';

  @override
  String get clientBookingTakenSessionTitle => 'Session unavailable';

  @override
  String get clientBookingTakenExpiredTitle => 'Window ended';

  @override
  String get clientBookingTakenLoading => 'Looking for free dates';

  @override
  String get clientBookingTakenNearest => 'Nearest free dates';

  @override
  String clientBookingTakenSimilar(String date) {
    return 'Similar halls free on $date';
  }

  @override
  String get clientBookingTakenAnother => 'Other date';

  @override
  String get clientBookingTakenResults => 'Results';

  @override
  String get clientBookingTakenNone => 'No dates nearby';

  @override
  String clientBookingTakenNoneInfo(String date) {
    return 'No free dates near $date at this hall. Choose another date or see other halls.';
  }

  @override
  String get clientBookingTakenVoucherValid => 'Your voucher is still valid';

  @override
  String get clientBookingTakenRebindFailed => 'Voucher can’t move there';

  @override
  String clientBookingTakenRebound(String date) {
    return 'Voucher moved to $date';
  }

  @override
  String get clientBookingConfirmHeading => 'Confirm';

  @override
  String get clientBookingConfirmByLabel => 'Confirm by';

  @override
  String get clientBookingConfirmLapsedLabel => 'Lapsed on';

  @override
  String get clientBookingConfirmWindowLabel => 'Time to confirm';

  @override
  String clientBookingConfirmLeft(String time) {
    return '$time remaining to confirm';
  }

  @override
  String get clientBookingConfirmSummary => 'What the venue approved';

  @override
  String get clientBookingConfirmSaveNet => 'You save after the voucher fee';

  @override
  String get clientBookingConfirmPayTitle => 'Payment';

  @override
  String get clientBookingConfirmPay =>
      'Nothing is paid here. You pay the venue directly after you confirm.';

  @override
  String get clientBookingConfirmConsentBody =>
      'I agree to the venue terms and the voucher terms.';

  @override
  String get clientBookingConfirmNoteCancel =>
      'Confirming books the date at the voucher price. Cancelling after you confirm releases the date and the voucher is used.';

  @override
  String get clientBookingConfirmReasonConsent => 'Agree to confirm';

  @override
  String get clientBookingConfirmAction => 'Confirm booking';

  @override
  String get clientBookingConfirmSeeNext => 'See options';

  @override
  String get clientBookingConfirmCancel => 'Cancel request';

  @override
  String get clientBookingConfirmViewRequest => 'View request';

  @override
  String get clientBookingConfirmOffline => 'Offline. Reconnect to confirm.';

  @override
  String get clientBookingUpdatedTitle => 'Request updated';

  @override
  String get clientBookingUpdatedAction => 'Details';

  @override
  String get clientBookingDoneHeading => 'Booking confirmed';

  @override
  String get clientBookingDoneVoucherTitle => 'Voucher';

  @override
  String get clientBookingDonePayWord => 'Pay venue';

  @override
  String get clientBookingDonePayTitle => 'At the venue';

  @override
  String clientBookingDonePay(String venue) {
    return 'Pay $venue directly, then show this code at the venue.';
  }

  @override
  String get clientBookingDoneCopied => 'Code copied';

  @override
  String get clientBookingDoneChecklist =>
      'Venue marked done in your checklist';

  @override
  String get clientBookingDoneSetDate => 'Set wedding date';

  @override
  String get clientBookingDoneDateSet => 'Wedding date set';

  @override
  String get clientBookingDoneActions => 'Next steps';

  @override
  String get clientBookingDoneDirections => 'Directions';

  @override
  String get clientBookingDoneVisit => 'Book a visit';

  @override
  String get clientBookingDoneCall => 'Call the venue';

  @override
  String get clientBookingDoneCalling => 'Calling the venue';

  @override
  String get clientBookingDoneCalendar => 'Add to calendar';

  @override
  String get clientBookingDoneCalendarToast => 'Added to calendar';

  @override
  String get clientBookingDoneShared => 'Link copied';

  @override
  String get clientBookingDoneView => 'View booking';

  @override
  String get clientBookingMapsTitle => 'Directions';

  @override
  String get clientBookingMapsGoogle => 'Google Maps';

  @override
  String get clientBookingMapsApple => 'Apple Maps';

  @override
  String get clientBookingMapsWaze => 'Waze';

  @override
  String get clientBookingMapsToast => 'Opening directions';

  @override
  String get clientBookingEndedTitle => 'Window ended';

  @override
  String get clientBookingEndedRevokedTitle => 'Approval withdrawn';

  @override
  String get clientBookingEndedTakenTitle => 'Date unavailable';

  @override
  String clientBookingEndedLapsed(String duration, String date) {
    return 'The $duration to confirm have ended. $date was released and the voucher is no longer valid.';
  }

  @override
  String clientBookingEndedRevoked(String venue, String date) {
    return '$venue can no longer hold $date, so the approval was withdrawn.';
  }

  @override
  String clientBookingEndedTaken(String date, String venue) {
    return '$date is no longer available at $venue.';
  }

  @override
  String get clientBookingEndedVoucherTitle => 'Your voucher';

  @override
  String get clientBookingEndedVoucherPlain =>
      'It is back with you and can be used for a new request here.';

  @override
  String get clientBookingEndedRefund => 'Ask for credit';

  @override
  String get clientBookingEndedNew => 'New request';

  @override
  String get clientBookingEndedFreeDates => 'Free dates';

  @override
  String get clientBookingEndedViewVenue => 'Venue';

  @override
  String get clientBookingEndedOffline => 'Offline. Reconnect to continue.';

  @override
  String get clientBookingEndedReleased => 'Hold released';

  @override
  String get clientBookingEndedWindow => 'Confirmation window';

  @override
  String get clientBookingEndedUntil => 'Can be used until';

  @override
  String get clientBookingEndedVoucherForfeited =>
      'Not valid. A voucher not confirmed at the venue within the window does not come back.';

  @override
  String clientBookingEndedVoucherCredit(String venue, String date) {
    return 'It is back with you. Use it again at $venue until $date, or ask support for a credit voucher.';
  }

  @override
  String get clientBookingsTitle => 'Bookings';

  @override
  String get clientBookingsFindHall => 'Find halls';

  @override
  String get clientBookingsSectionNeeds => 'Needs you';

  @override
  String get clientBookingsSectionPending => 'Pending';

  @override
  String get clientBookingsSectionConfirmed => 'Confirmed';

  @override
  String get clientBookingsSectionPast => 'Past';

  @override
  String get clientBookingsPastFilter => 'Filter past requests';

  @override
  String get clientBookingsPastNone => 'No requests with this status';

  @override
  String get clientBookingsLimitLabel => 'Open requests';

  @override
  String get clientBookingsLimitReached => 'Close one to send another';

  @override
  String get clientBookingsGuestTitle => 'Track your requests';

  @override
  String get clientBookingsGuestAction => 'Sign in';

  @override
  String get clientBookingsEmptyTitle => 'No requests yet';

  @override
  String get clientBookingsEmptyAction => 'Find halls';

  @override
  String clientBookingsEmptyActionDate(String date) {
    return 'Halls on $date';
  }

  @override
  String get clientBookingsVouchers => 'Vouchers';

  @override
  String get clientBookingsReceipts => 'Receipts';

  @override
  String get clientBookingsAudienceWomen => 'Ladies’ reception';

  @override
  String get clientBookingsAudienceMen => 'Men’s reception';

  @override
  String get clientBookingsAudienceMixed => 'Mixed reception';

  @override
  String get clientBookingsSessionDay => 'Day reception';

  @override
  String get clientBookingsSessionAfternoon => 'Afternoon reception';

  @override
  String get clientBookingsSessionEvening => 'Evening reception';

  @override
  String get clientBookingsRowReplyBy => 'Reply by';

  @override
  String get clientBookingsRowVoucherBack => 'Voucher is back';

  @override
  String get clientBookingsRowVoucherUsed => 'Voucher used';

  @override
  String get clientBookingsDetailTitle => 'Booking';

  @override
  String get clientBookingsThreadLabel => 'Booking progress';

  @override
  String get clientBookingsHeadFacts => 'Booking facts';

  @override
  String get clientBookingsFactDate => 'Date';

  @override
  String get clientBookingsFactHall => 'Hall';

  @override
  String get clientBookingsFactGuests => 'Guests';

  @override
  String get clientBookingsFactQuantity => 'Quantity';

  @override
  String get clientBookingsFactPackage => 'Package';

  @override
  String get clientBookingsFactNotes => 'Notes';

  @override
  String get clientBookingsPendingTitle => 'Request sent';

  @override
  String get clientBookingsPendingBody =>
      'Your voucher is attached. Nothing is held yet.';

  @override
  String get clientBookingsPendingHeldTitle => 'Date held';

  @override
  String get clientBookingsPendingHeld =>
      'Another couple’s approved request is holding this date for now. If it lapses, yours can be approved. Your voucher stays attached.';

  @override
  String get clientBookingsPendingWithdraw => 'Withdraw';

  @override
  String get clientBookingsApprovedCancel => 'Cancel request';

  @override
  String get clientBookingsCancelBooking => 'Cancel booking';

  @override
  String get clientBookingsConfirmWindow => 'Confirm window';

  @override
  String get clientBookingsConfirmLeft => 'Time remaining';

  @override
  String get clientBookingsConfirmInfoTitle => 'Confirm window';

  @override
  String get clientBookingsConfirmInfo =>
      'The date is held for you until then. You pay nothing more to Ghazal.';

  @override
  String get clientBookingsStepPay => 'Pay venue';

  @override
  String get clientBookingsStepShow => 'Show code';

  @override
  String get clientBookingsConfirmedInfoTitle => 'Next step';

  @override
  String clientBookingsConfirmedPay(String venue) {
    return 'Pay $venue directly, then show this code.';
  }

  @override
  String get clientBookingsAddToCalendar => 'Calendar';

  @override
  String get clientBookingsCalendarAdded => 'Added to calendar';

  @override
  String get clientBookingsBookVisit => 'Visit';

  @override
  String get clientBookingsRedeemedOn => 'Redeemed on';

  @override
  String get clientBookingsRedeemedPrice => 'Venue price applied';

  @override
  String get clientBookingsProposedWas => 'Original date';

  @override
  String get clientBookingsProposedReply => 'Reply by';

  @override
  String get clientBookingsDeclinedDate => 'Date unavailable';

  @override
  String get clientBookingsDeclinedCapacity => 'Capacity doesn’t fit';

  @override
  String get clientBookingsDeclinedPackage => 'Package unavailable';

  @override
  String get clientBookingsDeclinedOther => 'Not accepted';

  @override
  String get clientBookingsExpiredTitle => 'No reply';

  @override
  String get clientBookingsExpiredConfirmTitle => 'Confirm time ended';

  @override
  String clientBookingsExpiredConfirm(String date) {
    return 'The confirmation time ran out, so the hold on $date was released.';
  }

  @override
  String get clientBookingsExpiredDeadline => 'Deadline';

  @override
  String get clientBookingsCancelledOn => 'Cancelled on';

  @override
  String get clientBookingsCancelledByYou => 'By you';

  @override
  String get clientBookingsCancelledByVenue => 'By the venue';

  @override
  String get clientBookingsIssueOpen => 'Report issue';

  @override
  String get clientBookingsIssueUntil => 'Report until';

  @override
  String get clientBookingsIssueReportedTitle => 'Report sent';

  @override
  String get clientBookingsIssueReportedBody =>
      'Ghazal support has your report and will follow up in your messages.';

  @override
  String get clientBookingsIssueTitle => 'Report issue';

  @override
  String get clientBookingsIssueFacts => 'Report details';

  @override
  String get clientBookingsIssueReasonPrice => 'Price not honoured';

  @override
  String get clientBookingsIssueReasonNotRedeemed => 'Not redeemed';

  @override
  String get clientBookingsIssueReasonOther => 'Other';

  @override
  String get clientBookingsIssueNote => 'Note';

  @override
  String get clientBookingsIssueSend => 'Send report';

  @override
  String get clientBookingsIssueSent => 'Report sent';

  @override
  String get clientBookingsShowVoucher => 'Show voucher';

  @override
  String get clientBookingsChooseDate => 'Choose date';

  @override
  String get clientBookingsSendSimilar => 'Similar halls';

  @override
  String get clientBookingsSendNew => 'New request';

  @override
  String get clientBookingsWriteReview => 'Write review';

  @override
  String get clientBookingsSectionAlternatives => 'Free halls';

  @override
  String get clientBookingsSectionEvent => 'Event';

  @override
  String get clientBookingsSectionPrice => 'Price';

  @override
  String get clientBookingsSectionContact => 'Contact';

  @override
  String get clientBookingsTerms => 'Terms';

  @override
  String get clientBookingsMessage => 'Message';

  @override
  String get clientBookingsUsuallyReplies => 'Usually replies in';

  @override
  String get clientBookingsCallDisplayOnly => 'Opening phone';

  @override
  String get clientBookingsPriceStandard => 'Standard price';

  @override
  String get clientBookingsPriceSaving => 'You save';

  @override
  String get clientBookingsPricePerGuest => 'Per guest';

  @override
  String get clientBookingsPriceBasis => 'Price basis';

  @override
  String get clientBookingsPriceGhazal => 'Ghazal voucher';

  @override
  String get clientBookingsPricePaid => 'Paid';

  @override
  String get clientBookingsPriceVenue => 'Venue, paid directly';

  @override
  String get clientBookingsPriceSettled => 'Settled';

  @override
  String get clientBookingsPriceOffApp => 'Off-app';

  @override
  String get clientBookingsPriceInfoTitle => 'Price terms';

  @override
  String get clientBookingsPriceInfoInclusive =>
      'The venue sets this price, all-in. Ghazal adds nothing to it.';

  @override
  String get clientBookingsPriceInfoGhazal => 'Nothing more to pay Ghazal.';

  @override
  String get clientBookingsOutcomeBackTitle => 'Voucher is back';

  @override
  String clientBookingsOutcomeBackReusable(String venue, String date) {
    return 'Use it again at $venue until $date.';
  }

  @override
  String clientBookingsOutcomeBackCredit(String venue, String date) {
    return 'Use it again at $venue until $date, or ask support for a credit voucher.';
  }

  @override
  String get clientBookingsOutcomeBackPlain =>
      'Your voucher is ready for another request.';

  @override
  String get clientBookingsOutcomeUsedTitle => 'Voucher used';

  @override
  String get clientBookingsOutcomeUsedBody =>
      'Cancelling a confirmed booking uses up the voucher. No money is returned.';

  @override
  String get clientBookingsOutcomeCreditTitle => 'Credit voucher issued';

  @override
  String get clientBookingsOutcomeCreditBody =>
      'A credit voucher is in your account. Claim it at any hall, hotel or service.';

  @override
  String get clientBookingsOutcomeExpiredTitle => 'Voucher expired';

  @override
  String get clientBookingsOutcomeExpiredBody =>
      'The voucher passed its validity date and can no longer be used.';

  @override
  String get clientBookingsOutcomeAction => 'Use again';

  @override
  String get clientBookingsOutcomeUntil => 'Use again until';

  @override
  String get clientBookingsOutcomeAskSupport => 'Ask support';

  @override
  String get clientBookingsOutcomeInfoTitle => 'Voucher terms';

  @override
  String clientBookingsTicketQr(String code) {
    return 'QR code of voucher $code';
  }

  @override
  String get clientBookingsTicketShowFull => 'Enlarge';

  @override
  String get clientBookingsTicketUsedOn => 'Used on';

  @override
  String get clientBookingsTicketValidUntil => 'Valid until';

  @override
  String get clientBookingsCancelTitleWithdraw => 'Withdraw request';

  @override
  String get clientBookingsCancelTitleApproved => 'Cancel request';

  @override
  String get clientBookingsCancelTitleConfirmed => 'Cancel booking';

  @override
  String get clientBookingsCancelDateLabel => 'Date';

  @override
  String get clientBookingsCancelDateReleased => 'Date released';

  @override
  String get clientBookingsCancelVoucherLabel => 'Voucher';

  @override
  String get clientBookingsCancelVoucherBack => 'Voucher returns';

  @override
  String get clientBookingsCancelVoucherUsed => 'Voucher used';

  @override
  String clientBookingsCancelVoucherBackBody(String venue, String date) {
    return 'Your voucher returns to you and can be used again at $venue until $date.';
  }

  @override
  String get clientBookingsCancelVoucherUsedBody =>
      'Cancelling a confirmed booking uses up your voucher. No money is returned.';

  @override
  String clientBookingsCancelDateWithdraw(String venue) {
    return '$venue is told straight away. Nothing was held for you yet.';
  }

  @override
  String clientBookingsCancelDateApproved(String date) {
    return 'The hold on $date is released.';
  }

  @override
  String clientBookingsCancelDateConfirmed(String date, String venue) {
    return 'The booking on $date at $venue is released.';
  }

  @override
  String clientBookingsCancelVenueMoney(String venue) {
    return 'Anything you paid $venue directly is settled between you and the venue.';
  }

  @override
  String get clientBookingsCancelInfoTitle => 'Cancellation';

  @override
  String get clientBookingsCancelAltAction => 'Message venue';

  @override
  String get clientBookingsCancelKeep => 'Keep request';

  @override
  String get clientBookingsCancelKeepBooking => 'Keep booking';

  @override
  String get clientBookingsCancelReasonTitle => 'Why?';

  @override
  String get clientBookingsCancelReasonPlans => 'Plans changed';

  @override
  String get clientBookingsCancelReasonVenue => 'Other venue';

  @override
  String get clientBookingsCancelReasonDate => 'Date changed';

  @override
  String get clientBookingsCancelReasonBudget => 'Budget';

  @override
  String get clientBookingsCancelReasonOther => 'Other';

  @override
  String get clientBookingsCancelNote => 'Note';

  @override
  String get clientBookingsCancelActionWithdraw => 'Withdraw request';

  @override
  String get clientBookingsCancelActionApproved => 'Cancel request';

  @override
  String get clientBookingsCancelActionConfirmed => 'Cancel booking';

  @override
  String get clientBookingsCancelErrorTitle => 'Couldn’t cancel';

  @override
  String get clientBookingsCancelErrorBody => 'Nothing was changed.';

  @override
  String get clientBookingsCancelDoneWithdrawn => 'Request withdrawn';

  @override
  String get clientBookingsCancelDoneApproved => 'Request cancelled';

  @override
  String get clientBookingsCancelDoneConfirmed => 'Booking cancelled';

  @override
  String get clientBookingsProposalCounterTitle => 'New dates';

  @override
  String clientBookingsProposalCounterBody(String venue, String date) {
    return '$venue cannot host you on $date. Choose one of these dates. The voucher price stays the same.';
  }

  @override
  String get clientBookingsProposalInfoTitle => 'Offer details';

  @override
  String get clientBookingsProposalFacts => 'Details';

  @override
  String get clientBookingsProposalDatesLabel => 'Dates offered';

  @override
  String clientBookingsProposalOptionLabel(String date, String price) {
    return '$date, voucher price $price';
  }

  @override
  String get clientBookingsProposalTaken => 'Taken';

  @override
  String clientBookingsProposalTakenBanner(String date) {
    return '$date was taken in the meantime. Choose another date or message the venue.';
  }

  @override
  String get clientBookingsProposalHeld =>
      'The voucher price is held on every date.';

  @override
  String get clientBookingsNoPenalty =>
      'No penalty if you decline. Your voucher stays yours.';

  @override
  String get clientBookingsProposalReplyBy => 'Reply by';

  @override
  String get clientBookingsProposalConfirmBy => 'Confirm by';

  @override
  String get clientBookingsProposalAccept => 'Accept date';

  @override
  String get clientBookingsProposalDeclineTitle => 'Decline these dates?';

  @override
  String get clientBookingsProposalDeclineAction => 'Decline dates';

  @override
  String get clientBookingsProposalDeclineKeep => 'Keep choosing';

  @override
  String get clientBookingsProposalAcceptedTitle => 'Date accepted';

  @override
  String get clientBookingsProposalClosedTitle => 'Request closed';

  @override
  String get clientBookingsProposalExpiredTitle => 'Offer lapsed';

  @override
  String get clientBookingsLater => 'Later';

  @override
  String get clientBookingsReceiptsTitle => 'Receipts';

  @override
  String get clientBookingsReceiptsInfoTitle => 'Event payments';

  @override
  String get clientBookingsReceiptsNote =>
      'Event payments are between you and the venue and do not appear here.';

  @override
  String get clientBookingsReceiptsEmptyTitle => 'No receipts';

  @override
  String get clientBookingsReceiptsReceipt => 'Receipt';

  @override
  String get clientBookingsReceiptsCredit => 'Credit voucher';

  @override
  String get clientBookingsReceiptsSaved => 'Saved to phone';

  @override
  String get clientBookingsMethodKnet => 'KNET';

  @override
  String get clientBookingsMethodApplePay => 'Apple Pay';

  @override
  String get clientBookingsMethodGooglePay => 'Google Pay';

  @override
  String get clientBookingsMethodCard => 'Card';

  @override
  String get clientBookingsViewerPreview =>
      'Document preview in Arabic and English';

  @override
  String get clientBookingsViewerDownload => 'Download';

  @override
  String get clientBookingsViewerDownloaded => 'Downloaded';

  @override
  String get clientBookingsViewerSavedAt => 'Saved to phone';

  @override
  String get clientBookingsViewerShareToast => 'Pick an app';

  @override
  String get clientBookingsViewerOpen => 'Open';

  @override
  String get clientBookingsViewerOpenToast => 'Opening app';

  @override
  String get clientBookingsViewerOpenVoucher => 'Voucher';

  @override
  String get clientBookingsOutcomeForfeitedTitle => 'Voucher not valid';

  @override
  String clientBookingsOutcomeForfeitedBody(String venue, num hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    return 'It was not confirmed at $venue within $hoursString hours, so it is forfeited. No money is returned.';
  }

  @override
  String get clientDiscoverHeroHeadline => 'Your evening hall';

  @override
  String clientDiscoverBellUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $countString unread',
      one: 'Notifications, $countString unread',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverSwitchLabel => 'Browse';

  @override
  String get clientDiscoverVariantsTitle => 'Status cards';

  @override
  String get clientDiscoverCategoryLuxuryHotels => 'Hotels';

  @override
  String get clientDiscoverCategoryWeddingHalls => 'Halls';

  @override
  String get clientDiscoverCategoryGovernment => 'Government';

  @override
  String get clientDiscoverCategoryBeach => 'Beach';

  @override
  String get clientDiscoverCategoryOutdoor => 'Outdoor';

  @override
  String get clientDiscoverCategoryVip => 'VIP';

  @override
  String get clientDiscoverBrowseTitle => 'Categories';

  @override
  String clientDiscoverFreeTitle(String date) {
    return 'Free $date';
  }

  @override
  String get clientDiscoverShortlistTitle => 'Saved';

  @override
  String get clientDiscoverShortlistCompare => 'Compare';

  @override
  String get clientDiscoverFeaturedTitle => 'Featured';

  @override
  String get clientDiscoverRecommendedTitle => 'For you';

  @override
  String get clientDiscoverTrendingTitle => 'Trending';

  @override
  String get clientDiscoverNearbyTitle => 'Nearby';

  @override
  String get clientDiscoverEmptyTitle => 'Fully booked';

  @override
  String get clientDiscoverEmptyWiden => 'Change date';

  @override
  String get clientDiscoverLocateDialogTitle => 'Use location?';

  @override
  String get clientDiscoverLocateAllow => 'Allow';

  @override
  String get clientDiscoverLocateNotNow => 'Not now';

  @override
  String get clientDiscoverEmptyNearLabel => 'Nearest free dates';

  @override
  String get clientDiscoverEmptyDateSet => 'Date updated';

  @override
  String get clientDiscoverBrowseAll => 'All halls';

  @override
  String get clientDiscoverBriefLabel => 'Your brief';

  @override
  String get clientDiscoverBriefChooseDate => 'Date';

  @override
  String get clientDiscoverBriefChooseArea => 'Area';

  @override
  String get clientDiscoverBriefAddGuests => 'Guests';

  @override
  String get clientDiscoverBriefSetBudget => 'Budget';

  @override
  String clientDiscoverBriefAreaMore(String first, String more) {
    return '$first +$more';
  }

  @override
  String clientDiscoverCtaCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $countString halls',
      one: 'Show $countString hall',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverCtaShow => 'Show halls';

  @override
  String get clientDiscoverCtaNearest => 'Nearest dates';

  @override
  String get clientDiscoverResultsTitle => 'Halls';

  @override
  String get clientDiscoverResultsSearchPlaceholder => 'Hall or area';

  @override
  String get clientDiscoverResultsFilters => 'Filters';

  @override
  String get clientDiscoverResultsClearAll => 'Clear';

  @override
  String clientDiscoverResultsRemoveChip(String name) {
    return 'Remove $name';
  }

  @override
  String get clientDiscoverResultsMap => 'Map';

  @override
  String get clientDiscoverResultsList => 'List';

  @override
  String get clientDiscoverResultsBriefHint => 'Edit brief';

  @override
  String get clientDiscoverResultsSeeFreeDates => 'Free dates';

  @override
  String get clientDiscoverResultsGovernmentNote =>
      'Browse only. Book through the official channel. No voucher.';

  @override
  String get clientDiscoverResultsRefreshed => 'Halls updated';

  @override
  String clientDiscoverResultsNoneRelax(String filter) {
    return 'Remove $filter';
  }

  @override
  String get clientDiscoverResultsNoneDates => 'Nearest free dates';

  @override
  String get clientDiscoverResultsOfflineMap =>
      'Map needs a connection. List still works.';

  @override
  String get clientDiscoverSearchRecent => 'Recent';

  @override
  String get clientDiscoverSearchClearRecent => 'Clear';

  @override
  String get clientDiscoverSortTitle => 'Sort';

  @override
  String get clientDiscoverSortRecommended => 'Recommended';

  @override
  String get clientDiscoverSortRating => 'Rating';

  @override
  String get clientDiscoverSortNewest => 'Newest';

  @override
  String get clientDiscoverSortPrice => 'Lowest price';

  @override
  String get clientDiscoverSortPriceDesc => 'Highest price';

  @override
  String get clientDiscoverSortDistance => 'Nearest';

  @override
  String get clientDiscoverChipAreasAll => 'All areas';

  @override
  String clientDiscoverChipRating(String rating) {
    return '$rating+';
  }

  @override
  String get clientDiscoverArrangementWomen => 'Ladies';

  @override
  String get clientDiscoverArrangementMen => 'Men';

  @override
  String get clientDiscoverArrangementMixed => 'Mixed';

  @override
  String get clientDiscoverSettingIndoor => 'Indoor';

  @override
  String get clientDiscoverSettingOutdoor => 'Outdoor';

  @override
  String get clientDiscoverSettingMixed => 'Both';

  @override
  String get clientDiscoverFacilityParking => 'Parking';

  @override
  String get clientDiscoverFacilityValet => 'Valet';

  @override
  String get clientDiscoverFacilityBridal => 'Bridal';

  @override
  String get clientDiscoverFacilityBuffet => 'Buffet';

  @override
  String get clientDiscoverFacilityDecor => 'Decor';

  @override
  String get clientDiscoverFacilityPhotography => 'Photos';

  @override
  String get clientDiscoverLevelPrestige => 'Prestige';

  @override
  String get clientDiscoverLevelSignature => 'Signature';

  @override
  String get clientDiscoverLevelClassic => 'Classic';

  @override
  String get clientDiscoverLevelGovernment => 'Government';

  @override
  String get clientDiscoverFiltersTitle => 'Filters';

  @override
  String get clientDiscoverFiltersGroupArrangement => 'Reception';

  @override
  String get clientDiscoverFiltersGroupType => 'Venue type';

  @override
  String get clientDiscoverFiltersGroupPrice => 'Standard price';

  @override
  String get clientDiscoverFiltersGroupCapacity => 'Capacity';

  @override
  String get clientDiscoverFiltersGroupSetting => 'Setting';

  @override
  String get clientDiscoverFiltersGroupFacilities => 'Facilities';

  @override
  String get clientDiscoverFiltersGroupRating => 'Rating';

  @override
  String get clientDiscoverFiltersGroupLevel => 'Level';

  @override
  String get clientDiscoverFiltersGroupBrand => 'Hotel brand';

  @override
  String clientDiscoverFiltersCta(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $countString halls',
      one: 'Show $countString hall',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverFiltersCtaNone => 'No halls';

  @override
  String get clientDiscoverFiltersClear => 'Clear';

  @override
  String clientDiscoverFiltersExpand(String group) {
    return 'Show $group';
  }

  @override
  String clientDiscoverFiltersCollapse(String group) {
    return 'Hide $group';
  }

  @override
  String get clientDiscoverBriefTitle => 'Your brief';

  @override
  String get clientDiscoverBriefClear => 'Clear';

  @override
  String get clientDiscoverBriefBack => 'Back to your brief';

  @override
  String get clientDiscoverBriefDateTitle => 'Date';

  @override
  String get clientDiscoverBriefDateFlexible => 'Any month';

  @override
  String get clientDiscoverBriefAreaTitle => 'Area';

  @override
  String get clientDiscoverBriefGuestsTitle => 'Guests';

  @override
  String get clientDiscoverBriefGuestsPresets => 'Quick choices';

  @override
  String get clientDiscoverBriefGuestsSection => 'Searching for';

  @override
  String get clientDiscoverBriefBudgetTitle => 'Budget';

  @override
  String get clientDiscoverBriefBudgetHelper => 'Hall and catering only';

  @override
  String get clientDiscoverBriefBudgetBands => 'Budget bands';

  @override
  String clientDiscoverBriefBudgetUnder(String amount) {
    return 'Under $amount';
  }

  @override
  String get clientDiscoverBriefDone => 'Done';

  @override
  String get clientDiscoverMergeTitle => 'Two briefs';

  @override
  String get clientDiscoverMergePhone => 'This phone';

  @override
  String get clientDiscoverMergeAccount => 'My account';

  @override
  String get clientDiscoverMapTitle => 'Map';

  @override
  String get clientDiscoverMapPins => 'Halls on the map';

  @override
  String clientDiscoverMapCluster(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString halls here, tap to zoom in',
      one: '$countString hall here, tap to zoom in',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverMapZoomOut => 'Show all halls';

  @override
  String get clientDiscoverMapLocate => 'My location';

  @override
  String get clientDiscoverMapSearchArea => 'Search here';

  @override
  String clientDiscoverMapDenied(String area) {
    return 'Near $area';
  }

  @override
  String get clientDiscoverMapLocated => 'Near you';

  @override
  String get clientDiscoverMapNoneAction => 'All halls';

  @override
  String get clientDiscoverMapOfflineAction => 'List';

  @override
  String get clientDiscoverMapViewLabel => 'Show as';

  @override
  String get clientDiscoverRefreshed => 'Updated';

  @override
  String get clientDiscoverVoucherTitle => 'Voucher prices';

  @override
  String get clientDiscoverWeekTitle => 'This week';

  @override
  String get clientDiscoverCardGetVoucher => 'Get voucher';

  @override
  String get clientDiscoverCardView => 'View';

  @override
  String get clientDiscoverChipRegion => 'Region';

  @override
  String get clientDiscoverChipDate => 'Date';

  @override
  String get clientDiscoverChipVoucher => 'Voucher';

  @override
  String get clientDiscoverSortVoucher => 'Voucher price';

  @override
  String get clientDiscoverMapVoucherPin => 'Voucher price';

  @override
  String get clientDiscoverFiltersGroupRegion => 'Region';

  @override
  String get clientDiscoverFiltersGroupStructure => 'Pricing';

  @override
  String get clientDiscoverFiltersGroupDate => 'Date';

  @override
  String get clientDiscoverFiltersGroupVoucher => 'Voucher price';

  @override
  String get clientDiscoverFiltersDateOpen => 'Calendar';

  @override
  String get clientDiscoverFiltersVoucherTitle => 'Voucher only';

  @override
  String get clientDiscoverBriefAreaAll => 'All';

  @override
  String get clientDiscoverBriefAreaClearGroup => 'Clear';

  @override
  String get clientDiscoverRegionPlaceholder => 'Area or hall';

  @override
  String get clientDiscoverRegionNear => 'Near me';

  @override
  String get clientDiscoverRegionListLabel => 'Governorates and areas';

  @override
  String get clientDiscoverDatesTitle => 'Dates';

  @override
  String get clientDiscoverDatesFlexible => 'Any month';

  @override
  String clientDiscoverDatesHint(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days',
      one: '$daysString day',
    );
    return 'Up to $_temp0';
  }

  @override
  String get clientDiscoverDatesLegend => 'Halls free on each day';

  @override
  String get clientDiscoverDatesMany => 'Many';

  @override
  String get clientDiscoverDatesFew => 'Few';

  @override
  String get clientDiscoverDatesNoneLegend => 'None';

  @override
  String get clientDiscoverDatesNone => 'No halls';

  @override
  String get clientDiscoverDatesApply => 'Apply';

  @override
  String get clientDiscoverDatesClear => 'Clear';

  @override
  String get clientDiscoverStatusNoDate => 'Pick a date';

  @override
  String clientDiscoverStatusBrief(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString halls free',
      one: '$countString hall free',
      zero: 'No halls free',
    );
    return '$_temp0';
  }

  @override
  String get clientDiscoverA11yDate => 'Date';

  @override
  String get clientDiscoverA11yTime => 'Time';

  @override
  String get clientDiscoverA11yTimeLeft => 'Time remaining';

  @override
  String get clientDiscoverA11yUpdated => 'Updated';

  @override
  String get clientDiscoverA11yDrive => 'Drive time';

  @override
  String get clientDiscoverMergeKeep => 'Keep';

  @override
  String get clientDiscoverA11yDaysLeft => 'Days remaining';

  @override
  String clientDiscoverMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get clientDiscoverFiltersVoucherCount => 'Voucher venues';

  @override
  String clientDiscoverKm(num km) {
    final intl.NumberFormat kmNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String kmString = kmNumberFormat.format(km);

    return '$kmString km';
  }

  @override
  String get clientDiscoverA11yDistance => 'Distance';

  @override
  String clientDiscoverBriefBudgetOver(String amount) {
    return '$amount and above';
  }

  @override
  String get clientMessagesInboxTitle => 'Messages';

  @override
  String clientMessagesBellUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Notifications, $countString unread',
      one: 'Notifications, $countString unread',
      zero: 'Notifications',
    );
    return '$_temp0';
  }

  @override
  String get clientMessagesFilterGroup => 'Filter conversations';

  @override
  String get clientMessagesFilterVenues => 'Halls';

  @override
  String get clientMessagesFilterVisits => 'Visits';

  @override
  String get clientMessagesFilterPlanner => 'Planner';

  @override
  String get clientMessagesFilterProviders => 'Services';

  @override
  String get clientMessagesFilterSupport => 'Support';

  @override
  String get clientMessagesPinned => 'Pinned';

  @override
  String get clientMessagesYou => 'You';

  @override
  String get clientMessagesPreviewVoice => 'Voice message';

  @override
  String get clientMessagesPreviewPhoto => 'Photo';

  @override
  String get clientMessagesPreviewDocument => 'Document';

  @override
  String clientMessagesUnreadCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unread messages',
      one: '$countString unread message',
      zero: 'No unread messages',
    );
    return '$_temp0';
  }

  @override
  String clientMessagesOfflineStamp(String time) {
    return 'Offline · $time';
  }

  @override
  String clientMessagesDayMonth(String day, String month) {
    return '$day $month';
  }

  @override
  String get clientMessagesEmptyTitle => 'No messages yet';

  @override
  String get clientMessagesEmptyAction => 'Browse halls';

  @override
  String get clientMessagesEmptySupport => 'Support';

  @override
  String get clientMessagesGuestLabel => 'Sign in to see your messages';

  @override
  String get clientMessagesGuestAction => 'Sign in';

  @override
  String get clientMessagesVisitMembers => 'Chat members';

  @override
  String get clientMessagesInfoTitle => 'Details';

  @override
  String clientMessagesRepliesWithin(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Usually replies within $hoursString hours',
      one: 'Usually replies within an hour',
    );
    return '$_temp0';
  }

  @override
  String get clientMessagesContextView => 'View request';

  @override
  String get clientMessagesContextConfirm => 'Confirm';

  @override
  String get clientMessagesFactDate => 'Event date';

  @override
  String get clientMessagesFactGuests => 'Guests';

  @override
  String get clientMessagesFactTimeLeft => 'Time to confirm';

  @override
  String get clientMessagesFactDue => 'Due date';

  @override
  String get clientMessagesFactMeeting => 'Meeting';

  @override
  String get clientMessagesFactDaysLeft => 'Days to the wedding';

  @override
  String get clientMessagesAudienceWomen => 'Ladies’ reception';

  @override
  String get clientMessagesAudienceMen => 'Men’s reception';

  @override
  String get clientMessagesAudienceMixed => 'Mixed reception';

  @override
  String get clientMessagesComposerPlaceholder => 'Message';

  @override
  String get clientMessagesComposerLabel => 'Message';

  @override
  String get clientMessagesAttach => 'Attach';

  @override
  String get clientMessagesRecordHold => 'Hold to record a voice message';

  @override
  String get clientMessagesRecording => 'Recording a voice message';

  @override
  String get clientMessagesSlideCancel => 'Cancel';

  @override
  String get clientMessagesReleaseCancel => 'Release';

  @override
  String get clientMessagesRecordDelete => 'Delete recording';

  @override
  String get clientMessagesRecordSend => 'Send voice message';

  @override
  String get clientMessagesRecordTooShort => 'Hold to record';

  @override
  String get clientMessagesMsgSending => 'Sending';

  @override
  String get clientMessagesMsgFailed => 'Not sent';

  @override
  String get clientMessagesMsgQueued => 'Queued';

  @override
  String get clientMessagesUploading => 'Uploading';

  @override
  String get clientMessagesUploadCancel => 'Cancel upload';

  @override
  String get clientMessagesOfflineQueue => 'Offline';

  @override
  String get clientMessagesSuggestAvailability => 'Dates';

  @override
  String get clientMessagesSuggestVisit => 'Visit';

  @override
  String get clientMessagesSuggestVoucher => 'Voucher';

  @override
  String clientMessagesSuggestAvailabilityText(String date) {
    return 'Peace be upon you. Is $date available for a ladies’ reception?';
  }

  @override
  String get clientMessagesSuggestAvailabilityAny =>
      'Peace be upon you. Which dates do you have available for a ladies’ reception?';

  @override
  String clientMessagesSuggestVoucherText(String date) {
    return 'Peace be upon you. What is the voucher price for the ladies’ reception on $date?';
  }

  @override
  String get clientMessagesSuggestVoucherAny =>
      'Peace be upon you. Could you tell us the voucher price for the ladies’ reception?';

  @override
  String get clientMessagesSupportIntro => 'Hello, how can we help?';

  @override
  String get clientMessagesBlockedNote => 'Blocked';

  @override
  String get clientMessagesUnblock => 'Unblock';

  @override
  String get clientMessagesUnblockedToast => 'Unblocked';

  @override
  String get clientMessagesSysRequestSent => 'Request sent';

  @override
  String get clientMessagesSysApproved => 'Approved';

  @override
  String get clientMessagesSysConfirmed => 'Confirmed';

  @override
  String get clientMessagesSysRedeemed => 'Voucher redeemed';

  @override
  String get clientMessagesSysNotAccepted => 'Not accepted';

  @override
  String get clientMessagesSysExpired => 'No reply';

  @override
  String get clientMessagesSysLapsed => 'Time ran out';

  @override
  String get clientMessagesSysCancelled => 'Cancelled';

  @override
  String get clientMessagesSysInfoTitle => 'Voucher';

  @override
  String get clientMessagesSysInfoKept => 'Your voucher is still yours.';

  @override
  String clientMessagesSysInfoPay(String venue) {
    return 'Pay $venue directly and show your voucher code.';
  }

  @override
  String get clientMessagesOpenPhoto => 'Photos in this conversation';

  @override
  String get clientMessagesPhotoViewer => 'Photo viewer';

  @override
  String get clientMessagesStatusDelivered => 'Delivered';

  @override
  String get clientMessagesStatusRead => 'Read';

  @override
  String get clientMessagesCardCalendar => 'Calendar';

  @override
  String get clientMessagesCardCalendarToast => 'Added';

  @override
  String get clientMessagesCardChange => 'Change';

  @override
  String get clientMessagesCardVendor => 'Profile';

  @override
  String get clientMessagesAttachTitle => 'Attach';

  @override
  String get clientMessagesAttachCamera => 'Camera';

  @override
  String get clientMessagesAttachPhoto => 'Photos';

  @override
  String get clientMessagesAttachDocument => 'Document';

  @override
  String get clientMessagesAttachRecent => 'Recent photos';

  @override
  String clientMessagesAttachLimits(String photo, String video) {
    return 'Photos up to $photo, videos up to $video. Chat media stays private between you and the other side.';
  }

  @override
  String get clientMessagesAttachLimitsTitle => 'Limits';

  @override
  String clientMessagesUnitMb(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString MB';
  }

  @override
  String clientMessagesUnitSeconds(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString seconds',
      one: '$nString second',
      zero: 'No seconds',
    );
    return '$_temp0';
  }

  @override
  String clientMessagesUnitKb(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString KB';
  }

  @override
  String get clientMessagesDocPreview => 'Document preview';

  @override
  String get clientMessagesDocQuotation => 'Quotation';

  @override
  String get clientMessagesDocEvent => 'Event date';

  @override
  String get clientMessagesDocHall => 'Hall';

  @override
  String get clientMessagesDocGuests => 'Guests';

  @override
  String get clientMessagesDocPackage => 'Package';

  @override
  String get clientMessagesDocFileSize => 'File size';

  @override
  String get clientMessagesDocStandard => 'Standard';

  @override
  String get clientMessagesDocVoucher => 'Voucher';

  @override
  String get clientMessagesDocSaving => 'Saved';

  @override
  String get clientMessagesDocDownload => 'Download';

  @override
  String get clientMessagesDocSaved => 'Saved';

  @override
  String clientMessagesDocOpen(String name) {
    return 'Open $name';
  }

  @override
  String get clientMessagesInfoBooking => 'Linked request';

  @override
  String get clientMessagesInfoShared => 'Photos and documents';

  @override
  String get clientMessagesInfoMute => 'Mute';

  @override
  String get clientMessagesInfoMuted => 'Muted';

  @override
  String get clientMessagesInfoUnmuted => 'Unmuted';

  @override
  String get clientMessagesInfoCall => 'Call';

  @override
  String get clientMessagesInfoReport => 'Report';

  @override
  String get clientMessagesInfoBlock => 'Block';

  @override
  String get clientMessagesInfoMembers => 'Members';

  @override
  String get clientMessagesInfoMembersNote =>
      'Only these three people are in this chat. Phone numbers are not shared.';

  @override
  String get clientMessagesInfoVisit => 'Visit';

  @override
  String get clientMessagesInfoVisitNote =>
      'Ghazal support is part of this chat, so it cannot be blocked. To stop it, cancel the visit.';

  @override
  String get clientMessagesInfoSupportNote =>
      'Support conversations cannot be blocked.';

  @override
  String get clientMessagesInfoPrivate =>
      'Chat media is private between you and the other side.';

  @override
  String get clientMessagesInfoPrivateTitle => 'Privacy';

  @override
  String get clientMessagesInfoNeedsConnection => 'Needs a connection';

  @override
  String get clientMessagesInfoErrorReport => 'Could not send';

  @override
  String get clientMessagesReportPick => 'Select message';

  @override
  String get clientMessagesReportReasonTitle => 'Reason';

  @override
  String get clientMessagesReasonSpam => 'Spam';

  @override
  String get clientMessagesReasonAbusive => 'Abusive';

  @override
  String get clientMessagesReasonInappropriate => 'Inappropriate';

  @override
  String get clientMessagesReasonOther => 'Other';

  @override
  String get clientMessagesReportNote => 'Note';

  @override
  String get clientMessagesReportSubmit => 'Send report';

  @override
  String get clientMessagesReportDone => 'Report sent';

  @override
  String get clientMessagesReportDoneDetail =>
      'The message stays in your conversation. Our team will take a look and act if it breaks our rules.';

  @override
  String get clientMessagesReportNoMessages => 'No messages';

  @override
  String get clientMessagesReportNeedMessage => 'Select a message';

  @override
  String get clientMessagesReportNeedReason => 'Select a reason';

  @override
  String get clientMessagesBlockTitle => 'Block chat?';

  @override
  String clientMessagesBlockBodyBooking(String phone) {
    return 'Updates still arrive. Call $phone';
  }

  @override
  String get clientMessagesBlockConfirm => 'Block';

  @override
  String get clientMessagesBlockKeep => 'Cancel';

  @override
  String get clientMessagesBlockedDoneTitle => 'Blocked';

  @override
  String get clientMessagesBlockedDoneDetail =>
      'You will not receive messages from this side. You can unblock it at any time.';

  @override
  String get clientMessagesNtfTitle => 'Notifications';

  @override
  String get clientMessagesNtfPrefs => 'Notification settings';

  @override
  String get clientMessagesNtfFilterGroup => 'Filter notifications';

  @override
  String get clientMessagesNtfBookings => 'Requests';

  @override
  String get clientMessagesNtfVouchers => 'Vouchers';

  @override
  String get clientMessagesNtfVisits => 'Visits';

  @override
  String get clientMessagesNtfMessages => 'Messages';

  @override
  String get clientMessagesNtfPlanning => 'Planning';

  @override
  String get clientMessagesNtfUnreadOnly => 'Unread';

  @override
  String get clientMessagesNtfUnread => 'Unread';

  @override
  String get clientMessagesNtfMarkAll => 'Read all';

  @override
  String get clientMessagesNtfAllRead => 'All read';

  @override
  String get clientMessagesNtfEmptyTitle => 'No notifications';

  @override
  String get clientMessagesNtfUnreadEmptyTitle => 'All caught up';

  @override
  String get clientMessagesNtfShowAll => 'Show all';

  @override
  String get clientMessagesNtfDeniedTitle => 'Notifications off';

  @override
  String get clientMessagesNtfDeniedInfo =>
      'Updates still appear here. Turn them on in your phone settings to get them as they happen.';

  @override
  String get clientMessagesNtfOpenSettings => 'Settings';

  @override
  String get clientMessagesNtfSettingsToast => 'Opens phone settings';

  @override
  String get clientMessagesNtfOffer => 'Offer';

  @override
  String get clientMessagesNtfKindRequestSent => 'Request sent';

  @override
  String get clientMessagesNtfKindApproved => 'Approved';

  @override
  String get clientMessagesNtfKindConfirmReminder => 'Confirm';

  @override
  String get clientMessagesNtfKindConfirmed => 'Confirmed';

  @override
  String get clientMessagesNtfKindDeclined => 'Not accepted';

  @override
  String get clientMessagesNtfKindExpired => 'Expired';

  @override
  String get clientMessagesNtfKindCancelled => 'Cancelled';

  @override
  String get clientMessagesNtfKindVoucherReady => 'Voucher ready';

  @override
  String get clientMessagesNtfKindVoucherKept => 'Still yours';

  @override
  String get clientMessagesNtfKindRedeemed => 'Redeemed';

  @override
  String get clientMessagesNtfKindRefunded => 'Credit';

  @override
  String get clientMessagesNtfKindExpiring => 'Expiring';

  @override
  String get clientMessagesNtfKindVisitRequested => 'Visit requested';

  @override
  String get clientMessagesNtfKindVisitConfirmed => 'Visit confirmed';

  @override
  String get clientMessagesNtfKindVisitSoon => 'Visit soon';

  @override
  String get clientMessagesNtfKindVisitChat => 'Visit chat';

  @override
  String get clientMessagesNtfKindNewVenue => 'New hall';

  @override
  String get clientMessagesNtfKindReview => 'Review';

  @override
  String get clientMessagesNtfKindCountdown => 'Wedding';

  @override
  String get clientMessagesNtfKindChecklist => 'Checklist';

  @override
  String get clientMessagesPromptTitle => 'Booking updates';

  @override
  String get clientMessagesPromptBody =>
      'We will tell you as soon as a hall replies to your request, and when your voucher is ready.';

  @override
  String get clientMessagesPromptNote =>
      'We only send what you need, and never late at night.';

  @override
  String get clientMessagesPromptOn => 'Turn on';

  @override
  String get clientMessagesPromptLater => 'Not now';

  @override
  String get clientMessagesPromptOnToast => 'Updates on';

  @override
  String get clientMessagesOsTitle =>
      '“Ghazal” would like to send you notifications';

  @override
  String get clientMessagesOsBody =>
      'Request updates, vouchers and visit reminders.';

  @override
  String get clientMessagesOsAllow => 'Allow';

  @override
  String get clientMessagesOsDeny => 'Don’t allow';

  @override
  String get clientMessagesMissingTitle => 'No longer listed';

  @override
  String get clientMessagesMissingArea => 'Area';

  @override
  String get clientMyWeddingHubTitle => 'My Wedding';

  @override
  String get clientMyWeddingHubNotifications => 'Notifications';

  @override
  String clientMyWeddingHeroUnit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get clientMyWeddingHeroTimeline => 'Countdown milestones';

  @override
  String get clientMyWeddingHeroDate => 'Wedding date';

  @override
  String get clientMyWeddingHeroWordToday => 'Today';

  @override
  String get clientMyWeddingHeroWordTomorrow => 'Tomorrow';

  @override
  String get clientMyWeddingHeroSetDate => 'Set date';

  @override
  String get clientMyWeddingDoneTitle => 'Congratulations';

  @override
  String get clientMyWeddingDoneReviewAction => 'Review';

  @override
  String get clientMyWeddingDayDirections => 'Directions';

  @override
  String get clientMyWeddingDayCall => 'Call venue';

  @override
  String get clientMyWeddingDayMessage => 'Message planner';

  @override
  String get clientMyWeddingDayDirectionsToast => 'Opening directions';

  @override
  String get clientMyWeddingDayCallToast => 'Calling the venue';

  @override
  String get clientMyWeddingNextTitle => 'Next up';

  @override
  String get clientMyWeddingNextWaiting => 'Waiting';

  @override
  String clientMyWeddingNextWaitingLabel(String when) {
    return 'Reply expected by $when';
  }

  @override
  String get clientMyWeddingNextHalls => 'View halls';

  @override
  String get clientMyWeddingNextHallsLabel => 'Halls free on your date';

  @override
  String get clientMyWeddingVoucherOpen => 'Open';

  @override
  String clientMyWeddingNextConfirmLabel(String when) {
    return 'Confirm by $when';
  }

  @override
  String get clientMyWeddingTaskVenue => 'Venue';

  @override
  String get clientMyWeddingTaskPhotographer => 'Photographer';

  @override
  String get clientMyWeddingTaskDress => 'Dress';

  @override
  String get clientMyWeddingTaskInvitations => 'Invitations';

  @override
  String get clientMyWeddingTaskCake => 'Cake';

  @override
  String get clientMyWeddingTaskMusic => 'Music';

  @override
  String get clientMyWeddingTaskFlowers => 'Flowers';

  @override
  String get clientMyWeddingTaskTransport => 'Transport';

  @override
  String clientMyWeddingTasksLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tasks remaining',
      one: '$countString task remaining',
    );
    return '$_temp0';
  }

  @override
  String get clientMyWeddingBookingsTitle => 'Bookings';

  @override
  String get clientMyWeddingBookingsEmptyTitle => 'No bookings';

  @override
  String get clientMyWeddingBookingsEmptyAction => 'Browse halls';

  @override
  String get clientMyWeddingBookingGuests => 'Guests';

  @override
  String get clientMyWeddingPlannerTitle => 'Wedding planner';

  @override
  String get clientMyWeddingPlannerOfferAction => 'See packages';

  @override
  String get clientMyWeddingPlannerDismiss => 'Hide this offer';

  @override
  String clientMyWeddingPlannerCall(String when) {
    return 'Video call $when';
  }

  @override
  String get clientMyWeddingToolsLabel => 'Planning tools';

  @override
  String get clientMyWeddingToolChecklist => 'Checklist';

  @override
  String get clientMyWeddingToolBudget => 'Budget';

  @override
  String get clientMyWeddingToolBudgetOver => 'Over';

  @override
  String get clientMyWeddingToolSaved => 'Saved';

  @override
  String get clientMyWeddingToolServices => 'Services';

  @override
  String get clientMyWeddingGuestAction => 'Sign in';

  @override
  String get clientMyWeddingSample => 'Sample';

  @override
  String get clientMyWeddingUpdated => 'Last updated';

  @override
  String get clientMyWeddingDateDiffersLabel => 'Booking date';

  @override
  String get clientMyWeddingDateDiffersAction => 'Use date';

  @override
  String get clientMyWeddingDateUpdated => 'Wedding date updated';

  @override
  String get clientMyWeddingChecklistTitle => 'Checklist';

  @override
  String get clientMyWeddingChecklistAdd => 'Add task';

  @override
  String clientMyWeddingChecklistProgress(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get clientMyWeddingChecklistBandBooking => 'Booking';

  @override
  String clientMyWeddingChecklistBandMore(String count) {
    return '$count+ months';
  }

  @override
  String clientMyWeddingChecklistBandMonths(String from, String to) {
    return '$from–$to months';
  }

  @override
  String get clientMyWeddingChecklistBandMonth => 'Final month';

  @override
  String get clientMyWeddingChecklistBandWeek => 'Final week';

  @override
  String get clientMyWeddingChecklistBandNoDate => 'Anytime';

  @override
  String get clientMyWeddingChecklistBandDone => 'Done';

  @override
  String clientMyWeddingChecklistDue(String when) {
    return 'Due $when';
  }

  @override
  String clientMyWeddingChecklistOverdue(String when) {
    return 'Overdue since $when';
  }

  @override
  String get clientMyWeddingChecklistAuto =>
      'Completes when your booking is confirmed';

  @override
  String clientMyWeddingChecklistBrowseLabel(String task) {
    return '$task: browse services';
  }

  @override
  String clientMyWeddingChecklistViewBookingLabel(String task) {
    return '$task: view booking';
  }

  @override
  String get clientMyWeddingChecklistEdit => 'Edit task';

  @override
  String get clientMyWeddingChecklistToastDone => 'Marked as done';

  @override
  String get clientMyWeddingChecklistAllDone => 'All done';

  @override
  String get clientMyWeddingChecklistEmptyTitle => 'No date yet';

  @override
  String get clientMyWeddingChecklistEmptyAction => 'Set date';

  @override
  String get clientMyWeddingTaskSheetAdd => 'Add task';

  @override
  String get clientMyWeddingTaskSheetEdit => 'Edit task';

  @override
  String get clientMyWeddingTaskTitlePlaceholder => 'Task';

  @override
  String get clientMyWeddingTaskTitleError => 'Enter a name';

  @override
  String get clientMyWeddingTaskDueLabel => 'Due date';

  @override
  String get clientMyWeddingTaskCategoryLabel => 'Category';

  @override
  String get clientMyWeddingTaskCategoryPlaceholder => 'None';

  @override
  String get clientMyWeddingTaskDelete => 'Delete';

  @override
  String get clientMyWeddingTaskAdded => 'Task added';

  @override
  String get clientMyWeddingTaskDeleted => 'Task deleted';

  @override
  String get clientMyWeddingBudgetTitle => 'Budget';

  @override
  String get clientMyWeddingBudgetEdit => 'Edit budget';

  @override
  String get clientMyWeddingBudgetRemaining => 'Remaining';

  @override
  String get clientMyWeddingBudgetOver => 'Over';

  @override
  String get clientMyWeddingBudgetTotalLabel => 'Total budget';

  @override
  String get clientMyWeddingBudgetPaid => 'Paid';

  @override
  String get clientMyWeddingBudgetCommitted => 'Committed';

  @override
  String clientMyWeddingBudgetBarLabel(
    String paid,
    String committed,
    String remaining,
  ) {
    return 'Paid $paid, committed $committed, remaining $remaining';
  }

  @override
  String get clientMyWeddingBudgetAddExpense => 'Add expense';

  @override
  String clientMyWeddingBudgetAlertSoft(String category, String percent) {
    return '$category $percent';
  }

  @override
  String clientMyWeddingBudgetAlertOver(String category, String amount) {
    return '$category $amount';
  }

  @override
  String get clientMyWeddingBudgetCategories => 'Categories';

  @override
  String get clientMyWeddingBudgetLedger => 'Payments';

  @override
  String get clientMyWeddingBudgetInfoTitle => 'Voucher and venue';

  @override
  String get clientMyWeddingBudgetInfoBody =>
      'The voucher is paid in the app. The venue price is paid to the venue directly, outside Ghazal.';

  @override
  String clientMyWeddingBudgetUsedLabel(String percent) {
    return '$percent used';
  }

  @override
  String clientMyWeddingBudgetOverByLabel(String amount) {
    return '$amount over its share';
  }

  @override
  String get clientMyWeddingBudgetLinked => 'Linked to your booking';

  @override
  String get clientMyWeddingBudgetPlanned => 'Planned';

  @override
  String get clientMyWeddingBudgetEmptyTitle => 'No budget yet';

  @override
  String get clientMyWeddingBudgetEmptyAction => 'Set budget';

  @override
  String get clientMyWeddingBudgetAdded => 'Expense added';

  @override
  String get clientMyWeddingExpenseTitleAdd => 'Add expense';

  @override
  String get clientMyWeddingExpenseTitleEdit => 'Edit expense';

  @override
  String get clientMyWeddingExpenseAmount => 'Amount';

  @override
  String get clientMyWeddingExpenseAmountError => 'Enter an amount';

  @override
  String get clientMyWeddingExpenseCategory => 'Category';

  @override
  String get clientMyWeddingExpenseNote => 'Note';

  @override
  String get clientMyWeddingExpenseDate => 'Date';

  @override
  String get clientMyWeddingExpenseStatus => 'Payment status';

  @override
  String get clientMyWeddingExpensePaid => 'Paid';

  @override
  String get clientMyWeddingExpensePlanned => 'Planned';

  @override
  String get clientMyWeddingExpenseDelete => 'Delete';

  @override
  String get clientMyWeddingExpenseDeleteTitle => 'Delete expense?';

  @override
  String get clientMyWeddingExpenseKeep => 'Keep';

  @override
  String get clientMyWeddingExpenseSuccessTitle => 'Added';

  @override
  String get clientMyWeddingExpenseOfflineReason => 'Reconnect to save';

  @override
  String get clientMyWeddingExpenseDeleted => 'Expense deleted';

  @override
  String get clientMyWeddingExpenseSampleLabel => 'Henna artist deposit';

  @override
  String get clientMyWeddingSetupTitle => 'Set budget';

  @override
  String get clientMyWeddingSetupTotal => 'Total';

  @override
  String get clientMyWeddingSetupPresets => 'Suggested totals';

  @override
  String get clientMyWeddingSetupCategories => 'Split';

  @override
  String get clientMyWeddingSetupVenueReference =>
      'Your venue and catering range';

  @override
  String get clientMyWeddingSetupUnallocated => 'Unallocated';

  @override
  String get clientMyWeddingSetupOver => 'Over total';

  @override
  String clientMyWeddingSetupAlertSoft(String percent) {
    return 'Alert at $percent';
  }

  @override
  String clientMyWeddingSetupAlertHard(String percent) {
    return 'Alert at $percent';
  }

  @override
  String get clientMyWeddingSetupError => 'Couldn’t save';

  @override
  String get clientMyWeddingSetupErrorDetail =>
      'We couldn’t save your budget. Nothing was changed.';

  @override
  String get clientMyWeddingSetupSaved => 'Budget saved';

  @override
  String get clientMyWeddingCatVenueCatering => 'Venue';

  @override
  String get clientMyWeddingCatPhotoVideo => 'Photo';

  @override
  String get clientMyWeddingCatFlowersDecor => 'Flowers';

  @override
  String get clientMyWeddingCatAttire => 'Attire';

  @override
  String get clientMyWeddingCatMakeupHenna => 'Makeup';

  @override
  String get clientMyWeddingCatCars => 'Cars';

  @override
  String get clientMyWeddingCatInvitations => 'Invitations';

  @override
  String get clientMyWeddingCatMusic => 'Music';

  @override
  String get clientMyWeddingCatHoneymoon => 'Honeymoon';

  @override
  String get clientOnboardingAltLanguage =>
      'Wedding stage framed by rose-and-greenery arches, blush swags and white drapery, with a long floral table in the foreground';

  @override
  String clientOnboardingStepProgress(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Step $currentString of $totalString';
  }

  @override
  String get clientOnboardingLanguageTitle => 'Choose your language';

  @override
  String get clientOnboardingLanguageGroup => 'App language';

  @override
  String get clientOnboardingLanguageSignIn => 'Sign in';

  @override
  String get clientOnboardingLanguageSignInOffline =>
      'Signing in needs a connection.';

  @override
  String get clientOnboardingIntroLabel => 'Introduction';

  @override
  String get clientOnboardingIntroSlide1Title => 'Compare three halls';

  @override
  String get clientOnboardingIntroSlide2Title => 'Free dates at a glance';

  @override
  String get clientOnboardingIntroSlide3Title => 'Lower voucher prices';

  @override
  String get clientOnboardingIntroStart => 'Get started';

  @override
  String get clientOnboardingInfoTitle => 'Your answers';

  @override
  String get clientOnboardingInfoBody =>
      'All optional. They stay on this device until you sign up, and you can change them anytime in Profile.';

  @override
  String get clientOnboardingAboutTitle => 'Who’s planning?';

  @override
  String get clientOnboardingAboutRoleLabel => 'Your role';

  @override
  String get clientOnboardingAboutRoleBride => 'Bride';

  @override
  String get clientOnboardingAboutRoleGroom => 'Groom';

  @override
  String get clientOnboardingAboutRoleFamily => 'Family';

  @override
  String get clientOnboardingAboutRolePlanner => 'Planner';

  @override
  String get clientOnboardingAboutNameLabel => 'Name';

  @override
  String get clientOnboardingAboutPartnerDefault => 'Partner’s name';

  @override
  String get clientOnboardingAboutPartnerGroom => 'Groom’s name';

  @override
  String get clientOnboardingAboutPartnerBride => 'Bride’s name';

  @override
  String get clientOnboardingAboutPartnerCouple => 'Couple’s names';

  @override
  String get clientOnboardingAboutMonogram => 'Monogram preview';

  @override
  String get clientOnboardingDateTitle => 'Wedding date';

  @override
  String get clientOnboardingDateOccasions => 'Around this month';

  @override
  String clientOnboardingDateOccasionOne(String name, String date) {
    return '$name · $date';
  }

  @override
  String clientOnboardingDateOccasionRange(
    String name,
    String from,
    String to,
  ) {
    return '$name · $from to $to';
  }

  @override
  String get clientOnboardingDateNotDecided => 'Undecided';

  @override
  String get clientOnboardingDateFlexible => 'Flexible';

  @override
  String get clientOnboardingDateFlexibleTitle => 'Flexible month';

  @override
  String get clientOnboardingDatePickDate => 'Pick a date';

  @override
  String get clientOnboardingDateMonthsLabel => 'Months';

  @override
  String get clientOnboardingGuestsTitle => 'Guests and budget';

  @override
  String get clientOnboardingGuestsSection => 'Guests';

  @override
  String get clientOnboardingGuestsExpected => 'Expected guests';

  @override
  String get clientOnboardingGuestsPresets => 'Common guest counts';

  @override
  String clientOnboardingGuestsPresetMax(String count) {
    return '$count+';
  }

  @override
  String get clientOnboardingGuestsSplitTitle => 'Ladies and men';

  @override
  String get clientOnboardingGuestsSplitLabel =>
      'Separate ladies’ and men’s receptions';

  @override
  String get clientOnboardingGuestsLadies => 'Ladies’ reception';

  @override
  String get clientOnboardingGuestsMen => 'Men’s reception';

  @override
  String get clientOnboardingBudgetSection => 'Venue and catering';

  @override
  String get clientOnboardingBudgetBands => 'Budget bands';

  @override
  String clientOnboardingBudgetUnder(String amount) {
    return 'Under $amount';
  }

  @override
  String clientOnboardingBudgetAbove(String amount) {
    return '$amount and above';
  }

  @override
  String get clientOnboardingBudgetRange => 'Custom budget range';

  @override
  String get clientOnboardingSkipHalf => 'Later';

  @override
  String get clientOnboardingAreasTitle => 'Areas';

  @override
  String get clientOnboardingAreasSearch => 'Search areas';

  @override
  String clientOnboardingAreasSelected(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString areas selected',
      one: '$countString area selected',
      zero: 'No areas selected',
    );
    return '$_temp0';
  }

  @override
  String get clientOnboardingAreasDemoQuery => 'Mish';

  @override
  String clientOnboardingAreasMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString more areas',
      one: '$countString more area',
      zero: 'No more areas',
    );
    return '$_temp0';
  }

  @override
  String get clientOnboardingAreasNoHallsNote =>
      'No halls yet. Home shows all.';

  @override
  String get clientOnboardingLanguageNativeAr => 'العربية';

  @override
  String get clientOnboardingLanguageNativeEn => 'English';

  @override
  String get clientPaymentTopTitle => 'Payment';

  @override
  String clientPaymentSave(String amount) {
    return 'Save $amount';
  }

  @override
  String get clientPaymentLabelHall => 'Hall';

  @override
  String get clientPaymentLabelPackage => 'Package';

  @override
  String get clientPaymentLabelDate => 'Date';

  @override
  String get clientPaymentLabelGuests => 'Guests';

  @override
  String get clientPaymentLabelOpenUntil => 'Open until';

  @override
  String get clientPaymentLabelSaving => 'You save';

  @override
  String get clientPaymentLabelAmount => 'Amount';

  @override
  String get clientPaymentLabelMethod => 'Method';

  @override
  String get clientPaymentLabelVoucherFor => 'Voucher for';

  @override
  String get clientPaymentAmountLabel => 'Ghazal voucher, paid once';

  @override
  String clientPaymentTimerSr(String time) {
    return 'Time remaining: $time';
  }

  @override
  String get clientPaymentMethodsTitle => 'Pay with';

  @override
  String get clientPaymentMethodsLabel => 'Payment method';

  @override
  String get clientPaymentMethodKnet => 'KNET';

  @override
  String get clientPaymentMethodApplePay => 'Apple Pay';

  @override
  String get clientPaymentMethodGooglePay => 'Google Pay';

  @override
  String get clientPaymentMethodCard => 'Visa or Mastercard';

  @override
  String get clientPaymentMethodCardShort => 'Card';

  @override
  String get clientPaymentMethodSuggested => 'Suggested';

  @override
  String get clientPaymentSecureTitle => 'Secure payment';

  @override
  String get clientPaymentHonestKnet =>
      'KNET opens your bank’s secure page and works with Kuwaiti bank cards only.';

  @override
  String get clientPaymentHonestWallet =>
      'You confirm on your device. Ghazal never sees your card details.';

  @override
  String get clientPaymentHonestCard =>
      'You enter your card on the payment provider’s secure page. Ghazal never sees or stores it.';

  @override
  String get clientPaymentCtaPay => 'Pay now';

  @override
  String get clientPaymentTermPrice => 'Voucher price';

  @override
  String get clientPaymentTermDirect => 'Pay direct';

  @override
  String get clientPaymentTermReturns => 'Voucher returns';

  @override
  String get clientPaymentHowLink => 'How the voucher works';

  @override
  String get clientPaymentHasVoucherBanner => 'You have this voucher';

  @override
  String get clientPaymentSessionErrorTitle => 'Couldn’t start payment';

  @override
  String get clientPaymentSessionError =>
      'We could not start the payment. No amount was charged.';

  @override
  String get clientPaymentExpiredBanner => 'Checkout ended';

  @override
  String get clientPaymentCancelledToast => 'Cancelled, not charged';

  @override
  String get clientPaymentGatewayTitle => 'Secure payment';

  @override
  String get clientPaymentGatewayBack => 'Close payment';

  @override
  String get clientPaymentLeaveTitle => 'Leave payment?';

  @override
  String get clientPaymentLeaveBody => 'Not charged yet';

  @override
  String get clientPaymentLeaveConfirm => 'Leave';

  @override
  String get clientPaymentLeaveStay => 'Stay';

  @override
  String get clientPaymentRedirectTitle => 'Opening secure page';

  @override
  String get clientPaymentRedirectBody =>
      'You will finish the payment on a secure page. Nothing is charged until you do.';

  @override
  String get clientPaymentRedirectPrivacy =>
      'Ghazal never sees your card number or PIN.';

  @override
  String get clientPaymentReturnedTitle => 'Checking payment';

  @override
  String get clientPaymentLostTitle => 'Connection lost';

  @override
  String get clientPaymentLostBody =>
      'We are checking your payment. There is no need to pay again.';

  @override
  String get clientPaymentCancelTitle => 'Payment cancelled';

  @override
  String get clientPaymentNotCharged => 'Not charged';

  @override
  String get clientPaymentNotChargedLabel => 'Charge status';

  @override
  String get clientPaymentReceivedLabel => 'Payment received';

  @override
  String get clientPaymentBankNote => 'Bank page';

  @override
  String get clientPaymentCardPageNote => 'Card page';

  @override
  String get clientPaymentBankBank => 'Bank';

  @override
  String get clientPaymentBankCard => 'Card number';

  @override
  String get clientPaymentBankExpiry => 'Expiry';

  @override
  String get clientPaymentBankPin => 'PIN';

  @override
  String get clientPaymentBankItemName => 'Ghazal voucher';

  @override
  String get clientPaymentBankSubmit => 'Submit';

  @override
  String get clientPaymentCardHolder => 'Name';

  @override
  String get clientPaymentCardCvv => 'CVV';

  @override
  String get clientPaymentProtoLabel => 'Prototype';

  @override
  String get clientPaymentProtoApproved => 'Approved';

  @override
  String get clientPaymentProtoDeclined => 'Declined';

  @override
  String get clientPaymentProtoSlow => 'Slow';

  @override
  String get clientPaymentProtoLost => 'Lost';

  @override
  String get clientPaymentProtoLate => 'Late';

  @override
  String get clientPaymentConfirmTitle => 'Confirming payment';

  @override
  String get clientPaymentConfirmLongTitle => 'Still confirming';

  @override
  String get clientPaymentConfirmNotify => 'We’ll notify you';

  @override
  String get clientPaymentConfirmNotifyLabel => 'Notification';

  @override
  String get clientPaymentConfirmKeep => 'Keep waiting';

  @override
  String get clientPaymentConfirmLeave => 'Leave';

  @override
  String get clientPaymentConfirmOffline =>
      'You are offline. Your payment is being confirmed and we will notify you.';

  @override
  String get clientPaymentConfirmSuccessTitle => 'Payment received';

  @override
  String get clientPaymentConfirmProgress => 'Checking the payment';

  @override
  String get clientPaymentViewVoucher => 'View voucher';

  @override
  String get clientPaymentFailTitleExpired => 'Checkout ended';

  @override
  String get clientPaymentFailTitleLate => 'Voucher ready';

  @override
  String get clientPaymentFailBodyDeclined =>
      'Your bank did not accept the payment. You can try again or choose another method.';

  @override
  String get clientPaymentFailBodyCancelled =>
      'You closed the payment page before it finished.';

  @override
  String clientPaymentFailBodyExpired(String time, String minutes) {
    return 'Your checkout for this voucher ended at $time, after $minutes. You can start again with the same quote.';
  }

  @override
  String get clientPaymentFailBodyLate =>
      'Your payment arrived after the checkout ended, and we still honoured it. The voucher is yours.';

  @override
  String get clientPaymentFailBodyOffline =>
      'Reconnect to try again. Nothing is charged until a payment completes.';

  @override
  String get clientPaymentFailAnother => 'Another method';

  @override
  String get clientPaymentFailStartAgain => 'Start again';

  @override
  String get clientPaymentSupport => 'Support';

  @override
  String get clientPaymentDoneTitle => 'Voucher ready';

  @override
  String get clientPaymentDoneLate => 'Payment arrived late';

  @override
  String get clientPaymentDoneLateNote =>
      'Your payment arrived after the checkout ended. The voucher is active and bound to the date shown.';

  @override
  String get clientPaymentDoneReuse =>
      'If the request is declined or goes unanswered, your voucher comes back to you.';

  @override
  String get clientPaymentDoneCta => 'Send request';

  @override
  String get clientPaymentDoneRowVouchers => 'My vouchers';

  @override
  String get clientPaymentDoneRowReceipt => 'Receipt';

  @override
  String get clientPaymentTermsTitle => 'Voucher terms';

  @override
  String get clientPaymentTermsLabel => 'Voucher terms';

  @override
  String get clientPlannerOfferTitle => 'Need a planner?';

  @override
  String get clientPlannerTitle => 'Planner';

  @override
  String get clientPlannerCompareTitle => 'Compare';

  @override
  String get clientPlannerCompareLabel => 'Compare packages';

  @override
  String get clientPlannerTierPickerLabel => 'Package';

  @override
  String get clientPlannerFromPrefix => 'From';

  @override
  String clientPlannerMarks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString thread marks',
      one: '$countString thread mark',
    );
    return '$_temp0';
  }

  @override
  String clientPlannerCompareChoose(String name) {
    return 'Choose $name';
  }

  @override
  String clientPlannerCompareChosen(String name) {
    return '$name, chosen';
  }

  @override
  String get clientPlannerIncluded => 'Included';

  @override
  String get clientPlannerNotIncluded => 'Not included';

  @override
  String get clientPlannerIncludedLabel => 'What is included';

  @override
  String get clientPlannerEverythingIn => 'Everything in';

  @override
  String get clientPlannerIncSilver0 => 'Day coordinator';

  @override
  String get clientPlannerIncSilver1 => 'Event timeline';

  @override
  String get clientPlannerIncSilver2 => 'Vendor checks';

  @override
  String get clientPlannerIncSilver3 => 'Venue walkthrough';

  @override
  String get clientPlannerIncGold0 => 'Planning from booking';

  @override
  String get clientPlannerIncGold1 => 'Vendors and quotes';

  @override
  String get clientPlannerIncGold2 => 'Styling concept';

  @override
  String get clientPlannerIncGold3 => 'Two meetings';

  @override
  String get clientPlannerIncRoyal0 => 'Bespoke kosha';

  @override
  String get clientPlannerIncRoyal1 => 'Production management';

  @override
  String get clientPlannerIncRoyal2 => 'Vendor contracts';

  @override
  String get clientPlannerIncRoyal3 => 'Dedicated team';

  @override
  String get clientPlannerWeddingLabel => 'Your wedding';

  @override
  String get clientPlannerPriceInfoTitle => 'Price';

  @override
  String get clientPlannerPriceInfo =>
      'You agree the final price with your planner after the consultation. Nothing is paid now.';

  @override
  String get clientPlannerRequestConsultation => 'Request consultation';

  @override
  String get clientPlannerNotNowToast => 'Always in My Wedding';

  @override
  String get clientPlannerOtherPlanners => 'Other planners';

  @override
  String get clientPlannerGuestSignIn => 'Sign in';

  @override
  String get clientPlannerRetryToast => 'Still can’t connect';

  @override
  String get clientPlannerRequestTitle => 'Consultation';

  @override
  String get clientPlannerRequestChange => 'Change package';

  @override
  String get clientPlannerRequestTimesTitle => 'Times';

  @override
  String get clientPlannerRequestDayLabel => 'Day';

  @override
  String clientPlannerRequestWindowLabel(String day) {
    return 'Time of day for $day';
  }

  @override
  String clientPlannerRequestDayWithChoices(String day, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString windows chosen',
      one: '$countString window chosen',
    );
    return '$day, $_temp0';
  }

  @override
  String get clientPlannerRequestWindowMorning => 'Morning';

  @override
  String get clientPlannerRequestWindowAfternoon => 'Afternoon';

  @override
  String get clientPlannerRequestWindowEvening => 'Evening';

  @override
  String get clientPlannerRequestWindowsError => 'Pick a time';

  @override
  String get clientPlannerRequestReachLabel => 'Contact';

  @override
  String get clientPlannerRequestReachChat => 'Chat';

  @override
  String get clientPlannerRequestReachWhatsapp => 'WhatsApp';

  @override
  String get clientPlannerRequestReachPhone => 'Call';

  @override
  String get clientPlannerRequestNotesLabel => 'Notes';

  @override
  String get clientPlannerRequestSend => 'Send request';

  @override
  String get clientPlannerRequestSuccessTitle => 'Request sent';

  @override
  String get clientPlannerRequestSentToast => 'We’ll notify you';

  @override
  String get clientPlannerRequestOpenTitle => 'Request open';

  @override
  String get clientPlannerViewRequest => 'View request';

  @override
  String get clientPlannerStatusTitle => 'Your planner';

  @override
  String get clientPlannerStatusHeadWaiting => 'Finding your planner';

  @override
  String get clientPlannerStatusThreadLabel => 'Request progress';

  @override
  String get clientPlannerStatusStepRequested => 'Request';

  @override
  String get clientPlannerStatusStepAssigned => 'Planner';

  @override
  String get clientPlannerStatusStepMeeting => 'Meeting';

  @override
  String get clientPlannerStatusCancelTitle => 'Cancel request?';

  @override
  String get clientPlannerStatusCancelBody => 'Nothing is lost.';

  @override
  String get clientPlannerStatusCancelConfirm => 'Cancel request';

  @override
  String get clientPlannerStatusCancelKeep => 'Keep';

  @override
  String get clientPlannerStatusCancelledToast => 'Request cancelled';

  @override
  String get clientPlannerStatusSchedule => 'Schedule';

  @override
  String clientPlannerStatusMessageName(String name) {
    return 'Message $name';
  }

  @override
  String get clientPlannerStatusMeetingLabel => 'Next meeting';

  @override
  String get clientPlannerStatusAddToCalendar => 'Add to calendar';

  @override
  String get clientPlannerStatusCalendarToast => 'Added to calendar';

  @override
  String clientPlannerStatusAssignedToast(String name) {
    return '$name assigned';
  }

  @override
  String get clientPlannerTypeVideo => 'Video';

  @override
  String get clientPlannerTypePhone => 'Call';

  @override
  String get clientPlannerTypeVideoName => 'Video call';

  @override
  String get clientPlannerTypePhoneName => 'Phone call';

  @override
  String get clientPlannerMeetingTitle => 'Schedule meeting';

  @override
  String get clientPlannerMeetingDayLabel => 'Day';

  @override
  String get clientPlannerMeetingTimeLabel => 'Time';

  @override
  String get clientPlannerMeetingTypeLabel => 'Meeting type';

  @override
  String clientPlannerMeetingDayNoSlots(String day) {
    return '$day, no free times';
  }

  @override
  String get clientPlannerMeetingConfirm => 'Confirm';

  @override
  String get clientPlannerMeetingNoSlotsTitle => 'No free times';

  @override
  String get clientPlannerMeetingTaken => 'Time taken';

  @override
  String get clientPlannerMeetingSuccessTitle => 'Meeting set';

  @override
  String get clientPlannerMeetingCalendar => 'Calendar';

  @override
  String clientProfileSharedVersion(String version) {
    return 'v$version';
  }

  @override
  String get clientProfileSharedOn => 'On';

  @override
  String get clientProfileSharedOff => 'Off';

  @override
  String get clientProfileSharedKeep => 'Keep account';

  @override
  String get clientProfileSharedSupport => 'Support';

  @override
  String get clientProfileSharedTerms => 'Terms';

  @override
  String get clientProfileSharedPrivacy => 'Privacy';

  @override
  String get clientProfileSharedSignIn => 'Sign in';

  @override
  String get clientProfileSharedSignOut => 'Sign out';

  @override
  String get clientProfileSharedSignOutTitle => 'Sign out?';

  @override
  String get clientProfileSharedSignOutStay => 'Stay';

  @override
  String get clientProfileSharedSignedOut => 'Signed out';

  @override
  String get clientProfileSharedOpeningSettings => 'Opening settings';

  @override
  String get clientProfileSharedSaveFailed => 'Couldn’t save';

  @override
  String get clientProfileHubTitle => 'Profile';

  @override
  String get clientProfileHubAccount => 'Account';

  @override
  String get clientProfileHubVerified => 'Verified';

  @override
  String get clientProfileHubRowWedding => 'Wedding';

  @override
  String get clientProfileHubRowBookings => 'Bookings';

  @override
  String get clientProfileHubRowVouchers => 'Vouchers';

  @override
  String get clientProfileHubRowVisits => 'Visits';

  @override
  String get clientProfileHubRowReceipts => 'Receipts';

  @override
  String get clientProfileHubRowSaved => 'Saved';

  @override
  String get clientProfileHubRowPersonal => 'Personal info';

  @override
  String get clientProfileHubRowNotifications => 'Notifications';

  @override
  String get clientProfileHubCountPaid => 'Paid';

  @override
  String get clientProfileHubCountReady => 'Ready';

  @override
  String get clientProfileHubCountUpcoming => 'Upcoming';

  @override
  String get clientProfileHubCountHalls => 'Halls';

  @override
  String get clientProfileDigitsTitle => 'Digits';

  @override
  String get clientProfileLegalTitle => 'Terms and privacy';

  @override
  String get clientProfileWedTitle => 'Wedding info';

  @override
  String get clientProfileWedRole => 'I am';

  @override
  String get clientProfileWedRoleBride => 'Bride';

  @override
  String get clientProfileWedRoleGroom => 'Groom';

  @override
  String get clientProfileWedRoleFamily => 'Family';

  @override
  String get clientProfileWedRolePlanner => 'Wedding planner';

  @override
  String get clientProfileWedName => 'Your name';

  @override
  String get clientProfileWedPartnerDefault => 'Partner’s name';

  @override
  String get clientProfileWedPartnerGroom => 'Groom’s name';

  @override
  String get clientProfileWedPartnerBride => 'Bride’s name';

  @override
  String get clientProfileWedPartnerCouple => 'Couple’s names';

  @override
  String get clientProfileWedDate => 'Wedding date';

  @override
  String get clientProfileWedCountdown => 'Days to go';

  @override
  String clientProfileWedDaysUnit(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileWedGuests => 'Guests';

  @override
  String get clientProfileWedLadies => 'Ladies';

  @override
  String get clientProfileWedMen => 'Men';

  @override
  String get clientProfileWedBudget => 'Venue and catering';

  @override
  String get clientProfileWedAreas => 'Areas';

  @override
  String get clientProfileWedTotal => 'Total budget';

  @override
  String get clientProfileWedDiffersAction => 'Use date';

  @override
  String get clientProfileWedDateUpdated => 'Date updated';

  @override
  String get clientProfilePersTitle => 'Personal info';

  @override
  String get clientProfilePersName => 'Name';

  @override
  String get clientProfilePersNameError => 'Add your name';

  @override
  String get clientProfilePersMonogram => 'Monogram';

  @override
  String get clientProfilePersEmail => 'Email';

  @override
  String get clientProfilePersEmailError => 'Check the email';

  @override
  String get clientProfilePersPhone => 'Phone';

  @override
  String get clientProfilePersPhoneChange => 'Change';

  @override
  String get clientProfilePersPhoneNote =>
      'Venues and providers see your number only for requests you send them.';

  @override
  String get clientProfilePersPhoneNoteTitle => 'Your number';

  @override
  String get clientProfilePersMethods => 'Sign in';

  @override
  String get clientProfilePersMethodWhatsapp => 'WhatsApp';

  @override
  String get clientProfilePersMethodApple => 'Apple';

  @override
  String get clientProfilePersMethodGoogle => 'Google';

  @override
  String get clientProfilePersMethodHidden => 'Hidden email';

  @override
  String get clientProfilePersMethodLinked => 'Linked';

  @override
  String get clientProfilePersMethodNotLinked => 'Unlinked';

  @override
  String get clientProfilePhoneTitle => 'Change number';

  @override
  String get clientProfilePhoneNew => 'New number';

  @override
  String get clientProfilePhoneSend => 'Send code';

  @override
  String clientProfilePhoneErrorDigits(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString digits',
      one: '$countString digit',
    );
    return 'Needs $_temp0';
  }

  @override
  String get clientProfilePhoneDone => 'Number updated';

  @override
  String get clientProfileNotifTitle => 'Notifications';

  @override
  String get clientProfileNotifDenied => 'Off on this phone';

  @override
  String get clientProfileNotifGroupAlways => 'Always on';

  @override
  String get clientProfileNotifRequests => 'Requests';

  @override
  String get clientProfileNotifVouchers => 'Vouchers';

  @override
  String get clientProfileNotifVisits => 'Visits';

  @override
  String get clientProfileNotifGroupReminders => 'Reminders';

  @override
  String get clientProfileNotifConfirm => 'Confirm request';

  @override
  String get clientProfileNotifConfirmFact => 'Time to confirm';

  @override
  String get clientProfileNotifVisitReminders => 'Visit';

  @override
  String get clientProfileNotifVoucherExpiry => 'Voucher ending';

  @override
  String get clientProfileNotifMilestones => 'Countdown';

  @override
  String get clientProfileNotifGroupMarketing => 'Offers and news';

  @override
  String get clientProfileNotifOffers => 'Venue offers';

  @override
  String get clientProfileNotifPriceDrops => 'Price drops';

  @override
  String get clientProfileNotifNewVenues => 'New halls';

  @override
  String get clientProfileNotifFrequencyTitle => 'Frequency';

  @override
  String clientProfileNotifFrequency(int count, int days) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString messages',
      one: '$countString message',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString days',
      one: '$daysString day',
    );
    return 'At most $_temp0 a week, and none in the final $_temp1 before your wedding.';
  }

  @override
  String get clientProfileNotifChannels => 'Send by';

  @override
  String get clientProfileNotifChannelPush => 'App';

  @override
  String get clientProfileNotifChannelWhatsapp => 'WhatsApp';

  @override
  String get clientProfileNotifChannelEmail => 'Email';

  @override
  String get clientProfileNotifChannelEmailAdd => 'Add email';

  @override
  String get clientProfileNotifQuiet => 'Quiet hours';

  @override
  String get clientProfileNotifQuietOffers => 'Offers';

  @override
  String get clientProfileNotifQuietAlerts => 'Alerts';

  @override
  String get clientProfileNotifPhone => 'Phone';

  @override
  String clientProfileSetBiometric(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'face': 'Face ID',
      'touch': 'Touch ID',
      'other': 'Fingerprint',
    });
    return '$_temp0';
  }

  @override
  String get clientProfileSetBiometricHint => 'Set up in phone settings';

  @override
  String get clientProfileSetBiometricOff => 'Turned off';

  @override
  String get clientProfileSetLocation => 'Location';

  @override
  String get clientProfileSetLocationValue => 'While using';

  @override
  String get clientProfileSetUsage => 'Usage data';

  @override
  String get clientProfileSetUsageDetail =>
      'Helps us improve Ghazal. Never includes payment details.';

  @override
  String get clientProfileDelTitle => 'Delete account';

  @override
  String get clientProfileDelItemData => 'Personal data';

  @override
  String get clientProfileDelItemPlans => 'Plans';

  @override
  String get clientProfileDelOutAnonymised => 'Anonymised';

  @override
  String get clientProfileDelOutKept => 'Kept';

  @override
  String get clientProfileDelOutRemoved => 'Removed';

  @override
  String get clientProfileDelOutWithdrawn => 'Withdrawn';

  @override
  String get clientProfileDelDetailTitle => 'What happens';

  @override
  String get clientProfileDelSheetData => 'Your personal data is anonymised.';

  @override
  String get clientProfileDelSheetReceipts =>
      'Voucher receipts and ledger records are kept, as the law requires.';

  @override
  String get clientProfileDelSheetSaved =>
      'Saved halls, checklist and budget are removed.';

  @override
  String get clientProfileDelSheetApple =>
      'Sign in with Apple access is revoked.';

  @override
  String clientProfileDelSheetRequest(String venue) {
    return 'Your pending request to $venue will be withdrawn, and its voucher ends with your account.';
  }

  @override
  String clientProfileDelVoucher(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString vouchers ready',
      one: 'Voucher ready',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileDelVoucherRefund => 'Use voucher';

  @override
  String clientProfileDelVoucherDetailRefund(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $countString vouchers ready. Use them first: once your account is deleted they end and do not come back.',
      one: 'You have a voucher ready. Use it first: once your account is deleted it ends and does not come back.',
    );
    return '$_temp0';
  }

  @override
  String clientProfileDelVoucherDetailEnds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You have $countString vouchers ready. They end with your account, so use them first if you still need them.',
      one: 'You have a voucher ready. It ends with your account, so use it first if you still need it.',
    );
    return '$_temp0';
  }

  @override
  String get clientProfileDelUndone => 'Can’t be undone';

  @override
  String get clientProfileDelDeleting => 'Deleting';

  @override
  String get clientProfileDelSuccessTitle => 'Account deleted';

  @override
  String get clientProfileDelSuccessDetail =>
      'Your personal data is anonymised. Receipts are kept as the law requires. You can create a new account any time.';

  @override
  String get clientProfileDelErrorTitle => 'Couldn’t delete';

  @override
  String get clientProfileDelErrorDetail =>
      'Nothing was changed. Try again, or contact Support.';

  @override
  String get clientProfileDelBlockedTitle => 'Deletion paused';

  @override
  String clientProfileDelBlockedDetail(String venue, String date) {
    return 'Deletion is paused while your booking at $venue on $date is confirmed. Cancel it, or request deletion after the event.';
  }

  @override
  String clientProfileDelBlockedApprovedDetail(String venue) {
    return 'Deletion is paused while $venue is waiting for you to confirm the approved request. Confirm it or cancel it first.';
  }

  @override
  String get clientProfileDelBlockedSchedule => 'Schedule deletion';

  @override
  String get clientProfileDelBlockedOpen => 'Open request';

  @override
  String get clientProfileDelBlockedCancel => 'Cancel booking';

  @override
  String get clientProfileDelBlockedCancelRequest => 'Cancel request';

  @override
  String get clientProfileDelScheduledTitle => 'Deletion scheduled';

  @override
  String get clientProfileDelScheduledCancel => 'Cancel deletion';

  @override
  String get clientProfileDelScheduledCancelled => 'Deletion cancelled';

  @override
  String clientReviewsRewardsStarCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stars',
      one: '$countString star',
    );
    return '$_temp0';
  }

  @override
  String clientReviewsRewardsStarsAndBelow(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString stars and below',
      one: '$countString star and below',
    );
    return '$_temp0';
  }

  @override
  String get clientReviewsRewardsAudienceWomen => 'Ladies’ reception';

  @override
  String get clientReviewsRewardsAudienceMen => 'Men’s reception';

  @override
  String get clientReviewsRewardsAudienceMixed => 'Mixed reception';

  @override
  String get clientReviewsRewardsRating => 'Rating';

  @override
  String get clientReviewsRewardsGuest => 'Guest';

  @override
  String get clientReviewsRewardsInReview => 'In review';

  @override
  String clientReviewsRewardsOpens(String date) {
    return 'Opens $date';
  }

  @override
  String clientReviewsRewardsOpensName(String date) {
    return 'Reviews open after your event on $date.';
  }

  @override
  String get clientReviewsRewardsShowMore => 'Show more';

  @override
  String get clientReviewsRewardsListTitle => 'Reviews';

  @override
  String get clientReviewsRewardsListWrite => 'Write review';

  @override
  String get clientReviewsRewardsListEvent => 'Your event';

  @override
  String get clientReviewsRewardsListSignIn => 'Sign in';

  @override
  String get clientReviewsRewardsListSignInName => 'to review your event';

  @override
  String get clientReviewsRewardsListInfoTitle => 'Verified reviews';

  @override
  String get clientReviewsRewardsListInfoReal =>
      'Only guests with a completed booking can review.';

  @override
  String get clientReviewsRewardsListInfoVenue =>
      'Venues reply once. They cannot edit or remove reviews.';

  @override
  String get clientReviewsRewardsListInfoNew =>
      'Be the first to review after your event.';

  @override
  String get clientReviewsRewardsListFilterLabel => 'Filter reviews';

  @override
  String get clientReviewsRewardsListFilterPhotos => 'Photos';

  @override
  String get clientReviewsRewardsListSortRecent => 'Recent';

  @override
  String get clientReviewsRewardsListSortHighest => 'Highest';

  @override
  String get clientReviewsRewardsListSortLowest => 'Lowest';

  @override
  String get clientReviewsRewardsListSortTitle => 'Sort';

  @override
  String get clientReviewsRewardsListMore => 'More options for this review';

  @override
  String get clientReviewsRewardsListMoreReviews => 'More';

  @override
  String get clientReviewsRewardsListVerified => 'Verified booking';

  @override
  String clientReviewsRewardsListReplyFrom(String venue) {
    return 'Reply from $venue';
  }

  @override
  String get clientReviewsRewardsListReportTitle => 'Report';

  @override
  String get clientReviewsRewardsListReasonAbusive => 'Abusive';

  @override
  String get clientReviewsRewardsListReasonNotVenue => 'Not this venue';

  @override
  String get clientReviewsRewardsListReasonPeople => 'Shows people';

  @override
  String get clientReviewsRewardsListReasonOther => 'Other';

  @override
  String get clientReviewsRewardsListReportReason => 'Pick a reason';

  @override
  String get clientReviewsRewardsListReportSent => 'Report sent';

  @override
  String get clientReviewsRewardsListReported => 'Reported';

  @override
  String get clientReviewsRewardsWriteTitle => 'Write review';

  @override
  String clientReviewsRewardsWritePrompt(String venue) {
    return 'How was $venue?';
  }

  @override
  String get clientReviewsRewardsWriteOverall => 'Overall';

  @override
  String get clientReviewsRewardsWriteStar1 => 'Poor';

  @override
  String get clientReviewsRewardsWriteStar2 => 'Fair';

  @override
  String get clientReviewsRewardsWriteStar3 => 'Good';

  @override
  String get clientReviewsRewardsWriteStar4 => 'Very good';

  @override
  String get clientReviewsRewardsWriteStar5 => 'Excellent';

  @override
  String get clientReviewsRewardsWriteCatVenue => 'Venue';

  @override
  String get clientReviewsRewardsWriteCatFood => 'Food';

  @override
  String get clientReviewsRewardsWriteCatService => 'Service';

  @override
  String get clientReviewsRewardsWriteCatValue => 'Value';

  @override
  String get clientReviewsRewardsWriteTextLabel => 'Comment';

  @override
  String get clientReviewsRewardsWriteMediaTitle => 'Photos';

  @override
  String get clientReviewsRewardsWriteMediaNoPeople => 'No people';

  @override
  String get clientReviewsRewardsWriteMediaInfoTitle => 'Review rules';

  @override
  String get clientReviewsRewardsWriteMediaRule =>
      'Photos and videos showing people can’t be published.';

  @override
  String get clientReviewsRewardsWriteMediaAllowed =>
      'The hall, décor, food and details are welcome.';

  @override
  String get clientReviewsRewardsWriteMediaChecked =>
      'Reviews are checked before they appear. Photos wait for our team and only you see them.';

  @override
  String get clientReviewsRewardsWriteMediaAdd => 'Add photo or video';

  @override
  String get clientReviewsRewardsWriteMediaUploading => 'Uploading';

  @override
  String get clientReviewsRewardsWriteMediaRejected => 'People';

  @override
  String get clientReviewsRewardsWriteMediaRejectedNote =>
      'This photo can’t be published because it shows people. Remove it, or add another.';

  @override
  String get clientReviewsRewardsWriteMediaRemove => 'Remove this photo';

  @override
  String get clientReviewsRewardsWriteNameHide => 'Hide name';

  @override
  String get clientReviewsRewardsWriteSubmitReason => 'Add a rating';

  @override
  String get clientReviewsRewardsWriteOffline => 'You’re offline. Draft saved.';

  @override
  String get clientReviewsRewardsWriteOfflineReason => 'Connect to send';

  @override
  String get clientReviewsRewardsWriteError => 'Not sent. Draft saved.';

  @override
  String get clientReviewsRewardsWriteLockedAction => 'View booking';

  @override
  String get clientReviewsRewardsWriteDoneTitle => 'Thank you';

  @override
  String get clientReviewsRewardsWriteDoneHelper =>
      'Appears after a quick check';

  @override
  String get clientReviewsRewardsWriteDoneSee => 'See reviews';

  @override
  String get clientReviewsRewardsWriteAlreadyTitle => 'Already reviewed';

  @override
  String get clientSavedCompareSavedTitle => 'Saved';

  @override
  String get clientSavedCompareSavedTabsLabel => 'Saved items';

  @override
  String clientSavedCompareSavedSummaryFree(num free, num total, String date) {
    final intl.NumberFormat freeNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String freeString = freeNumberFormat.format(free);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$freeString of $totalString halls free on $date';
  }

  @override
  String clientSavedCompareSavedSummaryOneFree(String date) {
    return 'Free on $date';
  }

  @override
  String clientSavedCompareSavedSummaryOneBusy(String date) {
    return 'Not free on $date';
  }

  @override
  String get clientSavedCompareSavedSelect => 'Select';

  @override
  String get clientSavedCompareSavedSelectNeedTwo => 'Select at least two';

  @override
  String clientSavedCompareSavedSelectRow(String name) {
    return 'Select $name';
  }

  @override
  String clientSavedCompareSavedDeselectRow(String name) {
    return 'Deselect $name';
  }

  @override
  String clientSavedCompareSavedAvailFree(String date) {
    return 'Still free on $date';
  }

  @override
  String get clientSavedCompareSavedAvailHeld => 'On hold';

  @override
  String clientSavedCompareSavedAvailBooked(String date) {
    return 'Booked on $date';
  }

  @override
  String get clientSavedCompareSavedSavingChanged => 'Saving changed';

  @override
  String clientSavedCompareSavedVoucherReadyOpen(String name) {
    return 'Open your voucher for $name';
  }

  @override
  String get clientSavedCompareSavedUnlisted => 'Unlisted';

  @override
  String get clientSavedCompareSavedRemoved => 'Removed';

  @override
  String get clientSavedCompareSavedGuestBanner => 'This phone only';

  @override
  String get clientSavedCompareSavedGuestSignIn => 'Sign in';

  @override
  String get clientSavedCompareLastUpdated => 'Last updated';

  @override
  String get clientSavedCompareSavedEmptyVenuesTitle => 'No halls saved';

  @override
  String get clientSavedCompareSavedEmptyVenuesAction => 'Browse halls';

  @override
  String get clientSavedCompareSavedEmptyServicesTitle => 'No services saved';

  @override
  String get clientSavedCompareSavedEmptyServicesAction => 'Browse services';

  @override
  String get clientSavedCompareSavedEmptyPackagesTitle => 'No packages saved';

  @override
  String get clientSavedCompareSavedEmptyPackagesAction => 'See packages';

  @override
  String get clientSavedCompareSavedPlannerLabel => 'Wedding planner';

  @override
  String get clientSavedCompareSavedFrom => 'From';

  @override
  String get clientSavedCompareFactGuests => 'Guests';

  @override
  String get clientSavedCompareFactDate => 'Date';

  @override
  String get clientSavedCompareFactFreeHalls => 'Halls free on your date';

  @override
  String get clientSavedCompareFactWomen => 'Ladies';

  @override
  String get clientSavedCompareFactMen => 'Men';

  @override
  String get clientSavedCompareFactMixed => 'Mixed';

  @override
  String get clientSavedCompareFactEdit => 'Edit your brief';

  @override
  String get clientSavedCompareTrayTitle => 'Compare';

  @override
  String get clientSavedCompareTrayAddOne => 'Add one more';

  @override
  String clientSavedCompareTrayAction(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Compare ($countString)';
  }

  @override
  String clientSavedCompareTrayRemove(String name) {
    return 'Remove $name from compare';
  }

  @override
  String clientSavedCompareTrayBadge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Open your comparison, $countString halls',
      one: 'Open your comparison, $countString hall',
      zero: 'Your comparison is empty',
    );
    return '$_temp0';
  }

  @override
  String get clientSavedCompareReplaceTitle => 'Replace which one?';

  @override
  String clientSavedCompareReplaceBody(num max, String name) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'You can compare up to $maxString halls. Choose the one $name will replace.';
  }

  @override
  String get clientSavedCompareReplaceDone => 'Comparison updated';

  @override
  String get clientSavedCompareCompareTitle => 'Compare';

  @override
  String get clientSavedCompareCompareLinkCopied => 'Link copied';

  @override
  String get clientSavedCompareCompareRowAvailability => 'Availability';

  @override
  String get clientSavedCompareCompareRowPrice => 'Price';

  @override
  String get clientSavedCompareCompareRowPriceFrom => 'From price';

  @override
  String get clientSavedCompareCompareRowCapacity => 'Largest hall holds';

  @override
  String get clientSavedCompareCompareRowSetting => 'Setting';

  @override
  String get clientSavedCompareCompareRowValet => 'Valet';

  @override
  String get clientSavedCompareCompareRowParking => 'Free parking';

  @override
  String get clientSavedCompareCompareRowBridal => 'Bridal suite';

  @override
  String get clientSavedCompareCompareRowBuffet => 'Buffet';

  @override
  String get clientSavedCompareCompareRowPhotography => 'Photography';

  @override
  String get clientSavedCompareCompareRowRating => 'Rating';

  @override
  String clientSavedCompareCompareRowDistance(String origin) {
    return 'Drive from $origin';
  }

  @override
  String clientSavedCompareCompareDriveMinutes(num minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String get clientSavedCompareCompareRowPackages => 'Packages';

  @override
  String get clientSavedCompareCompareRowHow => 'Booking channel';

  @override
  String get clientSavedCompareCompareRowPhotos => 'Photos';

  @override
  String get clientSavedCompareCompareValHowVoucher => 'With voucher';

  @override
  String get clientSavedCompareCompareValHowStandard => 'Standard only';

  @override
  String get clientSavedCompareCompareValHowOfficial => 'Official channel';

  @override
  String get clientSavedCompareCompareValIncluded => 'Included';

  @override
  String get clientSavedCompareCompareValExtra => 'Extra cost';

  @override
  String get clientSavedCompareCompareValNotOffered => 'Not offered';

  @override
  String get clientSavedCompareCompareValIndoor => 'Indoor';

  @override
  String get clientSavedCompareCompareValOutdoor => 'Outdoor';

  @override
  String get clientSavedCompareCompareValWomenOnly => 'Female only';

  @override
  String get clientSavedCompareCompareValAllowed => 'Allowed';

  @override
  String get clientSavedCompareCompareValNotAllowed => 'Not allowed';

  @override
  String get clientSavedCompareCompareValBelow => 'Below your guests';

  @override
  String get clientSavedCompareCompareValFrom => 'From';

  @override
  String get clientSavedCompareCompareShowPackages => 'Show packages';

  @override
  String get clientSavedCompareCompareHidePackages => 'Hide packages';

  @override
  String get clientSavedCompareCompareBadgeRated => 'Top rated';

  @override
  String get clientSavedCompareCompareBadgeLowest => 'Cheapest';

  @override
  String get clientSavedCompareCompareBadgeClosest => 'Closest';

  @override
  String get clientSavedCompareCompareActionVoucher => 'Voucher';

  @override
  String get clientSavedCompareCompareActionView => 'View';

  @override
  String get clientSavedCompareCompareActionDates => 'Dates';

  @override
  String get clientSavedCompareCompareActionOfficial => 'Official';

  @override
  String clientSavedCompareCompareActionFor(String action, String name) {
    return '$action: $name';
  }

  @override
  String clientSavedCompareCompareOpen(String name) {
    return 'Open $name';
  }

  @override
  String clientSavedCompareComparePick(String name) {
    return 'Choose $name';
  }

  @override
  String clientSavedCompareCompareUnpick(String name) {
    return 'Chosen: $name';
  }

  @override
  String clientSavedCompareComparePicked(String name) {
    return '$name is your choice.';
  }

  @override
  String get clientSavedCompareCompareSetDate => 'Set date';

  @override
  String get clientSavedCompareCompareFewerTitle => 'Add a second hall';

  @override
  String get clientSavedCompareCompareFewerAction => 'Choose hall';

  @override
  String get clientSavedCompareCompareDiffLabel => 'Rows shown';

  @override
  String get clientSavedCompareCompareDiffOnly => 'Differences';

  @override
  String get clientSavedCompareCompareDiffAll => 'All';

  @override
  String get clientSavedCompareKeyTitle => 'Symbols';

  @override
  String get clientSavedCompareKeyBest => 'Best';

  @override
  String get clientSavedCompareKeySave => 'Saving';

  @override
  String clientSavedCompareCompareHidden(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString matching rows hidden',
      one: '$countString matching row hidden',
    );
    return '$_temp0';
  }

  @override
  String get clientServicesFrom => 'From';

  @override
  String clientServicesOpenName(String name) {
    return 'Open $name';
  }

  @override
  String get clientServicesArea => 'Area';

  @override
  String get clientServicesProviders => 'Providers';

  @override
  String get clientServicesSoon => 'Soon';

  @override
  String get clientServicesVoucherAvailable => 'Voucher prices available';

  @override
  String get clientServicesSavedView => 'View';

  @override
  String get clientServicesRequestSent => 'Request sent';

  @override
  String get clientServicesReconnect => 'Reconnect to continue';

  @override
  String get clientServicesHowTitle => 'How it works';

  @override
  String get clientServicesUnitEvent => '/event';

  @override
  String get clientServicesUnitCake => '/cake';

  @override
  String get clientServicesUnitSession => '/session';

  @override
  String get clientServicesUnitDress => '/dress';

  @override
  String get clientServicesUnitSuit => '/suit';

  @override
  String get clientServicesUnitCard => '/card';

  @override
  String get clientServicesUnitBooking => '/booking';

  @override
  String get clientServicesUnitPackage => '/package';

  @override
  String get clientServicesHubTitle => 'Services';

  @override
  String get clientServicesHubSwitchLabel => 'Browse';

  @override
  String get clientServicesHubGroupsLabel => 'Categories';

  @override
  String get clientServicesHubMoreHeading => 'More';

  @override
  String get clientServicesHubPlannerTitle => 'Wedding planner';

  @override
  String get clientServicesHubSavedTitle => 'Saved';

  @override
  String get clientServicesHubGovernmentNote => 'Add catering and decor';

  @override
  String clientServicesHubVoucherLine(String fee) {
    return 'Get a $fee Ghazal voucher on a provider’s page to unlock lower prices. You always pay the provider directly.';
  }

  @override
  String get clientServicesListTitle => 'Providers';

  @override
  String get clientServicesListSiblings => 'Related services';

  @override
  String get clientServicesListFemaleTeam => 'Female team';

  @override
  String clientServicesListGridLabel(String category) {
    return 'Providers in $category';
  }

  @override
  String get clientServicesListNoResultsTitle => 'No matches';

  @override
  String get clientServicesListClear => 'Clear filters';

  @override
  String get clientServicesListEmptyTitle => 'No providers yet';

  @override
  String get clientServicesFilterTitle => 'Filters';

  @override
  String get clientServicesFilterLabel => 'Filter';

  @override
  String get clientServicesSheetSortLabel => 'Sort';

  @override
  String clientServicesSheetUpTo(String price) {
    return 'Up to $price';
  }

  @override
  String clientServicesSheetRatingAtLeast(String rating) {
    return '$rating+';
  }

  @override
  String clientServicesSheetShow(String count) {
    return 'Show $count';
  }

  @override
  String get clientServicesSortRecommended => 'Featured';

  @override
  String get clientServicesSortPrice => 'Price';

  @override
  String get clientServicesSortRating => 'Rating';

  @override
  String get clientServicesProfileTitle => 'Provider';

  @override
  String clientServicesProfileHeroLabel(String name) {
    return 'Portfolio photos of $name';
  }

  @override
  String get clientServicesProfileReply => 'Replies within';

  @override
  String get clientServicesProfileVerified => 'Verified';

  @override
  String get clientServicesProfileEventTitle => 'Event';

  @override
  String get clientServicesProfileEventInfoTitle => 'The date';

  @override
  String get clientServicesProfileAvailabilityBody =>
      'Availability is confirmed by the provider in chat.';

  @override
  String get clientServicesProfileEventNote =>
      'Your voucher is tied to this date and package.';

  @override
  String get clientServicesProfileAsk => 'Ask';

  @override
  String get clientServicesProfilePackagesTitle => 'Packages';

  @override
  String clientServicesProfilePackageChoose(String name) {
    return 'Choose $name';
  }

  @override
  String clientServicesProfilePackageChosen(String name) {
    return '$name, chosen';
  }

  @override
  String get clientServicesProfileIncludes => 'Includes';

  @override
  String get clientServicesProfileBudgetTitle => 'Add to budget';

  @override
  String get clientServicesProfileReviewsTitle => 'Reviews';

  @override
  String get clientServicesProfileGetVoucher => 'Get voucher';

  @override
  String get clientServicesProfileRequest => 'Request quote';

  @override
  String get clientServicesProfileOpenChat => 'Open chat';

  @override
  String get clientServicesHowRequestLabel => 'Request';

  @override
  String get clientServicesHowSettleLabel => 'Pay provider';

  @override
  String clientServicesHowPayTitle(String fee) {
    return 'Pay $fee online';
  }

  @override
  String get clientServicesHowPayBody =>
      'Use KNET, a card, Apple Pay or Google Pay. The voucher is tied to this provider and package.';

  @override
  String get clientServicesHowRequestTitle => 'Request at the voucher price';

  @override
  String clientServicesHowRequestBody(String hours) {
    return 'The provider answers. After approval you have $hours to confirm.';
  }

  @override
  String get clientServicesHowSettleTitle => 'Pay the provider directly';

  @override
  String get clientServicesHowSettleBody =>
      'Settle as the provider agrees and show your voucher code. Ghazal takes no payment for the service.';

  @override
  String get clientServicesQuoteTitle => 'Request quote';

  @override
  String get clientServicesQuotePackage => 'Package';

  @override
  String get clientServicesQuoteDate => 'Event date';

  @override
  String get clientServicesQuoteDatePlaceholder => 'Choose a date';

  @override
  String get clientServicesQuoteVenue => 'Venue';

  @override
  String get clientServicesQuoteGuests => 'Guests';

  @override
  String get clientServicesQuoteNoteLabel => 'Note for the provider';

  @override
  String get clientServicesQuoteNotePlaceholder => 'Note';

  @override
  String get clientServicesQuoteSend => 'Send request';

  @override
  String get clientServicesQuoteDateError => 'Date needed';

  @override
  String get clientServicesQuoteGuestNote => 'Sign in to send';

  @override
  String get clientServicesQuoteThreadExists => 'Added to your chat';

  @override
  String get clientServicesQuoteErrorTitle => 'Couldn’t send';

  @override
  String get clientServicesQuoteErrorBody => 'Nothing you typed was lost.';

  @override
  String get clientServicesQuoteVoucherFailed =>
      'Your voucher is safe and nothing was charged.';

  @override
  String get clientServicesQuoteAttachTitle => 'Use voucher';

  @override
  String get clientServicesQuoteAttachInfoTitle => 'Voucher request';

  @override
  String get clientServicesQuoteAttachNote =>
      'Your enquiry becomes a request at the voucher price. The provider can accept, decline or suggest another date.';

  @override
  String get clientServicesQuoteNextTitle => 'What’s next';

  @override
  String get clientServicesQuoteViewRequest => 'View request';

  @override
  String clientServicesQuoteVoucherSuccessBody(String vendor, String hours) {
    return '$vendor will answer in Messages. Once they accept, you have $hours to confirm.';
  }

  @override
  String get clientShellTabBarLabel => 'Main navigation';

  @override
  String get clientShellTabDiscover => 'Discover';

  @override
  String get clientShellTabSaved => 'Saved';

  @override
  String get clientShellTabMyWedding => 'My Wedding';

  @override
  String get clientShellTabMessages => 'Messages';

  @override
  String get clientShellTabProfile => 'Profile';

  @override
  String clientShellTabUnread(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString unread messages',
      one: '$countString unread message',
    );
    return '$_temp0';
  }

  @override
  String clientShellGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get clientShellGreetingAnonymous => 'Hello';

  @override
  String get clientShellBriefTitle => 'Your brief';

  @override
  String get clientShellBriefEditLabel => 'Edit date, guests, area and budget';

  @override
  String get clientShellBriefDate => 'Date';

  @override
  String get clientShellBriefGuests => 'Guests';

  @override
  String get clientShellBriefArea => 'Area';

  @override
  String get clientShellBriefBudget => 'Venue and catering budget';

  @override
  String get clientShellBriefNotDecided => 'Not decided';

  @override
  String get clientShellBriefFlexibleMonth => 'Flexible month';

  @override
  String get clientShellSwitchVenues => 'Venues';

  @override
  String get clientShellSwitchServices => 'Services';

  @override
  String get clientShellSwitchPackages => 'Packages';

  @override
  String clientShellCompareTray(String pair) {
    return 'Compare ($pair)';
  }

  @override
  String get clientVenueTierPrestige => 'Prestige';

  @override
  String get clientVenueTierSignature => 'Signature';

  @override
  String get clientVenueTierClassic => 'Classic';

  @override
  String get clientVenueTierGovernment => 'Government hall';

  @override
  String get clientVenueAboutTitle => 'About';

  @override
  String get clientVenueTypeHotel => 'Hotel';

  @override
  String get clientVenueTypeHall => 'Hall';

  @override
  String get clientVenueTypeResort => 'Resort';

  @override
  String get clientVenueTypeVilla => 'Villa';

  @override
  String get clientVenueTypeOutdoor => 'Outdoor';

  @override
  String get clientVenueTypeConvention => 'Convention centre';

  @override
  String clientVenueAddressLine(String block, String street) {
    return 'Block $block, $street';
  }

  @override
  String clientVenueRegionLine(String area, String governorate) {
    return '$area, $governorate';
  }

  @override
  String clientVenueHeroLabel(String venue) {
    return 'Photos of $venue';
  }

  @override
  String get clientVenueHeroOpen => 'Open the photo gallery';

  @override
  String get clientVenueNoPhotos => 'Photos coming soon';

  @override
  String get clientVenueZoneHall => 'Hall';

  @override
  String get clientVenueZoneStage => 'Stage and kosha';

  @override
  String get clientVenueZoneBridal => 'Bridal suite';

  @override
  String get clientVenueZoneBuffet => 'Buffet';

  @override
  String get clientVenueZoneOutdoors => 'Outdoors';

  @override
  String get clientVenueZoneEntrance => 'Entrance and valet';

  @override
  String get clientVenueZoneLayout => 'Layouts';

  @override
  String get clientVenueZoneVideo => 'Video';

  @override
  String clientVenueZoneWithHall(String zone, String hall) {
    return '$zone, $hall';
  }

  @override
  String clientVenueGalleryLabel(String venue) {
    return 'Photo gallery of $venue';
  }

  @override
  String clientVenueGalleryCounter(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString/$totalString';
  }

  @override
  String get clientVenueGalleryZones => 'Photo zones';

  @override
  String get clientVenueVideoPlay => 'Play the video';

  @override
  String get clientVenueVideoPause => 'Pause the video';

  @override
  String get clientVenueVideoScrub => 'Video position';

  @override
  String get clientVenueVideoCaption => 'Entrance, hall, stage';

  @override
  String get clientVenueDateLabel => 'Your date';

  @override
  String get clientVenueDateChoose => 'Choose date';

  @override
  String get clientVenueDateChangeLabel => 'Change the date';

  @override
  String get clientVenueGuestsAdd => 'Add guests';

  @override
  String get clientVenueGuestsChangeLabel => 'Change the number of guests';

  @override
  String get clientVenueGuestsLabel => 'Guests';

  @override
  String get clientVenueEstimateLabel => 'Estimated total';

  @override
  String clientVenueEstimateMinimum(String guests) {
    return 'Priced for the minimum of $guests';
  }

  @override
  String get clientVenueHeldSr =>
      'Date held by another couple. You can still send a request.';

  @override
  String get clientVenueNearestTitle => 'Nearest free dates';

  @override
  String get clientVenueSeeAllDates => 'All dates';

  @override
  String clientVenueWindowApplied(String title) {
    return '$title applies to your date';
  }

  @override
  String get clientVenueHowTitle => 'How the voucher works';

  @override
  String get clientVenueThreadTitle => 'Your booking in five steps';

  @override
  String get clientVenueThreadLabel =>
      'Booking steps: voucher, request, approval, confirmation, at the venue';

  @override
  String get clientVenueThreadVoucher => 'Voucher';

  @override
  String get clientVenueThreadRequest => 'Request';

  @override
  String get clientVenueThreadApproval => 'Approval';

  @override
  String get clientVenueThreadConfirm => 'Confirm';

  @override
  String get clientVenueThreadAtVenue => 'At the venue';

  @override
  String clientVenueThreadNote(String fee, String venue) {
    return 'You pay Ghazal $fee once, for the voucher. Everything else you pay to $venue directly.';
  }

  @override
  String clientVenueResponseUsually(int hours) {
    final intl.NumberFormat hoursNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hoursString = hoursNumberFormat.format(hours);

    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hoursString hours',
      one: '$hoursString hour',
    );
    return 'Usually replies within $_temp0';
  }

  @override
  String get clientVenueOwnedView => 'View';

  @override
  String get clientVenueHallsTitle => 'Halls';

  @override
  String get clientVenueHallSwitchLabel => 'Choose a hall';

  @override
  String get clientVenueHallFacts => 'Facts';

  @override
  String get clientVenueHallCapacity => 'Capacity';

  @override
  String get clientVenueHallIndoor => 'Indoor';

  @override
  String get clientVenueHallOutdoor => 'Outdoor';

  @override
  String get clientVenueHallMixed => 'Indoor and outdoor';

  @override
  String get clientVenueHallExclusive => 'One wedding a day';

  @override
  String get clientVenueHallExclusiveShort => 'Exclusive';

  @override
  String get clientVenueSessionSwitchLabel => 'Choose a session';

  @override
  String get clientVenueMore => 'Show more';

  @override
  String get clientVenueLess => 'Show less';

  @override
  String get clientVenuePackagesTitle => 'Packages';

  @override
  String get clientVenuePackagesDetails => 'Package details';

  @override
  String get clientVenuePackagesNone => 'None on this date';

  @override
  String get clientVenuePkgMinGuests => 'Minimum guests';

  @override
  String get clientVenuePkgIncludes => 'Included';

  @override
  String get clientVenuePkgIncludesAll => 'Show all inclusions';

  @override
  String get clientVenuePkgMenu => 'Menu';

  @override
  String get clientVenuePkgExtras => 'Extras';

  @override
  String get clientVenuePkgSave => 'Save package';

  @override
  String get clientVenuePkgSaved => 'Remove from saved packages';

  @override
  String get clientVenuePkgTierWeekday => 'Weekday';

  @override
  String get clientVenuePkgTierWeekend => 'Weekend';

  @override
  String get clientVenuePkgTierSeason => 'Season';

  @override
  String get clientVenuePkgTierHoliday => 'Holiday';

  @override
  String get clientVenuePkgTierSpecialDate => 'Special date';

  @override
  String clientVenuePkgTierLabel(String date) {
    return 'Rate for $date';
  }

  @override
  String get clientVenuePkgOverTitle => 'Over capacity';

  @override
  String clientVenuePkgOverCap(String hall, String guests) {
    return '$hall holds up to $guests. You can choose another hall or fewer guests.';
  }

  @override
  String clientVenuePkgUnavailable(String date) {
    return 'Not available on $date';
  }

  @override
  String get clientVenueFacilitiesTitle => 'Facilities';

  @override
  String get clientVenueFacilitiesAll => 'All facilities';

  @override
  String get clientVenueFacIncluded => 'Included';

  @override
  String get clientVenueFacExtra => 'Extra';

  @override
  String get clientVenueFacOff => 'Not offered';

  @override
  String get clientVenuePoliciesTitle => 'Policies';

  @override
  String get clientVenuePolicyTerms => 'Terms';

  @override
  String get clientVenuePolicyRules => 'Hall rules';

  @override
  String get clientVenuePolicyGood => 'Good to know';

  @override
  String get clientVenueFaqTitle => 'Questions';

  @override
  String get clientVenueReviewsTitle => 'Reviews';

  @override
  String clientVenueReviewsAll(String count) {
    return 'See all $count reviews';
  }

  @override
  String get clientVenueReviewsNone => 'No reviews yet';

  @override
  String get clientVenueCatVenue => 'Venue';

  @override
  String get clientVenueCatFood => 'Food';

  @override
  String get clientVenueCatService => 'Service';

  @override
  String get clientVenueCatValue => 'Value';

  @override
  String get clientVenueReviewAnon => 'Guest';

  @override
  String get clientVenueReviewReply => 'The venue replied';

  @override
  String get clientVenueLocationTitle => 'Location';

  @override
  String clientVenueDriveFrom(String origin) {
    return 'Drive from $origin';
  }

  @override
  String get clientVenueMapsShort => 'Maps';

  @override
  String get clientVenueMapsTitle => 'Maps';

  @override
  String get clientVenueMapsGoogle => 'Google Maps';

  @override
  String get clientVenueMapsApple => 'Apple Maps';

  @override
  String get clientVenueMapsWaze => 'Waze';

  @override
  String clientVenueMapsOpening(String app) {
    return 'Opening $app';
  }

  @override
  String get clientVenueSimilarTitle => 'Similar halls';

  @override
  String get clientVenueCtaChooseDate => 'Choose date';

  @override
  String get clientVenueCtaSeeDates => 'Free dates';

  @override
  String get clientVenueCtaGetVoucher => 'Get voucher';

  @override
  String get clientVenueCtaSendRequest => 'Send request';

  @override
  String get clientVenueCtaVisit => 'Book visit';

  @override
  String get clientVenueCtaContact => 'Contact';

  @override
  String get clientVenueCtaChangeGuests => 'Change guests';

  @override
  String get clientVenueVisitNone => 'No visit times are open at the moment';

  @override
  String get clientVenueCtaOffline => 'Reconnect';

  @override
  String clientVenueOfflineBanner(String time) {
    return 'Offline, saved $time';
  }

  @override
  String get clientVenueCompareAdded => 'Added to compare';

  @override
  String get clientVenueCompareView => 'View';

  @override
  String get clientVenueSavedRemoved => 'Removed';

  @override
  String get clientVenueSavedView => 'View';

  @override
  String get clientVenueShareCopied => 'Link copied';

  @override
  String get clientVenueDelistedTitle => 'No longer listed';

  @override
  String get clientVenueDelistedCta => 'Browse halls';

  @override
  String clientVenueTotalFor(String guests) {
    return 'Total for $guests';
  }

  @override
  String get clientVenueContactTitle => 'Contact';

  @override
  String clientVenueContactCalling(String venue) {
    return 'Calling $venue';
  }

  @override
  String get clientVenueContactWhatsapp => 'Opening WhatsApp';

  @override
  String get clientVenueContactChat => 'Message';

  @override
  String get clientVenueCalTitle => 'Dates';

  @override
  String get clientVenueCalMonthJump => 'Jump to a month';

  @override
  String get clientVenueCalMonthTitle => 'Month';

  @override
  String clientVenueCalMonthDensity(String month, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString free dates',
      one: '$countString free date',
      zero: 'no free dates',
    );
    return '$month: $_temp0';
  }

  @override
  String clientVenueCalBasis(String guests) {
    return 'Prices in KD for $guests';
  }

  @override
  String get clientVenueCalGuestsCta => 'Add guests';

  @override
  String get clientVenueCalNone => 'No free dates';

  @override
  String get clientVenueCalPickHint => 'Pick a date to see the estimate.';

  @override
  String get clientVenueCalPickFree => 'Choose one of the free dates.';

  @override
  String get clientVenueCalOccasionsLabel => 'Occasions this month';

  @override
  String clientVenueCalChosen(String date) {
    return 'Date set $date';
  }

  @override
  String get clientVenueCalUse => 'Use date';

  @override
  String get clientVenuePolTitle => 'Policies';

  @override
  String get clientVenuePolTabsLabel => 'Policy sections';

  @override
  String get clientVenuePolTabTerms => 'Terms';

  @override
  String get clientVenuePolTabRules => 'Rules';

  @override
  String get clientVenuePolTabGood => 'Good to know';

  @override
  String get clientVenuePolRulesLabel => 'Reception type';

  @override
  String get clientVenuePolChildren => 'Children';

  @override
  String get clientVenuePolDress => 'Dress code';

  @override
  String get clientVenuePolHours => 'Working hours';

  @override
  String get clientVenuePolClosures => 'Closures';

  @override
  String clientVenuePolHoursLine(String days, String open, String close) {
    return '$days: $open – $close';
  }

  @override
  String clientVenuePolClosureLine(String name, String from, String to) {
    return '$name: $from – $to';
  }

  @override
  String get clientVenueAudWomen => 'Ladies';

  @override
  String get clientVenueAudMen => 'Men';

  @override
  String get clientVenueAudMixed => 'Mixed';

  @override
  String get clientVenueRulePhotography => 'Photography';

  @override
  String get clientVenueRulePhotoFemale => 'Women only';

  @override
  String get clientVenueRuleMusic => 'Music';

  @override
  String get clientVenueRuleMusicBand => 'DJ or band';

  @override
  String get clientVenueRuleMusicLive => 'Live';

  @override
  String get clientVenueRuleMusicDuff => 'Duff only';

  @override
  String get clientVenueRuleAllowed => 'Allowed';

  @override
  String get clientVenueRuleApproval => 'With approval';

  @override
  String get clientVenueRuleNot => 'Not allowed';

  @override
  String get clientVenueRuleNone => 'None';

  @override
  String get clientVenueRuleEntrance => 'Separate entrance';

  @override
  String get clientVenueRuleCloakroom => 'Abaya cloakroom';

  @override
  String get clientVenueRulePrayer => 'Prayer room';

  @override
  String get clientVenueRuleSecurity => 'Female security';

  @override
  String get clientVenueRuleBackup => 'Indoor backup';

  @override
  String get clientVenueRuleBoys => 'Boys’ age';

  @override
  String get clientVenueRuleCatering => 'Outside catering';

  @override
  String get clientVenueRuleDecor => 'Outside decor';

  @override
  String get clientVenueRuleBukhoor => 'Bukhoor';

  @override
  String get clientVenueRuleCutoff => 'Event ends by';

  @override
  String get clientVenueRuleExtraHour => 'Extra hour';

  @override
  String clientVenueTermsVenueTitle(String venue) {
    return 'Terms of $venue';
  }

  @override
  String get clientVenueTermsVoucherTitle => 'The Ghazal voucher';

  @override
  String clientVenueTermsVoucherFee(String fee) {
    return '$fee, paid once to Ghazal';
  }

  @override
  String get clientVenueTermsVoucherBound => 'Bound to this venue and quote';

  @override
  String get clientVenueTermsDirect => 'Pay and cancel with the venue';

  @override
  String clientVenueTermsVoucherReuse(String days) {
    return 'Declined or unanswered: reuse for $days, or ask support for credit';
  }

  @override
  String clientVenueTermsVoucherConfirm(String hours) {
    return 'Confirm within $hours of approval';
  }

  @override
  String get clientVenueGovFeesTitle => 'Fees';

  @override
  String get clientVenueGovSecurity => 'Security deposit';

  @override
  String get clientVenueGovRefundable => 'Refundable';

  @override
  String get clientVenueGovHallOnly =>
      'Hall only: bring your own decor and catering.';

  @override
  String get clientVenueGovHallOnlyShort => 'Hall only';

  @override
  String get clientVenueGovFeesInfoTitle => 'About the fees';

  @override
  String get clientVenueGovRulesTitle => 'Rules';

  @override
  String get clientVenueGovRuleNoChange => 'No date changes';

  @override
  String get clientVenueGovRulePay => 'Pay on time';

  @override
  String get clientVenueGovRulePayInfo =>
      'Payment is made on the official channel within the time it states, or the booking is cancelled automatically.';

  @override
  String get clientVenueGovRuleKnet => 'KNET';

  @override
  String get clientVenueGovAvail => 'Official app';

  @override
  String get clientVenueGovCtaOfficial => 'Official booking';

  @override
  String get clientVenueGovCtaCatering => 'Find services';

  @override
  String get clientVenueGovLeaveTitle => 'Leaving Ghazal';

  @override
  String get clientVenueGovLeaveBody =>
      'Booking and payment happen on the official channel. Ghazal does not hold or guarantee it.';

  @override
  String get clientVenueGovLeaveToast => 'Opening official site';

  @override
  String get clientVenueGovSelfLink => 'Mark booked';

  @override
  String get clientVenueGovSelfTitle => 'Mark booked';

  @override
  String get clientVenueGovSelfDate => 'Date';

  @override
  String get clientVenueGovSelfFee => 'Fee paid';

  @override
  String get clientVenueGovSelfNote =>
      'This is a record for your budget, checklist and countdown only. It is not a Ghazal booking.';

  @override
  String get clientVenueGovSelfInfoTitle => 'Not a booking';

  @override
  String get clientVenueGovSelfToast => 'Saved to your wedding';

  @override
  String get clientVenueGovSelfView => 'View';

  @override
  String get clientVenueGovWhyTitle => 'Why no voucher?';

  @override
  String get clientVenueGovWhyBody =>
      'Governmental facilities have fixed official fees, so there is no Ghazal price to unlock.';

  @override
  String get clientVenueGovBrowse => 'Browse halls';

  @override
  String get clientVisitsBookTitle => 'Book a visit';

  @override
  String get clientVisitsBookAction => 'Request visit';

  @override
  String get clientVisitsInfoTitle => 'Free visit';

  @override
  String get clientVisitsInfoFree => 'A visit is free and needs no voucher.';

  @override
  String clientVisitsInfoChat(String venue) {
    return 'A chat opens with $venue and Ghazal support to confirm your visit.';
  }

  @override
  String clientVisitsInfoWindow(String minutes) {
    return 'Each window lasts $minutes minutes. Arrive at any time inside it.';
  }

  @override
  String get clientVisitsSlotDay => 'Day';

  @override
  String get clientVisitsSlotMorning => 'Morning';

  @override
  String get clientVisitsSlotAfternoon => 'Afternoon';

  @override
  String get clientVisitsSlotEvening => 'Evening';

  @override
  String get clientVisitsSlotTaken => 'Taken';

  @override
  String clientVisitsNoWeek(String date) {
    return 'Free from $date';
  }

  @override
  String get clientVisitsTakenNext => 'Next free windows';

  @override
  String get clientVisitsNotSent => 'Not sent';

  @override
  String get clientVisitsVisitors => 'Visitors';

  @override
  String clientVisitsVisitorsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString visitors',
      one: '$countString visitor',
    );
    return '$_temp0';
  }

  @override
  String get clientVisitsNoteLabel => 'Note for the venue';

  @override
  String get clientVisitsNote => 'Note';

  @override
  String get clientVisitsFactDay => 'Day';

  @override
  String get clientVisitsFactWindow => 'Arrival window';

  @override
  String get clientVisitsFactVisitors => 'Visitors';

  @override
  String get clientVisitsRequestedTitle => 'Visit requested';

  @override
  String get clientVisitsOpenChat => 'Open chat';

  @override
  String get clientVisitsBackToVenue => 'Venue';

  @override
  String get clientVisitsRedirecting => 'Opening chat';

  @override
  String get clientVisitsStay => 'Stay';

  @override
  String get clientVisitsSummary => 'Visit details';

  @override
  String get clientVisitsStepsLabel => 'Visit progress';

  @override
  String get clientVisitsStepRequest => 'Request';

  @override
  String get clientVisitsStepConfirm => 'Confirmation';

  @override
  String get clientVisitsStepWay => 'On the way';

  @override
  String get clientVisitsStepArrival => 'Arrival';

  @override
  String get clientVisitsMembersOpen => 'Chat members';

  @override
  String get clientVisitsRoleHotel => 'Hotel';

  @override
  String get clientVisitsRoleSupport => 'Support';

  @override
  String get clientVisitsMembersTitle => 'Chat members';

  @override
  String get clientVisitsMembersPrivateTitle => 'Private';

  @override
  String get clientVisitsMembersPrivate =>
      'Only these three can read this chat. Phone numbers are not shared. Ghazal support cannot be blocked.';

  @override
  String get clientVisitsMembersVenue => 'Venue page';

  @override
  String get clientVisitsMembersReport => 'Report or block';

  @override
  String get clientVisitsClosed => 'Closed';

  @override
  String get clientVisitsMessageVenue => 'Message venue';

  @override
  String get clientVisitsRecordTooShort => 'Hold to record';

  @override
  String get clientVisitsAttachTitle => 'Attach';

  @override
  String get clientVisitsPhotoViewer => 'Photos';

  @override
  String get clientVisitsGetVoucher => 'Voucher';

  @override
  String get clientVisitsConfirmedToast => 'Time confirmed';

  @override
  String get clientVisitsGuestTitle => 'Your visits';

  @override
  String get clientVisitsGuestAction => 'Sign in';

  @override
  String get clientVisitsMsgSending => 'Sending';

  @override
  String get clientVisitsMsgQueued => 'Queued';

  @override
  String get clientVisitsMsgDelete => 'Delete';

  @override
  String get clientVisitsPinLabel => 'Your visit';

  @override
  String get clientVisitsConfirmTime => 'Confirm';

  @override
  String get clientVisitsChangeOrCancel => 'Change or cancel';

  @override
  String get clientVisitsOnTheWay => 'En route';

  @override
  String get clientVisitsArrived => 'Arrived';

  @override
  String get clientVisitsNeedsConnection => 'Needs a connection';

  @override
  String get clientVisitsChooseAnother => 'Another time';

  @override
  String get clientVisitsSysOpened => 'Chat opened';

  @override
  String get clientVisitsSysConfirmed => 'Visit confirmed';

  @override
  String get clientVisitsSysProposed => 'New time suggested';

  @override
  String get clientVisitsSysDeclined => 'Time unavailable. Chat closed.';

  @override
  String get clientVisitsSysCancelled => 'Visit cancelled. Chat closed.';

  @override
  String get clientVisitsSysArrived => 'Arrival confirmed';

  @override
  String get clientVisitsSysCompleted => 'Visit complete';

  @override
  String get clientVisitsSysClosed => 'Chat closed';

  @override
  String get clientVisitsSysMissed => 'Visit missed';

  @override
  String get clientVisitsSysAccepted => 'New time accepted';

  @override
  String clientVisitsSysAsked(String when) {
    return 'You asked for $when';
  }

  @override
  String get clientVisitsTapOnTheWay => 'We are on our way.';

  @override
  String get clientVisitsTapArrived => 'We have arrived.';

  @override
  String clientVisitsDemoSupport(String name) {
    return 'Hello $name, I am Lama from Ghazal support. I am here with you and the hotel to confirm your arrival.';
  }

  @override
  String get clientVisitsDemoClient =>
      'Peace be upon you. We would like to visit the hall, my mother and I.';

  @override
  String clientVisitsDemoHotelConfirm(String name, String day, String time) {
    return 'Welcome $name. Your visit is confirmed for $day at $time, and we will meet you at the main entrance.';
  }

  @override
  String clientVisitsDemoHotelPropose(String name, String day, String time) {
    return '$name, that slot is no longer free. Could we meet you on $day at $time instead?';
  }

  @override
  String clientVisitsDemoHotelDecline(String name) {
    return 'Thank you $name. We cannot host visits at this time. You are welcome to choose another day.';
  }

  @override
  String get clientVisitsDemoHere =>
      'We have arrived, we are at the main entrance.';

  @override
  String get clientVisitsDemoPending =>
      'Is there parking close to the main entrance?';

  @override
  String clientVisitsDemoHotelAck(String name) {
    return 'Thank you $name, noted. We will see you then.';
  }

  @override
  String clientVisitsDemoHotelAckRequested(String name) {
    return 'Thank you $name. We received your request and will confirm shortly.';
  }

  @override
  String get clientVisitsListTitle => 'Visits';

  @override
  String get clientVisitsTabUpcoming => 'Upcoming';

  @override
  String get clientVisitsTabPast => 'Past';

  @override
  String get clientVisitsEmptyTitle => 'No visits';

  @override
  String get clientVisitsEmptyAction => 'See halls';

  @override
  String get clientVisitsChangeTitle => 'Your visit';

  @override
  String get clientVisitsInfoFeeTitle => 'No fee';

  @override
  String get clientVisitsInfoNoFee => 'Nothing is charged and nothing is lost.';

  @override
  String clientVisitsInfoRecord(String venue) {
    return 'The chat records the change and $venue is told.';
  }

  @override
  String get clientVisitsRowAsk => 'Another time';

  @override
  String get clientVisitsRowCancel => 'Cancel visit';

  @override
  String get clientVisitsAskAction => 'Send request';

  @override
  String get clientVisitsPickReason => 'Pick a reason';

  @override
  String get clientVisitsReasonPlans => 'Plans changed';

  @override
  String get clientVisitsReasonOtherVenue => 'Chose elsewhere';

  @override
  String get clientVisitsReasonOther => 'Other';

  @override
  String get clientVisitsKeepVisit => 'Keep visit';

  @override
  String get clientVisitsDoneAskTitle => 'Request sent';

  @override
  String clientVisitsDoneAskDetail(String venue) {
    return '$venue will answer in the chat.';
  }

  @override
  String get clientVisitsDoneCancelTitle => 'Visit cancelled';

  @override
  String clientVisitsDoneCancelDetail(String venue) {
    return 'Nothing was charged. The chat is closed and $venue was told.';
  }

  @override
  String get clientVisitsNothingChanged => 'Nothing changed';

  @override
  String get clientVouchersAskOpen => 'Open support chat';

  @override
  String clientVouchersAskText(String code) {
    return 'Hello, my voucher $code could not be used. Could you issue a credit voucher?';
  }

  @override
  String get clientVouchersAskTitle => 'Use or ask support';

  @override
  String get clientVouchersAttachedToast => 'Voucher attached';

  @override
  String clientVouchersBackCredit(String date) {
    return 'Use it again here until $date, or ask support for a credit voucher.';
  }

  @override
  String clientVouchersBackKept(String date) {
    return 'Use it again here until $date.';
  }

  @override
  String get clientVouchersBackLine => 'Back if declined';

  @override
  String get clientVouchersBrowseHalls => 'Browse halls';

  @override
  String get clientVouchersChooseAnother => 'Choose another';

  @override
  String get clientVouchersChooseLabel => 'Choose a voucher';

  @override
  String get clientVouchersCodeCopied => 'Code copied';

  @override
  String clientVouchersConsumedBody(String name) {
    return 'You cancelled at $name after confirming, so the voucher is used up.';
  }

  @override
  String get clientVouchersContact => 'Contact';

  @override
  String clientVouchersCreditBody(String validity, String confirm) {
    return 'Granted by Ghazal support. Claim it with any hall, hotel or service within $validity, then confirm there within $confirm.';
  }

  @override
  String get clientVouchersCreditDeclined => 'No credit issued';

  @override
  String get clientVouchersCreditIssuedBody =>
      'Support issued you a credit voucher. It works at any hall, hotel or service.';

  @override
  String get clientVouchersCtaSignIn => 'Sign in';

  @override
  String get clientVouchersDetailTitle => 'Voucher';

  @override
  String get clientVouchersEmptyHistory => 'No history';

  @override
  String get clientVouchersEmptyReady => 'No vouchers';

  @override
  String get clientVouchersEmptyRequest => 'No requests';

  @override
  String clientVouchersExpiredBody(String date) {
    return 'Not used before $date, so it can no longer be used.';
  }

  @override
  String get clientVouchersExplainerTitle => 'How it works';

  @override
  String get clientVouchersForRequestTitle => 'Your voucher';

  @override
  String clientVouchersForfeitedBody(String hours) {
    return 'The $hours to confirm at the venue or service ended, so this voucher is not valid and does not come back.';
  }

  @override
  String get clientVouchersGetAnother => 'Get another';

  @override
  String get clientVouchersGetVoucher => 'Get voucher';

  @override
  String get clientVouchersGuestTitle => 'Your vouchers';

  @override
  String get clientVouchersHistPaid => 'Paid';

  @override
  String get clientVouchersHistRequested => 'Requested';

  @override
  String get clientVouchersHistReturned => 'Returned';

  @override
  String get clientVouchersHistoryLabel => 'Voucher history';

  @override
  String get clientVouchersInfoBack => 'Why returned';

  @override
  String get clientVouchersInfoFit => 'Why not';

  @override
  String get clientVouchersInfoPay => 'Pay direct';

  @override
  String get clientVouchersInfoPaying => 'Payment';

  @override
  String get clientVouchersInfoRequest => 'Your request';

  @override
  String get clientVouchersInfoUsedUp => 'Used up';

  @override
  String clientVouchersInfoWaiting(String name) {
    return 'Waiting for $name to reply. Your voucher stays with this request until it is answered.';
  }

  @override
  String get clientVouchersInfoWindow => 'Confirm window';

  @override
  String get clientVouchersInvalidSaving =>
      'On these changes the saving at the venue is smaller than the voucher price.';

  @override
  String clientVouchersInvalidTarget(String bound, String other) {
    return 'This voucher belongs to $bound, and your request is now for $other.';
  }

  @override
  String get clientVouchersKeep => 'Keep voucher';

  @override
  String get clientVouchersLabelConfirmBy => 'Confirm by';

  @override
  String get clientVouchersLabelEvent => 'Event date';

  @override
  String get clientVouchersLabelExpired => 'Expired on';

  @override
  String get clientVouchersLabelExpires => 'Expires';

  @override
  String get clientVouchersLabelHall => 'Hall';

  @override
  String get clientVouchersLabelMethod => 'Paid with';

  @override
  String get clientVouchersLabelPackage => 'Package';

  @override
  String get clientVouchersLabelReuse => 'Reusable until';

  @override
  String get clientVouchersLabelUsed => 'Used on';

  @override
  String get clientVouchersLabelValid => 'Valid until';

  @override
  String get clientVouchersNoLongerFits => 'No longer fits';

  @override
  String clientVouchersNoneBody(String name, String fee) {
    return 'A voucher lets you request $name at the voucher price. It costs $fee, paid once, online.';
  }

  @override
  String get clientVouchersNoneTitle => 'Voucher needed';

  @override
  String get clientVouchersOfflineSaved => 'Offline, saved on phone';

  @override
  String get clientVouchersOnePer => 'One voucher per request.';

  @override
  String get clientVouchersOwned => 'Already yours';

  @override
  String clientVouchersPayBody(String name) {
    return 'Pay $name directly, on the terms you agreed. Their team scans the code, then marks it used.';
  }

  @override
  String clientVouchersPayFee(String fee) {
    return 'Pay $fee';
  }

  @override
  String get clientVouchersPayingBody =>
      'We are waiting for the bank to confirm. The voucher is ready the moment it does.';

  @override
  String get clientVouchersPhaseDirect => 'Pay direct';

  @override
  String get clientVouchersPhaseUsedUp => 'Used up';

  @override
  String get clientVouchersPhaseWaiting => 'Waiting';

  @override
  String get clientVouchersPriceChanged => 'Prices updated';

  @override
  String get clientVouchersQrAwake =>
      'The screen stays bright and awake while this is open.';

  @override
  String clientVouchersQrLabel(String code) {
    return 'QR code of voucher $code';
  }

  @override
  String get clientVouchersQuoteLabel => 'The choice your voucher is bound to';

  @override
  String get clientVouchersRestore => 'Restore choice';

  @override
  String get clientVouchersRestoredToast => 'Choice restored';

  @override
  String get clientVouchersReuseOnly =>
      'Support can issue a credit voucher only when the venue or service could not take your request. This voucher can be used again here.';

  @override
  String get clientVouchersSegHistory => 'History';

  @override
  String get clientVouchersSegLabel => 'Voucher groups';

  @override
  String get clientVouchersSegReady => 'Ready';

  @override
  String get clientVouchersSegRequest => 'In request';

  @override
  String get clientVouchersSendRequest => 'Send request';

  @override
  String get clientVouchersShowCode => 'Show code';

  @override
  String get clientVouchersStepDirect => 'Pay direct';

  @override
  String get clientVouchersStepRequest => 'Request';

  @override
  String get clientVouchersStepsLabel => 'Voucher steps';

  @override
  String get clientVouchersStillFits => 'Still fits';

  @override
  String get clientVouchersSupport => 'Support';

  @override
  String clientVouchersTermBack(String days) {
    return 'If the venue declines, does not reply or cancels, the voucher comes back: use it again here for $days, or ask support for a credit voucher.';
  }

  @override
  String clientVouchersTermDirect(String name) {
    return 'You pay $name directly, outside the app, after you confirm. Ghazal takes no part in that payment.';
  }

  @override
  String clientVouchersTermForfeit(String confirm) {
    return 'After approval, confirm within $confirm by paying at the venue or service, or the voucher is not valid.';
  }

  @override
  String get clientVouchersTermUsed =>
      'If you cancel after confirming, the voucher is used up.';

  @override
  String clientVouchersTermValid(String validity) {
    return 'Valid for $validity from the day you pay.';
  }

  @override
  String clientVouchersTermWhat(String fee, String name) {
    return 'A $fee voucher lets you request $name at the voucher price. It belongs to this choice only.';
  }

  @override
  String clientVouchersTermWindows(String name, String reply, String confirm) {
    return '$name replies within $reply. After approval you have $confirm to confirm.';
  }

  @override
  String get clientVouchersTermWithdraw =>
      'If you withdraw before approval, you can use it again here.';

  @override
  String get clientVouchersTermsTitle => 'Voucher terms';

  @override
  String get clientVouchersTooSmallBody =>
      'On this choice the voucher would not save you more than it costs, so we are not offering one. Contact the venue and pay the standard price.';

  @override
  String get clientVouchersTooSmallTitle => 'No voucher needed';

  @override
  String get clientVouchersUseAgain => 'Use again';

  @override
  String get clientVouchersUseThis => 'Use voucher';

  @override
  String get clientVouchersUsedUpBody =>
      'You cancelled after confirming, so this voucher is used up.';

  @override
  String get clientVouchersViewReceipt => 'View receipt';

  @override
  String get clientVouchersViewReceiptShort => 'Receipt';

  @override
  String get clientVouchersViewRequest => 'View request';

  @override
  String get clientVouchersWalletTitle => 'My vouchers';

  @override
  String clientVouchersWhyDeclined(String name) {
    return '$name could not take this request.';
  }

  @override
  String clientVouchersWhyNoResponse(String name) {
    return '$name did not reply in time.';
  }

  @override
  String clientVouchersWhyRevoked(String name) {
    return '$name withdrew its approval.';
  }

  @override
  String get clientVouchersWhySlotTaken => 'Another booking took the date.';

  @override
  String clientVouchersWhySuspended(String name) {
    return '$name is not taking requests at the moment.';
  }

  @override
  String clientVouchersWhyVenueCancelled(String name) {
    return '$name cancelled the booking.';
  }

  @override
  String get clientVouchersWhyWithdrawn => 'You withdrew the request.';

  @override
  String get clientVouchersWindowBody =>
      'The date is held until the window ends. After it, the approval ends and the voucher is not valid.';

  @override
  String get clientVouchersWindowLeft => 'Time remaining to confirm';

  @override
  String get clientVouchersWordDeclined => 'Declined';

  @override
  String get clientVouchersWordNoResponse => 'No reply';

  @override
  String get clientVouchersWordRevoked => 'Revoked';

  @override
  String get clientVouchersWordSlotTaken => 'Date taken';

  @override
  String get clientVouchersWordSuspended => 'Paused';

  @override
  String get clientVouchersWordVenueCancelled => 'Cancelled';

  @override
  String get clientVouchersWordWithdrawn => 'Withdrawn';
}
