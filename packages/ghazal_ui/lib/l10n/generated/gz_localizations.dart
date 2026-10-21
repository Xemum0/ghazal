import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'gz_localizations_ar.dart';
import 'gz_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GzL10n
/// returned by `GzL10n.of(context)`.
///
/// Applications need to include `GzL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/gz_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GzL10n.localizationsDelegates,
///   supportedLocales: GzL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GzL10n.supportedLocales
/// property.
abstract class GzL10n {
  GzL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GzL10n of(BuildContext context) {
    return Localizations.of<GzL10n>(context, GzL10n)!;
  }

  static const LocalizationsDelegate<GzL10n> delegate = _GzL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @commonActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get commonActionAccept;

  /// No description provided for @commonActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonActionAdd;

  /// No description provided for @commonActionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonActionApply;

  /// No description provided for @commonActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonActionBack;

  /// No description provided for @commonActionCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get commonActionCall;

  /// No description provided for @commonActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonActionCancel;

  /// No description provided for @commonActionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonActionClear;

  /// No description provided for @commonActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonActionClose;

  /// No description provided for @commonActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonActionConfirm;

  /// No description provided for @commonActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonActionContinue;

  /// No description provided for @commonActionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get commonActionDecline;

  /// No description provided for @commonActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonActionDone;

  /// No description provided for @commonActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonActionEdit;

  /// No description provided for @commonActionMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get commonActionMessage;

  /// No description provided for @commonActionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonActionNext;

  /// No description provided for @commonActionOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get commonActionOpenWhatsapp;

  /// No description provided for @commonActionPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonActionPrevious;

  /// No description provided for @commonActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonActionRemove;

  /// No description provided for @commonActionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get commonActionReschedule;

  /// No description provided for @commonActionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonActionReset;

  /// No description provided for @commonActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonActionRetry;

  /// No description provided for @commonActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonActionSave;

  /// No description provided for @commonActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonActionSearch;

  /// No description provided for @commonActionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonActionSeeAll;

  /// No description provided for @commonActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonActionSend;

  /// No description provided for @commonActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonActionShare;

  /// No description provided for @commonActionShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get commonActionShowLess;

  /// No description provided for @commonActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonActionSkip;

  /// No description provided for @commonActionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonActionUndo;

  /// No description provided for @commonActionWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get commonActionWhatsapp;

  /// No description provided for @commonAvailabilityAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get commonAvailabilityAvailable;

  /// No description provided for @commonAvailabilityBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get commonAvailabilityBlocked;

  /// No description provided for @commonAvailabilityBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get commonAvailabilityBooked;

  /// No description provided for @commonAvailabilityFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get commonAvailabilityFree;

  /// No description provided for @commonAvailabilityHeld.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get commonAvailabilityHeld;

  /// No description provided for @commonAvailabilityPast.
  ///
  /// In en, this message translates to:
  /// **'Past date'**
  String get commonAvailabilityPast;

  /// No description provided for @commonAvailabilityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonAvailabilityUnavailable;

  /// No description provided for @commonAvailabilityLineFree.
  ///
  /// In en, this message translates to:
  /// **'{date} · Free'**
  String commonAvailabilityLineFree(String date);

  /// No description provided for @commonAvailabilityLineBooked.
  ///
  /// In en, this message translates to:
  /// **'{date} · Booked'**
  String commonAvailabilityLineBooked(String date);

  /// No description provided for @commonCalendarAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get commonCalendarAvailability;

  /// No description provided for @commonCalendarPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get commonCalendarPrices;

  /// No description provided for @commonCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonCalendarToday;

  /// No description provided for @commonCalendarSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonCalendarSelected;

  /// No description provided for @commonCalendarPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak days'**
  String get commonCalendarPeak;

  /// No description provided for @commonCalendarPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get commonCalendarPreviousMonth;

  /// No description provided for @commonCalendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get commonCalendarNextMonth;

  /// No description provided for @commonCalendarOccasionApproximate.
  ///
  /// In en, this message translates to:
  /// **'{occasion} (approx.)'**
  String commonCalendarOccasionApproximate(String occasion);

  /// No description provided for @commonStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusRequested;

  /// No description provided for @commonStatusAwaitingDeposit.
  ///
  /// In en, this message translates to:
  /// **'Approved · deposit due'**
  String get commonStatusAwaitingDeposit;

  /// No description provided for @commonStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get commonStatusConfirmed;

  /// No description provided for @commonStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get commonStatusRejected;

  /// No description provided for @commonStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get commonStatusExpired;

  /// No description provided for @commonStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get commonStatusCancelled;

  /// No description provided for @commonStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonStatusCompleted;

  /// No description provided for @commonStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get commonStatusRefunded;

  /// No description provided for @commonStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get commonStatusNoShow;

  /// No description provided for @commonStatusHeadlineConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed booking'**
  String get commonStatusHeadlineConfirmed;

  /// No description provided for @commonStatusCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you'**
  String get commonStatusCancelledByYou;

  /// No description provided for @commonStatusCancelledByVenue.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by the venue'**
  String get commonStatusCancelledByVenue;

  /// No description provided for @commonStatusHotelMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get commonStatusHotelMissed;

  /// No description provided for @commonStatusUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get commonStatusUrgent;

  /// No description provided for @commonStatusTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String commonStatusTimeLeft(String time);

  /// No description provided for @commonFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonFilterAll;

  /// No description provided for @commonTierWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get commonTierWeekday;

  /// No description provided for @commonTierWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get commonTierWeekend;

  /// No description provided for @commonTierHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get commonTierHoliday;

  /// No description provided for @commonTierSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get commonTierSeason;

  /// No description provided for @commonTierSpecialDate.
  ///
  /// In en, this message translates to:
  /// **'Special date'**
  String get commonTierSpecialDate;

  /// No description provided for @commonUnitPerGuest.
  ///
  /// In en, this message translates to:
  /// **'per guest'**
  String get commonUnitPerGuest;

  /// No description provided for @commonUnitPerNight.
  ///
  /// In en, this message translates to:
  /// **'per night'**
  String get commonUnitPerNight;

  /// No description provided for @commonUnitPerDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get commonUnitPerDay;

  /// No description provided for @commonUnitPerHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get commonUnitPerHour;

  /// No description provided for @commonUnitMinGuests.
  ///
  /// In en, this message translates to:
  /// **'Minimum {count, plural, one{{count} guest} other{{count} guests}}'**
  String commonUnitMinGuests(int count);

  /// No description provided for @commonUnitUpToGuests.
  ///
  /// In en, this message translates to:
  /// **'Up to {count, plural, one{{count} guest} other{{count} guests}}'**
  String commonUnitUpToGuests(int count);

  /// No description provided for @commonCountGuests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No guests} one{{count} guest} other{{count} guests}}'**
  String commonCountGuests(int count);

  /// No description provided for @commonCountDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days} one{{count} day} other{{count} days}}'**
  String commonCountDays(int count);

  /// No description provided for @commonCountHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hours} one{{count} hour} other{{count} hours}}'**
  String commonCountHours(int count);

  /// No description provided for @commonCountMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No minutes} one{{count} minute} other{{count} minutes}}'**
  String commonCountMinutes(int count);

  /// No description provided for @commonCountHalls.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No halls} one{{count} hall} other{{count} halls}}'**
  String commonCountHalls(int count);

  /// No description provided for @commonCountPackages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No packages} one{{count} package} other{{count} packages}}'**
  String commonCountPackages(int count);

  /// No description provided for @commonCountMessages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No messages} one{{count} message} other{{count} messages}}'**
  String commonCountMessages(int count);

  /// No description provided for @commonCountBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No bookings} one{{count} booking} other{{count} bookings}}'**
  String commonCountBookings(int count);

  /// No description provided for @commonCountSessions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sessions} one{{count} session} other{{count} sessions}}'**
  String commonCountSessions(int count);

  /// No description provided for @commonCountMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No months} one{{count} month} other{{count} months}}'**
  String commonCountMonths(int count);

  /// No description provided for @commonCountDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No dates} one{{count} date} other{{count} dates}}'**
  String commonCountDates(int count);

  /// No description provided for @commonCountRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No requests} one{{count} request} other{{count} requests}}'**
  String commonCountRequests(int count);

  /// No description provided for @commonCountReviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} one{{count} review} other{{count} reviews}}'**
  String commonCountReviews(int count);

  /// No description provided for @commonCountPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} one{{count} photo} other{{count} photos}}'**
  String commonCountPhotos(int count);

  /// No description provided for @commonCountdownDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Today} one{{count} day to go} other{{count} days to go}}'**
  String commonCountdownDays(int count);

  /// No description provided for @commonCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String commonCounter(num current, num total);

  /// No description provided for @commonStateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonStateLoading;

  /// No description provided for @commonStateTitleGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonStateTitleGeneric;

  /// No description provided for @commonStateTitleLoad.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load'**
  String get commonStateTitleLoad;

  /// No description provided for @commonStateTitleNetwork.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commonStateTitleNetwork;

  /// No description provided for @commonStateTitlePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get commonStateTitlePayment;

  /// No description provided for @commonStateTitleNoAccess.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get commonStateTitleNoAccess;

  /// No description provided for @commonStateTitleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get commonStateTitleNotFound;

  /// No description provided for @commonStateTitleEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get commonStateTitleEmptySearch;

  /// No description provided for @commonStateTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get commonStateTitleEmpty;

  /// No description provided for @commonStateOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get commonStateOffline;

  /// No description provided for @commonStateErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Nothing was changed. Please try again.'**
  String get commonStateErrorGeneric;

  /// No description provided for @commonStateErrorLoad.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this. Please try again.'**
  String get commonStateErrorLoad;

  /// No description provided for @commonStateErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t connect. Check your connection and try again.'**
  String get commonStateErrorNetwork;

  /// No description provided for @commonStateErrorPayment.
  ///
  /// In en, this message translates to:
  /// **'The payment could not be completed. No amount was charged.'**
  String get commonStateErrorPayment;

  /// No description provided for @commonStateErrorNoAccess.
  ///
  /// In en, this message translates to:
  /// **'You do not have access. Ask your manager.'**
  String get commonStateErrorNoAccess;

  /// No description provided for @commonStateErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page is no longer available.'**
  String get commonStateErrorNotFound;

  /// No description provided for @commonStateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonStateSaved;

  /// No description provided for @commonStateCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get commonStateCopied;

  /// No description provided for @commonStateSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get commonStateSent;

  /// No description provided for @commonNoPaymentNowFull.
  ///
  /// In en, this message translates to:
  /// **'No payment now. Nothing is charged until the hotel approves.'**
  String get commonNoPaymentNowFull;

  /// No description provided for @commonMoneyDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get commonMoneyDeposit;

  /// No description provided for @commonMoneyBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance'**
  String get commonMoneyBalance;

  /// No description provided for @commonMoneyTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonMoneyTotal;

  /// No description provided for @commonMoneyServiceCharge.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get commonMoneyServiceCharge;

  /// No description provided for @commonMoneyRentalFee.
  ///
  /// In en, this message translates to:
  /// **'Rental fee'**
  String get commonMoneyRentalFee;

  /// No description provided for @commonLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonLabelOptional;

  /// No description provided for @commonLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonLabelRequired;

  /// No description provided for @commonLabelNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Not decided'**
  String get commonLabelNotDecided;

  /// No description provided for @commonLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonLabelToday;

  /// No description provided for @commonLabelTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonLabelTomorrow;

  /// No description provided for @commonLabelKuwaitTime.
  ///
  /// In en, this message translates to:
  /// **'Kuwait time'**
  String get commonLabelKuwaitTime;

  /// No description provided for @commonLabelSponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get commonLabelSponsored;

  /// No description provided for @commonLabelNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get commonLabelNew;

  /// No description provided for @commonLabelOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonLabelOr;

  /// No description provided for @commonLabelLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get commonLabelLanguage;

  /// No description provided for @commonLabelSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonLabelSettings;

  /// No description provided for @commonLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get commonLanguageEnglish;

  /// No description provided for @commonLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get commonLanguageArabic;

  /// No description provided for @commonFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get commonFieldRequired;

  /// No description provided for @commonFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'This value isn’t valid.'**
  String get commonFieldInvalid;

  /// No description provided for @commonFieldPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'This phone number isn’t valid.'**
  String get commonFieldPhoneInvalid;

  /// No description provided for @commonA11yFavouriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get commonA11yFavouriteAdd;

  /// No description provided for @commonA11yFavouriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get commonA11yFavouriteRemove;

  /// No description provided for @commonA11yCompareAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to compare'**
  String get commonA11yCompareAdd;

  /// No description provided for @commonA11yCompareRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from compare'**
  String get commonA11yCompareRemove;

  /// No description provided for @commonA11yPhotoCounter.
  ///
  /// In en, this message translates to:
  /// **'Photo {current} of {total}'**
  String commonA11yPhotoCounter(num current, num total);

  /// No description provided for @commonA11yRating.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of {max}'**
  String commonA11yRating(num rating, num max);

  /// No description provided for @commonA11ySelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get commonA11ySelected;

  /// No description provided for @commonStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusPending;

  /// No description provided for @commonStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get commonStatusApproved;

  /// No description provided for @commonStatusRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get commonStatusRedeemed;

  /// No description provided for @commonStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonStatusDeclined;

  /// No description provided for @commonStatusHotelPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonStatusHotelPending;

  /// No description provided for @commonStatusHotelApproved.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get commonStatusHotelApproved;

  /// No description provided for @commonStatusHotelRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get commonStatusHotelRedeemed;

  /// No description provided for @commonStatusHotelDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonStatusHotelDeclined;

  /// No description provided for @commonStatusHotelLapsed.
  ///
  /// In en, this message translates to:
  /// **'Lapsed'**
  String get commonStatusHotelLapsed;

  /// No description provided for @commonStatusDateProposed.
  ///
  /// In en, this message translates to:
  /// **'New date'**
  String get commonStatusDateProposed;

  /// No description provided for @commonVoucherStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Paying'**
  String get commonVoucherStatusUnpaid;

  /// No description provided for @commonVoucherStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get commonVoucherStatusActive;

  /// No description provided for @commonVoucherStatusBound.
  ///
  /// In en, this message translates to:
  /// **'In request'**
  String get commonVoucherStatusBound;

  /// No description provided for @commonVoucherStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get commonVoucherStatusUsed;

  /// No description provided for @commonVoucherStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get commonVoucherStatusExpired;

  /// No description provided for @commonVisitStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get commonVisitStatusRequested;

