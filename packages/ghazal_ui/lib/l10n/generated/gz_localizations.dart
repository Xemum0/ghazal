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

  /// No description provided for @stubNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get stubNotBuilt;
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
