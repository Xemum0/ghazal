import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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

  /// No description provided for @clientAuthSharedNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get clientAuthSharedNotNow;

  /// No description provided for @clientAuthSharedSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientAuthSharedSupport;

  /// No description provided for @clientAuthSharedApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get clientAuthSharedApple;

  /// No description provided for @clientAuthSharedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get clientAuthSharedGoogle;

  /// No description provided for @clientAuthSharedUsePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get clientAuthSharedUsePassword;

  /// No description provided for @clientAuthSharedUseCode.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp code'**
  String get clientAuthSharedUseCode;

  /// No description provided for @clientAuthSharedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientAuthSharedSignIn;

  /// No description provided for @clientAuthSharedCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get clientAuthSharedCreateAccount;

  /// No description provided for @clientAuthSharedSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get clientAuthSharedSignedIn;

  /// No description provided for @clientAuthSharedAccountReady.
  ///
  /// In en, this message translates to:
  /// **'Account ready'**
  String get clientAuthSharedAccountReady;

  /// No description provided for @clientAuthSharedPhone.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get clientAuthSharedPhone;

  /// No description provided for @clientAuthSharedSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get clientAuthSharedSendCode;

  /// No description provided for @clientAuthSharedDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientAuthSharedDate;

  /// No description provided for @clientAuthSharedGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientAuthSharedGuests;

  /// No description provided for @clientAuthSharedLegalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get clientAuthSharedLegalTerms;

  /// No description provided for @clientAuthSharedLegalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get clientAuthSharedLegalPrivacy;

  /// No description provided for @clientAuthSharedLegalNote.
  ///
  /// In en, this message translates to:
  /// **'Full text before launch'**
  String get clientAuthSharedLegalNote;

  /// No description provided for @clientAuthSharedTermsSection1.
  ///
  /// In en, this message translates to:
  /// **'Using Ghazal'**
  String get clientAuthSharedTermsSection1;

  /// No description provided for @clientAuthSharedTermsSection2.
  ///
  /// In en, this message translates to:
  /// **'The voucher'**
  String get clientAuthSharedTermsSection2;

  /// No description provided for @clientAuthSharedTermsSection3.
  ///
  /// In en, this message translates to:
  /// **'Paying the venue'**
  String get clientAuthSharedTermsSection3;

  /// No description provided for @clientAuthSharedTermsSection4.
  ///
  /// In en, this message translates to:
  /// **'Your responsibilities'**
  String get clientAuthSharedTermsSection4;

  /// No description provided for @clientAuthSharedPrivacySection1.
  ///
  /// In en, this message translates to:
  /// **'What we collect'**
  String get clientAuthSharedPrivacySection1;

  /// No description provided for @clientAuthSharedPrivacySection2.
  ///
  /// In en, this message translates to:
  /// **'How we use it'**
  String get clientAuthSharedPrivacySection2;

  /// No description provided for @clientAuthSharedPrivacySection3.
  ///
  /// In en, this message translates to:
  /// **'Who sees it'**
  String get clientAuthSharedPrivacySection3;

  /// No description provided for @clientAuthSharedPrivacySection4.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get clientAuthSharedPrivacySection4;

  /// No description provided for @clientAuthSharedInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get clientAuthSharedInfoTitle;

  /// No description provided for @clientAuthSharedPartnerNote.
  ///
  /// In en, this message translates to:
  /// **'Hotel or service provider? Use the Ghazal Partner app.'**
  String get clientAuthSharedPartnerNote;

  /// No description provided for @clientAuthSharedSmallPrint.
  ///
  /// In en, this message translates to:
  /// **'Our <terms>Terms of Use</terms> and <privacy>Privacy Policy</privacy> apply. You confirm them when you create an account.'**
  String get clientAuthSharedSmallPrint;

  /// No description provided for @clientAuthReasonSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientAuthReasonSendRequest;

  /// No description provided for @clientAuthReasonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientAuthReasonVoucher;

  /// No description provided for @clientAuthReasonVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get clientAuthReasonVisit;

  /// No description provided for @clientAuthReasonChat.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientAuthReasonChat;

  /// No description provided for @clientAuthReasonReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get clientAuthReasonReview;

  /// No description provided for @clientAuthReasonPlanner.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get clientAuthReasonPlanner;

  /// No description provided for @clientAuthReasonQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get clientAuthReasonQuote;

  /// No description provided for @clientAuthReasonSave.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get clientAuthReasonSave;

  /// No description provided for @clientAuthGateErrorDigits.
  ///
  /// In en, this message translates to:
  /// **'Needs {count, plural, one{{count} digit} other{{count} digits}}'**
  String clientAuthGateErrorDigits(int count);

  /// No description provided for @clientAuthGateErrorNotOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Not on WhatsApp'**
  String get clientAuthGateErrorNotOnWhatsapp;

  /// No description provided for @clientAuthGateNotOnWhatsappDetail.
  ///
  /// In en, this message translates to:
  /// **'We could not send a code to this number on WhatsApp. Continue with Apple or Google, or contact Support.'**
  String get clientAuthGateNotOnWhatsappDetail;

  /// No description provided for @clientAuthOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp code'**
  String get clientAuthOtpTitle;

  /// No description provided for @clientAuthOtpSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify number'**
  String get clientAuthOtpSheetTitle;

  /// No description provided for @clientAuthOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get clientAuthOtpLabel;

  /// No description provided for @clientAuthOtpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get clientAuthOtpVerify;

  /// No description provided for @clientAuthOtpWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong code'**
  String get clientAuthOtpWrong;

  /// No description provided for @clientAuthOtpAttemptsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} attempt remaining} other{{count} attempts remaining}}'**
  String clientAuthOtpAttemptsLeft(int count);

  /// No description provided for @clientAuthOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get clientAuthOtpExpired;

  /// No description provided for @clientAuthOtpResent.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get clientAuthOtpResent;

  /// No description provided for @clientAuthOtpResendIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Resend code in {count} second} other{Resend code in {count} seconds}}'**
  String clientAuthOtpResendIn(int count);

  /// No description provided for @clientAuthOtpTimer.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String clientAuthOtpTimer(String count);

  /// No description provided for @clientAuthOtpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get clientAuthOtpResend;

  /// No description provided for @clientAuthOtpChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get clientAuthOtpChange;

  /// No description provided for @clientAuthOtpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get clientAuthOtpChangeNumber;

  /// No description provided for @clientAuthOtpLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts'**
  String get clientAuthOtpLocked;

  /// No description provided for @clientAuthOtpLockedDetail.
  ///
  /// In en, this message translates to:
  /// **'Please try again later or contact Support.'**
  String get clientAuthOtpLockedDetail;

  /// No description provided for @clientAuthOtpDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get clientAuthOtpDeliveryFailed;

  /// No description provided for @clientAuthOtpDeliveryFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'The code did not reach WhatsApp. Send it again, or continue another way.'**
  String get clientAuthOtpDeliveryFailedDetail;

  /// No description provided for @clientAuthOtpSendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get clientAuthOtpSendAgain;

  /// No description provided for @clientAuthOtpSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get clientAuthOtpSuccessTitle;

  /// No description provided for @clientAuthOtpOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp'**
  String get clientAuthOtpOpening;

  /// No description provided for @clientAuthNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get clientAuthNameTitle;

  /// No description provided for @clientAuthNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientAuthNameLabel;

  /// No description provided for @clientAuthNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get clientAuthNamePlaceholder;

  /// No description provided for @clientAuthNameEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientAuthNameEmailLabel;

  /// No description provided for @clientAuthNameAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get clientAuthNameAccept;

  /// No description provided for @clientAuthNameLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy'**
  String get clientAuthNameLegalTitle;

  /// No description provided for @clientAuthNameKept.
  ///
  /// In en, this message translates to:
  /// **'Saved to your account'**
  String get clientAuthNameKept;

  /// No description provided for @clientAuthNameMonogram.
  ///
  /// In en, this message translates to:
  /// **'Your monogram'**
  String get clientAuthNameMonogram;

  /// No description provided for @clientAuthPwdForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get clientAuthPwdForgotTitle;

  /// No description provided for @clientAuthPwdResetTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get clientAuthPwdResetTitle;

  /// No description provided for @clientAuthPwdPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get clientAuthPwdPassword;

  /// No description provided for @clientAuthPwdShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get clientAuthPwdShow;

  /// No description provided for @clientAuthPwdHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get clientAuthPwdHide;

  /// No description provided for @clientAuthPwdForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot?'**
  String get clientAuthPwdForgot;

  /// No description provided for @clientAuthPwdForgotLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get clientAuthPwdForgotLabel;

  /// No description provided for @clientAuthPwdEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get clientAuthPwdEnterCode;

  /// No description provided for @clientAuthPwdVerified.
  ///
  /// In en, this message translates to:
  /// **'Number verified on WhatsApp'**
  String get clientAuthPwdVerified;

  /// No description provided for @clientAuthPwdStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength: {level}'**
  String clientAuthPwdStrength(String level);

  /// No description provided for @clientAuthPwdStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get clientAuthPwdStrengthWeak;

  /// No description provided for @clientAuthPwdStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get clientAuthPwdStrengthFair;

  /// No description provided for @clientAuthPwdStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get clientAuthPwdStrengthStrong;

  /// No description provided for @clientAuthPwdRuleLength.
  ///
  /// In en, this message translates to:
  /// **'At least {count, plural, one{{count} character} other{{count} characters}}'**
  String clientAuthPwdRuleLength(int count);

  /// No description provided for @clientAuthPwdRuleMix.
  ///
  /// In en, this message translates to:
  /// **'A letter and a number'**
  String get clientAuthPwdRuleMix;

  /// No description provided for @clientAuthPwdRulePhone.
  ///
  /// In en, this message translates to:
  /// **'Not your number'**
  String get clientAuthPwdRulePhone;

  /// No description provided for @clientAuthPwdRuleMet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get clientAuthPwdRuleMet;

  /// No description provided for @clientAuthPwdRuleOpen.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get clientAuthPwdRuleOpen;

  /// No description provided for @clientAuthPwdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Details don’t match'**
  String get clientAuthPwdInvalid;

  /// No description provided for @clientAuthPwdLocked.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get clientAuthPwdLocked;

  /// No description provided for @clientAuthPwdUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get clientAuthPwdUpdatedTitle;

  /// No description provided for @clientAuthBioTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get clientAuthBioTitle;

  /// No description provided for @clientAuthBioMethod.
  ///
  /// In en, this message translates to:
  /// **'{method, select, face{Face ID} touch{Touch ID} other{Fingerprint}}'**
  String clientAuthBioMethod(String method);

  /// No description provided for @clientAuthBioPromptDetail.
  ///
  /// In en, this message translates to:
  /// **'{method, select, face{Face ID} touch{Touch ID} other{Your fingerprint}} only unlocks the sign-in kept on this phone. It never replaces your first sign-in.'**
  String clientAuthBioPromptDetail(String method);

  /// No description provided for @clientAuthBioTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get clientAuthBioTurnOn;

  /// No description provided for @clientAuthBioUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get clientAuthBioUnlock;

  /// No description provided for @clientAuthBioFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not matched'**
  String get clientAuthBioFailedTitle;

  /// No description provided for @clientAuthBioFailedDetail.
  ///
  /// In en, this message translates to:
  /// **'You can try again or sign in another way. Your account is not locked.'**
  String get clientAuthBioFailedDetail;

  /// No description provided for @clientAuthBioUnavailableRow.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get clientAuthBioUnavailableRow;

  /// No description provided for @clientAuthBioUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'Add Face ID or a fingerprint in your phone’s settings to turn this on. Biometrics only unlock the sign-in kept on this phone.'**
  String get clientAuthBioUnavailableDetail;

  /// No description provided for @clientAuthBioEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Turned on'**
  String get clientAuthBioEnabledTitle;

  /// No description provided for @clientBookingStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String clientBookingStepOf(String step, String total);

  /// No description provided for @clientBookingStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Request progress'**
  String get clientBookingStepsLabel;

  /// No description provided for @clientBookingLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave request?'**
  String get clientBookingLeaveTitle;

  /// No description provided for @clientBookingLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Draft saved.'**
  String get clientBookingLeaveBody;

  /// No description provided for @clientBookingLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get clientBookingLeaveConfirm;

  /// No description provided for @clientBookingLeaveKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get clientBookingLeaveKeep;

  /// No description provided for @clientBookingEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Est.'**
  String get clientBookingEstimateLabel;

  /// No description provided for @clientBookingOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline. Draft saved.'**
  String get clientBookingOfflineBanner;

  /// No description provided for @clientBookingPriceErrorBanner.
  ///
  /// In en, this message translates to:
  /// **'Price not updated'**
  String get clientBookingPriceErrorBanner;

  /// No description provided for @clientBookingPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientBookingPriceTitle;

  /// No description provided for @clientBookingVoucherTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientBookingVoucherTotalLabel;

  /// No description provided for @clientBookingVoucherEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher price (est.)'**
  String get clientBookingVoucherEstimateLabel;

  /// No description provided for @clientBookingYouSaveNet.
  ///
  /// In en, this message translates to:
  /// **'You save {amount} after the voucher fee'**
  String clientBookingYouSaveNet(String amount);

  /// No description provided for @clientBookingReplyWithin.
  ///
  /// In en, this message translates to:
  /// **'The venue replies within'**
  String get clientBookingReplyWithin;

  /// No description provided for @clientBookingReplyFast.
  ///
  /// In en, this message translates to:
  /// **'The venue is asked to reply within'**
  String get clientBookingReplyFast;

  /// No description provided for @clientBookingEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Your event'**
  String get clientBookingEventTitle;

  /// No description provided for @clientBookingDateChange.
  ///
  /// In en, this message translates to:
  /// **'Change the date'**
  String get clientBookingDateChange;

  /// No description provided for @clientBookingDateTakenAction.
  ///
  /// In en, this message translates to:
  /// **'Free dates'**
  String get clientBookingDateTakenAction;

  /// No description provided for @clientBookingDateTakenBanner.
  ///
  /// In en, this message translates to:
  /// **'{date} unavailable'**
  String clientBookingDateTakenBanner(String date);

  /// No description provided for @clientBookingDateTakenReason.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get clientBookingDateTakenReason;

  /// No description provided for @clientBookingHostingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get clientBookingHostingLabel;

  /// No description provided for @clientBookingHostingWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get clientBookingHostingWomen;

  /// No description provided for @clientBookingHostingMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get clientBookingHostingMen;

  /// No description provided for @clientBookingHostingMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed celebration'**
  String get clientBookingHostingMixed;

  /// No description provided for @clientBookingHostingWomenShort.
  ///
  /// In en, this message translates to:
  /// **'Ladies’'**
  String get clientBookingHostingWomenShort;

  /// No description provided for @clientBookingHostingMenShort.
  ///
  /// In en, this message translates to:
  /// **'Men’s'**
  String get clientBookingHostingMenShort;

  /// No description provided for @clientBookingHostingMixedShort.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get clientBookingHostingMixedShort;

  /// No description provided for @clientBookingHallLabel.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientBookingHallLabel;

  /// No description provided for @clientBookingSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get clientBookingSessionLabel;

  /// No description provided for @clientBookingGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientBookingGuestsLabel;

  /// No description provided for @clientBookingGuestsPresets.
  ///
  /// In en, this message translates to:
  /// **'Common guest counts'**
  String get clientBookingGuestsPresets;

  /// No description provided for @clientBookingOccasionLabel.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get clientBookingOccasionLabel;

  /// No description provided for @clientBookingOccasionWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get clientBookingOccasionWedding;

  /// No description provided for @clientBookingOccasionMilka.
  ///
  /// In en, this message translates to:
  /// **'Milka'**
  String get clientBookingOccasionMilka;

  /// No description provided for @clientBookingOccasionHenna.
  ///
  /// In en, this message translates to:
  /// **'Henna'**
  String get clientBookingOccasionHenna;

  /// No description provided for @clientBookingOccasionEngagement.
  ///
  /// In en, this message translates to:
  /// **'Engagement'**
  String get clientBookingOccasionEngagement;

  /// No description provided for @clientBookingOccasionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientBookingOccasionOther;

  /// No description provided for @clientBookingNeedVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher first'**
  String get clientBookingNeedVoucherTitle;

  /// No description provided for @clientBookingNeedVoucherInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientBookingNeedVoucherInfoTitle;

  /// No description provided for @clientBookingNeedVoucherBody.
  ///
  /// In en, this message translates to:
  /// **'A request needs a voucher. It gives you the voucher price and goes to the venue with your request.'**
  String get clientBookingNeedVoucherBody;

  /// No description provided for @clientBookingHostingOneVoucher.
  ///
  /// In en, this message translates to:
  /// **'One voucher covers one reception. A second reception is its own request with its own voucher.'**
  String get clientBookingHostingOneVoucher;

  /// No description provided for @clientBookingNeedVoucherAction.
  ///
  /// In en, this message translates to:
  /// **'Get voucher {fee}'**
  String clientBookingNeedVoucherAction(String fee);

  /// No description provided for @clientBookingFromVoucher.
  ///
  /// In en, this message translates to:
  /// **'From your voucher'**
  String get clientBookingFromVoucher;

  /// No description provided for @clientBookingFromVoucherChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get clientBookingFromVoucherChange;

  /// No description provided for @clientBookingFromVoucherChangeAria.
  ///
  /// In en, this message translates to:
  /// **'Change what the voucher is bound to'**
  String get clientBookingFromVoucherChangeAria;

  /// No description provided for @clientBookingPackageTitle.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientBookingPackageTitle;

  /// No description provided for @clientBookingPackageSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get clientBookingPackageSelected;

  /// No description provided for @clientBookingPackageIncludes.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get clientBookingPackageIncludes;

  /// No description provided for @clientBookingPackageDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get clientBookingPackageDetails;

  /// No description provided for @clientBookingPackageFlat.
  ///
  /// In en, this message translates to:
  /// **'Package price'**
  String get clientBookingPackageFlat;

  /// No description provided for @clientBookingPackageNoVoucher.
  ///
  /// In en, this message translates to:
  /// **'No voucher'**
  String get clientBookingPackageNoVoucher;

  /// No description provided for @clientBookingPackageChangeVoucher.
  ///
  /// In en, this message translates to:
  /// **'Opens the voucher for this quote'**
  String get clientBookingPackageChangeVoucher;

  /// No description provided for @clientBookingPackageNotCoveredToast.
  ///
  /// In en, this message translates to:
  /// **'Not covered by voucher'**
  String get clientBookingPackageNotCoveredToast;

  /// No description provided for @clientBookingPackageNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No package fits'**
  String get clientBookingPackageNoneTitle;

  /// No description provided for @clientBookingPackageNoneBody.
  ///
  /// In en, this message translates to:
  /// **'No package fits {guests} in this hall. Change the guests or choose another hall.'**
  String clientBookingPackageNoneBody(String guests);

  /// No description provided for @clientBookingPackageNoneInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get clientBookingPackageNoneInfoTitle;

  /// No description provided for @clientBookingPackageNoneAction.
  ///
  /// In en, this message translates to:
  /// **'Change guests'**
  String get clientBookingPackageNoneAction;

  /// No description provided for @clientBookingPackageMissingReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a package'**
  String get clientBookingPackageMissingReason;

  /// No description provided for @clientBookingPackageBreakdownOpen.
  ///
  /// In en, this message translates to:
  /// **'See the price breakdown'**
  String get clientBookingPackageBreakdownOpen;

  /// No description provided for @clientBookingExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get clientBookingExtrasTitle;

  /// No description provided for @clientBookingExtrasInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get clientBookingExtrasInfoTitle;

  /// No description provided for @clientBookingExtrasIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get clientBookingExtrasIncluded;

  /// No description provided for @clientBookingExtrasNone.
  ///
  /// In en, this message translates to:
  /// **'No extras'**
  String get clientBookingExtrasNone;

  /// No description provided for @clientBookingExtrasNoneOffered.
  ///
  /// In en, this message translates to:
  /// **'This venue does not sell extras for your booking. You can continue.'**
  String get clientBookingExtrasNoneOffered;

  /// No description provided for @clientBookingExtrasLead.
  ///
  /// In en, this message translates to:
  /// **'Optional and priced separately, at your voucher price where the venue has one.'**
  String get clientBookingExtrasLead;

  /// No description provided for @clientBookingExtrasSettledNote.
  ///
  /// In en, this message translates to:
  /// **'Extras are settled directly with the venue.'**
  String get clientBookingExtrasSettledNote;

  /// No description provided for @clientBookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get clientBookingDetailsTitle;

  /// No description provided for @clientBookingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientBookingNameLabel;

  /// No description provided for @clientBookingNameError.
  ///
  /// In en, this message translates to:
  /// **'Add a name'**
  String get clientBookingNameError;

  /// No description provided for @clientBookingPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get clientBookingPhoneLabel;

  /// No description provided for @clientBookingPhoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get clientBookingPhoneVerified;

  /// No description provided for @clientBookingPhoneVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get clientBookingPhoneVerify;

  /// No description provided for @clientBookingPhoneDigits.
  ///
  /// In en, this message translates to:
  /// **'Needs {count, plural, one{{count} digit} other{{count} digits}}'**
  String clientBookingPhoneDigits(int count);

  /// No description provided for @clientBookingEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientBookingEmailLabel;

  /// No description provided for @clientBookingForLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking for'**
  String get clientBookingForLabel;

  /// No description provided for @clientBookingForSelf.
  ///
  /// In en, this message translates to:
  /// **'Myself'**
  String get clientBookingForSelf;

  /// No description provided for @clientBookingForOther.
  ///
  /// In en, this message translates to:
  /// **'Someone else'**
  String get clientBookingForOther;

  /// No description provided for @clientBookingForNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get clientBookingForNameLabel;

  /// No description provided for @clientBookingForRelationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get clientBookingForRelationLabel;

  /// No description provided for @clientBookingRelationBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get clientBookingRelationBride;

  /// No description provided for @clientBookingRelationGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get clientBookingRelationGroom;

  /// No description provided for @clientBookingRelationFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get clientBookingRelationFamily;

  /// No description provided for @clientBookingRelationPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get clientBookingRelationPlanner;

  /// No description provided for @clientBookingRequestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get clientBookingRequestsLabel;

  /// No description provided for @clientBookingRequestsSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Common requests'**
  String get clientBookingRequestsSuggestions;

  /// No description provided for @clientBookingSuggestPhotographer.
  ///
  /// In en, this message translates to:
  /// **'Female photographer only'**
  String get clientBookingSuggestPhotographer;

  /// No description provided for @clientBookingSuggestKosha.
  ///
  /// In en, this message translates to:
  /// **'Kosha team access from {time}'**
  String clientBookingSuggestKosha(String time);

  /// No description provided for @clientBookingSuggestWheelchair.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair access'**
  String get clientBookingSuggestWheelchair;

  /// No description provided for @clientBookingSuggestPhotographerShort.
  ///
  /// In en, this message translates to:
  /// **'Photographer'**
  String get clientBookingSuggestPhotographerShort;

  /// No description provided for @clientBookingSuggestKoshaShort.
  ///
  /// In en, this message translates to:
  /// **'Kosha'**
  String get clientBookingSuggestKoshaShort;

  /// No description provided for @clientBookingSuggestWheelchairShort.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair'**
  String get clientBookingSuggestWheelchairShort;

  /// No description provided for @clientBookingPrivacyWord.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get clientBookingPrivacyWord;

  /// No description provided for @clientBookingPrivacy.
  ///
  /// In en, this message translates to:
  /// **'{venue} sees your name and phone for this request only. It sees your voucher code only when you redeem it.'**
  String clientBookingPrivacy(String venue);

  /// No description provided for @clientBookingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get clientBookingReviewTitle;

  /// No description provided for @clientBookingReviewExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get clientBookingReviewExtras;

  /// No description provided for @clientBookingReviewContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientBookingReviewContact;

  /// No description provided for @clientBookingReviewPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientBookingReviewPackage;

  /// No description provided for @clientBookingReviewPriceNote.
  ///
  /// In en, this message translates to:
  /// **'All-in, and frozen when you send. Nothing more to pay Ghazal: after you confirm, you pay the venue directly.'**
  String get clientBookingReviewPriceNote;

  /// No description provided for @clientBookingNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get clientBookingNextTitle;

  /// No description provided for @clientBookingNextSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get clientBookingNextSend;

  /// No description provided for @clientBookingNextReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get clientBookingNextReply;

  /// No description provided for @clientBookingNextConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientBookingNextConfirm;

  /// No description provided for @clientBookingNextVenue.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get clientBookingNextVenue;

  /// No description provided for @clientBookingNextReplyNote.
  ///
  /// In en, this message translates to:
  /// **'Expected reply by'**
  String get clientBookingNextReplyNote;

  /// No description provided for @clientBookingNextConfirmNote.
  ///
  /// In en, this message translates to:
  /// **'Time to confirm after approval'**
  String get clientBookingNextConfirmNote;

  /// No description provided for @clientBookingNextVenueNote.
  ///
  /// In en, this message translates to:
  /// **'You pay {venue} directly and show your voucher code.'**
  String clientBookingNextVenueNote(String venue);

  /// No description provided for @clientBookingConsent.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get clientBookingConsent;

  /// No description provided for @clientBookingConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get clientBookingConsentTitle;

  /// No description provided for @clientBookingConsentBody.
  ///
  /// In en, this message translates to:
  /// **'I agree to the venue terms, the voucher terms and the platform terms.'**
  String get clientBookingConsentBody;

  /// No description provided for @clientBookingConsentRead.
  ///
  /// In en, this message translates to:
  /// **'Read the terms'**
  String get clientBookingConsentRead;

  /// No description provided for @clientBookingSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientBookingSend;

  /// No description provided for @clientBookingSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Try again.'**
  String get clientBookingSendFailed;

  /// No description provided for @clientBookingReasonConsent.
  ///
  /// In en, this message translates to:
  /// **'Agree to send'**
  String get clientBookingReasonConsent;

  /// No description provided for @clientBookingReasonLimit.
  ///
  /// In en, this message translates to:
  /// **'Requests full'**
  String get clientBookingReasonLimit;

  /// No description provided for @clientBookingReasonVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher needed'**
  String get clientBookingReasonVoucher;

  /// No description provided for @clientBookingReasonPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get clientBookingReasonPhone;

  /// No description provided for @clientBookingLimitBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} open'**
  String clientBookingLimitBanner(String count, String max);

  /// No description provided for @clientBookingLimitAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientBookingLimitAction;

  /// No description provided for @clientBookingLimitInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get clientBookingLimitInfoTitle;

  /// No description provided for @clientBookingLimitInfo.
  ///
  /// In en, this message translates to:
  /// **'Withdraw an open request to send another.'**
  String get clientBookingLimitInfo;

  /// No description provided for @clientBookingPhoneBanner.
  ///
  /// In en, this message translates to:
  /// **'Phone not verified'**
  String get clientBookingPhoneBanner;

  /// No description provided for @clientBookingVoucherUneconomic.
  ///
  /// In en, this message translates to:
  /// **'Saving too low'**
  String get clientBookingVoucherUneconomic;

  /// No description provided for @clientBookingVoucherUneconomicInfo.
  ///
  /// In en, this message translates to:
  /// **'For this quote the saving is no longer more than the voucher price, so the voucher cannot be used for it.'**
  String get clientBookingVoucherUneconomicInfo;

  /// No description provided for @clientBookingVoucherCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientBookingVoucherCardTitle;

  /// No description provided for @clientBookingVoucherChange.
  ///
  /// In en, this message translates to:
  /// **'Change voucher'**
  String get clientBookingVoucherChange;

  /// No description provided for @clientBookingVoucherValid.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get clientBookingVoucherValid;

  /// No description provided for @clientBookingQuoteChanged.
  ///
  /// In en, this message translates to:
  /// **'Your total changed since you got the voucher, because of the extras you added. The voucher still applies.'**
  String get clientBookingQuoteChanged;

  /// No description provided for @clientBookingQuoteChangedShort.
  ///
  /// In en, this message translates to:
  /// **'Total changed'**
  String get clientBookingQuoteChangedShort;

  /// No description provided for @clientBookingSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientBookingSentTitle;

  /// No description provided for @clientBookingSentInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get clientBookingSentInfoTitle;

  /// No description provided for @clientBookingSentBody.
  ///
  /// In en, this message translates to:
  /// **'The date is not held yet. If {venue} approves, we hold it for you for {count, plural, one{{count} hour} other{{count} hours}} so you can confirm. Your voucher is attached to the request.'**
  String clientBookingSentBody(String venue, int count);

  /// No description provided for @clientBookingSentWithdraw.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw this request. Your voucher comes back and can be used again here.'**
  String get clientBookingSentWithdraw;

  /// No description provided for @clientBookingSentDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientBookingSentDate;

  /// No description provided for @clientBookingSentHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientBookingSentHall;

  /// No description provided for @clientBookingSentGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientBookingSentGuests;

  /// No description provided for @clientBookingSentReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get clientBookingSentReference;

  /// No description provided for @clientBookingSentVoucherPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientBookingSentVoucherPrice;

  /// No description provided for @clientBookingSentHeld.
  ///
  /// In en, this message translates to:
  /// **'Date held'**
  String get clientBookingSentHeld;

  /// No description provided for @clientBookingSentHeldLong.
  ///
  /// In en, this message translates to:
  /// **'Date held by another couple'**
  String get clientBookingSentHeldLong;

  /// No description provided for @clientBookingSentView.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientBookingSentView;

  /// No description provided for @clientBookingSentDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get clientBookingSentDiscover;

  /// No description provided for @clientBookingSentWedding.
  ///
  /// In en, this message translates to:
  /// **'My Wedding'**
  String get clientBookingSentWedding;

  /// No description provided for @clientBookingSentNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates'**
  String get clientBookingSentNotifTitle;

  /// No description provided for @clientBookingSentNotifYes.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get clientBookingSentNotifYes;

  /// No description provided for @clientBookingSentNotifNo.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get clientBookingSentNotifNo;

  /// No description provided for @clientBookingSentNotifToast.
  ///
  /// In en, this message translates to:
  /// **'Updates on'**
  String get clientBookingSentNotifToast;

  /// No description provided for @clientBookingSentOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Summary saved.'**
  String get clientBookingSentOffline;

  /// No description provided for @clientBookingPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding planner'**
  String get clientBookingPlannerTitle;

  /// No description provided for @clientBookingPlannerNo.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get clientBookingPlannerNo;

  /// No description provided for @clientBookingTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get clientBookingTakenTitle;

  /// No description provided for @clientBookingTakenSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session unavailable'**
  String get clientBookingTakenSessionTitle;

  /// No description provided for @clientBookingTakenExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Window ended'**
  String get clientBookingTakenExpiredTitle;

  /// No description provided for @clientBookingTakenLoading.
  ///
  /// In en, this message translates to:
  /// **'Looking for free dates'**
  String get clientBookingTakenLoading;

  /// No description provided for @clientBookingTakenNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest free dates'**
  String get clientBookingTakenNearest;

  /// No description provided for @clientBookingTakenSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar halls free on {date}'**
  String clientBookingTakenSimilar(String date);

  /// No description provided for @clientBookingTakenAnother.
  ///
  /// In en, this message translates to:
  /// **'Other date'**
  String get clientBookingTakenAnother;

  /// No description provided for @clientBookingTakenResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get clientBookingTakenResults;

  /// No description provided for @clientBookingTakenNone.
  ///
  /// In en, this message translates to:
  /// **'No dates nearby'**
  String get clientBookingTakenNone;

  /// No description provided for @clientBookingTakenNoneInfo.
  ///
  /// In en, this message translates to:
  /// **'No free dates near {date} at this hall. Choose another date or see other halls.'**
  String clientBookingTakenNoneInfo(String date);

  /// No description provided for @clientBookingTakenVoucherValid.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is still valid'**
  String get clientBookingTakenVoucherValid;

  /// No description provided for @clientBookingTakenRebindFailed.
  ///
  /// In en, this message translates to:
  /// **'Voucher can’t move there'**
  String get clientBookingTakenRebindFailed;

  /// No description provided for @clientBookingTakenRebound.
  ///
  /// In en, this message translates to:
  /// **'Voucher moved to {date}'**
  String clientBookingTakenRebound(String date);

  /// No description provided for @clientBookingConfirmHeading.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientBookingConfirmHeading;

  /// No description provided for @clientBookingConfirmByLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm by'**
  String get clientBookingConfirmByLabel;

  /// No description provided for @clientBookingConfirmLapsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Lapsed on'**
  String get clientBookingConfirmLapsedLabel;

  /// No description provided for @clientBookingConfirmWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Time to confirm'**
  String get clientBookingConfirmWindowLabel;

  /// No description provided for @clientBookingConfirmLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} remaining to confirm'**
  String clientBookingConfirmLeft(String time);

  /// No description provided for @clientBookingConfirmSummary.
  ///
  /// In en, this message translates to:
  /// **'What the venue approved'**
  String get clientBookingConfirmSummary;

  /// No description provided for @clientBookingConfirmSaveNet.
  ///
  /// In en, this message translates to:
  /// **'You save after the voucher fee'**
  String get clientBookingConfirmSaveNet;

  /// No description provided for @clientBookingConfirmPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get clientBookingConfirmPayTitle;

  /// No description provided for @clientBookingConfirmPay.
  ///
  /// In en, this message translates to:
  /// **'Nothing is paid here. You pay the venue directly after you confirm.'**
  String get clientBookingConfirmPay;

  /// No description provided for @clientBookingConfirmConsentBody.
  ///
  /// In en, this message translates to:
  /// **'I agree to the venue terms and the voucher terms.'**
  String get clientBookingConfirmConsentBody;

  /// No description provided for @clientBookingConfirmNoteCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirming books the date at the voucher price. Cancelling after you confirm releases the date and the voucher is used.'**
  String get clientBookingConfirmNoteCancel;

  /// No description provided for @clientBookingConfirmReasonConsent.
  ///
  /// In en, this message translates to:
  /// **'Agree to confirm'**
  String get clientBookingConfirmReasonConsent;

  /// No description provided for @clientBookingConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get clientBookingConfirmAction;

  /// No description provided for @clientBookingConfirmSeeNext.
  ///
  /// In en, this message translates to:
  /// **'See options'**
  String get clientBookingConfirmSeeNext;

  /// No description provided for @clientBookingConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientBookingConfirmCancel;

  /// No description provided for @clientBookingConfirmViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientBookingConfirmViewRequest;

  /// No description provided for @clientBookingConfirmOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Reconnect to confirm.'**
  String get clientBookingConfirmOffline;

  /// No description provided for @clientBookingUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request updated'**
  String get clientBookingUpdatedTitle;

  /// No description provided for @clientBookingUpdatedAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get clientBookingUpdatedAction;

  /// No description provided for @clientBookingDoneHeading.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get clientBookingDoneHeading;

  /// No description provided for @clientBookingDoneVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientBookingDoneVoucherTitle;

  /// No description provided for @clientBookingDonePayWord.
  ///
  /// In en, this message translates to:
  /// **'Pay venue'**
  String get clientBookingDonePayWord;

  /// No description provided for @clientBookingDonePayTitle.
  ///
  /// In en, this message translates to:
  /// **'At the venue'**
  String get clientBookingDonePayTitle;

  /// No description provided for @clientBookingDonePay.
  ///
  /// In en, this message translates to:
  /// **'Pay {venue} directly, then show this code at the venue.'**
  String clientBookingDonePay(String venue);

  /// No description provided for @clientBookingDoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get clientBookingDoneCopied;

  /// No description provided for @clientBookingDoneChecklist.
  ///
  /// In en, this message translates to:
  /// **'Venue marked done in your checklist'**
  String get clientBookingDoneChecklist;

  /// No description provided for @clientBookingDoneSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set wedding date'**
  String get clientBookingDoneSetDate;

  /// No description provided for @clientBookingDoneDateSet.
  ///
  /// In en, this message translates to:
  /// **'Wedding date set'**
  String get clientBookingDoneDateSet;

  /// No description provided for @clientBookingDoneActions.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get clientBookingDoneActions;

  /// No description provided for @clientBookingDoneDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get clientBookingDoneDirections;

  /// No description provided for @clientBookingDoneVisit.
  ///
  /// In en, this message translates to:
  /// **'Book a visit'**
  String get clientBookingDoneVisit;

  /// No description provided for @clientBookingDoneCall.
  ///
  /// In en, this message translates to:
  /// **'Call the venue'**
  String get clientBookingDoneCall;

  /// No description provided for @clientBookingDoneCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling the venue'**
  String get clientBookingDoneCalling;

  /// No description provided for @clientBookingDoneCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get clientBookingDoneCalendar;

  /// No description provided for @clientBookingDoneCalendarToast.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar'**
  String get clientBookingDoneCalendarToast;

  /// No description provided for @clientBookingDoneShared.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get clientBookingDoneShared;

  /// No description provided for @clientBookingDoneView.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get clientBookingDoneView;

  /// No description provided for @clientBookingMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get clientBookingMapsTitle;

  /// No description provided for @clientBookingMapsGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get clientBookingMapsGoogle;

  /// No description provided for @clientBookingMapsApple.
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get clientBookingMapsApple;

  /// No description provided for @clientBookingMapsWaze.
  ///
  /// In en, this message translates to:
  /// **'Waze'**
  String get clientBookingMapsWaze;

  /// No description provided for @clientBookingMapsToast.
  ///
  /// In en, this message translates to:
  /// **'Opening directions'**
  String get clientBookingMapsToast;

  /// No description provided for @clientBookingEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Window ended'**
  String get clientBookingEndedTitle;

  /// No description provided for @clientBookingEndedRevokedTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval withdrawn'**
  String get clientBookingEndedRevokedTitle;

  /// No description provided for @clientBookingEndedTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get clientBookingEndedTakenTitle;

  /// No description provided for @clientBookingEndedLapsed.
  ///
  /// In en, this message translates to:
  /// **'The {duration} to confirm have ended. {date} was released and the voucher is no longer valid.'**
  String clientBookingEndedLapsed(String duration, String date);

  /// No description provided for @clientBookingEndedRevoked.
  ///
  /// In en, this message translates to:
  /// **'{venue} can no longer hold {date}, so the approval was withdrawn.'**
  String clientBookingEndedRevoked(String venue, String date);

  /// No description provided for @clientBookingEndedTaken.
  ///
  /// In en, this message translates to:
  /// **'{date} is no longer available at {venue}.'**
  String clientBookingEndedTaken(String date, String venue);

  /// No description provided for @clientBookingEndedVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Your voucher'**
  String get clientBookingEndedVoucherTitle;

  /// No description provided for @clientBookingEndedVoucherPlain.
  ///
  /// In en, this message translates to:
  /// **'It is back with you and can be used for a new request here.'**
  String get clientBookingEndedVoucherPlain;

  /// No description provided for @clientBookingEndedRefund.
  ///
  /// In en, this message translates to:
  /// **'Ask for credit'**
  String get clientBookingEndedRefund;

  /// No description provided for @clientBookingEndedNew.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get clientBookingEndedNew;

  /// No description provided for @clientBookingEndedFreeDates.
  ///
  /// In en, this message translates to:
  /// **'Free dates'**
  String get clientBookingEndedFreeDates;

  /// No description provided for @clientBookingEndedViewVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientBookingEndedViewVenue;

  /// No description provided for @clientBookingEndedOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline. Reconnect to continue.'**
  String get clientBookingEndedOffline;

  /// No description provided for @clientBookingEndedReleased.
  ///
  /// In en, this message translates to:
  /// **'Hold released'**
  String get clientBookingEndedReleased;

  /// No description provided for @clientBookingEndedWindow.
  ///
  /// In en, this message translates to:
  /// **'Confirmation window'**
  String get clientBookingEndedWindow;

  /// No description provided for @clientBookingEndedUntil.
  ///
  /// In en, this message translates to:
  /// **'Can be used until'**
  String get clientBookingEndedUntil;

  /// No description provided for @clientBookingEndedVoucherForfeited.
  ///
  /// In en, this message translates to:
  /// **'Not valid. A voucher not confirmed at the venue within the window does not come back.'**
  String get clientBookingEndedVoucherForfeited;

  /// No description provided for @clientBookingEndedVoucherCredit.
  ///
  /// In en, this message translates to:
  /// **'It is back with you. Use it again at {venue} until {date}, or ask support for a credit voucher.'**
  String clientBookingEndedVoucherCredit(String venue, String date);

  /// No description provided for @clientBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get clientBookingsTitle;

  /// No description provided for @clientBookingsFindHall.
  ///
  /// In en, this message translates to:
  /// **'Find halls'**
  String get clientBookingsFindHall;

  /// No description provided for @clientBookingsSectionNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get clientBookingsSectionNeeds;

  /// No description provided for @clientBookingsSectionPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get clientBookingsSectionPending;

  /// No description provided for @clientBookingsSectionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get clientBookingsSectionConfirmed;

  /// No description provided for @clientBookingsSectionPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get clientBookingsSectionPast;

  /// No description provided for @clientBookingsPastFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter past requests'**
  String get clientBookingsPastFilter;

  /// No description provided for @clientBookingsPastNone.
  ///
  /// In en, this message translates to:
  /// **'No requests with this status'**
  String get clientBookingsPastNone;

  /// No description provided for @clientBookingsLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get clientBookingsLimitLabel;

  /// No description provided for @clientBookingsLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Close one to send another'**
  String get clientBookingsLimitReached;

  /// No description provided for @clientBookingsGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your requests'**
  String get clientBookingsGuestTitle;

  /// No description provided for @clientBookingsGuestAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientBookingsGuestAction;

  /// No description provided for @clientBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get clientBookingsEmptyTitle;

  /// No description provided for @clientBookingsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Find halls'**
  String get clientBookingsEmptyAction;

  /// No description provided for @clientBookingsEmptyActionDate.
  ///
  /// In en, this message translates to:
  /// **'Halls on {date}'**
  String clientBookingsEmptyActionDate(String date);

  /// No description provided for @clientBookingsVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get clientBookingsVouchers;

  /// No description provided for @clientBookingsReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get clientBookingsReceipts;

  /// No description provided for @clientBookingsAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get clientBookingsAudienceWomen;

  /// No description provided for @clientBookingsAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get clientBookingsAudienceMen;

  /// No description provided for @clientBookingsAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed reception'**
  String get clientBookingsAudienceMixed;

  /// No description provided for @clientBookingsSessionDay.
  ///
  /// In en, this message translates to:
  /// **'Day reception'**
  String get clientBookingsSessionDay;

  /// No description provided for @clientBookingsSessionAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon reception'**
  String get clientBookingsSessionAfternoon;

  /// No description provided for @clientBookingsSessionEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening reception'**
  String get clientBookingsSessionEvening;

  /// No description provided for @clientBookingsRowReplyBy.
  ///
  /// In en, this message translates to:
  /// **'Reply by'**
  String get clientBookingsRowReplyBy;

  /// No description provided for @clientBookingsRowVoucherBack.
  ///
  /// In en, this message translates to:
  /// **'Voucher is back'**
  String get clientBookingsRowVoucherBack;

  /// No description provided for @clientBookingsRowVoucherUsed.
  ///
  /// In en, this message translates to:
  /// **'Voucher used'**
  String get clientBookingsRowVoucherUsed;

  /// No description provided for @clientBookingsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get clientBookingsDetailTitle;

  /// No description provided for @clientBookingsThreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking progress'**
  String get clientBookingsThreadLabel;

  /// No description provided for @clientBookingsHeadFacts.
  ///
  /// In en, this message translates to:
  /// **'Booking facts'**
  String get clientBookingsHeadFacts;

  /// No description provided for @clientBookingsFactDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientBookingsFactDate;

  /// No description provided for @clientBookingsFactHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientBookingsFactHall;

  /// No description provided for @clientBookingsFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientBookingsFactGuests;

  /// No description provided for @clientBookingsFactQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get clientBookingsFactQuantity;

  /// No description provided for @clientBookingsFactPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientBookingsFactPackage;

  /// No description provided for @clientBookingsFactNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get clientBookingsFactNotes;

  /// No description provided for @clientBookingsPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientBookingsPendingTitle;

  /// No description provided for @clientBookingsPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is attached. Nothing is held yet.'**
  String get clientBookingsPendingBody;

  /// No description provided for @clientBookingsPendingHeldTitle.
  ///
  /// In en, this message translates to:
  /// **'Date held'**
  String get clientBookingsPendingHeldTitle;

  /// No description provided for @clientBookingsPendingHeld.
  ///
  /// In en, this message translates to:
  /// **'Another couple’s approved request is holding this date for now. If it lapses, yours can be approved. Your voucher stays attached.'**
  String get clientBookingsPendingHeld;

  /// No description provided for @clientBookingsPendingWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get clientBookingsPendingWithdraw;

  /// No description provided for @clientBookingsApprovedCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientBookingsApprovedCancel;

  /// No description provided for @clientBookingsCancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get clientBookingsCancelBooking;

  /// No description provided for @clientBookingsConfirmWindow.
  ///
  /// In en, this message translates to:
  /// **'Confirm window'**
  String get clientBookingsConfirmWindow;

  /// No description provided for @clientBookingsConfirmLeft.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get clientBookingsConfirmLeft;

  /// No description provided for @clientBookingsConfirmInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm window'**
  String get clientBookingsConfirmInfoTitle;

  /// No description provided for @clientBookingsConfirmInfo.
  ///
  /// In en, this message translates to:
  /// **'The date is held for you until then. You pay nothing more to Ghazal.'**
  String get clientBookingsConfirmInfo;

  /// No description provided for @clientBookingsStepPay.
  ///
  /// In en, this message translates to:
  /// **'Pay venue'**
  String get clientBookingsStepPay;

  /// No description provided for @clientBookingsStepShow.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get clientBookingsStepShow;

  /// No description provided for @clientBookingsConfirmedInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get clientBookingsConfirmedInfoTitle;

  /// No description provided for @clientBookingsConfirmedPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {venue} directly, then show this code.'**
  String clientBookingsConfirmedPay(String venue);

  /// No description provided for @clientBookingsAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get clientBookingsAddToCalendar;

  /// No description provided for @clientBookingsCalendarAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar'**
  String get clientBookingsCalendarAdded;

  /// No description provided for @clientBookingsBookVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get clientBookingsBookVisit;

  /// No description provided for @clientBookingsRedeemedOn.
  ///
  /// In en, this message translates to:
  /// **'Redeemed on'**
  String get clientBookingsRedeemedOn;

  /// No description provided for @clientBookingsRedeemedPrice.
  ///
  /// In en, this message translates to:
  /// **'Venue price applied'**
  String get clientBookingsRedeemedPrice;

  /// No description provided for @clientBookingsProposedWas.
  ///
  /// In en, this message translates to:
  /// **'Original date'**
  String get clientBookingsProposedWas;

  /// No description provided for @clientBookingsProposedReply.
  ///
  /// In en, this message translates to:
  /// **'Reply by'**
  String get clientBookingsProposedReply;

  /// No description provided for @clientBookingsDeclinedDate.
  ///
  /// In en, this message translates to:
  /// **'Date unavailable'**
  String get clientBookingsDeclinedDate;

  /// No description provided for @clientBookingsDeclinedCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity doesn’t fit'**
  String get clientBookingsDeclinedCapacity;

  /// No description provided for @clientBookingsDeclinedPackage.
  ///
  /// In en, this message translates to:
  /// **'Package unavailable'**
  String get clientBookingsDeclinedPackage;

  /// No description provided for @clientBookingsDeclinedOther.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get clientBookingsDeclinedOther;

  /// No description provided for @clientBookingsExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'No reply'**
  String get clientBookingsExpiredTitle;

  /// No description provided for @clientBookingsExpiredConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm time ended'**
  String get clientBookingsExpiredConfirmTitle;

  /// No description provided for @clientBookingsExpiredConfirm.
  ///
  /// In en, this message translates to:
  /// **'The confirmation time ran out, so the hold on {date} was released.'**
  String clientBookingsExpiredConfirm(String date);

  /// No description provided for @clientBookingsExpiredDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get clientBookingsExpiredDeadline;

  /// No description provided for @clientBookingsCancelledOn.
  ///
  /// In en, this message translates to:
  /// **'Cancelled on'**
  String get clientBookingsCancelledOn;

  /// No description provided for @clientBookingsCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'By you'**
  String get clientBookingsCancelledByYou;

  /// No description provided for @clientBookingsCancelledByVenue.
  ///
  /// In en, this message translates to:
  /// **'By the venue'**
  String get clientBookingsCancelledByVenue;

  /// No description provided for @clientBookingsIssueOpen.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get clientBookingsIssueOpen;

  /// No description provided for @clientBookingsIssueUntil.
  ///
  /// In en, this message translates to:
  /// **'Report until'**
  String get clientBookingsIssueUntil;

  /// No description provided for @clientBookingsIssueReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get clientBookingsIssueReportedTitle;

  /// No description provided for @clientBookingsIssueReportedBody.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support has your report and will follow up in your messages.'**
  String get clientBookingsIssueReportedBody;

  /// No description provided for @clientBookingsIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get clientBookingsIssueTitle;

  /// No description provided for @clientBookingsIssueFacts.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get clientBookingsIssueFacts;

  /// No description provided for @clientBookingsIssueReasonPrice.
  ///
  /// In en, this message translates to:
  /// **'Price not honoured'**
  String get clientBookingsIssueReasonPrice;

  /// No description provided for @clientBookingsIssueReasonNotRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Not redeemed'**
  String get clientBookingsIssueReasonNotRedeemed;

  /// No description provided for @clientBookingsIssueReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientBookingsIssueReasonOther;

  /// No description provided for @clientBookingsIssueNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientBookingsIssueNote;

  /// No description provided for @clientBookingsIssueSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get clientBookingsIssueSend;

  /// No description provided for @clientBookingsIssueSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get clientBookingsIssueSent;

  /// No description provided for @clientBookingsShowVoucher.
  ///
  /// In en, this message translates to:
  /// **'Show voucher'**
  String get clientBookingsShowVoucher;

  /// No description provided for @clientBookingsChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get clientBookingsChooseDate;

  /// No description provided for @clientBookingsSendSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar halls'**
  String get clientBookingsSendSimilar;

  /// No description provided for @clientBookingsSendNew.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get clientBookingsSendNew;

  /// No description provided for @clientBookingsWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get clientBookingsWriteReview;

  /// No description provided for @clientBookingsSectionAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Free halls'**
  String get clientBookingsSectionAlternatives;

  /// No description provided for @clientBookingsSectionEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get clientBookingsSectionEvent;

  /// No description provided for @clientBookingsSectionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientBookingsSectionPrice;

  /// No description provided for @clientBookingsSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientBookingsSectionContact;

  /// No description provided for @clientBookingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get clientBookingsTerms;

  /// No description provided for @clientBookingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientBookingsMessage;

  /// No description provided for @clientBookingsUsuallyReplies.
  ///
  /// In en, this message translates to:
  /// **'Usually replies in'**
  String get clientBookingsUsuallyReplies;

  /// No description provided for @clientBookingsCallDisplayOnly.
  ///
  /// In en, this message translates to:
  /// **'Opening phone'**
  String get clientBookingsCallDisplayOnly;

  /// No description provided for @clientBookingsPriceStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get clientBookingsPriceStandard;

  /// No description provided for @clientBookingsPriceSaving.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get clientBookingsPriceSaving;

  /// No description provided for @clientBookingsPricePerGuest.
  ///
  /// In en, this message translates to:
  /// **'Per guest'**
  String get clientBookingsPricePerGuest;

  /// No description provided for @clientBookingsPriceBasis.
  ///
  /// In en, this message translates to:
  /// **'Price basis'**
  String get clientBookingsPriceBasis;

  /// No description provided for @clientBookingsPriceGhazal.
  ///
  /// In en, this message translates to:
  /// **'Ghazal voucher'**
  String get clientBookingsPriceGhazal;

  /// No description provided for @clientBookingsPricePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get clientBookingsPricePaid;

  /// No description provided for @clientBookingsPriceVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue, paid directly'**
  String get clientBookingsPriceVenue;

  /// No description provided for @clientBookingsPriceSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get clientBookingsPriceSettled;

  /// No description provided for @clientBookingsPriceOffApp.
  ///
  /// In en, this message translates to:
  /// **'Off-app'**
  String get clientBookingsPriceOffApp;

  /// No description provided for @clientBookingsPriceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Price terms'**
  String get clientBookingsPriceInfoTitle;

  /// No description provided for @clientBookingsPriceInfoInclusive.
  ///
  /// In en, this message translates to:
  /// **'The venue sets this price, all-in. Ghazal adds nothing to it.'**
  String get clientBookingsPriceInfoInclusive;

  /// No description provided for @clientBookingsPriceInfoGhazal.
  ///
  /// In en, this message translates to:
  /// **'Nothing more to pay Ghazal.'**
  String get clientBookingsPriceInfoGhazal;

  /// No description provided for @clientBookingsOutcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher is back'**
  String get clientBookingsOutcomeBackTitle;

  /// No description provided for @clientBookingsOutcomeBackReusable.
  ///
  /// In en, this message translates to:
  /// **'Use it again at {venue} until {date}.'**
  String clientBookingsOutcomeBackReusable(String venue, String date);

  /// No description provided for @clientBookingsOutcomeBackCredit.
  ///
  /// In en, this message translates to:
  /// **'Use it again at {venue} until {date}, or ask support for a credit voucher.'**
  String clientBookingsOutcomeBackCredit(String venue, String date);

  /// No description provided for @clientBookingsOutcomeBackPlain.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is ready for another request.'**
  String get clientBookingsOutcomeBackPlain;

  /// No description provided for @clientBookingsOutcomeUsedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher used'**
  String get clientBookingsOutcomeUsedTitle;

  /// No description provided for @clientBookingsOutcomeUsedBody.
  ///
  /// In en, this message translates to:
  /// **'Cancelling a confirmed booking uses up the voucher. No money is returned.'**
  String get clientBookingsOutcomeUsedBody;

  /// No description provided for @clientBookingsOutcomeCreditTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit voucher issued'**
  String get clientBookingsOutcomeCreditTitle;

  /// No description provided for @clientBookingsOutcomeCreditBody.
  ///
  /// In en, this message translates to:
  /// **'A credit voucher is in your account. Claim it at any hall, hotel or service.'**
  String get clientBookingsOutcomeCreditBody;

  /// No description provided for @clientBookingsOutcomeExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher expired'**
  String get clientBookingsOutcomeExpiredTitle;

  /// No description provided for @clientBookingsOutcomeExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'The voucher passed its validity date and can no longer be used.'**
  String get clientBookingsOutcomeExpiredBody;

  /// No description provided for @clientBookingsOutcomeAction.
  ///
  /// In en, this message translates to:
  /// **'Use again'**
  String get clientBookingsOutcomeAction;

  /// No description provided for @clientBookingsOutcomeUntil.
  ///
  /// In en, this message translates to:
  /// **'Use again until'**
  String get clientBookingsOutcomeUntil;

  /// No description provided for @clientBookingsOutcomeAskSupport.
  ///
  /// In en, this message translates to:
  /// **'Ask support'**
  String get clientBookingsOutcomeAskSupport;

  /// No description provided for @clientBookingsOutcomeInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher terms'**
  String get clientBookingsOutcomeInfoTitle;

  /// No description provided for @clientBookingsTicketQr.
  ///
  /// In en, this message translates to:
  /// **'QR code of voucher {code}'**
  String clientBookingsTicketQr(String code);

  /// No description provided for @clientBookingsTicketShowFull.
  ///
  /// In en, this message translates to:
  /// **'Enlarge'**
  String get clientBookingsTicketShowFull;

  /// No description provided for @clientBookingsTicketUsedOn.
  ///
  /// In en, this message translates to:
  /// **'Used on'**
  String get clientBookingsTicketUsedOn;

  /// No description provided for @clientBookingsTicketValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get clientBookingsTicketValidUntil;

  /// No description provided for @clientBookingsCancelTitleWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get clientBookingsCancelTitleWithdraw;

  /// No description provided for @clientBookingsCancelTitleApproved.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientBookingsCancelTitleApproved;

  /// No description provided for @clientBookingsCancelTitleConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get clientBookingsCancelTitleConfirmed;

  /// No description provided for @clientBookingsCancelDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientBookingsCancelDateLabel;

  /// No description provided for @clientBookingsCancelDateReleased.
  ///
  /// In en, this message translates to:
  /// **'Date released'**
  String get clientBookingsCancelDateReleased;

  /// No description provided for @clientBookingsCancelVoucherLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientBookingsCancelVoucherLabel;

  /// No description provided for @clientBookingsCancelVoucherBack.
  ///
  /// In en, this message translates to:
  /// **'Voucher returns'**
  String get clientBookingsCancelVoucherBack;

  /// No description provided for @clientBookingsCancelVoucherUsed.
  ///
  /// In en, this message translates to:
  /// **'Voucher used'**
  String get clientBookingsCancelVoucherUsed;

  /// No description provided for @clientBookingsCancelVoucherBackBody.
  ///
  /// In en, this message translates to:
  /// **'Your voucher returns to you and can be used again at {venue} until {date}.'**
  String clientBookingsCancelVoucherBackBody(String venue, String date);

  /// No description provided for @clientBookingsCancelVoucherUsedBody.
  ///
  /// In en, this message translates to:
  /// **'Cancelling a confirmed booking uses up your voucher. No money is returned.'**
  String get clientBookingsCancelVoucherUsedBody;

  /// No description provided for @clientBookingsCancelDateWithdraw.
  ///
  /// In en, this message translates to:
  /// **'{venue} is told straight away. Nothing was held for you yet.'**
  String clientBookingsCancelDateWithdraw(String venue);

  /// No description provided for @clientBookingsCancelDateApproved.
  ///
  /// In en, this message translates to:
  /// **'The hold on {date} is released.'**
  String clientBookingsCancelDateApproved(String date);

  /// No description provided for @clientBookingsCancelDateConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The booking on {date} at {venue} is released.'**
  String clientBookingsCancelDateConfirmed(String date, String venue);

  /// No description provided for @clientBookingsCancelVenueMoney.
  ///
  /// In en, this message translates to:
  /// **'Anything you paid {venue} directly is settled between you and the venue.'**
  String clientBookingsCancelVenueMoney(String venue);

  /// No description provided for @clientBookingsCancelInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get clientBookingsCancelInfoTitle;

  /// No description provided for @clientBookingsCancelAltAction.
  ///
  /// In en, this message translates to:
  /// **'Message venue'**
  String get clientBookingsCancelAltAction;

  /// No description provided for @clientBookingsCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get clientBookingsCancelKeep;

  /// No description provided for @clientBookingsCancelKeepBooking.
  ///
  /// In en, this message translates to:
  /// **'Keep booking'**
  String get clientBookingsCancelKeepBooking;

  /// No description provided for @clientBookingsCancelReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get clientBookingsCancelReasonTitle;

  /// No description provided for @clientBookingsCancelReasonPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans changed'**
  String get clientBookingsCancelReasonPlans;

  /// No description provided for @clientBookingsCancelReasonVenue.
  ///
  /// In en, this message translates to:
  /// **'Other venue'**
  String get clientBookingsCancelReasonVenue;

  /// No description provided for @clientBookingsCancelReasonDate.
  ///
  /// In en, this message translates to:
  /// **'Date changed'**
  String get clientBookingsCancelReasonDate;

  /// No description provided for @clientBookingsCancelReasonBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get clientBookingsCancelReasonBudget;

  /// No description provided for @clientBookingsCancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientBookingsCancelReasonOther;

  /// No description provided for @clientBookingsCancelNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientBookingsCancelNote;

  /// No description provided for @clientBookingsCancelActionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get clientBookingsCancelActionWithdraw;

  /// No description provided for @clientBookingsCancelActionApproved.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientBookingsCancelActionApproved;

  /// No description provided for @clientBookingsCancelActionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get clientBookingsCancelActionConfirmed;

  /// No description provided for @clientBookingsCancelErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t cancel'**
  String get clientBookingsCancelErrorTitle;

  /// No description provided for @clientBookingsCancelErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed.'**
  String get clientBookingsCancelErrorBody;

  /// No description provided for @clientBookingsCancelDoneWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Request withdrawn'**
  String get clientBookingsCancelDoneWithdrawn;

  /// No description provided for @clientBookingsCancelDoneApproved.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get clientBookingsCancelDoneApproved;

  /// No description provided for @clientBookingsCancelDoneConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get clientBookingsCancelDoneConfirmed;

  /// No description provided for @clientBookingsProposalCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'New dates'**
  String get clientBookingsProposalCounterTitle;

  /// No description provided for @clientBookingsProposalCounterBody.
  ///
  /// In en, this message translates to:
  /// **'{venue} cannot host you on {date}. Choose one of these dates. The voucher price stays the same.'**
  String clientBookingsProposalCounterBody(String venue, String date);

  /// No description provided for @clientBookingsProposalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer details'**
  String get clientBookingsProposalInfoTitle;

  /// No description provided for @clientBookingsProposalFacts.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get clientBookingsProposalFacts;

  /// No description provided for @clientBookingsProposalDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates offered'**
  String get clientBookingsProposalDatesLabel;

  /// No description provided for @clientBookingsProposalOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'{date}, voucher price {price}'**
  String clientBookingsProposalOptionLabel(String date, String price);

  /// No description provided for @clientBookingsProposalTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get clientBookingsProposalTaken;

  /// No description provided for @clientBookingsProposalTakenBanner.
  ///
  /// In en, this message translates to:
  /// **'{date} was taken in the meantime. Choose another date or message the venue.'**
  String clientBookingsProposalTakenBanner(String date);

  /// No description provided for @clientBookingsProposalHeld.
  ///
  /// In en, this message translates to:
  /// **'The voucher price is held on every date.'**
  String get clientBookingsProposalHeld;

  /// No description provided for @clientBookingsNoPenalty.
  ///
  /// In en, this message translates to:
  /// **'No penalty if you decline. Your voucher stays yours.'**
  String get clientBookingsNoPenalty;

  /// No description provided for @clientBookingsProposalReplyBy.
  ///
  /// In en, this message translates to:
  /// **'Reply by'**
  String get clientBookingsProposalReplyBy;

  /// No description provided for @clientBookingsProposalConfirmBy.
  ///
  /// In en, this message translates to:
  /// **'Confirm by'**
  String get clientBookingsProposalConfirmBy;

  /// No description provided for @clientBookingsProposalAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept date'**
  String get clientBookingsProposalAccept;

  /// No description provided for @clientBookingsProposalDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline these dates?'**
  String get clientBookingsProposalDeclineTitle;

  /// No description provided for @clientBookingsProposalDeclineAction.
  ///
  /// In en, this message translates to:
  /// **'Decline dates'**
  String get clientBookingsProposalDeclineAction;

  /// No description provided for @clientBookingsProposalDeclineKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep choosing'**
  String get clientBookingsProposalDeclineKeep;

  /// No description provided for @clientBookingsProposalAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Date accepted'**
  String get clientBookingsProposalAcceptedTitle;

  /// No description provided for @clientBookingsProposalClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request closed'**
  String get clientBookingsProposalClosedTitle;

  /// No description provided for @clientBookingsProposalExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer lapsed'**
  String get clientBookingsProposalExpiredTitle;

  /// No description provided for @clientBookingsLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get clientBookingsLater;

  /// No description provided for @clientBookingsReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get clientBookingsReceiptsTitle;

  /// No description provided for @clientBookingsReceiptsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Event payments'**
  String get clientBookingsReceiptsInfoTitle;

  /// No description provided for @clientBookingsReceiptsNote.
  ///
  /// In en, this message translates to:
  /// **'Event payments are between you and the venue and do not appear here.'**
  String get clientBookingsReceiptsNote;

  /// No description provided for @clientBookingsReceiptsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No receipts'**
  String get clientBookingsReceiptsEmptyTitle;

  /// No description provided for @clientBookingsReceiptsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get clientBookingsReceiptsReceipt;

  /// No description provided for @clientBookingsReceiptsCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit voucher'**
  String get clientBookingsReceiptsCredit;

  /// No description provided for @clientBookingsReceiptsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to phone'**
  String get clientBookingsReceiptsSaved;

  /// No description provided for @clientBookingsMethodKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get clientBookingsMethodKnet;

  /// No description provided for @clientBookingsMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get clientBookingsMethodApplePay;

  /// No description provided for @clientBookingsMethodGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get clientBookingsMethodGooglePay;

  /// No description provided for @clientBookingsMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get clientBookingsMethodCard;

  /// No description provided for @clientBookingsViewerPreview.
  ///
  /// In en, this message translates to:
  /// **'Document preview in Arabic and English'**
  String get clientBookingsViewerPreview;

  /// No description provided for @clientBookingsViewerDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get clientBookingsViewerDownload;

  /// No description provided for @clientBookingsViewerDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get clientBookingsViewerDownloaded;

  /// No description provided for @clientBookingsViewerSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved to phone'**
  String get clientBookingsViewerSavedAt;

  /// No description provided for @clientBookingsViewerShareToast.
  ///
  /// In en, this message translates to:
  /// **'Pick an app'**
  String get clientBookingsViewerShareToast;

  /// No description provided for @clientBookingsViewerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get clientBookingsViewerOpen;

  /// No description provided for @clientBookingsViewerOpenToast.
  ///
  /// In en, this message translates to:
  /// **'Opening app'**
  String get clientBookingsViewerOpenToast;

  /// No description provided for @clientBookingsViewerOpenVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientBookingsViewerOpenVoucher;

  /// No description provided for @clientBookingsOutcomeForfeitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher not valid'**
  String get clientBookingsOutcomeForfeitedTitle;

  /// No description provided for @clientBookingsOutcomeForfeitedBody.
  ///
  /// In en, this message translates to:
  /// **'It was not confirmed at {venue} within {hours} hours, so it is forfeited. No money is returned.'**
  String clientBookingsOutcomeForfeitedBody(String venue, num hours);

  /// No description provided for @clientDiscoverHeroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your evening hall'**
  String get clientDiscoverHeroHeadline;

  /// No description provided for @clientDiscoverBellUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Notifications} one{Notifications, {count} unread} other{Notifications, {count} unread}}'**
  String clientDiscoverBellUnread(int count);

  /// No description provided for @clientDiscoverSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get clientDiscoverSwitchLabel;

  /// No description provided for @clientDiscoverVariantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Status cards'**
  String get clientDiscoverVariantsTitle;

  /// No description provided for @clientDiscoverCategoryLuxuryHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get clientDiscoverCategoryLuxuryHotels;

  /// No description provided for @clientDiscoverCategoryWeddingHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get clientDiscoverCategoryWeddingHalls;

  /// No description provided for @clientDiscoverCategoryGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get clientDiscoverCategoryGovernment;

  /// No description provided for @clientDiscoverCategoryBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get clientDiscoverCategoryBeach;

  /// No description provided for @clientDiscoverCategoryOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get clientDiscoverCategoryOutdoor;

  /// No description provided for @clientDiscoverCategoryVip.
  ///
  /// In en, this message translates to:
  /// **'VIP'**
  String get clientDiscoverCategoryVip;

  /// No description provided for @clientDiscoverBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get clientDiscoverBrowseTitle;

  /// No description provided for @clientDiscoverFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free {date}'**
  String clientDiscoverFreeTitle(String date);

  /// No description provided for @clientDiscoverShortlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientDiscoverShortlistTitle;

  /// No description provided for @clientDiscoverShortlistCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get clientDiscoverShortlistCompare;

  /// No description provided for @clientDiscoverFeaturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get clientDiscoverFeaturedTitle;

  /// No description provided for @clientDiscoverRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get clientDiscoverRecommendedTitle;

  /// No description provided for @clientDiscoverTrendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get clientDiscoverTrendingTitle;

  /// No description provided for @clientDiscoverNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get clientDiscoverNearbyTitle;

  /// No description provided for @clientDiscoverEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get clientDiscoverEmptyTitle;

  /// No description provided for @clientDiscoverEmptyWiden.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get clientDiscoverEmptyWiden;

  /// No description provided for @clientDiscoverLocateDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Use location?'**
  String get clientDiscoverLocateDialogTitle;

  /// No description provided for @clientDiscoverLocateAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get clientDiscoverLocateAllow;

  /// No description provided for @clientDiscoverLocateNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get clientDiscoverLocateNotNow;

  /// No description provided for @clientDiscoverEmptyNearLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearest free dates'**
  String get clientDiscoverEmptyNearLabel;

  /// No description provided for @clientDiscoverEmptyDateSet.
  ///
  /// In en, this message translates to:
  /// **'Date updated'**
  String get clientDiscoverEmptyDateSet;

  /// No description provided for @clientDiscoverBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'All halls'**
  String get clientDiscoverBrowseAll;

  /// No description provided for @clientDiscoverBriefLabel.
  ///
  /// In en, this message translates to:
  /// **'Your brief'**
  String get clientDiscoverBriefLabel;

  /// No description provided for @clientDiscoverBriefChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientDiscoverBriefChooseDate;

  /// No description provided for @clientDiscoverBriefChooseArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get clientDiscoverBriefChooseArea;

  /// No description provided for @clientDiscoverBriefAddGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientDiscoverBriefAddGuests;

  /// No description provided for @clientDiscoverBriefSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get clientDiscoverBriefSetBudget;

  /// No description provided for @clientDiscoverBriefAreaMore.
  ///
  /// In en, this message translates to:
  /// **'{first} +{more}'**
  String clientDiscoverBriefAreaMore(String first, String more);

  /// No description provided for @clientDiscoverCtaCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Show {count} hall} other{Show {count} halls}}'**
  String clientDiscoverCtaCount(int count);

  /// No description provided for @clientDiscoverCtaShow.
  ///
  /// In en, this message translates to:
  /// **'Show halls'**
  String get clientDiscoverCtaShow;

  /// No description provided for @clientDiscoverCtaNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest dates'**
  String get clientDiscoverCtaNearest;

  /// No description provided for @clientDiscoverResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get clientDiscoverResultsTitle;

  /// No description provided for @clientDiscoverResultsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Hall or area'**
  String get clientDiscoverResultsSearchPlaceholder;

  /// No description provided for @clientDiscoverResultsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientDiscoverResultsFilters;

  /// No description provided for @clientDiscoverResultsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverResultsClearAll;

  /// No description provided for @clientDiscoverResultsRemoveChip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String clientDiscoverResultsRemoveChip(String name);

  /// No description provided for @clientDiscoverResultsMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get clientDiscoverResultsMap;

  /// No description provided for @clientDiscoverResultsList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get clientDiscoverResultsList;

  /// No description provided for @clientDiscoverResultsBriefHint.
  ///
  /// In en, this message translates to:
  /// **'Edit brief'**
  String get clientDiscoverResultsBriefHint;

  /// No description provided for @clientDiscoverResultsSeeFreeDates.
  ///
  /// In en, this message translates to:
  /// **'Free dates'**
  String get clientDiscoverResultsSeeFreeDates;

  /// No description provided for @clientDiscoverResultsGovernmentNote.
  ///
  /// In en, this message translates to:
  /// **'Browse only. Book through the official channel. No voucher.'**
  String get clientDiscoverResultsGovernmentNote;

  /// No description provided for @clientDiscoverResultsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Halls updated'**
  String get clientDiscoverResultsRefreshed;

  /// No description provided for @clientDiscoverResultsNoneRelax.
  ///
  /// In en, this message translates to:
  /// **'Remove {filter}'**
  String clientDiscoverResultsNoneRelax(String filter);

  /// No description provided for @clientDiscoverResultsNoneDates.
  ///
  /// In en, this message translates to:
  /// **'Nearest free dates'**
  String get clientDiscoverResultsNoneDates;

  /// No description provided for @clientDiscoverResultsOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Map needs a connection. List still works.'**
  String get clientDiscoverResultsOfflineMap;

  /// No description provided for @clientDiscoverSearchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get clientDiscoverSearchRecent;

  /// No description provided for @clientDiscoverSearchClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverSearchClearRecent;

  /// No description provided for @clientDiscoverSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get clientDiscoverSortTitle;

  /// No description provided for @clientDiscoverSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get clientDiscoverSortRecommended;

  /// No description provided for @clientDiscoverSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientDiscoverSortRating;

  /// No description provided for @clientDiscoverSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get clientDiscoverSortNewest;

  /// No description provided for @clientDiscoverSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price'**
  String get clientDiscoverSortPrice;

  /// No description provided for @clientDiscoverSortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Highest price'**
  String get clientDiscoverSortPriceDesc;

  /// No description provided for @clientDiscoverSortDistance.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get clientDiscoverSortDistance;

  /// No description provided for @clientDiscoverChipAreasAll.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get clientDiscoverChipAreasAll;

  /// No description provided for @clientDiscoverChipRating.
  ///
  /// In en, this message translates to:
  /// **'{rating}+'**
  String clientDiscoverChipRating(String rating);

  /// No description provided for @clientDiscoverArrangementWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get clientDiscoverArrangementWomen;

  /// No description provided for @clientDiscoverArrangementMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get clientDiscoverArrangementMen;

  /// No description provided for @clientDiscoverArrangementMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get clientDiscoverArrangementMixed;

  /// No description provided for @clientDiscoverSettingIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get clientDiscoverSettingIndoor;

  /// No description provided for @clientDiscoverSettingOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get clientDiscoverSettingOutdoor;

  /// No description provided for @clientDiscoverSettingMixed.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get clientDiscoverSettingMixed;

  /// No description provided for @clientDiscoverFacilityParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get clientDiscoverFacilityParking;

  /// No description provided for @clientDiscoverFacilityValet.
  ///
  /// In en, this message translates to:
  /// **'Valet'**
  String get clientDiscoverFacilityValet;

  /// No description provided for @clientDiscoverFacilityBridal.
  ///
  /// In en, this message translates to:
  /// **'Bridal'**
  String get clientDiscoverFacilityBridal;

  /// No description provided for @clientDiscoverFacilityBuffet.
  ///
  /// In en, this message translates to:
  /// **'Buffet'**
  String get clientDiscoverFacilityBuffet;

  /// No description provided for @clientDiscoverFacilityDecor.
  ///
  /// In en, this message translates to:
  /// **'Decor'**
  String get clientDiscoverFacilityDecor;

  /// No description provided for @clientDiscoverFacilityPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientDiscoverFacilityPhotography;

  /// No description provided for @clientDiscoverLevelPrestige.
  ///
  /// In en, this message translates to:
  /// **'Prestige'**
  String get clientDiscoverLevelPrestige;

  /// No description provided for @clientDiscoverLevelSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get clientDiscoverLevelSignature;

  /// No description provided for @clientDiscoverLevelClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get clientDiscoverLevelClassic;

  /// No description provided for @clientDiscoverLevelGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get clientDiscoverLevelGovernment;

  /// No description provided for @clientDiscoverFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientDiscoverFiltersTitle;

  /// No description provided for @clientDiscoverFiltersGroupArrangement.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get clientDiscoverFiltersGroupArrangement;

  /// No description provided for @clientDiscoverFiltersGroupType.
  ///
  /// In en, this message translates to:
  /// **'Venue type'**
  String get clientDiscoverFiltersGroupType;

  /// No description provided for @clientDiscoverFiltersGroupPrice.
  ///
  /// In en, this message translates to:
  /// **'Standard price'**
  String get clientDiscoverFiltersGroupPrice;

  /// No description provided for @clientDiscoverFiltersGroupCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get clientDiscoverFiltersGroupCapacity;

  /// No description provided for @clientDiscoverFiltersGroupSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get clientDiscoverFiltersGroupSetting;

  /// No description provided for @clientDiscoverFiltersGroupFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get clientDiscoverFiltersGroupFacilities;

  /// No description provided for @clientDiscoverFiltersGroupRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientDiscoverFiltersGroupRating;

  /// No description provided for @clientDiscoverFiltersGroupLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get clientDiscoverFiltersGroupLevel;

  /// No description provided for @clientDiscoverFiltersGroupBrand.
  ///
  /// In en, this message translates to:
  /// **'Hotel brand'**
  String get clientDiscoverFiltersGroupBrand;

  /// No description provided for @clientDiscoverFiltersCta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Show {count} hall} other{Show {count} halls}}'**
  String clientDiscoverFiltersCta(int count);

  /// No description provided for @clientDiscoverFiltersCtaNone.
  ///
  /// In en, this message translates to:
  /// **'No halls'**
  String get clientDiscoverFiltersCtaNone;

  /// No description provided for @clientDiscoverFiltersClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverFiltersClear;

  /// No description provided for @clientDiscoverFiltersExpand.
  ///
  /// In en, this message translates to:
  /// **'Show {group}'**
  String clientDiscoverFiltersExpand(String group);

  /// No description provided for @clientDiscoverFiltersCollapse.
  ///
  /// In en, this message translates to:
  /// **'Hide {group}'**
  String clientDiscoverFiltersCollapse(String group);

  /// No description provided for @clientDiscoverBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Your brief'**
  String get clientDiscoverBriefTitle;

  /// No description provided for @clientDiscoverBriefClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverBriefClear;

  /// No description provided for @clientDiscoverBriefBack.
  ///
  /// In en, this message translates to:
  /// **'Back to your brief'**
  String get clientDiscoverBriefBack;

  /// No description provided for @clientDiscoverBriefDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientDiscoverBriefDateTitle;

  /// No description provided for @clientDiscoverBriefDateFlexible.
  ///
  /// In en, this message translates to:
  /// **'Any month'**
  String get clientDiscoverBriefDateFlexible;

  /// No description provided for @clientDiscoverBriefAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get clientDiscoverBriefAreaTitle;

  /// No description provided for @clientDiscoverBriefGuestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientDiscoverBriefGuestsTitle;

  /// No description provided for @clientDiscoverBriefGuestsPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick choices'**
  String get clientDiscoverBriefGuestsPresets;

  /// No description provided for @clientDiscoverBriefGuestsSection.
  ///
  /// In en, this message translates to:
  /// **'Searching for'**
  String get clientDiscoverBriefGuestsSection;

  /// No description provided for @clientDiscoverBriefBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get clientDiscoverBriefBudgetTitle;

  /// No description provided for @clientDiscoverBriefBudgetHelper.
  ///
  /// In en, this message translates to:
  /// **'Hall and catering only'**
  String get clientDiscoverBriefBudgetHelper;

  /// No description provided for @clientDiscoverBriefBudgetBands.
  ///
  /// In en, this message translates to:
  /// **'Budget bands'**
  String get clientDiscoverBriefBudgetBands;

  /// No description provided for @clientDiscoverBriefBudgetUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {amount}'**
  String clientDiscoverBriefBudgetUnder(String amount);

  /// No description provided for @clientDiscoverBriefDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get clientDiscoverBriefDone;

  /// No description provided for @clientDiscoverMergeTitle.
  ///
  /// In en, this message translates to:
  /// **'Two briefs'**
  String get clientDiscoverMergeTitle;

  /// No description provided for @clientDiscoverMergePhone.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get clientDiscoverMergePhone;

  /// No description provided for @clientDiscoverMergeAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get clientDiscoverMergeAccount;

  /// No description provided for @clientDiscoverMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get clientDiscoverMapTitle;

  /// No description provided for @clientDiscoverMapPins.
  ///
  /// In en, this message translates to:
  /// **'Halls on the map'**
  String get clientDiscoverMapPins;

  /// No description provided for @clientDiscoverMapCluster.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hall here, tap to zoom in} other{{count} halls here, tap to zoom in}}'**
  String clientDiscoverMapCluster(int count);

  /// No description provided for @clientDiscoverMapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Show all halls'**
  String get clientDiscoverMapZoomOut;

  /// No description provided for @clientDiscoverMapLocate.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get clientDiscoverMapLocate;

  /// No description provided for @clientDiscoverMapSearchArea.
  ///
  /// In en, this message translates to:
  /// **'Search here'**
  String get clientDiscoverMapSearchArea;

  /// No description provided for @clientDiscoverMapDenied.
  ///
  /// In en, this message translates to:
  /// **'Near {area}'**
  String clientDiscoverMapDenied(String area);

  /// No description provided for @clientDiscoverMapLocated.
  ///
  /// In en, this message translates to:
  /// **'Near you'**
  String get clientDiscoverMapLocated;

  /// No description provided for @clientDiscoverMapNoneAction.
  ///
  /// In en, this message translates to:
  /// **'All halls'**
  String get clientDiscoverMapNoneAction;

  /// No description provided for @clientDiscoverMapOfflineAction.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get clientDiscoverMapOfflineAction;

  /// No description provided for @clientDiscoverMapViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Show as'**
  String get clientDiscoverMapViewLabel;

  /// No description provided for @clientDiscoverRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get clientDiscoverRefreshed;

  /// No description provided for @clientDiscoverVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices'**
  String get clientDiscoverVoucherTitle;

  /// No description provided for @clientDiscoverWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get clientDiscoverWeekTitle;

  /// No description provided for @clientDiscoverCardGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Get voucher'**
  String get clientDiscoverCardGetVoucher;

  /// No description provided for @clientDiscoverCardView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientDiscoverCardView;

  /// No description provided for @clientDiscoverChipRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get clientDiscoverChipRegion;

  /// No description provided for @clientDiscoverChipDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientDiscoverChipDate;

  /// No description provided for @clientDiscoverChipVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientDiscoverChipVoucher;

  /// No description provided for @clientDiscoverSortVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientDiscoverSortVoucher;

  /// No description provided for @clientDiscoverMapVoucherPin.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientDiscoverMapVoucherPin;

  /// No description provided for @clientDiscoverFiltersGroupRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get clientDiscoverFiltersGroupRegion;

  /// No description provided for @clientDiscoverFiltersGroupStructure.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get clientDiscoverFiltersGroupStructure;

  /// No description provided for @clientDiscoverFiltersGroupDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientDiscoverFiltersGroupDate;

  /// No description provided for @clientDiscoverFiltersGroupVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientDiscoverFiltersGroupVoucher;

  /// No description provided for @clientDiscoverFiltersDateOpen.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get clientDiscoverFiltersDateOpen;

  /// No description provided for @clientDiscoverFiltersVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher only'**
  String get clientDiscoverFiltersVoucherTitle;

  /// No description provided for @clientDiscoverBriefAreaAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientDiscoverBriefAreaAll;

  /// No description provided for @clientDiscoverBriefAreaClearGroup.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverBriefAreaClearGroup;

  /// No description provided for @clientDiscoverRegionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Area or hall'**
  String get clientDiscoverRegionPlaceholder;

  /// No description provided for @clientDiscoverRegionNear.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get clientDiscoverRegionNear;

  /// No description provided for @clientDiscoverRegionListLabel.
  ///
  /// In en, this message translates to:
  /// **'Governorates and areas'**
  String get clientDiscoverRegionListLabel;

  /// No description provided for @clientDiscoverDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get clientDiscoverDatesTitle;

  /// No description provided for @clientDiscoverDatesFlexible.
  ///
  /// In en, this message translates to:
  /// **'Any month'**
  String get clientDiscoverDatesFlexible;

  /// No description provided for @clientDiscoverDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {days, plural, one{{days} day} other{{days} days}}'**
  String clientDiscoverDatesHint(int days);

  /// No description provided for @clientDiscoverDatesLegend.
  ///
  /// In en, this message translates to:
  /// **'Halls free on each day'**
  String get clientDiscoverDatesLegend;

  /// No description provided for @clientDiscoverDatesMany.
  ///
  /// In en, this message translates to:
  /// **'Many'**
  String get clientDiscoverDatesMany;

  /// No description provided for @clientDiscoverDatesFew.
  ///
  /// In en, this message translates to:
  /// **'Few'**
  String get clientDiscoverDatesFew;

  /// No description provided for @clientDiscoverDatesNoneLegend.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get clientDiscoverDatesNoneLegend;

  /// No description provided for @clientDiscoverDatesNone.
  ///
  /// In en, this message translates to:
  /// **'No halls'**
  String get clientDiscoverDatesNone;

  /// No description provided for @clientDiscoverDatesApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get clientDiscoverDatesApply;

  /// No description provided for @clientDiscoverDatesClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clientDiscoverDatesClear;

  /// No description provided for @clientDiscoverStatusNoDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get clientDiscoverStatusNoDate;

  /// No description provided for @clientDiscoverStatusBrief.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No halls free} one{{count} hall free} other{{count} halls free}}'**
  String clientDiscoverStatusBrief(int count);

  /// No description provided for @clientDiscoverA11yDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientDiscoverA11yDate;

  /// No description provided for @clientDiscoverA11yTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clientDiscoverA11yTime;

  /// No description provided for @clientDiscoverA11yTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get clientDiscoverA11yTimeLeft;

  /// No description provided for @clientDiscoverA11yUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get clientDiscoverA11yUpdated;

  /// No description provided for @clientDiscoverA11yDrive.
  ///
  /// In en, this message translates to:
  /// **'Drive time'**
  String get clientDiscoverA11yDrive;

  /// No description provided for @clientDiscoverMergeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get clientDiscoverMergeKeep;

  /// No description provided for @clientDiscoverA11yDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get clientDiscoverA11yDaysLeft;

  /// No description provided for @clientDiscoverMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String clientDiscoverMinutes(String minutes);

  /// No description provided for @clientDiscoverFiltersVoucherCount.
  ///
  /// In en, this message translates to:
  /// **'Voucher venues'**
  String get clientDiscoverFiltersVoucherCount;

  /// No description provided for @clientDiscoverKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String clientDiscoverKm(num km);

  /// No description provided for @clientDiscoverA11yDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get clientDiscoverA11yDistance;

  /// No description provided for @clientDiscoverBriefBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} and above'**
  String clientDiscoverBriefBudgetOver(String amount);

  /// No description provided for @clientMessagesInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get clientMessagesInboxTitle;

  /// No description provided for @clientMessagesBellUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Notifications} one{Notifications, {count} unread} other{Notifications, {count} unread}}'**
  String clientMessagesBellUnread(int count);

  /// No description provided for @clientMessagesFilterGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter conversations'**
  String get clientMessagesFilterGroup;

  /// No description provided for @clientMessagesFilterVenues.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get clientMessagesFilterVenues;

  /// No description provided for @clientMessagesFilterVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get clientMessagesFilterVisits;

  /// No description provided for @clientMessagesFilterPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get clientMessagesFilterPlanner;

  /// No description provided for @clientMessagesFilterProviders.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get clientMessagesFilterProviders;

  /// No description provided for @clientMessagesFilterSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientMessagesFilterSupport;

  /// No description provided for @clientMessagesPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get clientMessagesPinned;

  /// No description provided for @clientMessagesYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get clientMessagesYou;

  /// No description provided for @clientMessagesPreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get clientMessagesPreviewVoice;

  /// No description provided for @clientMessagesPreviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get clientMessagesPreviewPhoto;

  /// No description provided for @clientMessagesPreviewDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get clientMessagesPreviewDocument;

  /// No description provided for @clientMessagesUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread messages} one{{count} unread message} other{{count} unread messages}}'**
  String clientMessagesUnreadCount(int count);

  /// No description provided for @clientMessagesOfflineStamp.
  ///
  /// In en, this message translates to:
  /// **'Offline · {time}'**
  String clientMessagesOfflineStamp(String time);

  /// No description provided for @clientMessagesDayMonth.
  ///
  /// In en, this message translates to:
  /// **'{day} {month}'**
  String clientMessagesDayMonth(String day, String month);

  /// No description provided for @clientMessagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get clientMessagesEmptyTitle;

  /// No description provided for @clientMessagesEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientMessagesEmptyAction;

  /// No description provided for @clientMessagesEmptySupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientMessagesEmptySupport;

  /// No description provided for @clientMessagesGuestLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your messages'**
  String get clientMessagesGuestLabel;

  /// No description provided for @clientMessagesGuestAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientMessagesGuestAction;

  /// No description provided for @clientMessagesVisitMembers.
  ///
  /// In en, this message translates to:
  /// **'Chat members'**
  String get clientMessagesVisitMembers;

  /// No description provided for @clientMessagesInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get clientMessagesInfoTitle;

  /// No description provided for @clientMessagesRepliesWithin.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, one{Usually replies within an hour} other{Usually replies within {hours} hours}}'**
  String clientMessagesRepliesWithin(int hours);

  /// No description provided for @clientMessagesContextView.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientMessagesContextView;

  /// No description provided for @clientMessagesContextConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientMessagesContextConfirm;

  /// No description provided for @clientMessagesFactDate.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get clientMessagesFactDate;

  /// No description provided for @clientMessagesFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientMessagesFactGuests;

  /// No description provided for @clientMessagesFactTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time to confirm'**
  String get clientMessagesFactTimeLeft;

  /// No description provided for @clientMessagesFactDue.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get clientMessagesFactDue;

  /// No description provided for @clientMessagesFactMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get clientMessagesFactMeeting;

  /// No description provided for @clientMessagesFactDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days to the wedding'**
  String get clientMessagesFactDaysLeft;

  /// No description provided for @clientMessagesAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get clientMessagesAudienceWomen;

  /// No description provided for @clientMessagesAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get clientMessagesAudienceMen;

  /// No description provided for @clientMessagesAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed reception'**
  String get clientMessagesAudienceMixed;

  /// No description provided for @clientMessagesComposerPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientMessagesComposerPlaceholder;

  /// No description provided for @clientMessagesComposerLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientMessagesComposerLabel;

  /// No description provided for @clientMessagesAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get clientMessagesAttach;

  /// No description provided for @clientMessagesRecordHold.
  ///
  /// In en, this message translates to:
  /// **'Hold to record a voice message'**
  String get clientMessagesRecordHold;

  /// No description provided for @clientMessagesRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording a voice message'**
  String get clientMessagesRecording;

  /// No description provided for @clientMessagesSlideCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientMessagesSlideCancel;

  /// No description provided for @clientMessagesReleaseCancel.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get clientMessagesReleaseCancel;

  /// No description provided for @clientMessagesRecordDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get clientMessagesRecordDelete;

  /// No description provided for @clientMessagesRecordSend.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get clientMessagesRecordSend;

  /// No description provided for @clientMessagesRecordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get clientMessagesRecordTooShort;

  /// No description provided for @clientMessagesMsgSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get clientMessagesMsgSending;

  /// No description provided for @clientMessagesMsgFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get clientMessagesMsgFailed;

  /// No description provided for @clientMessagesMsgQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get clientMessagesMsgQueued;

  /// No description provided for @clientMessagesUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get clientMessagesUploading;

  /// No description provided for @clientMessagesUploadCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel upload'**
  String get clientMessagesUploadCancel;

  /// No description provided for @clientMessagesOfflineQueue.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get clientMessagesOfflineQueue;

  /// No description provided for @clientMessagesSuggestAvailability.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get clientMessagesSuggestAvailability;

  /// No description provided for @clientMessagesSuggestVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get clientMessagesSuggestVisit;

  /// No description provided for @clientMessagesSuggestVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientMessagesSuggestVoucher;

  /// No description provided for @clientMessagesSuggestAvailabilityText.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you. Is {date} available for a ladies’ reception?'**
  String clientMessagesSuggestAvailabilityText(String date);

  /// No description provided for @clientMessagesSuggestAvailabilityAny.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you. Which dates do you have available for a ladies’ reception?'**
  String get clientMessagesSuggestAvailabilityAny;

  /// No description provided for @clientMessagesSuggestVoucherText.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you. What is the voucher price for the ladies’ reception on {date}?'**
  String clientMessagesSuggestVoucherText(String date);

  /// No description provided for @clientMessagesSuggestVoucherAny.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you. Could you tell us the voucher price for the ladies’ reception?'**
  String get clientMessagesSuggestVoucherAny;

  /// No description provided for @clientMessagesSupportIntro.
  ///
  /// In en, this message translates to:
  /// **'Hello, how can we help?'**
  String get clientMessagesSupportIntro;

  /// No description provided for @clientMessagesBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get clientMessagesBlockedNote;

  /// No description provided for @clientMessagesUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get clientMessagesUnblock;

  /// No description provided for @clientMessagesUnblockedToast.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get clientMessagesUnblockedToast;

  /// No description provided for @clientMessagesSysRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientMessagesSysRequestSent;

  /// No description provided for @clientMessagesSysApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clientMessagesSysApproved;

  /// No description provided for @clientMessagesSysConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get clientMessagesSysConfirmed;

  /// No description provided for @clientMessagesSysRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Voucher redeemed'**
  String get clientMessagesSysRedeemed;

  /// No description provided for @clientMessagesSysNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get clientMessagesSysNotAccepted;

  /// No description provided for @clientMessagesSysExpired.
  ///
  /// In en, this message translates to:
  /// **'No reply'**
  String get clientMessagesSysExpired;

  /// No description provided for @clientMessagesSysLapsed.
  ///
  /// In en, this message translates to:
  /// **'Time ran out'**
  String get clientMessagesSysLapsed;

  /// No description provided for @clientMessagesSysCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clientMessagesSysCancelled;

  /// No description provided for @clientMessagesSysInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientMessagesSysInfoTitle;

  /// No description provided for @clientMessagesSysInfoKept.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is still yours.'**
  String get clientMessagesSysInfoKept;

  /// No description provided for @clientMessagesSysInfoPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {venue} directly and show your voucher code.'**
  String clientMessagesSysInfoPay(String venue);

  /// No description provided for @clientMessagesOpenPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos in this conversation'**
  String get clientMessagesOpenPhoto;

  /// No description provided for @clientMessagesPhotoViewer.
  ///
  /// In en, this message translates to:
  /// **'Photo viewer'**
  String get clientMessagesPhotoViewer;

  /// No description provided for @clientMessagesStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get clientMessagesStatusDelivered;

  /// No description provided for @clientMessagesStatusRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get clientMessagesStatusRead;

  /// No description provided for @clientMessagesCardCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get clientMessagesCardCalendar;

  /// No description provided for @clientMessagesCardCalendarToast.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get clientMessagesCardCalendarToast;

  /// No description provided for @clientMessagesCardChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get clientMessagesCardChange;

  /// No description provided for @clientMessagesCardVendor.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get clientMessagesCardVendor;

  /// No description provided for @clientMessagesAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get clientMessagesAttachTitle;

  /// No description provided for @clientMessagesAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get clientMessagesAttachCamera;

  /// No description provided for @clientMessagesAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientMessagesAttachPhoto;

  /// No description provided for @clientMessagesAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get clientMessagesAttachDocument;

  /// No description provided for @clientMessagesAttachRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent photos'**
  String get clientMessagesAttachRecent;

  /// No description provided for @clientMessagesAttachLimits.
  ///
  /// In en, this message translates to:
  /// **'Photos up to {photo}, videos up to {video}. Chat media stays private between you and the other side.'**
  String clientMessagesAttachLimits(String photo, String video);

  /// No description provided for @clientMessagesAttachLimitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Limits'**
  String get clientMessagesAttachLimitsTitle;

  /// No description provided for @clientMessagesUnitMb.
  ///
  /// In en, this message translates to:
  /// **'{n} MB'**
  String clientMessagesUnitMb(num n);

  /// No description provided for @clientMessagesUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No seconds} one{{n} second} other{{n} seconds}}'**
  String clientMessagesUnitSeconds(int n);

  /// No description provided for @clientMessagesUnitKb.
  ///
  /// In en, this message translates to:
  /// **'{n} KB'**
  String clientMessagesUnitKb(num n);

  /// No description provided for @clientMessagesDocPreview.
  ///
  /// In en, this message translates to:
  /// **'Document preview'**
  String get clientMessagesDocPreview;

  /// No description provided for @clientMessagesDocQuotation.
  ///
  /// In en, this message translates to:
  /// **'Quotation'**
  String get clientMessagesDocQuotation;

  /// No description provided for @clientMessagesDocEvent.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get clientMessagesDocEvent;

  /// No description provided for @clientMessagesDocHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientMessagesDocHall;

  /// No description provided for @clientMessagesDocGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientMessagesDocGuests;

  /// No description provided for @clientMessagesDocPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientMessagesDocPackage;

  /// No description provided for @clientMessagesDocFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get clientMessagesDocFileSize;

  /// No description provided for @clientMessagesDocStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get clientMessagesDocStandard;

  /// No description provided for @clientMessagesDocVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientMessagesDocVoucher;

  /// No description provided for @clientMessagesDocSaving.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientMessagesDocSaving;

  /// No description provided for @clientMessagesDocDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get clientMessagesDocDownload;

  /// No description provided for @clientMessagesDocSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientMessagesDocSaved;

  /// No description provided for @clientMessagesDocOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String clientMessagesDocOpen(String name);

  /// No description provided for @clientMessagesInfoBooking.
  ///
  /// In en, this message translates to:
  /// **'Linked request'**
  String get clientMessagesInfoBooking;

  /// No description provided for @clientMessagesInfoShared.
  ///
  /// In en, this message translates to:
  /// **'Photos and documents'**
  String get clientMessagesInfoShared;

  /// No description provided for @clientMessagesInfoMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get clientMessagesInfoMute;

  /// No description provided for @clientMessagesInfoMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get clientMessagesInfoMuted;

  /// No description provided for @clientMessagesInfoUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Unmuted'**
  String get clientMessagesInfoUnmuted;

  /// No description provided for @clientMessagesInfoCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get clientMessagesInfoCall;

  /// No description provided for @clientMessagesInfoReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get clientMessagesInfoReport;

  /// No description provided for @clientMessagesInfoBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get clientMessagesInfoBlock;

  /// No description provided for @clientMessagesInfoMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clientMessagesInfoMembers;

  /// No description provided for @clientMessagesInfoMembersNote.
  ///
  /// In en, this message translates to:
  /// **'Only these three people are in this chat. Phone numbers are not shared.'**
  String get clientMessagesInfoMembersNote;

  /// No description provided for @clientMessagesInfoVisit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get clientMessagesInfoVisit;

  /// No description provided for @clientMessagesInfoVisitNote.
  ///
  /// In en, this message translates to:
  /// **'Ghazal support is part of this chat, so it cannot be blocked. To stop it, cancel the visit.'**
  String get clientMessagesInfoVisitNote;

  /// No description provided for @clientMessagesInfoSupportNote.
  ///
  /// In en, this message translates to:
  /// **'Support conversations cannot be blocked.'**
  String get clientMessagesInfoSupportNote;

  /// No description provided for @clientMessagesInfoPrivate.
  ///
  /// In en, this message translates to:
  /// **'Chat media is private between you and the other side.'**
  String get clientMessagesInfoPrivate;

  /// No description provided for @clientMessagesInfoPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get clientMessagesInfoPrivateTitle;

  /// No description provided for @clientMessagesInfoNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection'**
  String get clientMessagesInfoNeedsConnection;

  /// No description provided for @clientMessagesInfoErrorReport.
  ///
  /// In en, this message translates to:
  /// **'Could not send'**
  String get clientMessagesInfoErrorReport;

  /// No description provided for @clientMessagesReportPick.
  ///
  /// In en, this message translates to:
  /// **'Select message'**
  String get clientMessagesReportPick;

  /// No description provided for @clientMessagesReportReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get clientMessagesReportReasonTitle;

  /// No description provided for @clientMessagesReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get clientMessagesReasonSpam;

  /// No description provided for @clientMessagesReasonAbusive.
  ///
  /// In en, this message translates to:
  /// **'Abusive'**
  String get clientMessagesReasonAbusive;

  /// No description provided for @clientMessagesReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get clientMessagesReasonInappropriate;

  /// No description provided for @clientMessagesReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientMessagesReasonOther;

  /// No description provided for @clientMessagesReportNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientMessagesReportNote;

  /// No description provided for @clientMessagesReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get clientMessagesReportSubmit;

  /// No description provided for @clientMessagesReportDone.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get clientMessagesReportDone;

  /// No description provided for @clientMessagesReportDoneDetail.
  ///
  /// In en, this message translates to:
  /// **'The message stays in your conversation. Our team will take a look and act if it breaks our rules.'**
  String get clientMessagesReportDoneDetail;

  /// No description provided for @clientMessagesReportNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get clientMessagesReportNoMessages;

  /// No description provided for @clientMessagesReportNeedMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a message'**
  String get clientMessagesReportNeedMessage;

  /// No description provided for @clientMessagesReportNeedReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get clientMessagesReportNeedReason;

  /// No description provided for @clientMessagesBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block chat?'**
  String get clientMessagesBlockTitle;

  /// No description provided for @clientMessagesBlockBodyBooking.
  ///
  /// In en, this message translates to:
  /// **'Updates still arrive. Call {phone}'**
  String clientMessagesBlockBodyBooking(String phone);

  /// No description provided for @clientMessagesBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get clientMessagesBlockConfirm;

  /// No description provided for @clientMessagesBlockKeep.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clientMessagesBlockKeep;

  /// No description provided for @clientMessagesBlockedDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get clientMessagesBlockedDoneTitle;

  /// No description provided for @clientMessagesBlockedDoneDetail.
  ///
  /// In en, this message translates to:
  /// **'You will not receive messages from this side. You can unblock it at any time.'**
  String get clientMessagesBlockedDoneDetail;

  /// No description provided for @clientMessagesNtfTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientMessagesNtfTitle;

  /// No description provided for @clientMessagesNtfPrefs.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get clientMessagesNtfPrefs;

  /// No description provided for @clientMessagesNtfFilterGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter notifications'**
  String get clientMessagesNtfFilterGroup;

  /// No description provided for @clientMessagesNtfBookings.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get clientMessagesNtfBookings;

  /// No description provided for @clientMessagesNtfVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get clientMessagesNtfVouchers;

  /// No description provided for @clientMessagesNtfVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get clientMessagesNtfVisits;

  /// No description provided for @clientMessagesNtfMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get clientMessagesNtfMessages;

  /// No description provided for @clientMessagesNtfPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get clientMessagesNtfPlanning;

  /// No description provided for @clientMessagesNtfUnreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get clientMessagesNtfUnreadOnly;

  /// No description provided for @clientMessagesNtfUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get clientMessagesNtfUnread;

  /// No description provided for @clientMessagesNtfMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get clientMessagesNtfMarkAll;

  /// No description provided for @clientMessagesNtfAllRead.
  ///
  /// In en, this message translates to:
  /// **'All read'**
  String get clientMessagesNtfAllRead;

  /// No description provided for @clientMessagesNtfEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get clientMessagesNtfEmptyTitle;

  /// No description provided for @clientMessagesNtfUnreadEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get clientMessagesNtfUnreadEmptyTitle;

  /// No description provided for @clientMessagesNtfShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get clientMessagesNtfShowAll;

  /// No description provided for @clientMessagesNtfDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get clientMessagesNtfDeniedTitle;

  /// No description provided for @clientMessagesNtfDeniedInfo.
  ///
  /// In en, this message translates to:
  /// **'Updates still appear here. Turn them on in your phone settings to get them as they happen.'**
  String get clientMessagesNtfDeniedInfo;

  /// No description provided for @clientMessagesNtfOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get clientMessagesNtfOpenSettings;

  /// No description provided for @clientMessagesNtfSettingsToast.
  ///
  /// In en, this message translates to:
  /// **'Opens phone settings'**
  String get clientMessagesNtfSettingsToast;

  /// No description provided for @clientMessagesNtfOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get clientMessagesNtfOffer;

  /// No description provided for @clientMessagesNtfKindRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientMessagesNtfKindRequestSent;

  /// No description provided for @clientMessagesNtfKindApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clientMessagesNtfKindApproved;

  /// No description provided for @clientMessagesNtfKindConfirmReminder.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientMessagesNtfKindConfirmReminder;

  /// No description provided for @clientMessagesNtfKindConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get clientMessagesNtfKindConfirmed;

  /// No description provided for @clientMessagesNtfKindDeclined.
  ///
  /// In en, this message translates to:
  /// **'Not accepted'**
  String get clientMessagesNtfKindDeclined;

  /// No description provided for @clientMessagesNtfKindExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get clientMessagesNtfKindExpired;

  /// No description provided for @clientMessagesNtfKindCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clientMessagesNtfKindCancelled;

  /// No description provided for @clientMessagesNtfKindVoucherReady.
  ///
  /// In en, this message translates to:
  /// **'Voucher ready'**
  String get clientMessagesNtfKindVoucherReady;

  /// No description provided for @clientMessagesNtfKindVoucherKept.
  ///
  /// In en, this message translates to:
  /// **'Still yours'**
  String get clientMessagesNtfKindVoucherKept;

  /// No description provided for @clientMessagesNtfKindRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Redeemed'**
  String get clientMessagesNtfKindRedeemed;

  /// No description provided for @clientMessagesNtfKindRefunded.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get clientMessagesNtfKindRefunded;

  /// No description provided for @clientMessagesNtfKindExpiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get clientMessagesNtfKindExpiring;

  /// No description provided for @clientMessagesNtfKindVisitRequested.
  ///
  /// In en, this message translates to:
  /// **'Visit requested'**
  String get clientMessagesNtfKindVisitRequested;

  /// No description provided for @clientMessagesNtfKindVisitConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Visit confirmed'**
  String get clientMessagesNtfKindVisitConfirmed;

  /// No description provided for @clientMessagesNtfKindVisitSoon.
  ///
  /// In en, this message translates to:
  /// **'Visit soon'**
  String get clientMessagesNtfKindVisitSoon;

  /// No description provided for @clientMessagesNtfKindVisitChat.
  ///
  /// In en, this message translates to:
  /// **'Visit chat'**
  String get clientMessagesNtfKindVisitChat;

  /// No description provided for @clientMessagesNtfKindNewVenue.
  ///
  /// In en, this message translates to:
  /// **'New hall'**
  String get clientMessagesNtfKindNewVenue;

  /// No description provided for @clientMessagesNtfKindReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get clientMessagesNtfKindReview;

  /// No description provided for @clientMessagesNtfKindCountdown.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get clientMessagesNtfKindCountdown;

  /// No description provided for @clientMessagesNtfKindChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get clientMessagesNtfKindChecklist;

  /// No description provided for @clientMessagesPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking updates'**
  String get clientMessagesPromptTitle;

  /// No description provided for @clientMessagesPromptBody.
  ///
  /// In en, this message translates to:
  /// **'We will tell you as soon as a hall replies to your request, and when your voucher is ready.'**
  String get clientMessagesPromptBody;

  /// No description provided for @clientMessagesPromptNote.
  ///
  /// In en, this message translates to:
  /// **'We only send what you need, and never late at night.'**
  String get clientMessagesPromptNote;

  /// No description provided for @clientMessagesPromptOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get clientMessagesPromptOn;

  /// No description provided for @clientMessagesPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get clientMessagesPromptLater;

  /// No description provided for @clientMessagesPromptOnToast.
  ///
  /// In en, this message translates to:
  /// **'Updates on'**
  String get clientMessagesPromptOnToast;

  /// No description provided for @clientMessagesOsTitle.
  ///
  /// In en, this message translates to:
  /// **'“Ghazal” would like to send you notifications'**
  String get clientMessagesOsTitle;

  /// No description provided for @clientMessagesOsBody.
  ///
  /// In en, this message translates to:
  /// **'Request updates, vouchers and visit reminders.'**
  String get clientMessagesOsBody;

  /// No description provided for @clientMessagesOsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get clientMessagesOsAllow;

  /// No description provided for @clientMessagesOsDeny.
  ///
  /// In en, this message translates to:
  /// **'Don’t allow'**
  String get clientMessagesOsDeny;

  /// No description provided for @clientMessagesMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'No longer listed'**
  String get clientMessagesMissingTitle;

  /// No description provided for @clientMessagesMissingArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get clientMessagesMissingArea;

  /// No description provided for @clientMyWeddingHubTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wedding'**
  String get clientMyWeddingHubTitle;

  /// No description provided for @clientMyWeddingHubNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientMyWeddingHubNotifications;

  /// No description provided for @clientMyWeddingHeroUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day} other{days}}'**
  String clientMyWeddingHeroUnit(int count);

  /// No description provided for @clientMyWeddingHeroTimeline.
  ///
  /// In en, this message translates to:
  /// **'Countdown milestones'**
  String get clientMyWeddingHeroTimeline;

  /// No description provided for @clientMyWeddingHeroDate.
  ///
  /// In en, this message translates to:
  /// **'Wedding date'**
  String get clientMyWeddingHeroDate;

  /// No description provided for @clientMyWeddingHeroWordToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get clientMyWeddingHeroWordToday;

  /// No description provided for @clientMyWeddingHeroWordTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get clientMyWeddingHeroWordTomorrow;

  /// No description provided for @clientMyWeddingHeroSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get clientMyWeddingHeroSetDate;

  /// No description provided for @clientMyWeddingDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get clientMyWeddingDoneTitle;

  /// No description provided for @clientMyWeddingDoneReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get clientMyWeddingDoneReviewAction;

  /// No description provided for @clientMyWeddingDayDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get clientMyWeddingDayDirections;

  /// No description provided for @clientMyWeddingDayCall.
  ///
  /// In en, this message translates to:
  /// **'Call venue'**
  String get clientMyWeddingDayCall;

  /// No description provided for @clientMyWeddingDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Message planner'**
  String get clientMyWeddingDayMessage;

  /// No description provided for @clientMyWeddingDayDirectionsToast.
  ///
  /// In en, this message translates to:
  /// **'Opening directions'**
  String get clientMyWeddingDayDirectionsToast;

  /// No description provided for @clientMyWeddingDayCallToast.
  ///
  /// In en, this message translates to:
  /// **'Calling the venue'**
  String get clientMyWeddingDayCallToast;

  /// No description provided for @clientMyWeddingNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get clientMyWeddingNextTitle;

  /// No description provided for @clientMyWeddingNextWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get clientMyWeddingNextWaiting;

  /// No description provided for @clientMyWeddingNextWaitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply expected by {when}'**
  String clientMyWeddingNextWaitingLabel(String when);

  /// No description provided for @clientMyWeddingNextHalls.
  ///
  /// In en, this message translates to:
  /// **'View halls'**
  String get clientMyWeddingNextHalls;

  /// No description provided for @clientMyWeddingNextHallsLabel.
  ///
  /// In en, this message translates to:
  /// **'Halls free on your date'**
  String get clientMyWeddingNextHallsLabel;

  /// No description provided for @clientMyWeddingVoucherOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get clientMyWeddingVoucherOpen;

  /// No description provided for @clientMyWeddingNextConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm by {when}'**
  String clientMyWeddingNextConfirmLabel(String when);

  /// No description provided for @clientMyWeddingTaskVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientMyWeddingTaskVenue;

  /// No description provided for @clientMyWeddingTaskPhotographer.
  ///
  /// In en, this message translates to:
  /// **'Photographer'**
  String get clientMyWeddingTaskPhotographer;

  /// No description provided for @clientMyWeddingTaskDress.
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get clientMyWeddingTaskDress;

  /// No description provided for @clientMyWeddingTaskInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get clientMyWeddingTaskInvitations;

  /// No description provided for @clientMyWeddingTaskCake.
  ///
  /// In en, this message translates to:
  /// **'Cake'**
  String get clientMyWeddingTaskCake;

  /// No description provided for @clientMyWeddingTaskMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get clientMyWeddingTaskMusic;

  /// No description provided for @clientMyWeddingTaskFlowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get clientMyWeddingTaskFlowers;

  /// No description provided for @clientMyWeddingTaskTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get clientMyWeddingTaskTransport;

  /// No description provided for @clientMyWeddingTasksLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} task remaining} other{{count} tasks remaining}}'**
  String clientMyWeddingTasksLeft(int count);

  /// No description provided for @clientMyWeddingBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get clientMyWeddingBookingsTitle;

  /// No description provided for @clientMyWeddingBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get clientMyWeddingBookingsEmptyTitle;

  /// No description provided for @clientMyWeddingBookingsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientMyWeddingBookingsEmptyAction;

  /// No description provided for @clientMyWeddingBookingGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientMyWeddingBookingGuests;

  /// No description provided for @clientMyWeddingPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding planner'**
  String get clientMyWeddingPlannerTitle;

  /// No description provided for @clientMyWeddingPlannerOfferAction.
  ///
  /// In en, this message translates to:
  /// **'See packages'**
  String get clientMyWeddingPlannerOfferAction;

  /// No description provided for @clientMyWeddingPlannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Hide this offer'**
  String get clientMyWeddingPlannerDismiss;

  /// No description provided for @clientMyWeddingPlannerCall.
  ///
  /// In en, this message translates to:
  /// **'Video call {when}'**
  String clientMyWeddingPlannerCall(String when);

  /// No description provided for @clientMyWeddingToolsLabel.
  ///
  /// In en, this message translates to:
  /// **'Planning tools'**
  String get clientMyWeddingToolsLabel;

  /// No description provided for @clientMyWeddingToolChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get clientMyWeddingToolChecklist;

  /// No description provided for @clientMyWeddingToolBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get clientMyWeddingToolBudget;

  /// No description provided for @clientMyWeddingToolBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get clientMyWeddingToolBudgetOver;

  /// No description provided for @clientMyWeddingToolSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientMyWeddingToolSaved;

  /// No description provided for @clientMyWeddingToolServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get clientMyWeddingToolServices;

  /// No description provided for @clientMyWeddingGuestAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientMyWeddingGuestAction;

  /// No description provided for @clientMyWeddingSample.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get clientMyWeddingSample;

  /// No description provided for @clientMyWeddingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get clientMyWeddingUpdated;

  /// No description provided for @clientMyWeddingDateDiffersLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking date'**
  String get clientMyWeddingDateDiffersLabel;

  /// No description provided for @clientMyWeddingDateDiffersAction.
  ///
  /// In en, this message translates to:
  /// **'Use date'**
  String get clientMyWeddingDateDiffersAction;

  /// No description provided for @clientMyWeddingDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Wedding date updated'**
  String get clientMyWeddingDateUpdated;

  /// No description provided for @clientMyWeddingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get clientMyWeddingChecklistTitle;

  /// No description provided for @clientMyWeddingChecklistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get clientMyWeddingChecklistAdd;

  /// No description provided for @clientMyWeddingChecklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String clientMyWeddingChecklistProgress(String done, String total);

  /// No description provided for @clientMyWeddingChecklistBandBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get clientMyWeddingChecklistBandBooking;

  /// No description provided for @clientMyWeddingChecklistBandMore.
  ///
  /// In en, this message translates to:
  /// **'{count}+ months'**
  String clientMyWeddingChecklistBandMore(String count);

  /// No description provided for @clientMyWeddingChecklistBandMonths.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} months'**
  String clientMyWeddingChecklistBandMonths(String from, String to);

  /// No description provided for @clientMyWeddingChecklistBandMonth.
  ///
  /// In en, this message translates to:
  /// **'Final month'**
  String get clientMyWeddingChecklistBandMonth;

  /// No description provided for @clientMyWeddingChecklistBandWeek.
  ///
  /// In en, this message translates to:
  /// **'Final week'**
  String get clientMyWeddingChecklistBandWeek;

  /// No description provided for @clientMyWeddingChecklistBandNoDate.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get clientMyWeddingChecklistBandNoDate;

  /// No description provided for @clientMyWeddingChecklistBandDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get clientMyWeddingChecklistBandDone;

  /// No description provided for @clientMyWeddingChecklistDue.
  ///
  /// In en, this message translates to:
  /// **'Due {when}'**
  String clientMyWeddingChecklistDue(String when);

  /// No description provided for @clientMyWeddingChecklistOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue since {when}'**
  String clientMyWeddingChecklistOverdue(String when);

  /// No description provided for @clientMyWeddingChecklistAuto.
  ///
  /// In en, this message translates to:
  /// **'Completes when your booking is confirmed'**
  String get clientMyWeddingChecklistAuto;

  /// No description provided for @clientMyWeddingChecklistBrowseLabel.
  ///
  /// In en, this message translates to:
  /// **'{task}: browse services'**
  String clientMyWeddingChecklistBrowseLabel(String task);

  /// No description provided for @clientMyWeddingChecklistViewBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'{task}: view booking'**
  String clientMyWeddingChecklistViewBookingLabel(String task);

  /// No description provided for @clientMyWeddingChecklistEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get clientMyWeddingChecklistEdit;

  /// No description provided for @clientMyWeddingChecklistToastDone.
  ///
  /// In en, this message translates to:
  /// **'Marked as done'**
  String get clientMyWeddingChecklistToastDone;

  /// No description provided for @clientMyWeddingChecklistAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get clientMyWeddingChecklistAllDone;

  /// No description provided for @clientMyWeddingChecklistEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No date yet'**
  String get clientMyWeddingChecklistEmptyTitle;

  /// No description provided for @clientMyWeddingChecklistEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get clientMyWeddingChecklistEmptyAction;

  /// No description provided for @clientMyWeddingTaskSheetAdd.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get clientMyWeddingTaskSheetAdd;

  /// No description provided for @clientMyWeddingTaskSheetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get clientMyWeddingTaskSheetEdit;

  /// No description provided for @clientMyWeddingTaskTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get clientMyWeddingTaskTitlePlaceholder;

  /// No description provided for @clientMyWeddingTaskTitleError.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get clientMyWeddingTaskTitleError;

  /// No description provided for @clientMyWeddingTaskDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get clientMyWeddingTaskDueLabel;

  /// No description provided for @clientMyWeddingTaskCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get clientMyWeddingTaskCategoryLabel;

  /// No description provided for @clientMyWeddingTaskCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get clientMyWeddingTaskCategoryPlaceholder;

  /// No description provided for @clientMyWeddingTaskDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get clientMyWeddingTaskDelete;

  /// No description provided for @clientMyWeddingTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Task added'**
  String get clientMyWeddingTaskAdded;

  /// No description provided for @clientMyWeddingTaskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get clientMyWeddingTaskDeleted;

  /// No description provided for @clientMyWeddingBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get clientMyWeddingBudgetTitle;

  /// No description provided for @clientMyWeddingBudgetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get clientMyWeddingBudgetEdit;

  /// No description provided for @clientMyWeddingBudgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get clientMyWeddingBudgetRemaining;

  /// No description provided for @clientMyWeddingBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get clientMyWeddingBudgetOver;

  /// No description provided for @clientMyWeddingBudgetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get clientMyWeddingBudgetTotalLabel;

  /// No description provided for @clientMyWeddingBudgetPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get clientMyWeddingBudgetPaid;

  /// No description provided for @clientMyWeddingBudgetCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get clientMyWeddingBudgetCommitted;

  /// No description provided for @clientMyWeddingBudgetBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid}, committed {committed}, remaining {remaining}'**
  String clientMyWeddingBudgetBarLabel(
    String paid,
    String committed,
    String remaining,
  );

  /// No description provided for @clientMyWeddingBudgetAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get clientMyWeddingBudgetAddExpense;

  /// No description provided for @clientMyWeddingBudgetAlertSoft.
  ///
  /// In en, this message translates to:
  /// **'{category} {percent}'**
  String clientMyWeddingBudgetAlertSoft(String category, String percent);

  /// No description provided for @clientMyWeddingBudgetAlertOver.
  ///
  /// In en, this message translates to:
  /// **'{category} {amount}'**
  String clientMyWeddingBudgetAlertOver(String category, String amount);

  /// No description provided for @clientMyWeddingBudgetCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get clientMyWeddingBudgetCategories;

  /// No description provided for @clientMyWeddingBudgetLedger.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get clientMyWeddingBudgetLedger;

  /// No description provided for @clientMyWeddingBudgetInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher and venue'**
  String get clientMyWeddingBudgetInfoTitle;

  /// No description provided for @clientMyWeddingBudgetInfoBody.
  ///
  /// In en, this message translates to:
  /// **'The voucher is paid in the app. The venue price is paid to the venue directly, outside Ghazal.'**
  String get clientMyWeddingBudgetInfoBody;

  /// No description provided for @clientMyWeddingBudgetUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent} used'**
  String clientMyWeddingBudgetUsedLabel(String percent);

  /// No description provided for @clientMyWeddingBudgetOverByLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} over its share'**
  String clientMyWeddingBudgetOverByLabel(String amount);

  /// No description provided for @clientMyWeddingBudgetLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to your booking'**
  String get clientMyWeddingBudgetLinked;

  /// No description provided for @clientMyWeddingBudgetPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get clientMyWeddingBudgetPlanned;

  /// No description provided for @clientMyWeddingBudgetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budget yet'**
  String get clientMyWeddingBudgetEmptyTitle;

  /// No description provided for @clientMyWeddingBudgetEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get clientMyWeddingBudgetEmptyAction;

  /// No description provided for @clientMyWeddingBudgetAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense added'**
  String get clientMyWeddingBudgetAdded;

  /// No description provided for @clientMyWeddingExpenseTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get clientMyWeddingExpenseTitleAdd;

  /// No description provided for @clientMyWeddingExpenseTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get clientMyWeddingExpenseTitleEdit;

  /// No description provided for @clientMyWeddingExpenseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get clientMyWeddingExpenseAmount;

  /// No description provided for @clientMyWeddingExpenseAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get clientMyWeddingExpenseAmountError;

  /// No description provided for @clientMyWeddingExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get clientMyWeddingExpenseCategory;

  /// No description provided for @clientMyWeddingExpenseNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientMyWeddingExpenseNote;

  /// No description provided for @clientMyWeddingExpenseDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientMyWeddingExpenseDate;

  /// No description provided for @clientMyWeddingExpenseStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get clientMyWeddingExpenseStatus;

  /// No description provided for @clientMyWeddingExpensePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get clientMyWeddingExpensePaid;

  /// No description provided for @clientMyWeddingExpensePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get clientMyWeddingExpensePlanned;

  /// No description provided for @clientMyWeddingExpenseDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get clientMyWeddingExpenseDelete;

  /// No description provided for @clientMyWeddingExpenseDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get clientMyWeddingExpenseDeleteTitle;

  /// No description provided for @clientMyWeddingExpenseKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get clientMyWeddingExpenseKeep;

  /// No description provided for @clientMyWeddingExpenseSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get clientMyWeddingExpenseSuccessTitle;

  /// No description provided for @clientMyWeddingExpenseOfflineReason.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to save'**
  String get clientMyWeddingExpenseOfflineReason;

  /// No description provided for @clientMyWeddingExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get clientMyWeddingExpenseDeleted;

  /// No description provided for @clientMyWeddingExpenseSampleLabel.
  ///
  /// In en, this message translates to:
  /// **'Henna artist deposit'**
  String get clientMyWeddingExpenseSampleLabel;

  /// No description provided for @clientMyWeddingSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get clientMyWeddingSetupTitle;

  /// No description provided for @clientMyWeddingSetupTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get clientMyWeddingSetupTotal;

  /// No description provided for @clientMyWeddingSetupPresets.
  ///
  /// In en, this message translates to:
  /// **'Suggested totals'**
  String get clientMyWeddingSetupPresets;

  /// No description provided for @clientMyWeddingSetupCategories.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get clientMyWeddingSetupCategories;

  /// No description provided for @clientMyWeddingSetupVenueReference.
  ///
  /// In en, this message translates to:
  /// **'Your venue and catering range'**
  String get clientMyWeddingSetupVenueReference;

  /// No description provided for @clientMyWeddingSetupUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get clientMyWeddingSetupUnallocated;

  /// No description provided for @clientMyWeddingSetupOver.
  ///
  /// In en, this message translates to:
  /// **'Over total'**
  String get clientMyWeddingSetupOver;

  /// No description provided for @clientMyWeddingSetupAlertSoft.
  ///
  /// In en, this message translates to:
  /// **'Alert at {percent}'**
  String clientMyWeddingSetupAlertSoft(String percent);

  /// No description provided for @clientMyWeddingSetupAlertHard.
  ///
  /// In en, this message translates to:
  /// **'Alert at {percent}'**
  String clientMyWeddingSetupAlertHard(String percent);

  /// No description provided for @clientMyWeddingSetupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get clientMyWeddingSetupError;

  /// No description provided for @clientMyWeddingSetupErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your budget. Nothing was changed.'**
  String get clientMyWeddingSetupErrorDetail;

  /// No description provided for @clientMyWeddingSetupSaved.
  ///
  /// In en, this message translates to:
  /// **'Budget saved'**
  String get clientMyWeddingSetupSaved;

  /// No description provided for @clientMyWeddingCatVenueCatering.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientMyWeddingCatVenueCatering;

  /// No description provided for @clientMyWeddingCatPhotoVideo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get clientMyWeddingCatPhotoVideo;

  /// No description provided for @clientMyWeddingCatFlowersDecor.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get clientMyWeddingCatFlowersDecor;

  /// No description provided for @clientMyWeddingCatAttire.
  ///
  /// In en, this message translates to:
  /// **'Attire'**
  String get clientMyWeddingCatAttire;

  /// No description provided for @clientMyWeddingCatMakeupHenna.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get clientMyWeddingCatMakeupHenna;

  /// No description provided for @clientMyWeddingCatCars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get clientMyWeddingCatCars;

  /// No description provided for @clientMyWeddingCatInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get clientMyWeddingCatInvitations;

  /// No description provided for @clientMyWeddingCatMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get clientMyWeddingCatMusic;

  /// No description provided for @clientMyWeddingCatHoneymoon.
  ///
  /// In en, this message translates to:
  /// **'Honeymoon'**
  String get clientMyWeddingCatHoneymoon;

  /// No description provided for @clientOnboardingAltLanguage.
  ///
  /// In en, this message translates to:
  /// **'Wedding stage framed by rose-and-greenery arches, blush swags and white drapery, with a long floral table in the foreground'**
  String get clientOnboardingAltLanguage;

  /// No description provided for @clientOnboardingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String clientOnboardingStepProgress(num current, num total);

  /// No description provided for @clientOnboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get clientOnboardingLanguageTitle;

  /// No description provided for @clientOnboardingLanguageGroup.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get clientOnboardingLanguageGroup;

  /// No description provided for @clientOnboardingLanguageSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientOnboardingLanguageSignIn;

  /// No description provided for @clientOnboardingLanguageSignInOffline.
  ///
  /// In en, this message translates to:
  /// **'Signing in needs a connection.'**
  String get clientOnboardingLanguageSignInOffline;

  /// No description provided for @clientOnboardingIntroLabel.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get clientOnboardingIntroLabel;

  /// No description provided for @clientOnboardingIntroSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Compare three halls'**
  String get clientOnboardingIntroSlide1Title;

  /// No description provided for @clientOnboardingIntroSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Free dates at a glance'**
  String get clientOnboardingIntroSlide2Title;

  /// No description provided for @clientOnboardingIntroSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Lower voucher prices'**
  String get clientOnboardingIntroSlide3Title;

  /// No description provided for @clientOnboardingIntroStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get clientOnboardingIntroStart;

  /// No description provided for @clientOnboardingInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get clientOnboardingInfoTitle;

  /// No description provided for @clientOnboardingInfoBody.
  ///
  /// In en, this message translates to:
  /// **'All optional. They stay on this device until you sign up, and you can change them anytime in Profile.'**
  String get clientOnboardingInfoBody;

  /// No description provided for @clientOnboardingAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Who’s planning?'**
  String get clientOnboardingAboutTitle;

  /// No description provided for @clientOnboardingAboutRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get clientOnboardingAboutRoleLabel;

  /// No description provided for @clientOnboardingAboutRoleBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get clientOnboardingAboutRoleBride;

  /// No description provided for @clientOnboardingAboutRoleGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get clientOnboardingAboutRoleGroom;

  /// No description provided for @clientOnboardingAboutRoleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get clientOnboardingAboutRoleFamily;

  /// No description provided for @clientOnboardingAboutRolePlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get clientOnboardingAboutRolePlanner;

  /// No description provided for @clientOnboardingAboutNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientOnboardingAboutNameLabel;

  /// No description provided for @clientOnboardingAboutPartnerDefault.
  ///
  /// In en, this message translates to:
  /// **'Partner’s name'**
  String get clientOnboardingAboutPartnerDefault;

  /// No description provided for @clientOnboardingAboutPartnerGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom’s name'**
  String get clientOnboardingAboutPartnerGroom;

  /// No description provided for @clientOnboardingAboutPartnerBride.
  ///
  /// In en, this message translates to:
  /// **'Bride’s name'**
  String get clientOnboardingAboutPartnerBride;

  /// No description provided for @clientOnboardingAboutPartnerCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple’s names'**
  String get clientOnboardingAboutPartnerCouple;

  /// No description provided for @clientOnboardingAboutMonogram.
  ///
  /// In en, this message translates to:
  /// **'Monogram preview'**
  String get clientOnboardingAboutMonogram;

  /// No description provided for @clientOnboardingDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding date'**
  String get clientOnboardingDateTitle;

  /// No description provided for @clientOnboardingDateOccasions.
  ///
  /// In en, this message translates to:
  /// **'Around this month'**
  String get clientOnboardingDateOccasions;

  /// No description provided for @clientOnboardingDateOccasionOne.
  ///
  /// In en, this message translates to:
  /// **'{name} · {date}'**
  String clientOnboardingDateOccasionOne(String name, String date);

  /// No description provided for @clientOnboardingDateOccasionRange.
  ///
  /// In en, this message translates to:
  /// **'{name} · {from} to {to}'**
  String clientOnboardingDateOccasionRange(String name, String from, String to);

  /// No description provided for @clientOnboardingDateNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Undecided'**
  String get clientOnboardingDateNotDecided;

  /// No description provided for @clientOnboardingDateFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get clientOnboardingDateFlexible;

  /// No description provided for @clientOnboardingDateFlexibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Flexible month'**
  String get clientOnboardingDateFlexibleTitle;

  /// No description provided for @clientOnboardingDatePickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get clientOnboardingDatePickDate;

  /// No description provided for @clientOnboardingDateMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get clientOnboardingDateMonthsLabel;

  /// No description provided for @clientOnboardingGuestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guests and budget'**
  String get clientOnboardingGuestsTitle;

  /// No description provided for @clientOnboardingGuestsSection.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientOnboardingGuestsSection;

  /// No description provided for @clientOnboardingGuestsExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected guests'**
  String get clientOnboardingGuestsExpected;

  /// No description provided for @clientOnboardingGuestsPresets.
  ///
  /// In en, this message translates to:
  /// **'Common guest counts'**
  String get clientOnboardingGuestsPresets;

  /// No description provided for @clientOnboardingGuestsPresetMax.
  ///
  /// In en, this message translates to:
  /// **'{count}+'**
  String clientOnboardingGuestsPresetMax(String count);

  /// No description provided for @clientOnboardingGuestsSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Ladies and men'**
  String get clientOnboardingGuestsSplitTitle;

  /// No description provided for @clientOnboardingGuestsSplitLabel.
  ///
  /// In en, this message translates to:
  /// **'Separate ladies’ and men’s receptions'**
  String get clientOnboardingGuestsSplitLabel;

  /// No description provided for @clientOnboardingGuestsLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get clientOnboardingGuestsLadies;

  /// No description provided for @clientOnboardingGuestsMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get clientOnboardingGuestsMen;

  /// No description provided for @clientOnboardingBudgetSection.
  ///
  /// In en, this message translates to:
  /// **'Venue and catering'**
  String get clientOnboardingBudgetSection;

  /// No description provided for @clientOnboardingBudgetBands.
  ///
  /// In en, this message translates to:
  /// **'Budget bands'**
  String get clientOnboardingBudgetBands;

  /// No description provided for @clientOnboardingBudgetUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {amount}'**
  String clientOnboardingBudgetUnder(String amount);

  /// No description provided for @clientOnboardingBudgetAbove.
  ///
  /// In en, this message translates to:
  /// **'{amount} and above'**
  String clientOnboardingBudgetAbove(String amount);

  /// No description provided for @clientOnboardingBudgetRange.
  ///
  /// In en, this message translates to:
  /// **'Custom budget range'**
  String get clientOnboardingBudgetRange;

  /// No description provided for @clientOnboardingSkipHalf.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get clientOnboardingSkipHalf;

  /// No description provided for @clientOnboardingAreasTitle.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get clientOnboardingAreasTitle;

  /// No description provided for @clientOnboardingAreasSearch.
  ///
  /// In en, this message translates to:
  /// **'Search areas'**
  String get clientOnboardingAreasSearch;

  /// No description provided for @clientOnboardingAreasSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No areas selected} one{{count} area selected} other{{count} areas selected}}'**
  String clientOnboardingAreasSelected(int count);

  /// No description provided for @clientOnboardingAreasDemoQuery.
  ///
  /// In en, this message translates to:
  /// **'Mish'**
  String get clientOnboardingAreasDemoQuery;

  /// No description provided for @clientOnboardingAreasMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No more areas} one{{count} more area} other{{count} more areas}}'**
  String clientOnboardingAreasMore(int count);

  /// No description provided for @clientOnboardingAreasNoHallsNote.
  ///
  /// In en, this message translates to:
  /// **'No halls yet. Home shows all.'**
  String get clientOnboardingAreasNoHallsNote;

  /// No description provided for @clientPaymentTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get clientPaymentTopTitle;

  /// No description provided for @clientPaymentSave.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}'**
  String clientPaymentSave(String amount);

  /// No description provided for @clientPaymentLabelHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientPaymentLabelHall;

  /// No description provided for @clientPaymentLabelPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientPaymentLabelPackage;

  /// No description provided for @clientPaymentLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientPaymentLabelDate;

  /// No description provided for @clientPaymentLabelGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientPaymentLabelGuests;

  /// No description provided for @clientPaymentLabelOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until'**
  String get clientPaymentLabelOpenUntil;

  /// No description provided for @clientPaymentLabelSaving.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get clientPaymentLabelSaving;

  /// No description provided for @clientPaymentLabelAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get clientPaymentLabelAmount;

  /// No description provided for @clientPaymentLabelMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get clientPaymentLabelMethod;

  /// No description provided for @clientPaymentLabelVoucherFor.
  ///
  /// In en, this message translates to:
  /// **'Voucher for'**
  String get clientPaymentLabelVoucherFor;

  /// No description provided for @clientPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Ghazal voucher, paid once'**
  String get clientPaymentAmountLabel;

  /// No description provided for @clientPaymentTimerSr.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {time}'**
  String clientPaymentTimerSr(String time);

  /// No description provided for @clientPaymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get clientPaymentMethodsTitle;

  /// No description provided for @clientPaymentMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get clientPaymentMethodsLabel;

  /// No description provided for @clientPaymentMethodKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get clientPaymentMethodKnet;

  /// No description provided for @clientPaymentMethodApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get clientPaymentMethodApplePay;

  /// No description provided for @clientPaymentMethodGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get clientPaymentMethodGooglePay;

  /// No description provided for @clientPaymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Visa or Mastercard'**
  String get clientPaymentMethodCard;

  /// No description provided for @clientPaymentMethodCardShort.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get clientPaymentMethodCardShort;

  /// No description provided for @clientPaymentMethodSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get clientPaymentMethodSuggested;

  /// No description provided for @clientPaymentSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get clientPaymentSecureTitle;

  /// No description provided for @clientPaymentHonestKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET opens your bank’s secure page and works with Kuwaiti bank cards only.'**
  String get clientPaymentHonestKnet;

  /// No description provided for @clientPaymentHonestWallet.
  ///
  /// In en, this message translates to:
  /// **'You confirm on your device. Ghazal never sees your card details.'**
  String get clientPaymentHonestWallet;

  /// No description provided for @clientPaymentHonestCard.
  ///
  /// In en, this message translates to:
  /// **'You enter your card on the payment provider’s secure page. Ghazal never sees or stores it.'**
  String get clientPaymentHonestCard;

  /// No description provided for @clientPaymentCtaPay.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get clientPaymentCtaPay;

  /// No description provided for @clientPaymentTermPrice.
  ///
  /// In en, this message translates to:
  /// **'Voucher price'**
  String get clientPaymentTermPrice;

  /// No description provided for @clientPaymentTermDirect.
  ///
  /// In en, this message translates to:
  /// **'Pay direct'**
  String get clientPaymentTermDirect;

  /// No description provided for @clientPaymentTermReturns.
  ///
  /// In en, this message translates to:
  /// **'Voucher returns'**
  String get clientPaymentTermReturns;

  /// No description provided for @clientPaymentHowLink.
  ///
  /// In en, this message translates to:
  /// **'How the voucher works'**
  String get clientPaymentHowLink;

  /// No description provided for @clientPaymentHasVoucherBanner.
  ///
  /// In en, this message translates to:
  /// **'You have this voucher'**
  String get clientPaymentHasVoucherBanner;

  /// No description provided for @clientPaymentSessionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start payment'**
  String get clientPaymentSessionErrorTitle;

  /// No description provided for @clientPaymentSessionError.
  ///
  /// In en, this message translates to:
  /// **'We could not start the payment. No amount was charged.'**
  String get clientPaymentSessionError;

  /// No description provided for @clientPaymentExpiredBanner.
  ///
  /// In en, this message translates to:
  /// **'Checkout ended'**
  String get clientPaymentExpiredBanner;

  /// No description provided for @clientPaymentCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Cancelled, not charged'**
  String get clientPaymentCancelledToast;

  /// No description provided for @clientPaymentGatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get clientPaymentGatewayTitle;

  /// No description provided for @clientPaymentGatewayBack.
  ///
  /// In en, this message translates to:
  /// **'Close payment'**
  String get clientPaymentGatewayBack;

  /// No description provided for @clientPaymentLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave payment?'**
  String get clientPaymentLeaveTitle;

  /// No description provided for @clientPaymentLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Not charged yet'**
  String get clientPaymentLeaveBody;

  /// No description provided for @clientPaymentLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get clientPaymentLeaveConfirm;

  /// No description provided for @clientPaymentLeaveStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get clientPaymentLeaveStay;

  /// No description provided for @clientPaymentRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening secure page'**
  String get clientPaymentRedirectTitle;

  /// No description provided for @clientPaymentRedirectBody.
  ///
  /// In en, this message translates to:
  /// **'You will finish the payment on a secure page. Nothing is charged until you do.'**
  String get clientPaymentRedirectBody;

  /// No description provided for @clientPaymentRedirectPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Ghazal never sees your card number or PIN.'**
  String get clientPaymentRedirectPrivacy;

  /// No description provided for @clientPaymentReturnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Checking payment'**
  String get clientPaymentReturnedTitle;

  /// No description provided for @clientPaymentLostTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get clientPaymentLostTitle;

  /// No description provided for @clientPaymentLostBody.
  ///
  /// In en, this message translates to:
  /// **'We are checking your payment. There is no need to pay again.'**
  String get clientPaymentLostBody;

  /// No description provided for @clientPaymentCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get clientPaymentCancelTitle;

  /// No description provided for @clientPaymentNotCharged.
  ///
  /// In en, this message translates to:
  /// **'Not charged'**
  String get clientPaymentNotCharged;

  /// No description provided for @clientPaymentNotChargedLabel.
  ///
  /// In en, this message translates to:
  /// **'Charge status'**
  String get clientPaymentNotChargedLabel;

  /// No description provided for @clientPaymentReceivedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get clientPaymentReceivedLabel;

  /// No description provided for @clientPaymentBankNote.
  ///
  /// In en, this message translates to:
  /// **'Bank page'**
  String get clientPaymentBankNote;

  /// No description provided for @clientPaymentCardPageNote.
  ///
  /// In en, this message translates to:
  /// **'Card page'**
  String get clientPaymentCardPageNote;

  /// No description provided for @clientPaymentBankBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get clientPaymentBankBank;

  /// No description provided for @clientPaymentBankCard.
  ///
  /// In en, this message translates to:
  /// **'Card number'**
  String get clientPaymentBankCard;

  /// No description provided for @clientPaymentBankExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get clientPaymentBankExpiry;

  /// No description provided for @clientPaymentBankPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get clientPaymentBankPin;

  /// No description provided for @clientPaymentBankItemName.
  ///
  /// In en, this message translates to:
  /// **'Ghazal voucher'**
  String get clientPaymentBankItemName;

  /// No description provided for @clientPaymentBankSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get clientPaymentBankSubmit;

  /// No description provided for @clientPaymentCardHolder.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientPaymentCardHolder;

  /// No description provided for @clientPaymentCardCvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get clientPaymentCardCvv;

  /// No description provided for @clientPaymentProtoLabel.
  ///
  /// In en, this message translates to:
  /// **'Prototype'**
  String get clientPaymentProtoLabel;

  /// No description provided for @clientPaymentProtoApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clientPaymentProtoApproved;

  /// No description provided for @clientPaymentProtoDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get clientPaymentProtoDeclined;

  /// No description provided for @clientPaymentProtoSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get clientPaymentProtoSlow;

  /// No description provided for @clientPaymentProtoLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get clientPaymentProtoLost;

  /// No description provided for @clientPaymentProtoLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get clientPaymentProtoLate;

  /// No description provided for @clientPaymentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming payment'**
  String get clientPaymentConfirmTitle;

  /// No description provided for @clientPaymentConfirmLongTitle.
  ///
  /// In en, this message translates to:
  /// **'Still confirming'**
  String get clientPaymentConfirmLongTitle;

  /// No description provided for @clientPaymentConfirmNotify.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify you'**
  String get clientPaymentConfirmNotify;

  /// No description provided for @clientPaymentConfirmNotifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get clientPaymentConfirmNotifyLabel;

  /// No description provided for @clientPaymentConfirmKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get clientPaymentConfirmKeep;

  /// No description provided for @clientPaymentConfirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get clientPaymentConfirmLeave;

  /// No description provided for @clientPaymentConfirmOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Your payment is being confirmed and we will notify you.'**
  String get clientPaymentConfirmOffline;

  /// No description provided for @clientPaymentConfirmSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get clientPaymentConfirmSuccessTitle;

  /// No description provided for @clientPaymentConfirmProgress.
  ///
  /// In en, this message translates to:
  /// **'Checking the payment'**
  String get clientPaymentConfirmProgress;

  /// No description provided for @clientPaymentViewVoucher.
  ///
  /// In en, this message translates to:
  /// **'View voucher'**
  String get clientPaymentViewVoucher;

  /// No description provided for @clientPaymentFailTitleExpired.
  ///
  /// In en, this message translates to:
  /// **'Checkout ended'**
  String get clientPaymentFailTitleExpired;

  /// No description provided for @clientPaymentFailTitleLate.
  ///
  /// In en, this message translates to:
  /// **'Voucher ready'**
  String get clientPaymentFailTitleLate;

  /// No description provided for @clientPaymentFailBodyDeclined.
  ///
  /// In en, this message translates to:
  /// **'Your bank did not accept the payment. You can try again or choose another method.'**
  String get clientPaymentFailBodyDeclined;

  /// No description provided for @clientPaymentFailBodyCancelled.
  ///
  /// In en, this message translates to:
  /// **'You closed the payment page before it finished.'**
  String get clientPaymentFailBodyCancelled;

  /// No description provided for @clientPaymentFailBodyExpired.
  ///
  /// In en, this message translates to:
  /// **'Your checkout for this voucher ended at {time}, after {minutes}. You can start again with the same quote.'**
  String clientPaymentFailBodyExpired(String time, String minutes);

  /// No description provided for @clientPaymentFailBodyLate.
  ///
  /// In en, this message translates to:
  /// **'Your payment arrived after the checkout ended, and we still honoured it. The voucher is yours.'**
  String get clientPaymentFailBodyLate;

  /// No description provided for @clientPaymentFailBodyOffline.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to try again. Nothing is charged until a payment completes.'**
  String get clientPaymentFailBodyOffline;

  /// No description provided for @clientPaymentFailAnother.
  ///
  /// In en, this message translates to:
  /// **'Another method'**
  String get clientPaymentFailAnother;

  /// No description provided for @clientPaymentFailStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get clientPaymentFailStartAgain;

  /// No description provided for @clientPaymentSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientPaymentSupport;

  /// No description provided for @clientPaymentDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher ready'**
  String get clientPaymentDoneTitle;

  /// No description provided for @clientPaymentDoneLate.
  ///
  /// In en, this message translates to:
  /// **'Payment arrived late'**
  String get clientPaymentDoneLate;

  /// No description provided for @clientPaymentDoneLateNote.
  ///
  /// In en, this message translates to:
  /// **'Your payment arrived after the checkout ended. The voucher is active and bound to the date shown.'**
  String get clientPaymentDoneLateNote;

  /// No description provided for @clientPaymentDoneReuse.
  ///
  /// In en, this message translates to:
  /// **'If the request is declined or goes unanswered, your voucher comes back to you.'**
  String get clientPaymentDoneReuse;

  /// No description provided for @clientPaymentDoneCta.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientPaymentDoneCta;

  /// No description provided for @clientPaymentDoneRowVouchers.
  ///
  /// In en, this message translates to:
  /// **'My vouchers'**
  String get clientPaymentDoneRowVouchers;

  /// No description provided for @clientPaymentDoneRowReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get clientPaymentDoneRowReceipt;

  /// No description provided for @clientPaymentTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher terms'**
  String get clientPaymentTermsTitle;

  /// No description provided for @clientPaymentTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher terms'**
  String get clientPaymentTermsLabel;

  /// No description provided for @clientPlannerOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a planner?'**
  String get clientPlannerOfferTitle;

  /// No description provided for @clientPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get clientPlannerTitle;

  /// No description provided for @clientPlannerCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get clientPlannerCompareTitle;

  /// No description provided for @clientPlannerCompareLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare packages'**
  String get clientPlannerCompareLabel;

  /// No description provided for @clientPlannerTierPickerLabel.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientPlannerTierPickerLabel;

  /// No description provided for @clientPlannerFromPrefix.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clientPlannerFromPrefix;

  /// No description provided for @clientPlannerMarks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} thread mark} other{{count} thread marks}}'**
  String clientPlannerMarks(int count);

  /// No description provided for @clientPlannerCompareChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String clientPlannerCompareChoose(String name);

  /// No description provided for @clientPlannerCompareChosen.
  ///
  /// In en, this message translates to:
  /// **'{name}, chosen'**
  String clientPlannerCompareChosen(String name);

  /// No description provided for @clientPlannerIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get clientPlannerIncluded;

  /// No description provided for @clientPlannerNotIncluded.
  ///
  /// In en, this message translates to:
  /// **'Not included'**
  String get clientPlannerNotIncluded;

  /// No description provided for @clientPlannerIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'What is included'**
  String get clientPlannerIncludedLabel;

  /// No description provided for @clientPlannerEverythingIn.
  ///
  /// In en, this message translates to:
  /// **'Everything in'**
  String get clientPlannerEverythingIn;

  /// No description provided for @clientPlannerIncSilver0.
  ///
  /// In en, this message translates to:
  /// **'Day coordinator'**
  String get clientPlannerIncSilver0;

  /// No description provided for @clientPlannerIncSilver1.
  ///
  /// In en, this message translates to:
  /// **'Event timeline'**
  String get clientPlannerIncSilver1;

  /// No description provided for @clientPlannerIncSilver2.
  ///
  /// In en, this message translates to:
  /// **'Vendor checks'**
  String get clientPlannerIncSilver2;

  /// No description provided for @clientPlannerIncSilver3.
  ///
  /// In en, this message translates to:
  /// **'Venue walkthrough'**
  String get clientPlannerIncSilver3;

  /// No description provided for @clientPlannerIncGold0.
  ///
  /// In en, this message translates to:
  /// **'Planning from booking'**
  String get clientPlannerIncGold0;

  /// No description provided for @clientPlannerIncGold1.
  ///
  /// In en, this message translates to:
  /// **'Vendors and quotes'**
  String get clientPlannerIncGold1;

  /// No description provided for @clientPlannerIncGold2.
  ///
  /// In en, this message translates to:
  /// **'Styling concept'**
  String get clientPlannerIncGold2;

  /// No description provided for @clientPlannerIncGold3.
  ///
  /// In en, this message translates to:
  /// **'Two meetings'**
  String get clientPlannerIncGold3;

  /// No description provided for @clientPlannerIncRoyal0.
  ///
  /// In en, this message translates to:
  /// **'Bespoke kosha'**
  String get clientPlannerIncRoyal0;

  /// No description provided for @clientPlannerIncRoyal1.
  ///
  /// In en, this message translates to:
  /// **'Production management'**
  String get clientPlannerIncRoyal1;

  /// No description provided for @clientPlannerIncRoyal2.
  ///
  /// In en, this message translates to:
  /// **'Vendor contracts'**
  String get clientPlannerIncRoyal2;

  /// No description provided for @clientPlannerIncRoyal3.
  ///
  /// In en, this message translates to:
  /// **'Dedicated team'**
  String get clientPlannerIncRoyal3;

  /// No description provided for @clientPlannerWeddingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your wedding'**
  String get clientPlannerWeddingLabel;

  /// No description provided for @clientPlannerPriceInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientPlannerPriceInfoTitle;

  /// No description provided for @clientPlannerPriceInfo.
  ///
  /// In en, this message translates to:
  /// **'You agree the final price with your planner after the consultation. Nothing is paid now.'**
  String get clientPlannerPriceInfo;

  /// No description provided for @clientPlannerRequestConsultation.
  ///
  /// In en, this message translates to:
  /// **'Request consultation'**
  String get clientPlannerRequestConsultation;

  /// No description provided for @clientPlannerNotNowToast.
  ///
  /// In en, this message translates to:
  /// **'Always in My Wedding'**
  String get clientPlannerNotNowToast;

  /// No description provided for @clientPlannerOtherPlanners.
  ///
  /// In en, this message translates to:
  /// **'Other planners'**
  String get clientPlannerOtherPlanners;

  /// No description provided for @clientPlannerGuestSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientPlannerGuestSignIn;

  /// No description provided for @clientPlannerRetryToast.
  ///
  /// In en, this message translates to:
  /// **'Still can’t connect'**
  String get clientPlannerRetryToast;

  /// No description provided for @clientPlannerRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get clientPlannerRequestTitle;

  /// No description provided for @clientPlannerRequestChange.
  ///
  /// In en, this message translates to:
  /// **'Change package'**
  String get clientPlannerRequestChange;

  /// No description provided for @clientPlannerRequestTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get clientPlannerRequestTimesTitle;

  /// No description provided for @clientPlannerRequestDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get clientPlannerRequestDayLabel;

  /// No description provided for @clientPlannerRequestWindowLabel.
  ///
  /// In en, this message translates to:
  /// **'Time of day for {day}'**
  String clientPlannerRequestWindowLabel(String day);

  /// No description provided for @clientPlannerRequestDayWithChoices.
  ///
  /// In en, this message translates to:
  /// **'{day}, {count, plural, one{{count} window chosen} other{{count} windows chosen}}'**
  String clientPlannerRequestDayWithChoices(String day, int count);

  /// No description provided for @clientPlannerRequestWindowMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get clientPlannerRequestWindowMorning;

  /// No description provided for @clientPlannerRequestWindowAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get clientPlannerRequestWindowAfternoon;

  /// No description provided for @clientPlannerRequestWindowEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get clientPlannerRequestWindowEvening;

  /// No description provided for @clientPlannerRequestWindowsError.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get clientPlannerRequestWindowsError;

  /// No description provided for @clientPlannerRequestReachLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientPlannerRequestReachLabel;

  /// No description provided for @clientPlannerRequestReachChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get clientPlannerRequestReachChat;

  /// No description provided for @clientPlannerRequestReachWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get clientPlannerRequestReachWhatsapp;

  /// No description provided for @clientPlannerRequestReachPhone.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get clientPlannerRequestReachPhone;

  /// No description provided for @clientPlannerRequestNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get clientPlannerRequestNotesLabel;

  /// No description provided for @clientPlannerRequestSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientPlannerRequestSend;

  /// No description provided for @clientPlannerRequestSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientPlannerRequestSuccessTitle;

  /// No description provided for @clientPlannerRequestSentToast.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify you'**
  String get clientPlannerRequestSentToast;

  /// No description provided for @clientPlannerRequestOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Request open'**
  String get clientPlannerRequestOpenTitle;

  /// No description provided for @clientPlannerViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientPlannerViewRequest;

  /// No description provided for @clientPlannerStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Your planner'**
  String get clientPlannerStatusTitle;

  /// No description provided for @clientPlannerStatusHeadWaiting.
  ///
  /// In en, this message translates to:
  /// **'Finding your planner'**
  String get clientPlannerStatusHeadWaiting;

  /// No description provided for @clientPlannerStatusThreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Request progress'**
  String get clientPlannerStatusThreadLabel;

  /// No description provided for @clientPlannerStatusStepRequested.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientPlannerStatusStepRequested;

  /// No description provided for @clientPlannerStatusStepAssigned.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get clientPlannerStatusStepAssigned;

  /// No description provided for @clientPlannerStatusStepMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get clientPlannerStatusStepMeeting;

  /// No description provided for @clientPlannerStatusCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel request?'**
  String get clientPlannerStatusCancelTitle;

  /// No description provided for @clientPlannerStatusCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is lost.'**
  String get clientPlannerStatusCancelBody;

  /// No description provided for @clientPlannerStatusCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientPlannerStatusCancelConfirm;

  /// No description provided for @clientPlannerStatusCancelKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get clientPlannerStatusCancelKeep;

  /// No description provided for @clientPlannerStatusCancelledToast.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get clientPlannerStatusCancelledToast;

  /// No description provided for @clientPlannerStatusSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get clientPlannerStatusSchedule;

  /// No description provided for @clientPlannerStatusMessageName.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String clientPlannerStatusMessageName(String name);

  /// No description provided for @clientPlannerStatusMeetingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next meeting'**
  String get clientPlannerStatusMeetingLabel;

  /// No description provided for @clientPlannerStatusAddToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to calendar'**
  String get clientPlannerStatusAddToCalendar;

  /// No description provided for @clientPlannerStatusCalendarToast.
  ///
  /// In en, this message translates to:
  /// **'Added to calendar'**
  String get clientPlannerStatusCalendarToast;

  /// No description provided for @clientPlannerStatusAssignedToast.
  ///
  /// In en, this message translates to:
  /// **'{name} assigned'**
  String clientPlannerStatusAssignedToast(String name);

  /// No description provided for @clientPlannerTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get clientPlannerTypeVideo;

  /// No description provided for @clientPlannerTypePhone.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get clientPlannerTypePhone;

  /// No description provided for @clientPlannerTypeVideoName.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get clientPlannerTypeVideoName;

  /// No description provided for @clientPlannerTypePhoneName.
  ///
  /// In en, this message translates to:
  /// **'Phone call'**
  String get clientPlannerTypePhoneName;

  /// No description provided for @clientPlannerMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule meeting'**
  String get clientPlannerMeetingTitle;

  /// No description provided for @clientPlannerMeetingDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get clientPlannerMeetingDayLabel;

  /// No description provided for @clientPlannerMeetingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clientPlannerMeetingTimeLabel;

  /// No description provided for @clientPlannerMeetingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Meeting type'**
  String get clientPlannerMeetingTypeLabel;

  /// No description provided for @clientPlannerMeetingDayNoSlots.
  ///
  /// In en, this message translates to:
  /// **'{day}, no free times'**
  String clientPlannerMeetingDayNoSlots(String day);

  /// No description provided for @clientPlannerMeetingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientPlannerMeetingConfirm;

  /// No description provided for @clientPlannerMeetingNoSlotsTitle.
  ///
  /// In en, this message translates to:
  /// **'No free times'**
  String get clientPlannerMeetingNoSlotsTitle;

  /// No description provided for @clientPlannerMeetingTaken.
  ///
  /// In en, this message translates to:
  /// **'Time taken'**
  String get clientPlannerMeetingTaken;

  /// No description provided for @clientPlannerMeetingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Meeting set'**
  String get clientPlannerMeetingSuccessTitle;

  /// No description provided for @clientPlannerMeetingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get clientPlannerMeetingCalendar;

  /// No description provided for @clientProfileSharedVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String clientProfileSharedVersion(String version);

  /// No description provided for @clientProfileSharedOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get clientProfileSharedOn;

  /// No description provided for @clientProfileSharedOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get clientProfileSharedOff;

  /// No description provided for @clientProfileSharedKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep account'**
  String get clientProfileSharedKeep;

  /// No description provided for @clientProfileSharedSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientProfileSharedSupport;

  /// No description provided for @clientProfileSharedTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get clientProfileSharedTerms;

  /// No description provided for @clientProfileSharedPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get clientProfileSharedPrivacy;

  /// No description provided for @clientProfileSharedSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientProfileSharedSignIn;

  /// No description provided for @clientProfileSharedSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get clientProfileSharedSignOut;

  /// No description provided for @clientProfileSharedSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get clientProfileSharedSignOutTitle;

  /// No description provided for @clientProfileSharedSignOutStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get clientProfileSharedSignOutStay;

  /// No description provided for @clientProfileSharedSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get clientProfileSharedSignedOut;

  /// No description provided for @clientProfileSharedOpeningSettings.
  ///
  /// In en, this message translates to:
  /// **'Opening settings'**
  String get clientProfileSharedOpeningSettings;

  /// No description provided for @clientProfileSharedSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save'**
  String get clientProfileSharedSaveFailed;

  /// No description provided for @clientProfileHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get clientProfileHubTitle;

  /// No description provided for @clientProfileHubAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get clientProfileHubAccount;

  /// No description provided for @clientProfileHubVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get clientProfileHubVerified;

  /// No description provided for @clientProfileHubRowWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get clientProfileHubRowWedding;

  /// No description provided for @clientProfileHubRowBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get clientProfileHubRowBookings;

  /// No description provided for @clientProfileHubRowVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get clientProfileHubRowVouchers;

  /// No description provided for @clientProfileHubRowVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get clientProfileHubRowVisits;

  /// No description provided for @clientProfileHubRowReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get clientProfileHubRowReceipts;

  /// No description provided for @clientProfileHubRowSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientProfileHubRowSaved;

  /// No description provided for @clientProfileHubRowPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get clientProfileHubRowPersonal;

  /// No description provided for @clientProfileHubRowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientProfileHubRowNotifications;

  /// No description provided for @clientProfileHubCountPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get clientProfileHubCountPaid;

  /// No description provided for @clientProfileHubCountReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get clientProfileHubCountReady;

  /// No description provided for @clientProfileHubCountUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get clientProfileHubCountUpcoming;

  /// No description provided for @clientProfileHubCountHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get clientProfileHubCountHalls;

  /// No description provided for @clientProfileDigitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get clientProfileDigitsTitle;

  /// No description provided for @clientProfileLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy'**
  String get clientProfileLegalTitle;

  /// No description provided for @clientProfileWedTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding info'**
  String get clientProfileWedTitle;

  /// No description provided for @clientProfileWedRole.
  ///
  /// In en, this message translates to:
  /// **'I am'**
  String get clientProfileWedRole;

  /// No description provided for @clientProfileWedRoleBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get clientProfileWedRoleBride;

  /// No description provided for @clientProfileWedRoleGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get clientProfileWedRoleGroom;

  /// No description provided for @clientProfileWedRoleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get clientProfileWedRoleFamily;

  /// No description provided for @clientProfileWedRolePlanner.
  ///
  /// In en, this message translates to:
  /// **'Wedding planner'**
  String get clientProfileWedRolePlanner;

  /// No description provided for @clientProfileWedName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get clientProfileWedName;

  /// No description provided for @clientProfileWedPartnerDefault.
  ///
  /// In en, this message translates to:
  /// **'Partner’s name'**
  String get clientProfileWedPartnerDefault;

  /// No description provided for @clientProfileWedPartnerGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom’s name'**
  String get clientProfileWedPartnerGroom;

  /// No description provided for @clientProfileWedPartnerBride.
  ///
  /// In en, this message translates to:
  /// **'Bride’s name'**
  String get clientProfileWedPartnerBride;

  /// No description provided for @clientProfileWedPartnerCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple’s names'**
  String get clientProfileWedPartnerCouple;

  /// No description provided for @clientProfileWedDate.
  ///
  /// In en, this message translates to:
  /// **'Wedding date'**
  String get clientProfileWedDate;

  /// No description provided for @clientProfileWedCountdown.
  ///
  /// In en, this message translates to:
  /// **'Days to go'**
  String get clientProfileWedCountdown;

  /// No description provided for @clientProfileWedDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day} other{days}}'**
  String clientProfileWedDaysUnit(int count);

  /// No description provided for @clientProfileWedGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientProfileWedGuests;

  /// No description provided for @clientProfileWedLadies.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get clientProfileWedLadies;

  /// No description provided for @clientProfileWedMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get clientProfileWedMen;

  /// No description provided for @clientProfileWedBudget.
  ///
  /// In en, this message translates to:
  /// **'Venue and catering'**
  String get clientProfileWedBudget;

  /// No description provided for @clientProfileWedAreas.
  ///
  /// In en, this message translates to:
  /// **'Areas'**
  String get clientProfileWedAreas;

  /// No description provided for @clientProfileWedTotal.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get clientProfileWedTotal;

  /// No description provided for @clientProfileWedDiffersAction.
  ///
  /// In en, this message translates to:
  /// **'Use date'**
  String get clientProfileWedDiffersAction;

  /// No description provided for @clientProfileWedDateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Date updated'**
  String get clientProfileWedDateUpdated;

  /// No description provided for @clientProfilePersTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get clientProfilePersTitle;

  /// No description provided for @clientProfilePersName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get clientProfilePersName;

  /// No description provided for @clientProfilePersNameError.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get clientProfilePersNameError;

  /// No description provided for @clientProfilePersMonogram.
  ///
  /// In en, this message translates to:
  /// **'Monogram'**
  String get clientProfilePersMonogram;

  /// No description provided for @clientProfilePersEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientProfilePersEmail;

  /// No description provided for @clientProfilePersEmailError.
  ///
  /// In en, this message translates to:
  /// **'Check the email'**
  String get clientProfilePersEmailError;

  /// No description provided for @clientProfilePersPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get clientProfilePersPhone;

  /// No description provided for @clientProfilePersPhoneChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get clientProfilePersPhoneChange;

  /// No description provided for @clientProfilePersPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Venues and providers see your number only for requests you send them.'**
  String get clientProfilePersPhoneNote;

  /// No description provided for @clientProfilePersPhoneNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Your number'**
  String get clientProfilePersPhoneNoteTitle;

  /// No description provided for @clientProfilePersMethods.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientProfilePersMethods;

  /// No description provided for @clientProfilePersMethodWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get clientProfilePersMethodWhatsapp;

  /// No description provided for @clientProfilePersMethodApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get clientProfilePersMethodApple;

  /// No description provided for @clientProfilePersMethodGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get clientProfilePersMethodGoogle;

  /// No description provided for @clientProfilePersMethodHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden email'**
  String get clientProfilePersMethodHidden;

  /// No description provided for @clientProfilePersMethodLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get clientProfilePersMethodLinked;

  /// No description provided for @clientProfilePersMethodNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get clientProfilePersMethodNotLinked;

  /// No description provided for @clientProfilePhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get clientProfilePhoneTitle;

  /// No description provided for @clientProfilePhoneNew.
  ///
  /// In en, this message translates to:
  /// **'New number'**
  String get clientProfilePhoneNew;

  /// No description provided for @clientProfilePhoneSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get clientProfilePhoneSend;

  /// No description provided for @clientProfilePhoneErrorDigits.
  ///
  /// In en, this message translates to:
  /// **'Needs {count, plural, one{{count} digit} other{{count} digits}}'**
  String clientProfilePhoneErrorDigits(int count);

  /// No description provided for @clientProfilePhoneDone.
  ///
  /// In en, this message translates to:
  /// **'Number updated'**
  String get clientProfilePhoneDone;

  /// No description provided for @clientProfileNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get clientProfileNotifTitle;

  /// No description provided for @clientProfileNotifDenied.
  ///
  /// In en, this message translates to:
  /// **'Off on this phone'**
  String get clientProfileNotifDenied;

  /// No description provided for @clientProfileNotifGroupAlways.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get clientProfileNotifGroupAlways;

  /// No description provided for @clientProfileNotifRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get clientProfileNotifRequests;

  /// No description provided for @clientProfileNotifVouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get clientProfileNotifVouchers;

  /// No description provided for @clientProfileNotifVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get clientProfileNotifVisits;

  /// No description provided for @clientProfileNotifGroupReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get clientProfileNotifGroupReminders;

  /// No description provided for @clientProfileNotifConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm request'**
  String get clientProfileNotifConfirm;

  /// No description provided for @clientProfileNotifConfirmFact.
  ///
  /// In en, this message translates to:
  /// **'Time to confirm'**
  String get clientProfileNotifConfirmFact;

  /// No description provided for @clientProfileNotifVisitReminders.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get clientProfileNotifVisitReminders;

  /// No description provided for @clientProfileNotifVoucherExpiry.
  ///
  /// In en, this message translates to:
  /// **'Voucher ending'**
  String get clientProfileNotifVoucherExpiry;

  /// No description provided for @clientProfileNotifMilestones.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get clientProfileNotifMilestones;

  /// No description provided for @clientProfileNotifGroupMarketing.
  ///
  /// In en, this message translates to:
  /// **'Offers and news'**
  String get clientProfileNotifGroupMarketing;

  /// No description provided for @clientProfileNotifOffers.
  ///
  /// In en, this message translates to:
  /// **'Venue offers'**
  String get clientProfileNotifOffers;

  /// No description provided for @clientProfileNotifPriceDrops.
  ///
  /// In en, this message translates to:
  /// **'Price drops'**
  String get clientProfileNotifPriceDrops;

  /// No description provided for @clientProfileNotifNewVenues.
  ///
  /// In en, this message translates to:
  /// **'New halls'**
  String get clientProfileNotifNewVenues;

  /// No description provided for @clientProfileNotifFrequencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get clientProfileNotifFrequencyTitle;

  /// No description provided for @clientProfileNotifFrequency.
  ///
  /// In en, this message translates to:
  /// **'At most {count, plural, one{{count} message} other{{count} messages}} a week, and none in the final {days, plural, one{{days} day} other{{days} days}} before your wedding.'**
  String clientProfileNotifFrequency(int count, int days);

  /// No description provided for @clientProfileNotifChannels.
  ///
  /// In en, this message translates to:
  /// **'Send by'**
  String get clientProfileNotifChannels;

  /// No description provided for @clientProfileNotifChannelPush.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get clientProfileNotifChannelPush;

  /// No description provided for @clientProfileNotifChannelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get clientProfileNotifChannelWhatsapp;

  /// No description provided for @clientProfileNotifChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get clientProfileNotifChannelEmail;

  /// No description provided for @clientProfileNotifChannelEmailAdd.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get clientProfileNotifChannelEmailAdd;

  /// No description provided for @clientProfileNotifQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get clientProfileNotifQuiet;

  /// No description provided for @clientProfileNotifQuietOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get clientProfileNotifQuietOffers;

  /// No description provided for @clientProfileNotifQuietAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get clientProfileNotifQuietAlerts;

  /// No description provided for @clientProfileNotifPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get clientProfileNotifPhone;

  /// No description provided for @clientProfileSetBiometric.
  ///
  /// In en, this message translates to:
  /// **'{method, select, face{Face ID} touch{Touch ID} other{Fingerprint}}'**
  String clientProfileSetBiometric(String method);

  /// No description provided for @clientProfileSetBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Set up in phone settings'**
  String get clientProfileSetBiometricHint;

  /// No description provided for @clientProfileSetBiometricOff.
  ///
  /// In en, this message translates to:
  /// **'Turned off'**
  String get clientProfileSetBiometricOff;

  /// No description provided for @clientProfileSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientProfileSetLocation;

  /// No description provided for @clientProfileSetLocationValue.
  ///
  /// In en, this message translates to:
  /// **'While using'**
  String get clientProfileSetLocationValue;

  /// No description provided for @clientProfileSetUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage data'**
  String get clientProfileSetUsage;

  /// No description provided for @clientProfileSetUsageDetail.
  ///
  /// In en, this message translates to:
  /// **'Helps us improve Ghazal. Never includes payment details.'**
  String get clientProfileSetUsageDetail;

  /// No description provided for @clientProfileDelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get clientProfileDelTitle;

  /// No description provided for @clientProfileDelItemData.
  ///
  /// In en, this message translates to:
  /// **'Personal data'**
  String get clientProfileDelItemData;

  /// No description provided for @clientProfileDelItemPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get clientProfileDelItemPlans;

  /// No description provided for @clientProfileDelOutAnonymised.
  ///
  /// In en, this message translates to:
  /// **'Anonymised'**
  String get clientProfileDelOutAnonymised;

  /// No description provided for @clientProfileDelOutKept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get clientProfileDelOutKept;

  /// No description provided for @clientProfileDelOutRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get clientProfileDelOutRemoved;

  /// No description provided for @clientProfileDelOutWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get clientProfileDelOutWithdrawn;

  /// No description provided for @clientProfileDelDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens'**
  String get clientProfileDelDetailTitle;

  /// No description provided for @clientProfileDelSheetData.
  ///
  /// In en, this message translates to:
  /// **'Your personal data is anonymised.'**
  String get clientProfileDelSheetData;

  /// No description provided for @clientProfileDelSheetReceipts.
  ///
  /// In en, this message translates to:
  /// **'Voucher receipts and ledger records are kept, as the law requires.'**
  String get clientProfileDelSheetReceipts;

  /// No description provided for @clientProfileDelSheetSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved halls, checklist and budget are removed.'**
  String get clientProfileDelSheetSaved;

  /// No description provided for @clientProfileDelSheetApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple access is revoked.'**
  String get clientProfileDelSheetApple;

  /// No description provided for @clientProfileDelSheetRequest.
  ///
  /// In en, this message translates to:
  /// **'Your pending request to {venue} will be withdrawn, and its voucher ends with your account.'**
  String clientProfileDelSheetRequest(String venue);

  /// No description provided for @clientProfileDelVoucher.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Voucher ready} other{{count} vouchers ready}}'**
  String clientProfileDelVoucher(int count);

  /// No description provided for @clientProfileDelVoucherRefund.
  ///
  /// In en, this message translates to:
  /// **'Use voucher'**
  String get clientProfileDelVoucherRefund;

  /// No description provided for @clientProfileDelVoucherDetailRefund.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You have a voucher ready. Use it first: once your account is deleted it ends and does not come back.} other{You have {count} vouchers ready. Use them first: once your account is deleted they end and do not come back.}}'**
  String clientProfileDelVoucherDetailRefund(int count);

  /// No description provided for @clientProfileDelVoucherDetailEnds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{You have a voucher ready. It ends with your account, so use it first if you still need it.} other{You have {count} vouchers ready. They end with your account, so use them first if you still need them.}}'**
  String clientProfileDelVoucherDetailEnds(int count);

  /// No description provided for @clientProfileDelUndone.
  ///
  /// In en, this message translates to:
  /// **'Can’t be undone'**
  String get clientProfileDelUndone;

  /// No description provided for @clientProfileDelDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get clientProfileDelDeleting;

  /// No description provided for @clientProfileDelSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get clientProfileDelSuccessTitle;

  /// No description provided for @clientProfileDelSuccessDetail.
  ///
  /// In en, this message translates to:
  /// **'Your personal data is anonymised. Receipts are kept as the law requires. You can create a new account any time.'**
  String get clientProfileDelSuccessDetail;

  /// No description provided for @clientProfileDelErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t delete'**
  String get clientProfileDelErrorTitle;

  /// No description provided for @clientProfileDelErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'Nothing was changed. Try again, or contact Support.'**
  String get clientProfileDelErrorDetail;

  /// No description provided for @clientProfileDelBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion paused'**
  String get clientProfileDelBlockedTitle;

  /// No description provided for @clientProfileDelBlockedDetail.
  ///
  /// In en, this message translates to:
  /// **'Deletion is paused while your booking at {venue} on {date} is confirmed. Cancel it, or request deletion after the event.'**
  String clientProfileDelBlockedDetail(String venue, String date);

  /// No description provided for @clientProfileDelBlockedApprovedDetail.
  ///
  /// In en, this message translates to:
  /// **'Deletion is paused while {venue} is waiting for you to confirm the approved request. Confirm it or cancel it first.'**
  String clientProfileDelBlockedApprovedDetail(String venue);

  /// No description provided for @clientProfileDelBlockedSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule deletion'**
  String get clientProfileDelBlockedSchedule;

  /// No description provided for @clientProfileDelBlockedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open request'**
  String get clientProfileDelBlockedOpen;

  /// No description provided for @clientProfileDelBlockedCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get clientProfileDelBlockedCancel;

  /// No description provided for @clientProfileDelBlockedCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get clientProfileDelBlockedCancelRequest;

  /// No description provided for @clientProfileDelScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion scheduled'**
  String get clientProfileDelScheduledTitle;

  /// No description provided for @clientProfileDelScheduledCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion'**
  String get clientProfileDelScheduledCancel;

  /// No description provided for @clientProfileDelScheduledCancelled.
  ///
  /// In en, this message translates to:
  /// **'Deletion cancelled'**
  String get clientProfileDelScheduledCancelled;

  /// No description provided for @clientReviewsRewardsStarCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} star} other{{count} stars}}'**
  String clientReviewsRewardsStarCount(int count);

  /// No description provided for @clientReviewsRewardsStarsAndBelow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} star and below} other{{count} stars and below}}'**
  String clientReviewsRewardsStarsAndBelow(int count);

  /// No description provided for @clientReviewsRewardsAudienceWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies’ reception'**
  String get clientReviewsRewardsAudienceWomen;

  /// No description provided for @clientReviewsRewardsAudienceMen.
  ///
  /// In en, this message translates to:
  /// **'Men’s reception'**
  String get clientReviewsRewardsAudienceMen;

  /// No description provided for @clientReviewsRewardsAudienceMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed reception'**
  String get clientReviewsRewardsAudienceMixed;

  /// No description provided for @clientReviewsRewardsRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientReviewsRewardsRating;

  /// No description provided for @clientReviewsRewardsGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get clientReviewsRewardsGuest;

  /// No description provided for @clientReviewsRewardsInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get clientReviewsRewardsInReview;

  /// No description provided for @clientReviewsRewardsOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens {date}'**
  String clientReviewsRewardsOpens(String date);

  /// No description provided for @clientReviewsRewardsOpensName.
  ///
  /// In en, this message translates to:
  /// **'Reviews open after your event on {date}.'**
  String clientReviewsRewardsOpensName(String date);

  /// No description provided for @clientReviewsRewardsShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get clientReviewsRewardsShowMore;

  /// No description provided for @clientReviewsRewardsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get clientReviewsRewardsListTitle;

  /// No description provided for @clientReviewsRewardsListWrite.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get clientReviewsRewardsListWrite;

  /// No description provided for @clientReviewsRewardsListEvent.
  ///
  /// In en, this message translates to:
  /// **'Your event'**
  String get clientReviewsRewardsListEvent;

  /// No description provided for @clientReviewsRewardsListSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientReviewsRewardsListSignIn;

  /// No description provided for @clientReviewsRewardsListSignInName.
  ///
  /// In en, this message translates to:
  /// **'to review your event'**
  String get clientReviewsRewardsListSignInName;

  /// No description provided for @clientReviewsRewardsListInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified reviews'**
  String get clientReviewsRewardsListInfoTitle;

  /// No description provided for @clientReviewsRewardsListInfoReal.
  ///
  /// In en, this message translates to:
  /// **'Only guests with a completed booking can review.'**
  String get clientReviewsRewardsListInfoReal;

  /// No description provided for @clientReviewsRewardsListInfoVenue.
  ///
  /// In en, this message translates to:
  /// **'Venues reply once. They cannot edit or remove reviews.'**
  String get clientReviewsRewardsListInfoVenue;

  /// No description provided for @clientReviewsRewardsListInfoNew.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review after your event.'**
  String get clientReviewsRewardsListInfoNew;

  /// No description provided for @clientReviewsRewardsListFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter reviews'**
  String get clientReviewsRewardsListFilterLabel;

  /// No description provided for @clientReviewsRewardsListFilterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientReviewsRewardsListFilterPhotos;

  /// No description provided for @clientReviewsRewardsListSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get clientReviewsRewardsListSortRecent;

  /// No description provided for @clientReviewsRewardsListSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get clientReviewsRewardsListSortHighest;

  /// No description provided for @clientReviewsRewardsListSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get clientReviewsRewardsListSortLowest;

  /// No description provided for @clientReviewsRewardsListSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get clientReviewsRewardsListSortTitle;

  /// No description provided for @clientReviewsRewardsListMore.
  ///
  /// In en, this message translates to:
  /// **'More options for this review'**
  String get clientReviewsRewardsListMore;

  /// No description provided for @clientReviewsRewardsListMoreReviews.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get clientReviewsRewardsListMoreReviews;

  /// No description provided for @clientReviewsRewardsListVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified booking'**
  String get clientReviewsRewardsListVerified;

  /// No description provided for @clientReviewsRewardsListReplyFrom.
  ///
  /// In en, this message translates to:
  /// **'Reply from {venue}'**
  String clientReviewsRewardsListReplyFrom(String venue);

  /// No description provided for @clientReviewsRewardsListReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get clientReviewsRewardsListReportTitle;

  /// No description provided for @clientReviewsRewardsListReasonAbusive.
  ///
  /// In en, this message translates to:
  /// **'Abusive'**
  String get clientReviewsRewardsListReasonAbusive;

  /// No description provided for @clientReviewsRewardsListReasonNotVenue.
  ///
  /// In en, this message translates to:
  /// **'Not this venue'**
  String get clientReviewsRewardsListReasonNotVenue;

  /// No description provided for @clientReviewsRewardsListReasonPeople.
  ///
  /// In en, this message translates to:
  /// **'Shows people'**
  String get clientReviewsRewardsListReasonPeople;

  /// No description provided for @clientReviewsRewardsListReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientReviewsRewardsListReasonOther;

  /// No description provided for @clientReviewsRewardsListReportReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get clientReviewsRewardsListReportReason;

  /// No description provided for @clientReviewsRewardsListReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get clientReviewsRewardsListReportSent;

  /// No description provided for @clientReviewsRewardsListReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get clientReviewsRewardsListReported;

  /// No description provided for @clientReviewsRewardsWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get clientReviewsRewardsWriteTitle;

  /// No description provided for @clientReviewsRewardsWritePrompt.
  ///
  /// In en, this message translates to:
  /// **'How was {venue}?'**
  String clientReviewsRewardsWritePrompt(String venue);

  /// No description provided for @clientReviewsRewardsWriteOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get clientReviewsRewardsWriteOverall;

  /// No description provided for @clientReviewsRewardsWriteStar1.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get clientReviewsRewardsWriteStar1;

  /// No description provided for @clientReviewsRewardsWriteStar2.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get clientReviewsRewardsWriteStar2;

  /// No description provided for @clientReviewsRewardsWriteStar3.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get clientReviewsRewardsWriteStar3;

  /// No description provided for @clientReviewsRewardsWriteStar4.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get clientReviewsRewardsWriteStar4;

  /// No description provided for @clientReviewsRewardsWriteStar5.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get clientReviewsRewardsWriteStar5;

  /// No description provided for @clientReviewsRewardsWriteCatVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientReviewsRewardsWriteCatVenue;

  /// No description provided for @clientReviewsRewardsWriteCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get clientReviewsRewardsWriteCatFood;

  /// No description provided for @clientReviewsRewardsWriteCatService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get clientReviewsRewardsWriteCatService;

  /// No description provided for @clientReviewsRewardsWriteCatValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get clientReviewsRewardsWriteCatValue;

  /// No description provided for @clientReviewsRewardsWriteTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get clientReviewsRewardsWriteTextLabel;

  /// No description provided for @clientReviewsRewardsWriteMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientReviewsRewardsWriteMediaTitle;

  /// No description provided for @clientReviewsRewardsWriteMediaNoPeople.
  ///
  /// In en, this message translates to:
  /// **'No people'**
  String get clientReviewsRewardsWriteMediaNoPeople;

  /// No description provided for @clientReviewsRewardsWriteMediaInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Review rules'**
  String get clientReviewsRewardsWriteMediaInfoTitle;

  /// No description provided for @clientReviewsRewardsWriteMediaRule.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos showing people can’t be published.'**
  String get clientReviewsRewardsWriteMediaRule;

  /// No description provided for @clientReviewsRewardsWriteMediaAllowed.
  ///
  /// In en, this message translates to:
  /// **'The hall, décor, food and details are welcome.'**
  String get clientReviewsRewardsWriteMediaAllowed;

  /// No description provided for @clientReviewsRewardsWriteMediaChecked.
  ///
  /// In en, this message translates to:
  /// **'Reviews are checked before they appear. Photos wait for our team and only you see them.'**
  String get clientReviewsRewardsWriteMediaChecked;

  /// No description provided for @clientReviewsRewardsWriteMediaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo or video'**
  String get clientReviewsRewardsWriteMediaAdd;

  /// No description provided for @clientReviewsRewardsWriteMediaUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get clientReviewsRewardsWriteMediaUploading;

  /// No description provided for @clientReviewsRewardsWriteMediaRejected.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get clientReviewsRewardsWriteMediaRejected;

  /// No description provided for @clientReviewsRewardsWriteMediaRejectedNote.
  ///
  /// In en, this message translates to:
  /// **'This photo can’t be published because it shows people. Remove it, or add another.'**
  String get clientReviewsRewardsWriteMediaRejectedNote;

  /// No description provided for @clientReviewsRewardsWriteMediaRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo'**
  String get clientReviewsRewardsWriteMediaRemove;

  /// No description provided for @clientReviewsRewardsWriteNameHide.
  ///
  /// In en, this message translates to:
  /// **'Hide name'**
  String get clientReviewsRewardsWriteNameHide;

  /// No description provided for @clientReviewsRewardsWriteSubmitReason.
  ///
  /// In en, this message translates to:
  /// **'Add a rating'**
  String get clientReviewsRewardsWriteSubmitReason;

  /// No description provided for @clientReviewsRewardsWriteOffline.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Draft saved.'**
  String get clientReviewsRewardsWriteOffline;

  /// No description provided for @clientReviewsRewardsWriteOfflineReason.
  ///
  /// In en, this message translates to:
  /// **'Connect to send'**
  String get clientReviewsRewardsWriteOfflineReason;

  /// No description provided for @clientReviewsRewardsWriteError.
  ///
  /// In en, this message translates to:
  /// **'Not sent. Draft saved.'**
  String get clientReviewsRewardsWriteError;

  /// No description provided for @clientReviewsRewardsWriteLockedAction.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get clientReviewsRewardsWriteLockedAction;

  /// No description provided for @clientReviewsRewardsWriteDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get clientReviewsRewardsWriteDoneTitle;

  /// No description provided for @clientReviewsRewardsWriteDoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Appears after a quick check'**
  String get clientReviewsRewardsWriteDoneHelper;

  /// No description provided for @clientReviewsRewardsWriteDoneSee.
  ///
  /// In en, this message translates to:
  /// **'See reviews'**
  String get clientReviewsRewardsWriteDoneSee;

  /// No description provided for @clientReviewsRewardsWriteAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Already reviewed'**
  String get clientReviewsRewardsWriteAlreadyTitle;

  /// No description provided for @clientSavedCompareSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientSavedCompareSavedTitle;

  /// No description provided for @clientSavedCompareSavedTabsLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved items'**
  String get clientSavedCompareSavedTabsLabel;

  /// No description provided for @clientSavedCompareSavedSummaryFree.
  ///
  /// In en, this message translates to:
  /// **'{free} of {total} halls free on {date}'**
  String clientSavedCompareSavedSummaryFree(num free, num total, String date);

  /// No description provided for @clientSavedCompareSavedSummaryOneFree.
  ///
  /// In en, this message translates to:
  /// **'Free on {date}'**
  String clientSavedCompareSavedSummaryOneFree(String date);

  /// No description provided for @clientSavedCompareSavedSummaryOneBusy.
  ///
  /// In en, this message translates to:
  /// **'Not free on {date}'**
  String clientSavedCompareSavedSummaryOneBusy(String date);

  /// No description provided for @clientSavedCompareSavedSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get clientSavedCompareSavedSelect;

  /// No description provided for @clientSavedCompareSavedSelectNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Select at least two'**
  String get clientSavedCompareSavedSelectNeedTwo;

  /// No description provided for @clientSavedCompareSavedSelectRow.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String clientSavedCompareSavedSelectRow(String name);

  /// No description provided for @clientSavedCompareSavedDeselectRow.
  ///
  /// In en, this message translates to:
  /// **'Deselect {name}'**
  String clientSavedCompareSavedDeselectRow(String name);

  /// No description provided for @clientSavedCompareSavedAvailFree.
  ///
  /// In en, this message translates to:
  /// **'Still free on {date}'**
  String clientSavedCompareSavedAvailFree(String date);

  /// No description provided for @clientSavedCompareSavedAvailHeld.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get clientSavedCompareSavedAvailHeld;

  /// No description provided for @clientSavedCompareSavedAvailBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked on {date}'**
  String clientSavedCompareSavedAvailBooked(String date);

  /// No description provided for @clientSavedCompareSavedSavingChanged.
  ///
  /// In en, this message translates to:
  /// **'Saving changed'**
  String get clientSavedCompareSavedSavingChanged;

  /// No description provided for @clientSavedCompareSavedVoucherReadyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open your voucher for {name}'**
  String clientSavedCompareSavedVoucherReadyOpen(String name);

  /// No description provided for @clientSavedCompareSavedUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Unlisted'**
  String get clientSavedCompareSavedUnlisted;

  /// No description provided for @clientSavedCompareSavedRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get clientSavedCompareSavedRemoved;

  /// No description provided for @clientSavedCompareSavedGuestBanner.
  ///
  /// In en, this message translates to:
  /// **'This phone only'**
  String get clientSavedCompareSavedGuestBanner;

  /// No description provided for @clientSavedCompareSavedGuestSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientSavedCompareSavedGuestSignIn;

  /// No description provided for @clientSavedCompareLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get clientSavedCompareLastUpdated;

  /// No description provided for @clientSavedCompareSavedEmptyVenuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No halls saved'**
  String get clientSavedCompareSavedEmptyVenuesTitle;

  /// No description provided for @clientSavedCompareSavedEmptyVenuesAction.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientSavedCompareSavedEmptyVenuesAction;

  /// No description provided for @clientSavedCompareSavedEmptyServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No services saved'**
  String get clientSavedCompareSavedEmptyServicesTitle;

  /// No description provided for @clientSavedCompareSavedEmptyServicesAction.
  ///
  /// In en, this message translates to:
  /// **'Browse services'**
  String get clientSavedCompareSavedEmptyServicesAction;

  /// No description provided for @clientSavedCompareSavedEmptyPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No packages saved'**
  String get clientSavedCompareSavedEmptyPackagesTitle;

  /// No description provided for @clientSavedCompareSavedEmptyPackagesAction.
  ///
  /// In en, this message translates to:
  /// **'See packages'**
  String get clientSavedCompareSavedEmptyPackagesAction;

  /// No description provided for @clientSavedCompareSavedPlannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Wedding planner'**
  String get clientSavedCompareSavedPlannerLabel;

  /// No description provided for @clientSavedCompareSavedFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clientSavedCompareSavedFrom;

  /// No description provided for @clientSavedCompareFactGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientSavedCompareFactGuests;

  /// No description provided for @clientSavedCompareFactDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientSavedCompareFactDate;

  /// No description provided for @clientSavedCompareFactFreeHalls.
  ///
  /// In en, this message translates to:
  /// **'Halls free on your date'**
  String get clientSavedCompareFactFreeHalls;

  /// No description provided for @clientSavedCompareFactWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get clientSavedCompareFactWomen;

  /// No description provided for @clientSavedCompareFactMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get clientSavedCompareFactMen;

  /// No description provided for @clientSavedCompareFactMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get clientSavedCompareFactMixed;

  /// No description provided for @clientSavedCompareFactEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit your brief'**
  String get clientSavedCompareFactEdit;

  /// No description provided for @clientSavedCompareTrayTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get clientSavedCompareTrayTitle;

  /// No description provided for @clientSavedCompareTrayAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one more'**
  String get clientSavedCompareTrayAddOne;

  /// No description provided for @clientSavedCompareTrayAction.
  ///
  /// In en, this message translates to:
  /// **'Compare ({count})'**
  String clientSavedCompareTrayAction(num count);

  /// No description provided for @clientSavedCompareTrayRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from compare'**
  String clientSavedCompareTrayRemove(String name);

  /// No description provided for @clientSavedCompareTrayBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Your comparison is empty} one{Open your comparison, {count} hall} other{Open your comparison, {count} halls}}'**
  String clientSavedCompareTrayBadge(int count);

  /// No description provided for @clientSavedCompareReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace which one?'**
  String get clientSavedCompareReplaceTitle;

  /// No description provided for @clientSavedCompareReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'You can compare up to {max} halls. Choose the one {name} will replace.'**
  String clientSavedCompareReplaceBody(num max, String name);

  /// No description provided for @clientSavedCompareReplaceDone.
  ///
  /// In en, this message translates to:
  /// **'Comparison updated'**
  String get clientSavedCompareReplaceDone;

  /// No description provided for @clientSavedCompareCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get clientSavedCompareCompareTitle;

  /// No description provided for @clientSavedCompareCompareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get clientSavedCompareCompareLinkCopied;

  /// No description provided for @clientSavedCompareCompareRowAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get clientSavedCompareCompareRowAvailability;

  /// No description provided for @clientSavedCompareCompareRowPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientSavedCompareCompareRowPrice;

  /// No description provided for @clientSavedCompareCompareRowPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'From price'**
  String get clientSavedCompareCompareRowPriceFrom;

  /// No description provided for @clientSavedCompareCompareRowCapacity.
  ///
  /// In en, this message translates to:
  /// **'Largest hall holds'**
  String get clientSavedCompareCompareRowCapacity;

  /// No description provided for @clientSavedCompareCompareRowSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get clientSavedCompareCompareRowSetting;

  /// No description provided for @clientSavedCompareCompareRowValet.
  ///
  /// In en, this message translates to:
  /// **'Valet'**
  String get clientSavedCompareCompareRowValet;

  /// No description provided for @clientSavedCompareCompareRowParking.
  ///
  /// In en, this message translates to:
  /// **'Free parking'**
  String get clientSavedCompareCompareRowParking;

  /// No description provided for @clientSavedCompareCompareRowBridal.
  ///
  /// In en, this message translates to:
  /// **'Bridal suite'**
  String get clientSavedCompareCompareRowBridal;

  /// No description provided for @clientSavedCompareCompareRowBuffet.
  ///
  /// In en, this message translates to:
  /// **'Buffet'**
  String get clientSavedCompareCompareRowBuffet;

  /// No description provided for @clientSavedCompareCompareRowPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get clientSavedCompareCompareRowPhotography;

  /// No description provided for @clientSavedCompareCompareRowRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientSavedCompareCompareRowRating;

  /// No description provided for @clientSavedCompareCompareRowDistance.
  ///
  /// In en, this message translates to:
  /// **'Drive from {origin}'**
  String clientSavedCompareCompareRowDistance(String origin);

  /// No description provided for @clientSavedCompareCompareDriveMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String clientSavedCompareCompareDriveMinutes(num minutes);

  /// No description provided for @clientSavedCompareCompareRowPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get clientSavedCompareCompareRowPackages;

  /// No description provided for @clientSavedCompareCompareRowHow.
  ///
  /// In en, this message translates to:
  /// **'Booking channel'**
  String get clientSavedCompareCompareRowHow;

  /// No description provided for @clientSavedCompareCompareRowPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientSavedCompareCompareRowPhotos;

  /// No description provided for @clientSavedCompareCompareValHowVoucher.
  ///
  /// In en, this message translates to:
  /// **'With voucher'**
  String get clientSavedCompareCompareValHowVoucher;

  /// No description provided for @clientSavedCompareCompareValHowStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard only'**
  String get clientSavedCompareCompareValHowStandard;

  /// No description provided for @clientSavedCompareCompareValHowOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official channel'**
  String get clientSavedCompareCompareValHowOfficial;

  /// No description provided for @clientSavedCompareCompareValIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get clientSavedCompareCompareValIncluded;

  /// No description provided for @clientSavedCompareCompareValExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra cost'**
  String get clientSavedCompareCompareValExtra;

  /// No description provided for @clientSavedCompareCompareValNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get clientSavedCompareCompareValNotOffered;

  /// No description provided for @clientSavedCompareCompareValIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get clientSavedCompareCompareValIndoor;

  /// No description provided for @clientSavedCompareCompareValOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get clientSavedCompareCompareValOutdoor;

  /// No description provided for @clientSavedCompareCompareValWomenOnly.
  ///
  /// In en, this message translates to:
  /// **'Female only'**
  String get clientSavedCompareCompareValWomenOnly;

  /// No description provided for @clientSavedCompareCompareValAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get clientSavedCompareCompareValAllowed;

  /// No description provided for @clientSavedCompareCompareValNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get clientSavedCompareCompareValNotAllowed;

  /// No description provided for @clientSavedCompareCompareValBelow.
  ///
  /// In en, this message translates to:
  /// **'Below your guests'**
  String get clientSavedCompareCompareValBelow;

  /// No description provided for @clientSavedCompareCompareValFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clientSavedCompareCompareValFrom;

  /// No description provided for @clientSavedCompareCompareShowPackages.
  ///
  /// In en, this message translates to:
  /// **'Show packages'**
  String get clientSavedCompareCompareShowPackages;

  /// No description provided for @clientSavedCompareCompareHidePackages.
  ///
  /// In en, this message translates to:
  /// **'Hide packages'**
  String get clientSavedCompareCompareHidePackages;

  /// No description provided for @clientSavedCompareCompareBadgeRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get clientSavedCompareCompareBadgeRated;

  /// No description provided for @clientSavedCompareCompareBadgeLowest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get clientSavedCompareCompareBadgeLowest;

  /// No description provided for @clientSavedCompareCompareBadgeClosest.
  ///
  /// In en, this message translates to:
  /// **'Closest'**
  String get clientSavedCompareCompareBadgeClosest;

  /// No description provided for @clientSavedCompareCompareActionVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientSavedCompareCompareActionVoucher;

  /// No description provided for @clientSavedCompareCompareActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientSavedCompareCompareActionView;

  /// No description provided for @clientSavedCompareCompareActionDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get clientSavedCompareCompareActionDates;

  /// No description provided for @clientSavedCompareCompareActionOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get clientSavedCompareCompareActionOfficial;

  /// No description provided for @clientSavedCompareCompareActionFor.
  ///
  /// In en, this message translates to:
  /// **'{action}: {name}'**
  String clientSavedCompareCompareActionFor(String action, String name);

  /// No description provided for @clientSavedCompareCompareOpen.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String clientSavedCompareCompareOpen(String name);

  /// No description provided for @clientSavedCompareComparePick.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String clientSavedCompareComparePick(String name);

  /// No description provided for @clientSavedCompareCompareUnpick.
  ///
  /// In en, this message translates to:
  /// **'Chosen: {name}'**
  String clientSavedCompareCompareUnpick(String name);

  /// No description provided for @clientSavedCompareComparePicked.
  ///
  /// In en, this message translates to:
  /// **'{name} is your choice.'**
  String clientSavedCompareComparePicked(String name);

  /// No description provided for @clientSavedCompareCompareSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get clientSavedCompareCompareSetDate;

  /// No description provided for @clientSavedCompareCompareFewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a second hall'**
  String get clientSavedCompareCompareFewerTitle;

  /// No description provided for @clientSavedCompareCompareFewerAction.
  ///
  /// In en, this message translates to:
  /// **'Choose hall'**
  String get clientSavedCompareCompareFewerAction;

  /// No description provided for @clientSavedCompareCompareDiffLabel.
  ///
  /// In en, this message translates to:
  /// **'Rows shown'**
  String get clientSavedCompareCompareDiffLabel;

  /// No description provided for @clientSavedCompareCompareDiffOnly.
  ///
  /// In en, this message translates to:
  /// **'Differences'**
  String get clientSavedCompareCompareDiffOnly;

  /// No description provided for @clientSavedCompareCompareDiffAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get clientSavedCompareCompareDiffAll;

  /// No description provided for @clientSavedCompareKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get clientSavedCompareKeyTitle;

  /// No description provided for @clientSavedCompareKeyBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get clientSavedCompareKeyBest;

  /// No description provided for @clientSavedCompareKeySave.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get clientSavedCompareKeySave;

  /// No description provided for @clientSavedCompareCompareHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} matching row hidden} other{{count} matching rows hidden}}'**
  String clientSavedCompareCompareHidden(int count);

  /// No description provided for @clientServicesFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clientServicesFrom;

  /// No description provided for @clientServicesOpenName.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String clientServicesOpenName(String name);

  /// No description provided for @clientServicesArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get clientServicesArea;

  /// No description provided for @clientServicesProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get clientServicesProviders;

  /// No description provided for @clientServicesSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get clientServicesSoon;

  /// No description provided for @clientServicesVoucherAvailable.
  ///
  /// In en, this message translates to:
  /// **'Voucher prices available'**
  String get clientServicesVoucherAvailable;

  /// No description provided for @clientServicesSavedView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientServicesSavedView;

  /// No description provided for @clientServicesRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientServicesRequestSent;

  /// No description provided for @clientServicesReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to continue'**
  String get clientServicesReconnect;

  /// No description provided for @clientServicesHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get clientServicesHowTitle;

  /// No description provided for @clientServicesUnitEvent.
  ///
  /// In en, this message translates to:
  /// **'/event'**
  String get clientServicesUnitEvent;

  /// No description provided for @clientServicesUnitCake.
  ///
  /// In en, this message translates to:
  /// **'/cake'**
  String get clientServicesUnitCake;

  /// No description provided for @clientServicesUnitSession.
  ///
  /// In en, this message translates to:
  /// **'/session'**
  String get clientServicesUnitSession;

  /// No description provided for @clientServicesUnitDress.
  ///
  /// In en, this message translates to:
  /// **'/dress'**
  String get clientServicesUnitDress;

  /// No description provided for @clientServicesUnitSuit.
  ///
  /// In en, this message translates to:
  /// **'/suit'**
  String get clientServicesUnitSuit;

  /// No description provided for @clientServicesUnitCard.
  ///
  /// In en, this message translates to:
  /// **'/card'**
  String get clientServicesUnitCard;

  /// No description provided for @clientServicesUnitBooking.
  ///
  /// In en, this message translates to:
  /// **'/booking'**
  String get clientServicesUnitBooking;

  /// No description provided for @clientServicesUnitPackage.
  ///
  /// In en, this message translates to:
  /// **'/package'**
  String get clientServicesUnitPackage;

  /// No description provided for @clientServicesHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get clientServicesHubTitle;

  /// No description provided for @clientServicesHubSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get clientServicesHubSwitchLabel;

  /// No description provided for @clientServicesHubGroupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get clientServicesHubGroupsLabel;

  /// No description provided for @clientServicesHubMoreHeading.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get clientServicesHubMoreHeading;

  /// No description provided for @clientServicesHubPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Wedding planner'**
  String get clientServicesHubPlannerTitle;

  /// No description provided for @clientServicesHubSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientServicesHubSavedTitle;

  /// No description provided for @clientServicesHubGovernmentNote.
  ///
  /// In en, this message translates to:
  /// **'Add catering and decor'**
  String get clientServicesHubGovernmentNote;

  /// No description provided for @clientServicesHubVoucherLine.
  ///
  /// In en, this message translates to:
  /// **'Get a {fee} Ghazal voucher on a provider’s page to unlock lower prices. You always pay the provider directly.'**
  String clientServicesHubVoucherLine(String fee);

  /// No description provided for @clientServicesListTitle.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get clientServicesListTitle;

  /// No description provided for @clientServicesListSiblings.
  ///
  /// In en, this message translates to:
  /// **'Related services'**
  String get clientServicesListSiblings;

  /// No description provided for @clientServicesListFemaleTeam.
  ///
  /// In en, this message translates to:
  /// **'Female team'**
  String get clientServicesListFemaleTeam;

  /// No description provided for @clientServicesListGridLabel.
  ///
  /// In en, this message translates to:
  /// **'Providers in {category}'**
  String clientServicesListGridLabel(String category);

  /// No description provided for @clientServicesListNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get clientServicesListNoResultsTitle;

  /// No description provided for @clientServicesListClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clientServicesListClear;

  /// No description provided for @clientServicesListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No providers yet'**
  String get clientServicesListEmptyTitle;

  /// No description provided for @clientServicesFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get clientServicesFilterTitle;

  /// No description provided for @clientServicesFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get clientServicesFilterLabel;

  /// No description provided for @clientServicesSheetSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get clientServicesSheetSortLabel;

  /// No description provided for @clientServicesSheetUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {price}'**
  String clientServicesSheetUpTo(String price);

  /// No description provided for @clientServicesSheetRatingAtLeast.
  ///
  /// In en, this message translates to:
  /// **'{rating}+'**
  String clientServicesSheetRatingAtLeast(String rating);

  /// No description provided for @clientServicesSheetShow.
  ///
  /// In en, this message translates to:
  /// **'Show {count}'**
  String clientServicesSheetShow(String count);

  /// No description provided for @clientServicesSortRecommended.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get clientServicesSortRecommended;

  /// No description provided for @clientServicesSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get clientServicesSortPrice;

  /// No description provided for @clientServicesSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get clientServicesSortRating;

  /// No description provided for @clientServicesProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get clientServicesProfileTitle;

  /// No description provided for @clientServicesProfileHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Portfolio photos of {name}'**
  String clientServicesProfileHeroLabel(String name);

  /// No description provided for @clientServicesProfileReply.
  ///
  /// In en, this message translates to:
  /// **'Replies within'**
  String get clientServicesProfileReply;

  /// No description provided for @clientServicesProfileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get clientServicesProfileVerified;

  /// No description provided for @clientServicesProfileEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get clientServicesProfileEventTitle;

  /// No description provided for @clientServicesProfileEventInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'The date'**
  String get clientServicesProfileEventInfoTitle;

  /// No description provided for @clientServicesProfileAvailabilityBody.
  ///
  /// In en, this message translates to:
  /// **'Availability is confirmed by the provider in chat.'**
  String get clientServicesProfileAvailabilityBody;

  /// No description provided for @clientServicesProfileEventNote.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is tied to this date and package.'**
  String get clientServicesProfileEventNote;

  /// No description provided for @clientServicesProfileAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get clientServicesProfileAsk;

  /// No description provided for @clientServicesProfilePackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get clientServicesProfilePackagesTitle;

  /// No description provided for @clientServicesProfilePackageChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String clientServicesProfilePackageChoose(String name);

  /// No description provided for @clientServicesProfilePackageChosen.
  ///
  /// In en, this message translates to:
  /// **'{name}, chosen'**
  String clientServicesProfilePackageChosen(String name);

  /// No description provided for @clientServicesProfileIncludes.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get clientServicesProfileIncludes;

  /// No description provided for @clientServicesProfileBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to budget'**
  String get clientServicesProfileBudgetTitle;

  /// No description provided for @clientServicesProfileReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get clientServicesProfileReviewsTitle;

  /// No description provided for @clientServicesProfileGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Get voucher'**
  String get clientServicesProfileGetVoucher;

  /// No description provided for @clientServicesProfileRequest.
  ///
  /// In en, this message translates to:
  /// **'Request quote'**
  String get clientServicesProfileRequest;

  /// No description provided for @clientServicesProfileOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get clientServicesProfileOpenChat;

  /// No description provided for @clientServicesHowRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientServicesHowRequestLabel;

  /// No description provided for @clientServicesHowSettleLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay provider'**
  String get clientServicesHowSettleLabel;

  /// No description provided for @clientServicesHowPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay {fee} online'**
  String clientServicesHowPayTitle(String fee);

  /// No description provided for @clientServicesHowPayBody.
  ///
  /// In en, this message translates to:
  /// **'Use KNET, a card, Apple Pay or Google Pay. The voucher is tied to this provider and package.'**
  String get clientServicesHowPayBody;

  /// No description provided for @clientServicesHowRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request at the voucher price'**
  String get clientServicesHowRequestTitle;

  /// No description provided for @clientServicesHowRequestBody.
  ///
  /// In en, this message translates to:
  /// **'The provider answers. After approval you have {hours} to confirm.'**
  String clientServicesHowRequestBody(String hours);

  /// No description provided for @clientServicesHowSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay the provider directly'**
  String get clientServicesHowSettleTitle;

  /// No description provided for @clientServicesHowSettleBody.
  ///
  /// In en, this message translates to:
  /// **'Settle as the provider agrees and show your voucher code. Ghazal takes no payment for the service.'**
  String get clientServicesHowSettleBody;

  /// No description provided for @clientServicesQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Request quote'**
  String get clientServicesQuoteTitle;

  /// No description provided for @clientServicesQuotePackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientServicesQuotePackage;

  /// No description provided for @clientServicesQuoteDate.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get clientServicesQuoteDate;

  /// No description provided for @clientServicesQuoteDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get clientServicesQuoteDatePlaceholder;

  /// No description provided for @clientServicesQuoteVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientServicesQuoteVenue;

  /// No description provided for @clientServicesQuoteGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientServicesQuoteGuests;

  /// No description provided for @clientServicesQuoteNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the provider'**
  String get clientServicesQuoteNoteLabel;

  /// No description provided for @clientServicesQuoteNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientServicesQuoteNotePlaceholder;

  /// No description provided for @clientServicesQuoteSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientServicesQuoteSend;

  /// No description provided for @clientServicesQuoteDateError.
  ///
  /// In en, this message translates to:
  /// **'Date needed'**
  String get clientServicesQuoteDateError;

  /// No description provided for @clientServicesQuoteGuestNote.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send'**
  String get clientServicesQuoteGuestNote;

  /// No description provided for @clientServicesQuoteThreadExists.
  ///
  /// In en, this message translates to:
  /// **'Added to your chat'**
  String get clientServicesQuoteThreadExists;

  /// No description provided for @clientServicesQuoteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t send'**
  String get clientServicesQuoteErrorTitle;

  /// No description provided for @clientServicesQuoteErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing you typed was lost.'**
  String get clientServicesQuoteErrorBody;

  /// No description provided for @clientServicesQuoteVoucherFailed.
  ///
  /// In en, this message translates to:
  /// **'Your voucher is safe and nothing was charged.'**
  String get clientServicesQuoteVoucherFailed;

  /// No description provided for @clientServicesQuoteAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Use voucher'**
  String get clientServicesQuoteAttachTitle;

  /// No description provided for @clientServicesQuoteAttachInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher request'**
  String get clientServicesQuoteAttachInfoTitle;

  /// No description provided for @clientServicesQuoteAttachNote.
  ///
  /// In en, this message translates to:
  /// **'Your enquiry becomes a request at the voucher price. The provider can accept, decline or suggest another date.'**
  String get clientServicesQuoteAttachNote;

  /// No description provided for @clientServicesQuoteNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What’s next'**
  String get clientServicesQuoteNextTitle;

  /// No description provided for @clientServicesQuoteViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientServicesQuoteViewRequest;

  /// No description provided for @clientServicesQuoteVoucherSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{vendor} will answer in Messages. Once they accept, you have {hours} to confirm.'**
  String clientServicesQuoteVoucherSuccessBody(String vendor, String hours);

  /// No description provided for @clientShellTabBarLabel.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get clientShellTabBarLabel;

  /// No description provided for @clientShellTabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get clientShellTabDiscover;

  /// No description provided for @clientShellTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get clientShellTabSaved;

  /// No description provided for @clientShellTabMyWedding.
  ///
  /// In en, this message translates to:
  /// **'My Wedding'**
  String get clientShellTabMyWedding;

  /// No description provided for @clientShellTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get clientShellTabMessages;

  /// No description provided for @clientShellTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get clientShellTabProfile;

  /// No description provided for @clientShellTabUnread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} unread message} other{{count} unread messages}}'**
  String clientShellTabUnread(int count);

  /// No description provided for @clientShellGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String clientShellGreeting(String name);

  /// No description provided for @clientShellGreetingAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get clientShellGreetingAnonymous;

  /// No description provided for @clientShellBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Your brief'**
  String get clientShellBriefTitle;

  /// No description provided for @clientShellBriefEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit date, guests, area and budget'**
  String get clientShellBriefEditLabel;

  /// No description provided for @clientShellBriefDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientShellBriefDate;

  /// No description provided for @clientShellBriefGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientShellBriefGuests;

  /// No description provided for @clientShellBriefArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get clientShellBriefArea;

  /// No description provided for @clientShellBriefBudget.
  ///
  /// In en, this message translates to:
  /// **'Venue and catering budget'**
  String get clientShellBriefBudget;

  /// No description provided for @clientShellBriefNotDecided.
  ///
  /// In en, this message translates to:
  /// **'Not decided'**
  String get clientShellBriefNotDecided;

  /// No description provided for @clientShellBriefFlexibleMonth.
  ///
  /// In en, this message translates to:
  /// **'Flexible month'**
  String get clientShellBriefFlexibleMonth;

  /// No description provided for @clientShellSwitchVenues.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get clientShellSwitchVenues;

  /// No description provided for @clientShellSwitchServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get clientShellSwitchServices;

  /// No description provided for @clientShellSwitchPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get clientShellSwitchPackages;

  /// No description provided for @clientShellCompareTray.
  ///
  /// In en, this message translates to:
  /// **'Compare ({pair})'**
  String clientShellCompareTray(String pair);

  /// No description provided for @clientVenueTierPrestige.
  ///
  /// In en, this message translates to:
  /// **'Prestige'**
  String get clientVenueTierPrestige;

  /// No description provided for @clientVenueTierSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get clientVenueTierSignature;

  /// No description provided for @clientVenueTierClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get clientVenueTierClassic;

  /// No description provided for @clientVenueTierGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government hall'**
  String get clientVenueTierGovernment;

  /// No description provided for @clientVenueAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get clientVenueAboutTitle;

  /// No description provided for @clientVenueTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get clientVenueTypeHotel;

  /// No description provided for @clientVenueTypeHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientVenueTypeHall;

  /// No description provided for @clientVenueTypeResort.
  ///
  /// In en, this message translates to:
  /// **'Resort'**
  String get clientVenueTypeResort;

  /// No description provided for @clientVenueTypeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get clientVenueTypeVilla;

  /// No description provided for @clientVenueTypeOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get clientVenueTypeOutdoor;

  /// No description provided for @clientVenueTypeConvention.
  ///
  /// In en, this message translates to:
  /// **'Convention centre'**
  String get clientVenueTypeConvention;

  /// No description provided for @clientVenueAddressLine.
  ///
  /// In en, this message translates to:
  /// **'Block {block}, {street}'**
  String clientVenueAddressLine(String block, String street);

  /// No description provided for @clientVenueRegionLine.
  ///
  /// In en, this message translates to:
  /// **'{area}, {governorate}'**
  String clientVenueRegionLine(String area, String governorate);

  /// No description provided for @clientVenueHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Photos of {venue}'**
  String clientVenueHeroLabel(String venue);

  /// No description provided for @clientVenueHeroOpen.
  ///
  /// In en, this message translates to:
  /// **'Open the photo gallery'**
  String get clientVenueHeroOpen;

  /// No description provided for @clientVenueNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos coming soon'**
  String get clientVenueNoPhotos;

  /// No description provided for @clientVenueZoneHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientVenueZoneHall;

  /// No description provided for @clientVenueZoneStage.
  ///
  /// In en, this message translates to:
  /// **'Stage and kosha'**
  String get clientVenueZoneStage;

  /// No description provided for @clientVenueZoneBridal.
  ///
  /// In en, this message translates to:
  /// **'Bridal suite'**
  String get clientVenueZoneBridal;

  /// No description provided for @clientVenueZoneBuffet.
  ///
  /// In en, this message translates to:
  /// **'Buffet'**
  String get clientVenueZoneBuffet;

  /// No description provided for @clientVenueZoneOutdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get clientVenueZoneOutdoors;

  /// No description provided for @clientVenueZoneEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance and valet'**
  String get clientVenueZoneEntrance;

  /// No description provided for @clientVenueZoneLayout.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get clientVenueZoneLayout;

  /// No description provided for @clientVenueZoneVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get clientVenueZoneVideo;

  /// No description provided for @clientVenueZoneWithHall.
  ///
  /// In en, this message translates to:
  /// **'{zone}, {hall}'**
  String clientVenueZoneWithHall(String zone, String hall);

  /// No description provided for @clientVenueGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo gallery of {venue}'**
  String clientVenueGalleryLabel(String venue);

  /// No description provided for @clientVenueGalleryCounter.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String clientVenueGalleryCounter(num current, num total);

  /// No description provided for @clientVenueGalleryZones.
  ///
  /// In en, this message translates to:
  /// **'Photo zones'**
  String get clientVenueGalleryZones;

  /// No description provided for @clientVenueVideoPlay.
  ///
  /// In en, this message translates to:
  /// **'Play the video'**
  String get clientVenueVideoPlay;

  /// No description provided for @clientVenueVideoPause.
  ///
  /// In en, this message translates to:
  /// **'Pause the video'**
  String get clientVenueVideoPause;

  /// No description provided for @clientVenueVideoScrub.
  ///
  /// In en, this message translates to:
  /// **'Video position'**
  String get clientVenueVideoScrub;

  /// No description provided for @clientVenueVideoCaption.
  ///
  /// In en, this message translates to:
  /// **'Entrance, hall, stage'**
  String get clientVenueVideoCaption;

  /// No description provided for @clientVenueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Your date'**
  String get clientVenueDateLabel;

  /// No description provided for @clientVenueDateChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get clientVenueDateChoose;

  /// No description provided for @clientVenueDateChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change the date'**
  String get clientVenueDateChangeLabel;

  /// No description provided for @clientVenueGuestsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add guests'**
  String get clientVenueGuestsAdd;

  /// No description provided for @clientVenueGuestsChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change the number of guests'**
  String get clientVenueGuestsChangeLabel;

  /// No description provided for @clientVenueGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get clientVenueGuestsLabel;

  /// No description provided for @clientVenueEstimateLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated total'**
  String get clientVenueEstimateLabel;

  /// No description provided for @clientVenueEstimateMinimum.
  ///
  /// In en, this message translates to:
  /// **'Priced for the minimum of {guests}'**
  String clientVenueEstimateMinimum(String guests);

  /// No description provided for @clientVenueHeldSr.
  ///
  /// In en, this message translates to:
  /// **'Date held by another couple. You can still send a request.'**
  String get clientVenueHeldSr;

  /// No description provided for @clientVenueNearestTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest free dates'**
  String get clientVenueNearestTitle;

  /// No description provided for @clientVenueSeeAllDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get clientVenueSeeAllDates;

  /// No description provided for @clientVenueWindowApplied.
  ///
  /// In en, this message translates to:
  /// **'{title} applies to your date'**
  String clientVenueWindowApplied(String title);

  /// No description provided for @clientVenueHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How the voucher works'**
  String get clientVenueHowTitle;

  /// No description provided for @clientVenueThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking in five steps'**
  String get clientVenueThreadTitle;

  /// No description provided for @clientVenueThreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking steps: voucher, request, approval, confirmation, at the venue'**
  String get clientVenueThreadLabel;

  /// No description provided for @clientVenueThreadVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientVenueThreadVoucher;

  /// No description provided for @clientVenueThreadRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientVenueThreadRequest;

  /// No description provided for @clientVenueThreadApproval.
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get clientVenueThreadApproval;

  /// No description provided for @clientVenueThreadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientVenueThreadConfirm;

  /// No description provided for @clientVenueThreadAtVenue.
  ///
  /// In en, this message translates to:
  /// **'At the venue'**
  String get clientVenueThreadAtVenue;

  /// No description provided for @clientVenueThreadNote.
  ///
  /// In en, this message translates to:
  /// **'You pay Ghazal {fee} once, for the voucher. Everything else you pay to {venue} directly.'**
  String clientVenueThreadNote(String fee, String venue);

  /// No description provided for @clientVenueResponseUsually.
  ///
  /// In en, this message translates to:
  /// **'Usually replies within {hours, plural, one{{hours} hour} other{{hours} hours}}'**
  String clientVenueResponseUsually(int hours);

  /// No description provided for @clientVenueOwnedView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientVenueOwnedView;

  /// No description provided for @clientVenueHallsTitle.
  ///
  /// In en, this message translates to:
  /// **'Halls'**
  String get clientVenueHallsTitle;

  /// No description provided for @clientVenueHallSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a hall'**
  String get clientVenueHallSwitchLabel;

  /// No description provided for @clientVenueHallFacts.
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get clientVenueHallFacts;

  /// No description provided for @clientVenueHallCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get clientVenueHallCapacity;

  /// No description provided for @clientVenueHallIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get clientVenueHallIndoor;

  /// No description provided for @clientVenueHallOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get clientVenueHallOutdoor;

  /// No description provided for @clientVenueHallMixed.
  ///
  /// In en, this message translates to:
  /// **'Indoor and outdoor'**
  String get clientVenueHallMixed;

  /// No description provided for @clientVenueHallExclusive.
  ///
  /// In en, this message translates to:
  /// **'One wedding a day'**
  String get clientVenueHallExclusive;

  /// No description provided for @clientVenueHallExclusiveShort.
  ///
  /// In en, this message translates to:
  /// **'Exclusive'**
  String get clientVenueHallExclusiveShort;

  /// No description provided for @clientVenueSessionSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a session'**
  String get clientVenueSessionSwitchLabel;

  /// No description provided for @clientVenueMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get clientVenueMore;

  /// No description provided for @clientVenueLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get clientVenueLess;

  /// No description provided for @clientVenuePackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get clientVenuePackagesTitle;

  /// No description provided for @clientVenuePackagesDetails.
  ///
  /// In en, this message translates to:
  /// **'Package details'**
  String get clientVenuePackagesDetails;

  /// No description provided for @clientVenuePackagesNone.
  ///
  /// In en, this message translates to:
  /// **'None on this date'**
  String get clientVenuePackagesNone;

  /// No description provided for @clientVenuePkgMinGuests.
  ///
  /// In en, this message translates to:
  /// **'Minimum guests'**
  String get clientVenuePkgMinGuests;

  /// No description provided for @clientVenuePkgIncludes.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get clientVenuePkgIncludes;

  /// No description provided for @clientVenuePkgIncludesAll.
  ///
  /// In en, this message translates to:
  /// **'Show all inclusions'**
  String get clientVenuePkgIncludesAll;

  /// No description provided for @clientVenuePkgMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get clientVenuePkgMenu;

  /// No description provided for @clientVenuePkgExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get clientVenuePkgExtras;

  /// No description provided for @clientVenuePkgSave.
  ///
  /// In en, this message translates to:
  /// **'Save package'**
  String get clientVenuePkgSave;

  /// No description provided for @clientVenuePkgSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved packages'**
  String get clientVenuePkgSaved;

  /// No description provided for @clientVenuePkgTierWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekday'**
  String get clientVenuePkgTierWeekday;

  /// No description provided for @clientVenuePkgTierWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get clientVenuePkgTierWeekend;

  /// No description provided for @clientVenuePkgTierSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get clientVenuePkgTierSeason;

  /// No description provided for @clientVenuePkgTierHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get clientVenuePkgTierHoliday;

  /// No description provided for @clientVenuePkgTierSpecialDate.
  ///
  /// In en, this message translates to:
  /// **'Special date'**
  String get clientVenuePkgTierSpecialDate;

  /// No description provided for @clientVenuePkgTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate for {date}'**
  String clientVenuePkgTierLabel(String date);

  /// No description provided for @clientVenuePkgOverTitle.
  ///
  /// In en, this message translates to:
  /// **'Over capacity'**
  String get clientVenuePkgOverTitle;

  /// No description provided for @clientVenuePkgOverCap.
  ///
  /// In en, this message translates to:
  /// **'{hall} holds up to {guests}. You can choose another hall or fewer guests.'**
  String clientVenuePkgOverCap(String hall, String guests);

  /// No description provided for @clientVenuePkgUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on {date}'**
  String clientVenuePkgUnavailable(String date);

  /// No description provided for @clientVenueFacilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get clientVenueFacilitiesTitle;

  /// No description provided for @clientVenueFacilitiesAll.
  ///
  /// In en, this message translates to:
  /// **'All facilities'**
  String get clientVenueFacilitiesAll;

  /// No description provided for @clientVenueFacIncluded.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get clientVenueFacIncluded;

  /// No description provided for @clientVenueFacExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get clientVenueFacExtra;

  /// No description provided for @clientVenueFacOff.
  ///
  /// In en, this message translates to:
  /// **'Not offered'**
  String get clientVenueFacOff;

  /// No description provided for @clientVenuePoliciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get clientVenuePoliciesTitle;

  /// No description provided for @clientVenuePolicyTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get clientVenuePolicyTerms;

  /// No description provided for @clientVenuePolicyRules.
  ///
  /// In en, this message translates to:
  /// **'Hall rules'**
  String get clientVenuePolicyRules;

  /// No description provided for @clientVenuePolicyGood.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get clientVenuePolicyGood;

  /// No description provided for @clientVenueFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get clientVenueFaqTitle;

  /// No description provided for @clientVenueReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get clientVenueReviewsTitle;

  /// No description provided for @clientVenueReviewsAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count} reviews'**
  String clientVenueReviewsAll(String count);

  /// No description provided for @clientVenueReviewsNone.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get clientVenueReviewsNone;

  /// No description provided for @clientVenueCatVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientVenueCatVenue;

  /// No description provided for @clientVenueCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get clientVenueCatFood;

  /// No description provided for @clientVenueCatService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get clientVenueCatService;

  /// No description provided for @clientVenueCatValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get clientVenueCatValue;

  /// No description provided for @clientVenueReviewAnon.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get clientVenueReviewAnon;

  /// No description provided for @clientVenueReviewReply.
  ///
  /// In en, this message translates to:
  /// **'The venue replied'**
  String get clientVenueReviewReply;

  /// No description provided for @clientVenueLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get clientVenueLocationTitle;

  /// No description provided for @clientVenueDriveFrom.
  ///
  /// In en, this message translates to:
  /// **'Drive from {origin}'**
  String clientVenueDriveFrom(String origin);

  /// No description provided for @clientVenueMapsShort.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get clientVenueMapsShort;

  /// No description provided for @clientVenueMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get clientVenueMapsTitle;

  /// No description provided for @clientVenueMapsGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get clientVenueMapsGoogle;

  /// No description provided for @clientVenueMapsApple.
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get clientVenueMapsApple;

  /// No description provided for @clientVenueMapsWaze.
  ///
  /// In en, this message translates to:
  /// **'Waze'**
  String get clientVenueMapsWaze;

  /// No description provided for @clientVenueMapsOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening {app}'**
  String clientVenueMapsOpening(String app);

  /// No description provided for @clientVenueSimilarTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar halls'**
  String get clientVenueSimilarTitle;

  /// No description provided for @clientVenueCtaChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get clientVenueCtaChooseDate;

  /// No description provided for @clientVenueCtaSeeDates.
  ///
  /// In en, this message translates to:
  /// **'Free dates'**
  String get clientVenueCtaSeeDates;

  /// No description provided for @clientVenueCtaGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Get voucher'**
  String get clientVenueCtaGetVoucher;

  /// No description provided for @clientVenueCtaSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientVenueCtaSendRequest;

  /// No description provided for @clientVenueCtaVisit.
  ///
  /// In en, this message translates to:
  /// **'Book visit'**
  String get clientVenueCtaVisit;

  /// No description provided for @clientVenueCtaContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientVenueCtaContact;

  /// No description provided for @clientVenueCtaChangeGuests.
  ///
  /// In en, this message translates to:
  /// **'Change guests'**
  String get clientVenueCtaChangeGuests;

  /// No description provided for @clientVenueVisitNone.
  ///
  /// In en, this message translates to:
  /// **'No visit times are open at the moment'**
  String get clientVenueVisitNone;

  /// No description provided for @clientVenueCtaOffline.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get clientVenueCtaOffline;

  /// No description provided for @clientVenueOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline, saved {time}'**
  String clientVenueOfflineBanner(String time);

  /// No description provided for @clientVenueCompareAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to compare'**
  String get clientVenueCompareAdded;

  /// No description provided for @clientVenueCompareView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientVenueCompareView;

  /// No description provided for @clientVenueSavedRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get clientVenueSavedRemoved;

  /// No description provided for @clientVenueSavedView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientVenueSavedView;

  /// No description provided for @clientVenueShareCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get clientVenueShareCopied;

  /// No description provided for @clientVenueDelistedTitle.
  ///
  /// In en, this message translates to:
  /// **'No longer listed'**
  String get clientVenueDelistedTitle;

  /// No description provided for @clientVenueDelistedCta.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientVenueDelistedCta;

  /// No description provided for @clientVenueTotalFor.
  ///
  /// In en, this message translates to:
  /// **'Total for {guests}'**
  String clientVenueTotalFor(String guests);

  /// No description provided for @clientVenueContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientVenueContactTitle;

  /// No description provided for @clientVenueContactCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling {venue}'**
  String clientVenueContactCalling(String venue);

  /// No description provided for @clientVenueContactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp'**
  String get clientVenueContactWhatsapp;

  /// No description provided for @clientVenueContactChat.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clientVenueContactChat;

  /// No description provided for @clientVenueCalTitle.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get clientVenueCalTitle;

  /// No description provided for @clientVenueCalMonthJump.
  ///
  /// In en, this message translates to:
  /// **'Jump to a month'**
  String get clientVenueCalMonthJump;

  /// No description provided for @clientVenueCalMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get clientVenueCalMonthTitle;

  /// No description provided for @clientVenueCalMonthDensity.
  ///
  /// In en, this message translates to:
  /// **'{month}: {count, plural, =0{no free dates} one{{count} free date} other{{count} free dates}}'**
  String clientVenueCalMonthDensity(String month, int count);

  /// No description provided for @clientVenueCalBasis.
  ///
  /// In en, this message translates to:
  /// **'Prices in KD for {guests}'**
  String clientVenueCalBasis(String guests);

  /// No description provided for @clientVenueCalGuestsCta.
  ///
  /// In en, this message translates to:
  /// **'Add guests'**
  String get clientVenueCalGuestsCta;

  /// No description provided for @clientVenueCalNone.
  ///
  /// In en, this message translates to:
  /// **'No free dates'**
  String get clientVenueCalNone;

  /// No description provided for @clientVenueCalPickHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a date to see the estimate.'**
  String get clientVenueCalPickHint;

  /// No description provided for @clientVenueCalPickFree.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the free dates.'**
  String get clientVenueCalPickFree;

  /// No description provided for @clientVenueCalOccasionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Occasions this month'**
  String get clientVenueCalOccasionsLabel;

  /// No description provided for @clientVenueCalChosen.
  ///
  /// In en, this message translates to:
  /// **'Date set {date}'**
  String clientVenueCalChosen(String date);

  /// No description provided for @clientVenueCalUse.
  ///
  /// In en, this message translates to:
  /// **'Use date'**
  String get clientVenueCalUse;

  /// No description provided for @clientVenuePolTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get clientVenuePolTitle;

  /// No description provided for @clientVenuePolTabsLabel.
  ///
  /// In en, this message translates to:
  /// **'Policy sections'**
  String get clientVenuePolTabsLabel;

  /// No description provided for @clientVenuePolTabTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get clientVenuePolTabTerms;

  /// No description provided for @clientVenuePolTabRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get clientVenuePolTabRules;

  /// No description provided for @clientVenuePolTabGood.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get clientVenuePolTabGood;

  /// No description provided for @clientVenuePolRulesLabel.
  ///
  /// In en, this message translates to:
  /// **'Reception type'**
  String get clientVenuePolRulesLabel;

  /// No description provided for @clientVenuePolChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get clientVenuePolChildren;

  /// No description provided for @clientVenuePolDress.
  ///
  /// In en, this message translates to:
  /// **'Dress code'**
  String get clientVenuePolDress;

  /// No description provided for @clientVenuePolHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get clientVenuePolHours;

  /// No description provided for @clientVenuePolClosures.
  ///
  /// In en, this message translates to:
  /// **'Closures'**
  String get clientVenuePolClosures;

  /// No description provided for @clientVenuePolHoursLine.
  ///
  /// In en, this message translates to:
  /// **'{days}: {open} – {close}'**
  String clientVenuePolHoursLine(String days, String open, String close);

  /// No description provided for @clientVenuePolClosureLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {from} – {to}'**
  String clientVenuePolClosureLine(String name, String from, String to);

  /// No description provided for @clientVenueAudWomen.
  ///
  /// In en, this message translates to:
  /// **'Ladies'**
  String get clientVenueAudWomen;

  /// No description provided for @clientVenueAudMen.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get clientVenueAudMen;

  /// No description provided for @clientVenueAudMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get clientVenueAudMixed;

  /// No description provided for @clientVenueRulePhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get clientVenueRulePhotography;

  /// No description provided for @clientVenueRulePhotoFemale.
  ///
  /// In en, this message translates to:
  /// **'Women only'**
  String get clientVenueRulePhotoFemale;

  /// No description provided for @clientVenueRuleMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get clientVenueRuleMusic;

  /// No description provided for @clientVenueRuleMusicBand.
  ///
  /// In en, this message translates to:
  /// **'DJ or band'**
  String get clientVenueRuleMusicBand;

  /// No description provided for @clientVenueRuleMusicLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get clientVenueRuleMusicLive;

  /// No description provided for @clientVenueRuleMusicDuff.
  ///
  /// In en, this message translates to:
  /// **'Duff only'**
  String get clientVenueRuleMusicDuff;

  /// No description provided for @clientVenueRuleAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get clientVenueRuleAllowed;

  /// No description provided for @clientVenueRuleApproval.
  ///
  /// In en, this message translates to:
  /// **'With approval'**
  String get clientVenueRuleApproval;

  /// No description provided for @clientVenueRuleNot.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get clientVenueRuleNot;

  /// No description provided for @clientVenueRuleNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get clientVenueRuleNone;

  /// No description provided for @clientVenueRuleEntrance.
  ///
  /// In en, this message translates to:
  /// **'Separate entrance'**
  String get clientVenueRuleEntrance;

  /// No description provided for @clientVenueRuleCloakroom.
  ///
  /// In en, this message translates to:
  /// **'Abaya cloakroom'**
  String get clientVenueRuleCloakroom;

  /// No description provided for @clientVenueRulePrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer room'**
  String get clientVenueRulePrayer;

  /// No description provided for @clientVenueRuleSecurity.
  ///
  /// In en, this message translates to:
  /// **'Female security'**
  String get clientVenueRuleSecurity;

  /// No description provided for @clientVenueRuleBackup.
  ///
  /// In en, this message translates to:
  /// **'Indoor backup'**
  String get clientVenueRuleBackup;

  /// No description provided for @clientVenueRuleBoys.
  ///
  /// In en, this message translates to:
  /// **'Boys’ age'**
  String get clientVenueRuleBoys;

  /// No description provided for @clientVenueRuleCatering.
  ///
  /// In en, this message translates to:
  /// **'Outside catering'**
  String get clientVenueRuleCatering;

  /// No description provided for @clientVenueRuleDecor.
  ///
  /// In en, this message translates to:
  /// **'Outside decor'**
  String get clientVenueRuleDecor;

  /// No description provided for @clientVenueRuleBukhoor.
  ///
  /// In en, this message translates to:
  /// **'Bukhoor'**
  String get clientVenueRuleBukhoor;

  /// No description provided for @clientVenueRuleCutoff.
  ///
  /// In en, this message translates to:
  /// **'Event ends by'**
  String get clientVenueRuleCutoff;

  /// No description provided for @clientVenueRuleExtraHour.
  ///
  /// In en, this message translates to:
  /// **'Extra hour'**
  String get clientVenueRuleExtraHour;

  /// No description provided for @clientVenueTermsVenueTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of {venue}'**
  String clientVenueTermsVenueTitle(String venue);

  /// No description provided for @clientVenueTermsVoucherTitle.
  ///
  /// In en, this message translates to:
  /// **'The Ghazal voucher'**
  String get clientVenueTermsVoucherTitle;

  /// No description provided for @clientVenueTermsVoucherFee.
  ///
  /// In en, this message translates to:
  /// **'{fee}, paid once to Ghazal'**
  String clientVenueTermsVoucherFee(String fee);

  /// No description provided for @clientVenueTermsVoucherBound.
  ///
  /// In en, this message translates to:
  /// **'Bound to this venue and quote'**
  String get clientVenueTermsVoucherBound;

  /// No description provided for @clientVenueTermsDirect.
  ///
  /// In en, this message translates to:
  /// **'Pay and cancel with the venue'**
  String get clientVenueTermsDirect;

  /// No description provided for @clientVenueTermsVoucherReuse.
  ///
  /// In en, this message translates to:
  /// **'Declined or unanswered: reuse for {days}, or ask support for credit'**
  String clientVenueTermsVoucherReuse(String days);

  /// No description provided for @clientVenueTermsVoucherConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm within {hours} of approval'**
  String clientVenueTermsVoucherConfirm(String hours);

  /// No description provided for @clientVenueGovFeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get clientVenueGovFeesTitle;

  /// No description provided for @clientVenueGovSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get clientVenueGovSecurity;

  /// No description provided for @clientVenueGovRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get clientVenueGovRefundable;

  /// No description provided for @clientVenueGovHallOnly.
  ///
  /// In en, this message translates to:
  /// **'Hall only: bring your own decor and catering.'**
  String get clientVenueGovHallOnly;

  /// No description provided for @clientVenueGovHallOnlyShort.
  ///
  /// In en, this message translates to:
  /// **'Hall only'**
  String get clientVenueGovHallOnlyShort;

  /// No description provided for @clientVenueGovFeesInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About the fees'**
  String get clientVenueGovFeesInfoTitle;

  /// No description provided for @clientVenueGovRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get clientVenueGovRulesTitle;

  /// No description provided for @clientVenueGovRuleNoChange.
  ///
  /// In en, this message translates to:
  /// **'No date changes'**
  String get clientVenueGovRuleNoChange;

  /// No description provided for @clientVenueGovRulePay.
  ///
  /// In en, this message translates to:
  /// **'Pay on time'**
  String get clientVenueGovRulePay;

  /// No description provided for @clientVenueGovRulePayInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment is made on the official channel within the time it states, or the booking is cancelled automatically.'**
  String get clientVenueGovRulePayInfo;

  /// No description provided for @clientVenueGovRuleKnet.
  ///
  /// In en, this message translates to:
  /// **'KNET'**
  String get clientVenueGovRuleKnet;

  /// No description provided for @clientVenueGovAvail.
  ///
  /// In en, this message translates to:
  /// **'Official app'**
  String get clientVenueGovAvail;

  /// No description provided for @clientVenueGovCtaOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official booking'**
  String get clientVenueGovCtaOfficial;

  /// No description provided for @clientVenueGovCtaCatering.
  ///
  /// In en, this message translates to:
  /// **'Find services'**
  String get clientVenueGovCtaCatering;

  /// No description provided for @clientVenueGovLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaving Ghazal'**
  String get clientVenueGovLeaveTitle;

  /// No description provided for @clientVenueGovLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Booking and payment happen on the official channel. Ghazal does not hold or guarantee it.'**
  String get clientVenueGovLeaveBody;

  /// No description provided for @clientVenueGovLeaveToast.
  ///
  /// In en, this message translates to:
  /// **'Opening official site'**
  String get clientVenueGovLeaveToast;

  /// No description provided for @clientVenueGovSelfLink.
  ///
  /// In en, this message translates to:
  /// **'Mark booked'**
  String get clientVenueGovSelfLink;

  /// No description provided for @clientVenueGovSelfTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark booked'**
  String get clientVenueGovSelfTitle;

  /// No description provided for @clientVenueGovSelfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get clientVenueGovSelfDate;

  /// No description provided for @clientVenueGovSelfFee.
  ///
  /// In en, this message translates to:
  /// **'Fee paid'**
  String get clientVenueGovSelfFee;

  /// No description provided for @clientVenueGovSelfNote.
  ///
  /// In en, this message translates to:
  /// **'This is a record for your budget, checklist and countdown only. It is not a Ghazal booking.'**
  String get clientVenueGovSelfNote;

  /// No description provided for @clientVenueGovSelfInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Not a booking'**
  String get clientVenueGovSelfInfoTitle;

  /// No description provided for @clientVenueGovSelfToast.
  ///
  /// In en, this message translates to:
  /// **'Saved to your wedding'**
  String get clientVenueGovSelfToast;

  /// No description provided for @clientVenueGovSelfView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get clientVenueGovSelfView;

  /// No description provided for @clientVenueGovWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why no voucher?'**
  String get clientVenueGovWhyTitle;

  /// No description provided for @clientVenueGovWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Governmental facilities have fixed official fees, so there is no Ghazal price to unlock.'**
  String get clientVenueGovWhyBody;

  /// No description provided for @clientVenueGovBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientVenueGovBrowse;

  /// No description provided for @clientVisitsBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a visit'**
  String get clientVisitsBookTitle;

  /// No description provided for @clientVisitsBookAction.
  ///
  /// In en, this message translates to:
  /// **'Request visit'**
  String get clientVisitsBookAction;

  /// No description provided for @clientVisitsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Free visit'**
  String get clientVisitsInfoTitle;

  /// No description provided for @clientVisitsInfoFree.
  ///
  /// In en, this message translates to:
  /// **'A visit is free and needs no voucher.'**
  String get clientVisitsInfoFree;

  /// No description provided for @clientVisitsInfoChat.
  ///
  /// In en, this message translates to:
  /// **'A chat opens with {venue} and Ghazal support to confirm your visit.'**
  String clientVisitsInfoChat(String venue);

  /// No description provided for @clientVisitsInfoWindow.
  ///
  /// In en, this message translates to:
  /// **'Each window lasts {minutes} minutes. Arrive at any time inside it.'**
  String clientVisitsInfoWindow(String minutes);

  /// No description provided for @clientVisitsSlotDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get clientVisitsSlotDay;

  /// No description provided for @clientVisitsSlotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get clientVisitsSlotMorning;

  /// No description provided for @clientVisitsSlotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get clientVisitsSlotAfternoon;

  /// No description provided for @clientVisitsSlotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get clientVisitsSlotEvening;

  /// No description provided for @clientVisitsSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get clientVisitsSlotTaken;

  /// No description provided for @clientVisitsNoWeek.
  ///
  /// In en, this message translates to:
  /// **'Free from {date}'**
  String clientVisitsNoWeek(String date);

  /// No description provided for @clientVisitsTakenNext.
  ///
  /// In en, this message translates to:
  /// **'Next free windows'**
  String get clientVisitsTakenNext;

  /// No description provided for @clientVisitsNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get clientVisitsNotSent;

  /// No description provided for @clientVisitsVisitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get clientVisitsVisitors;

  /// No description provided for @clientVisitsVisitorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} visitor} other{{count} visitors}}'**
  String clientVisitsVisitorsCount(int count);

  /// No description provided for @clientVisitsNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note for the venue'**
  String get clientVisitsNoteLabel;

  /// No description provided for @clientVisitsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get clientVisitsNote;

  /// No description provided for @clientVisitsFactDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get clientVisitsFactDay;

  /// No description provided for @clientVisitsFactWindow.
  ///
  /// In en, this message translates to:
  /// **'Arrival window'**
  String get clientVisitsFactWindow;

  /// No description provided for @clientVisitsFactVisitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get clientVisitsFactVisitors;

  /// No description provided for @clientVisitsRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit requested'**
  String get clientVisitsRequestedTitle;

  /// No description provided for @clientVisitsOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get clientVisitsOpenChat;

  /// No description provided for @clientVisitsBackToVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get clientVisitsBackToVenue;

  /// No description provided for @clientVisitsRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Opening chat'**
  String get clientVisitsRedirecting;

  /// No description provided for @clientVisitsStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get clientVisitsStay;

  /// No description provided for @clientVisitsSummary.
  ///
  /// In en, this message translates to:
  /// **'Visit details'**
  String get clientVisitsSummary;

  /// No description provided for @clientVisitsStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit progress'**
  String get clientVisitsStepsLabel;

  /// No description provided for @clientVisitsStepRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientVisitsStepRequest;

  /// No description provided for @clientVisitsStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get clientVisitsStepConfirm;

  /// No description provided for @clientVisitsStepWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get clientVisitsStepWay;

  /// No description provided for @clientVisitsStepArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get clientVisitsStepArrival;

  /// No description provided for @clientVisitsMembersOpen.
  ///
  /// In en, this message translates to:
  /// **'Chat members'**
  String get clientVisitsMembersOpen;

  /// No description provided for @clientVisitsRoleHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get clientVisitsRoleHotel;

  /// No description provided for @clientVisitsRoleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientVisitsRoleSupport;

  /// No description provided for @clientVisitsMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat members'**
  String get clientVisitsMembersTitle;

  /// No description provided for @clientVisitsMembersPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get clientVisitsMembersPrivateTitle;

  /// No description provided for @clientVisitsMembersPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only these three can read this chat. Phone numbers are not shared. Ghazal support cannot be blocked.'**
  String get clientVisitsMembersPrivate;

  /// No description provided for @clientVisitsMembersVenue.
  ///
  /// In en, this message translates to:
  /// **'Venue page'**
  String get clientVisitsMembersVenue;

  /// No description provided for @clientVisitsMembersReport.
  ///
  /// In en, this message translates to:
  /// **'Report or block'**
  String get clientVisitsMembersReport;

  /// No description provided for @clientVisitsClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get clientVisitsClosed;

  /// No description provided for @clientVisitsMessageVenue.
  ///
  /// In en, this message translates to:
  /// **'Message venue'**
  String get clientVisitsMessageVenue;

  /// No description provided for @clientVisitsRecordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Hold to record'**
  String get clientVisitsRecordTooShort;

  /// No description provided for @clientVisitsAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get clientVisitsAttachTitle;

  /// No description provided for @clientVisitsPhotoViewer.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get clientVisitsPhotoViewer;

  /// No description provided for @clientVisitsGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientVisitsGetVoucher;

  /// No description provided for @clientVisitsConfirmedToast.
  ///
  /// In en, this message translates to:
  /// **'Time confirmed'**
  String get clientVisitsConfirmedToast;

  /// No description provided for @clientVisitsGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your visits'**
  String get clientVisitsGuestTitle;

  /// No description provided for @clientVisitsGuestAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientVisitsGuestAction;

  /// No description provided for @clientVisitsMsgSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get clientVisitsMsgSending;

  /// No description provided for @clientVisitsMsgQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get clientVisitsMsgQueued;

  /// No description provided for @clientVisitsMsgDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get clientVisitsMsgDelete;

  /// No description provided for @clientVisitsPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Your visit'**
  String get clientVisitsPinLabel;

  /// No description provided for @clientVisitsConfirmTime.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get clientVisitsConfirmTime;

  /// No description provided for @clientVisitsChangeOrCancel.
  ///
  /// In en, this message translates to:
  /// **'Change or cancel'**
  String get clientVisitsChangeOrCancel;

  /// No description provided for @clientVisitsOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get clientVisitsOnTheWay;

  /// No description provided for @clientVisitsArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get clientVisitsArrived;

  /// No description provided for @clientVisitsNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Needs a connection'**
  String get clientVisitsNeedsConnection;

  /// No description provided for @clientVisitsChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get clientVisitsChooseAnother;

  /// No description provided for @clientVisitsSysOpened.
  ///
  /// In en, this message translates to:
  /// **'Chat opened'**
  String get clientVisitsSysOpened;

  /// No description provided for @clientVisitsSysConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Visit confirmed'**
  String get clientVisitsSysConfirmed;

  /// No description provided for @clientVisitsSysProposed.
  ///
  /// In en, this message translates to:
  /// **'New time suggested'**
  String get clientVisitsSysProposed;

  /// No description provided for @clientVisitsSysDeclined.
  ///
  /// In en, this message translates to:
  /// **'Time unavailable. Chat closed.'**
  String get clientVisitsSysDeclined;

  /// No description provided for @clientVisitsSysCancelled.
  ///
  /// In en, this message translates to:
  /// **'Visit cancelled. Chat closed.'**
  String get clientVisitsSysCancelled;

  /// No description provided for @clientVisitsSysArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrival confirmed'**
  String get clientVisitsSysArrived;

  /// No description provided for @clientVisitsSysCompleted.
  ///
  /// In en, this message translates to:
  /// **'Visit complete'**
  String get clientVisitsSysCompleted;

  /// No description provided for @clientVisitsSysClosed.
  ///
  /// In en, this message translates to:
  /// **'Chat closed'**
  String get clientVisitsSysClosed;

  /// No description provided for @clientVisitsSysMissed.
  ///
  /// In en, this message translates to:
  /// **'Visit missed'**
  String get clientVisitsSysMissed;

  /// No description provided for @clientVisitsSysAccepted.
  ///
  /// In en, this message translates to:
  /// **'New time accepted'**
  String get clientVisitsSysAccepted;

  /// No description provided for @clientVisitsSysAsked.
  ///
  /// In en, this message translates to:
  /// **'You asked for {when}'**
  String clientVisitsSysAsked(String when);

  /// No description provided for @clientVisitsTapOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'We are on our way.'**
  String get clientVisitsTapOnTheWay;

  /// No description provided for @clientVisitsTapArrived.
  ///
  /// In en, this message translates to:
  /// **'We have arrived.'**
  String get clientVisitsTapArrived;

  /// No description provided for @clientVisitsDemoSupport.
  ///
  /// In en, this message translates to:
  /// **'Hello {name}, I am Lama from Ghazal support. I am here with you and the hotel to confirm your arrival.'**
  String clientVisitsDemoSupport(String name);

  /// No description provided for @clientVisitsDemoClient.
  ///
  /// In en, this message translates to:
  /// **'Peace be upon you. We would like to visit the hall, my mother and I.'**
  String get clientVisitsDemoClient;

  /// No description provided for @clientVisitsDemoHotelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Welcome {name}. Your visit is confirmed for {day} at {time}, and we will meet you at the main entrance.'**
  String clientVisitsDemoHotelConfirm(String name, String day, String time);

  /// No description provided for @clientVisitsDemoHotelPropose.
  ///
  /// In en, this message translates to:
  /// **'{name}, that slot is no longer free. Could we meet you on {day} at {time} instead?'**
  String clientVisitsDemoHotelPropose(String name, String day, String time);

  /// No description provided for @clientVisitsDemoHotelDecline.
  ///
  /// In en, this message translates to:
  /// **'Thank you {name}. We cannot host visits at this time. You are welcome to choose another day.'**
  String clientVisitsDemoHotelDecline(String name);

  /// No description provided for @clientVisitsDemoHere.
  ///
  /// In en, this message translates to:
  /// **'We have arrived, we are at the main entrance.'**
  String get clientVisitsDemoHere;

  /// No description provided for @clientVisitsDemoPending.
  ///
  /// In en, this message translates to:
  /// **'Is there parking close to the main entrance?'**
  String get clientVisitsDemoPending;

  /// No description provided for @clientVisitsDemoHotelAck.
  ///
  /// In en, this message translates to:
  /// **'Thank you {name}, noted. We will see you then.'**
  String clientVisitsDemoHotelAck(String name);

  /// No description provided for @clientVisitsDemoHotelAckRequested.
  ///
  /// In en, this message translates to:
  /// **'Thank you {name}. We received your request and will confirm shortly.'**
  String clientVisitsDemoHotelAckRequested(String name);

  /// No description provided for @clientVisitsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get clientVisitsListTitle;

  /// No description provided for @clientVisitsTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get clientVisitsTabUpcoming;

  /// No description provided for @clientVisitsTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get clientVisitsTabPast;

  /// No description provided for @clientVisitsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No visits'**
  String get clientVisitsEmptyTitle;

  /// No description provided for @clientVisitsEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'See halls'**
  String get clientVisitsEmptyAction;

  /// No description provided for @clientVisitsChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your visit'**
  String get clientVisitsChangeTitle;

  /// No description provided for @clientVisitsInfoFeeTitle.
  ///
  /// In en, this message translates to:
  /// **'No fee'**
  String get clientVisitsInfoFeeTitle;

  /// No description provided for @clientVisitsInfoNoFee.
  ///
  /// In en, this message translates to:
  /// **'Nothing is charged and nothing is lost.'**
  String get clientVisitsInfoNoFee;

  /// No description provided for @clientVisitsInfoRecord.
  ///
  /// In en, this message translates to:
  /// **'The chat records the change and {venue} is told.'**
  String clientVisitsInfoRecord(String venue);

  /// No description provided for @clientVisitsRowAsk.
  ///
  /// In en, this message translates to:
  /// **'Another time'**
  String get clientVisitsRowAsk;

  /// No description provided for @clientVisitsRowCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel visit'**
  String get clientVisitsRowCancel;

  /// No description provided for @clientVisitsAskAction.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientVisitsAskAction;

  /// No description provided for @clientVisitsPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason'**
  String get clientVisitsPickReason;

  /// No description provided for @clientVisitsReasonPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans changed'**
  String get clientVisitsReasonPlans;

  /// No description provided for @clientVisitsReasonOtherVenue.
  ///
  /// In en, this message translates to:
  /// **'Chose elsewhere'**
  String get clientVisitsReasonOtherVenue;

  /// No description provided for @clientVisitsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get clientVisitsReasonOther;

  /// No description provided for @clientVisitsKeepVisit.
  ///
  /// In en, this message translates to:
  /// **'Keep visit'**
  String get clientVisitsKeepVisit;

  /// No description provided for @clientVisitsDoneAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get clientVisitsDoneAskTitle;

  /// No description provided for @clientVisitsDoneAskDetail.
  ///
  /// In en, this message translates to:
  /// **'{venue} will answer in the chat.'**
  String clientVisitsDoneAskDetail(String venue);

  /// No description provided for @clientVisitsDoneCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit cancelled'**
  String get clientVisitsDoneCancelTitle;

  /// No description provided for @clientVisitsDoneCancelDetail.
  ///
  /// In en, this message translates to:
  /// **'Nothing was charged. The chat is closed and {venue} was told.'**
  String clientVisitsDoneCancelDetail(String venue);

  /// No description provided for @clientVisitsNothingChanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed'**
  String get clientVisitsNothingChanged;

  /// No description provided for @clientVouchersAskOpen.
  ///
  /// In en, this message translates to:
  /// **'Open support chat'**
  String get clientVouchersAskOpen;

  /// No description provided for @clientVouchersAskText.
  ///
  /// In en, this message translates to:
  /// **'Hello, my voucher {code} could not be used. Could you issue a credit voucher?'**
  String clientVouchersAskText(String code);

  /// No description provided for @clientVouchersAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Use or ask support'**
  String get clientVouchersAskTitle;

  /// No description provided for @clientVouchersAttachedToast.
  ///
  /// In en, this message translates to:
  /// **'Voucher attached'**
  String get clientVouchersAttachedToast;

  /// No description provided for @clientVouchersBackCredit.
  ///
  /// In en, this message translates to:
  /// **'Use it again here until {date}, or ask support for a credit voucher.'**
  String clientVouchersBackCredit(String date);

  /// No description provided for @clientVouchersBackKept.
  ///
  /// In en, this message translates to:
  /// **'Use it again here until {date}.'**
  String clientVouchersBackKept(String date);

  /// No description provided for @clientVouchersBackLine.
  ///
  /// In en, this message translates to:
  /// **'Back if declined'**
  String get clientVouchersBackLine;

  /// No description provided for @clientVouchersBrowseHalls.
  ///
  /// In en, this message translates to:
  /// **'Browse halls'**
  String get clientVouchersBrowseHalls;

  /// No description provided for @clientVouchersChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get clientVouchersChooseAnother;

  /// No description provided for @clientVouchersChooseLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a voucher'**
  String get clientVouchersChooseLabel;

  /// No description provided for @clientVouchersCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get clientVouchersCodeCopied;

  /// No description provided for @clientVouchersConsumedBody.
  ///
  /// In en, this message translates to:
  /// **'You cancelled at {name} after confirming, so the voucher is used up.'**
  String clientVouchersConsumedBody(String name);

  /// No description provided for @clientVouchersContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get clientVouchersContact;

  /// No description provided for @clientVouchersCreditBody.
  ///
  /// In en, this message translates to:
  /// **'Granted by Ghazal support. Claim it with any hall, hotel or service within {validity}, then confirm there within {confirm}.'**
  String clientVouchersCreditBody(String validity, String confirm);

  /// No description provided for @clientVouchersCreditDeclined.
  ///
  /// In en, this message translates to:
  /// **'No credit issued'**
  String get clientVouchersCreditDeclined;

  /// No description provided for @clientVouchersCreditIssuedBody.
  ///
  /// In en, this message translates to:
  /// **'Support issued you a credit voucher. It works at any hall, hotel or service.'**
  String get clientVouchersCreditIssuedBody;

  /// No description provided for @clientVouchersCtaSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get clientVouchersCtaSignIn;

  /// No description provided for @clientVouchersDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher'**
  String get clientVouchersDetailTitle;

  /// No description provided for @clientVouchersEmptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get clientVouchersEmptyHistory;

  /// No description provided for @clientVouchersEmptyReady.
  ///
  /// In en, this message translates to:
  /// **'No vouchers'**
  String get clientVouchersEmptyReady;

  /// No description provided for @clientVouchersEmptyRequest.
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get clientVouchersEmptyRequest;

  /// No description provided for @clientVouchersExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Not used before {date}, so it can no longer be used.'**
  String clientVouchersExpiredBody(String date);

  /// No description provided for @clientVouchersExplainerTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get clientVouchersExplainerTitle;

  /// No description provided for @clientVouchersForRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your voucher'**
  String get clientVouchersForRequestTitle;

  /// No description provided for @clientVouchersForfeitedBody.
  ///
  /// In en, this message translates to:
  /// **'The {hours} to confirm at the venue or service ended, so this voucher is not valid and does not come back.'**
  String clientVouchersForfeitedBody(String hours);

  /// No description provided for @clientVouchersGetAnother.
  ///
  /// In en, this message translates to:
  /// **'Get another'**
  String get clientVouchersGetAnother;

  /// No description provided for @clientVouchersGetVoucher.
  ///
  /// In en, this message translates to:
  /// **'Get voucher'**
  String get clientVouchersGetVoucher;

  /// No description provided for @clientVouchersGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your vouchers'**
  String get clientVouchersGuestTitle;

  /// No description provided for @clientVouchersHistPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get clientVouchersHistPaid;

  /// No description provided for @clientVouchersHistRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get clientVouchersHistRequested;

  /// No description provided for @clientVouchersHistReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get clientVouchersHistReturned;

  /// No description provided for @clientVouchersHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher history'**
  String get clientVouchersHistoryLabel;

  /// No description provided for @clientVouchersInfoBack.
  ///
  /// In en, this message translates to:
  /// **'Why returned'**
  String get clientVouchersInfoBack;

  /// No description provided for @clientVouchersInfoFit.
  ///
  /// In en, this message translates to:
  /// **'Why not'**
  String get clientVouchersInfoFit;

  /// No description provided for @clientVouchersInfoPay.
  ///
  /// In en, this message translates to:
  /// **'Pay direct'**
  String get clientVouchersInfoPay;

  /// No description provided for @clientVouchersInfoPaying.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get clientVouchersInfoPaying;

  /// No description provided for @clientVouchersInfoRequest.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get clientVouchersInfoRequest;

  /// No description provided for @clientVouchersInfoUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get clientVouchersInfoUsedUp;

  /// No description provided for @clientVouchersInfoWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to reply. Your voucher stays with this request until it is answered.'**
  String clientVouchersInfoWaiting(String name);

  /// No description provided for @clientVouchersInfoWindow.
  ///
  /// In en, this message translates to:
  /// **'Confirm window'**
  String get clientVouchersInfoWindow;

  /// No description provided for @clientVouchersInvalidSaving.
  ///
  /// In en, this message translates to:
  /// **'On these changes the saving at the venue is smaller than the voucher price.'**
  String get clientVouchersInvalidSaving;

  /// No description provided for @clientVouchersInvalidTarget.
  ///
  /// In en, this message translates to:
  /// **'This voucher belongs to {bound}, and your request is now for {other}.'**
  String clientVouchersInvalidTarget(String bound, String other);

  /// No description provided for @clientVouchersKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep voucher'**
  String get clientVouchersKeep;

  /// No description provided for @clientVouchersLabelConfirmBy.
  ///
  /// In en, this message translates to:
  /// **'Confirm by'**
  String get clientVouchersLabelConfirmBy;

  /// No description provided for @clientVouchersLabelEvent.
  ///
  /// In en, this message translates to:
  /// **'Event date'**
  String get clientVouchersLabelEvent;

  /// No description provided for @clientVouchersLabelExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired on'**
  String get clientVouchersLabelExpired;

  /// No description provided for @clientVouchersLabelExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get clientVouchersLabelExpires;

  /// No description provided for @clientVouchersLabelHall.
  ///
  /// In en, this message translates to:
  /// **'Hall'**
  String get clientVouchersLabelHall;

  /// No description provided for @clientVouchersLabelMethod.
  ///
  /// In en, this message translates to:
  /// **'Paid with'**
  String get clientVouchersLabelMethod;

  /// No description provided for @clientVouchersLabelPackage.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get clientVouchersLabelPackage;

  /// No description provided for @clientVouchersLabelReuse.
  ///
  /// In en, this message translates to:
  /// **'Reusable until'**
  String get clientVouchersLabelReuse;

  /// No description provided for @clientVouchersLabelUsed.
  ///
  /// In en, this message translates to:
  /// **'Used on'**
  String get clientVouchersLabelUsed;

  /// No description provided for @clientVouchersLabelValid.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get clientVouchersLabelValid;

  /// No description provided for @clientVouchersNoLongerFits.
  ///
  /// In en, this message translates to:
  /// **'No longer fits'**
  String get clientVouchersNoLongerFits;

  /// No description provided for @clientVouchersNoneBody.
  ///
  /// In en, this message translates to:
  /// **'A voucher lets you request {name} at the voucher price. It costs {fee}, paid once, online.'**
  String clientVouchersNoneBody(String name, String fee);

  /// No description provided for @clientVouchersNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher needed'**
  String get clientVouchersNoneTitle;

  /// No description provided for @clientVouchersOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline, saved on phone'**
  String get clientVouchersOfflineSaved;

  /// No description provided for @clientVouchersOnePer.
  ///
  /// In en, this message translates to:
  /// **'One voucher per request.'**
  String get clientVouchersOnePer;

  /// No description provided for @clientVouchersOwned.
  ///
  /// In en, this message translates to:
  /// **'Already yours'**
  String get clientVouchersOwned;

  /// No description provided for @clientVouchersPayBody.
  ///
  /// In en, this message translates to:
  /// **'Pay {name} directly, on the terms you agreed. Their team scans the code, then marks it used.'**
  String clientVouchersPayBody(String name);

  /// No description provided for @clientVouchersPayFee.
  ///
  /// In en, this message translates to:
  /// **'Pay {fee}'**
  String clientVouchersPayFee(String fee);

  /// No description provided for @clientVouchersPayingBody.
  ///
  /// In en, this message translates to:
  /// **'We are waiting for the bank to confirm. The voucher is ready the moment it does.'**
  String get clientVouchersPayingBody;

  /// No description provided for @clientVouchersPhaseDirect.
  ///
  /// In en, this message translates to:
  /// **'Pay direct'**
  String get clientVouchersPhaseDirect;

  /// No description provided for @clientVouchersPhaseUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Used up'**
  String get clientVouchersPhaseUsedUp;

  /// No description provided for @clientVouchersPhaseWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get clientVouchersPhaseWaiting;

  /// No description provided for @clientVouchersPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Prices updated'**
  String get clientVouchersPriceChanged;

  /// No description provided for @clientVouchersQrAwake.
  ///
  /// In en, this message translates to:
  /// **'The screen stays bright and awake while this is open.'**
  String get clientVouchersQrAwake;

  /// No description provided for @clientVouchersQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code of voucher {code}'**
  String clientVouchersQrLabel(String code);

  /// No description provided for @clientVouchersQuoteLabel.
  ///
  /// In en, this message translates to:
  /// **'The choice your voucher is bound to'**
  String get clientVouchersQuoteLabel;

  /// No description provided for @clientVouchersRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore choice'**
  String get clientVouchersRestore;

  /// No description provided for @clientVouchersRestoredToast.
  ///
  /// In en, this message translates to:
  /// **'Choice restored'**
  String get clientVouchersRestoredToast;

  /// No description provided for @clientVouchersReuseOnly.
  ///
  /// In en, this message translates to:
  /// **'Support can issue a credit voucher only when the venue or service could not take your request. This voucher can be used again here.'**
  String get clientVouchersReuseOnly;

  /// No description provided for @clientVouchersSegHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get clientVouchersSegHistory;

  /// No description provided for @clientVouchersSegLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher groups'**
  String get clientVouchersSegLabel;

  /// No description provided for @clientVouchersSegReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get clientVouchersSegReady;

  /// No description provided for @clientVouchersSegRequest.
  ///
  /// In en, this message translates to:
  /// **'In request'**
  String get clientVouchersSegRequest;

  /// No description provided for @clientVouchersSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clientVouchersSendRequest;

  /// No description provided for @clientVouchersShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get clientVouchersShowCode;

  /// No description provided for @clientVouchersStepDirect.
  ///
  /// In en, this message translates to:
  /// **'Pay direct'**
  String get clientVouchersStepDirect;

  /// No description provided for @clientVouchersStepRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get clientVouchersStepRequest;

  /// No description provided for @clientVouchersStepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Voucher steps'**
  String get clientVouchersStepsLabel;

  /// No description provided for @clientVouchersStillFits.
  ///
  /// In en, this message translates to:
  /// **'Still fits'**
  String get clientVouchersStillFits;

  /// No description provided for @clientVouchersSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get clientVouchersSupport;

  /// No description provided for @clientVouchersTermBack.
  ///
  /// In en, this message translates to:
  /// **'If the venue declines, does not reply or cancels, the voucher comes back: use it again here for {days}, or ask support for a credit voucher.'**
  String clientVouchersTermBack(String days);

  /// No description provided for @clientVouchersTermDirect.
  ///
  /// In en, this message translates to:
  /// **'You pay {name} directly, outside the app, after you confirm. Ghazal takes no part in that payment.'**
  String clientVouchersTermDirect(String name);

  /// No description provided for @clientVouchersTermForfeit.
  ///
  /// In en, this message translates to:
  /// **'After approval, confirm within {confirm} by paying at the venue or service, or the voucher is not valid.'**
  String clientVouchersTermForfeit(String confirm);

  /// No description provided for @clientVouchersTermUsed.
  ///
  /// In en, this message translates to:
  /// **'If you cancel after confirming, the voucher is used up.'**
  String get clientVouchersTermUsed;

  /// No description provided for @clientVouchersTermValid.
  ///
  /// In en, this message translates to:
  /// **'Valid for {validity} from the day you pay.'**
  String clientVouchersTermValid(String validity);

  /// No description provided for @clientVouchersTermWhat.
  ///
  /// In en, this message translates to:
  /// **'A {fee} voucher lets you request {name} at the voucher price. It belongs to this choice only.'**
  String clientVouchersTermWhat(String fee, String name);

  /// No description provided for @clientVouchersTermWindows.
  ///
  /// In en, this message translates to:
  /// **'{name} replies within {reply}. After approval you have {confirm} to confirm.'**
  String clientVouchersTermWindows(String name, String reply, String confirm);

  /// No description provided for @clientVouchersTermWithdraw.
  ///
  /// In en, this message translates to:
  /// **'If you withdraw before approval, you can use it again here.'**
  String get clientVouchersTermWithdraw;

  /// No description provided for @clientVouchersTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Voucher terms'**
  String get clientVouchersTermsTitle;

  /// No description provided for @clientVouchersTooSmallBody.
  ///
  /// In en, this message translates to:
  /// **'On this choice the voucher would not save you more than it costs, so we are not offering one. Contact the venue and pay the standard price.'**
  String get clientVouchersTooSmallBody;

  /// No description provided for @clientVouchersTooSmallTitle.
  ///
  /// In en, this message translates to:
  /// **'No voucher needed'**
  String get clientVouchersTooSmallTitle;

  /// No description provided for @clientVouchersUseAgain.
  ///
  /// In en, this message translates to:
  /// **'Use again'**
  String get clientVouchersUseAgain;

  /// No description provided for @clientVouchersUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use voucher'**
  String get clientVouchersUseThis;

  /// No description provided for @clientVouchersUsedUpBody.
  ///
  /// In en, this message translates to:
  /// **'You cancelled after confirming, so this voucher is used up.'**
  String get clientVouchersUsedUpBody;

  /// No description provided for @clientVouchersViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get clientVouchersViewReceipt;

  /// No description provided for @clientVouchersViewReceiptShort.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get clientVouchersViewReceiptShort;

  /// No description provided for @clientVouchersViewRequest.
  ///
  /// In en, this message translates to:
  /// **'View request'**
  String get clientVouchersViewRequest;

  /// No description provided for @clientVouchersWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'My vouchers'**
  String get clientVouchersWalletTitle;

  /// No description provided for @clientVouchersWhyDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} could not take this request.'**
  String clientVouchersWhyDeclined(String name);

  /// No description provided for @clientVouchersWhyNoResponse.
  ///
  /// In en, this message translates to:
  /// **'{name} did not reply in time.'**
  String clientVouchersWhyNoResponse(String name);

  /// No description provided for @clientVouchersWhyRevoked.
  ///
  /// In en, this message translates to:
  /// **'{name} withdrew its approval.'**
  String clientVouchersWhyRevoked(String name);

  /// No description provided for @clientVouchersWhySlotTaken.
  ///
  /// In en, this message translates to:
  /// **'Another booking took the date.'**
  String get clientVouchersWhySlotTaken;

  /// No description provided for @clientVouchersWhySuspended.
  ///
  /// In en, this message translates to:
  /// **'{name} is not taking requests at the moment.'**
  String clientVouchersWhySuspended(String name);

  /// No description provided for @clientVouchersWhyVenueCancelled.
  ///
  /// In en, this message translates to:
  /// **'{name} cancelled the booking.'**
  String clientVouchersWhyVenueCancelled(String name);

  /// No description provided for @clientVouchersWhyWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'You withdrew the request.'**
  String get clientVouchersWhyWithdrawn;

  /// No description provided for @clientVouchersWindowBody.
  ///
  /// In en, this message translates to:
  /// **'The date is held until the window ends. After it, the approval ends and the voucher is not valid.'**
  String get clientVouchersWindowBody;

  /// No description provided for @clientVouchersWindowLeft.
  ///
  /// In en, this message translates to:
  /// **'Time remaining to confirm'**
  String get clientVouchersWindowLeft;

  /// No description provided for @clientVouchersWordDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get clientVouchersWordDeclined;

  /// No description provided for @clientVouchersWordNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No reply'**
  String get clientVouchersWordNoResponse;

  /// No description provided for @clientVouchersWordRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get clientVouchersWordRevoked;

  /// No description provided for @clientVouchersWordSlotTaken.
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get clientVouchersWordSlotTaken;

  /// No description provided for @clientVouchersWordSuspended.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get clientVouchersWordSuspended;

  /// No description provided for @clientVouchersWordVenueCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get clientVouchersWordVenueCancelled;

  /// No description provided for @clientVouchersWordWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get clientVouchersWordWithdrawn;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppL10nAr();
    case 'en':
      return AppL10nEn();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