  /// No description provided for @commonVisitStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get commonVisitStatusConfirmed;

  /// No description provided for @commonVisitStatusReschedule.
  ///
  /// In en, this message translates to:
  /// **'New time'**
  String get commonVisitStatusReschedule;

  /// No description provided for @commonVisitStatusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get commonVisitStatusArrived;

  /// No description provided for @commonVisitStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonVisitStatusCompleted;

  /// No description provided for @commonVisitStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonVisitStatusDeclined;

  /// No description provided for @commonVisitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get commonVisitStatusCancelled;

  /// No description provided for @commonVisitStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get commonVisitStatusMissed;

  /// No description provided for @commonListingStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get commonListingStatusDraft;

  /// No description provided for @commonListingStatusPayment.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get commonListingStatusPayment;

  /// No description provided for @commonListingStatusReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get commonListingStatusReview;

  /// No description provided for @commonListingStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get commonListingStatusApproved;

  /// No description provided for @commonListingStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get commonListingStatusRejected;

  /// No description provided for @commonListingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get commonListingStatusActive;

  /// No description provided for @commonListingStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get commonListingStatusExpired;

  /// No description provided for @commonListingStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get commonListingStatusPaused;

  /// No description provided for @commonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get commonVoucher;

  /// No description provided for @commonVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get commonVoucherPrice;

  /// No description provided for @commonStandardPrice.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get commonStandardPrice;

  /// No description provided for @commonYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String commonYouSave(String amount);

  /// No description provided for @commonSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String commonSaveAmount(String amount);

  /// No description provided for @commonConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get commonConfirmBooking;

  /// No description provided for @commonRedeemVoucher.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get commonRedeemVoucher;

  /// No description provided for @commonVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Voucher code'**
  String get commonVoucherCode;

  /// No description provided for @commonValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String commonValidUntil(String date);

  /// No description provided for @commonLabelGuestVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher price after you sign up'**
  String get commonLabelGuestVoucher;

  /// No description provided for @commonRoleClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get commonRoleClient;

  /// No description provided for @commonRoleYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonRoleYou;

  /// No description provided for @commonRoleHotelRep.
  ///
  /// In en, this message translates to:
  /// **'Hotel representative'**
  String get commonRoleHotelRep;

  /// No description provided for @commonRoleSupport.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support'**
  String get commonRoleSupport;

  /// No description provided for @commonVenueTypePrivateHall.
  ///
  /// In en, this message translates to:
  /// **'Private hall'**
  String get commonVenueTypePrivateHall;

  /// No description provided for @commonVenueTypeGovernmental.
  ///
  /// In en, this message translates to:
  /// **'Governmental facility'**
  String get commonVenueTypeGovernmental;

  /// No description provided for @commonVenueTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get commonVenueTypeHotel;

  /// No description provided for @commonPricingPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get commonPricingPerPerson;

  /// No description provided for @commonPricingPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get commonPricingPackages;

  /// No description provided for @commonPricingPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get commonPricingPackage;

  /// No description provided for @commonPricingStructure.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get commonPricingStructure;

  /// No description provided for @commonFilterGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get commonFilterGovernorate;

  /// No description provided for @commonFilterVenueType.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get commonFilterVenueType;

  /// No description provided for @commonFilterCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get commonFilterCapacity;

  /// No description provided for @commonPlanWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get commonPlanWeekly;

  /// No description provided for @commonPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get commonPlanMonthly;

  /// No description provided for @commonPlanAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get commonPlanAnnual;

  /// No description provided for @commonRatesSoon.
  ///
  /// In en, this message translates to:
  /// **'Rates announced soon'**
  String get commonRatesSoon;

  /// No description provided for @commonExempt.
  ///
  /// In en, this message translates to:
  /// **'Exempt'**
  String get commonExempt;

  /// No description provided for @commonMajorHotel.
  ///
  /// In en, this message translates to:
  /// **'Major hotel'**
  String get commonMajorHotel;

  /// No description provided for @commonA11yInfo.
  ///
  /// In en, this message translates to:
  /// **'More info'**
  String get commonA11yInfo;

  /// No description provided for @commonLabelDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonLabelDetails;

  /// No description provided for @commonVoucherStatusForfeited.
  ///
  /// In en, this message translates to:
  /// **'Not valid'**
  String get commonVoucherStatusForfeited;

  /// No description provided for @commonVoucherStatusCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get commonVoucherStatusCredit;

  /// No description provided for @commonVoucherStatusCreditIssued.
  ///
  /// In en, this message translates to:
  /// **'Credit issued'**
  String get commonVoucherStatusCreditIssued;

  /// No description provided for @commonVoucherCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit voucher'**
  String get commonVoucherCredit;

  /// No description provided for @commonVoucherAnyVenue.
  ///
  /// In en, this message translates to:
  /// **'Any hall, hotel or service'**
  String get commonVoucherAnyVenue;

  /// No description provided for @commonVoucherNotValidNote.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed within {hours, plural, one{{hours} hour} other{{hours} hours}}'**
  String commonVoucherNotValidNote(int hours);

  /// No description provided for @commonVoucherConfirmIn24h.
  ///
  /// In en, this message translates to:
  /// **'Confirm at the hotel or service within {hours, plural, one{{hours} hour} other{{hours} hours}}, or the voucher is not valid'**
  String commonVoucherConfirmIn24h(int hours);

  /// No description provided for @commonAskSupport.
  ///
  /// In en, this message translates to:
  /// **'Ask support'**
  String get commonAskSupport;

  /// No description provided for @commonCreditRequested.
  ///
  /// In en, this message translates to:
  /// **'Request sent to support'**
  String get commonCreditRequested;

  /// No description provided for @commonBillingContract.
  ///
  /// In en, this message translates to:
  /// **'Business contract'**
  String get commonBillingContract;

  /// No description provided for @commonBillingPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get commonBillingPlan;

  /// No description provided for @commonBillingContractTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms as contracted'**
  String get commonBillingContractTerms;

  /// No description provided for @commonStaffInvitedByEmail.
  ///
  /// In en, this message translates to:
  /// **'Invited by email'**
  String get commonStaffInvitedByEmail;

  /// No description provided for @commonCalendarByEmail.
  ///
  /// In en, this message translates to:
  /// **'Calendar by email'**
  String get commonCalendarByEmail;

  /// No description provided for @commonReviewAskSupportHide.
  ///
  /// In en, this message translates to:
  /// **'Ask support to hide or delete'**
  String get commonReviewAskSupportHide;

  /// No description provided for @commonVideoLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to {size} MB per video'**
  String commonVideoLimit(String size);

  /// No description provided for @uiClientBriefCardDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get uiClientBriefCardDate;

  /// No description provided for @uiClientBriefCardArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get uiClientBriefCardArea;

  /// No description provided for @uiClientBriefCardGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get uiClientBriefCardGuests;

  /// No description provided for @uiClientBriefCardBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get uiClientBriefCardBudget;

  /// No description provided for @uiClientBriefCardNameDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get uiClientBriefCardNameDate;

  /// No description provided for @uiClientBriefCardNameArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get uiClientBriefCardNameArea;

  /// No description provided for @uiClientBriefCardNameGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get uiClientBriefCardNameGuests;

  /// No description provided for @uiClientBriefCardNameBudget.
  ///
  /// In en, this message translates to:
  /// **'Venue and catering budget'**
  String get uiClientBriefCardNameBudget;

  /// No description provided for @uiClientBriefCardRow.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String uiClientBriefCardRow(String label, String value);

  /// No description provided for @uiClientBriefCardShowHalls.
  ///
  /// In en, this message translates to:
  /// **'Show halls'**
  String get uiClientBriefCardShowHalls;

  /// No description provided for @uiClientBriefCardShowCount.
  ///
  /// In en, this message translates to:
  /// **'Show {count}'**
  String uiClientBriefCardShowCount(String count);

  /// No description provided for @uiClientBriefCardMore.
  ///
  /// In en, this message translates to:
  /// **'+{n}'**
  String uiClientBriefCardMore(String n);

  /// No description provided for @uiClientBriefCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your brief'**
  String get uiClientBriefCardTitle;

  /// No description provided for @uiClientBriefSentenceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get uiClientBriefSentenceWomen;

  /// No description provided for @uiClientBriefSentenceMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get uiClientBriefSentenceMen;

  /// No description provided for @uiClientBriefSentenceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed celebration'**
  String get uiClientBriefSentenceMixed;

  /// No description provided for @uiClientBriefSentenceReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get uiClientBriefSentenceReception;

  /// No description provided for @uiClientBriefSentenceForGuests.
  ///
  /// In en, this message translates to:
  /// **'for'**
  String get uiClientBriefSentenceForGuests;

  /// No description provided for @uiClientBriefSentenceOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get uiClientBriefSentenceOn;

  /// No description provided for @uiClientBriefSentenceIn.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get uiClientBriefSentenceIn;

  /// No description provided for @uiClientBriefSentenceBudgetOf.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get uiClientBriefSentenceBudgetOf;

  /// No description provided for @uiClientBriefSentenceChooseGuests.
  ///
  /// In en, this message translates to:
  /// **'add guests'**
  String get uiClientBriefSentenceChooseGuests;

  /// No description provided for @uiClientBriefSentenceChooseDate.
  ///
  /// In en, this message translates to:
  /// **'choose a date'**
  String get uiClientBriefSentenceChooseDate;

  /// No description provided for @uiClientBriefSentenceChooseArea.
  ///
  /// In en, this message translates to:
  /// **'choose an area'**
  String get uiClientBriefSentenceChooseArea;

  /// No description provided for @uiClientBriefSentenceChooseBudget.
  ///
  /// In en, this message translates to:
  /// **'set a budget'**
  String get uiClientBriefSentenceChooseBudget;

  /// No description provided for @uiClientBriefSentenceField.
  ///
  /// In en, this message translates to:
  /// **'Change {what}'**
  String uiClientBriefSentenceField(String what);

  /// No description provided for @uiClientBriefSentenceWhatDate.
  ///
  /// In en, this message translates to:
  /// **'the date'**
  String get uiClientBriefSentenceWhatDate;

  /// No description provided for @uiClientBriefSentenceWhatGuests.
  ///
  /// In en, this message translates to:
  /// **'the guests'**
  String get uiClientBriefSentenceWhatGuests;

  /// No description provided for @uiClientBriefSentenceWhatArea.
  ///
  /// In en, this message translates to:
  /// **'the area'**
  String get uiClientBriefSentenceWhatArea;

  /// No description provided for @uiClientBriefSentenceWhatBudget.
  ///
  /// In en, this message translates to:
  /// **'the budget'**
  String get uiClientBriefSentenceWhatBudget;

  /// No description provided for @uiClientBriefSentenceEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit date, guests, area and budget'**
  String get uiClientBriefSentenceEditLabel;

  /// No description provided for @uiClientVoucherWindowEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get uiClientVoucherWindowEyebrow;

  /// No description provided for @uiClientVoucherWindowEvents.
  ///
  /// In en, this message translates to:
  /// **'For events {window}'**
  String uiClientVoucherWindowEvents(String window);

  /// No description provided for @uiClientVoucherWindowEventsOn.
  ///
  /// In en, this message translates to:
  /// **'For events on {days}'**
  String uiClientVoucherWindowEventsOn(String days);

  /// No description provided for @uiClientVoucherWindowEventsDates.
  ///
  /// In en, this message translates to:
  /// **'For events on selected dates'**
  String get uiClientVoucherWindowEventsDates;

  /// No description provided for @uiClientVoucherWindowUntil.
  ///
  /// In en, this message translates to:
  /// **'Price available until {date}'**
  String uiClientVoucherWindowUntil(String date);

  /// No description provided for @uiClientVoucherWindowView.
  ///
  /// In en, this message translates to:
  /// **'See the hall'**
  String get uiClientVoucherWindowView;

  /// No description provided for @uiClientVoucherWindowEnded.
  ///
  /// In en, this message translates to:
  /// **'This price has ended'**
  String get uiClientVoucherWindowEnded;

  /// No description provided for @uiClientVoucherWindowScheduled.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get uiClientVoucherWindowScheduled;

  /// No description provided for @uiClientVoucherWindowFromTo.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String uiClientVoucherWindowFromTo(String from, String to);

  /// No description provided for @uiClientCountdownEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your wedding'**
  String get uiClientCountdownEyebrow;

  /// No description provided for @uiClientCountdownUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String uiClientCountdownUnit(int count);

  /// No description provided for @uiClientCountdownToGo.
  ///
  /// In en, this message translates to:
  /// **'until your wedding'**
  String get uiClientCountdownToGo;

  /// No description provided for @uiClientCountdownYear.
  ///
  /// In en, this message translates to:
  /// **'A year of planning ahead.'**
  String get uiClientCountdownYear;

  /// No description provided for @uiClientCountdownHalf.
  ///
  /// In en, this message translates to:
  /// **'Six months to go.'**
  String get uiClientCountdownHalf;

  /// No description provided for @uiClientCountdownMonth.
  ///
  /// In en, this message translates to:
  /// **'One month to go. A good time to settle the details.'**
  String get uiClientCountdownMonth;

  /// No description provided for @uiClientCountdownWeek.
  ///
  /// In en, this message translates to:
  /// **'One week to go. Your guest count is now locked.'**
  String get uiClientCountdownWeek;

  /// No description provided for @uiClientCountdownTomorrowLine.
  ///
  /// In en, this message translates to:
  /// **'Everything is set for tomorrow.'**
  String get uiClientCountdownTomorrowLine;

  /// No description provided for @uiClientCountdownTodayLine.
  ///
  /// In en, this message translates to:
  /// **'Today is your day.'**
  String get uiClientCountdownTodayLine;

  /// No description provided for @uiClientCountdownProgress.
  ///
  /// In en, this message translates to:
  /// **'Waiting time elapsed'**
  String get uiClientCountdownProgress;

  /// No description provided for @uiClientCountdownTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get uiClientCountdownTomorrow;

  /// No description provided for @uiClientCountdownToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get uiClientCountdownToday;

  /// No description provided for @uiClientVenueCardTagWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get uiClientVenueCardTagWomen;

  /// No description provided for @uiClientVenueCardTagMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get uiClientVenueCardTagMen;

  /// No description provided for @uiClientVenueCardTagMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get uiClientVenueCardTagMixed;

  /// No description provided for @uiClientVenueCardBookedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Booked on your date'**
  String get uiClientVenueCardBookedOnDate;

