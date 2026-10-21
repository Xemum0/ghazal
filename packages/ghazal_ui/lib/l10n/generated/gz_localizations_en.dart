// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'gz_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class GzL10nEn extends GzL10n {
  GzL10nEn([String locale = 'en']) : super(locale);

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
  String get uiInputsOtpGroup => 'Verification code';

  @override
  String uiInputsOtpCell(String n, String total) {
    return 'Digit $n of $total';
  }

  @override
  String get uiInputsPhoneCountry => 'Country code';

  @override
  String get uiInputsPhoneNumber => 'Mobile number';

  @override
  String get uiInputsStepperIncrease => 'Increase';

  @override
  String get uiInputsStepperDecrease => 'Decrease';

  @override
  String get uiInputsRangeMinimum => 'Minimum';

  @override
  String get uiInputsRangeMaximum => 'Maximum';

  @override
  String get uiInputsSelectChoose => 'Choose';

  @override
  String uiInputsSelectCount(String n) {
    return '$n selected';
  }

  @override
  String get uiInputsSelectNoResults => 'No matches';

  @override
  String get uiInputsCalendarStartDate => 'Start date';

  @override
  String get uiInputsCalendarEndDate => 'End date';

  @override
  String get uiInputsCalendarHint => 'Use the arrow keys to move between days.';

  @override
  String uiInputsCalendarPriceBasis(String currency, String unit) {
    return '$currency · $unit';
  }

  @override
  String uiInputsDateFieldRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String get uiInputsDateFieldChooseDate => 'Choose a date';

  @override
  String get uiInputsDateFieldChooseDates => 'Choose dates';

  @override
  String get uiInputsSlotSession => 'Session';

  @override
  String get stubNotBuilt => 'Not built yet';
}
