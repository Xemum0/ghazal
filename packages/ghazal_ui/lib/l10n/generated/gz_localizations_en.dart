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
  String get uiClientBriefCardDate => 'Date';

  @override
  String get uiClientBriefCardArea => 'Area';

  @override
  String get uiClientBriefCardGuests => 'Guests';

  @override
  String get uiClientBriefCardBudget => 'Budget';

  @override
  String get uiClientBriefCardNameDate => 'Date';

  @override
  String get uiClientBriefCardNameArea => 'Area';

  @override
  String get uiClientBriefCardNameGuests => 'Guests';

  @override
  String get uiClientBriefCardNameBudget => 'Venue and catering budget';

  @override
  String uiClientBriefCardRow(String label, String value) {
    return '$label: $value';
  }

  @override
  String get uiClientBriefCardShowHalls => 'Show halls';

  @override
  String uiClientBriefCardShowCount(String count) {
    return 'Show $count';
  }

  @override
  String uiClientBriefCardMore(String n) {
    return '+$n';
  }

  @override
  String get uiClientBriefCardTitle => 'Your brief';

  @override
  String get uiClientBriefSentenceWomen => 'Ladies’ reception';

  @override
  String get uiClientBriefSentenceMen => 'Men’s reception';

  @override
  String get uiClientBriefSentenceMixed => 'Mixed celebration';

  @override
  String get uiClientBriefSentenceReception => 'Reception';

  @override
  String get uiClientBriefSentenceForGuests => 'for';

  @override
  String get uiClientBriefSentenceOn => 'on';

  @override
  String get uiClientBriefSentenceIn => 'in';

  @override
  String get uiClientBriefSentenceBudgetOf => 'budget';

  @override
  String get uiClientBriefSentenceChooseGuests => 'add guests';

  @override
  String get uiClientBriefSentenceChooseDate => 'choose a date';

  @override
  String get uiClientBriefSentenceChooseArea => 'choose an area';

  @override
  String get uiClientBriefSentenceChooseBudget => 'set a budget';

  @override
  String uiClientBriefSentenceField(String what) {
    return 'Change $what';
  }

  @override
  String get uiClientBriefSentenceWhatDate => 'the date';

  @override
  String get uiClientBriefSentenceWhatGuests => 'the guests';

  @override
  String get uiClientBriefSentenceWhatArea => 'the area';

  @override
  String get uiClientBriefSentenceWhatBudget => 'the budget';

  @override
  String get uiClientBriefSentenceEditLabel => 'Edit date, guests, area and budget';

  @override
  String get uiClientVoucherWindowEyebrow => 'Voucher price';

  @override
  String uiClientVoucherWindowEvents(String window) {
    return 'For events $window';
  }

  @override
  String uiClientVoucherWindowEventsOn(String days) {
    return 'For events on $days';
  }

  @override
  String get uiClientVoucherWindowEventsDates => 'For events on selected dates';

  @override
  String uiClientVoucherWindowUntil(String date) {
    return 'Price available until $date';
  }

  @override
  String get uiClientVoucherWindowView => 'See the hall';

  @override
  String get uiClientVoucherWindowEnded => 'This price has ended';

  @override
  String get uiClientVoucherWindowScheduled => 'Starts soon';

  @override
  String uiClientVoucherWindowFromTo(String from, String to) {
    return '$from – $to';
  }

  @override
  String get uiClientCountdownEyebrow => 'Your wedding';

  @override
  String uiClientCountdownUnit(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'days', one: 'day');
    return '$_temp0';
  }

  @override
  String get uiClientCountdownToGo => 'until your wedding';

  @override
  String get uiClientCountdownYear => 'A year of planning ahead.';

  @override
  String get uiClientCountdownHalf => 'Six months to go.';

  @override
  String get uiClientCountdownMonth => 'One month to go. A good time to settle the details.';

  @override
  String get uiClientCountdownWeek => 'One week to go. Your guest count is now locked.';

  @override
  String get uiClientCountdownTomorrowLine => 'Everything is set for tomorrow.';

  @override
  String get uiClientCountdownTodayLine => 'Today is your day.';

  @override
  String get uiClientCountdownProgress => 'Waiting time elapsed';

  @override
  String get uiClientCountdownTomorrow => 'Tomorrow';

  @override
  String get uiClientCountdownToday => 'Today';

  @override
  String get uiClientVenueCardTagWomen => 'Ladies';

  @override
  String get uiClientVenueCardTagMen => 'Men';

  @override
  String get uiClientVenueCardTagMixed => 'Mixed';

  @override
  String get uiClientVenueCardBookedOnDate => 'Booked on your date';

  @override
  String get uiClientVenueCardGovernment => 'Booked through the Ministry of Social Affairs';

  @override
  String get uiClientVenueCardGovernmentTag => 'Government';

  @override
  String get uiClientVenueCardFeatured => 'Featured';

  @override
  String get uiClientVenueCardWindow => 'Special voucher price';

  @override
  String get uiClientVenueCardNoPhotos => 'Photos coming soon';

  @override
  String get uiClientVenueCardHasVideo => 'Has a video tour';

  @override
  String get uiClientVenueCardPriceDropped => 'Price dropped';

  @override
  String get uiClientVenueCardSelect => 'Choose this hall';

  @override
  String uiClientVenueCardPhotosOf(String name) {
    return 'Photos of $name';
  }

  @override
  String uiClientVenueCardOpen(String name) {
    return 'Open $name';
  }

  @override
  String get uiClientCompareAddOne => 'Add one more to compare';

  @override
  String get uiClientCompareCompare => 'Compare';

  @override
  String uiClientCompareRemoveFrom(String name) {
    return 'Remove $name from compare';
  }

  @override
  String get uiClientCompareClear => 'Clear the comparison';

  @override
  String get uiClientCompareExpand => 'Show the comparison tray';

  @override
  String uiClientCompareEmptySlot(String n) {
    return 'Empty slot $n';
  }

  @override
  String uiClientCompareTrayLabel(String pair) {
    return 'Compare ($pair)';
  }

  @override
  String get uiClientCompareBest => 'Best in row';

  @override
  String get uiClientCompareDifferences => 'Differences only';

  @override
  String uiClientCompareHidden(String n) {
    return '$n matching rows hidden';
  }

  @override
  String get uiClientCompareHiddenOne => '1 matching row hidden';

  @override
  String get uiClientCompareAllShown => 'All rows shown';

  @override
  String get uiClientCompareNoLonger => 'No longer listed';

  @override
  String uiClientCompareYours(String n) {
    return 'your $n';
  }

  @override
  String uiClientCompareOpen(String name) {
    return 'Open $name';
  }

  @override
  String uiClientComparePick(String name) {
    return 'Choose $name';
  }

  @override
  String uiClientCompareUnpick(String name) {
    return 'Unchoose $name';
  }

  @override
  String get uiClientCompareGroupDate => 'Your date';

  @override
  String get uiClientCompareGroupPrice => 'Price';

  @override
  String get uiClientCompareGroupCapacity => 'Capacity and layout';

  @override
  String get uiClientCompareGroupFacilities => 'Facilities';

  @override
  String get uiClientCompareRating => 'Rating';

  @override
  String get uiClientCompareGroupDistance => 'Distance';

  @override
  String get uiClientCompareGroupBooking => 'Type and structure';

  @override
  String get uiClientComparePhotos => 'Photos';

  @override
  String get uiClientCompareRowAvailability => 'Availability';

  @override
  String get uiClientCompareRowPriceDate => 'Voucher price for your date';

  @override
  String get uiClientCompareRowPriceFrom => 'Voucher price from';

  @override
  String get uiClientCompareRowStandard => 'Standard price';

  @override
  String get uiClientCompareRowSavings => 'You save';

  @override
  String get uiClientCompareNoVoucher => 'No voucher price';

  @override
  String get uiClientCompareRowPerGuest => 'Per guest';

  @override
  String get uiClientCompareRowCapacity => 'Largest hall';

  @override
  String get uiClientCompareRowValet => 'Valet';

  @override
  String get uiClientCompareRowPhotography => 'Photography';

  @override
  String uiClientCompareRowDistance(String origin) {
    return 'Drive from $origin';
  }

  @override
  String get uiClientCompareRowPackages => 'Packages';

  @override
  String get uiClientCompareRowType => 'Venue type';

  @override
  String get uiClientComparePickDate => 'Pick a date';

  @override
  String get uiClientCompareIncluded => 'Included';

  @override
  String get uiClientCompareExtra => 'Extra';

  @override
  String get uiClientCompareNotOffered => 'Not offered';

  @override
  String get uiClientCompareWomenOnly => 'Women only';

  @override
  String get uiClientCompareAllowed => 'Allowed';

  @override
  String get uiClientCompareNotAllowed => 'Not allowed';

  @override
  String uiClientCompareFits(String n) {
    return 'Fits $n';
  }

  @override
  String uiClientCompareBelow(String n) {
    return 'Below $n';
  }

  @override
  String uiClientCompareUpTo(String n) {
    return 'Up to $n';
  }

  @override
  String get uiClientComparePerGuestUnit => 'per guest';

  @override
  String get uiClientCompareGetVoucher => 'Get voucher';

  @override
  String get uiClientCompareOfficial => 'Official';

  @override
  String get uiClientCompareSeeDates => 'See dates';

  @override
  String get uiClientCompareBestRated => 'Best rated';

  @override
  String get uiClientCompareLowest => 'Lowest price';

  @override
  String get uiClientCompareClosest => 'Closest';

  @override
  String get uiClientCompareTypeOfficial => 'Official channel';

  @override
  String get uiClientComparePerPerson => 'Per person';

  @override
  String get uiClientComparePackagesWord => 'Packages';

  @override
  String get uiClientCompareBoth => 'Both';

  @override
  String get uiClientReviewAnonymous => 'Anonymous guest';

  @override
  String get uiClientReviewVerified => 'Verified booking';

  @override
  String uiClientReviewReply(String venue) {
    return 'Reply from $venue';
  }

  @override
  String get uiClientReviewMore => 'Read more';

  @override
  String get uiClientReviewLess => 'Show less';

  @override
  String get uiClientReviewPhotos => 'Photos from this event';

  @override
  String get uiClientReviewLadies => 'Ladies’ reception';

  @override
  String get uiClientReviewMen => 'Men’s reception';

  @override
  String get uiClientReviewCatVenue => 'Venue';

  @override
  String get uiClientReviewCatFood => 'Food';

  @override
  String get uiClientReviewCatService => 'Service';

  @override
  String get uiClientReviewCatValue => 'Value';

  @override
  String get uiClientReviewNone => 'No reviews yet. The first guests will write here after their event.';

  @override
  String uiClientReviewScore(String label, String value) {
    return '$label: $value';
  }

  @override
  String get uiClientVenueInfoGroupSpace => 'Spaces';

  @override
  String get uiClientVenueInfoGroupService => 'Services';

  @override
  String get uiClientVenueInfoGroupProduction => 'Production';

  @override
  String get uiClientVenueInfoGroupPolicy => 'House rules';

  @override
  String get uiClientVenueInfoIncluded => 'Included';

  @override
  String get uiClientVenueInfoExtra => 'Extra';

  @override
  String uiClientVenueInfoExtraFrom(String price) {
    return 'Extra, from $price';
  }

  @override
  String get uiClientVenueInfoNotOffered => 'Not offered';

  @override
  String uiClientVenueInfoShowAll(String n) {
    return 'Show all $n facilities';
  }

  @override
  String get uiClientVenueInfoShowLess => 'Show fewer';

  @override
  String get uiClientVenueInfoPhotography => 'Photography';

  @override
  String get uiClientVenueInfoMusic => 'Music';

  @override
  String get uiClientVenueInfoEntrance => 'Entrance';

  @override
  String get uiClientVenueInfoCloakroom => 'Abaya cloakroom';

  @override
  String get uiClientVenueInfoPrayer => 'Prayer room';

  @override
  String get uiClientVenueInfoSecurity => 'Security';

  @override
  String get uiClientVenueInfoBoys => 'Boys';

  @override
  String get uiClientVenueInfoCatering => 'Outside catering';

  @override
  String get uiClientVenueInfoDecor => 'Outside decor';

  @override
  String get uiClientVenueInfoBukhoor => 'Bukhoor';

  @override
  String get uiClientVenueInfoCutOff => 'Event ends by';

  @override
  String get uiClientVenueInfoExtraHour => 'Extra hour';

  @override
  String get uiClientVenueInfoBackup => 'Indoor backup';

  @override
  String get uiClientVenueInfoPhotoFemale => 'Female photographers only';

  @override
  String get uiClientVenueInfoPhotoAllowed => 'Photography allowed';

  @override
  String get uiClientVenueInfoPhotoNone => 'No photography';

  @override
  String get uiClientVenueInfoMusicBand => 'DJ or band';

  @override
  String get uiClientVenueInfoMusicLive => 'Live music';

  @override
  String get uiClientVenueInfoMusicDuff => 'Duff and nasheed only';

  @override
  String get uiClientVenueInfoMusicNone => 'No music';

  @override
  String get uiClientVenueInfoNo => 'No';

  @override
  String get uiClientVenueInfoSeparate => 'Separate entrance';

  @override
  String get uiClientVenueInfoSecurityFemale => 'Female security';

  @override
  String uiClientVenueInfoBoysUpTo(String n) {
    return 'Up to age $n';
  }

  @override
  String get uiClientVenueInfoBoysAny => 'Any age';

  @override
  String get uiClientVenueInfoAllowed => 'Allowed';

  @override
  String get uiClientVenueInfoApproval => 'With the hotel’s approval';

  @override
  String get uiClientVenueInfoNotAllowed => 'Not allowed';

  @override
  String get uiClientVenueInfoAvailable => 'Available';

  @override
  String get uiClientVenueInfoMapOpen => 'Open in Maps';

  @override
  String uiClientVenueInfoMapDrive(String time, String origin) {
    return '$time from $origin';
  }

  @override
  String uiClientVenueInfoMapPin(String name) {
    return 'Location of $name';
  }

  @override
  String uiClientVenueInfoBlock(String n) {
    return 'Block $n';
  }

  @override
  String uiClientChecklistDone(String done, String total) {
    return '$done of $total done';
  }

  @override
  String get uiClientChecklistProgress => 'Checklist progress';

  @override
  String uiClientChecklistDue(String date) {
    return 'Due $date';
  }

  @override
  String uiClientChecklistOverdue(String date) {
    return 'Overdue since $date';
  }

  @override
  String get uiClientChecklistNoDate => 'No date set';

  @override
  String get uiClientChecklistAuto => 'Completes when your booking is confirmed';

  @override
  String uiClientChecklistCompletedOn(String date) {
    return 'Done $date';
  }

  @override
  String get uiClientChecklistChoose => 'Choose';

  @override
  String get uiClientChecklistYours => 'Your task';

  @override
  String get uiClientBudgetTotal => 'Wedding budget';

  @override
  String get uiClientBudgetPaid => 'Paid';

  @override
  String get uiClientBudgetCommitted => 'Committed';

  @override
  String get uiClientBudgetRemaining => 'Remaining';

  @override
  String uiClientBudgetOf(String paid, String allocated) {
    return '$paid of $allocated';
  }

  @override
  String uiClientBudgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String uiClientBudgetAlertCategory(String name) {
    return '$name is over its share of the budget.';
  }

  @override
  String get uiClientBudgetAlertTotal => 'Your plans are above your total budget.';

  @override
  String get uiClientBudgetLinked => 'Linked to your booking';

  @override
  String get uiClientBudgetCategories => 'By category';

  @override
  String uiClientBudgetBarLabel(String paid, String paidAmount, String committed, String committedAmount, String remaining, String remainingAmount) {
    return '$paid: $paidAmount, $committed: $committedAmount, $remaining: $remainingAmount';
  }

  @override
  String get uiClientTierSuits => 'Suits';

  @override
  String get uiClientTierConsult => 'Request consultation';

  @override
  String uiClientTierMarks(String n) {
    return '$n of 3 marks';
  }

  @override
  String uiClientServiceOpen(String name) {
    return 'Open $name';
  }

  @override
  String get uiClientVendorVerified => 'Verified';

  @override
  String get uiClientVendorFemaleTeam => 'Female team for ladies’ halls';

  @override
  String uiClientVendorReplies(String time) {
    return 'Usually replies within $time';
  }

  @override
  String get uiClientChatSent => 'Sent';

  @override
  String get uiClientChatDelivered => 'Delivered';

  @override
  String get uiClientChatRead => 'Read';

  @override
  String get uiClientChatPlay => 'Play voice message';

  @override
  String get uiClientChatPause => 'Pause voice message';

  @override
  String get uiClientChatVoice => 'Voice message';

  @override
  String get uiClientChatPhoto => 'Photo';

  @override
  String uiClientChatDownload(String name) {
    return 'Download $name';
  }

  @override
  String get uiClientChatOpenPhoto => 'Open photo';

  @override
  String get uiClientChatPdf => 'PDF';

  @override
  String uiClientChatKb(String n) {
    return '$n KB';
  }

  @override
  String get uiClientChatDraft => 'Draft';

  @override
  String get uiClientChatYou => 'You: ';

  @override
  String get uiClientChatPinned => 'Pinned';

  @override
  String uiClientChatUnread(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString unread messages', one: '$countString unread message');
    return '$_temp0';
  }

  @override
  String get uiClientThreadVoucher => 'Voucher';

  @override
  String get uiClientThreadRequest => 'Request';

  @override
  String get uiClientThreadApproval => 'Approval';

  @override
  String get uiClientThreadConfirmation => 'Confirmed';

  @override
  String get uiClientThreadRedemption => 'Redeemed';

  @override
  String get uiClientThreadVoucherLong => 'Voucher bought';

  @override
  String get uiClientThreadRequestLong => 'Request sent';

  @override
  String get uiClientThreadApprovalLong => 'Venue approval';

  @override
  String get uiClientThreadConfirmationLong => 'You confirmed';

  @override
  String get uiClientThreadRedemptionLong => 'Redeemed';

  @override
  String get uiClientThreadConfirmationStep => 'Confirm';

  @override
  String get uiClientThreadRedemptionStep => 'At venue';

  @override
  String get uiClientThreadConfirmationStepLong => 'Your confirmation';

  @override
  String get uiClientThreadRedemptionStepLong => 'At the venue';

  @override
  String get uiClientThreadNotRedeemed => 'Not redeemed';

  @override
  String get uiClientThreadLabel => 'Booking progress';

  @override
  String uiClientThreadStepOf(String n, String total) {
    return 'Step $n of $total';
  }

  @override
  String get uiClientBookingCardDate => 'Date';

  @override
  String get uiClientBookingCardVoucherPrice => 'Voucher price';

  @override
  String get uiClientBookingCardQuantity => 'Quantity';

  @override
  String uiClientBookingCardOpen(String ref) {
    return 'Open booking $ref';
  }

  @override
  String uiClientBookingCardConfirmBy(String when, String left) {
    return 'Confirm by $when · $left';
  }

  @override
  String get uiClientPackageHallOnly => 'hall hire';

  @override
  String get uiClientPackagePlus => 'plus';

  @override
  String uiClientPackageForGuests(String guests) {
    return 'for $guests';
  }

  @override
  String uiClientPackageUpTo(String guests) {
    return 'up to $guests';
  }

  @override
  String get uiClientPackageIncluded => 'Included';

  @override
  String get uiClientPackageNotCovered => 'Good to know';

  @override
  String get uiClientPackageSelected => 'Selected';

  @override
  String get uiClientPackageUnavailable => 'Not available on your date';

  @override
  String uiClientPackageShowAll(String n) {
    return 'Show all $n inclusions';
  }

  @override
  String get uiClientPackageShowLess => 'Show fewer';

  @override
  String get uiClientPackageLadies => 'Ladies';

  @override
  String get uiClientPackageMen => 'Men';

  @override
  String get uiClientPackageMixed => 'Mixed';

  @override
  String get uiClientBreakdownLines => 'Price details';

  @override
  String get uiClientBreakdownStandardTotal => 'Standard price';

  @override
  String get uiClientBreakdownVoucherTotal => 'Voucher price';

  @override
  String get uiClientBreakdownSave => 'You save';

  @override
  String get uiClientBreakdownWho => 'Who you pay';

  @override
  String get uiClientBreakdownGhazal => 'Ghazal · your voucher';

  @override
  String get uiClientBreakdownGhazalPaid => 'Paid once, when you got the voucher';

  @override
  String uiClientBreakdownVenue(String venue) {
    return '$venue · directly';
  }

  @override
  String get uiClientBreakdownVenueReview => 'After you confirm, you pay the venue yourself at this price.';

  @override
  String get uiClientBreakdownVenueConfirmed => 'Pay the venue directly, then show your voucher code.';

  @override
  String get uiClientBreakdownVenueRedeemed => 'Settled with the venue. The voucher was redeemed.';

  @override
  String get uiClientBreakdownInclusive => 'All-in at the venue’s own terms. Ghazal adds nothing to this price.';

  @override
  String get uiClientBreakdownNoMore => 'Nothing more to pay Ghazal.';

  @override
  String get uiClientPaymentKnet => 'KNET';

  @override
  String get uiClientPaymentKnetNote => 'Kuwaiti bank cards';

  @override
  String get uiClientPaymentVisa => 'Visa';

  @override
  String get uiClientPaymentMastercard => 'Mastercard';

  @override
  String get uiClientPaymentCardNote => 'Credit or debit card';

  @override
  String get uiClientPaymentApplePay => 'Apple Pay';

  @override
  String get uiClientPaymentApplePayNote => 'With the card on your device';

  @override
  String get uiClientPaymentGooglePay => 'Google Pay';

  @override
  String get uiClientPaymentGooglePayNote => 'With the card on your device';

  @override
  String get uiClientPaymentRecommended => 'Recommended after a KNET limit';

  @override
  String get uiClientPaymentUnavailable => 'Not available on this device';

  @override
  String get uiClientPaymentSelected => 'Selected';

  @override
  String get uiClientReceiptTitle => 'Receipt';

  @override
  String get uiClientReceiptIssuer => 'Ghazal';

  @override
  String get uiClientReceiptNumber => 'Receipt number';

  @override
  String get uiClientReceiptVoucherCode => 'Voucher code';

  @override
  String get uiClientReceiptIssued => 'Paid on';

  @override
  String get uiClientReceiptVia => 'Paid with';

  @override
  String uiClientReceiptLine(String name) {
    return 'Voucher for $name';
  }

  @override
  String get uiClientReceiptTotal => 'Total';

  @override
  String get uiClientReceiptFooter => 'Issued in Kuwaiti dinars (KWD). Western digits, three decimals.';

  @override
  String get uiClientNotificationUnread => 'Unread';

  @override
  String get uiClientNotificationMarketing => 'Offer';

  @override
  String get uiFiltersGovernorateAll => 'All Kuwait';

  @override
  String get uiFiltersCapacityFrom => 'From';

  @override
  String get uiFiltersCapacityTo => 'To';

  @override
  String uiFiltersCapacitySummary(String range) {
    return '$range guests';
  }

  @override
  String get uiFiltersCapacityMin => 'Fewest guests';

  @override
  String get uiFiltersCapacityMax => 'Most guests';

  @override
  String uiHotelTimeLeft(String time) {
    return '$time left';
  }

  @override
  String get uiHotelRowNew => 'New';

  @override
  String get uiHotelCardPackage => 'Package';

  @override
  String get uiHotelCardVoucherPrice => 'Voucher price';

  @override
  String get uiHotelCardNoOther => 'No other request for this date';

  @override
  String get uiHotelCardVerified => 'Verified phone';

  @override
  String get uiHotelCardFirstBooking => 'First booking';

  @override
  String get uiHotelCardCompare => 'Compare';

  @override
  String get uiHotelCardHeld => 'Date held';

  @override
  String get uiHotelCardHeldReason => 'Date on hold';

  @override
  String get uiHotelCardConfirmBy => 'Client confirms by';

  @override
  String get uiHotelCardUndoMessage => 'Request approved';

  @override
  String uiHotelCardChat(String name) {
    return 'Message $name';
  }

  @override
  String uiHotelCardCall(String name) {
    return 'Call $name';
  }

  @override
  String uiHotelCardOpen(String date) {
    return 'Open request: $date';
  }

  @override
  String get uiHotelCardTagWomen => 'Ladies';

  @override
  String get uiHotelCardTagMen => 'Men';

  @override
  String get uiHotelCardTagMixed => 'Mixed';

  @override
  String get uiHotelCardHours => 'Hours';

  @override
  String get uiHotelCardSpecialRequests => 'Special requests';

  @override
  String uiHotelCardOthers(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'other requests for this date', one: 'other request for this date');
    return '$_temp0';
  }

  @override
  String get uiHotelTimelineNow => 'Now';

  @override
  String get uiHotelTimelineEmpty => 'Nothing scheduled today';

  @override
  String get uiHotelStripConfirmed => 'Confirmed';

  @override
  String get uiHotelStripPending => 'Pending or on hold';

  @override
  String get uiHotelStripOpen => 'Open';

  @override
  String get uiHotelStripToday => 'Today';

  @override
  String get uiHotelStripSep => ', ';

  @override
  String uiHotelStripConfirmedCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString confirmed', one: '$countString confirmed');
    return '$_temp0';
  }

  @override
  String uiHotelStripPendingCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString pending', one: '$countString pending');
    return '$_temp0';
  }

  @override
  String uiHotelStripOpenCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString open', one: '$countString open');
    return '$_temp0';
  }

  @override
  String uiHotelKpiUp(String pct) {
    return 'up $pct';
  }

  @override
  String uiHotelKpiDown(String pct) {
    return 'down $pct';
  }

  @override
  String get uiHotelKpiFlat => 'unchanged';

  @override
  String get uiHotelOccBooked => 'Booked';

  @override
  String get uiHotelOccHeld => 'On hold';

  @override
  String get uiHotelOccBlocked => 'Blocked';

  @override
  String get uiHotelOccOpen => 'Open';

  @override
  String uiHotelOccOf(String booked, String total) {
    return '$booked of $total hall-nights booked';
  }

  @override
  String uiHotelOccNights(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'hall-nights', one: 'hall-night');
    return '$_temp0';
  }

  @override
  String get uiHotelVactRequests => 'Requests received';

  @override
  String get uiHotelVactAwaiting => 'Waiting for the client to confirm';

  @override
  String get uiHotelVactRedeemed => 'Vouchers redeemed';

  @override
  String get uiHotelVactChart => 'Vouchers bought per day';

  @override
  String get uiHotelVactDaily => 'Bought per day';

  @override
  String get uiHotelCalFree => 'open';

  @override
  String get uiHotelCalRequest => 'Request';

  @override
  String get uiHotelCalRequestLegend => 'Pending request';

  @override
  String get uiHotelCalSep => ', ';

  @override
  String uiHotelCalHoldUntil(String time) {
    return 'Held until $time';
  }

  @override
  String get uiHotelCalOpen => 'Open';

  @override
  String get uiHotelCalBlock => 'Block';

  @override
  String get uiHotelCalBlockDate => 'Block this date';

  @override
  String uiHotelCalBy(String name) {
    return 'by $name';
  }

  @override
  String uiHotelCalAgenda(String date) {
    return 'Agenda for $date';
  }

  @override
  String uiHotelCalRequests(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString pending requests for this date',
      one: '$countString pending request for this date',
    );
    return '$_temp0';
  }

  @override
  String get uiHotelCalReasonOfflineBooking => 'Booked offline';

  @override
  String get uiHotelCalReasonMaintenance => 'Maintenance';

  @override
  String get uiHotelCalReasonPrivateEvent => 'Private event';

  @override
  String get uiHotelCalReasonOther => 'Other';

  @override
  String get uiHotelCalSetup => 'Setup';

  @override
  String get uiHotelCalTeardown => 'Teardown';

  @override
  String get uiHotelCalOpenDay => 'Open: nothing booked or held on this date';

  @override
  String get uiHotelCalDragHint => 'Press and hold a date, then drag across. Or tap a start date and an end date.';

  @override
  String get uiHotelCalSheetTitle => 'Block dates';

  @override
  String get uiHotelCalSheetShortcuts => 'Shortcuts';

  @override
  String get uiHotelCalSheetReason => 'Reason';

  @override
  String get uiHotelCalSheetHalls => 'Halls';

  @override
  String get uiHotelCalSheetOpen => 'Open';

  @override
  String get uiHotelCalSheetOffer => 'Offer';

  @override
  String get uiHotelCalSheetNone => 'Choose the dates';

  @override
  String get uiHotelCalSheetGrid => 'Choose dates to block';

  @override
  String get uiHotelCalSheetNote => 'Hidden from couples as soon as you block.';

  @override
  String uiHotelCalSheetDates(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString dates', one: '$countString date');
    return '$_temp0';
  }

  @override
  String get uiHotelActionsReschedule => 'Propose another date';

  @override
  String get uiHotelActionsRescheduleWhy => 'Offer up to three dates at the same voucher price. The client has 48 hours to answer.';

  @override
  String get uiHotelActionsRevoke => 'Revoke approval';

  @override
  String get uiHotelActionsRevokeWhy => 'The date is released and the voucher goes back to the client.';

  @override
  String get uiHotelActionsCancel => 'Cancel booking';

  @override
  String get uiHotelActionsCancelWhy => 'The voucher goes back to the client. The cancellation counts on your record.';

  @override
  String get uiHotelStatusRef => 'Booking reference';

  @override
  String get uiHotelStatusVoucher => 'Voucher';

  @override
  String get uiHotelStatusClientPays => 'The client pays you directly';

  @override
  String get uiHotelStatusStandard => 'Standard price';

  @override
  String get uiHotelStatusDirect => 'Settled between you and the client, off the app.';

  @override
  String uiHotelStatusAwaiting(String when, String left) {
    return 'Waiting for the client to confirm by $when · $left';
  }

  @override
  String get uiHotelStatusRedeem => 'Redeem voucher';

  @override
  String uiHotelStatusRedeemed(String when, String name) {
    return 'Redeemed $when by $name';
  }

  @override
  String uiHotelStatusRedeemedNoName(String when) {
    return 'Redeemed $when';
  }

  @override
  String get uiHotelGuestBookingFor => 'Booking for';

  @override
  String get uiHotelGuestContact => 'Contact';

  @override
  String get uiHotelGuestPhone => 'Phone';

  @override
  String get uiHotelGuestNotShared => 'Not shared yet. Message in chat.';

  @override
  String get uiHotelGuestVerified => 'Verified phone';

  @override
  String get uiHotelGuestFirst => 'First booking';

  @override
  String get uiHotelGuestCall => 'Call';

  @override
  String get uiHotelGuestChat => 'Chat';

  @override
  String get uiHotelGuestVoucher => 'Voucher';

  @override
  String get uiHotelGuestCallWhy => 'The client has not shared the number';

  @override
  String get uiHotelGuestBride => 'The bride';

  @override
  String get uiHotelGuestGroom => 'The groom';

  @override
  String get uiHotelGuestFamily => 'A family member';

  @override
  String get uiHotelGuestPlanner => 'A wedding planner';

  @override
  String get uiHotelValidityEventDates => 'Event dates';

  @override
  String get uiHotelValidityHelper => 'The lower voucher price applies to events on these dates.';

  @override
  String get uiHotelValidityWindow => 'This price runs for';

  @override
  String uiHotelValidityHours(String n) {
    return '$n hours';
  }

  @override
  String uiHotelValidityEnds(String time) {
    return 'Ends $time';
  }

  @override
  String get uiHotelValidityScheduled => 'Scheduled';

  @override
  String get uiHotelValidityActive => 'Active';

  @override
  String get uiHotelValidityEnded => 'Ended';

  @override
  String uiHotelValidityStarts(String time) {
    return 'Starts $time';
  }

  @override
  String get uiHotelWindowLabel => 'How couples see it';

  @override
  String get uiHotelWindowSaving => 'Saving against the standard price';

  @override
  String uiHotelPackageGuests(String from, String to) {
    return '$from to $to guests';
  }

  @override
  String get uiHotelPackagePrice => 'Standard price per guest';

  @override
  String get uiHotelPackagePriceFlat => 'Standard price';

  @override
  String get uiHotelPackageVoucherPrice => 'Voucher price per guest';

  @override
  String get uiHotelPackageVoucherPriceFlat => 'Voucher price';

  @override
  String get uiHotelPackagePriceHelper => 'In KD, up to three decimals. What a client pays you without a voucher.';

  @override
  String get uiHotelPackageVoucherHelper => 'Lower than the standard price. What a client pays you with a Ghazal voucher.';

  @override
  String get uiHotelPackagePriceError => 'Enter an amount such as 52 or 52.500.';

  @override
  String get uiHotelPackageVoucherError => 'The voucher price must be lower than the standard price.';

  @override
  String uiHotelPackageVoucherSmall(String amount) {
    return 'Clients save $amount, which is not more than the voucher fee, so no voucher is offered.';
  }

  @override
  String uiHotelPackageSaving(String amount, String unit) {
    return 'Clients save $amount$unit with the voucher';
  }

  @override
  String uiHotelPackageStructure(String structure) {
    return 'Pricing: $structure';
  }

  @override
  String get uiHotelPackagePerPerson => 'per person';

  @override
  String get uiHotelPackagePackage => 'package';

  @override
  String get uiHotelPackageMin => 'Minimum guests';

  @override
  String get uiHotelPackageMax => 'Maximum guests';

  @override
  String uiHotelPackageRule(String step) {
    return 'Moves by $step';
  }

  @override
  String get uiHotelPackageInclusions => 'Inclusions';

  @override
  String uiHotelPackageRemove(String name) {
    return 'Remove $name';
  }

  @override
  String get uiHotelPackageAdd => 'Add inclusion';

  @override
  String uiHotelPackageActiveOf(String name) {
    return '$name is active';
  }

  @override
  String get uiHotelPackageDashboard => 'Seasonal, holiday and special-date prices are edited on the dashboard.';

  @override
  String uiHotelPackageEdit(String name) {
    return 'Edit $name';
  }

  @override
  String get uiHotelPackageKd => 'KD';

  @override
  String get uiHotelPhotosCover => 'Cover';

  @override
  String get uiHotelPhotosAdd => 'Add photos';

  @override
  String get uiHotelPhotosReview => 'In review';

  @override
  String get uiHotelPhotosRejected => 'Rejected';

  @override
  String uiHotelPhotosEarlier(String n) {
    return 'Move $n earlier';
  }

  @override
  String uiHotelPhotosLater(String n) {
    return 'Move $n later';
  }

  @override
  String get uiHotelPhotosDrag => 'Drag to reorder';

  @override
  String uiHotelPhotosOpen(String n, String zone) {
    return 'Photo $n: $zone';
  }

  @override
  String get uiHotelPhotosHall => 'Hall';

  @override
  String get uiHotelPhotosStageKosha => 'Stage and Kosha';

  @override
  String get uiHotelPhotosBridalSuite => 'Bridal suite';

  @override
  String get uiHotelPhotosBuffet => 'Buffet';

  @override
  String get uiHotelPhotosOutdoors => 'Outdoors';

  @override
  String get uiHotelPhotosEntranceValet => 'Entrance and valet';

  @override
  String get uiHotelPhotosLayout => 'Layouts';

  @override
  String get uiHotelHoursClosed => 'Closed';

  @override
  String uiHotelHoursOpen(String day) {
    return 'Open on $day';
  }

  @override
  String get uiHotelHoursFrom => 'Opens';

  @override
  String get uiHotelHoursTo => 'Closes';

  @override
  String get uiHotelHoursNextDay => 'next day';

  @override
  String get uiHotelHoursCopy => 'Copy to all days';

  @override
  String get uiHotelHoursInvalid => 'The closing time is before the opening time.';

  @override
  String uiHotelHoursPick(String what, String time) {
    return '$what at $time';
  }

  @override
  String get uiHotelReviewAnonymous => 'Anonymous';

  @override
  String get uiHotelReviewVerified => 'Verified booking';

  @override
  String get uiHotelReviewNeeds => 'Needs reply';

  @override
  String get uiHotelReviewReported => 'Reported · under review by Ghazal';

  @override
  String uiHotelReviewEvent(String month) {
    return 'Event in $month';
  }

  @override
  String get uiHotelReviewReply => 'Reply';

  @override
  String get uiHotelReviewReport => 'Report';

  @override
  String get uiHotelReviewDraft => 'Your draft';

  @override
  String uiHotelReviewYours(String name) {
    return 'Reply from $name';
  }

  @override
  String get uiHotelReviewOnce => 'A reply is public and can be sent once.';

  @override
  String get uiHotelStaffYou => 'You';

  @override
  String get uiHotelStaffActive => 'Active';

  @override
  String uiHotelStaffLastSeen(String time) {
    return 'last seen $time';
  }

  @override
  String get uiHotelStaffPending => 'Invite pending';

  @override
  String uiHotelStaffExpires(String date) {
    return 'expires $date';
  }

  @override
  String get uiHotelStaffDeactivated => 'Deactivated';

  @override
  String get uiHotelStaffAllowed => 'Allowed';

  @override
  String get uiHotelStaffNotAllowed => 'Not for this role';

  @override
  String uiHotelStaffOpen(String name) {
    return 'Permissions of $name';
  }

  @override
  String get uiHotelStaffAccept => 'Accept, decline and propose dates';

  @override
  String get uiHotelStaffBlock => 'Block and open dates';

  @override
  String get uiHotelStaffCancel => 'Reschedule or cancel a confirmed booking';

  @override
  String get uiHotelStaffCash => 'Record cash received';

  @override
  String get uiHotelStaffRevenue => 'See revenue and payments';

  @override
  String get uiHotelStaffOffers => 'Create and end offers';

  @override
  String get uiHotelStaffManage => 'Staff and bank information';

  @override
  String get uiHotelStaffSwitchable => 'Can be switched off by the owner';

  @override
  String get uiHotelPhotosMakeCover => 'Make cover';

  @override
  String get uiHotelPhotosDelete => 'Delete';

  @override
  String get uiHotelPhotosOpenAction => 'Open';

  @override
  String get uiHotelPhotosDeleted => 'Photo deleted';

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
  String get uiKitErrorValidationFailed => 'Some details need another look. Check the highlighted fields.';

  @override
  String get uiKitErrorAuthRequired => 'Sign in to continue.';

  @override
  String get uiKitErrorTokenExpired => 'Your session ended. Please sign in again.';

  @override
  String get uiKitErrorSessionRevoked => 'You were signed out on this device. Please sign in again.';

  @override
  String get uiKitErrorPhoneVerificationRequired => 'Verify your mobile number first, then try again.';

  @override
  String get uiKitErrorForbidden => 'Your role cannot do this. Ask your manager.';

  @override
  String get uiKitErrorStepUpRequired => 'Confirm with a fresh code or your password to continue.';

  @override
  String get uiKitErrorNotFound => 'This is no longer available.';

  @override
  String get uiKitErrorVenueContextRequired => 'Choose the venue or service account you are working in.';

  @override
  String get uiKitErrorOtpInvalid => 'That code is not right. Check it and try again.';

  @override
  String get uiKitErrorOtpExpired => 'That code has expired. Ask for a new one.';

  @override
  String get uiKitErrorOtpLocked => 'Too many wrong codes. Try again later.';

  @override
  String get uiKitErrorCredentialsInvalid => 'The details do not match an account. Check them and try again.';

  @override
  String get uiKitErrorRateLimited => 'Too many attempts. Please wait a moment and try again.';

  @override
  String get uiKitErrorIdempotencyInProgress => 'This is already being processed. Give it a moment.';

  @override
  String get uiKitErrorPreconditionFailed => 'This was changed elsewhere. Reload and try again.';

  @override
  String get uiKitErrorBookingStateConflict => 'This request was updated meanwhile. Reload to see where it stands.';

  @override
  String get uiKitErrorSlotUnavailable => 'That date is no longer available. Pick another date.';

  @override
  String get uiKitErrorOpenRequestLimit => 'You have reached the limit of open requests. Wait for a reply or withdraw one.';

  @override
  String get uiKitErrorQuoteExpired => 'This quote has expired. Review it again.';

  @override
  String get uiKitErrorQuoteChanged => 'The price changed since you saw it. Review the new quote.';

  @override
  String get uiKitErrorLeadTimeTooShort => 'This date is too close. Pick a later date.';

  @override
  String get uiKitErrorGuestsOutOfRange => 'The number of guests is outside what this option allows.';

  @override
  String get uiKitErrorAudienceNotAllowed => 'This hall does not offer this option for your group.';

  @override
  String get uiKitErrorChannelNotBookable => 'This venue takes requests through its official channel only.';

  @override
  String get uiKitErrorVoucherNotOffered => 'A voucher does not lower the price for this choice.';

  @override
  String get uiKitErrorVoucherNotUsable => 'This voucher cannot be used. It may be expired, forfeited or already tied to a request.';

  @override
  String get uiKitErrorVoucherTargetMismatch => 'This voucher is tied to another venue or service.';

  @override
  String get uiKitErrorVoucherCheckoutExpired => 'The checkout timed out and nothing was charged. Start again.';

  @override
  String get uiKitErrorVoucherUnknown => 'No voucher matches this code. Check it and try again.';

  @override
  String get uiKitErrorVoucherOtherPartner => 'This voucher belongs to another venue or service.';

  @override
  String get uiKitErrorVoucherNotConfirmed => 'The client has not confirmed this request yet.';

  @override
  String get uiKitErrorVoucherAlreadyUsed => 'This voucher has already been used.';

  @override
  String get uiKitErrorCreditNotEligible => 'This voucher cannot be considered for a credit voucher.';

  @override
  String get uiKitErrorRefundRequestExists => 'A request for this voucher is already with support.';

  @override
  String get uiKitErrorConfirmWindowEnded => 'The time to confirm has passed.';

  @override
  String get uiKitErrorUndoWindowEnded => 'The time to undo has passed.';

  @override
  String get uiKitErrorPaymentGatewayError => 'The payment service is unavailable. Nothing was charged. Try again shortly.';

  @override
  String get uiKitErrorPlanRatesNotAnnounced => 'Plan rates will be announced soon.';

  @override
  String get uiKitErrorListingNotEditable => 'This listing cannot be edited in its current status.';

  @override
  String get uiKitErrorListingStateConflict => 'This listing is not in a status that allows this action.';

  @override
  String get uiKitErrorMediaTooLarge => 'This file is too large. Choose a smaller one.';

  @override
  String get uiKitErrorMediaTypeUnsupported => 'This file type is not accepted.';

  @override
  String get uiKitErrorReviewAlreadyReplied => 'This review already has a reply.';

  @override
  String get uiKitErrorReviewNotAllowed => 'A review is possible once the event is completed, and only once.';

  @override
  String get uiKitErrorVisitSlotTaken => 'That arrival window is taken. Pick another one.';

  @override
  String get uiKitErrorVisitNotAllowed => 'This venue does not take site visits through the app.';

  @override
  String get uiKitErrorVisitStateConflict => 'This visit was updated meanwhile. Reload to see where it stands.';

  @override
  String get uiKitErrorStaffLastAdmin => 'The last admin cannot be removed or changed.';

  @override
  String get uiKitErrorInvitationExpired => 'This invitation has expired or was already used. Ask for a new one.';

  @override
  String get uiKitErrorEmailAlreadyInvited => 'This email already has a pending invitation.';

  @override
  String get uiKitErrorAccountDeletionBlocked => 'The account cannot be deleted while a confirmed request is coming up.';

  @override
  String get uiKitErrorAppUpdateRequired => 'Please update the app to continue.';

  @override
  String get uiKitErrorOffline => 'You are offline. Check your connection and try again.';

  @override
  String get uiKitErrorTimeout => 'This is taking too long. Please try again.';

  @override
  String get uiKitDemoTitle => 'Demo tools';

  @override
  String get uiKitDemoHotspot => 'Demo tools';

  @override
  String get uiKitDemoModeTitle => 'Backend';

  @override
  String get uiKitDemoModeInProcess => 'In-process mock';

  @override
  String uiKitDemoModeRemote(String url) {
    return 'Remote API at $url';
  }

  @override
  String get uiKitDemoStoryTitle => 'Story';

  @override
  String get uiKitDemoReset => 'Reset the story';

  @override
  String get uiKitDemoResetDone => 'The story is back at the start.';

  @override
  String get uiKitDemoPersonaTitle => 'Who is using the app';

  @override
  String get uiKitDemoPersonaGuest => 'Guest';

  @override
  String get uiKitDemoPersonaNewClient => 'New client';

  @override
  String get uiKitDemoPersonaReem => 'Reem';

  @override
  String get uiKitDemoPersonaHotelManager => 'Hotel manager';

  @override
  String get uiKitDemoPersonaHotelAdmin => 'Hotel admin';

  @override
  String get uiKitDemoPersonaProvider => 'Service provider';

  @override
  String get uiKitDemoScenarioTitle => 'Next requests';

  @override
  String get uiKitDemoScenarioNone => 'Normal';

  @override
  String get uiKitDemoScenarioSlow => 'Slow';

  @override
  String get uiKitDemoScenarioError => 'Error';

  @override
  String get uiKitDemoScenarioOffline => 'Offline';

  @override
  String get uiKitDemoScenarioEmpty => 'Empty';

  @override
  String get uiKitDemoScenarioExpired => 'Session expires';

  @override
  String get uiKitDemoClockTitle => 'Clock';

  @override
  String uiKitDemoClockNow(String time) {
    return 'Story time: $time';
  }

  @override
  String get uiKitDemoAdvanceHour => 'Advance one hour';

  @override
  String get uiKitDemoAdvanceDay => 'Advance one day';

  @override
  String get uiKitDemoJumpTitle => 'Jump to a story point';

  @override
  String get uiKitDemoPointPending => 'Awaiting reply';

  @override
  String get uiKitDemoPointApproved => 'Approved';

  @override
  String get uiKitDemoPointConfirmed => 'Confirmed';

  @override
  String get uiKitDemoPointRedeemed => 'Redeemed';

  @override
  String get uiKitDemoPointCompleted => 'Completed';

  @override
  String get uiKitDemoPointDeclined => 'Declined';

  @override
  String get uiKitDemoPointExpired => 'Expired';

  @override
  String get uiKitDemoPointLapsed => 'Forfeited';

  @override
  String get uiKitDemoPointCancelled => 'Cancelled';

  @override
  String get uiKitDemoPointCounterOffer => 'Counter-offer';

  @override
  String get uiKitDemoLanguageTitle => 'Language and digits';

  @override
  String get uiKitDemoDigitsEastern => 'Eastern Arabic digits';

  @override
  String get uiKitDemoDigitsWestern => 'Western digits';

  @override
  String get uiProviderAdPlanExemptBody => 'No fee for major hotels';

  @override
  String uiProviderAdPlanPerPeriod(String period) {
    return 'per $period';
  }

  @override
  String get uiProviderAdPlanWeek => 'week';

  @override
  String get uiProviderAdPlanMonth => 'month';

  @override
  String get uiProviderAdPlanYear => 'year';

  @override
  String get uiProviderAdPlanStarts => 'Runs from the day it is approved';

  @override
  String uiProviderAdPlanChoose(String name) {
    return 'Choose $name';
  }

  @override
  String get uiProviderMajorHotelExemptFee => 'Fee exempt';

  @override
  String get uiProviderMajorHotelExplain => 'Major hotels pay no listing or advertising fees. Every listing is still reviewed before it goes live.';

  @override
  String uiProviderListingEndsOn(String date) {
    return 'Ends $date';
  }

  @override
  String get uiProviderListingStartsAfter => 'Starts when approved';

  @override
  String get uiProviderListingNoPlan => 'No plan chosen yet';

  @override
  String get uiProviderListingReview => 'With the review team';

  @override
  String get uiProviderListingRejectContentNotCompliant => 'Content does not meet our guidelines';

  @override
  String get uiProviderListingRejectWrongCategory => 'Wrong category';

  @override
  String get uiProviderListingRejectMissingDetails => 'Details are missing';

  @override
  String get uiProviderListingRejectUnclearPricing => 'Pricing is unclear';

  @override
  String get uiProviderListingRejectOther => 'See the moderator note';

  @override
  String get uiProviderTimelineLabel => 'Review history';

  @override
  String get uiProviderTimelineDraft => 'Draft saved';

  @override
  String get uiProviderTimelinePaymentPending => 'Waiting for payment';

  @override
  String get uiProviderTimelinePendingReview => 'Sent for review';

  @override
  String get uiProviderTimelineApproved => 'Approved';

  @override
  String get uiProviderTimelineRejected => 'Not approved';

  @override
  String get uiProviderTimelineActive => 'Live on Ghazal';

  @override
  String get uiProviderTimelineExpired => 'Plan ended';

  @override
  String get uiProviderTimelinePaused => 'Paused';

  @override
  String get uiProviderTimelineYou => 'You';

  @override
  String get uiProviderTimelineSystem => 'Ghazal';

  @override
  String get uiProviderTimelineModerator => 'Ghazal review team';

  @override
  String uiProviderTimelineModeratorBy(String name) {
    return 'Ghazal review team · $name';
  }

  @override
  String get uiProviderTimelineNextReview => 'A person at Ghazal reviews it';

  @override
  String get uiProviderTimelineNextReviewNote =>
      'Every listing is checked for content and category before it goes live. Paying never publishes it by itself.';

  @override
  String get uiProviderTimelineNextLive => 'Goes live';

  @override
  String get uiProviderTimelineNextLiveNote => 'Your plan starts the day it goes live.';

  @override
  String uiProviderTimelineKeptUntil(String date) {
    return 'Your plan is kept until $date so you can resubmit.';
  }

  @override
  String get uiProviderTimelineReasonContentNotCompliant => 'Content does not meet our guidelines';

  @override
  String get uiProviderTimelineReasonWrongCategory => 'Wrong category';

  @override
  String get uiProviderTimelineReasonMissingDetails => 'Details are missing';

  @override
  String get uiProviderTimelineReasonUnclearPricing => 'Pricing is unclear';

  @override
  String get uiProviderTimelineReasonOther => 'See the note';

  @override
  String get uiSharedGuests => 'Guests';

  @override
  String get uiSharedFrom => 'From';

  @override
  String get uiSharedPerNight => 'Per night';

  @override
  String get uiSharedRentalFee => 'Rental fee';

  @override
  String get uiSharedLockedVoucher => 'Voucher price after you sign up';

  @override
  String get uiSharedVoucher => 'Voucher';

  @override
  String get uiSharedLessThanMinute => 'Less than a minute left';

  @override
  String uiSharedSpokenDays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString days', one: '$countString day');
    return '$_temp0';
  }

  @override
  String uiSharedSpokenHours(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString hours', one: '$countString hour');
    return '$_temp0';
  }

  @override
  String uiSharedSpokenMinutes(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$countString minutes', one: '$countString minute');
    return '$_temp0';
  }

  @override
  String uiSharedSpokenJoin(String first, String second) {
    return '$first $second';
  }

  @override
  String get stubNotBuilt => 'Not built yet';

  @override
  String get uiVisitsStripLabel => 'Chat members';

  @override
  String get uiVisitsStripOpen => 'Show chat members';

  @override
  String uiVisitsCardWith(String name) {
    return 'With $name';
  }

  @override
  String get uiVisitsCardChat => 'Open group chat';

  @override
  String get uiVisitsCardReadOnly => 'Chat is read-only';

  @override
  String get uiVoucherCardCode => 'Code';

  @override
  String uiVoucherCardQrLabel(String code) {
    return 'QR code of voucher $code';
  }

  @override
  String get uiVoucherCardCopy => 'Copy';

  @override
  String get uiVoucherCardFull => 'Full screen';

  @override
  String get uiVoucherCardDate => 'Event date';

  @override
  String get uiVoucherCardPackage => 'Package';

  @override
  String get uiVoucherCardValidUntil => 'Valid until';

  @override
  String get uiVoucherCardUsedOn => 'Redeemed on';

  @override
  String get uiVoucherPriceSignUp => 'Sign up';

  @override
  String get uiVoucherPriceNetTitle => 'Your saving';

  @override
  String uiVoucherPriceNet(String amount, String fee) {
    return 'You save $amount after the $fee voucher.';
  }

  @override
  String get uiVoucherPricePackage => 'Package price';

  @override
  String get uiVoucherSummaryHead => 'Your voucher';

  @override
  String get uiVoucherSummaryBoundTo => 'Bound to';

  @override
  String get uiVoucherSummaryDate => 'Event date';

  @override
  String get uiVoucherSummaryPackage => 'Package';

  @override
  String get uiVoucherSummaryGuests => 'Guests';

  @override
  String get uiVoucherSummarySave => 'You save';

  @override
  String get uiVoucherSummaryPayToday => 'You pay Ghazal today';

  @override
  String get uiVoucherSummaryPayOnce => 'For the voucher, once';

  @override
  String uiVoucherSummaryDirectly(String amount, String venue) {
    return 'The rest, $amount, you pay to $venue directly after you confirm. Ghazal takes no part in that payment.';
  }

  @override
  String get uiVoucherSummaryRuleBound => 'The voucher belongs to this venue and this quote.';

  @override
  String uiVoucherSummaryRuleReuse(String days) {
    return 'If the venue declines, you can use it again here for $days.';
  }

  @override
  String get uiVoucherSummaryRuleCredit => 'If the venue declines or does not reply, ask support for a credit voucher.';

  @override
  String get uiVoucherConfirmEyebrow => 'Confirm your booking';

  @override
  String uiVoucherConfirmBy(String when) {
    return 'Confirm by $when';
  }

  @override
  String get uiVoucherConfirmHeld => 'The date is held for you until then. You pay nothing more to Ghazal.';

  @override
  String get uiVoucherConfirmLapsedTitle => 'The confirm window ended';

  @override
  String get uiVoucherConfirmLapsedBody => 'The date was released and the voucher is no longer valid.';

  @override
  String get uiVoucherConfirmDoneTitle => 'You confirmed this booking';

  @override
  String uiVoucherConfirmDoneAt(String when) {
    return 'Confirmed on $when';
  }

  @override
  String get uiVoucherConfirmThread => 'Share of the confirm window that has passed';
}