  /// No description provided for @uiClientVenueCardGovernment.
  ///
  /// In en, this message translates to:
  /// **'Booked through the Ministry of Social Affairs'**
  String get uiClientVenueCardGovernment;

  /// No description provided for @uiClientVenueCardGovernmentTag.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get uiClientVenueCardGovernmentTag;

  /// No description provided for @uiClientVenueCardFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get uiClientVenueCardFeatured;

  /// No description provided for @uiClientVenueCardWindow.
  ///
  /// In en, this message translates to:
  /// **'Special voucher price'**
  String get uiClientVenueCardWindow;

  /// No description provided for @uiClientVenueCardNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos coming soon'**
  String get uiClientVenueCardNoPhotos;

  /// No description provided for @uiClientVenueCardHasVideo.
  ///
  /// In en, this message translates to:
  /// **'Has a video tour'**
  String get uiClientVenueCardHasVideo;

  /// No description provided for @uiClientVenueCardPriceDropped.
  ///
  /// In en, this message translates to:
  /// **'Price dropped'**
  String get uiClientVenueCardPriceDropped;

  /// No description provided for @uiClientVenueCardSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose this hall'**
  String get uiClientVenueCardSelect;

  /// No description provided for @uiClientVenueCardPhotosOf.
  ///
  /// In en, this message translates to:
  /// **'Photos of {name}'**
  String uiClientVenueCardPhotosOf(String name);

  /// No description provided for @uiClientVenueCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String uiClientVenueCardOpen(String name);

  /// No description provided for @uiClientCompareAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one more to compare'**
  String get uiClientCompareAddOne;

  /// No description provided for @uiClientCompareCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get uiClientCompareCompare;

  /// No description provided for @uiClientCompareRemoveFrom.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from compare'**
  String uiClientCompareRemoveFrom(String name);

  /// No description provided for @uiClientCompareClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the comparison'**
  String get uiClientCompareClear;

  /// No description provided for @uiClientCompareExpand.
  ///
  /// In en, this message translates to:
  /// **'Show the comparison tray'**
  String get uiClientCompareExpand;

  /// No description provided for @uiClientCompareEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot {n}'**
  String uiClientCompareEmptySlot(String n);

  /// No description provided for @uiClientCompareTrayLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare ({pair})'**
  String uiClientCompareTrayLabel(String pair);

  /// No description provided for @uiClientCompareBest.
  ///
  /// In en, this message translates to:
  /// **'Best in row'**
  String get uiClientCompareBest;

  /// No description provided for @uiClientCompareDifferences.
  ///
  /// In en, this message translates to:
  /// **'Differences only'**
  String get uiClientCompareDifferences;

  /// No description provided for @uiClientCompareHidden.
  ///
  /// In en, this message translates to:
  /// **'{n} matching rows hidden'**
  String uiClientCompareHidden(String n);

  /// No description provided for @uiClientCompareHiddenOne.
  ///
  /// In en, this message translates to:
  /// **'1 matching row hidden'**
  String get uiClientCompareHiddenOne;

  /// No description provided for @uiClientCompareAllShown.
  ///
  /// In en, this message translates to:
  /// **'All rows shown'**
  String get uiClientCompareAllShown;

  /// No description provided for @uiClientCompareNoLonger.
  ///
  /// In en, this message translates to:
  /// **'No longer listed'**
  String get uiClientCompareNoLonger;

  /// No description provided for @uiClientCompareYours.
  ///
  /// In en, this message translates to:
  /// **'your {n}'**
  String uiClientCompareYours(String n);

  /// No description provided for @uiClientCompareOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String uiClientCompareOpen(String name);

  /// No description provided for @uiClientComparePick.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String uiClientComparePick(String name);

  /// No description provided for @uiClientCompareUnpick.
  ///
  /// In en, this message translates to:
  /// **'Unchoose {name}'**
  String uiClientCompareUnpick(String name);

  /// No description provided for @uiClientCompareGroupDate.
  ///
  /// In en, this message translates to:
  /// **'Your date'**
  String get uiClientCompareGroupDate;

  /// No description provided for @uiClientCompareGroupPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get uiClientCompareGroupPrice;

  /// No description provided for @uiClientCompareGroupCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity and layout'**
  String get uiClientCompareGroupCapacity;

  /// No description provided for @uiClientCompareGroupFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get uiClientCompareGroupFacilities;

  /// No description provided for @uiClientCompareRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get uiClientCompareRating;

  /// No description provided for @uiClientCompareGroupDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get uiClientCompareGroupDistance;

  /// No description provided for @uiClientCompareGroupBooking.
  ///
  /// In en, this message translates to:
  /// **'Type and structure'**
  String get uiClientCompareGroupBooking;

  /// No description provided for @uiClientComparePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get uiClientComparePhotos;

  /// No description provided for @uiClientCompareRowAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get uiClientCompareRowAvailability;

  /// No description provided for @uiClientCompareRowPriceDate.
  ///
  /// In en, this message translates to:
  /// **'Voucher price for your date'**
  String get uiClientCompareRowPriceDate;

  /// No description provided for @uiClientCompareRowPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'Voucher price from'**
  String get uiClientCompareRowPriceFrom;

  /// No description provided for @uiClientCompareRowStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get uiClientCompareRowStandard;

  /// No description provided for @uiClientCompareRowSavings.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get uiClientCompareRowSavings;

  /// No description provided for @uiClientCompareNoVoucher.
  ///
  /// In en, this message translates to:
  /// **'No voucher price'**
  String get uiClientCompareNoVoucher;

  /// No description provided for @uiClientCompareRowPerGuest.
  ///
  /// In en, this message translates to:
  /// **'Per guest'**
  String get uiClientCompareRowPerGuest;

  /// No description provided for @uiClientCompareRowCapacity.
  ///
  /// In en, this message translates to:
  /// **'Largest hall'**
  String get uiClientCompareRowCapacity;

  /// No description provided for @uiClientCompareRowValet.
  ///
  /// In en, this message translates to:
  /// **'Valet'**
  String get uiClientCompareRowValet;

  /// No description provided for @uiClientCompareRowPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get uiClientCompareRowPhotography;

  /// No description provided for @uiClientCompareRowDistance.
  ///
  /// In en, this message translates to:
  /// **'Drive from {origin}'**
  String uiClientCompareRowDistance(String origin);

  /// No description provided for @uiClientCompareRowPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get uiClientCompareRowPackages;

  /// No description provided for @uiClientCompareRowType.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get uiClientCompareRowType;

  /// No description provided for @uiClientComparePickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get uiClientComparePickDate;

  /// No description provided for @uiClientCompareIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get uiClientCompareIncluded;

  /// No description provided for @uiClientCompareExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get uiClientCompareExtra;

  /// No description provided for @uiClientCompareNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get uiClientCompareNotOffered;

  /// No description provided for @uiClientCompareWomenOnly.
  ///
  /// In en, this message translates to:
  /// **'Women only'**
  String get uiClientCompareWomenOnly;

  /// No description provided for @uiClientCompareAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get uiClientCompareAllowed;

  /// No description provided for @uiClientCompareNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get uiClientCompareNotAllowed;

  /// No description provided for @uiClientCompareFits.
  ///
  /// In en, this message translates to:
  /// **'Fits {n}'**
  String uiClientCompareFits(String n);

  /// No description provided for @uiClientCompareBelow.
  ///
  /// In en, this message translates to:
  /// **'Below {n}'**
  String uiClientCompareBelow(String n);

  /// No description provided for @uiClientCompareUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {n}'**
  String uiClientCompareUpTo(String n);

  /// No description provided for @uiClientComparePerGuestUnit.
  ///
  /// In en, this message translates to:
  /// **'per guest'**
  String get uiClientComparePerGuestUnit;

  /// No description provided for @uiClientCompareGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Get voucher'**
  String get uiClientCompareGetVoucher;

  /// No description provided for @uiClientCompareOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get uiClientCompareOfficial;

  /// No description provided for @uiClientCompareSeeDates.
  ///
  /// In en, this message translates to:
  /// **'See dates'**
  String get uiClientCompareSeeDates;

  /// No description provided for @uiClientCompareBestRated.
  ///
  /// In en, this message translates to:
  /// **'Best rated'**
  String get uiClientCompareBestRated;

  /// No description provided for @uiClientCompareLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get uiClientCompareLowest;

  /// No description provided for @uiClientCompareClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest'**
  String get uiClientCompareClosest;

  /// No description provided for @uiClientCompareTypeOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official channel'**
  String get uiClientCompareTypeOfficial;

  /// No description provided for @uiClientComparePerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get uiClientComparePerPerson;

  /// No description provided for @uiClientComparePackagesWord.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get uiClientComparePackagesWord;

  /// No description provided for @uiClientCompareBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get uiClientCompareBoth;

  /// No description provided for @uiClientReviewAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous guest'**
  String get uiClientReviewAnonymous;

  /// No description provided for @uiClientReviewVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified booking'**
  String get uiClientReviewVerified;

  /// No description provided for @uiClientReviewReply.
  ///
  /// In en, this message translates to:
  /// **'Reply from {venue}'**
  String uiClientReviewReply(String venue);

  /// No description provided for @uiClientReviewMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get uiClientReviewMore;

  /// No description provided for @uiClientReviewLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get uiClientReviewLess;

  /// No description provided for @uiClientReviewPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos from this event'**
  String get uiClientReviewPhotos;

  /// No description provided for @uiClientReviewLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get uiClientReviewLadies;

  /// No description provided for @uiClientReviewMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get uiClientReviewMen;

  /// No description provided for @uiClientReviewCatVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get uiClientReviewCatVenue;

  /// No description provided for @uiClientReviewCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get uiClientReviewCatFood;

  /// No description provided for @uiClientReviewCatService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get uiClientReviewCatService;

  /// No description provided for @uiClientReviewCatValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get uiClientReviewCatValue;

  /// No description provided for @uiClientReviewNone.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. The first guests will write here after their event.'**
  String get uiClientReviewNone;

  /// No description provided for @uiClientReviewScore.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String uiClientReviewScore(String label, String value);

  /// No description provided for @uiClientVenueInfoGroupSpace.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get uiClientVenueInfoGroupSpace;

  /// No description provided for @uiClientVenueInfoGroupService.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get uiClientVenueInfoGroupService;

  /// No description provided for @uiClientVenueInfoGroupProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get uiClientVenueInfoGroupProduction;

  /// No description provided for @uiClientVenueInfoGroupPolicy.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get uiClientVenueInfoGroupPolicy;

  /// No description provided for @uiClientVenueInfoIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get uiClientVenueInfoIncluded;

  /// No description provided for @uiClientVenueInfoExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get uiClientVenueInfoExtra;

  /// No description provided for @uiClientVenueInfoExtraFrom.
  ///
  /// In en, this message translates to:
  /// **'Extra, from {price}'**
  String uiClientVenueInfoExtraFrom(String price);

  /// No description provided for @uiClientVenueInfoNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get uiClientVenueInfoNotOffered;

  /// No description provided for @uiClientVenueInfoShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {n} facilities'**
  String uiClientVenueInfoShowAll(String n);

  /// No description provided for @uiClientVenueInfoShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get uiClientVenueInfoShowLess;

  /// No description provided for @uiClientVenueInfoPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get uiClientVenueInfoPhotography;

  /// No description provided for @uiClientVenueInfoMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get uiClientVenueInfoMusic;

  /// No description provided for @uiClientVenueInfoEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get uiClientVenueInfoEntrance;

  /// No description provided for @uiClientVenueInfoCloakroom.
  ///
  /// In en, this message translates to:
  /// **'Abaya cloakroom'**
  String get uiClientVenueInfoCloakroom;

  /// No description provided for @uiClientVenueInfoPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer room'**
  String get uiClientVenueInfoPrayer;

  /// No description provided for @uiClientVenueInfoSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get uiClientVenueInfoSecurity;

  /// No description provided for @uiClientVenueInfoBoys.
  ///
  /// In en, this message translates to:
  /// **'Boys'**
  String get uiClientVenueInfoBoys;

  /// No description provided for @uiClientVenueInfoCatering.
  ///
  /// In en, this message translates to:
  /// **'Outside catering'**
  String get uiClientVenueInfoCatering;

  /// No description provided for @uiClientVenueInfoDecor.
  ///
  /// In en, this message translates to:
  /// **'Outside decor'**
  String get uiClientVenueInfoDecor;

  /// No description provided for @uiClientVenueInfoBukhoor.
  ///
  /// In en, this message translates to:
  /// **'Bukhoor'**
  String get uiClientVenueInfoBukhoor;

  /// No description provided for @uiClientVenueInfoCutOff.
  ///
  /// In en, this message translates to:
  /// **'Event ends by'**
  String get uiClientVenueInfoCutOff;

  /// No description provided for @uiClientVenueInfoExtraHour.
  ///
  /// In en, this message translates to:
  /// **'Extra hour'**
  String get uiClientVenueInfoExtraHour;

  /// No description provided for @uiClientVenueInfoBackup.
  ///
  /// In en, this message translates to:
  /// **'Indoor backup'**
  String get uiClientVenueInfoBackup;

  /// No description provided for @uiClientVenueInfoPhotoFemale.
  ///
  /// In en, this message translates to:
  /// **'Female photographers only'**
  String get uiClientVenueInfoPhotoFemale;

  /// No description provided for @uiClientVenueInfoPhotoAllowed.
  ///
  /// In en, this message translates to:
  /// **'Photography allowed'**
  String get uiClientVenueInfoPhotoAllowed;

  /// No description provided for @uiClientVenueInfoPhotoNone.
  ///
  /// In en, this message translates to:
  /// **'No photography'**
  String get uiClientVenueInfoPhotoNone;

  /// No description provided for @uiClientVenueInfoMusicBand.
  ///
  /// In en, this message translates to:
  /// **'DJ or band'**
  String get uiClientVenueInfoMusicBand;

  /// No description provided for @uiClientVenueInfoMusicLive.
  ///
  /// In en, this message translates to:
  /// **'Live music'**
  String get uiClientVenueInfoMusicLive;

  /// No description provided for @uiClientVenueInfoMusicDuff.
  ///
  /// In en, this message translates to:
  /// **'Duff and nasheed only'**
  String get uiClientVenueInfoMusicDuff;

  /// No description provided for @uiClientVenueInfoMusicNone.
  ///
  /// In en, this message translates to:
  /// **'No music'**
  String get uiClientVenueInfoMusicNone;

  /// No description provided for @uiClientVenueInfoNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get uiClientVenueInfoNo;

  /// No description provided for @uiClientVenueInfoSeparate.
  ///
  /// In en, this message translates to:
  /// **'Separate entrance'**
  String get uiClientVenueInfoSeparate;

  /// No description provided for @uiClientVenueInfoSecurityFemale.
  ///
  /// In en, this message translates to:
  /// **'Female security'**
  String get uiClientVenueInfoSecurityFemale;

  /// No description provided for @uiClientVenueInfoBoysUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to age {n}'**
  String uiClientVenueInfoBoysUpTo(String n);

  /// No description provided for @uiClientVenueInfoBoysAny.
  ///
  /// In en, this message translates to:
  /// **'Any age'**
  String get uiClientVenueInfoBoysAny;

  /// No description provided for @uiClientVenueInfoAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get uiClientVenueInfoAllowed;

  /// No description provided for @uiClientVenueInfoApproval.
  ///
  /// In en, this message translates to:
  /// **'With the hotel’s approval'**
  String get uiClientVenueInfoApproval;

  /// No description provided for @uiClientVenueInfoNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get uiClientVenueInfoNotAllowed;

  /// No description provided for @uiClientVenueInfoAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get uiClientVenueInfoAvailable;

  /// No description provided for @uiClientVenueInfoMapOpen.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get uiClientVenueInfoMapOpen;

  /// No description provided for @uiClientVenueInfoMapDrive.
  ///
  /// In en, this message translates to:
  /// **'{time} from {origin}'**
  String uiClientVenueInfoMapDrive(String time, String origin);

  /// No description provided for @uiClientVenueInfoMapPin.
  ///
  /// In en, this message translates to:
  /// **'Location of {name}'**
  String uiClientVenueInfoMapPin(String name);

  /// No description provided for @uiClientVenueInfoBlock.
  ///
  /// In en, this message translates to:
  /// **'Block {n}'**
  String uiClientVenueInfoBlock(String n);

  /// No description provided for @uiClientChecklistDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String uiClientChecklistDone(String done, String total);

  /// No description provided for @uiClientChecklistProgress.
  ///
  /// In en, this message translates to:
  /// **'Checklist progress'**
  String get uiClientChecklistProgress;

  /// No description provided for @uiClientChecklistDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String uiClientChecklistDue(String date);

  /// No description provided for @uiClientChecklistOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue since {date}'**
  String uiClientChecklistOverdue(String date);

  /// No description provided for @uiClientChecklistNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get uiClientChecklistNoDate;

  /// No description provided for @uiClientChecklistAuto.
  ///
  /// In en, this message translates to:
  /// **'Completes when your booking is confirmed'**
  String get uiClientChecklistAuto;

  /// No description provided for @uiClientChecklistCompletedOn.
  ///
  /// In en, this message translates to:
  /// **'Done {date}'**
  String uiClientChecklistCompletedOn(String date);

  /// No description provided for @uiClientChecklistChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get uiClientChecklistChoose;

  /// No description provided for @uiClientChecklistYours.
  ///
  /// In en, this message translates to:
  /// **'Your task'**
  String get uiClientChecklistYours;

  /// No description provided for @uiClientBudgetTotal.
  ///
  /// In en, this message translates to:
  /// **'Wedding budget'**
  String get uiClientBudgetTotal;

  /// No description provided for @uiClientBudgetPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get uiClientBudgetPaid;

  /// No description provided for @uiClientBudgetCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get uiClientBudgetCommitted;

  /// No description provided for @uiClientBudgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get uiClientBudgetRemaining;

  /// No description provided for @uiClientBudgetOf.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {allocated}'**
  String uiClientBudgetOf(String paid, String allocated);

  /// No description provided for @uiClientBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String uiClientBudgetOver(String amount);

  /// No description provided for @uiClientBudgetAlertCategory.
  ///
  /// In en, this message translates to:
  /// **'{name} is over its share of the budget.'**
  String uiClientBudgetAlertCategory(String name);

  /// No description provided for @uiClientBudgetAlertTotal.
  ///
  /// In en, this message translates to:
  /// **'Your plans are above your total budget.'**
  String get uiClientBudgetAlertTotal;

  /// No description provided for @uiClientBudgetLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to your booking'**
  String get uiClientBudgetLinked;

  /// No description provided for @uiClientBudgetCategories.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get uiClientBudgetCategories;

  /// No description provided for @uiClientBudgetBarLabel.
  ///
  /// In en, this message translates to:
  /// **'{paid}: {paidAmount}, {committed}: {committedAmount}, {remaining}: {remainingAmount}'**
  String uiClientBudgetBarLabel(
    String paid,
    String paidAmount,
    String committed,
    String committedAmount,
    String remaining,
    String remainingAmount,
  );

  /// No description provided for @uiClientTierSuits.
  ///
  /// In en, this message translates to:
  /// **'Suits'**
  String get uiClientTierSuits;

  /// No description provided for @uiClientTierConsult.
  ///
  /// In en, this message translates to:
  /// **'Request consultation'**
  String get uiClientTierConsult;

  /// No description provided for @uiClientTierMarks.
  ///
  /// In en, this message translates to:
  /// **'{n} of 3 marks'**
  String uiClientTierMarks(String n);

  /// No description provided for @uiClientServiceOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String uiClientServiceOpen(String name);

  /// No description provided for @uiClientVendorVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get uiClientVendorVerified;

  /// No description provided for @uiClientVendorFemaleTeam.
  ///
  /// In en, this message translates to:
  /// **'Female team for ladies’ halls'**
  String get uiClientVendorFemaleTeam;

  /// No description provided for @uiClientVendorReplies.
  ///
  /// In en, this message translates to:
  /// **'Usually replies within {time}'**
  String uiClientVendorReplies(String time);

  /// No description provided for @uiClientChatSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get uiClientChatSent;

  /// No description provided for @uiClientChatDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get uiClientChatDelivered;

  /// No description provided for @uiClientChatRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get uiClientChatRead;

  /// No description provided for @uiClientChatPlay.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get uiClientChatPlay;

  /// No description provided for @uiClientChatPause.
  ///
  /// In en, this message translates to:
  /// **'Pause voice message'**
  String get uiClientChatPause;

  /// No description provided for @uiClientChatVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get uiClientChatVoice;

  /// No description provided for @uiClientChatPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get uiClientChatPhoto;

  /// No description provided for @uiClientChatDownload.
  ///
  /// In en, this message translates to:
  /// **'Download {name}'**
  String uiClientChatDownload(String name);

  /// No description provided for @uiClientChatOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get uiClientChatOpenPhoto;

  /// No description provided for @uiClientChatPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get uiClientChatPdf;

  /// No description provided for @uiClientChatKb.
  ///
  /// In en, this message translates to:
  /// **'{n} KB'**
  String uiClientChatKb(String n);

  /// No description provided for @uiClientChatDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get uiClientChatDraft;

  /// No description provided for @uiClientChatYou.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get uiClientChatYou;

  /// No description provided for @uiClientChatPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get uiClientChatPinned;

  /// No description provided for @uiClientChatUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unread message} other{{count} unread messages}}'**
  String uiClientChatUnread(int count);

  /// No description provided for @uiClientThreadVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get uiClientThreadVoucher;

  /// No description provided for @uiClientThreadRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get uiClientThreadRequest;

  /// No description provided for @uiClientThreadApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get uiClientThreadApproval;

  /// No description provided for @uiClientThreadConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get uiClientThreadConfirmation;

  /// No description provided for @uiClientThreadRedemption.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get uiClientThreadRedemption;

  /// No description provided for @uiClientThreadVoucherLong.
  ///
  /// In en, this message translates to:
  /// **'Voucher bought'**
  String get uiClientThreadVoucherLong;

  /// No description provided for @uiClientThreadRequestLong.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get uiClientThreadRequestLong;

  /// No description provided for @uiClientThreadApprovalLong.
  ///
  /// In en, this message translates to:
  /// **'Venue approval'**
  String get uiClientThreadApprovalLong;

  /// No description provided for @uiClientThreadConfirmationLong.
  ///
  /// In en, this message translates to:
  /// **'You confirmed'**
  String get uiClientThreadConfirmationLong;

  /// No description provided for @uiClientThreadRedemptionLong.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get uiClientThreadRedemptionLong;

  /// No description provided for @uiClientThreadConfirmationStep.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get uiClientThreadConfirmationStep;

  /// No description provided for @uiClientThreadRedemptionStep.
  ///
  /// In en, this message translates to:
  /// **'At venue'**
  String get uiClientThreadRedemptionStep;

  /// No description provided for @uiClientThreadConfirmationStepLong.
  ///
  /// In en, this message translates to:
  /// **'Your confirmation'**
  String get uiClientThreadConfirmationStepLong;

  /// No description provided for @uiClientThreadRedemptionStepLong.
  ///
  /// In en, this message translates to:
  /// **'At the venue'**
  String get uiClientThreadRedemptionStepLong;

  /// No description provided for @uiClientThreadNotRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Not redeemed'**
  String get uiClientThreadNotRedeemed;

  /// No description provided for @uiClientThreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking progress'**
  String get uiClientThreadLabel;

  /// No description provided for @uiClientThreadStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String uiClientThreadStepOf(String n, String total);

  /// No description provided for @uiClientBookingCardDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get uiClientBookingCardDate;

  /// No description provided for @uiClientBookingCardVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get uiClientBookingCardVoucherPrice;

  /// No description provided for @uiClientBookingCardQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get uiClientBookingCardQuantity;

  /// No description provided for @uiClientBookingCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Open booking {ref}'**
  String uiClientBookingCardOpen(String ref);

  /// No description provided for @uiClientBookingCardConfirmBy.
  ///
  /// In en, this message translates to:
  /// **'Confirm by {when} · {left}'**
  String uiClientBookingCardConfirmBy(String when, String left);

  /// No description provided for @uiClientPackageHallOnly.
  ///
  /// In en, this message translates to:
  /// **'hall hire'**
  String get uiClientPackageHallOnly;

  /// No description provided for @uiClientPackagePlus.
  ///
  /// In en, this message translates to:
  /// **'plus'**
  String get uiClientPackagePlus;

  /// No description provided for @uiClientPackageForGuests.
  ///
  /// In en, this message translates to:
  /// **'for {guests}'**
  String uiClientPackageForGuests(String guests);

  /// No description provided for @uiClientPackageUpTo.
  ///
  /// In en, this message translates to:
  /// **'up to {guests}'**
  String uiClientPackageUpTo(String guests);

  /// No description provided for @uiClientPackageIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get uiClientPackageIncluded;

  /// No description provided for @uiClientPackageNotCovered.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get uiClientPackageNotCovered;

  /// No description provided for @uiClientPackageSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get uiClientPackageSelected;

  /// No description provided for @uiClientPackageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on your date'**
  String get uiClientPackageUnavailable;

  /// No description provided for @uiClientPackageShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {n} inclusions'**
  String uiClientPackageShowAll(String n);

  /// No description provided for @uiClientPackageShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get uiClientPackageShowLess;

  /// No description provided for @uiClientPackageLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get uiClientPackageLadies;

  /// No description provided for @uiClientPackageMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get uiClientPackageMen;

  /// No description provided for @uiClientPackageMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get uiClientPackageMixed;

  /// No description provided for @uiClientBreakdownLines.
  ///
  /// In en, this message translates to:
  /// **'Price details'**
  String get uiClientBreakdownLines;

  /// No description provided for @uiClientBreakdownStandardTotal.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get uiClientBreakdownStandardTotal;

  /// No description provided for @uiClientBreakdownVoucherTotal.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get uiClientBreakdownVoucherTotal;

  /// No description provided for @uiClientBreakdownSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get uiClientBreakdownSave;

  /// No description provided for @uiClientBreakdownWho.
  ///
  /// In en, this message translates to:
  /// **'Who you pay'**
  String get uiClientBreakdownWho;

  /// No description provided for @uiClientBreakdownGhazal.
  ///
  /// In en, this message translates to:
  /// **'Ghazal · your voucher'**
  String get uiClientBreakdownGhazal;

  /// No description provided for @uiClientBreakdownGhazalPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid once, when you got the voucher'**
  String get uiClientBreakdownGhazalPaid;

  /// No description provided for @uiClientBreakdownVenue.
  ///
  /// In en, this message translates to:
  /// **'{venue} · directly'**
  String uiClientBreakdownVenue(String venue);

  /// No description provided for @uiClientBreakdownVenueReview.
  ///
  /// In en, this message translates to:
  /// **'After you confirm, you pay the venue yourself at this price.'**
  String get uiClientBreakdownVenueReview;

  /// No description provided for @uiClientBreakdownVenueConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Pay the venue directly, then show your voucher code.'**
  String get uiClientBreakdownVenueConfirmed;

  /// No description provided for @uiClientBreakdownVenueRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Settled with the venue. The voucher was redeemed.'**
  String get uiClientBreakdownVenueRedeemed;

  /// No description provided for @uiClientBreakdownInclusive.
  ///
  /// In en, this message translates to:
  /// **'All-in at the venue’s own terms. Ghazal adds nothing to this price.'**
  String get uiClientBreakdownInclusive;

  /// No description provided for @uiClientBreakdownNoMore.
  ///
  /// In en, this message translates to:
  /// **'Nothing more to pay Ghazal.'**
  String get uiClientBreakdownNoMore;

  /// No description provided for @uiClientPaymentKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get uiClientPaymentKnet;

  /// No description provided for @uiClientPaymentKnetNote.
  ///
  /// In en, this message translates to:
  /// **'Kuwaiti bank cards'**
  String get uiClientPaymentKnetNote;

  /// No description provided for @uiClientPaymentVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get uiClientPaymentVisa;

  /// No description provided for @uiClientPaymentMastercard.
  ///
  /// In en, this message translates to:
  /// **'Mastercard'**
  String get uiClientPaymentMastercard;

  /// No description provided for @uiClientPaymentCardNote.
  ///
  /// In en, this message translates to:
  /// **'Credit or debit card'**
  String get uiClientPaymentCardNote;

  /// No description provided for @uiClientPaymentApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get uiClientPaymentApplePay;

  /// No description provided for @uiClientPaymentApplePayNote.
  ///
  /// In en, this message translates to:
  /// **'With the card on your device'**
  String get uiClientPaymentApplePayNote;

  /// No description provided for @uiClientPaymentGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get uiClientPaymentGooglePay;

  /// No description provided for @uiClientPaymentGooglePayNote.
  ///
  /// In en, this message translates to:
  /// **'With the card on your device'**
  String get uiClientPaymentGooglePayNote;

  /// No description provided for @uiClientPaymentRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended after a KNET limit'**
  String get uiClientPaymentRecommended;

  /// No description provided for @uiClientPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get uiClientPaymentUnavailable;

  /// No description provided for @uiClientPaymentSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get uiClientPaymentSelected;

  /// No description provided for @uiClientReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get uiClientReceiptTitle;

  /// No description provided for @uiClientReceiptIssuer.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get uiClientReceiptIssuer;

  /// No description provided for @uiClientReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get uiClientReceiptNumber;

  /// No description provided for @uiClientReceiptVoucherCode.
  ///
  /// In en, this message translates to:
  /// **'Voucher code'**
  String get uiClientReceiptVoucherCode;

  /// No description provided for @uiClientReceiptIssued.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get uiClientReceiptIssued;

  /// No description provided for @uiClientReceiptVia.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get uiClientReceiptVia;

  /// No description provided for @uiClientReceiptLine.
  ///
  /// In en, this message translates to:
  /// **'Voucher for {name}'**
  String uiClientReceiptLine(String name);

  /// No description provided for @uiClientReceiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get uiClientReceiptTotal;

  /// No description provided for @uiClientReceiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Issued in Kuwaiti dinars (KWD). Western digits, three decimals.'**
  String get uiClientReceiptFooter;

  /// No description provided for @uiClientNotificationUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get uiClientNotificationUnread;

  /// No description provided for @uiClientNotificationMarketing.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get uiClientNotificationMarketing;

  /// No description provided for @uiFiltersGovernorateAll.
  ///
  /// In en, this message translates to:
  /// **'All Kuwait'**
  String get uiFiltersGovernorateAll;

  /// No description provided for @uiFiltersCapacityFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get uiFiltersCapacityFrom;

  /// No description provided for @uiFiltersCapacityTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get uiFiltersCapacityTo;

  /// No description provided for @uiFiltersCapacitySummary.
  ///
  /// In en, this message translates to:
  /// **'{range} guests'**
  String uiFiltersCapacitySummary(String range);

  /// No description provided for @uiFiltersCapacityMin.
  ///
  /// In en, this message translates to:
  /// **'Fewest guests'**
  String get uiFiltersCapacityMin;

  /// No description provided for @uiFiltersCapacityMax.
  ///
  /// In en, this message translates to:
  /// **'Most guests'**
  String get uiFiltersCapacityMax;

  /// No description provided for @uiHotelTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String uiHotelTimeLeft(String time);

  /// No description provided for @uiHotelRowNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get uiHotelRowNew;

  /// No description provided for @uiHotelCardPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get uiHotelCardPackage;

  /// No description provided for @uiHotelCardVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get uiHotelCardVoucherPrice;

  /// No description provided for @uiHotelCardNoOther.
  ///
  /// In en, this message translates to:
  /// **'No other request for this date'**
  String get uiHotelCardNoOther;

  /// No description provided for @uiHotelCardVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified phone'**
  String get uiHotelCardVerified;

  /// No description provided for @uiHotelCardFirstBooking.
  ///
  /// In en, this message translates to:
  /// **'First booking'**
  String get uiHotelCardFirstBooking;

  /// No description provided for @uiHotelCardCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get uiHotelCardCompare;

  /// No description provided for @uiHotelCardHeld.
  ///
  /// In en, this message translates to:
  /// **'Date held'**
  String get uiHotelCardHeld;

  /// No description provided for @uiHotelCardHeldReason.
  ///
  /// In en, this message translates to:
  /// **'Date on hold'**
  String get uiHotelCardHeldReason;

  /// No description provided for @uiHotelCardConfirmBy.
  ///
  /// In en, this message translates to:
  /// **'Client confirms by'**
  String get uiHotelCardConfirmBy;

  /// No description provided for @uiHotelCardUndoMessage.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get uiHotelCardUndoMessage;

  /// No description provided for @uiHotelCardChat.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String uiHotelCardChat(String name);

  /// No description provided for @uiHotelCardCall.
  ///
  /// In en, this message translates to:
  /// **'Call {name}'**
  String uiHotelCardCall(String name);

  /// No description provided for @uiHotelCardOpen.
  ///
  /// In en, this message translates to:
  /// **'Open request: {date}'**
  String uiHotelCardOpen(String date);

  /// No description provided for @uiHotelCardTagWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get uiHotelCardTagWomen;

  /// No description provided for @uiHotelCardTagMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get uiHotelCardTagMen;

  /// No description provided for @uiHotelCardTagMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get uiHotelCardTagMixed;

  /// No description provided for @uiHotelCardHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get uiHotelCardHours;

  /// No description provided for @uiHotelCardSpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get uiHotelCardSpecialRequests;

  /// No description provided for @uiHotelCardOthers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{other request for this date} other{other requests for this date}}'**
  String uiHotelCardOthers(int count);

  /// No description provided for @uiHotelTimelineNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get uiHotelTimelineNow;

  /// No description provided for @uiHotelTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today'**
  String get uiHotelTimelineEmpty;

  /// No description provided for @uiHotelStripConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get uiHotelStripConfirmed;

  /// No description provided for @uiHotelStripPending.
  ///
  /// In en, this message translates to:
  /// **'Pending or on hold'**
  String get uiHotelStripPending;

  /// No description provided for @uiHotelStripOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiHotelStripOpen;

  /// No description provided for @uiHotelStripToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get uiHotelStripToday;

  /// No description provided for @uiHotelStripSep.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get uiHotelStripSep;

  /// No description provided for @uiHotelStripConfirmedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} confirmed}}'**
  String uiHotelStripConfirmedCount(int count);

  /// No description provided for @uiHotelStripPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} pending}}'**
  String uiHotelStripPendingCount(int count);

  /// No description provided for @uiHotelStripOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} open}}'**
  String uiHotelStripOpenCount(int count);

  /// No description provided for @uiHotelKpiUp.
  ///
  /// In en, this message translates to:
  /// **'up {pct}'**
  String uiHotelKpiUp(String pct);

  /// No description provided for @uiHotelKpiDown.
  ///
  /// In en, this message translates to:
  /// **'down {pct}'**
  String uiHotelKpiDown(String pct);

  /// No description provided for @uiHotelKpiFlat.
  ///
  /// In en, this message translates to:
  /// **'unchanged'**
  String get uiHotelKpiFlat;

  /// No description provided for @uiHotelOccBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get uiHotelOccBooked;

  /// No description provided for @uiHotelOccHeld.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get uiHotelOccHeld;

  /// No description provided for @uiHotelOccBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get uiHotelOccBlocked;

  /// No description provided for @uiHotelOccOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiHotelOccOpen;

  /// No description provided for @uiHotelOccOf.
  ///
  /// In en, this message translates to:
  /// **'{booked} of {total} hall-nights booked'**
  String uiHotelOccOf(String booked, String total);

  /// No description provided for @uiHotelOccNights.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{hall-night} other{hall-nights}}'**
  String uiHotelOccNights(int count);

  /// No description provided for @uiHotelVactRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests received'**
  String get uiHotelVactRequests;

  /// No description provided for @uiHotelVactAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client to confirm'**
  String get uiHotelVactAwaiting;

  /// No description provided for @uiHotelVactRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Vouchers redeemed'**
  String get uiHotelVactRedeemed;

  /// No description provided for @uiHotelVactChart.
  ///
  /// In en, this message translates to:
  /// **'Vouchers bought per day'**
  String get uiHotelVactChart;

  /// No description provided for @uiHotelVactDaily.
  ///
  /// In en, this message translates to:
  /// **'Bought per day'**
  String get uiHotelVactDaily;

  /// No description provided for @uiHotelCalFree.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get uiHotelCalFree;

  /// No description provided for @uiHotelCalRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get uiHotelCalRequest;

  /// No description provided for @uiHotelCalRequestLegend.
  ///
  /// In en, this message translates to:
  /// **'Pending request'**
  String get uiHotelCalRequestLegend;

  /// No description provided for @uiHotelCalSep.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get uiHotelCalSep;

  /// No description provided for @uiHotelCalHoldUntil.
  ///
  /// In en, this message translates to:
  /// **'Held until {time}'**
  String uiHotelCalHoldUntil(String time);

  /// No description provided for @uiHotelCalOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiHotelCalOpen;

  /// No description provided for @uiHotelCalBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get uiHotelCalBlock;

  /// No description provided for @uiHotelCalBlockDate.
  ///
  /// In en, this message translates to:
  /// **'Block this date'**
  String get uiHotelCalBlockDate;

  /// No description provided for @uiHotelCalBy.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String uiHotelCalBy(String name);

  /// No description provided for @uiHotelCalAgenda.
  ///
  /// In en, this message translates to:
  /// **'Agenda for {date}'**
  String uiHotelCalAgenda(String date);

  /// No description provided for @uiHotelCalRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} pending request for this date} other{{count} pending requests for this date}}'**
  String uiHotelCalRequests(int count);

  /// No description provided for @uiHotelCalReasonOfflineBooking.
  ///
  /// In en, this message translates to:
  /// **'Booked offline'**
  String get uiHotelCalReasonOfflineBooking;

  /// No description provided for @uiHotelCalReasonMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get uiHotelCalReasonMaintenance;

  /// No description provided for @uiHotelCalReasonPrivateEvent.
  ///
  /// In en, this message translates to:
  /// **'Private event'**
  String get uiHotelCalReasonPrivateEvent;

  /// No description provided for @uiHotelCalReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get uiHotelCalReasonOther;

  /// No description provided for @uiHotelCalSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get uiHotelCalSetup;

  /// No description provided for @uiHotelCalTeardown.
  ///
  /// In en, this message translates to:
  /// **'Teardown'**
  String get uiHotelCalTeardown;

  /// No description provided for @uiHotelCalOpenDay.
  ///
  /// In en, this message translates to:
  /// **'Open: nothing booked or held on this date'**
  String get uiHotelCalOpenDay;

  /// No description provided for @uiHotelCalDragHint.
  ///
  /// In en, this message translates to:
  /// **'Press and hold a date, then drag across. Or tap a start date and an end date.'**
  String get uiHotelCalDragHint;

  /// No description provided for @uiHotelCalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Block dates'**
  String get uiHotelCalSheetTitle;

  /// No description provided for @uiHotelCalSheetShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get uiHotelCalSheetShortcuts;

  /// No description provided for @uiHotelCalSheetReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get uiHotelCalSheetReason;

  /// No description provided for @uiHotelCalSheetHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get uiHotelCalSheetHalls;

  /// No description provided for @uiHotelCalSheetOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiHotelCalSheetOpen;

  /// No description provided for @uiHotelCalSheetOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get uiHotelCalSheetOffer;

  /// No description provided for @uiHotelCalSheetNone.
  ///
  /// In en, this message translates to:
  /// **'Choose the dates'**
  String get uiHotelCalSheetNone;

  /// No description provided for @uiHotelCalSheetGrid.
  ///
  /// In en, this message translates to:
  /// **'Choose dates to block'**
  String get uiHotelCalSheetGrid;

  /// No description provided for @uiHotelCalSheetNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden from couples as soon as you block.'**
  String get uiHotelCalSheetNote;

  /// No description provided for @uiHotelCalSheetDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} date} other{{count} dates}}'**
  String uiHotelCalSheetDates(int count);

  /// No description provided for @uiHotelActionsReschedule.
  ///
  /// In en, this message translates to:
  /// **'Propose another date'**
  String get uiHotelActionsReschedule;

  /// No description provided for @uiHotelActionsRescheduleWhy.
  ///
  /// In en, this message translates to:
  /// **'Offer up to three dates at the same voucher price. The client has 48 hours to answer.'**
  String get uiHotelActionsRescheduleWhy;

  /// No description provided for @uiHotelActionsRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke approval'**
  String get uiHotelActionsRevoke;

  /// No description provided for @uiHotelActionsRevokeWhy.
  ///
  /// In en, this message translates to:
  /// **'The date is released and the voucher goes back to the client.'**
  String get uiHotelActionsRevokeWhy;

  /// No description provided for @uiHotelActionsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get uiHotelActionsCancel;

  /// No description provided for @uiHotelActionsCancelWhy.
  ///
  /// In en, this message translates to:
  /// **'The voucher goes back to the client. The cancellation counts on your record.'**
  String get uiHotelActionsCancelWhy;

  /// No description provided for @uiHotelStatusRef.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get uiHotelStatusRef;

  /// No description provided for @uiHotelStatusVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get uiHotelStatusVoucher;

  /// No description provided for @uiHotelStatusClientPays.
  ///
  /// In en, this message translates to:
  /// **'The client pays you directly'**
  String get uiHotelStatusClientPays;

  /// No description provided for @uiHotelStatusStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get uiHotelStatusStandard;

  /// No description provided for @uiHotelStatusDirect.
  ///
  /// In en, this message translates to:
  /// **'Settled between you and the client, off the app.'**
  String get uiHotelStatusDirect;

  /// No description provided for @uiHotelStatusAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the client to confirm by {when} · {left}'**
  String uiHotelStatusAwaiting(String when, String left);

  /// No description provided for @uiHotelStatusRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem voucher'**
  String get uiHotelStatusRedeem;

  /// No description provided for @uiHotelStatusRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed {when} by {name}'**
  String uiHotelStatusRedeemed(String when, String name);

  /// No description provided for @uiHotelStatusRedeemedNoName.
  ///
  /// In en, this message translates to:
  /// **'Redeemed {when}'**
  String uiHotelStatusRedeemedNoName(String when);

  /// No description provided for @uiHotelGuestBookingFor.
  ///
  /// In en, this message translates to:
  /// **'Booking for'**
  String get uiHotelGuestBookingFor;

  /// No description provided for @uiHotelGuestContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get uiHotelGuestContact;

  /// No description provided for @uiHotelGuestPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get uiHotelGuestPhone;

  /// No description provided for @uiHotelGuestNotShared.
  ///
  /// In en, this message translates to:
  /// **'Not shared yet. Message in chat.'**
  String get uiHotelGuestNotShared;

  /// No description provided for @uiHotelGuestVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified phone'**
  String get uiHotelGuestVerified;

  /// No description provided for @uiHotelGuestFirst.
  ///
  /// In en, this message translates to:
  /// **'First booking'**
  String get uiHotelGuestFirst;

  /// No description provided for @uiHotelGuestCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get uiHotelGuestCall;

  /// No description provided for @uiHotelGuestChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get uiHotelGuestChat;

  /// No description provided for @uiHotelGuestVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get uiHotelGuestVoucher;

  /// No description provided for @uiHotelGuestCallWhy.
  ///
  /// In en, this message translates to:
  /// **'The client has not shared the number'**
  String get uiHotelGuestCallWhy;

  /// No description provided for @uiHotelGuestBride.
  ///
  /// In en, this message translates to:
  /// **'The bride'**
  String get uiHotelGuestBride;

  /// No description provided for @uiHotelGuestGroom.
  ///
  /// In en, this message translates to:
  /// **'The groom'**
  String get uiHotelGuestGroom;

  /// No description provided for @uiHotelGuestFamily.
  ///
  /// In en, this message translates to:
  /// **'A family member'**
  String get uiHotelGuestFamily;

  /// No description provided for @uiHotelGuestPlanner.
  ///
  /// In en, this message translates to:
  /// **'A wedding planner'**
  String get uiHotelGuestPlanner;

  /// No description provided for @uiHotelValidityEventDates.
  ///
  /// In en, this message translates to:
  /// **'Event dates'**
  String get uiHotelValidityEventDates;

  /// No description provided for @uiHotelValidityHelper.
  ///
  /// In en, this message translates to:
  /// **'The lower voucher price applies to events on these dates.'**
  String get uiHotelValidityHelper;

  /// No description provided for @uiHotelValidityWindow.
  ///
  /// In en, this message translates to:
  /// **'This price runs for'**
  String get uiHotelValidityWindow;

  /// No description provided for @uiHotelValidityHours.
  ///
  /// In en, this message translates to:
  /// **'{n} hours'**
  String uiHotelValidityHours(String n);

  /// No description provided for @uiHotelValidityEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {time}'**
  String uiHotelValidityEnds(String time);

  /// No description provided for @uiHotelValidityScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get uiHotelValidityScheduled;

  /// No description provided for @uiHotelValidityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get uiHotelValidityActive;

  /// No description provided for @uiHotelValidityEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get uiHotelValidityEnded;

  /// No description provided for @uiHotelValidityStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts {time}'**
  String uiHotelValidityStarts(String time);

  /// No description provided for @uiHotelWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'How couples see it'**
  String get uiHotelWindowLabel;

  /// No description provided for @uiHotelWindowSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving against the standard price'**
  String get uiHotelWindowSaving;

  /// No description provided for @uiHotelPackageGuests.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} guests'**
  String uiHotelPackageGuests(String from, String to);

  /// No description provided for @uiHotelPackagePrice.
  ///
  /// In en, this message translates to:
  /// **'Standard price per guest'**
  String get uiHotelPackagePrice;

  /// No description provided for @uiHotelPackagePriceFlat.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get uiHotelPackagePriceFlat;

  /// No description provided for @uiHotelPackageVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price per guest'**
  String get uiHotelPackageVoucherPrice;

  /// No description provided for @uiHotelPackageVoucherPriceFlat.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get uiHotelPackageVoucherPriceFlat;

  /// No description provided for @uiHotelPackagePriceHelper.
  ///
  /// In en, this message translates to:
  /// **'In KD, up to three decimals. What a client pays you without a voucher.'**
  String get uiHotelPackagePriceHelper;

  /// No description provided for @uiHotelPackageVoucherHelper.
  ///
  /// In en, this message translates to:
  /// **'Lower than the standard price. What a client pays you with a Ghazal voucher.'**
  String get uiHotelPackageVoucherHelper;

  /// No description provided for @uiHotelPackagePriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount such as 52 or 52.500.'**
  String get uiHotelPackagePriceError;

  /// No description provided for @uiHotelPackageVoucherError.
  ///
  /// In en, this message translates to:
  /// **'The voucher price must be lower than the standard price.'**
  String get uiHotelPackageVoucherError;

  /// No description provided for @uiHotelPackageVoucherSmall.
  ///
  /// In en, this message translates to:
  /// **'Clients save {amount}, which is not more than the voucher fee, so no voucher is offered.'**
  String uiHotelPackageVoucherSmall(String amount);

  /// No description provided for @uiHotelPackageSaving.
  ///
  /// In en, this message translates to:
  /// **'Clients save {amount}{unit} with the voucher'**
  String uiHotelPackageSaving(String amount, String unit);

  /// No description provided for @uiHotelPackageStructure.
  ///
  /// In en, this message translates to:
  /// **'Pricing: {structure}'**
  String uiHotelPackageStructure(String structure);

  /// No description provided for @uiHotelPackagePerPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get uiHotelPackagePerPerson;

  /// No description provided for @uiHotelPackagePackage.
  ///
  /// In en, this message translates to:
  /// **'package'**
  String get uiHotelPackagePackage;

  /// No description provided for @uiHotelPackageMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum guests'**
  String get uiHotelPackageMin;

  /// No description provided for @uiHotelPackageMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum guests'**
  String get uiHotelPackageMax;

  /// No description provided for @uiHotelPackageRule.
  ///
  /// In en, this message translates to:
  /// **'Moves by {step}'**
  String uiHotelPackageRule(String step);

  /// No description provided for @uiHotelPackageInclusions.
  ///
  /// In en, this message translates to:
  /// **'Inclusions'**
  String get uiHotelPackageInclusions;

  /// No description provided for @uiHotelPackageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String uiHotelPackageRemove(String name);

  /// No description provided for @uiHotelPackageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add inclusion'**
  String get uiHotelPackageAdd;

  /// No description provided for @uiHotelPackageActiveOf.
  ///
  /// In en, this message translates to:
  /// **'{name} is active'**
  String uiHotelPackageActiveOf(String name);

  /// No description provided for @uiHotelPackageDashboard.
  ///
  /// In en, this message translates to:
  /// **'Seasonal, holiday and special-date prices are edited on the dashboard.'**
  String get uiHotelPackageDashboard;

  /// No description provided for @uiHotelPackageEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String uiHotelPackageEdit(String name);

  /// No description provided for @uiHotelPackageKd.
  ///
  /// In en, this message translates to:
  /// **'KD'**
  String get uiHotelPackageKd;

  /// No description provided for @uiHotelPhotosCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get uiHotelPhotosCover;

  /// No description provided for @uiHotelPhotosAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get uiHotelPhotosAdd;

  /// No description provided for @uiHotelPhotosReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get uiHotelPhotosReview;

  /// No description provided for @uiHotelPhotosRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get uiHotelPhotosRejected;

  /// No description provided for @uiHotelPhotosEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move {n} earlier'**
  String uiHotelPhotosEarlier(String n);

  /// No description provided for @uiHotelPhotosLater.
  ///
  /// In en, this message translates to:
  /// **'Move {n} later'**
  String uiHotelPhotosLater(String n);

  /// No description provided for @uiHotelPhotosDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get uiHotelPhotosDrag;

  /// No description provided for @uiHotelPhotosOpen.
  ///
  /// In en, this message translates to:
  /// **'Photo {n}: {zone}'**
  String uiHotelPhotosOpen(String n, String zone);

  /// No description provided for @uiHotelPhotosHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get uiHotelPhotosHall;

  /// No description provided for @uiHotelPhotosStageKosha.
  ///
  /// In en, this message translates to:
  /// **'Stage and Kosha'**
  String get uiHotelPhotosStageKosha;

  /// No description provided for @uiHotelPhotosBridalSuite.
  ///
  /// In en, this message translates to:
  /// **'Bridal suite'**
  String get uiHotelPhotosBridalSuite;

  /// No description provided for @uiHotelPhotosBuffet.
  ///
  /// In en, this message translates to:
  /// **'Buffet'**
  String get uiHotelPhotosBuffet;

  /// No description provided for @uiHotelPhotosOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get uiHotelPhotosOutdoors;

  /// No description provided for @uiHotelPhotosEntranceValet.
  ///
  /// In en, this message translates to:
  /// **'Entrance and valet'**
  String get uiHotelPhotosEntranceValet;

  /// No description provided for @uiHotelPhotosLayout.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get uiHotelPhotosLayout;

  /// No description provided for @uiHotelHoursClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get uiHotelHoursClosed;

  /// No description provided for @uiHotelHoursOpen.
  ///
  /// In en, this message translates to:
  /// **'Open on {day}'**
  String uiHotelHoursOpen(String day);

  /// No description provided for @uiHotelHoursFrom.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get uiHotelHoursFrom;

  /// No description provided for @uiHotelHoursTo.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get uiHotelHoursTo;

  /// No description provided for @uiHotelHoursNextDay.
  ///
  /// In en, this message translates to:
  /// **'next day'**
  String get uiHotelHoursNextDay;

  /// No description provided for @uiHotelHoursCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to all days'**
  String get uiHotelHoursCopy;

  /// No description provided for @uiHotelHoursInvalid.
  ///
  /// In en, this message translates to:
  /// **'The closing time is before the opening time.'**
  String get uiHotelHoursInvalid;

  /// No description provided for @uiHotelHoursPick.
  ///
  /// In en, this message translates to:
  /// **'{what} at {time}'**
  String uiHotelHoursPick(String what, String time);

  /// No description provided for @uiHotelReviewAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get uiHotelReviewAnonymous;

  /// No description provided for @uiHotelReviewVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified booking'**
  String get uiHotelReviewVerified;

  /// No description provided for @uiHotelReviewNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs reply'**
  String get uiHotelReviewNeeds;

  /// No description provided for @uiHotelReviewReported.
  ///
  /// In en, this message translates to:
  /// **'Reported · under review by Ghazal'**
  String get uiHotelReviewReported;

  /// No description provided for @uiHotelReviewEvent.
  ///
  /// In en, this message translates to:
  /// **'Event in {month}'**
  String uiHotelReviewEvent(String month);

  /// No description provided for @uiHotelReviewReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get uiHotelReviewReply;

  /// No description provided for @uiHotelReviewReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get uiHotelReviewReport;

  /// No description provided for @uiHotelReviewDraft.
  ///
  /// In en, this message translates to:
  /// **'Your draft'**
  String get uiHotelReviewDraft;

  /// No description provided for @uiHotelReviewYours.
  ///
  /// In en, this message translates to:
  /// **'Reply from {name}'**
  String uiHotelReviewYours(String name);

  /// No description provided for @uiHotelReviewOnce.
  ///
  /// In en, this message translates to:
  /// **'A reply is public and can be sent once.'**
  String get uiHotelReviewOnce;

  /// No description provided for @uiHotelStaffYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get uiHotelStaffYou;

  /// No description provided for @uiHotelStaffActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get uiHotelStaffActive;

  /// No description provided for @uiHotelStaffLastSeen.
  ///
  /// In en, this message translates to:
  /// **'last seen {time}'**
  String uiHotelStaffLastSeen(String time);

  /// No description provided for @uiHotelStaffPending.
  ///
  /// In en, this message translates to:
  /// **'Invite pending'**
  String get uiHotelStaffPending;

  /// No description provided for @uiHotelStaffExpires.
  ///
  /// In en, this message translates to:
  /// **'expires {date}'**
  String uiHotelStaffExpires(String date);

  /// No description provided for @uiHotelStaffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get uiHotelStaffDeactivated;

  /// No description provided for @uiHotelStaffAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get uiHotelStaffAllowed;

  /// No description provided for @uiHotelStaffNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not for this role'**
  String get uiHotelStaffNotAllowed;

  /// No description provided for @uiHotelStaffOpen.
  ///
  /// In en, this message translates to:
  /// **'Permissions of {name}'**
  String uiHotelStaffOpen(String name);

  /// No description provided for @uiHotelStaffAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept, decline and propose dates'**
  String get uiHotelStaffAccept;

  /// No description provided for @uiHotelStaffBlock.
  ///
  /// In en, this message translates to:
  /// **'Block and open dates'**
  String get uiHotelStaffBlock;

  /// No description provided for @uiHotelStaffCancel.
  ///
  /// In en, this message translates to:
  /// **'Reschedule or cancel a confirmed booking'**
  String get uiHotelStaffCancel;

  /// No description provided for @uiHotelStaffCash.
  ///
  /// In en, this message translates to:
  /// **'Record cash received'**
  String get uiHotelStaffCash;

  /// No description provided for @uiHotelStaffRevenue.
  ///
  /// In en, this message translates to:
  /// **'See revenue and payments'**
  String get uiHotelStaffRevenue;

  /// No description provided for @uiHotelStaffOffers.
  ///
  /// In en, this message translates to:
  /// **'Create and end offers'**
  String get uiHotelStaffOffers;

  /// No description provided for @uiHotelStaffManage.
  ///
  /// In en, this message translates to:
  /// **'Staff and bank information'**
  String get uiHotelStaffManage;

  /// No description provided for @uiHotelStaffSwitchable.
  ///
  /// In en, this message translates to:
  /// **'Can be switched off by the owner'**
  String get uiHotelStaffSwitchable;

  /// No description provided for @uiHotelPhotosMakeCover.
  ///
  /// In en, this message translates to:
  /// **'Make cover'**
  String get uiHotelPhotosMakeCover;

  /// No description provided for @uiHotelPhotosDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get uiHotelPhotosDelete;

  /// No description provided for @uiHotelPhotosOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get uiHotelPhotosOpenAction;

  /// No description provided for @uiHotelPhotosDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get uiHotelPhotosDeleted;

  /// No description provided for @uiInputsOtpGroup.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get uiInputsOtpGroup;

  /// No description provided for @uiInputsOtpCell.
  ///
  /// In en, this message translates to:
  /// **'Digit {n} of {total}'**
  String uiInputsOtpCell(String n, String total);

  /// No description provided for @uiInputsPhoneCountry.
  ///
  /// In en, this message translates to:
  /// **'Country code'**
  String get uiInputsPhoneCountry;

  /// No description provided for @uiInputsPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get uiInputsPhoneNumber;

  /// No description provided for @uiInputsStepperIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get uiInputsStepperIncrease;

  /// No description provided for @uiInputsStepperDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get uiInputsStepperDecrease;

  /// No description provided for @uiInputsRangeMinimum.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get uiInputsRangeMinimum;

  /// No description provided for @uiInputsRangeMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get uiInputsRangeMaximum;

  /// No description provided for @uiInputsSelectChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get uiInputsSelectChoose;

  /// No description provided for @uiInputsSelectCount.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String uiInputsSelectCount(String n);

  /// No description provided for @uiInputsSelectNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get uiInputsSelectNoResults;

  /// No description provided for @uiInputsCalendarStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get uiInputsCalendarStartDate;

  /// No description provided for @uiInputsCalendarEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get uiInputsCalendarEndDate;

  /// No description provided for @uiInputsCalendarHint.
  ///
  /// In en, this message translates to:
  /// **'Use the arrow keys to move between days.'**
  String get uiInputsCalendarHint;

  /// No description provided for @uiInputsCalendarPriceBasis.
  ///
  /// In en, this message translates to:
  /// **'{currency} · {unit}'**
  String uiInputsCalendarPriceBasis(String currency, String unit);

  /// No description provided for @uiInputsDateFieldRange.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String uiInputsDateFieldRange(String from, String to);

  /// No description provided for @uiInputsDateFieldChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get uiInputsDateFieldChooseDate;

  /// No description provided for @uiInputsDateFieldChooseDates.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get uiInputsDateFieldChooseDates;

  /// No description provided for @uiInputsSlotSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get uiInputsSlotSession;

  /// No description provided for @uiKitErrorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Some details need another look. Check the highlighted fields.'**
  String get uiKitErrorValidationFailed;

  /// No description provided for @uiKitErrorAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get uiKitErrorAuthRequired;

  /// No description provided for @uiKitErrorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Please sign in again.'**
  String get uiKitErrorTokenExpired;

  /// No description provided for @uiKitErrorSessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'You were signed out on this device. Please sign in again.'**
  String get uiKitErrorSessionRevoked;

  /// No description provided for @uiKitErrorPhoneVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verify your mobile number first, then try again.'**
  String get uiKitErrorPhoneVerificationRequired;

  /// No description provided for @uiKitErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your role cannot do this. Ask your manager.'**
  String get uiKitErrorForbidden;

  /// No description provided for @uiKitErrorStepUpRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm with a fresh code or your password to continue.'**
  String get uiKitErrorStepUpRequired;

  /// No description provided for @uiKitErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available.'**
  String get uiKitErrorNotFound;

  /// No description provided for @uiKitErrorVenueContextRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose the venue or service account you are working in.'**
  String get uiKitErrorVenueContextRequired;

  /// No description provided for @uiKitErrorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. Check it and try again.'**
  String get uiKitErrorOtpInvalid;

  /// No description provided for @uiKitErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new one.'**
  String get uiKitErrorOtpExpired;

  /// No description provided for @uiKitErrorOtpLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong codes. Try again later.'**
  String get uiKitErrorOtpLocked;

  /// No description provided for @uiKitErrorCredentialsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The details do not match an account. Check them and try again.'**
  String get uiKitErrorCredentialsInvalid;

  /// No description provided for @uiKitErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get uiKitErrorRateLimited;

  /// No description provided for @uiKitErrorIdempotencyInProgress.
  ///
  /// In en, this message translates to:
  /// **'This is already being processed. Give it a moment.'**
  String get uiKitErrorIdempotencyInProgress;

  /// No description provided for @uiKitErrorPreconditionFailed.
  ///
  /// In en, this message translates to:
  /// **'This was changed elsewhere. Reload and try again.'**
  String get uiKitErrorPreconditionFailed;

  /// No description provided for @uiKitErrorBookingStateConflict.
  ///
  /// In en, this message translates to:
  /// **'This request was updated meanwhile. Reload to see where it stands.'**
  String get uiKitErrorBookingStateConflict;

  /// No description provided for @uiKitErrorSlotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'That date is no longer available. Pick another date.'**
  String get uiKitErrorSlotUnavailable;

  /// No description provided for @uiKitErrorOpenRequestLimit.
  ///
  /// In en, this message translates to:
  /// **'You have reached the limit of open requests. Wait for a reply or withdraw one.'**
  String get uiKitErrorOpenRequestLimit;

  /// No description provided for @uiKitErrorQuoteExpired.
  ///
  /// In en, this message translates to:
  /// **'This quote has expired. Review it again.'**
  String get uiKitErrorQuoteExpired;

  /// No description provided for @uiKitErrorQuoteChanged.
  ///
  /// In en, this message translates to:
  /// **'The price changed since you saw it. Review the new quote.'**
  String get uiKitErrorQuoteChanged;

  /// No description provided for @uiKitErrorLeadTimeTooShort.
  ///
  /// In en, this message translates to:
  /// **'This date is too close. Pick a later date.'**
  String get uiKitErrorLeadTimeTooShort;

  /// No description provided for @uiKitErrorGuestsOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'The number of guests is outside what this option allows.'**
  String get uiKitErrorGuestsOutOfRange;

  /// No description provided for @uiKitErrorAudienceNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This hall does not offer this option for your group.'**
  String get uiKitErrorAudienceNotAllowed;

  /// No description provided for @uiKitErrorChannelNotBookable.
  ///
  /// In en, this message translates to:
  /// **'This venue takes requests through its official channel only.'**
  String get uiKitErrorChannelNotBookable;

  /// No description provided for @uiKitErrorVoucherNotOffered.
  ///
  /// In en, this message translates to:
  /// **'A voucher does not lower the price for this choice.'**
  String get uiKitErrorVoucherNotOffered;

  /// No description provided for @uiKitErrorVoucherNotUsable.
  ///
  /// In en, this message translates to:
  /// **'This voucher cannot be used. It may be expired, forfeited or already tied to a request.'**
  String get uiKitErrorVoucherNotUsable;

  /// No description provided for @uiKitErrorVoucherTargetMismatch.
  ///
  /// In en, this message translates to:
  /// **'This voucher is tied to another venue or service.'**
  String get uiKitErrorVoucherTargetMismatch;

  /// No description provided for @uiKitErrorVoucherCheckoutExpired.
  ///
  /// In en, this message translates to:
  /// **'The checkout timed out and nothing was charged. Start again.'**
  String get uiKitErrorVoucherCheckoutExpired;

  /// No description provided for @uiKitErrorVoucherUnknown.
  ///
  /// In en, this message translates to:
  /// **'No voucher matches this code. Check it and try again.'**
  String get uiKitErrorVoucherUnknown;

  /// No description provided for @uiKitErrorVoucherOtherPartner.
  ///
  /// In en, this message translates to:
  /// **'This voucher belongs to another venue or service.'**
  String get uiKitErrorVoucherOtherPartner;

  /// No description provided for @uiKitErrorVoucherNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The client has not confirmed this request yet.'**
  String get uiKitErrorVoucherNotConfirmed;

  /// No description provided for @uiKitErrorVoucherAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This voucher has already been used.'**
  String get uiKitErrorVoucherAlreadyUsed;

  /// No description provided for @uiKitErrorCreditNotEligible.
  ///
  /// In en, this message translates to:
  /// **'This voucher cannot be considered for a credit voucher.'**
  String get uiKitErrorCreditNotEligible;

  /// No description provided for @uiKitErrorRefundRequestExists.
  ///
  /// In en, this message translates to:
  /// **'A request for this voucher is already with support.'**
  String get uiKitErrorRefundRequestExists;

  /// No description provided for @uiKitErrorConfirmWindowEnded.
  ///
  /// In en, this message translates to:
  /// **'The time to confirm has passed.'**
  String get uiKitErrorConfirmWindowEnded;

  /// No description provided for @uiKitErrorUndoWindowEnded.
  ///
  /// In en, this message translates to:
  /// **'The time to undo has passed.'**
  String get uiKitErrorUndoWindowEnded;

  /// No description provided for @uiKitErrorPaymentGatewayError.
  ///
  /// In en, this message translates to:
  /// **'The payment service is unavailable. Nothing was charged. Try again shortly.'**
  String get uiKitErrorPaymentGatewayError;

  /// No description provided for @uiKitErrorPlanRatesNotAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Plan rates will be announced soon.'**
  String get uiKitErrorPlanRatesNotAnnounced;

  /// No description provided for @uiKitErrorListingNotEditable.
  ///
  /// In en, this message translates to:
  /// **'This listing cannot be edited in its current status.'**
  String get uiKitErrorListingNotEditable;

  /// No description provided for @uiKitErrorListingStateConflict.
  ///
  /// In en, this message translates to:
  /// **'This listing is not in a status that allows this action.'**
  String get uiKitErrorListingStateConflict;

  /// No description provided for @uiKitErrorMediaTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This file is too large. Choose a smaller one.'**
  String get uiKitErrorMediaTooLarge;

  /// No description provided for @uiKitErrorMediaTypeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This file type is not accepted.'**
  String get uiKitErrorMediaTypeUnsupported;

  /// No description provided for @uiKitErrorReviewAlreadyReplied.
  ///
  /// In en, this message translates to:
  /// **'This review already has a reply.'**
  String get uiKitErrorReviewAlreadyReplied;

  /// No description provided for @uiKitErrorReviewNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'A review is possible once the event is completed, and only once.'**
  String get uiKitErrorReviewNotAllowed;

  /// No description provided for @uiKitErrorVisitSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'That arrival window is taken. Pick another one.'**
  String get uiKitErrorVisitSlotTaken;

  /// No description provided for @uiKitErrorVisitNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This venue does not take site visits through the app.'**
  String get uiKitErrorVisitNotAllowed;

  /// No description provided for @uiKitErrorVisitStateConflict.
  ///
  /// In en, this message translates to:
  /// **'This visit was updated meanwhile. Reload to see where it stands.'**
  String get uiKitErrorVisitStateConflict;

  /// No description provided for @uiKitErrorStaffLastAdmin.
  ///
  /// In en, this message translates to:
  /// **'The last admin cannot be removed or changed.'**
  String get uiKitErrorStaffLastAdmin;

  /// No description provided for @uiKitErrorInvitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired or was already used. Ask for a new one.'**
  String get uiKitErrorInvitationExpired;

  /// No description provided for @uiKitErrorEmailAlreadyInvited.
  ///
  /// In en, this message translates to:
  /// **'This email already has a pending invitation.'**
  String get uiKitErrorEmailAlreadyInvited;

  /// No description provided for @uiKitErrorAccountDeletionBlocked.
  ///
  /// In en, this message translates to:
  /// **'The account cannot be deleted while a confirmed request is coming up.'**
  String get uiKitErrorAccountDeletionBlocked;

  /// No description provided for @uiKitErrorAppUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please update the app to continue.'**
  String get uiKitErrorAppUpdateRequired;

  /// No description provided for @uiKitErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection and try again.'**
  String get uiKitErrorOffline;

  /// No description provided for @uiKitErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Please try again.'**
  String get uiKitErrorTimeout;

  /// No description provided for @uiKitDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo tools'**
  String get uiKitDemoTitle;

  /// No description provided for @uiKitDemoHotspot.
  ///
  /// In en, this message translates to:
  /// **'Demo tools'**
  String get uiKitDemoHotspot;

  /// No description provided for @uiKitDemoModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get uiKitDemoModeTitle;

  /// No description provided for @uiKitDemoModeInProcess.
  ///
  /// In en, this message translates to:
  /// **'In-process mock'**
  String get uiKitDemoModeInProcess;

  /// No description provided for @uiKitDemoModeRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote API at {url}'**
  String uiKitDemoModeRemote(String url);

  /// No description provided for @uiKitDemoStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get uiKitDemoStoryTitle;

  /// No description provided for @uiKitDemoReset.
  ///
  /// In en, this message translates to:
  /// **'Reset the story'**
  String get uiKitDemoReset;

  /// No description provided for @uiKitDemoResetDone.
  ///
  /// In en, this message translates to:
  /// **'The story is back at the start.'**
  String get uiKitDemoResetDone;

  /// No description provided for @uiKitDemoPersonaTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is using the app'**
  String get uiKitDemoPersonaTitle;

  /// No description provided for @uiKitDemoPersonaGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get uiKitDemoPersonaGuest;

  /// No description provided for @uiKitDemoPersonaNewClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get uiKitDemoPersonaNewClient;

  /// No description provided for @uiKitDemoPersonaReem.
  ///
  /// In en, this message translates to:
  /// **'Reem'**
  String get uiKitDemoPersonaReem;

  /// No description provided for @uiKitDemoPersonaHotelManager.
  ///
  /// In en, this message translates to:
  /// **'Hotel manager'**
  String get uiKitDemoPersonaHotelManager;

  /// No description provided for @uiKitDemoPersonaHotelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Hotel admin'**
  String get uiKitDemoPersonaHotelAdmin;

  /// No description provided for @uiKitDemoPersonaProvider.
  ///
  /// In en, this message translates to:
  /// **'Service provider'**
  String get uiKitDemoPersonaProvider;

  /// No description provided for @uiKitDemoScenarioTitle.
  ///
  /// In en, this message translates to:
  /// **'Next requests'**
  String get uiKitDemoScenarioTitle;

  /// No description provided for @uiKitDemoScenarioNone.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get uiKitDemoScenarioNone;

  /// No description provided for @uiKitDemoScenarioSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get uiKitDemoScenarioSlow;

  /// No description provided for @uiKitDemoScenarioError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get uiKitDemoScenarioError;

  /// No description provided for @uiKitDemoScenarioOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get uiKitDemoScenarioOffline;

  /// No description provided for @uiKitDemoScenarioEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get uiKitDemoScenarioEmpty;

  /// No description provided for @uiKitDemoScenarioExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expires'**
  String get uiKitDemoScenarioExpired;

  /// No description provided for @uiKitDemoClockTitle.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get uiKitDemoClockTitle;

  /// No description provided for @uiKitDemoClockNow.
  ///
  /// In en, this message translates to:
  /// **'Story time: {time}'**
  String uiKitDemoClockNow(String time);

  /// No description provided for @uiKitDemoAdvanceHour.
  ///
  /// In en, this message translates to:
  /// **'Advance one hour'**
  String get uiKitDemoAdvanceHour;

  /// No description provided for @uiKitDemoAdvanceDay.
  ///
  /// In en, this message translates to:
  /// **'Advance one day'**
  String get uiKitDemoAdvanceDay;

  /// No description provided for @uiKitDemoJumpTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump to a story point'**
  String get uiKitDemoJumpTitle;

  /// No description provided for @uiKitDemoPointPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting reply'**
  String get uiKitDemoPointPending;

  /// No description provided for @uiKitDemoPointApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get uiKitDemoPointApproved;

  /// No description provided for @uiKitDemoPointConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get uiKitDemoPointConfirmed;

  /// No description provided for @uiKitDemoPointRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get uiKitDemoPointRedeemed;

  /// No description provided for @uiKitDemoPointCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get uiKitDemoPointCompleted;

  /// No description provided for @uiKitDemoPointDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get uiKitDemoPointDeclined;

  /// No description provided for @uiKitDemoPointExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get uiKitDemoPointExpired;

  /// No description provided for @uiKitDemoPointLapsed.
  ///
  /// In en, this message translates to:
  /// **'Forfeited'**
  String get uiKitDemoPointLapsed;

  /// No description provided for @uiKitDemoPointCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get uiKitDemoPointCancelled;

  /// No description provided for @uiKitDemoPointCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter-offer'**
  String get uiKitDemoPointCounterOffer;

  /// No description provided for @uiKitDemoLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language and digits'**
  String get uiKitDemoLanguageTitle;

  /// No description provided for @uiKitDemoDigitsEastern.
  ///
  /// In en, this message translates to:
  /// **'Eastern Arabic digits'**
  String get uiKitDemoDigitsEastern;

  /// No description provided for @uiKitDemoDigitsWestern.
  ///
  /// In en, this message translates to:
  /// **'Western digits'**
  String get uiKitDemoDigitsWestern;

  /// No description provided for @uiProviderAdPlanExemptBody.
  ///
  /// In en, this message translates to:
  /// **'No fee for major hotels'**
  String get uiProviderAdPlanExemptBody;

  /// No description provided for @uiProviderAdPlanPerPeriod.
  ///
  /// In en, this message translates to:
  /// **'per {period}'**
  String uiProviderAdPlanPerPeriod(String period);

  /// No description provided for @uiProviderAdPlanWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get uiProviderAdPlanWeek;

  /// No description provided for @uiProviderAdPlanMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get uiProviderAdPlanMonth;

  /// No description provided for @uiProviderAdPlanYear.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get uiProviderAdPlanYear;

  /// No description provided for @uiProviderAdPlanStarts.
  ///
  /// In en, this message translates to:
  /// **'Runs from the day it is approved'**
  String get uiProviderAdPlanStarts;

  /// No description provided for @uiProviderAdPlanChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String uiProviderAdPlanChoose(String name);

  /// No description provided for @uiProviderMajorHotelExemptFee.
  ///
  /// In en, this message translates to:
  /// **'Fee exempt'**
  String get uiProviderMajorHotelExemptFee;

  /// No description provided for @uiProviderMajorHotelExplain.
  ///
  /// In en, this message translates to:
  /// **'Major hotels pay no listing or advertising fees. Every listing is still reviewed before it goes live.'**
  String get uiProviderMajorHotelExplain;

  /// No description provided for @uiProviderListingEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String uiProviderListingEndsOn(String date);

  /// No description provided for @uiProviderListingStartsAfter.
  ///
  /// In en, this message translates to:
  /// **'Starts when approved'**
  String get uiProviderListingStartsAfter;

  /// No description provided for @uiProviderListingNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No plan chosen yet'**
  String get uiProviderListingNoPlan;

  /// No description provided for @uiProviderListingReview.
  ///
  /// In en, this message translates to:
  /// **'With the review team'**
  String get uiProviderListingReview;

  /// No description provided for @uiProviderListingRejectContentNotCompliant.
  ///
  /// In en, this message translates to:
  /// **'Content does not meet our guidelines'**
  String get uiProviderListingRejectContentNotCompliant;

  /// No description provided for @uiProviderListingRejectWrongCategory.
  ///
  /// In en, this message translates to:
  /// **'Wrong category'**
  String get uiProviderListingRejectWrongCategory;

  /// No description provided for @uiProviderListingRejectMissingDetails.
  ///
  /// In en, this message translates to:
  /// **'Details are missing'**
  String get uiProviderListingRejectMissingDetails;

  /// No description provided for @uiProviderListingRejectUnclearPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing is unclear'**
  String get uiProviderListingRejectUnclearPricing;

  /// No description provided for @uiProviderListingRejectOther.
  ///
  /// In en, this message translates to:
  /// **'See the moderator note'**
  String get uiProviderListingRejectOther;

  /// No description provided for @uiProviderTimelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Review history'**
  String get uiProviderTimelineLabel;

  /// No description provided for @uiProviderTimelineDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get uiProviderTimelineDraft;

  /// No description provided for @uiProviderTimelinePaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get uiProviderTimelinePaymentPending;

  /// No description provided for @uiProviderTimelinePendingReview.
  ///
  /// In en, this message translates to:
  /// **'Sent for review'**
  String get uiProviderTimelinePendingReview;

  /// No description provided for @uiProviderTimelineApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get uiProviderTimelineApproved;

  /// No description provided for @uiProviderTimelineRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get uiProviderTimelineRejected;

  /// No description provided for @uiProviderTimelineActive.
  ///
  /// In en, this message translates to:
  /// **'Live on Ghazal'**
  String get uiProviderTimelineActive;

  /// No description provided for @uiProviderTimelineExpired.
  ///
  /// In en, this message translates to:
  /// **'Plan ended'**
  String get uiProviderTimelineExpired;

  /// No description provided for @uiProviderTimelinePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get uiProviderTimelinePaused;

  /// No description provided for @uiProviderTimelineYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get uiProviderTimelineYou;

  /// No description provided for @uiProviderTimelineSystem.
  ///
  /// In en, this message translates to:
  /// **'Ghazal'**
  String get uiProviderTimelineSystem;

  /// No description provided for @uiProviderTimelineModerator.
  ///
  /// In en, this message translates to:
  /// **'Ghazal review team'**
  String get uiProviderTimelineModerator;

  /// No description provided for @uiProviderTimelineModeratorBy.
  ///
  /// In en, this message translates to:
  /// **'Ghazal review team · {name}'**
  String uiProviderTimelineModeratorBy(String name);

  /// No description provided for @uiProviderTimelineNextReview.
  ///
  /// In en, this message translates to:
  /// **'A person at Ghazal reviews it'**
  String get uiProviderTimelineNextReview;

  /// No description provided for @uiProviderTimelineNextReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Every listing is checked for content and category before it goes live. Paying never publishes it by itself.'**
  String get uiProviderTimelineNextReviewNote;

  /// No description provided for @uiProviderTimelineNextLive.
  ///
  /// In en, this message translates to:
  /// **'Goes live'**
  String get uiProviderTimelineNextLive;

  /// No description provided for @uiProviderTimelineNextLiveNote.
  ///
  /// In en, this message translates to:
  /// **'Your plan starts the day it goes live.'**
  String get uiProviderTimelineNextLiveNote;

  /// No description provided for @uiProviderTimelineKeptUntil.
  ///
  /// In en, this message translates to:
  /// **'Your plan is kept until {date} so you can resubmit.'**
  String uiProviderTimelineKeptUntil(String date);

  /// No description provided for @uiProviderTimelineReasonContentNotCompliant.
  ///
  /// In en, this message translates to:
  /// **'Content does not meet our guidelines'**
  String get uiProviderTimelineReasonContentNotCompliant;

  /// No description provided for @uiProviderTimelineReasonWrongCategory.
  ///
  /// In en, this message translates to:
  /// **'Wrong category'**
  String get uiProviderTimelineReasonWrongCategory;

  /// No description provided for @uiProviderTimelineReasonMissingDetails.
  ///
  /// In en, this message translates to:
  /// **'Details are missing'**
  String get uiProviderTimelineReasonMissingDetails;

  /// No description provided for @uiProviderTimelineReasonUnclearPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing is unclear'**
  String get uiProviderTimelineReasonUnclearPricing;

  /// No description provided for @uiProviderTimelineReasonOther.
  ///
  /// In en, this message translates to:
  /// **'See the note'**
  String get uiProviderTimelineReasonOther;

  /// No description provided for @uiSharedGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get uiSharedGuests;

  /// No description provided for @uiSharedFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get uiSharedFrom;

  /// No description provided for @uiSharedPerNight.
  ///
  /// In en, this message translates to:
  /// **'Per night'**
  String get uiSharedPerNight;

  /// No description provided for @uiSharedRentalFee.
  ///
  /// In en, this message translates to:
  /// **'Rental fee'**
  String get uiSharedRentalFee;

  /// No description provided for @uiSharedLockedVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher price after you sign up'**
  String get uiSharedLockedVoucher;

  /// No description provided for @uiSharedVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get uiSharedVoucher;

  /// No description provided for @uiSharedLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute left'**
  String get uiSharedLessThanMinute;

  /// No description provided for @uiSharedSpokenDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} other{{count} days}}'**
  String uiSharedSpokenDays(int count);

  /// No description provided for @uiSharedSpokenHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hour} other{{count} hours}}'**
  String uiSharedSpokenHours(int count);

  /// No description provided for @uiSharedSpokenMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} minute} other{{count} minutes}}'**
  String uiSharedSpokenMinutes(int count);

  /// No description provided for @uiSharedSpokenJoin.
  ///
  /// In en, this message translates to:
  /// **'{first} {second}'**
  String uiSharedSpokenJoin(String first, String second);

  /// No description provided for @stubNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get stubNotBuilt;

  /// No description provided for @uiVisitsStripLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat members'**
  String get uiVisitsStripLabel;

  /// No description provided for @uiVisitsStripOpen.
  ///
  /// In en, this message translates to:
  /// **'Show chat members'**
  String get uiVisitsStripOpen;

  /// No description provided for @uiVisitsCardWith.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String uiVisitsCardWith(String name);

  /// No description provided for @uiVisitsCardChat.
  ///
  /// In en, this message translates to:
  /// **'Open group chat'**
  String get uiVisitsCardChat;

  /// No description provided for @uiVisitsCardReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Chat is read-only'**
  String get uiVisitsCardReadOnly;

  /// No description provided for @uiVoucherCardCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get uiVoucherCardCode;

  /// No description provided for @uiVoucherCardQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code of voucher {code}'**
  String uiVoucherCardQrLabel(String code);

  /// No description provided for @uiVoucherCardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get uiVoucherCardCopy;

  /// No description provided for @uiVoucherCardFull.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get uiVoucherCardFull;

  /// No description provided for @uiVoucherCardDate.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get uiVoucherCardDate;

  /// No description provided for @uiVoucherCardPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get uiVoucherCardPackage;

  /// No description provided for @uiVoucherCardValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get uiVoucherCardValidUntil;

  /// No description provided for @uiVoucherCardUsedOn.
  ///
  /// In en, this message translates to:
  /// **'Redeemed on'**
  String get uiVoucherCardUsedOn;

  /// No description provided for @uiVoucherPriceSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get uiVoucherPriceSignUp;

  /// No description provided for @uiVoucherPriceNetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your saving'**
  String get uiVoucherPriceNetTitle;

  /// No description provided for @uiVoucherPriceNet.
  ///
  /// In en, this message translates to:
  /// **'You save {amount} after the {fee} voucher.'**
  String uiVoucherPriceNet(String amount, String fee);

  /// No description provided for @uiVoucherPricePackage.
  ///
  /// In en, this message translates to:
  /// **'Package price'**
  String get uiVoucherPricePackage;

  /// No description provided for @uiVoucherSummaryHead.
  ///
  /// In en, this message translates to:
  /// **'Your voucher'**
  String get uiVoucherSummaryHead;

  /// No description provided for @uiVoucherSummaryBoundTo.
  ///
  /// In en, this message translates to:
  /// **'Bound to'**
  String get uiVoucherSummaryBoundTo;

  /// No description provided for @uiVoucherSummaryDate.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get uiVoucherSummaryDate;

  /// No description provided for @uiVoucherSummaryPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get uiVoucherSummaryPackage;

  /// No description provided for @uiVoucherSummaryGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get uiVoucherSummaryGuests;

  /// No description provided for @uiVoucherSummarySave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get uiVoucherSummarySave;

  /// No description provided for @uiVoucherSummaryPayToday.
  ///
  /// In en, this message translates to:
  /// **'You pay Ghazal today'**
  String get uiVoucherSummaryPayToday;

  /// No description provided for @uiVoucherSummaryPayOnce.
  ///
  /// In en, this message translates to:
  /// **'For the voucher, once'**
  String get uiVoucherSummaryPayOnce;

  /// No description provided for @uiVoucherSummaryDirectly.
  ///
  /// In en, this message translates to:
  /// **'The rest, {amount}, you pay to {venue} directly after you confirm. Ghazal takes no part in that payment.'**
  String uiVoucherSummaryDirectly(String amount, String venue);

  /// No description provided for @uiVoucherSummaryRuleBound.
  ///
  /// In en, this message translates to:
  /// **'The voucher belongs to this venue and this quote.'**
  String get uiVoucherSummaryRuleBound;

  /// No description provided for @uiVoucherSummaryRuleReuse.
  ///
  /// In en, this message translates to:
  /// **'If the venue declines, you can use it again here for {days}.'**
  String uiVoucherSummaryRuleReuse(String days);

  /// No description provided for @uiVoucherSummaryRuleCredit.
  ///
  /// In en, this message translates to:
  /// **'If the venue declines or does not reply, ask support for a credit voucher.'**
  String get uiVoucherSummaryRuleCredit;

  /// No description provided for @uiVoucherConfirmEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Confirm your booking'**
  String get uiVoucherConfirmEyebrow;

  /// No description provided for @uiVoucherConfirmBy.
  ///
  /// In en, this message translates to:
  /// **'Confirm by {when}'**
  String uiVoucherConfirmBy(String when);

  /// No description provided for @uiVoucherConfirmHeld.
  ///
  /// In en, this message translates to:
  /// **'The date is held for you until then. You pay nothing more to Ghazal.'**
  String get uiVoucherConfirmHeld;

  /// No description provided for @uiVoucherConfirmLapsedTitle.
  ///
  /// In en, this message translates to:
  /// **'The confirm window ended'**
  String get uiVoucherConfirmLapsedTitle;

  /// No description provided for @uiVoucherConfirmLapsedBody.
  ///
  /// In en, this message translates to:
  /// **'The date was released and the voucher is no longer valid.'**
  String get uiVoucherConfirmLapsedBody;

  /// No description provided for @uiVoucherConfirmDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You confirmed this booking'**
  String get uiVoucherConfirmDoneTitle;

  /// No description provided for @uiVoucherConfirmDoneAt.
  ///
  /// In en, this message translates to:
  /// **'Confirmed on {when}'**
  String uiVoucherConfirmDoneAt(String when);

  /// No description provided for @uiVoucherConfirmThread.
  ///
  /// In en, this message translates to:
  /// **'Share of the confirm window that has passed'**
  String get uiVoucherConfirmThread;
}

class _GzL10nDelegate extends LocalizationsDelegate<GzL10n> {
  const _GzL10nDelegate();

  @override
  Future<GzL10n> load(Locale locale) {
    return SynchronousFuture<GzL10n>(lookupGzL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_GzL10nDelegate old) => false;
}

GzL10n lookupGzL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return GzL10nAr();
    case 'en':
      return GzL10nEn();
  }

  throw FlutterError(
    'GzL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
